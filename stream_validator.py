from flask import Flask, request, Response
import os
import logging
from urllib.parse import parse_qs
import time # Added for health check

app = Flask(__name__)
logging.basicConfig(
    level=logging.INFO, # Use INFO level for production
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# --- Reverted Logic: Collect ALL non-empty destination keys ---
# Any of these keys, if provided in the environment AND used in OBS,
# will grant access to the relay server.
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

ACCEPTED_IP = os.getenv('ACCEPTED_IP', '')

# Populate VALID_KEYS with only the keys that are actually set (non-empty)
for key_name, key_value in DESTINATION_KEYS.items():
    if key_value: # Only add if the environment variable was set and is not empty
        VALID_KEYS.append(key_value)

# Log the keys that will be considered valid (obscured) for debugging/confirmation
if VALID_KEYS:
    obscured_keys = [k[:2] + '...' + k[-2:] if len(k) > 4 else '****' for k in VALID_KEYS]
    app.logger.info(f"Stream validator starting. Valid incoming keys (from OBS) can be any of: {obscured_keys}")
else:
    app.logger.warning("Stream validator starting. No destination keys found in environment. No streams will be accepted.")

if ACCEPTED_IP:
    app.logger.info(f"IP Whitelist active. Only allowing: {ACCEPTED_IP}")
# --- End Reverted Logic ---


@app.route('/validate', methods=['POST'])
def validate():
    # Get raw data and parse it
    raw_data = request.get_data(as_text=True)
    parsed_data = parse_qs(raw_data)

    # Extract the stream key from the 'name' parameter (this is the key set in OBS)
    stream_key_attempt = parsed_data.get('name', [''])[0]

    # Try to get real IP from Nginx
    client_ip = request.headers.get('X-Real-IP', request.remote_addr)
    if not client_ip or client_ip == '127.0.0.1':
        client_ip = parsed_data.get('addr', [request.remote_addr])[0]

    app.logger.debug(f"Received stream key attempt: '{stream_key_attempt}' from {client_ip}")

    # --- IP Whitelist Check ---
    if ACCEPTED_IP and client_ip != ACCEPTED_IP:
        app.logger.warning(f"REJECTED IP: {client_ip}. Does not match whitelist: {ACCEPTED_IP}")
        return Response('IP not whitelisted', status=403)

    # --- Reverted Validation Check ---
    # Check if the attempted key exists in the list of configured destination keys
    if not VALID_KEYS:
        app.logger.warning(f"REJECTED key from {client_ip}. No valid keys configured on server.")
        return Response('No stream keys configured on server', status=403)

    if stream_key_attempt and stream_key_attempt in VALID_KEYS:
        app.logger.info(f"VALID key accepted from {client_ip}. Key matches one of the configured destination keys.")
        return Response('OK', status=200)
    else:
        obscured_attempt = stream_key_attempt[:2] + '...' + stream_key_attempt[-2:] if len(stream_key_attempt) > 4 else '****'
        app.logger.warning(f"INVALID key rejected from {client_ip}. Attempted key '{obscured_attempt}' is not among the configured destination keys.")
        return Response('Invalid stream key', status=403)

@app.route('/health', methods=['GET'])
def health_check():
    """ Simple health check endpoint """
    return Response('OK', status=200)

if __name__ == '__main__':
    # Run on 127.0.0.1 (localhost only) as Nginx accesses it internally
    app.run(host='127.0.0.1', port=8080, debug=False)
