#!/bin/bash
set -e

NGINX_TEMPLATE=/etc/nginx/nginx.conf.template
NGINX_CONF=/etc/nginx/nginx.conf
VALIDATOR_LOG=/tmp/validator.log
ENV_OK=0
MAX_WAIT_VALIDATOR_SECONDS=15
VALIDATOR_CHECK_INTERVAL_SECONDS=0.2

# Ensure directories for stunnel and sessions
mkdir -p /var/run/stunnel4
mkdir -p /app/data/sessions
chown -R stunnel4:stunnel4 /var/run/stunnel4 /var/log/stunnel4 || true

echo "Starting stream key validation server..."
gunicorn \
    --workers 1 \
    --bind 127.0.0.1:8080 \
    --log-level info \
    --access-logfile "$VALIDATOR_LOG" \
    --error-logfile "$VALIDATOR_LOG" \
    stream_validator:app &
VALIDATOR_PID=$!

echo "Waiting for validator to be ready..."
VALIDATOR_READY=0
MAX_ATTEMPTS=$(awk -v max_wait="$MAX_WAIT_VALIDATOR_SECONDS" -v interval="$VALIDATOR_CHECK_INTERVAL_SECONDS" 'BEGIN {printf "%.0f", max_wait / interval}')
CURRENT_ATTEMPT=0

while [ $CURRENT_ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if kill -0 $VALIDATOR_PID 2>/dev/null && curl --fail --silent --connect-timeout 0.1 --max-time 0.4 http://127.0.0.1:8080/health > /dev/null; then
        echo "Validator is running and responding."
        VALIDATOR_READY=1
        break
    fi
    sleep $VALIDATOR_CHECK_INTERVAL_SECONDS
    CURRENT_ATTEMPT=$((CURRENT_ATTEMPT + 1))
done

if [ $VALIDATOR_READY -eq 0 ]; then
    echo "ERROR: Stream key validator failed to start."
    cat "$VALIDATOR_LOG"
    exit 1
fi

TMP_TEMPLATE=$(mktemp)
cp $NGINX_TEMPLATE $TMP_TEMPLATE

echo "Configuring Nginx push destinations..."

add_push() {
    local env_key_var="$1"
    local env_url_var="$2"
    local template_marker="$3"
    local push_url="${!env_url_var}"
    local key_value="${!env_key_var}"

    if [ -n "$key_value" ] && [ -n "$push_url" ]; then
        local escaped_push="push ${push_url}${key_value};"
        sed -i "s|#${template_marker}|${escaped_push}|g" $TMP_TEMPLATE
        ENV_OK=1
    else
        sed -i "s|#${template_marker}| |g" $TMP_TEMPLATE
    fi
}

# Horizontal
add_push "YOUTUBE_KEY"   "YOUTUBE_URL"   "youtube"
add_push "FACEBOOK_KEY"  "FACEBOOK_URL"  "facebook"
add_push "INSTAGRAM_KEY" "INSTAGRAM_URL" "instagram"
add_push "TIKTOK_KEY"    "TIKTOK_URL"    "tiktok"
add_push "KICK_KEY"      "KICK_URL"      "kick"
add_push "X_KEY"         "X_URL"         "x"
add_push "TWITCH_KEY"    "TWITCH_URL"    "twitch"
add_push "RTMP1_KEY"     "RTMP1_URL"     "rtmp1"
add_push "TROVO_KEY"     "TROVO_URL"     "trovo"

# Vertical
add_push "V_YOUTUBE_KEY"   "V_YOUTUBE_URL"   "v_youtube"
add_push "V_FACEBOOK_KEY"  "V_FACEBOOK_URL"  "v_facebook"
add_push "V_INSTAGRAM_KEY" "V_INSTAGRAM_URL" "v_instagram"
add_push "V_TIKTOK_KEY"    "V_TIKTOK_URL"    "v_tiktok"
add_push "V_KICK_KEY"      "V_KICK_URL"      "v_kick"
add_push "V_X_KEY"         "V_X_URL"         "v_x"
add_push "V_TWITCH_KEY"    "V_TWITCH_URL"    "v_twitch"
add_push "V_RTMP1_KEY"     "V_RTMP1_URL"     "v_rtmp1"
add_push "V_TROVO_KEY"     "V_TROVO_URL"     "v_trovo"

export ACCEPTED_IP
export APP_NAME
export CHUNK_SIZE

EXPORT_VARS=$(printf '${%s} ' $(env | cut -d= -f1))
envsubst "$EXPORT_VARS" < $TMP_TEMPLATE > $NGINX_CONF
rm $TMP_TEMPLATE

echo "Starting Stunnel..."
stunnel4 /etc/stunnel/stunnel.conf

echo "Starting Nginx..."
exec "$@"
