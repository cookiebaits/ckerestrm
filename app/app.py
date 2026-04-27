import os
import sqlite3
import subprocess
from flask import Flask, render_template, request, redirect, url_for, session, Response
from werkzeug.middleware.proxy_fix import ProxyFix

app = Flask(__name__)
app.wsgi_app = ProxyFix(app.wsgi_app, x_proto=1, x_host=1)

SECRET_FILE = '/app/data/secret.key'
if os.path.exists(SECRET_FILE):
    with open(SECRET_FILE, 'rb') as f:
        app.secret_key = f.read()
else:
    app.secret_key = os.urandom(24)
    # create dir if running tests outside container
    os.makedirs('/app/data', exist_ok=True)
    with open(SECRET_FILE, 'wb') as f:
        f.write(app.secret_key)

DB_PATH = '/app/data/settings.db'
NGINX_CONF = '/etc/nginx/nginx.conf'
NGINX_TEMPLATE = '/etc/nginx/nginx.conf.template'

ADMIN_USERNAME = os.environ.get('ADMIN_USERNAME', 'admin')
ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD', 'P4sswerd')

import urllib.parse
def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()

    # Try adding new columns if they don't exist (SQLite doesn't have IF NOT EXISTS for columns, so we catch the exception)
    columns_to_add = [
        "ALTER TABLE settings ADD COLUMN transcode_active INTEGER DEFAULT 0",
        "ALTER TABLE settings ADD COLUMN resolution TEXT DEFAULT '1080'",
        "ALTER TABLE settings ADD COLUMN bitrate TEXT DEFAULT '6000k'",
        "ALTER TABLE settings ADD COLUMN framerate TEXT DEFAULT '60'",
        "ALTER TABLE settings ADD COLUMN video_preset TEXT DEFAULT 'veryfast'",
        "ALTER TABLE settings ADD COLUMN service_enabled INTEGER DEFAULT 0",
        "ALTER TABLE settings ADD COLUMN admin_username TEXT DEFAULT 'admin'",
        "ALTER TABLE settings ADD COLUMN admin_password TEXT DEFAULT 'P4sswerd'",
        "ALTER TABLE settings ADD COLUMN twitch_client_id TEXT DEFAULT ''",
        "ALTER TABLE settings ADD COLUMN twitch_client_secret TEXT DEFAULT ''",
        "ALTER TABLE settings ADD COLUMN youtube_client_id TEXT DEFAULT ''",
        "ALTER TABLE settings ADD COLUMN youtube_client_secret TEXT DEFAULT ''"
    ]

    for query in columns_to_add:
        try:
            conn.execute(query)
        except sqlite3.OperationalError:
            pass

    conn.execute('''
        CREATE TABLE IF NOT EXISTS settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            admin_username TEXT DEFAULT 'admin',
            admin_password TEXT DEFAULT 'P4sswerd',
            master_stream_key TEXT DEFAULT 'default_key',
            service_enabled INTEGER DEFAULT 0,
            transcode_active INTEGER DEFAULT 1,
            resolution TEXT DEFAULT '1080',
            bitrate TEXT DEFAULT '4500k',
            framerate TEXT DEFAULT '50',
            video_preset TEXT DEFAULT 'faster',
            youtube_url TEXT DEFAULT 'rtmps://a.rtmps.youtube.com/live2/',
            youtube_key TEXT DEFAULT '',
            youtube_client_id TEXT DEFAULT '',
            youtube_client_secret TEXT DEFAULT '',
            youtube_active INTEGER DEFAULT 0,
            twitch_url TEXT DEFAULT 'rtmps://ingest.global-contribute.live-video.net/app/',
            twitch_key TEXT DEFAULT '',
            twitch_client_id TEXT DEFAULT '',
            twitch_client_secret TEXT DEFAULT '',
            twitch_active INTEGER DEFAULT 0,
            instagram_url TEXT DEFAULT 'rtmps://live-upload.instagram.com/rtmp/',
            instagram_key TEXT DEFAULT '',
            instagram_active INTEGER DEFAULT 0,
            x_url TEXT DEFAULT 'rtmps://va.pscp.tv/x/',
            x_key TEXT DEFAULT '',
            x_active INTEGER DEFAULT 0,
            kick_url TEXT DEFAULT 'rtmps://fa723fc1b171.global-contribute.live-video.net/kick/',
            kick_key TEXT DEFAULT '',
            kick_active INTEGER DEFAULT 0
        )
    ''')
    row = conn.execute('SELECT * FROM settings').fetchone()
    if row is None:
        conn.execute('''INSERT INTO settings (
            admin_username, admin_password,
            master_stream_key,
            youtube_url, twitch_url, instagram_url, x_url, kick_url
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)''', (
            ADMIN_USERNAME, ADMIN_PASSWORD,
            'default_key',
            'rtmps://a.rtmps.youtube.com/live2/',
            'rtmps://ingest.global-contribute.live-video.net/app/',
            'rtmps://live-upload.instagram.com/rtmp/',
            'rtmps://va.pscp.tv/x/',
            'rtmps://fa723fc1b171.global-contribute.live-video.net/kick/'
        ))
    conn.commit()
    conn.close()

def generate_stunnel_conf(settings):
    platforms = ['youtube', 'twitch', 'instagram', 'x', 'kick']
    base_port = 19360
    stunnel_mappings = {}

    for idx, p in enumerate(platforms):
        if settings[f'{p}_active']:
            url = settings[f'{p}_url']
            if url.startswith('rtmps://'):
                parsed = urllib.parse.urlparse(url)
                host = parsed.hostname
                port = parsed.port if parsed.port else 443
                local_port = base_port + idx

                # Write stunnel config for this platform
                conf_content = f"[{p}-live]\nclient=yes\naccept=127.0.0.1:{local_port}\nconnect={host}:{port}\n"
                try:
                    with open(f"/etc/stunnel/conf.d/{p}.conf", "w") as f:
                        f.write(conf_content)
                except Exception as e:
                    app.logger.error(f"Failed to write stunnel conf for {p}: {e}")

                # Store mapping so Nginx can push to it
                path = parsed.path.lstrip('/')
                stunnel_mappings[p] = f"rtmp://127.0.0.1:{local_port}/{path}"

    try:
        # Reload stunnel4 via SIGHUP
        subprocess.run(['pkill', '-HUP', 'stunnel4'], check=False)
    except Exception:
        pass

    return stunnel_mappings

def _build_nginx_conf(settings, stunnel_mappings):
    import re
    def sanitize(s):
        if not s: return ''
        # Remove semicolons, newlines, quotes to prevent Nginx config injection
        return re.sub(r'[;\n\r\'"]', '', s)

    push_directives = []
    platforms = ['youtube', 'twitch', 'instagram', 'x', 'kick']

    for p in platforms:
        if settings[f'{p}_active']:
            url = sanitize(settings[f'{p}_url'])
            key = sanitize(settings[f'{p}_key'])
            if not url or not key:
                continue

            if url.startswith('rtmps://') and p in stunnel_mappings:
                actual_url = stunnel_mappings[p]
                if not actual_url.endswith('/'):
                    actual_url += '/'
                push_directives.append(f"            push {actual_url}{key};")
            else:
                if not url.endswith('/'):
                    url += '/'
                push_directives.append(f"            push {url}{key};")

    push_block = "\n".join(push_directives)

    try:
        with open(NGINX_TEMPLATE, 'r') as f:
            template = f.read()

        if settings['transcode_active']:
            new_conf = template.replace('# PUSH_DIRECTIVES', "")
            new_conf = new_conf.replace('# OUT_PUSH_DIRECTIVES', push_block)

            res_map = {'1080': '1920x1080', '720': '1280x720'}
            res = sanitize(res_map.get(settings['resolution'], '1920x1080'))
            bitrate = sanitize(settings['bitrate'])
            fps = sanitize(settings.get('framerate', '60'))
            preset = sanitize(settings.get('video_preset', 'veryfast'))

            ffmpeg_exec = f"exec ffmpeg -i rtmp://127.0.0.1:1935/live/$name -c:v libx264 -preset {preset} -b:v {bitrate} -maxrate {bitrate} -bufsize {bitrate} -s {res} -r {fps} -c:a aac -b:a 128k -f flv rtmp://127.0.0.1:1935/out/$name;"
            new_conf = new_conf.replace('# FFMPEG_EXEC', ffmpeg_exec)
        else:
            new_conf = template.replace('# PUSH_DIRECTIVES', push_block)
            new_conf = new_conf.replace('# OUT_PUSH_DIRECTIVES', "")
            new_conf = new_conf.replace('# FFMPEG_EXEC', "")

        with open(NGINX_CONF, 'w') as f:
            f.write(new_conf)

    except Exception as e:
        app.logger.error(f"Failed to generate nginx config: {e}")

def generate_nginx_conf():
    conn = get_db_connection()
    settings = conn.execute('SELECT * FROM settings ORDER BY id DESC LIMIT 1').fetchone()
    conn.close()

    if not settings:
        return

    stunnel_mappings = generate_stunnel_conf(settings)
    _build_nginx_conf(settings, stunnel_mappings)

    try:
        # First check if Nginx is actually running (in case it crashed or this is first boot manually triggered)
        if subprocess.run(['pgrep', 'nginx'], stdout=subprocess.DEVNULL).returncode != 0:
            app.logger.info("Nginx not running, starting it...")
            subprocess.run(['nginx'], check=True)
        else:
            subprocess.run(['nginx', '-s', 'reload'], check=True)
    except Exception as e:
        app.logger.error(f"Failed to reload/start nginx: {e}")

def init_db_and_conf():
    init_db()
    conn = get_db_connection()
    settings = conn.execute('SELECT * FROM settings ORDER BY id DESC LIMIT 1').fetchone()
    conn.close()

    if not settings:
        return

    stunnel_mappings = generate_stunnel_conf(settings)
    _build_nginx_conf(settings, stunnel_mappings)

import secrets

def generate_csrf_token():
    if '_csrf_token' not in session:
        session['_csrf_token'] = secrets.token_hex(32)
    return session['_csrf_token']

app.jinja_env.globals['csrf_token'] = generate_csrf_token

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username_attempt = request.form['username']
        password_attempt = request.form['password']

        conn = get_db_connection()
        settings = conn.execute('SELECT admin_username, admin_password FROM settings ORDER BY id DESC LIMIT 1').fetchone()
        conn.close()

        if settings and username_attempt == settings['admin_username'] and password_attempt == settings['admin_password']:
            session['logged_in'] = True
            return redirect(url_for('dashboard'))
        return render_template('login.html', error='Invalid Credentials')
    return render_template('login.html')

@app.route('/update_account', methods=['POST'])
def update_account():
    if not session.get('logged_in'):
        return redirect(url_for('login'))

    token = session.get('_csrf_token', None)
    if not token or token != request.form.get('_csrf_token'):
        return Response('CSRF validation failed', status=403)

    new_username = request.form.get('admin_username')
    new_password = request.form.get('admin_password')

    if new_username and new_password:
        conn = get_db_connection()
        conn.execute('UPDATE settings SET admin_username = ?, admin_password = ?', (new_username, new_password))
        conn.commit()
        conn.close()

    return redirect(url_for('dashboard'))

@app.route('/logout')
def logout():
    session.pop('logged_in', None)
    return redirect(url_for('login'))

import requests

@app.route('/oauth/twitch/login')
def twitch_login():
    if not session.get('logged_in'):
        return redirect(url_for('login'))

    conn = get_db_connection()
    settings = conn.execute('SELECT twitch_client_id FROM settings ORDER BY id DESC LIMIT 1').fetchone()
    conn.close()

    if not settings or not settings['twitch_client_id']:
        return "Twitch Client ID not configured.", 400

    client_id = settings['twitch_client_id']
    redirect_uri = url_for('twitch_callback', _external=True)
    # Twitch OAuth scope required to read stream key is channel:read:stream_key
    auth_url = f"https://id.twitch.tv/oauth2/authorize?client_id={client_id}&redirect_uri={redirect_uri}&response_type=code&scope=channel:read:stream_key"
    return redirect(auth_url)

@app.route('/oauth/twitch/callback')
def twitch_callback():
    if not session.get('logged_in'):
        return redirect(url_for('login'))

    code = request.args.get('code')
    if not code:
        return "Missing authorization code.", 400

    conn = get_db_connection()
    settings = conn.execute('SELECT twitch_client_id, twitch_client_secret FROM settings ORDER BY id DESC LIMIT 1').fetchone()

    if not settings or not settings['twitch_client_id'] or not settings['twitch_client_secret']:
        conn.close()
        return "Twitch OAuth credentials missing.", 400

    client_id = settings['twitch_client_id']
    client_secret = settings['twitch_client_secret']
    redirect_uri = url_for('twitch_callback', _external=True)

    # Exchange code for token
    token_url = "https://id.twitch.tv/oauth2/token"
    token_data = {
        'client_id': client_id,
        'client_secret': client_secret,
        'code': code,
        'grant_type': 'authorization_code',
        'redirect_uri': redirect_uri
    }
    r = requests.post(token_url, data=token_data)
    if r.status_code != 200:
        conn.close()
        return f"Failed to get token: {r.text}", 400

    token_json = r.json()
    access_token = token_json.get('access_token')

    # Get user id (broadcaster id)
    headers = {
        'Authorization': f'Bearer {access_token}',
        'Client-Id': client_id
    }
    user_r = requests.get('https://api.twitch.tv/helix/users', headers=headers)
    if user_r.status_code != 200:
        conn.close()
        return f"Failed to get user id: {user_r.text}", 400

    user_data = user_r.json()
    if not user_data['data']:
        conn.close()
        return "No user found.", 400
    broadcaster_id = user_data['data'][0]['id']

    # Get stream key
    stream_key_r = requests.get(f'https://api.twitch.tv/helix/streams/key?broadcaster_id={broadcaster_id}', headers=headers)
    if stream_key_r.status_code != 200:
        conn.close()
        return f"Failed to get stream key: {stream_key_r.text}", 400

    stream_key_data = stream_key_r.json()
    if not stream_key_data['data']:
        conn.close()
        return "No stream key found.", 400

    stream_key = stream_key_data['data'][0]['stream_key']

    # Update DB
    conn.execute('UPDATE settings SET twitch_key = ?', (stream_key,))
    conn.commit()
    conn.close()

    generate_nginx_conf()
    return redirect(url_for('dashboard'))

INGEST_SERVERS = {
    'youtube': [
        ('Primary YouTube Ingest', 'rtmps://a.rtmps.youtube.com/live2/'),
        ('Backup YouTube Ingest', 'rtmps://b.rtmps.youtube.com/live2/')
    ],
    'twitch': [
        ('US East (Ashburn, VA)', 'rtmps://iad03.contribute.live-video.net/app/'),
        ('US East (New York, NY)', 'rtmps://jfk.contribute.live-video.net/app/'),
        ('US Central (Dallas, TX)', 'rtmps://dfw.contribute.live-video.net/app/'),
        ('US West (San Francisco, CA)', 'rtmps://sfo.contribute.live-video.net/app/'),
        ('US West (Seattle, WA)', 'rtmps://sea.contribute.live-video.net/app/'),
        ('EU (London, UK)', 'rtmps://lhr03.contribute.live-video.net/app/'),
        ('EU (Frankfurt, UK)', 'rtmps://fra02.contribute.live-video.net/app/'),
        ('Global Auto-Routing', 'rtmps://ingest.global-contribute.live-video.net/app/')
    ]
}

@app.route('/')
def dashboard():
    if not session.get('logged_in'):
        return redirect(url_for('login'))

    conn = get_db_connection()
    settings = conn.execute('SELECT * FROM settings ORDER BY id DESC LIMIT 1').fetchone()
    conn.close()

    return render_template('index.html', settings=settings, ingest_servers=INGEST_SERVERS)

@app.route('/save', methods=['POST'])
def save():
    if not session.get('logged_in'):
        return redirect(url_for('login'))

    token = session.get('_csrf_token', None)
    if not token or token != request.form.get('_csrf_token'):
        return Response('CSRF validation failed', status=403)

    master_stream_key = request.form.get('master_stream_key', '')

    platforms = ['youtube', 'twitch', 'instagram', 'x', 'kick']
    updates = {'master_stream_key': master_stream_key}

    updates['service_enabled'] = 1 if request.form.get('service_enabled') else 0
    updates['transcode_active'] = 1 if request.form.get('transcode_active') else 0
    updates['resolution'] = request.form.get('resolution', '1080')
    updates['bitrate'] = request.form.get('bitrate', '4500k')
    updates['framerate'] = request.form.get('framerate', '50')
    updates['video_preset'] = request.form.get('video_preset', 'faster')

    updates['twitch_client_id'] = request.form.get('twitch_client_id', '')
    updates['twitch_client_secret'] = request.form.get('twitch_client_secret', '')

    for p in platforms:
        updates[f'{p}_url'] = request.form.get(f'{p}_url', '')
        updates[f'{p}_key'] = request.form.get(f'{p}_key', '')
        updates[f'{p}_active'] = 1 if request.form.get(f'{p}_active') else 0

    conn = get_db_connection()
    conn.execute('''
        UPDATE settings SET
            master_stream_key = ?,
            service_enabled = ?,
            transcode_active = ?, resolution = ?, bitrate = ?,
            framerate = ?, video_preset = ?,
            youtube_url = ?, youtube_key = ?, youtube_active = ?,
            twitch_url = ?, twitch_key = ?, twitch_active = ?,
            twitch_client_id = ?, twitch_client_secret = ?,
            instagram_url = ?, instagram_key = ?, instagram_active = ?,
            x_url = ?, x_key = ?, x_active = ?,
            kick_url = ?, kick_key = ?, kick_active = ?
    ''', (
        updates['master_stream_key'],
        updates['service_enabled'],
        updates['transcode_active'], updates['resolution'], updates['bitrate'],
        updates['framerate'], updates['video_preset'],
        updates['youtube_url'], updates['youtube_key'], updates['youtube_active'],
        updates['twitch_url'], updates['twitch_key'], updates['twitch_active'],
        updates['twitch_client_id'], updates['twitch_client_secret'],
        updates['instagram_url'], updates['instagram_key'], updates['instagram_active'],
        updates['x_url'], updates['x_key'], updates['x_active'],
        updates['kick_url'], updates['kick_key'], updates['kick_active']
    ))
    conn.commit()
    conn.close()

    generate_nginx_conf()

    return redirect(url_for('dashboard'))

@app.route('/validate', methods=['POST'])
def validate():
    stream_key_attempt = request.form.get('name', '')

    conn = get_db_connection()
    settings = conn.execute('SELECT master_stream_key, service_enabled FROM settings ORDER BY id DESC LIMIT 1').fetchone()
    conn.close()

    if not settings or not settings['service_enabled']:
        return Response('Service is offline', status=403)

    if stream_key_attempt == settings['master_stream_key']:
        return Response('OK', status=200)

    return Response('Invalid stream key', status=403)

@app.route('/regenerate_key', methods=['POST'])
def regenerate_key():
    if not session.get('logged_in'):
        return redirect(url_for('login'))

    token = session.get('_csrf_token', None)
    if not token or token != request.form.get('_csrf_token'):
        return Response('CSRF validation failed', status=403)

    import secrets
    import string
    alphabet = string.ascii_letters + string.digits
    new_key = "live_" + ''.join(secrets.choice(alphabet) for i in range(24))

    conn = get_db_connection()
    conn.execute('UPDATE settings SET master_stream_key = ?', (new_key,))
    conn.commit()
    conn.close()

    return redirect(url_for('dashboard'))

@app.route('/health')
def health():
    return "OK"

@app.route('/api/status')
def api_status():
    if not session.get('logged_in'):
        return Response('Unauthorized', status=401)

    status = {
        'nginx': False,
        'stunnel': False,
        'ping': 'error'
    }

    # Check processes
    try:
        if subprocess.run(['pgrep', 'nginx'], stdout=subprocess.DEVNULL).returncode == 0:
            status['nginx'] = True
    except Exception: pass

    try:
        if subprocess.run(['pgrep', 'stunnel4'], stdout=subprocess.DEVNULL).returncode == 0:
            status['stunnel'] = True
    except Exception: pass

    from flask import jsonify
    return jsonify(status)

@app.route('/api/ping_platforms')
def api_ping_platforms():
    if not session.get('logged_in'):
        return Response('Unauthorized', status=401)

    import socket
    import time

    results = {'twitch': 'Error', 'youtube': 'Error'}

    def measure_tcp_latency(host, port=443, timeout=3):
        try:
            start_time = time.time()
            with socket.create_connection((host, port), timeout=timeout):
                pass
            end_time = time.time()
            return f"{(end_time - start_time) * 1000:.1f} ms"
        except Exception:
            return "Timeout/Blocked"

    results['twitch'] = measure_tcp_latency('live.twitch.tv')
    results['youtube'] = measure_tcp_latency('a.rtmps.youtube.com')

    from flask import jsonify
    return jsonify(results)

@app.route('/api/speedtest')
def api_speedtest():
    if not session.get('logged_in'):
        return Response('Unauthorized', status=401)

    try:
        import json
        # Run official Ookla speedtest binary and parse JSON output
        # The license acceptance is required on first run, so we pass the flags
        res = subprocess.check_output(['speedtest', '--accept-license', '--accept-gdpr', '-f', 'json'], stderr=subprocess.STDOUT).decode('utf-8')

        parsed = json.loads(res)
        data = {
            'Ping': f"{parsed.get('ping', {}).get('latency', 0):.2f} ms",
            'Download': f"{(parsed.get('download', {}).get('bandwidth', 0) * 8 / 1000000):.2f} Mbit/s",
            'Upload': f"{(parsed.get('upload', {}).get('bandwidth', 0) * 8 / 1000000):.2f} Mbit/s"
        }

        from flask import jsonify
        return jsonify(data)
    except Exception as e:
        app.logger.error(f"Speedtest failed: {e}")
        return Response('Error running speedtest', status=500)

if __name__ == '__main__':
    init_db()
    generate_nginx_conf()
    app.run(host='0.0.0.0', port=8080)
