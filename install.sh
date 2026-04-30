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
FACEBOOK_KEY=""
INSTAGRAM_KEY=""
CLOUDFLARE_KEY=""
TWITCH_URL="rtmp://ingest.global-contribute.live-video.net/app/"
TWITCH_KEY=""
KICK_KEY=""
X_KEY=""
TROVO_KEY=""
RTMP1_URL=""
RTMP1_KEY=""
CHUNK_SIZE="8192"

CONFIG_FILE="rtmp_config.env"

# Load saved configuration if it exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

save_config() {
    cat <<ENV_EOF > "$CONFIG_FILE"
YOUTUBE_URL="$YOUTUBE_URL"
YOUTUBE_KEY="$YOUTUBE_KEY"
FACEBOOK_KEY="$FACEBOOK_KEY"
INSTAGRAM_KEY="$INSTAGRAM_KEY"
CLOUDFLARE_KEY="$CLOUDFLARE_KEY"
TWITCH_URL="$TWITCH_URL"
TWITCH_KEY="$TWITCH_KEY"
KICK_KEY="$KICK_KEY"
X_KEY="$X_KEY"
TROVO_KEY="$TROVO_KEY"
RTMP1_URL="$RTMP1_URL"
RTMP1_KEY="$RTMP1_KEY"
CHUNK_SIZE="$CHUNK_SIZE"
ENV_EOF
    echo -e "${GREEN}Configuration saved to $CONFIG_FILE${NC}"
}

prompt_for_key() {
    local platform=$1
    local var_name=$2
    local current_value=${!var_name}

    echo -e "Enter Stream Key for ${YELLOW}$platform${NC} (Leave blank to keep current: ${current_value:-None}): "
    read -r input

    if [ ! -z "$input" ]; then
        printf -v "$var_name" "%s" "$input"
        save_config
    fi
}

configure_keys() {
    while true; do
        clear
        echo -e "${GREEN}=== Configure Stream Keys ===${NC}"
        echo "1) YouTube (Current: ${YOUTUBE_KEY:-None})"
        echo "2) Facebook (Current: ${FACEBOOK_KEY:-None})"
        echo "3) Instagram (Current: ${INSTAGRAM_KEY:-None})"
        echo "4) Cloudflare (Current: ${CLOUDFLARE_KEY:-None})"
        echo "5) Twitch (Current: ${TWITCH_KEY:-None})"
        echo "6) Kick (Current: ${KICK_KEY:-None})"
        echo "7) X (Twitter) (Current: ${X_KEY:-None})"
        echo "8) Trovo (Current: ${TROVO_KEY:-None})"
        echo "9) Custom RTMP (Current URL: ${RTMP1_URL:-None})"
        echo "10) Back to Main Menu"
        echo -e "Select an option: \c"
        read -r choice

        case $choice in
            1)
               prompt_for_key "YouTube Key" "YOUTUBE_KEY"
               echo -e "Select YouTube Server:"
               echo "  1) Primary (rtmp://x.rtmp.youtube.com/live2/)"
               echo "  2) Backup (rtmp://b.rtmp.youtube.com/live2?backup=1)"
               echo "  3) Secure Primary (rtmps://a.rtmps.youtube.com/live2/)"
               echo "  4) Secure Backup (rtmps://b.rtmps.youtube.com/live2?backup=1)"
               echo "  5) Custom URL"
               echo -e "Option (Current URL: $YOUTUBE_URL): \c"
               read -r y_opt
               case $y_opt in
                   1) YOUTUBE_URL="rtmp://x.rtmp.youtube.com/live2/" ;;
                   2) YOUTUBE_URL="rtmp://b.rtmp.youtube.com/live2?backup=1" ;;
                   3) YOUTUBE_URL="rtmps://a.rtmps.youtube.com/live2/" ;;
                   4) YOUTUBE_URL="rtmps://b.rtmps.youtube.com/live2?backup=1" ;;
                   5)
                      echo -e "Enter Custom YouTube Server URL: "
                      read -r y_url
                      if [ ! -z "$y_url" ]; then
                          YOUTUBE_URL="$y_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            2) prompt_for_key "Facebook" "FACEBOOK_KEY" ;;
            3) prompt_for_key "Instagram" "INSTAGRAM_KEY" ;;
            4) prompt_for_key "Cloudflare" "CLOUDFLARE_KEY" ;;
            5)
               prompt_for_key "Twitch Key" "TWITCH_KEY"
               echo -e "Select Twitch Server:"
               echo "  1) Global Auto (rtmp://ingest.global-contribute.live-video.net/app/)"
               echo "  2) US East (rtmp://use10.contribute.live-video.net/app/)"
               echo "  3) US West (rtmp://usw20.contribute.live-video.net/app/)"
               echo "  4) Europe Central (rtmp://euc10.contribute.live-video.net/app/)"
               echo "  5) Europe West (rtmp://euw10.contribute.live-video.net/app/)"
               echo "  6) Custom URL"
               echo -e "Option (Current URL: $TWITCH_URL): \c"
               read -r t_opt
               case $t_opt in
                   1) TWITCH_URL="rtmp://ingest.global-contribute.live-video.net/app/" ;;
                   2) TWITCH_URL="rtmp://use10.contribute.live-video.net/app/" ;;
                   3) TWITCH_URL="rtmp://usw20.contribute.live-video.net/app/" ;;
                   4) TWITCH_URL="rtmp://euc10.contribute.live-video.net/app/" ;;
                   5) TWITCH_URL="rtmp://euw10.contribute.live-video.net/app/" ;;
                   6)
                      echo -e "Enter Custom Twitch Server URL: "
                      read -r t_url
                      if [ ! -z "$t_url" ]; then
                          TWITCH_URL="$t_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            6) prompt_for_key "Kick" "KICK_KEY" ;;
            7) prompt_for_key "X (Twitter)" "X_KEY" ;;
            8) prompt_for_key "Trovo" "TROVO_KEY" ;;
            9)
               echo -e "Enter Custom RTMP Server URL (Current: $RTMP1_URL): "
               read -r c_url
               if [ ! -z "$c_url" ]; then
                   RTMP1_URL="$c_url"
                   save_config
               fi
               prompt_for_key "Custom RTMP Key" "RTMP1_KEY"
               ;;
            10) break ;;
            *) echo -e "${RED}Invalid option${NC}" ; sleep 1 ;;
        esac
    done
}

configure_optimizations() {
    clear
    echo -e "${GREEN}=== Optimizations ===${NC}"
    echo "Current Chunk Size: $CHUNK_SIZE (Default: 8192)"
    echo "Enter new Chunk Size (press Enter to keep current): "
    read -r input
    if [ ! -z "$input" ]; then
        CHUNK_SIZE="$input"
        save_config
        echo -e "${GREEN}Chunk size updated.${NC}"
        sleep 1
    fi
}

install_docker() {
    echo -e "${GREEN}Checking for Docker...${NC}"
    if ! command -v docker &> /dev/null; then
        echo -e "${YELLOW}Docker not found. Installing...${NC}"
        # Basic docker install via official script
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo systemctl start docker
        sudo systemctl enable docker
        rm get-docker.sh
        echo -e "${GREEN}Docker installed successfully.${NC}"
    else
        echo -e "${GREEN}Docker is already installed.${NC}"
    fi
    sleep 2
}

build_and_run() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed! Please run 'Install Docker' first.${NC}"
        sleep 2
        return
    fi

    echo -e "${GREEN}Building Docker Image...${NC}"
    docker build -t prism-rtmps .

    echo -e "${GREEN}Stopping any existing container...${NC}"
    docker stop prism-rtmps 2>/dev/null || true
    docker rm prism-rtmps 2>/dev/null || true

    echo -e "${GREEN}Starting container...${NC}"
    # Start the container
    docker run -d --name prism-rtmps \
        -p 1935:1935 \
        -p 8081:8081 \
        --restart unless-stopped \
        -e YOUTUBE_URL="$YOUTUBE_URL" \
        -e YOUTUBE_KEY="$YOUTUBE_KEY" \
        -e FACEBOOK_KEY="$FACEBOOK_KEY" \
        -e INSTAGRAM_KEY="$INSTAGRAM_KEY" \
        -e CLOUDFLARE_KEY="$CLOUDFLARE_KEY" \
        -e TWITCH_URL="$TWITCH_URL" \
        -e TWITCH_KEY="$TWITCH_KEY" \
        -e KICK_KEY="$KICK_KEY" \
        -e X_KEY="$X_KEY" \
        -e TROVO_KEY="$TROVO_KEY" \
        -e RTMP1_URL="$RTMP1_URL" \
        -e RTMP1_KEY="$RTMP1_KEY" \
        -e CHUNK_SIZE="$CHUNK_SIZE" \
        prism-rtmps

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Container 'prism-rtmps' is running!${NC}"
        echo -e "You can stream to: rtmp://<your_server_ip>:1935/live"
        echo -e "Stats available at: http://<your_server_ip>:8081/stat"
    else
        echo -e "${RED}Failed to start container.${NC}"
    fi
    echo -e "Press Enter to continue..."
    read -r
}

view_logs() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed!${NC}"
        sleep 2
        return
    fi

    echo -e "${YELLOW}Showing logs for prism-rtmps... (Press Ctrl+C to exit)${NC}"
    docker logs -f prism-rtmps
    echo -e "Press Enter to return to menu..."
    read -r
}

stop_container() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Docker is not installed!${NC}"
        sleep 2
        return
    fi
    echo -e "${YELLOW}Stopping container...${NC}"
    docker stop prism-rtmps 2>/dev/null && echo -e "${GREEN}Container stopped.${NC}" || echo -e "${RED}Container not running.${NC}"
    sleep 2
}

while true; do
    clear
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}     PrismRTMPS Quick Installer      ${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo "1) Install Docker (if not installed)"
    echo "2) Configure Stream Keys"
    echo "3) Configure Optimizations (Chunk Size)"
    echo "4) Build & Start Server"
    echo "5) Stop Server"
    echo "6) View Logs"
    echo "7) Quit"
    echo -e "Select an option: \c"
    read -r option

    case $option in
        1) install_docker ;;
        2) configure_keys ;;
        3) configure_optimizations ;;
        4) build_and_run ;;
        5) stop_container ;;
        6) view_logs ;;
        7) clear; echo -e "${GREEN}Goodbye!${NC}"; break ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
    esac
done
