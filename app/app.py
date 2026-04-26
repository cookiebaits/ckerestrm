import os
import sqlite3
import subprocess
from flask import Flask, render_template, request, redirect, url_for, session, Response

app = Flask(__name__)
app.secret_key = os.urandom(24) # Ensure session security
DB_PATH = '/app/data/settings.db'
NGINX_CONF = '/etc/nginx/nginx.conf'
NGINX_TEMPLATE = '/etc/nginx/nginx.conf.template'

ADMIN_USERNAME = os.environ.get('ADMIN_USERNAME', 'admin')
ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD', 'password')

import urllib.parse
def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()

    # Try adding new columns if they don't exist (SQLite doesn't have IF NOT EXISTS for columns, so we catch the exception)
    try:
        conn.execute("ALTER TABLE settings ADD COLUMN transcode_active INTEGER DEFAULT 0")
        conn.execute("ALTER TABLE settings ADD COLUMN resolution TEXT DEFAULT '1080'")
        conn.execute("ALTER TABLE settings ADD COLUMN bitrate TEXT DEFAULT '6000k'")
    except sqlite3.OperationalError:
        pass

    conn.execute('''
        CREATE TABLE IF NOT EXISTS settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            master_stream_key TEXT DEFAULT 'default_key',
            transcode_active INTEGER DEFAULT 0,
            resolution TEXT DEFAULT '1080',
            bitrate TEXT DEFAULT '6000k',
            youtube_url TEXT DEFAULT 'rtmps://a.rtmps.youtube.com/live2/',
            youtube_key TEXT DEFAULT '',
            youtube_active INTEGER DEFAULT 0,
            twitch_url TEXT DEFAULT 'rtmps://ingest.global-contribute.live-video.net/app/',
            twitch_key TEXT DEFAULT '',
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
            master_stream_key,
            youtube_url, twitch_url, instagram_url, x_url, kick_url
        ) VALUES (?, ?, ?, ?, ?, ?)''', (
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
    push_directives = []
    platforms = ['youtube', 'twitch', 'instagram', 'x', 'kick']
    for p in platforms:
        if settings[f'{p}_active']:
            url = settings[f'{p}_url']
            key = settings[f'{p}_key']
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
            res = res_map.get(settings['resolution'], '1920x1080')
            bitrate = settings['bitrate']
            ffmpeg_exec = f"exec ffmpeg -i rtmp://127.0.0.1:1935/live/$name -c:v libx264 -preset veryfast -b:v {bitrate} -maxrate {bitrate} -bufsize {bitrate} -s {res} -c:a aac -b:a 128k -f flv rtmp://127.0.0.1:1935/out/$name;"
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
        subprocess.run(['nginx', '-s', 'reload'], check=True)
    except Exception as e:
        app.logger.error(f"Failed to reload nginx: {e}")

def init_db_and_conf():
    init_db()
    conn = get_db_connection()
    settings = conn.execute('SELECT * FROM settings ORDER BY id DESC LIMIT 1').fetchone()
    conn.close()

    if not settings:
        return

    stunnel_mappings = generate_stunnel_conf(settings)
    _build_nginx_conf(settings, stunnel_mappings)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        if request.form['username'] == ADMIN_USERNAME and request.form['password'] == ADMIN_PASSWORD:
            session['logged_in'] = True
            return redirect(url_for('dashboard'))
        return render_template('login.html', error='Invalid Credentials')
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.pop('logged_in', None)
    return redirect(url_for('login'))

@app.route('/')
def dashboard():
    if not session.get('logged_in'):
        return redirect(url_for('login'))

    conn = get_db_connection()
    settings = conn.execute('SELECT * FROM settings ORDER BY id DESC LIMIT 1').fetchone()
    conn.close()

    return render_template('index.html', settings=settings)

@app.route('/save', methods=['POST'])
def save():
    if not session.get('logged_in'):
        return redirect(url_for('login'))

    master_stream_key = request.form.get('master_stream_key', '')

    platforms = ['youtube', 'twitch', 'instagram', 'x', 'kick']
    updates = {'master_stream_key': master_stream_key}

    updates['transcode_active'] = 1 if request.form.get('transcode_active') else 0
    updates['resolution'] = request.form.get('resolution', '1080')
    updates['bitrate'] = request.form.get('bitrate', '6000k')

    for p in platforms:
        updates[f'{p}_url'] = request.form.get(f'{p}_url', '')
        updates[f'{p}_key'] = request.form.get(f'{p}_key', '')
        updates[f'{p}_active'] = 1 if request.form.get(f'{p}_active') else 0

    conn = get_db_connection()
    conn.execute('''
        UPDATE settings SET
            master_stream_key = ?,
            transcode_active = ?, resolution = ?, bitrate = ?,
            youtube_url = ?, youtube_key = ?, youtube_active = ?,
            twitch_url = ?, twitch_key = ?, twitch_active = ?,
            instagram_url = ?, instagram_key = ?, instagram_active = ?,
            x_url = ?, x_key = ?, x_active = ?,
            kick_url = ?, kick_key = ?, kick_active = ?
    ''', (
        updates['master_stream_key'],
        updates['transcode_active'], updates['resolution'], updates['bitrate'],
        updates['youtube_url'], updates['youtube_key'], updates['youtube_active'],
        updates['twitch_url'], updates['twitch_key'], updates['twitch_active'],
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
    raw_data = request.get_data(as_text=True)
    from urllib.parse import parse_qs
    parsed_data = parse_qs(raw_data)
    stream_key_attempt = parsed_data.get('name', [''])[0]

    conn = get_db_connection()
    settings = conn.execute('SELECT master_stream_key FROM settings ORDER BY id DESC LIMIT 1').fetchone()
    conn.close()

    if settings and stream_key_attempt == settings['master_stream_key']:
        return Response('OK', status=200)

    return Response('Invalid stream key', status=403)

@app.route('/regenerate_key', methods=['POST'])
def regenerate_key():
    if not session.get('logged_in'):
        return redirect(url_for('login'))

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

if __name__ == '__main__':
    init_db()
    generate_nginx_conf()
    app.run(host='0.0.0.0', port=8080)
