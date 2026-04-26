#!/bin/bash
set -e

NGINX_TEMPLATE=/etc/nginx/nginx.conf.template
NGINX_CONF=/etc/nginx/nginx.conf

echo "Initializing database and Nginx configuration..."
cd /app && python3 -c 'from app import init_db_and_conf; init_db_and_conf()'

echo "Starting Web Dashboard and Validator..."
# Start Gunicorn in the background to run the Flask app
gunicorn \
    --workers 1 \
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
