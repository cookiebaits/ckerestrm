#!/bin/bash
# install.sh - Menu style configuration and installation for PrismRTMPS
# Ensure script is run with bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
YOUTUBE_URL="rtmp://x.rtmp.youtube.com/live2/"
YOUTUBE_KEY=""
FACEBOOK_URL="rtmp://127.0.0.1:19350/rtmp/"
FACEBOOK_KEY=""
INSTAGRAM_URL="rtmp://127.0.0.1:19351/rtmp/"
INSTAGRAM_KEY=""
TIKTOK_URL="rtmp://127.0.0.1:19358/s_v/"
TIKTOK_KEY=""
TWITCH_URL="rtmp://127.0.0.1:19353/app/"
TWITCH_KEY=""
KICK_URL="rtmp://127.0.0.1:19356/kick/"
KICK_KEY=""
X_URL="rtmp://127.0.0.1:19354/x/"
X_KEY=""
TROVO_URL="rtmp://livepush.trovo.live/live/"
TROVO_KEY=""
RTMP1_URL=""
RTMP1_KEY=""

# Vertical Defaults
V_YOUTUBE_URL=""
V_YOUTUBE_KEY=""
V_TWITCH_URL=""
V_TWITCH_KEY=""
V_KICK_URL=""
V_KICK_KEY=""
V_TIKTOK_URL=""
V_TIKTOK_KEY=""
V_FACEBOOK_URL=""
V_FACEBOOK_KEY=""
V_INSTAGRAM_URL=""
V_INSTAGRAM_KEY=""
V_X_URL=""
V_X_KEY=""
V_TROVO_URL=""
V_TROVO_KEY=""
V_RTMP1_URL=""
V_RTMP1_KEY=""

OBS_KEY=""
APP_NAME="live"
ACCEPTED_IP=""
SERVER_DOMAIN=""
CHUNK_SIZE="8192"

TWITCH_CLIENT_ID=""
TWITCH_CLIENT_SECRET=""
YOUTUBE_CLIENT_ID=""
YOUTUBE_CLIENT_SECRET=""

CONFIG_FILE="rtmp_config.env"

# Shared Server Lists
YOUTUBE_SERVERS=(
    "rtmp://x.rtmp.youtube.com/live2/|Primary (RTMP)"
    "rtmp://b.rtmp.youtube.com/live2?backup=1|Backup (RTMP)"
    "rtmp://127.0.0.1:19355/live2/|Secure Primary (RTMPS)"
    "rtmp://127.0.0.1:19357/live2?backup=1|Secure Backup (RTMPS)"
)

TWITCH_SERVERS=(
    "rtmp://ingest.global-contribute.live-video.net/app/|Global Auto (RTMP)"
    "rtmp://127.0.0.1:19353/app/|Secure Global (RTMPS)"
    "rtmp://iad05.contribute.live-video.net/app/|US East: Ashburn"
    "rtmp://jfk05.contribute.live-video.net/app/|US East: New York"
    "rtmp://sjc05.contribute.live-video.net/app/|US West: San Jose"
    "rtmp://sea01.contribute.live-video.net/app/|US West: Seattle"
    "rtmp://fra02.contribute.live-video.net/app/|EU: Frankfurt"
    "rtmp://lhr03.contribute.live-video.net/app/|EU: London"
    "rtmp://tyo01.contribute.live-video.net/app/|Asia: Tokyo"
)

KICK_SERVERS=(
    "rtmp://live.kick.com/app/|Standard (RTMP)"
    "rtmp://127.0.0.1:19356/kick/|Secure (RTMPS)"
)

# Load saved configuration if it exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

save_config() {
    cat <<ENV_EOF > "$CONFIG_FILE"
YOUTUBE_URL="$YOUTUBE_URL"
YOUTUBE_KEY="$YOUTUBE_KEY"
FACEBOOK_URL="$FACEBOOK_URL"
FACEBOOK_KEY="$FACEBOOK_KEY"
INSTAGRAM_URL="$INSTAGRAM_URL"
INSTAGRAM_KEY="$INSTAGRAM_KEY"
TIKTOK_URL="$TIKTOK_URL"
TIKTOK_KEY="$TIKTOK_KEY"
TWITCH_URL="$TWITCH_URL"
TWITCH_KEY="$TWITCH_KEY"
KICK_URL="$KICK_URL"
KICK_KEY="$KICK_KEY"
X_URL="$X_URL"
X_KEY="$X_KEY"
TROVO_URL="$TROVO_URL"
TROVO_KEY="$TROVO_KEY"
RTMP1_URL="$RTMP1_URL"
RTMP1_KEY="$RTMP1_KEY"
V_YOUTUBE_URL="$V_YOUTUBE_URL"
V_YOUTUBE_KEY="$V_YOUTUBE_KEY"
V_TWITCH_URL="$V_TWITCH_URL"
V_TWITCH_KEY="$V_TWITCH_KEY"
V_KICK_URL="$V_KICK_URL"
V_KICK_KEY="$V_KICK_KEY"
V_TIKTOK_URL="$V_TIKTOK_URL"
V_TIKTOK_KEY="$V_TIKTOK_KEY"
V_FACEBOOK_URL="$V_FACEBOOK_URL"
V_FACEBOOK_KEY="$V_FACEBOOK_KEY"
V_INSTAGRAM_URL="$V_INSTAGRAM_URL"
V_INSTAGRAM_KEY="$V_INSTAGRAM_KEY"
V_X_URL="$V_X_URL"
V_X_KEY="$V_X_KEY"
V_TROVO_URL="$V_TROVO_URL"
V_TROVO_KEY="$V_TROVO_KEY"
V_RTMP1_URL="$V_RTMP1_URL"
V_RTMP1_KEY="$V_RTMP1_KEY"
OBS_KEY="$OBS_KEY"
APP_NAME="$APP_NAME"
ACCEPTED_IP="$ACCEPTED_IP"
SERVER_DOMAIN="$SERVER_DOMAIN"
CHUNK_SIZE="$CHUNK_SIZE"
TWITCH_CLIENT_ID="$TWITCH_CLIENT_ID"
TWITCH_CLIENT_SECRET="$TWITCH_CLIENT_SECRET"
YOUTUBE_CLIENT_ID="$YOUTUBE_CLIENT_ID"
YOUTUBE_CLIENT_SECRET="$YOUTUBE_CLIENT_SECRET"
ENV_EOF
    echo -e "${GREEN}Configuration saved to $CONFIG_FILE${NC}"
}

prompt_for_key() {
    local platform=$1
    local var_name=$2
    local current_value=${!var_name}

    echo -e "Enter Stream Key for ${YELLOW}$platform${NC} (Type 'disable' to remove key, or leave blank to keep current: ${current_value:-None}): "
    read -r input

    if [ "$input" == "disable" ] || [ "$input" == "DISABLE" ]; then
        printf -v "$var_name" "%s" ""
        save_config
        echo -e "${GREEN}Disabled stream to $platform.${NC}"
        sleep 1
    elif [ ! -z "$input" ]; then
        printf -v "$var_name" "%s" "$input"
        save_config
    fi
}

select_server() {
    local platform=$1
    local var_url=$2
    local -n server_list=$3
    local current_url=${!var_url}

    echo -e "Select ${YELLOW}$platform${NC} Server:"
    local i=1
    for item in "${server_list[@]}"; do
        local name="${item#*|}"
        echo "  $i) $name"
        ((i++))
    done
    echo "  $i) Custom URL"
    echo -e "Option (Current: $current_url): \c"
    read -r opt

    if [[ "$opt" =~ ^[0-9]+$ ]] && [ "$opt" -ge 1 ] && [ "$opt" -lt "$i" ]; then
        local selected="${server_list[$((opt-1))]}"
        printf -v "$var_url" "%s" "${selected%|*}"
    elif [ "$opt" -eq "$i" ]; then
        echo -e "Enter Custom URL: "
        read -r custom_url
        if [ ! -z "$custom_url" ]; then
            printf -v "$var_url" "%s" "$custom_url"
        fi
    fi
    save_config
}

configure_platform() {
    local name=$1
    local key_var=$2
    local url_var=$3
    local server_list_name=$4

    prompt_for_key "$name" "$key_var"
    if [ ! -z "${!key_var}" ]; then
        select_server "$name" "$url_var" "$server_list_name"
    fi
}

configure_keys() {
    while true; do
        clear
        echo -e "${GREEN}=== Configure Horizontal Stream Keys ===${NC}"
        echo "1) YouTube (Current: ${YOUTUBE_KEY:-None})"
        echo "2) Twitch (Current: ${TWITCH_KEY:-None})"
        echo "3) Kick (Current: ${KICK_KEY:-None})"
        echo "4) TikTok (Current: ${TIKTOK_KEY:-None})"
        echo "5) Facebook (Current: ${FACEBOOK_KEY:-None})"
        echo "6) Instagram (Current: ${INSTAGRAM_KEY:-None})"
        echo "7) X (Twitter) (Current: ${X_KEY:-None})"
        echo "8) Trovo (Current: ${TROVO_KEY:-None})"
        echo "9) Custom RTMP (Current URL: ${RTMP1_URL:-None})"
        echo "10) Back to Main Menu"
        echo -e "Select an option: \c"
        read -r choice

        case $choice in
            1) configure_platform "YouTube" "YOUTUBE_KEY" "YOUTUBE_URL" YOUTUBE_SERVERS ;;
            2) configure_platform "Twitch" "TWITCH_KEY" "TWITCH_URL" TWITCH_SERVERS ;;
            3) configure_platform "Kick" "KICK_KEY" "KICK_URL" KICK_SERVERS ;;
            4) prompt_for_key "TikTok" "TIKTOK_KEY" ;;
            5) prompt_for_key "Facebook" "FACEBOOK_KEY" ;;
            6) prompt_for_key "Instagram" "INSTAGRAM_KEY" ;;
            7) prompt_for_key "X (Twitter)" "X_KEY" ;;
            8) prompt_for_key "Trovo" "TROVO_KEY" ;;
            9)
               echo -e "Enter Custom RTMP Server URL (Current: $RTMP1_URL): "
               read -r c_url
               if [ ! -z "$c_url" ]; then RTMP1_URL="$c_url"; save_config; fi
               prompt_for_key "Custom RTMP Key" "RTMP1_KEY"
               ;;
            10) break ;;
            *) echo -e "${RED}Invalid option${NC}" ; sleep 1 ;;
        esac
    done
}

configure_vertical_keys() {
    while true; do
        clear
        echo -e "${GREEN}=== Configure Vertical Stream Keys ===${NC}"
        echo "1) YouTube (Current: ${V_YOUTUBE_KEY:-None})"
        echo "2) Twitch (Current: ${V_TWITCH_KEY:-None})"
        echo "3) Kick (Current: ${V_KICK_KEY:-None})"
        echo "4) TikTok (Current: ${V_TIKTOK_KEY:-None})"
        echo "5) Facebook (Current: ${V_FACEBOOK_KEY:-None})"
        echo "6) Instagram (Current: ${V_INSTAGRAM_KEY:-None})"
        echo "7) X (Twitter) (Current: ${V_X_KEY:-None})"
        echo "8) Trovo (Current: ${V_TROVO_KEY:-None})"
        echo "9) Custom RTMP (Current URL: ${V_RTMP1_URL:-None})"
        echo "10) Back to Main Menu"
        echo -e "Select an option: \c"
        read -r choice

        case $choice in
            1) configure_platform "YouTube Vertical" "V_YOUTUBE_KEY" "V_YOUTUBE_URL" YOUTUBE_SERVERS ;;
            2) configure_platform "Twitch Vertical" "V_TWITCH_KEY" "V_TWITCH_URL" TWITCH_SERVERS ;;
            3) configure_platform "Kick Vertical" "V_KICK_KEY" "V_KICK_URL" KICK_SERVERS ;;
            4) prompt_for_key "TikTok Vertical" "V_TIKTOK_KEY" ;;
            5) prompt_for_key "Facebook Vertical" "V_FACEBOOK_KEY" ;;
            6) prompt_for_key "Instagram Vertical" "V_INSTAGRAM_KEY" ;;
            7) prompt_for_key "X Vertical" "V_X_KEY" ;;
            8) prompt_for_key "Trovo Vertical" "V_TROVO_KEY" ;;
            9)
               echo -e "Enter Custom RTMP Vertical Server URL (Current: $V_RTMP1_URL): "
               read -r c_url
               if [ ! -z "$c_url" ]; then V_RTMP1_URL="$c_url"; save_config; fi
               prompt_for_key "Custom RTMP Vertical Key" "V_RTMP1_KEY"
               ;;
            10) break ;;
            *) echo -e "${RED}Invalid option${NC}" ; sleep 1 ;;
        esac
    done
}

configure_domain() {
    clear
    echo -e "${GREEN}=== Domain / Reverse Proxy Configuration ===${NC}"
    echo -e "Current Domain: ${SERVER_DOMAIN:-None (Using IP)}"
    echo -e "Enter your domain or Cloudflare reverse proxy (e.g. stream.yourdomain.com):"
    read -r dom_input
    if [ "$dom_input" == "disable" ]; then SERVER_DOMAIN=""; else SERVER_DOMAIN="$dom_input"; fi
    save_config
    sleep 1
}

configure_whitelist() {
    clear
    echo -e "${GREEN}=== IP Whitelist Configuration ===${NC}"
    echo -e "Current Accepted IP: ${ACCEPTED_IP:-None (Allow All)}"
    echo -e "Enter IP address to whitelist (type 'disable' to allow all):"
    read -r ip_input
    if [ "$ip_input" == "disable" ]; then ACCEPTED_IP=""; else ACCEPTED_IP="$ip_input"; fi
    save_config
    sleep 1
}

configure_api() {
    while true; do
        clear
        echo -e "${GREEN}=== Configure API / OAuth (Twitch/YouTube) ===${NC}"
        echo "1) Twitch Client ID (Current: ${TWITCH_CLIENT_ID:-None})"
        echo "2) Twitch Client Secret (Current: ${TWITCH_CLIENT_SECRET:-None})"
        echo "3) YouTube Client ID (Current: ${YOUTUBE_CLIENT_ID:-None})"
        echo "4) YouTube Client Secret (Current: ${YOUTUBE_CLIENT_SECRET:-None})"
        echo "5) Back to Main Menu"
        echo -e "Select an option: \c"
        read -r choice
        case $choice in
            1) echo -n "Enter Twitch Client ID: "; read -r TWITCH_CLIENT_ID; save_config ;;
            2) echo -n "Enter Twitch Client Secret: "; read -r TWITCH_CLIENT_SECRET; save_config ;;
            3) echo -n "Enter YouTube Client ID: "; read -r YOUTUBE_CLIENT_ID; save_config ;;
            4) echo -n "Enter YouTube Client Secret: "; read -r YOUTUBE_CLIENT_SECRET; save_config ;;
            5) break ;;
        esac
    done
}

configure_obs() {
    clear
    echo -e "${GREEN}=== OBS Configuration ===${NC}"
    SERVER_IP=$(curl -4 -s ifconfig.me || echo "<your_server_ip>")
    DISPLAY_HOST=${SERVER_DOMAIN:-$SERVER_IP}
    echo -e "  ${YELLOW}Horizontal URL:${NC} rtmp://${DISPLAY_HOST}:1935/${APP_NAME}"
    echo -e "  ${YELLOW}Vertical URL:${NC}   rtmp://${DISPLAY_HOST}:1935/vertical"
    echo -e "  ${YELLOW}Combined Chat:${NC} http://${DISPLAY_HOST}:8081/chat.html"
    echo ""
    echo -e "Enter Custom OBS Security Key (Optional):"
    read -r obs_input
    if [ ! -z "$obs_input" ]; then OBS_KEY="$obs_input"; save_config; fi
    sleep 2
}

build_and_run() {
    # Auto-apply horizontal keys to vertical if empty
    [ -z "$V_YOUTUBE_KEY" ] && V_YOUTUBE_KEY="$YOUTUBE_KEY" && V_YOUTUBE_URL="$YOUTUBE_URL"
    [ -z "$V_TWITCH_KEY" ] && V_TWITCH_KEY="$TWITCH_KEY" && V_TWITCH_URL="$TWITCH_URL"
    [ -z "$V_KICK_KEY" ] && V_KICK_KEY="$KICK_KEY" && V_KICK_URL="$KICK_URL"
    [ -z "$V_TIKTOK_KEY" ] && V_TIKTOK_KEY="$TIKTOK_KEY" && V_TIKTOK_URL="$TIKTOK_URL"
    [ -z "$V_FACEBOOK_KEY" ] && V_FACEBOOK_KEY="$FACEBOOK_KEY" && V_FACEBOOK_URL="$FACEBOOK_URL"
    [ -z "$V_INSTAGRAM_KEY" ] && V_INSTAGRAM_KEY="$INSTAGRAM_KEY" && V_INSTAGRAM_URL="$INSTAGRAM_URL"
    [ -z "$V_X_KEY" ] && V_X_KEY="$X_KEY" && V_X_URL="$X_URL"
    [ -z "$V_TROVO_KEY" ] && V_TROVO_KEY="$TROVO_KEY" && V_TROVO_URL="$TROVO_URL"
    [ -z "$V_RTMP1_KEY" ] && V_RTMP1_KEY="$RTMP1_KEY" && V_RTMP1_URL="$RTMP1_URL"

    # Auto-select different servers for vertical if horizontal is the same
    # For YouTube
    if [ "$YOUTUBE_URL" == "$V_YOUTUBE_URL" ] && [ ! -z "$YOUTUBE_KEY" ]; then
        if [[ "$YOUTUBE_URL" == *"127.0.0.1:19355"* ]]; then
             V_YOUTUBE_URL="rtmp://127.0.0.1:19357/live2?backup=1"
        elif [[ "$YOUTUBE_URL" == *"x.rtmp.youtube.com"* ]]; then
             V_YOUTUBE_URL="rtmp://b.rtmp.youtube.com/live2?backup=1"
        else
             V_YOUTUBE_URL="rtmp://127.0.0.1:19355/live2/"
        fi
    fi
    # For Twitch
    if [ "$TWITCH_URL" == "$V_TWITCH_URL" ] && [ ! -z "$TWITCH_KEY" ]; then
         # Use a different region or secure port
         if [[ "$TWITCH_URL" == *"127.0.0.1:19353"* ]]; then
              V_TWITCH_URL="rtmp://iad05.contribute.live-video.net/app/"
         else
              V_TWITCH_URL="rtmp://127.0.0.1:19353/app/"
         fi
    fi

    echo -e "${GREEN}Building Docker Image (Debian Trixie)...${NC}"
    docker build -t prism-rtmps .

    docker stop prism-rtmps 2>/dev/null || true
    docker rm prism-rtmps 2>/dev/null || true

    docker run -d --name prism-rtmps \
        -p 1935:1935 -p 8081:8081 \
        --restart unless-stopped \
        -v $(pwd)/data:/app/data \
        --env-file <(env | grep -E '^(YOUTUBE|TWITCH|KICK|TIKTOK|FACEBOOK|INSTAGRAM|X|TROVO|RTMP1|V_|OBS|APP|ACCEPTED|SERVER|CHUNK|TWITCH_CLIENT|YOUTUBE_CLIENT)') \
        prism-rtmps

    echo -e "${GREEN}Server Started!${NC}"
    sleep 2
}

install_docker() {
    if ! command -v docker &> /dev/null; then
        curl -4 -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        rm get-docker.sh
    fi
}

SERVER_IP=$(curl -4 -s ifconfig.me || echo "<your_server_ip>")

while true; do
    clear
    DISPLAY_HOST=${SERVER_DOMAIN:-$SERVER_IP}
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}     PrismRTMPS Quick Installer      ${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${YELLOW}Quick Reference:${NC}"
    echo -e "  Horizontal Ingest: rtmp://${DISPLAY_HOST}:1935/${APP_NAME}"
    echo -e "  Vertical Ingest:   rtmp://${DISPLAY_HOST}:1935/vertical"
    echo -e "  Combined Chat:     http://${DISPLAY_HOST}:8081/chat.html"
    echo "-------------------------------------"
    echo "1) Install Docker"
    echo "2) Configure Stream Keys (Horizontal)"
    echo "3) Configure Stream Keys (Vertical)"
    echo "4) Configure OBS Setup"
    echo "5) Configure Domain / Reverse Proxy (Optional)"
    echo "6) Build & Start Server"
    echo "7) Stop Server"
    echo "8) Configure IP Whitelist (Optional)"
    echo "9) Configure API / OAuth (Twitch/YouTube)"
    echo "10) View Logs"
    echo "11) Quit"
    echo -e "Select an option: \c"
    read -r option

    case $option in
        1) install_docker ;;
        2) configure_keys ;;
        3) configure_vertical_keys ;;
        4) configure_obs ;;
        5) configure_domain ;;
        6) build_and_run ;;
        7) docker stop prism-rtmps ;;
        8) configure_whitelist ;;
        9) configure_api ;;
        10) docker logs -f prism-rtmps ;;
        11) exit 0 ;;
    esac
done
