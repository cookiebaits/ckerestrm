from flask import Flask, request, Response, session, redirect, url_for, jsonify
from flask_session import Session
import os
import logging
from urllib.parse import parse_qs, urlencode
import threading
import subprocess
from datetime import datetime
import requests
import secrets
import time

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('FLASK_SECRET_KEY', secrets.token_hex(32))
app.config['SESSION_TYPE'] = 'filesystem'
app.config['SESSION_FILE_DIR'] = '/app/data/sessions'
Session(app)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Configuration
VALID_KEYS = []
DESTINATION_KEYS = {
    'youtube': os.getenv('YOUTUBE_KEY', ''),
    'twitch': os.getenv('TWITCH_KEY', ''),
    'kick': os.getenv('KICK_KEY', ''),
    'x': os.getenv('X_KEY', ''),
    'facebook': os.getenv('FACEBOOK_KEY', ''),
    'instagram': os.getenv('INSTAGRAM_KEY', ''),
    'tiktok': os.getenv('TIKTOK_KEY', ''),
    'rtmp1': os.getenv('RTMP1_KEY', ''),
    'rtmp2': os.getenv('RTMP2_KEY', ''),
    'rtmp3': os.getenv('RTMP3_KEY', ''),
    'trovo': os.getenv('TROVO_KEY', ''),
    'obs': os.getenv('OBS_KEY', ''),
}

# Vertical Keys
for i in ['YOUTUBE', 'TWITCH', 'TIKTOK', 'KICK', 'FACEBOOK', 'INSTAGRAM', 'X', 'TROVO', 'RTMP1']:
    DESTINATION_KEYS[f'v_{i.lower()}'] = os.getenv(f'V_{i}_KEY', '')

ACCEPTED_IP = os.getenv('ACCEPTED_IP', '')
EPISODE_FILE = '/app/data/episode_count.txt'
TITLE_LOCK = threading.Lock()

# Populate VALID_KEYS
for key_name, key_value in DESTINATION_KEYS.items():
    if key_value:
        VALID_KEYS.append(key_value)

if VALID_KEYS:
    obscured_keys = [k[:2] + '...' + k[-2:] if len(k) > 4 else '****' for k in VALID_KEYS]
    app.logger.info(f"Stream validator starting. Valid keys: {obscured_keys}")
else:
    app.logger.warning("Stream validator starting. No keys found in environment.")

if ACCEPTED_IP:
    app.logger.info(f"IP Whitelist active: {ACCEPTED_IP}")

def get_episode_count():
    try:
        if not os.path.exists(EPISODE_FILE):
            os.makedirs(os.path.dirname(EPISODE_FILE), exist_ok=True)
            with open(EPISODE_FILE, 'w') as f:
                f.write('1')
            return 1
        with open(EPISODE_FILE, 'r') as f:
            return int(f.read().strip())
    except Exception as e:
        app.logger.error(f"Error reading episode count: {e}")
        return 1

def increment_episode_count():
    with TITLE_LOCK:
        count = get_episode_count()
        try:
            with open(EPISODE_FILE, 'w') as f:
                f.write(str(count + 1))
        except Exception as e:
            app.logger.error(f"Error writing episode count: {e}")

def run_update_titles():
    # Only run if Twitch credentials exist
    if not (os.getenv('TWITCH_CLIENT_ID') and os.getenv('TWITCH_OAUTH_TOKEN') and os.getenv('TWITCH_BROADCASTER_ID')):
        return

    count = get_episode_count()
    date_str = datetime.now().strftime('%Y-%m-%d')
    base_title = os.getenv('STREAM_BASE_TITLE', 'Live Stream')
    full_title = f"{base_title} | Ep.{count} | {date_str}"

    app.logger.info(f"Updating Twitch title to: {full_title}")

    try:
        # Call the update script
        subprocess.run(['python3', '/app/update_titles.py', full_title], check=False)
        # Note: We don't increment here to avoid double increments from dual horizontal/vertical streams
        # We'll increment on publish_done of the primary app.
    except Exception as e:
        app.logger.error(f"Failed to update titles: {e}")

@app.route('/validate', methods=['POST'])
def validate():
    raw_data = request.get_data(as_text=True)
    parsed_data = parse_qs(raw_data)
    stream_key_attempt = parsed_data.get('name', [''])[0]

    # Cloudflare Real IP or fallback
    client_ip = request.headers.get('CF-Connecting-IP', request.remote_addr)
    if not client_ip or client_ip == '127.0.0.1':
        client_ip = parsed_data.get('addr', [request.remote_addr])[0]

    # IP Whitelist Check
    if ACCEPTED_IP and client_ip != ACCEPTED_IP:
        app.logger.warning(f"REJECTED IP: {client_ip}")
        return Response('IP not whitelisted', status=403)

    # Key Check
    if not VALID_KEYS:
        return Response('No keys configured', status=403)

    if stream_key_attempt in VALID_KEYS:
        app.logger.info(f"ACCEPTED stream from {client_ip}")
        # Update titles in background to not block Nginx
        threading.Thread(target=run_update_titles).start()
        return Response('OK', status=200)
    else:
        app.logger.warning(f"REJECTED invalid key from {client_ip}")
        return Response('Invalid stream key', status=403)

@app.route('/publish_done', methods=['POST', 'GET'])
def publish_done():
    # Nginx sends GET by default for on_publish_done in some versions, but usually POST
    app_name = request.args.get('app', '')
    if app_name == os.getenv('APP_NAME', 'live'):
        # Increment episode count when horizontal stream finishes
        increment_episode_count()
        app.logger.info("Horizontal stream finished. Episode count incremented.")
    return Response('OK', status=200)

@app.route('/health', methods=['GET'])
def health_check():
    return Response('OK', status=200)

# OAuth Configurations
TWITCH_CLIENT_ID = os.getenv('TWITCH_CLIENT_ID')
TWITCH_CLIENT_SECRET = os.getenv('TWITCH_CLIENT_SECRET')
YOUTUBE_CLIENT_ID = os.getenv('YOUTUBE_CLIENT_ID')
YOUTUBE_CLIENT_SECRET = os.getenv('YOUTUBE_CLIENT_SECRET')

# --- Unified Chat Backend ---

CHAT_MESSAGES = []
CHAT_LOCK = threading.Lock()
MAX_CHAT_HISTORY = 100

# Global registry of active tokens for background polling
ACTIVE_TOKENS = {
    'twitch': None,
    'youtube': None,
    'yt_chat_id': None
}

def add_message(source, user, text):
    global CHAT_MESSAGES
    with CHAT_LOCK:
        msg = {
            'id': secrets.token_hex(8),
            'source': source,
            'user': user,
            'text': text,
            'timestamp': datetime.now().isoformat()
        }
        # Avoid duplicate test messages if needed, but here we just append
        CHAT_MESSAGES.append(msg)
        if len(CHAT_MESSAGES) > MAX_CHAT_HISTORY:
            CHAT_MESSAGES.pop(0)

def poll_twitch_chat():
    """Poll Twitch chat via Helix API"""
    broadcaster_id = os.getenv('TWITCH_BROADCASTER_ID')
    
    while True:
        token = ACTIVE_TOKENS.get('twitch')
        if token and broadcaster_id:
            try:
                # Use get_chat_messages (Helix) - note: this requires a user token from someone in the chat or the broadcaster
                url = f"https://api.twitch.tv/helix/chat/messages?broadcaster_id={broadcaster_id}&user_id={broadcaster_id}"
                headers = {
                    "Client-Id": os.getenv('TWITCH_CLIENT_ID'),
                    "Authorization": f"Bearer {token}"
                }
                # Note: Helix get_chat_messages is relatively new and might have tight rate limits.
                # In a real app, IRC is better.
                r = requests.get(url, headers=headers, timeout=5)
                if r.status_code == 200:
                    data = r.json()
                    for msg in data.get('data', []):
                        add_message('twitch', msg['user_name'], msg['message_text'])
            except Exception as e:
                app.logger.error(f"Twitch poll error: {e}")
        time.sleep(10)

def poll_youtube_chat():
    """Poll YouTube chat via Live Streaming API"""
    while True:
        token = ACTIVE_TOKENS.get('youtube')
        if token:
            try:
                headers = {"Authorization": f"Bearer {token}"}
                
                # 1. Get Live Chat ID if we don't have it
                if not ACTIVE_TOKENS.get('yt_chat_id'):
                    url = "https://www.googleapis.com/youtube/v3/liveBroadcasts?mine=true&broadcastStatus=active&part=snippet"
                    r = requests.get(url, headers=headers, timeout=5)
                    if r.status_code == 200:
                        items = r.json().get('items', [])
                        if items:
                            ACTIVE_TOKENS['yt_chat_id'] = items[0]['snippet'].get('liveChatId')

                # 2. Poll messages
                chat_id = ACTIVE_TOKENS.get('yt_chat_id')
                if chat_id:
                    url = f"https://www.googleapis.com/youtube/v3/liveChat/messages?liveChatId={chat_id}&part=snippet,authorDetails"
                    r = requests.get(url, headers=headers, timeout=5)
                    if r.status_code == 200:
                        data = r.json()
                        for item in data.get('items', []):
                            user = item['authorDetails']['displayName']
                            text = item['snippet']['displayMessage']
                            add_message('youtube', user, text)
            except Exception as e:
                app.logger.error(f"YouTube poll error: {e}")
        time.sleep(10)

# Start Polling Threads
threading.Thread(target=poll_twitch_chat, daemon=True).start()
threading.Thread(target=poll_youtube_chat, daemon=True).start()

@app.route('/chat/messages')
def get_messages():
    with CHAT_LOCK:
        return jsonify({
            'messages': CHAT_MESSAGES,
            'authenticated': {
                'twitch': 'twitch_token' in session,
                'youtube': 'youtube_token' in session
            }
        })

@app.route('/chat/test_msg')
def test_msg():
    source = request.args.get('source', 'twitch')
    user = request.args.get('user', 'TestUser')
    text = request.args.get('text', 'Hello from PrismRTMPS!')
    add_message(source, user, text)
    return "Message added!"

# --- OAuth Routes ---

@app.route('/login/twitch')
def login_twitch():
    redirect_uri = request.args.get('redirect_uri') or f"{request.host_url}callback/twitch"
    scope = "chat:read chat:edit channel:manage:broadcast"
    params = {
        "client_id": TWITCH_CLIENT_ID,
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "scope": scope
    }
    return redirect(f"https://id.twitch.tv/oauth2/authorize?{urlencode(params)}")

@app.route('/callback/twitch')
def callback_twitch():
    code = request.args.get('code')
    redirect_uri = f"{request.host_url}callback/twitch"
    
    data = {
        "client_id": TWITCH_CLIENT_ID,
        "client_secret": TWITCH_CLIENT_SECRET,
        "code": code,
        "grant_type": "authorization_code",
        "redirect_uri": redirect_uri
    }
    
    r = requests.post("https://id.twitch.tv/oauth2/token", data=data)
    res = r.json()
    
    if 'access_token' in res:
        session['twitch_token'] = res['access_token']
        session['twitch_refresh'] = res.get('refresh_token')
        ACTIVE_TOKENS['twitch'] = res['access_token']
        return "Twitch authenticated! You can close this window."
    return f"Error: {res.get('error_description', 'Unknown error')}", 400

@app.route('/login/youtube')
def login_youtube():
    redirect_uri = request.args.get('redirect_uri') or f"{request.host_url}callback/youtube"
    scope = "https://www.googleapis.com/auth/youtube.readonly https://www.googleapis.com/auth/youtube.force-ssl"
    params = {
        "client_id": YOUTUBE_CLIENT_ID,
        "redirect_uri": redirect_uri,
        "response_type": "code",
        "scope": scope,
        "access_type": "offline",
        "prompt": "consent"
    }
    return redirect(f"https://accounts.google.com/o/oauth2/v2/auth?{urlencode(params)}")

@app.route('/callback/youtube')
def callback_youtube():
    code = request.args.get('code')
    redirect_uri = f"{request.host_url}callback/youtube"
    
    data = {
        "client_id": YOUTUBE_CLIENT_ID,
        "client_secret": YOUTUBE_CLIENT_SECRET,
        "code": code,
        "grant_type": "authorization_code",
        "redirect_uri": redirect_uri
    }
    
    r = requests.post("https://oauth2.googleapis.com/token", data=data)
    res = r.json()
    
    if 'access_token' in res:
        session['youtube_token'] = res['access_token']
        session['youtube_refresh'] = res.get('refresh_token')
        ACTIVE_TOKENS['youtube'] = res['access_token']
        return "YouTube authenticated! You can close this window."
    return f"Error: {res.get('error_description', 'Unknown error')}", 400

if __name__ == '__main__':
    # Ensure session directory exists
    os.makedirs(app.config['SESSION_FILE_DIR'], exist_ok=True)
    app.run(host='127.0.0.1', port=8080, debug=False)
