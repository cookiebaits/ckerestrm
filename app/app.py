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

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db_connection()
    conn.execute('''
        CREATE TABLE IF NOT EXISTS settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            master_stream_key TEXT DEFAULT 'default_key',
            youtube_url TEXT DEFAULT 'rtmp://x.rtmp.youtube.com/live2/',
            youtube_key TEXT DEFAULT '',
            youtube_active INTEGER DEFAULT 0,
            twitch_url TEXT DEFAULT 'rtmp://ingest.global-contribute.live-video.net/app/',
            twitch_key TEXT DEFAULT '',
            twitch_active INTEGER DEFAULT 0,
            instagram_url TEXT DEFAULT 'rtmp://127.0.0.1:19351/rtmp/',
            instagram_key TEXT DEFAULT '',
            instagram_active INTEGER DEFAULT 0,
            x_url TEXT DEFAULT 'rtmp://127.0.0.1:19354/x/',
            x_key TEXT DEFAULT '',
            x_active INTEGER DEFAULT 0,
            kick_url TEXT DEFAULT 'rtmp://127.0.0.1:19353/kick/',
            kick_key TEXT DEFAULT '',
            kick_active INTEGER DEFAULT 0
        )
    ''')
    row = conn.execute('SELECT * FROM settings').fetchone()
    if row is None:
        conn.execute('INSERT INTO settings (master_stream_key) VALUES (?)', ('default_key',))
    conn.commit()
    conn.close()

def generate_nginx_conf():
    conn = get_db_connection()
    settings = conn.execute('SELECT * FROM settings ORDER BY id DESC LIMIT 1').fetchone()
    conn.close()

    if not settings:
        return

    push_directives = []
    platforms = ['youtube', 'twitch', 'instagram', 'x', 'kick']
    for p in platforms:
        if settings[f'{p}_active']:
            url = settings[f'{p}_url']
            key = settings[f'{p}_key']
            if url and key:
                push_directives.append(f"            push {url}{key};")

    push_block = "\n".join(push_directives)

    try:
        with open(NGINX_TEMPLATE, 'r') as f:
            template = f.read()

        new_conf = template.replace('# PUSH_DIRECTIVES', push_block)

        with open(NGINX_CONF, 'w') as f:
            f.write(new_conf)

        # Reload Nginx
        subprocess.run(['nginx', '-s', 'reload'], check=True)
    except Exception as e:
        app.logger.error(f"Failed to generate nginx config or reload: {e}")

def init_db_and_conf():
    init_db()
    # Generate config without reloading nginx (used by entrypoint)
    conn = get_db_connection()
    settings = conn.execute('SELECT * FROM settings ORDER BY id DESC LIMIT 1').fetchone()
    conn.close()

    if not settings:
        return

    push_directives = []
    platforms = ['youtube', 'twitch', 'instagram', 'x', 'kick']
    for p in platforms:
        if settings[f'{p}_active']:
            url = settings[f'{p}_url']
            key = settings[f'{p}_key']
            if url and key:
                push_directives.append(f"            push {url}{key};")

    push_block = "\n".join(push_directives)

    try:
        with open(NGINX_TEMPLATE, 'r') as f:
            template = f.read()
        new_conf = template.replace('# PUSH_DIRECTIVES', push_block)
        with open(NGINX_CONF, 'w') as f:
            f.write(new_conf)
    except Exception as e:
        app.logger.error(f"Failed to generate initial nginx config: {e}")

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

    for p in platforms:
        updates[f'{p}_url'] = request.form.get(f'{p}_url', '')
        updates[f'{p}_key'] = request.form.get(f'{p}_key', '')
        updates[f'{p}_active'] = 1 if request.form.get(f'{p}_active') else 0

    conn = get_db_connection()
    conn.execute('''
        UPDATE settings SET
            master_stream_key = ?,
            youtube_url = ?, youtube_key = ?, youtube_active = ?,
            twitch_url = ?, twitch_key = ?, twitch_active = ?,
            instagram_url = ?, instagram_key = ?, instagram_active = ?,
            x_url = ?, x_key = ?, x_active = ?,
            kick_url = ?, kick_key = ?, kick_active = ?
    ''', (
        updates['master_stream_key'],
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

@app.route('/health')
def health():
    return "OK"

if __name__ == '__main__':
    init_db()
    generate_nginx_conf()
    app.run(host='0.0.0.0', port=8080)
