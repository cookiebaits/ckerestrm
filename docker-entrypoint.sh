#!/bin/bash
set -e

NGINX_TEMPLATE=/etc/nginx/nginx.conf.template
NGINX_CONF=/etc/nginx/nginx.conf
VALIDATOR_LOG=/tmp/validator.log
ENV_OK=0
MAX_WAIT_VALIDATOR_SECONDS=15 # Maximum seconds to wait for validator
VALIDATOR_CHECK_INTERVAL_SECONDS=0.2 # Check every 200ms

# !!! Removed MASTER_STREAM_KEY check !!!
# The container will now start without it, relying on destination keys for validation.

echo "Starting stream key validation server..."
# Start Gunicorn in the background to run the Flask app
# -w 1: Use a single worker process (sufficient for this task)
# -b 127.0.0.1:8080: Bind to the same internal host and port
# --log-level info: Set the log level
# stream_validator:app: Point to the 'app' object in your python file
# Use eventlet worker for SocketIO support
gunicorn \
    --worker-class eventlet \
    --workers 1 \
    --bind 127.0.0.1:8080 \
    --log-level info \
    --access-logfile "$VALIDATOR_LOG" \
    --error-logfile "$VALIDATOR_LOG" \
    stream_validator:app &
VALIDATOR_PID=$!
echo "Validator PID: $VALIDATOR_PID"

# --- Robust Validator Check ---
echo "Waiting for validator to be ready..."
VALIDATOR_READY=0
# Calculate maximum attempts based on total wait time and interval
# Use awk for floating point division and ceiling to integer
MAX_ATTEMPTS=$(awk -v max_wait="$MAX_WAIT_VALIDATOR_SECONDS" -v interval="$VALIDATOR_CHECK_INTERVAL_SECONDS" 'BEGIN {printf "%.0f", max_wait / interval}')
CURRENT_ATTEMPT=0

while [ $CURRENT_ATTEMPT -lt $MAX_ATTEMPTS ]; do
    # Check if process exists AND responds to health check
    # Added --connect-timeout and reduced --max-time for curl
    if kill -0 $VALIDATOR_PID 2>/dev/null && curl --fail --silent --connect-timeout 0.1 --max-time 0.4 http://127.0.0.1:8080/health > /dev/null; then
        echo "Validator is running and responding."
        VALIDATOR_READY=1
        break
    fi

    # Log approximately every second to avoid excessive verbosity
    # (e.g., if interval is 0.2s, log every 5 attempts)
    LOG_THROTTLE_ATTEMPTS=$(awk -v interval="$VALIDATOR_CHECK_INTERVAL_SECONDS" 'BEGIN {printf "%.0f", 1 / interval}')
    if [ $((CURRENT_ATTEMPT % LOG_THROTTLE_ATTEMPTS)) -eq 0 ] || [ $CURRENT_ATTEMPT -eq 0 ]; then
        ELAPSED_SECONDS_APPROX=$(awk -v current_attempt="$CURRENT_ATTEMPT" -v interval="$VALIDATOR_CHECK_INTERVAL_SECONDS" 'BEGIN {printf "%.1f", current_attempt * interval}')
        echo "Validator not ready yet, waiting... (${ELAPSED_SECONDS_APPROX}s / ${MAX_WAIT_VALIDATOR_SECONDS}s)"
    fi
    sleep $VALIDATOR_CHECK_INTERVAL_SECONDS
    CURRENT_ATTEMPT=$((CURRENT_ATTEMPT + 1))
done

if [ $VALIDATOR_READY -eq 0 ]; then
    ELAPSED_SECONDS_FINAL=$(awk -v current_attempt="$CURRENT_ATTEMPT" -v interval="$VALIDATOR_CHECK_INTERVAL_SECONDS" 'BEGIN {printf "%.1f", current_attempt * interval}')
    echo "ERROR: Stream key validator failed to start or respond within ${ELAPSED_SECONDS_FINAL}s (max ${MAX_WAIT_VALIDATOR_SECONDS}s)."
    echo "Check validator logs:"
    cat "$VALIDATOR_LOG"
    exit 1
fi
# --- End Validator Check ---


# --- Configure Nginx based on Environment Variables ---
echo "Configuring Nginx push destinations..."

# Initialize push variables to empty
PLATFORMS="YOUTUBE FACEBOOK INSTAGRAM TIKTOK KICK X TWITCH TROVO RTMP1 RTMP2 RTMP3"
V_PLATFORMS="YOUTUBE FACEBOOK INSTAGRAM TIKTOK KICK X TWITCH TROVO RTMP1"

for p in $PLATFORMS; do
    export "PUSH_$p"=""
done
for p in $V_PLATFORMS; do
    export "PUSH_V_$p"=""
done
export PUSH_V_TIKTOK_DYN=""

# --- Input Sanitization ---
# Sanitize variables that will be injected into Nginx configuration
# to prevent configuration injection attacks.
sanitize_nginx() {
    local val="$1"
    # Remove semicolons, newlines, and quotes
    echo "$val" | tr -d ';\n\r"'"'"
}

# Function to set push directive variable if key is present
set_push_var() {
    local platform_name="$1"
    local env_key_var="$2"
    local env_url_var="$3"
    local export_var_name="PUSH_$4"
    local push_url="${!env_url_var}" # Indirect variable expansion
    local key_value="${!env_key_var}" # Indirect variable expansion

    if [ -n "$key_value" ]; then
        key_value=$(sanitize_nginx "$key_value")
        push_url=$(sanitize_nginx "$push_url")
        if [ -z "$push_url" ]; then
             echo "Warning: ${platform_name} key (${env_key_var}) is set, but URL (${env_url_var}) is empty. Skipping push."
             export "$export_var_name"=""
        else
            echo "${platform_name} activated."
            export "$export_var_name"="push ${push_url}${key_value};"
            ENV_OK=1
       fi
    else
        export "$export_var_name"=""
    fi
}

# Horizontal pushes
set_push_var "YouTube"     "YOUTUBE_KEY"    "YOUTUBE_URL"    "YOUTUBE"
set_push_var "Facebook"    "FACEBOOK_KEY"   "FACEBOOK_URL"   "FACEBOOK"
set_push_var "Instagram"   "INSTAGRAM_KEY"  "INSTAGRAM_URL"  "INSTAGRAM"
set_push_var "Twitch"      "TWITCH_KEY"     "TWITCH_URL"     "TWITCH"
set_push_var "Kick"        "KICK_KEY"       "KICK_URL"       "KICK"
set_push_var "X (Twitter)" "X_KEY"          "X_URL"          "X"
set_push_var "Trovo"       "TROVO_KEY"      "TROVO_URL"      "TROVO"
set_push_var "RTMP1"       "RTMP1_KEY"      "RTMP1_URL"      "RTMP1"
set_push_var "RTMP2"       "RTMP2_KEY"      "RTMP2_URL"      "RTMP2"
set_push_var "RTMP3"       "RTMP3_KEY"      "RTMP3_URL"      "RTMP3"

# Manual TikTok push (only if dynamic is not set)
if [ -z "$TIKTOK_SL_TOKEN" ]; then
    set_push_var "TikTok"  "TIKTOK_KEY"     "TIKTOK_URL"     "TIKTOK"
fi

# Vertical pushes
set_push_var "V-YouTube"   "V_YOUTUBE_KEY"   "V_YOUTUBE_URL"   "V_YOUTUBE"
set_push_var "V-Facebook"  "V_FACEBOOK_KEY"  "V_FACEBOOK_URL"  "V_FACEBOOK"
set_push_var "V-Instagram" "V_INSTAGRAM_KEY" "V_INSTAGRAM_URL" "V_INSTAGRAM"
set_push_var "V-Twitch"    "V_TWITCH_KEY"    "V_TWITCH_URL"    "V_TWITCH"
set_push_var "V-Kick"      "V_KICK_KEY"      "V_KICK_URL"      "V_KICK"
set_push_var "V-X"         "V_X_KEY"         "V_X_URL"         "V_X"
set_push_var "V-Trovo"     "V_TROVO_KEY"     "V_TROVO_URL"     "V_TROVO"
set_push_var "V-RTMP1"     "V_RTMP1_KEY"     "V_RTMP1_URL"     "V_RTMP1"

# Manual Vertical TikTok push (only if dynamic is not set)
if [ -z "$TIKTOK_SL_TOKEN" ]; then
    set_push_var "V-TikTok" "V_TIKTOK_KEY"    "V_TIKTOK_URL"    "V_TIKTOK"
fi

# TikTok Dynamic Key Relay (Vertical Only)
if [ -n "$TIKTOK_SL_TOKEN" ]; then
    echo "TikTok Dynamic Key Relay (Vertical) activated."
    export PUSH_V_TIKTOK_DYN="push rtmp://127.0.0.1:1935/tiktok_relay/vertical;"
    ENV_OK=1
fi

if [ $ENV_OK -eq 0 ]; then
    echo "Warning: No destination stream keys provided. Nginx will start, but no streams will be pushed, and no incoming streams will be accepted."
fi

echo "Generating final Nginx configuration..."
# Use envsubst to generate the config. It's safe against special characters in keys.
# We explicitly define the variables to substitute to avoid accidentally wiping out unrelated ${...} in future edits.
APP_NAME=$(sanitize_nginx "$APP_NAME")
CHUNK_SIZE=$(sanitize_nginx "$CHUNK_SIZE")

SUBST_VARS="\$APP_NAME \$CHUNK_SIZE \$PUSH_YOUTUBE \$PUSH_FACEBOOK \$PUSH_INSTAGRAM \$PUSH_TIKTOK \$PUSH_KICK \$PUSH_X \$PUSH_TWITCH \$PUSH_TROVO \$PUSH_RTMP1 \$PUSH_RTMP2 \$PUSH_RTMP3 \$PUSH_V_YOUTUBE \$PUSH_V_FACEBOOK \$PUSH_V_INSTAGRAM \$PUSH_V_TIKTOK \$PUSH_V_TIKTOK_DYN \$PUSH_V_KICK \$PUSH_V_X \$PUSH_V_TWITCH \$PUSH_V_TROVO \$PUSH_V_RTMP1 \$FACEBOOK_URL \$FACEBOOK_KEY \$TWITCH_URL \$TWITCH_KEY \$YOUTUBE_URL \$YOUTUBE_KEY \$KICK_URL \$KICK_KEY \$X_URL \$X_KEY"
envsubst "$SUBST_VARS" < $NGINX_TEMPLATE > $NGINX_CONF
chmod 600 $NGINX_CONF

# --- TLS / HTTPS ---
# Inbound SSL is handled by a host-level reverse proxy.

# --- Basic Auth for Stats & Dashboard ---
if [ -f "/etc/nginx/.htpasswd" ]; then
    echo "Enabling Basic Auth for Dashboard and Stats..."
    echo "auth_basic \"Restricted Access\";" > /etc/nginx/auth.conf
    echo "auth_basic_user_file /etc/nginx/.htpasswd;" >> /etc/nginx/auth.conf
else
    echo "" > /etc/nginx/auth.conf
fi
chmod 600 /etc/nginx/auth.conf

# --- RTMP IP Access Restrictions ---
touch /etc/nginx/rtmp_access.conf
if [ -n "$ACCEPTED_IP" ]; then
    echo "Configuring RTMP IP Whitelist (Defense in Depth)..."
    # Convert comma-separated list to Nginx allow directives
    echo "$ACCEPTED_IP" | tr ',' '\n' | while read -r ip; do
        if [ -n "$ip" ]; then
            echo "allow publish $ip;" >> /etc/nginx/rtmp_access.conf
        fi
    done
    echo "deny publish all;" >> /etc/nginx/rtmp_access.conf
else
    echo "" > /etc/nginx/rtmp_access.conf
fi
chmod 600 /etc/nginx/rtmp_access.conf



# Debug output if requested
if [ -n "${DEBUG}" ]; then
    echo "--- Final Nginx Configuration (${NGINX_CONF}) ---"
    cat $NGINX_CONF
    echo "-------------------------------------------------"
fi

echo "Starting Stunnel..."
# Start stunnel in the background
stunnel4 /etc/stunnel/stunnel.conf

# --- NOALBS Integration ---
if [ "$NOALBS_ENABLED" == "true" ]; then
    if [ -z "$OBS_WS_HOST" ]; then
        echo "ERROR: NOALBS is enabled but OBS_WS_HOST is not set. NOALBS will not start."
    else
        echo "Starting NOALBS Switcher..."
        # Launch in background and check if it stays running for a few seconds
        python3 /app/noalbs/noalbs.py > /tmp/noalbs.log 2>&1 &
        NOALBS_PID=$!
        (
            sleep 3
            if ! kill -0 $NOALBS_PID 2>/dev/null; then
                echo "ERROR: NOALBS Switcher failed to start. Check /tmp/noalbs.log for details."
                cat /tmp/noalbs.log
            else
                echo "NOALBS Switcher is running (PID: $NOALBS_PID)."
            fi
        ) &
    fi
fi

echo "Checking Nginx configuration syntax..."
nginx -t

echo "Starting Nginx..."
exec "$@" # Execute the CMD from Dockerfile (nginx -g 'daemon off;')
