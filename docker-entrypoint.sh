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
# Use a temporary file for sed modifications
TMP_TEMPLATE=$(mktemp)
cp $NGINX_TEMPLATE $TMP_TEMPLATE

echo "Configuring Nginx push destinations..."

# Function to add push directive if key is present
add_push() {
    local platform_name="$1"
    local env_key_var="$2"
    local env_url_var="$3"
    local template_marker="$4"
    local push_url="${!env_url_var}" # Indirect variable expansion
    local key_value="${!env_key_var}" # Indirect variable expansion

    if [ -n "$key_value" ]; then
        if [ -z "$push_url" ]; then
             echo "Warning: ${platform_name} key (${env_key_var}) is set, but URL (${env_url_var}) is empty. Skipping push."
             sed -i "s|{{PUSH_${template_marker}}}||g" $TMP_TEMPLATE
        else
            echo "${platform_name} activated."
            # Correctly escape slashes in URLs for sed, use | as delimiter
            local escaped_push="push ${push_url}${key_value};"
            sed -i "s|{{PUSH_${template_marker}}}|${escaped_push}|g" $TMP_TEMPLATE
            ENV_OK=1
       fi
    else
        # Remove the placeholder if key is not set
        sed -i "s|{{PUSH_${template_marker}}}||g" $TMP_TEMPLATE
    fi
}

# Add pushes for each platform using the function
add_push "YouTube"     "YOUTUBE_KEY"    "YOUTUBE_URL"    "YOUTUBE"
add_push "Facebook"    "FACEBOOK_KEY"   "FACEBOOK_URL"   "FACEBOOK"
add_push "Instagram"   "INSTAGRAM_KEY"  "INSTAGRAM_URL"  "INSTAGRAM"
add_push "Twitch"      "TWITCH_KEY"     "TWITCH_URL"     "TWITCH"
add_push "Kick"        "KICK_KEY"       "KICK_URL"       "KICK"
add_push "X (Twitter)" "X_KEY"          "X_URL"          "X"
add_push "Trovo"       "TROVO_KEY"      "TROVO_URL"      "TROVO"
add_push "RTMP1"       "RTMP1_KEY"      "RTMP1_URL"      "RTMP1"
add_push "RTMP2"       "RTMP2_KEY"      "RTMP2_URL"      "RTMP2"
add_push "RTMP3"       "RTMP3_KEY"      "RTMP3_URL"      "RTMP3"

# Manual TikTok push (only if dynamic is not set)
if [ -z "$TIKTOK_SL_TOKEN" ]; then
    add_push "TikTok"  "TIKTOK_KEY"     "TIKTOK_URL"     "TIKTOK"
else
    sed -i "s|{{PUSH_TIKTOK}}||g" $TMP_TEMPLATE
fi

# Vertical pushes
add_push "V-YouTube"   "V_YOUTUBE_KEY"   "V_YOUTUBE_URL"   "V_YOUTUBE"
add_push "V-Facebook"  "V_FACEBOOK_KEY"  "V_FACEBOOK_URL"  "V_FACEBOOK"
add_push "V-Instagram" "V_INSTAGRAM_KEY" "V_INSTAGRAM_URL" "V_INSTAGRAM"
add_push "V-Twitch"    "V_TWITCH_KEY"    "V_TWITCH_URL"    "V_TWITCH"
add_push "V-Kick"      "V_KICK_KEY"      "V_KICK_URL"      "V_KICK"
add_push "V-X"         "V_X_KEY"         "V_X_URL"         "V_X"
add_push "V-Trovo"     "V_TROVO_KEY"     "V_TROVO_URL"     "V_TROVO"
add_push "V-RTMP1"     "V_RTMP1_KEY"     "V_RTMP1_URL"     "V_RTMP1"

# Manual Vertical TikTok push (only if dynamic is not set)
if [ -z "$TIKTOK_SL_TOKEN" ]; then
    add_push "V-TikTok" "V_TIKTOK_KEY"    "V_TIKTOK_URL"    "V_TIKTOK"
else
    sed -i "s|{{PUSH_V_TIKTOK}}||g" $TMP_TEMPLATE
fi

# TikTok Dynamic Key Relay (Vertical Only)
if [ -n "$TIKTOK_SL_TOKEN" ]; then
    echo "TikTok Dynamic Key Relay (Vertical) activated."
    sed -i "s|{{PUSH_V_TIKTOK_DYN}}|push rtmp://127.0.0.1:1935/tiktok_relay/vertical;|g" $TMP_TEMPLATE
    ENV_OK=1
else
    sed -i "s|{{PUSH_V_TIKTOK_DYN}}||g" $TMP_TEMPLATE
fi

if [ $ENV_OK -eq 1 ]; then
    echo "Generating final Nginx configuration..."
    # Use envsubst for any remaining ${VAR} placeholders (though we added most via sed now)
    # Define the list of variables envsubst should consider
    EXPORT_VARS=$(printf '${%s} ' $(env | cut -d= -f1))
    envsubst "$EXPORT_VARS" < $TMP_TEMPLATE > $NGINX_CONF
    rm $TMP_TEMPLATE # Clean up temp file
else
    echo "Warning: No destination stream keys provided. Nginx will start, but no streams will be pushed, and no incoming streams will be accepted."
    # Still generate config from template, it will just have no push directives
    # Define the list of variables envsubst should consider even if no ENV_OK
    EXPORT_VARS=$(printf '${%s} ' $(env | cut -d= -f1))
    envsubst "$EXPORT_VARS" < $TMP_TEMPLATE > $NGINX_CONF
    rm $TMP_TEMPLATE
fi

# --- TLS / Let's Encrypt Logic ---
# This section dynamically generates an Nginx HTTPS server block if a domain and email are provided.
# It checks for existing certificates and attempts to obtain new ones if they are missing.
HTTPS_SERVER_BLOCK=""
if [ -n "$SERVER_DOMAIN" ] && [ -n "$LETSENCRYPT_EMAIL" ]; then
    if [ -f "/etc/letsencrypt/live/$SERVER_DOMAIN/fullchain.pem" ]; then
        echo "SSL Certificates found for $SERVER_DOMAIN"
        HTTPS_SERVER_BLOCK="server {
    listen 443 ssl;
    server_name $SERVER_DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$SERVER_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$SERVER_DOMAIN/privkey.pem;

    # High-security SSL settings
    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_ciphers TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_128_GCM_SHA256;
    ssl_ecdh_curve secp384r1;
    ssl_session_timeout  10m;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;

    location /stat {
        rtmp_stat all;
        rtmp_stat_stylesheet stat.xsl;
    }

    location /stat.xsl {
        root /usr/local/nginx/html;
    }

    location /login {
        proxy_pass http://127.0.0.1:8080;
    }

    location /callback {
        proxy_pass http://127.0.0.1:8080;
    }

    location /api {
        proxy_pass http://127.0.0.1:8080;
    }

    location /socket.io {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
    }

    location / {
        root /usr/local/nginx/html;
        index index.html;
    }
}"
    else
        echo "SSL Certificates NOT found. Certbot will attempt to obtain them in the background."
        (
            sleep 15
            echo "Certbot: Attempting to obtain certificates for $SERVER_DOMAIN..."
            certbot certonly --webroot -w /var/www/certbot --non-interactive --agree-tos --email "$LETSENCRYPT_EMAIL" -d "$SERVER_DOMAIN"
            if [ $? -eq 0 ]; then
                echo "Certbot: Success! Reloading to apply changes (Container may need a manual restart if config doesn't auto-update)."
                # We can't easily regenerate the template from here without restarting, 
                # but certbot might have already modified the config if we used --nginx.
                # However, we used --webroot for stability.
            else
                echo "Certbot: Failed to obtain certificates."
            fi
        ) &
    fi
fi

# Apply the dynamic HTTPS block to a separate config file included by nginx.conf.template
# This prevents Nginx from failing to start if the HTTPS block is empty.
echo "$HTTPS_SERVER_BLOCK" > /etc/nginx/https.conf

# --- Certbot Auto-Renewal Loop ---
# Runs in the background every 12 hours to ensure certificates are always valid.
# Calls 'nginx -s reload' after renewal to apply new certificates without downtime.
(
    while true; do
        sleep 12h
        echo "Certbot: Checking for certificate renewal..."
        certbot renew --quiet
        nginx -s reload
    done
) &


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

echo "Starting Nginx..."
exec "$@" # Execute the CMD from Dockerfile (nginx -g 'daemon off;')
