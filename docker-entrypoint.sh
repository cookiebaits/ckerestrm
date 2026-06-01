#!/bin/bash

NGINX_TEMPLATE=/etc/nginx/nginx.conf.template
NGINX_CONF=/etc/nginx/nginx.conf
VALIDATOR_LOG=/tmp/validator.log
ENV_OK=0
MAX_WAIT_VALIDATOR_SECONDS=15 # Maximum seconds to wait for validator
VALIDATOR_CHECK_INTERVAL_SECONDS=0.2 # Check every 200ms

echo "Starting stream key validation server..."
gunicorn \
    --workers 1 \
    --bind 127.0.0.1:8080 \
    --log-level info \
    --access-logfile "$VALIDATOR_LOG" \
    --error-logfile "$VALIDATOR_LOG" \
    stream_validator:app &
VALIDATOR_PID=$!
echo "Validator PID: $VALIDATOR_PID"

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
    local platform_name="$1"
    local env_key_var="$2"
    local env_url_var="$3"
    local template_marker="$4"
    local push_url="${!env_url_var}"
    local key_value="${!env_key_var}"

    if [ -n "$key_value" ]; then
        if [ -z "$push_url" ]; then
             sed -i "s|#${template_marker}| |g" $TMP_TEMPLATE
        else
            local escaped_push="push ${push_url}${key_value};"
            sed -i "s|#${template_marker}|${escaped_push}|g" $TMP_TEMPLATE
            ENV_OK=1
       fi
    else
        sed -i "s|#${template_marker}| |g" $TMP_TEMPLATE
    fi
}

add_push "Youtube"    "YOUTUBE_KEY"    "YOUTUBE_URL"    "youtube"
add_push "Facebook"   "FACEBOOK_KEY"   "FACEBOOK_URL"   "facebook"
add_push "Instagram"  "INSTAGRAM_KEY"  "INSTAGRAM_URL"  "instagram"
add_push "TikTok"     "TIKTOK_KEY"     "TIKTOK_URL"     "tiktok"
add_push "Twitch"     "TWITCH_KEY"     "TWITCH_URL"     "twitch"
add_push "Kick"       "KICK_KEY"       "KICK_URL"       "kick"
add_push "X (Twitter)" "X_KEY"          "X_URL"          "x"
add_push "Trovo"      "TROVO_KEY"      "TROVO_URL"      "trovo"
add_push "RTMP1"      "RTMP1_KEY"      "RTMP1_URL"      "rtmp1"
add_push "RTMP2"      "RTMP2_KEY"      "RTMP2_URL"      "rtmp2"
add_push "RTMP3"      "RTMP3_KEY"      "RTMP3_URL"      "rtmp3"

export ACCEPTED_IP
export STATIC_TITLE
export AUTO_TITLE
export TWITCH_CLIENT_ID
export TWITCH_OAUTH_TOKEN
export TWITCH_BROADCASTER_ID
export APP_NAME

EXPORT_VARS=$(printf '${%s} ' $(env | cut -d= -f1))
envsubst "$EXPORT_VARS" < $TMP_TEMPLATE > $NGINX_CONF
rm $TMP_TEMPLATE

echo "Starting Stunnel..."
stunnel4 /etc/stunnel/stunnel.conf

echo "Starting Nginx..."
exec "$@"
