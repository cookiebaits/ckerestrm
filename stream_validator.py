from flask import Flask, request, Response
import os
import logging
from urllib.parse import parse_qs

app = Flask(__name__)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

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

@app.route('/validate', methods=['POST'])
def validate():
    client_ip = request.remote_addr
    app.logger.info(f"Validation attempt received from {client_ip}")

    # Extract data from POST body
    raw_data = request.get_data(as_text=True)
    parsed_data = parse_qs(raw_data)

    # Nginx-RTMP sends 'name' (stream key) in the POST body
    stream_key_attempt = parsed_data.get('name', [None])[0]
    app_name = parsed_data.get('app', ['unknown'])[0]

    if not stream_key_attempt:
        app.logger.warning(f"REJECTED: No stream key found in POST body from {client_ip}. Body content: {raw_data}")
        return Response('Missing stream key', status=403)

    if not VALID_KEYS:
        app.logger.error(f"REJECTED: No valid keys configured on server. Cannot validate any stream.")
        return Response('No valid keys on server', status=500)

    if stream_key_attempt in VALID_KEYS:
        app.logger.info(f"SUCCESS: Valid key accepted for app '{app_name}' from {client_ip}.")
        return Response('OK', status=200)
    else:
        # Log a snippet of the failed key for identification (first 4 chars)
        obscured_key = (stream_key_attempt[:4] + "...") if len(stream_key_attempt) > 4 else "****"
        app.logger.warning(f"REJECTED: Invalid key from {client_ip}. Key used: {obscured_key}")
        return Response('Invalid stream key', status=403)

@app.route('/health', methods=['GET'])
def health_check():
    return Response('OK', status=200)

if __name__ == '__main__':
    # Listen on all interfaces
    app.run(host='0.0.0.0', port=8080, debug=False)
