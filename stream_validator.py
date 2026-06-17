from flask import Flask, request, Response, redirect, url_for, session, jsonify
from werkzeug.middleware.proxy_fix import ProxyFix
import os
import logging
from urllib.parse import parse_qs, urlencode
import threading
import subprocess
import time
from datetime import datetime
import obsws_python as obs
from flask_session import Session
import requests
import google_auth_oauthlib.flow
from googleapiclient.discovery import build
from flask_socketio import SocketIO, emit
import asyncio
import edge_tts
from twitchio.ext import commands

app = Flask(__name__)
# Support host-level reverse proxy headers
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1, x_prefix=1)
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet')

# Session configuration
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', os.urandom(24))
app.config['SESSION_TYPE'] = 'filesystem'
app.config['SESSION_FILE_DIR'] = '/app/data/sessions'
app.config['SESSION_COOKIE_HTTPONLY'] = True
app.config['SESSION_COOKIE_SECURE'] = True if os.getenv('SERVER_DOMAIN') else False
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'

os.makedirs(app.config['SESSION_FILE_DIR'], exist_ok=True)
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

ACCEPTED_IP_RAW = os.getenv('ACCEPTED_IP', '')
ACCEPTED_IPS = [ip.strip() for ip in ACCEPTED_IP_RAW.split(',')] if ACCEPTED_IP_RAW else []
EPISODE_FILE = '/app/data/episode_count.txt'
TITLE_LOCK = threading.Lock()

# OAuth Configuration
TWITCH_CLIENT_ID = os.getenv('TWITCH_CLIENT_ID', '')
TWITCH_CLIENT_SECRET = os.getenv('TWITCH_CLIENT_SECRET', '')
TWITCH_REDIRECT_URI = os.getenv('TWITCH_REDIRECT_URI', '')

YOUTUBE_CLIENT_ID = os.getenv('YOUTUBE_CLIENT_ID', '')
YOUTUBE_CLIENT_SECRET = os.getenv('YOUTUBE_CLIENT_SECRET', '')
YOUTUBE_REDIRECT_URI = os.getenv('YOUTUBE_REDIRECT_URI', '')

# OBS WebSocket Configuration
OBS_WS_HOST = os.getenv('OBS_WS_HOST', '')
OBS_WS_PORT = int(os.getenv('OBS_WS_PORT', 4455))
OBS_WS_PASSWORD = os.getenv('OBS_WS_PASSWORD', '')
OBS_SCENE_LIVE = os.getenv('OBS_SCENE_LIVE', 'Full Room')
OBS_SCENE_BRB = os.getenv('OBS_SCENE_BRB', 'brb')
OBS_SCENE_INTRO = os.getenv('OBS_SCENE_INTRO', 'Intro')

# Populate VALID_KEYS
for key_name, key_value in DESTINATION_KEYS.items():
    if key_value:
        VALID_KEYS.append(key_value)

if VALID_KEYS:
    obscured_keys = [k[:2] + '...' + k[-2:] if len(k) > 4 else '****' for k in VALID_KEYS]
    app.logger.info(f"Stream validator starting. Valid keys: {obscured_keys}")
else:
    app.logger.warning("Stream validator starting. No keys found in environment.")

if ACCEPTED_IP_RAW:
    app.logger.info("IP Whitelist is active")

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

def switch_obs_scene(scene_name, delay=0):
    if not OBS_WS_HOST:
        return

    def _do_switch():
        try:
            if delay > 0:
                app.logger.info(f"OBS: Waiting {delay} seconds before switching to '{scene_name}'")
                time.sleep(delay)
            cl = obs.ReqClient(host=OBS_WS_HOST, port=OBS_WS_PORT, password=OBS_WS_PASSWORD, timeout=3)
            cl.set_current_program_scene(scene_name)
            app.logger.info(f"OBS: Switched to scene '{scene_name}'")
        except Exception as e:
            app.logger.error(f"OBS WebSocket Error: {e}")

    threading.Thread(target=_do_switch).start()

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
    # Nginx RTMP module sends data as application/x-www-form-urlencoded
    # Flask populates request.form for us.
    stream_key_attempt = request.form.get('name')
    client_ip_from_data = request.form.get('addr')

    if not stream_key_attempt:
        # Fallback to manual parsing if necessary
        raw_data = request.get_data(as_text=True)
        parsed_data = parse_qs(raw_data)
        stream_key_attempt = parsed_data.get('name', [''])[0]
        client_ip_from_data = parsed_data.get('addr', [request.remote_addr])[0]
    
    app_name = request.args.get('app', '')

    # Cloudflare Real IP or fallback
    client_ip = request.headers.get('CF-Connecting-IP', request.remote_addr)
    if not client_ip or client_ip == '127.0.0.1':
        client_ip = client_ip_from_data or request.remote_addr

    # IP Whitelist Check
    if ACCEPTED_IPS and client_ip not in ACCEPTED_IPS:
        # Don't leak the whitelist in logs if we are being paranoid, but for now just logging the fail
        app.logger.warning(f"REJECTED IP: {client_ip} (Not in whitelist)")
        return Response('Unauthorized connection source', status=403)

    # Key Check
    if not VALID_KEYS:
        return Response('No keys configured', status=403)

    if stream_key_attempt in VALID_KEYS:
        app.logger.info(f"ACCEPTED stream from {client_ip}")
        # Update titles in background to not block Nginx
        threading.Thread(target=run_update_titles).start()
        
        # Only switch scenes if it's the primary horizontal stream
        if app_name == os.getenv('APP_NAME', 'live'):
            # Scene switching is now handled by NOALBS based on bitrate
            pass
        
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
        # Scene switching is now handled by NOALBS
        pass
    return Response('OK', status=200)

# --- OAuth Routes ---

@app.route('/login/twitch')
def login_twitch():
    if not TWITCH_CLIENT_ID:
        return "Twitch Client ID not configured", 400
    params = {
        'client_id': TWITCH_CLIENT_ID,
        'redirect_uri': TWITCH_REDIRECT_URI,
        'response_type': 'code',
        'scope': 'channel:manage:broadcast chat:read chat:edit'
    }
    return redirect(f"https://id.twitch.tv/oauth2/authorize?{urlencode(params)}")

@app.route('/callback/twitch')
def callback_twitch():
    code = request.args.get('code')
    data = {
        'client_id': TWITCH_CLIENT_ID,
        'client_secret': TWITCH_CLIENT_SECRET,
        'code': code,
        'grant_type': 'authorization_code',
        'redirect_uri': TWITCH_REDIRECT_URI
    }
    r = requests.post("https://id.twitch.tv/oauth2/token", data=data)
    res = r.json()
    session['twitch_token'] = res.get('access_token')
    
    # Get user info
    headers = {'Authorization': f"Bearer {session['twitch_token']}", 'Client-Id': TWITCH_CLIENT_ID}
    u = requests.get("https://api.twitch.tv/helix/users", headers=headers)
    user_data = u.json()
    if 'data' in user_data and len(user_data['data']) > 0:
        session['twitch_user'] = user_data['data'][0]['display_name']
        session['twitch_id'] = user_data['data'][0]['id']

    return redirect('/chat.html')

@app.route('/login/youtube')
def login_youtube():
    if not YOUTUBE_CLIENT_ID:
        return "YouTube Client ID not configured", 400
    flow = google_auth_oauthlib.flow.Flow.from_client_config(
        {
            "web": {
                "client_id": YOUTUBE_CLIENT_ID,
                "client_secret": YOUTUBE_CLIENT_SECRET,
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "redirect_uris": [YOUTUBE_REDIRECT_URI]
            }
        },
        scopes=['https://www.googleapis.com/auth/youtube.force-ssl']
    )
    flow.redirect_uri = YOUTUBE_REDIRECT_URI
    authorization_url, state = flow.authorization_url(access_type='offline', include_granted_scopes='true')
    session['google_state'] = state
    return redirect(authorization_url)

@app.route('/callback/youtube')
def callback_youtube():
    flow = google_auth_oauthlib.flow.Flow.from_client_config(
        {
            "web": {
                "client_id": YOUTUBE_CLIENT_ID,
                "client_secret": YOUTUBE_CLIENT_SECRET,
                "auth_uri": "https://accounts.google.com/o/oauth2/auth",
                "token_uri": "https://oauth2.googleapis.com/token",
                "redirect_uris": [YOUTUBE_REDIRECT_URI]
            }
        },
        scopes=['https://www.googleapis.com/auth/youtube.force-ssl'],
        state=session['google_state']
    )
    flow.redirect_uri = YOUTUBE_REDIRECT_URI
    flow.fetch_token(authorization_response=request.url)
    credentials = flow.credentials
    session['youtube_token'] = credentials.token
    
    youtube = build('youtube', 'v3', credentials=credentials)
    r = youtube.channels().list(mine=True, part='snippet').execute()
    if 'items' in r:
        session['youtube_user'] = r['items'][0]['snippet']['title']

    return redirect('/chat.html')

@app.route('/api/status')
def api_status():
    twitch_user = session.get('twitch_user')
    youtube_user = session.get('youtube_user')
    youtube_video_id = session.get('youtube_video_id')
    
    if 'youtube_token' in session and not youtube_video_id:
        try:
            # Try to fetch active live broadcast ID
            headers = {'Authorization': f"Bearer {session['youtube_token']}"}
            r = requests.get(
                "https://www.googleapis.com/youtube/v3/liveBroadcasts?broadcastStatus=active&part=id",
                headers=headers
            )
            data = r.json()
            if 'items' in data and len(data['items']) > 0:
                youtube_video_id = data['items'][0]['id']
                session['youtube_video_id'] = youtube_video_id
        except Exception as e:
            app.logger.error(f"Error fetching YouTube video ID: {e}")

    return jsonify({
        'twitch': twitch_user,
        'youtube': youtube_user,
        'youtube_video_id': youtube_video_id
    })

@app.route('/api/update_title', methods=['POST'])
def api_update_title():
    data = request.json
    title = data.get('title')
    results = {}

    if 'twitch_token' in session:
        headers = {
            'Client-Id': TWITCH_CLIENT_ID,
            'Authorization': f"Bearer {session['twitch_token']}",
            'Content-Type': 'application/json'
        }
        url = f"https://api.twitch.tv/helix/channels?broadcaster_id={session['twitch_id']}"
        r = requests.patch(url, headers=headers, json={"title": title})
        results['twitch'] = r.status_code == 204

    if 'youtube_token' in session:
        vid = session.get('youtube_video_id')
        if vid:
            try:
                from google.oauth2.credentials import Credentials
                creds = Credentials(session['youtube_token'])
                youtube = build('youtube', 'v3', credentials=creds)
                
                # Fetch the broadcast to get the full snippet
                r = youtube.liveBroadcasts().list(id=vid, part='snippet').execute()
                if 'items' in r and len(r['items']) > 0:
                    broadcast = r['items'][0]
                    broadcast['snippet']['title'] = title
                    youtube.liveBroadcasts().update(part='snippet', body=broadcast).execute()
                    results['youtube'] = True
                else:
                    results['youtube'] = "Broadcast not found"
            except Exception as e:
                app.logger.error(f"YouTube title update error: {e}")
                results['youtube'] = str(e)
        else:
            results['youtube'] = "Active Video ID not found. Open Dashboard while live."

    return jsonify(results)

@app.route('/health', methods=['GET'])
def health_check():
    return Response('OK', status=200)

# --- TTS & Unified Chat ---

@app.route('/api/tts')
def api_tts():
    text = request.args.get('text', '')
    if not text:
        return "No text", 400
    
    voice = "en-US-GuyNeural"
    communicate = edge_tts.Communicate(text, voice)
    
    # We'll stream the audio back
    def generate():
        for chunk in communicate.stream_sync():
            if chunk["type"] == "audio":
                yield chunk["data"]
                
    return Response(generate(), mimetype="audio/mpeg")

# Background Chat Managers
twitch_bot = None
youtube_active = False

def start_chat_managers():
    global twitch_bot, youtube_active
    
    # Twitch Chat
    if 'twitch_token' in session and not twitch_bot:
        try:
            class Bot(commands.Bot):
                def __init__(self, token):
                    super().__init__(token=f"oauth:{token}", prefix='!', initial_channels=[session['twitch_user']])

                async def event_message(self, message):
                    if message.echo: return
                    socketio.emit('chat_msg', {
                        'platform': 'twitch',
                        'user': message.author.name,
                        'text': message.content
                    })

            twitch_bot = Bot(session['twitch_token'])
            threading.Thread(target=lambda: twitch_bot.run(), daemon=True).start()
        except Exception as e:
            app.logger.error(f"Twitch Chat Error: {e}")

    # YouTube Chat Polling
    if 'youtube_token' in session and session.get('youtube_video_id') and not youtube_active:
        youtube_active = True
        def poll_yt():
            from google.oauth2.credentials import Credentials
            creds = Credentials(session['youtube_token'])
            youtube = build('youtube', 'v3', credentials=creds)
            
            # Get Live Chat ID
            r = youtube.liveBroadcasts().list(id=session['youtube_video_id'], part='snippet').execute()
            if 'items' in r and len(r['items']) > 0:
                chat_id = r['items'][0]['snippet']['liveChatId']
                next_page_token = None
                while youtube_active:
                    try:
                        c = youtube.liveChatMessages().list(liveChatId=chat_id, part='snippet,authorDetails', pageToken=next_page_token).execute()
                        for item in c.get('items', []):
                            socketio.emit('chat_msg', {
                                'platform': 'youtube',
                                'user': item['authorDetails']['displayName'],
                                'text': item['snippet']['displayMessage']
                            })
                        next_page_token = c.get('nextPageToken')
                        time.sleep(max(1, c.get('pollingIntervalMillis', 1000) / 1000))
                    except:
                        time.sleep(5)
        threading.Thread(target=poll_yt, daemon=True).start()

@app.route('/api/start_chat')
def api_start_chat():
    start_chat_managers()
    return jsonify({'status': 'started'})

if __name__ == '__main__':
    socketio.run(app, host='127.0.0.1', port=8080, debug=False)
