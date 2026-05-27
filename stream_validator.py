from flask import Flask, request, Response
import os
import logging
from urllib.parse import parse_qs
import time
from datetime import datetime
import requests
import threading

app = Flask(__name__)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

DATA_DIR = "/app/data"
EPISODE_FILE = os.path.join(DATA_DIR, "episode_count.txt")

# Ensure data directory exists
if not os.path.exists(DATA_DIR):
    try:
        os.makedirs(DATA_DIR, exist_ok=True)
    except:
        pass

def load_episode_count():
    if os.path.exists(EPISODE_FILE):
        try:
            with open(EPISODE_FILE, 'r') as f:
                return int(f.read().strip())
        except Exception as e:
            app.logger.error(f"Failed to load episode count: {e}")
    return int(os.getenv('EPISODE_COUNT', '1'))

def save_episode_count(count):
    try:
        with open(EPISODE_FILE, 'w') as f:
            f.write(str(count))
    except Exception as e:
        app.logger.error(f"Failed to save episode count: {e}")

# Configuration from environment
DESTINATION_KEYS = {
    'youtube': os.getenv('YOUTUBE_KEY', ''),
    'twitch': os.getenv('TWITCH_KEY', ''),
    'kick': os.getenv('KICK_KEY', ''),
    'x': os.getenv('X_KEY', ''),
    'facebook': os.getenv('FACEBOOK_KEY', ''),
    'instagram': os.getenv('INSTAGRAM_KEY', ''),
    'cloudflare': os.getenv('CLOUDFLARE_KEY', ''),
    'rtmp1': os.getenv('RTMP1_KEY', ''),
    'rtmp2': os.getenv('RTMP2_KEY', ''),
    'rtmp3': os.getenv('RTMP3_KEY', ''),
    'trovo': os.getenv('TROVO_KEY', ''),
    'obs': os.getenv('OBS_KEY', ''),
}

# Vertical Keys
VERTICAL_KEYS = {
    'youtube_vertical': os.getenv('YOUTUBE_VERTICAL_KEY', ''),
    'twitch_vertical': os.getenv('TWITCH_VERTICAL_KEY', ''),
    'tiktok_vertical': os.getenv('TIKTOK_VERTICAL_KEY', ''),
    'kick_vertical': os.getenv('KICK_VERTICAL_KEY', ''),
    'rtmp_vertical': os.getenv('RTMP_VERTICAL_KEY', ''),
}

VALID_KEYS = set()
for d in [DESTINATION_KEYS, VERTICAL_KEYS]:
    for key_value in d.values():
        if key_value:
            VALID_KEYS.add(key_value)

# Title Management State
TITLE_CONFIG = {
    'base_title': os.getenv('STREAM_BASE_TITLE', ''),
    'episode_count': load_episode_count(),
    'auto_increment': os.getenv('AUTO_INCREMENT_EPISODE', 'true').lower() == 'true',
    'auto_date': os.getenv('AUTO_DATE', 'true').lower() == 'true',
}

# Twitch API credentials for title updates
TWITCH_CREDS = {
    'client_id': os.getenv('TWITCH_CLIENT_ID', ''),
    'token': os.getenv('TWITCH_OAUTH_TOKEN', ''),
    'broadcaster_id': os.getenv('TWITCH_BROADCASTER_ID', ''),
}

def get_formatted_title():
    parts = []
    if TITLE_CONFIG['base_title']:
        parts.append(TITLE_CONFIG['base_title'])

    if TITLE_CONFIG['episode_count'] > 0:
        parts.append(f"Episode #{TITLE_CONFIG['episode_count']}")

    if TITLE_CONFIG['auto_date']:
        parts.append(datetime.now().strftime("%Y-%m-%d"))

    return " / ".join(parts)

def update_external_titles_worker():
    title = get_formatted_title()
    app.logger.info(f"Background thread: Updating stream titles to: {title}")

    # Twitch Update
    if TWITCH_CREDS['client_id'] and TWITCH_CREDS['token'] and TWITCH_CREDS['broadcaster_id']:
        headers = {
            'Client-Id': TWITCH_CREDS['client_id'],
            'Authorization': f"Bearer {TWITCH_CREDS['token']}",
            'Content-Type': 'application/json'
        }
        url = f"https://api.twitch.tv/helix/channels?broadcaster_id={TWITCH_CREDS['broadcaster_id']}"
        data = {"title": title}
        try:
            res = requests.patch(url, headers=headers, json=data, timeout=10)
            if res.status_code == 204:
                app.logger.info("Twitch title updated successfully.")
            else:
                app.logger.error(f"Twitch API error: {res.status_code} - {res.text}")
        except Exception as e:
            app.logger.error(f"Failed to update Twitch title: {e}")

def trigger_title_update():
    thread = threading.Thread(target=update_external_titles_worker)
    thread.daemon = True
    thread.start()

@app.route('/on_publish', methods=['POST'])
def on_publish():
    # Try to get stream key from POST body (form-urlencoded) or query string
    raw_data = request.get_data(as_text=True)
    parsed_data = parse_qs(raw_data)

    stream_key_attempt = parsed_data.get('name', [None])[0]
    if not stream_key_attempt:
        stream_key_attempt = request.args.get('key')
    if not stream_key_attempt:
        stream_key_attempt = request.args.get('name')

    app_name = request.args.get('app', 'live')
    client_ip = request.remote_addr

    if not VALID_KEYS:
        app.logger.warning(f"REJECTED key from {client_ip}. No valid keys configured.")
        return Response('No stream keys configured', status=403)

    if stream_key_attempt in VALID_KEYS:
        app.logger.info(f"VALID key accepted for app '{app_name}' from {client_ip}.")
        # Update titles on new stream start (only for primary app to avoid duplicates)
        if app_name == 'live':
            trigger_title_update()
        return Response('OK', status=200)
    else:
        app.logger.warning(f"INVALID key rejected from {client_ip}. Key used: {stream_key_attempt[:4]}...")
        return Response('Invalid stream key', status=403)

@app.route('/on_publish_done', methods=['POST'])
def on_publish_done():
    app_name = request.args.get('app', 'live')
    app.logger.info(f"Stream finished on app '{app_name}'.")

    # Only increment for the primary app to avoid double increment
    if app_name == 'live' and TITLE_CONFIG['auto_increment']:
        TITLE_CONFIG['episode_count'] += 1
        save_episode_count(TITLE_CONFIG['episode_count'])
        app.logger.info(f"Incremented episode count to {TITLE_CONFIG['episode_count']} and saved to disk.")

    return Response('OK', status=200)

@app.route('/validate', methods=['POST'])
def validate():
    return on_publish()

@app.route('/health', methods=['GET'])
def health_check():
    return Response('OK', status=200)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False)
