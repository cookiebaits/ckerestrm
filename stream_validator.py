from flask import Flask, request, Response
import os
import logging
from urllib.parse import parse_qs

app = Flask(__name__)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

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

for key_name, key_value in DESTINATION_KEYS.items():
    if key_value:
        VALID_KEYS.append(key_value)

if VALID_KEYS:
    obscured_keys = [k[:2] + '...' + k[-2:] if len(k) > 4 else '****' for k in VALID_KEYS]
    app.logger.info(f"Stream validator starting. Valid incoming keys: {obscured_keys}")
else:
    app.logger.warning("Stream validator starting. No keys found in environment.")

@app.route('/validate', methods=['POST'])
def validate():
    raw_data = request.get_data(as_text=True)
    parsed_data = parse_qs(raw_data)
    stream_key_attempt = parsed_data.get('name', [''])[0]
    client_ip = request.headers.get('X-Real-IP', request.remote_addr)
    if not client_ip or client_ip == '127.0.0.1':
        client_ip = parsed_data.get('addr', [request.remote_addr])[0]

    if ACCEPTED_IP and client_ip != ACCEPTED_IP:
        app.logger.warning(f"REJECTED IP: {client_ip}")
        return Response('IP not whitelisted', status=403)

    if not VALID_KEYS:
        return Response('No keys configured', status=403)

    if stream_key_attempt in VALID_KEYS:
        app.logger.info(f"ACCEPTED key from {client_ip}")
        return Response('OK', status=200)
    else:
        app.logger.warning(f"REJECTED key from {client_ip}")
        return Response('Invalid stream key', status=403)

@app.route('/publish_done', methods=['POST'])
def publish_done():
    """ Callback when stream ends """
    app.logger.info("Stream finished.")
    return Response('OK', status=200)

@app.route('/health', methods=['GET'])
def health_check():
    return Response('OK', status=200)

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=8080, debug=False)
