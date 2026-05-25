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
TIKTOK_URL=""
TIKTOK_KEY=""
KICK_URL="rtmp://127.0.0.1:19353/app/"
KICK_KEY=""
X_KEY=""
TROVO_KEY=""
RTMP1_URL=""
RTMP1_KEY=""
OBS_KEY=""
SERVER_DOMAIN=""
CHUNK_SIZE="8192"
STREAM_TITLE=""
EPISODE_NUM=""
AUTO_INCREMENT="n"
ADD_DATE="n"
TWITCH_CLIENT_ID=""
TWITCH_OAUTH_TOKEN=""
TWITCH_BROADCASTER_ID=""

TIKTOK_V_URL=""
TIKTOK_V_KEY=""
TWITCH_V_URL=""
TWITCH_V_KEY=""
YOUTUBE_V_URL=""
YOUTUBE_V_KEY=""

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
TIKTOK_URL="$TIKTOK_URL"
TIKTOK_KEY="$TIKTOK_KEY"
KICK_URL="$KICK_URL"
KICK_KEY="$KICK_KEY"
X_KEY="$X_KEY"
TROVO_KEY="$TROVO_KEY"
RTMP1_URL="$RTMP1_URL"
RTMP1_KEY="$RTMP1_KEY"
OBS_KEY="$OBS_KEY"
SERVER_DOMAIN="$SERVER_DOMAIN"
CHUNK_SIZE="$CHUNK_SIZE"
STREAM_TITLE="$STREAM_TITLE"
EPISODE_NUM="$EPISODE_NUM"
AUTO_INCREMENT="$AUTO_INCREMENT"
ADD_DATE="$ADD_DATE"
TWITCH_CLIENT_ID="$TWITCH_CLIENT_ID"
TWITCH_OAUTH_TOKEN="$TWITCH_OAUTH_TOKEN"
TWITCH_BROADCASTER_ID="$TWITCH_BROADCASTER_ID"

TIKTOK_V_URL="$TIKTOK_V_URL"
TIKTOK_V_KEY="$TIKTOK_V_KEY"
TWITCH_V_URL="$TWITCH_V_URL"
TWITCH_V_KEY="$TWITCH_V_KEY"
YOUTUBE_V_URL="$YOUTUBE_V_URL"
YOUTUBE_V_KEY="$YOUTUBE_V_KEY"
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

configure_keys() {
    while true; do
        clear
        echo -e "${GREEN}=== Configure Stream Keys ===${NC}"
        echo "1) Twitch (Current: ${TWITCH_KEY:-None})"
        echo "2) YouTube (Current: ${YOUTUBE_KEY:-None})"
        echo "3) TikTok (Current: ${TIKTOK_KEY:-None})"
        echo "4) Facebook (Current: ${FACEBOOK_KEY:-None})"
        echo "5) Instagram (Current: ${INSTAGRAM_KEY:-None})"
        echo "6) Cloudflare (Current: ${CLOUDFLARE_KEY:-None})"
        echo "7) Kick (Current: ${KICK_KEY:-None})"
        echo "8) X (Twitter) (Current: ${X_KEY:-None})"
        echo "9) Trovo (Current: ${TROVO_KEY:-None})"
        echo "10) Custom RTMP (Current URL: ${RTMP1_URL:-None})"
        echo "11) Back to Main Menu"
        echo -e "Select an option: \c"
        read -r choice

        case $choice in
            1)
               prompt_for_key "Twitch Key" "TWITCH_KEY"
               echo -e "Select Twitch Server:"
               echo "  1) Global Auto (rtmp://ingest.global-contribute.live-video.net/app/)"
               echo "  2) US East (rtmp://use10.contribute.live-video.net/app/)"
               echo "  3) US West (rtmp://usw20.contribute.live-video.net/app/)"
               echo "  4) Europe Central (rtmp://euc10.contribute.live-video.net/app/)"
               echo "  5) Europe West (rtmp://euw10.contribute.live-video.net/app/)"
               echo "  6) Global Secure RTMPS Proxy (rtmps://ingest.global-contribute.live-video.net/app/)"
               echo "  7) Custom URL"
               echo -e "Option (Current URL: $TWITCH_URL): \c"
               read -r t_opt
               case $t_opt in
                   1) TWITCH_URL="rtmp://ingest.global-contribute.live-video.net/app/" ;;
                   2) TWITCH_URL="rtmp://use10.contribute.live-video.net/app/" ;;
                   3) TWITCH_URL="rtmp://usw20.contribute.live-video.net/app/" ;;
                   4) TWITCH_URL="rtmp://euc10.contribute.live-video.net/app/" ;;
                   5) TWITCH_URL="rtmp://euw10.contribute.live-video.net/app/" ;;
                   6) TWITCH_URL="rtmp://127.0.0.1:19356/app/" ;;
                   7)
                      echo -e "Enter Custom Twitch Server URL: "
                      read -r t_url
                      if [ ! -z "$t_url" ]; then
                          TWITCH_URL="$t_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            2)
               prompt_for_key "YouTube Key" "YOUTUBE_KEY"
               echo -e "Select YouTube Server:"
               echo "  1) Primary (rtmp://x.rtmp.youtube.com/live2/)"
               echo "  2) Backup (rtmp://b.rtmp.youtube.com/live2?backup=1)"
               echo "  3) Secure Primary (rtmp://127.0.0.1:19355/live2/)"
               echo "  4) Secure Backup (rtmp://127.0.0.1:19357/live2?backup=1)"
               echo "  5) Custom URL"
               echo -e "Option (Current URL: $YOUTUBE_URL): \c"
               read -r y_opt
               case $y_opt in
                   1) YOUTUBE_URL="rtmp://x.rtmp.youtube.com/live2/" ;;
                   2) YOUTUBE_URL="rtmp://b.rtmp.youtube.com/live2?backup=1" ;;
                   3) YOUTUBE_URL="rtmp://127.0.0.1:19355/live2/" ;;
                   4) YOUTUBE_URL="rtmp://127.0.0.1:19357/live2?backup=1" ;;
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
            3)
               prompt_for_key "TikTok Key" "TIKTOK_KEY"
               echo -e "Select TikTok Server:"
               echo "  1) Global Secure Proxy (rtmps://push-rtmp-f5-ap-southeast-1.tiktokcdn.com/live)"
               echo "  2) Custom URL"
               echo -e "Option (Current URL: $TIKTOK_URL): \c"
               read -r tk_opt
               case $tk_opt in
                   1) TIKTOK_URL="rtmp://127.0.0.1:19358/live/" ;;
                   2)
                      echo -e "Enter Custom TikTok Server URL: "
                      read -r tk_url
                      if [ ! -z "$tk_url" ]; then
                          TIKTOK_URL="$tk_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            4) prompt_for_key "Facebook" "FACEBOOK_KEY" ;;
            5) prompt_for_key "Instagram" "INSTAGRAM_KEY" ;;
            6) prompt_for_key "Cloudflare" "CLOUDFLARE_KEY" ;;
            7)
               prompt_for_key "Kick Key" "KICK_KEY"
               echo -e "Select Kick Server:"
               echo "  1) Global Secure Proxy (rtmps://fa723fc1b171.global-contribute.live-video.net/app/)"
               echo "  2) Custom URL"
               echo -e "Option (Current URL: $KICK_URL): \c"
               read -r k_opt
               case $k_opt in
                   1) KICK_URL="rtmp://127.0.0.1:19353/app/" ;;
                   2)
                      echo -e "Enter Custom Kick Server URL: "
                      read -r k_url
                      if [ ! -z "$k_url" ]; then
                          KICK_URL="$k_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            8) prompt_for_key "X (Twitter)" "X_KEY" ;;
            9) prompt_for_key "Trovo" "TROVO_KEY" ;;
            10)
               echo -e "Enter Custom RTMP Server URL (Current: $RTMP1_URL): "
               read -r c_url
               if [ ! -z "$c_url" ]; then
                   RTMP1_URL="$c_url"
                   save_config
               fi
               prompt_for_key "Custom RTMP Key" "RTMP1_KEY"
               ;;
            11) break ;;
            *) echo -e "${RED}Invalid option${NC}" ; sleep 1 ;;
        esac
    done
}

configure_vertical() {
    while true; do
        clear
        echo -e "${GREEN}=== Configure Vertical Streams ===${NC}"
        echo -e "Use the OBS Aitum Vertical plugin and set its server to:"
        if [ ! -z "$SERVER_DOMAIN" ]; then
            echo -e "  ${YELLOW}Vertical URL:${NC} rtmp://${SERVER_DOMAIN}:1935/vertical"
        else
            SERVER_IP=$(curl -s ifconfig.me || echo "<your_server_ip>")
            echo -e "  ${YELLOW}Vertical URL:${NC} rtmp://${SERVER_IP}:1935/vertical"
        fi
        echo -e "Stream Key: Use your OBS Master Key or one of the configured keys."
        echo ""
        echo "1) TikTok Vertical (Current Key: ${TIKTOK_V_KEY:-None})"
        echo "2) Twitch Vertical (Current Key: ${TWITCH_V_KEY:-None})"
        echo "3) YouTube Vertical (Current Key: ${YOUTUBE_V_KEY:-None})"
        echo "4) Back to Main Menu"
        echo -e "Select an option: \c"
        read -r choice

        case $choice in
            1)
               prompt_for_key "TikTok Vertical Key" "TIKTOK_V_KEY"
               echo -e "Select TikTok Vertical Server:"
               echo "  1) Global Secure Proxy (rtmps://push-rtmp-f5-ap-southeast-1.tiktokcdn.com/live)"
               echo "  2) Custom URL"
               echo -e "Option (Current URL: $TIKTOK_V_URL): \c"
               read -r tk_v_opt
               case $tk_v_opt in
                   1) TIKTOK_V_URL="rtmp://127.0.0.1:19358/live/" ;;
                   2)
                      echo -e "Enter Custom TikTok Vertical Server URL: "
                      read -r tk_v_url
                      if [ ! -z "$tk_v_url" ]; then
                          TIKTOK_V_URL="$tk_v_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            2)
               prompt_for_key "Twitch Vertical Key" "TWITCH_V_KEY"
               echo -e "Select Twitch Vertical Server:"
               echo "  1) Global Auto (rtmp://ingest.global-contribute.live-video.net/app/)"
               echo "  2) US East (rtmp://use10.contribute.live-video.net/app/)"
               echo "  3) US West (rtmp://usw20.contribute.live-video.net/app/)"
               echo "  4) Europe Central (rtmp://euc10.contribute.live-video.net/app/)"
               echo "  5) Europe West (rtmp://euw10.contribute.live-video.net/app/)"
               echo "  6) Global Secure RTMPS Proxy (rtmps://ingest.global-contribute.live-video.net/app/)"
               echo "  7) Custom URL"
               echo -e "Option (Current URL: $TWITCH_V_URL): \c"
               read -r t_v_opt
               case $t_v_opt in
                   1) TWITCH_V_URL="rtmp://ingest.global-contribute.live-video.net/app/" ;;
                   2) TWITCH_V_URL="rtmp://use10.contribute.live-video.net/app/" ;;
                   3) TWITCH_V_URL="rtmp://usw20.contribute.live-video.net/app/" ;;
                   4) TWITCH_V_URL="rtmp://euc10.contribute.live-video.net/app/" ;;
                   5) TWITCH_V_URL="rtmp://euw10.contribute.live-video.net/app/" ;;
                   6) TWITCH_V_URL="rtmp://127.0.0.1:19356/app/" ;;
                   7)
                      echo -e "Enter Custom Twitch Vertical Server URL: "
                      read -r t_v_url
                      if [ ! -z "$t_v_url" ]; then
                          TWITCH_V_URL="$t_v_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            3)
               prompt_for_key "YouTube Vertical Key" "YOUTUBE_V_KEY"
               echo -e "Select YouTube Vertical Server:"
               echo "  1) Primary (rtmp://x.rtmp.youtube.com/live2/)"
               echo "  2) Backup (rtmp://b.rtmp.youtube.com/live2?backup=1)"
               echo "  3) Secure Primary (rtmp://127.0.0.1:19355/live2/)"
               echo "  4) Secure Backup (rtmp://127.0.0.1:19357/live2?backup=1)"
               echo "  5) Custom URL"
               echo -e "Option (Current URL: $YOUTUBE_V_URL): \c"
               read -r y_v_opt
               case $y_v_opt in
                   1) YOUTUBE_V_URL="rtmp://x.rtmp.youtube.com/live2/" ;;
                   2) YOUTUBE_V_URL="rtmp://b.rtmp.youtube.com/live2?backup=1" ;;
                   3) YOUTUBE_V_URL="rtmp://127.0.0.1:19355/live2/" ;;
                   4) YOUTUBE_V_URL="rtmp://127.0.0.1:19357/live2?backup=1" ;;
                   5)
                      echo -e "Enter Custom YouTube Vertical Server URL: "
                      read -r y_v_url
                      if [ ! -z "$y_v_url" ]; then
                          YOUTUBE_V_URL="$y_v_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            4) break ;;
            *) echo -e "${RED}Invalid option${NC}" ; sleep 1 ;;
        esac
    done
}

configure_obs() {
    clear
    echo -e "${GREEN}=== OBS Configuration ===${NC}"
    # Determine the public IP if possible, or fallback to placeholder
    if [ ! -z "$SERVER_DOMAIN" ]; then
        SERVER_HOST="$SERVER_DOMAIN"
    else
        SERVER_HOST=$(curl -s ifconfig.me || echo "<your_server_ip>")
    fi

    echo -e "To stream to this server from OBS or another encoder:"
    echo -e "  ${YELLOW}Server URL:${NC} rtmp://${SERVER_HOST}:1935/live"
    echo ""
    echo -e "For security, PrismRTMPS requires a matching stream key to accept your stream."
    echo -e "You must either use one of the destination keys you already configured (e.g., your Twitch or YouTube key),"
    echo -e "or you can create a custom, specific OBS Master Key here."
    echo ""
    echo -e "Current Custom OBS Key: ${OBS_KEY:-None}"
    echo -e "Enter new Custom OBS Key (Type 'disable' to remove, or press Enter to keep current): "
    read -r input
    if [ "$input" == "disable" ] || [ "$input" == "DISABLE" ]; then
        OBS_KEY=""
        save_config
        echo -e "${GREEN}Custom OBS Key removed.${NC}"
        sleep 1
    elif [ ! -z "$input" ]; then
        OBS_KEY="$input"
        save_config
        echo -e "${GREEN}Custom OBS Key updated.${NC}"
        sleep 1
    fi
}

configure_reverse_proxy() {
    clear
    echo -e "${GREEN}=== Configure Reverse Proxy / Custom Domain ===${NC}"
    echo -e "If you use Cloudflare or a custom domain, you can set it here."
    echo -e "This will update the OBS instructions to use your domain instead of your raw server IP."
    echo ""
    echo -e "${RED}IMPORTANT CLOUDFLARE WARNING:${NC}"
    echo -e "Standard Cloudflare full proxying (Orange Cloud) ONLY supports HTTP traffic and automatically drops raw RTMP connections on port 1935."
    echo -e "If using Cloudflare, you MUST set your DNS record to ${YELLOW}'DNS Only' (Grey Cloud)${NC} for streams to connect natively."
    echo -e "If you wish to hide your domain's A record (full proxy), you cannot stream standard RTMP directly. You must set up advanced routing like Cloudflare Tunnels (cloudflared) or a VPN, which requires local software on your PC."
    echo ""
    echo -e "Current Custom Domain: ${SERVER_DOMAIN:-None}"
    echo -e "Enter new Domain (Type 'disable' to remove, or press Enter to keep current): "
    read -r domain_input
    if [ "$domain_input" == "disable" ] || [ "$domain_input" == "DISABLE" ]; then
        SERVER_DOMAIN=""
        save_config
        echo -e "${GREEN}Custom Domain removed.${NC}"
        sleep 1
    elif [ ! -z "$domain_input" ]; then
        SERVER_DOMAIN="$domain_input"
        save_config
        echo -e "${GREEN}Custom Domain updated.${NC}"
        sleep 1
    fi
}

manage_titles() {
    while true; do
        clear
        echo -e "${GREEN}=== Manage Stream Titles ===${NC}"
        echo -e "This feature allows you to update your stream title across platforms."
        echo -e "1) Update Stream Title & Push"
        echo -e "2) Configure Twitch API Credentials for Title Sync"
        echo -e "3) Back to Main Menu"
        echo -e "Select an option: \c"
        read -r title_choice

        case $title_choice in
            1)
                clear
                echo -e "${GREEN}=== Update Stream Title ===${NC}"
                echo -e "Current Base Title: ${YELLOW}${STREAM_TITLE:-None}${NC}"
                echo -e "Current Episode Number: ${YELLOW}${EPISODE_NUM:-None}${NC}"
                echo -e "Auto-Increment Episode: ${YELLOW}${AUTO_INCREMENT}${NC}"
                echo -e "Automatically Add Date: ${YELLOW}${ADD_DATE}${NC}"
                echo ""

                echo -e "Enter new Stream Title (Supports Emojis! 🚀) (press Enter to keep current): "
                read -r title_input
                if [ ! -z "$title_input" ]; then
                    STREAM_TITLE="$title_input"
                fi

                echo -e "Enter Episode Number (optional, leave blank or type 'disable' to remove, press Enter to keep current): "
                read -r ep_input
                if [ "$ep_input" == "disable" ] || [ "$ep_input" == "DISABLE" ]; then
                    EPISODE_NUM=""
                elif [ ! -z "$ep_input" ]; then
                    EPISODE_NUM="$ep_input"
                fi

                if [ ! -z "$EPISODE_NUM" ]; then
                    echo -e "Enable auto-increment for episode number after pushing? (y/n) [Current: $AUTO_INCREMENT]: "
                    read -r auto_input
                    if [ "$auto_input" == "y" ] || [ "$auto_input" == "Y" ]; then
                        AUTO_INCREMENT="y"
                    elif [ "$auto_input" == "n" ] || [ "$auto_input" == "N" ]; then
                        AUTO_INCREMENT="n"
                    fi
                else
                    AUTO_INCREMENT="n"
                fi

                echo -e "Automatically append today's date to title? (y/n) [Current: $ADD_DATE]: "
                read -r date_input
                if [ "$date_input" == "y" ] || [ "$date_input" == "Y" ]; then
                    ADD_DATE="y"
                elif [ "$date_input" == "n" ] || [ "$date_input" == "N" ]; then
                    ADD_DATE="n"
                fi

                save_config

                # Format the final title
                FINAL_TITLE="$STREAM_TITLE"

                if [ "$ADD_DATE" == "y" ]; then
                    CURRENT_DATE=$(date +"%Y-%m-%d")
                    FINAL_TITLE="${FINAL_TITLE} / ${CURRENT_DATE}"
                fi

                if [ ! -z "$EPISODE_NUM" ]; then
                    FINAL_TITLE="${FINAL_TITLE} / Episode ${EPISODE_NUM}"
                fi

                echo -e "\n${GREEN}Final Stream Title to push:${NC} $FINAL_TITLE"
                echo -e "Pushing title to Twitch, YouTube, TikTok, and Kick..."

                # Run the python script to attempt API updates
                if [ -f "update_titles.py" ]; then
                    if ! python3 -c "import requests" &> /dev/null; then
                        echo -e "${YELLOW}Installing python3-requests for API integrations...${NC}"
                        sudo apt-get update && sudo apt-get install -y python3-requests
                    fi
                    python3 update_titles.py "$FINAL_TITLE"
                fi

                if [ "$AUTO_INCREMENT" == "y" ] && [ ! -z "$EPISODE_NUM" ]; then
                    EPISODE_NUM=$((EPISODE_NUM + 1))
                    save_config
                    echo -e "${YELLOW}Episode number auto-incremented to $EPISODE_NUM for next stream.${NC}"
                fi

                echo -e "\nPress Enter to return to menu..."
                read -r
                ;;
            2)
                clear
                echo -e "${GREEN}=== Configure Twitch API Credentials ===${NC}"
                echo -e "To automatically update your Twitch title, you need a Client ID, User OAuth Token (with channel:manage:broadcast scope), and Broadcaster ID."

                echo -e "Enter Twitch Client ID (Current: ${YELLOW}${TWITCH_CLIENT_ID:-None}${NC}): "
                read -r client_input
                if [ "$client_input" == "disable" ] || [ "$client_input" == "DISABLE" ]; then
                    TWITCH_CLIENT_ID=""
                elif [ ! -z "$client_input" ]; then
                    TWITCH_CLIENT_ID="$client_input"
                fi

                echo -e "Enter Twitch OAuth Token (Current: ${YELLOW}${TWITCH_OAUTH_TOKEN:-None}${NC}): "
                read -r token_input
                if [ "$token_input" == "disable" ] || [ "$token_input" == "DISABLE" ]; then
                    TWITCH_OAUTH_TOKEN=""
                elif [ ! -z "$token_input" ]; then
                    TWITCH_OAUTH_TOKEN="$token_input"
                fi

                echo -e "Enter Twitch Broadcaster ID (Current: ${YELLOW}${TWITCH_BROADCASTER_ID:-None}${NC}): "
                read -r bc_input
                if [ "$bc_input" == "disable" ] || [ "$bc_input" == "DISABLE" ]; then
                    TWITCH_BROADCASTER_ID=""
                elif [ ! -z "$bc_input" ]; then
                    TWITCH_BROADCASTER_ID="$bc_input"
                fi

                save_config
                echo -e "${GREEN}Twitch API credentials updated.${NC}"
                sleep 1
                ;;
            3) break ;;
            *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
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
        -e TIKTOK_URL="$TIKTOK_URL" \
        -e TIKTOK_KEY="$TIKTOK_KEY" \
        -e KICK_URL="$KICK_URL" \
        -e KICK_KEY="$KICK_KEY" \
        -e X_KEY="$X_KEY" \
        -e TROVO_KEY="$TROVO_KEY" \
        -e RTMP1_URL="$RTMP1_URL" \
        -e RTMP1_KEY="$RTMP1_KEY" \
        -e OBS_KEY="$OBS_KEY" \
        -e CHUNK_SIZE="$CHUNK_SIZE" \
        -e TIKTOK_V_URL="$TIKTOK_V_URL" \
        -e TIKTOK_V_KEY="$TIKTOK_V_KEY" \
        -e TWITCH_V_URL="$TWITCH_V_URL" \
        -e TWITCH_V_KEY="$TWITCH_V_KEY" \
        -e YOUTUBE_V_URL="$YOUTUBE_V_URL" \
        -e YOUTUBE_V_KEY="$YOUTUBE_V_KEY" \
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
    echo "3) Configure Vertical Streams"
    echo "4) Configure OBS Setup & Security Key"
    echo "5) Configure Reverse Proxy / Custom Domain"
    echo "6) Manage Stream Titles"
    echo "7) Configure Optimizations (Chunk Size)"
    echo "8) Build & Start Server"
    echo "9) Stop Server"
    echo "10) View Logs"
    echo "11) Quit"
    echo -e "Select an option: \c"
    read -r option

    case $option in
        1) install_docker ;;
        2) configure_keys ;;
        3) configure_vertical ;;
        4) configure_obs ;;
        5) configure_reverse_proxy ;;
        6) manage_titles ;;
        7) configure_optimizations ;;
        8) build_and_run ;;
        9) stop_container ;;
        10) view_logs ;;
        11) clear; echo -e "${GREEN}Goodbye!${NC}"; break ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
    esac
done
