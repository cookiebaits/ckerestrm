from flask import Flask, request, Response, session, redirect, url_for
from flask_session import Session
import os
import logging
import requests
from urllib.parse import parse_qs, urlencode
import json

app = Flask(__name__)
app.config['SECRET_KEY'] = os.urandom(24)
app.config['SESSION_TYPE'] = 'filesystem'
app.config['SESSION_FILE_DIR'] = '/app/data/sessions'
Session(app)

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

VALID_KEYS = []
PLATFORMS = ['YOUTUBE', 'TWITCH', 'KICK', 'TIKTOK', 'FACEBOOK', 'INSTAGRAM', 'X', 'TROVO', 'RTMP1']

for p in PLATFORMS:
    k = os.getenv(f'{p}_KEY', '')
    if k: VALID_KEYS.append(k)
    vk = os.getenv(f'V_{p}_KEY', '')
    if vk: VALID_KEYS.append(vk)

obs_key = os.getenv('OBS_KEY', '')
if obs_key: VALID_KEYS.append(obs_key)

ACCEPTED_IP = os.getenv('ACCEPTED_IP', '')
TWITCH_CLIENT_ID = os.getenv('TWITCH_CLIENT_ID')
TWITCH_CLIENT_SECRET = os.getenv('TWITCH_CLIENT_SECRET')
YOUTUBE_CLIENT_ID = os.getenv('YOUTUBE_CLIENT_ID')
YOUTUBE_CLIENT_SECRET = os.getenv('YOUTUBE_CLIENT_SECRET')

TOKEN_FILE = '/app/data/tokens.json'
def save_tokens(tokens):
    os.makedirs('/app/data', exist_ok=True)
    with open(TOKEN_FILE, 'w') as f: json.dump(tokens, f)
def load_tokens():
    if os.path.exists(TOKEN_FILE):
        try:
            with open(TOKEN_FILE, 'r') as f: return json.load(f)
        except: pass
    return {}

@app.route('/health')
def health(): return "OK"

@app.route('/validate', methods=['POST'])
def validate():
    raw_data = request.get_data(as_text=True)
    parsed_data = parse_qs(raw_data)
    stream_key = parsed_data.get('name', [''])[0]
    client_ip = request.headers.get('CF-Connecting-IP', request.remote_addr)
    if ACCEPTED_IP and client_ip != ACCEPTED_IP: return Response('IP Denied', status=403)
    if stream_key in VALID_KEYS: return Response('OK', status=200)
    return Response('Invalid Key', status=403)

@app.route('/login/twitch')
def login_twitch():
    redirect_uri = request.host_url.rstrip('/') + url_for('twitch_callback')
    params = {'client_id': TWITCH_CLIENT_ID, 'redirect_uri': redirect_uri, 'response_type': 'code', 'scope': 'chat:read channel:manage:broadcast'}
    return redirect(f"https://id.twitch.tv/oauth2/authorize?{urlencode(params)}")

@app.route('/callback/twitch')
def twitch_callback():
    code = request.args.get('code')
    redirect_uri = request.host_url.rstrip('/') + url_for('twitch_callback')
    res = requests.post('https://id.twitch.tv/oauth2/token', data={'client_id': TWITCH_CLIENT_ID, 'client_secret': TWITCH_CLIENT_SECRET, 'code': code, 'grant_type': 'authorization_code', 'redirect_uri': redirect_uri})
    tokens = load_tokens()
    tokens['twitch'] = res.json()
    save_tokens(tokens)
    return redirect('/chat.html')

@app.route('/login/youtube')
def login_youtube():
    redirect_uri = request.host_url.rstrip('/') + url_for('youtube_callback')
    params = {'client_id': YOUTUBE_CLIENT_ID, 'redirect_uri': redirect_uri, 'response_type': 'code', 'scope': 'https://www.googleapis.com/auth/youtube.force-ssl', 'access_type': 'offline', 'prompt': 'consent'}
    return redirect(f"https://accounts.google.com/o/oauth2/v2/auth?{urlencode(params)}")

@app.route('/callback/youtube')
def youtube_callback():
    code = request.args.get('code')
    redirect_uri = request.host_url.rstrip('/') + url_for('youtube_callback')
    res = requests.post('https://oauth2.googleapis.com/token', data={'client_id': YOUTUBE_CLIENT_ID, 'client_secret': YOUTUBE_CLIENT_SECRET, 'code': code, 'grant_type': 'authorization_code', 'redirect_uri': redirect_uri})
    tokens = load_tokens()
    tokens['youtube'] = res.json()
    save_tokens(tokens)
    return redirect('/chat.html')

@app.route('/auth_status')
def auth_status():
    tokens = load_tokens()
    status = {'twitch': None, 'youtube': None}
    if 'twitch' in tokens:
        t = tokens['twitch']
        headers = {'Client-ID': TWITCH_CLIENT_ID, 'Authorization': f"Bearer {t.get('access_token','')}"}
        res = requests.get('https://api.twitch.tv/helix/users', headers=headers)
        if res.status_code == 200:
            status['twitch'] = res.json()['data'][0]['login']
    if 'youtube' in tokens:
        y = tokens['youtube']
        headers = {'Authorization': f"Bearer {y.get('access_token','')}"}
        res = requests.get('https://www.googleapis.com/youtube/v3/liveBroadcasts?broadcastStatus=active&part=snippet', headers=headers)
        if res.status_code == 200:
            data = res.json()
            if data['items']: status['youtube'] = data['items'][0]['id']
    return json.dumps(status)

@app.route('/update_title', methods=['POST'])
def update_title():
    title = request.form.get('title')
    tokens = load_tokens()
    if 'twitch' in tokens:
        t = tokens['twitch']
        headers = {'Client-ID': TWITCH_CLIENT_ID, 'Authorization': f"Bearer {t.get('access_token','')}"}
        user_res = requests.get('https://api.twitch.tv/helix/users', headers=headers)
        if user_res.status_code == 200:
            uid = user_res.json()['data'][0]['id']
            requests.patch(f"https://api.twitch.tv/helix/channels?broadcaster_id={uid}", headers=headers, json={'title': title})
    if 'youtube' in tokens:
        y = tokens['youtube']
        headers = {'Authorization': f"Bearer {y.get('access_token','')}"}
        res = requests.get('https://www.googleapis.com/youtube/v3/liveBroadcasts?broadcastStatus=active&part=snippet', headers=headers)
        if res.status_code == 200:
            data = res.json()
            if data['items']:
                bid = data['items'][0]['id']
                snippet = data['items'][0]['snippet']
                snippet['title'] = title
                requests.put('https://www.googleapis.com/youtube/v3/liveBroadcasts?part=snippet', headers=headers, json={'id': bid, 'snippet': snippet})
    return redirect('/chat.html')

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=8080)
