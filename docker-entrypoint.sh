#!/bin/bash
set -e

NGINX_TEMPLATE=/etc/nginx/nginx.conf.template
NGINX_CONF=/etc/nginx/nginx.conf

echo "Ensuring Stunnel SSL certificate exists for RTMPS..."
mkdir -p /etc/stunnel/ssl
if [ ! -f /etc/stunnel/ssl/stunnel.pem ]; then
    echo "Generating self-signed SSL certificate for Stunnel..."
    openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost" \
        -keyout /etc/stunnel/ssl/stunnel.pem  -out /etc/stunnel/ssl/stunnel.pem
    chmod 600 /etc/stunnel/ssl/stunnel.pem
fi

echo "Initializing database and Nginx configuration..."
cd /app && python3 -c 'from app import init_db_and_conf; init_db_and_conf()'

echo "Starting Web Dashboard and Validator..."
# Start Gunicorn in the background to run the Flask app
gunicorn \
    --workers 3 \
    --bind 0.0.0.0:8080 \
    --log-level info \
    --chdir /app \
    app:app &
DASHBOARD_PID=$!

# Wait briefly to let the dashboard generate the config
sleep 2

echo "Starting Stunnel..."
# Start stunnel in the background
stunnel4 /etc/stunnel/stunnel.conf

echo "Starting Nginx..."
exec "$@" # Execute the CMD from Dockerfile (nginx -g 'daemon off;')
