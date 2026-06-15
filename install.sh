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
V_YOUTUBE_URL="rtmp://x.rtmp.youtube.com/live2/"
V_YOUTUBE_KEY=""
V_TWITCH_URL="rtmp://127.0.0.1:19353/app/"
V_TWITCH_KEY=""
V_KICK_URL="rtmp://127.0.0.1:19356/kick/"
V_KICK_KEY=""
V_TIKTOK_URL="rtmp://127.0.0.1:19358/s_v/"
V_TIKTOK_KEY=""
V_FACEBOOK_URL="rtmp://127.0.0.1:19350/rtmp/"
V_FACEBOOK_KEY=""
V_INSTAGRAM_URL="rtmp://127.0.0.1:19351/rtmp/"
V_INSTAGRAM_KEY=""
V_X_URL="rtmp://127.0.0.1:19354/x/"
V_X_KEY=""
V_TROVO_URL="rtmp://livepush.trovo.live/live/"
V_TROVO_KEY=""
V_RTMP1_URL=""
V_RTMP1_KEY=""

OBS_KEY=""
APP_NAME="live"
ACCEPTED_IP=""
SERVER_DOMAIN=""
LETSENCRYPT_EMAIL=""
CHUNK_SIZE="8192"
STREAM_BASE_TITLE="Live Stream"
TWITCH_CLIENT_ID=""
TWITCH_OAUTH_TOKEN=""
TWITCH_BROADCASTER_ID=""
TWITCH_CLIENT_SECRET=""
TWITCH_REDIRECT_URI=""
YOUTUBE_CLIENT_ID=""
YOUTUBE_CLIENT_SECRET=""
YOUTUBE_REDIRECT_URI=""
SECRET_KEY=$(openssl rand -hex 24)

# TikTok Dynamic Settings
TIKTOK_SL_TOKEN=""
TIKTOK_TITLE="Live Stream"
TIKTOK_GAME_NAME="Other"
TIKTOK_GAME_ID=""

# NOALBS & OBS Scene Switcher Settings
NOALBS_ENABLED="false"
LOW_BITRATE="1000"
RESTORE_BITRATE="1500"
BRB_VIDEO_PATH=""
OBS_WS_HOST=""
OBS_WS_PORT="4455"
OBS_WS_PASSWORD=""
OBS_SCENE_LIVE="Main"
OBS_SCENE_BRB="BRB"

# Combined Chat Settings
CHAT_TWITCH=""
CHAT_YOUTUBE=""
CHAT_KICK=""
CHAT_TIKTOK=""

CONFIG_FILE="rtmp_config.env"

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
CHAT_TWITCH="$CHAT_TWITCH"
CHAT_YOUTUBE="$CHAT_YOUTUBE"
CHAT_KICK="$CHAT_KICK"
CHAT_TIKTOK="$CHAT_TIKTOK"
SERVER_DOMAIN="$SERVER_DOMAIN"
LETSENCRYPT_EMAIL="$LETSENCRYPT_EMAIL"
CHUNK_SIZE="$CHUNK_SIZE"
STREAM_BASE_TITLE="$STREAM_BASE_TITLE"
TWITCH_CLIENT_ID="$TWITCH_CLIENT_ID"
TWITCH_OAUTH_TOKEN="$TWITCH_OAUTH_TOKEN"
TWITCH_BROADCASTER_ID="$TWITCH_BROADCASTER_ID"
TWITCH_CLIENT_SECRET="$TWITCH_CLIENT_SECRET"
TWITCH_REDIRECT_URI="$TWITCH_REDIRECT_URI"
YOUTUBE_CLIENT_ID="$YOUTUBE_CLIENT_ID"
YOUTUBE_CLIENT_SECRET="$YOUTUBE_CLIENT_SECRET"
YOUTUBE_REDIRECT_URI="$YOUTUBE_REDIRECT_URI"
SECRET_KEY="$SECRET_KEY"
NOALBS_ENABLED="$NOALBS_ENABLED"
LOW_BITRATE="$LOW_BITRATE"
RESTORE_BITRATE="$RESTORE_BITRATE"
BRB_VIDEO_PATH="$BRB_VIDEO_PATH"
OBS_WS_HOST="$OBS_WS_HOST"
OBS_WS_PORT="$OBS_WS_PORT"
OBS_WS_PASSWORD="$OBS_WS_PASSWORD"
OBS_SCENE_LIVE="$OBS_SCENE_LIVE"
OBS_SCENE_BRB="$OBS_SCENE_BRB"
TIKTOK_SL_TOKEN="$TIKTOK_SL_TOKEN"
TIKTOK_TITLE="$TIKTOK_TITLE"
TIKTOK_GAME_NAME="$TIKTOK_GAME_NAME"
TIKTOK_GAME_ID="$TIKTOK_GAME_ID"
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
            1)
               prompt_for_key "YouTube Key" "YOUTUBE_KEY"
               echo -e "Select YouTube Server:"
               echo "  1) Primary (rtmp://x.rtmp.youtube.com/live2/)"
               echo "  2) Backup (rtmp://b.rtmp.youtube.com/live2?backup=1)"
               echo "  3) Secure Primary (rtmps://a.rtmps.youtube.com/live2/ -> via Stunnel)"
               echo "  4) Secure Backup (rtmps://b.rtmps.youtube.com/live2?backup=1 -> via Stunnel)"
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
            2)
               prompt_for_key "Twitch Key" "TWITCH_KEY"
               echo -e "Select Twitch Server:"
               echo "  1) Global (rtmp://ingest.global-contribute.live-video.net/app/)"
               echo "  2) Secure Global (rtmps://ingest.global-contribute.live-video.net:443 -> Stunnel)"
               echo "  3) US East: Ashburn (rtmp://iad05.contribute.live-video.net/app/)"
               echo "  4) US East: New York (rtmp://jfk05.contribute.live-video.net/app/)"
               echo "  5) US East: Chicago (rtmp://ord02.contribute.live-video.net/app/)"
               echo "  6) US East: Miami (rtmp://mia05.contribute.live-video.net/app/)"
               echo "  7) US Central: Dallas (rtmp://dfw01.contribute.live-video.net/app/)"
               echo "  8) US West: San Jose (rtmp://sjc05.contribute.live-video.net/app/)"
               echo "  9) US West: Seattle (rtmp://sea01.contribute.live-video.net/app/)"
               echo "  10) US West: Los Angeles (rtmp://lax05.contribute.live-video.net/app/)"
               echo "  11) EU: Frankfurt (rtmp://fra02.contribute.live-video.net/app/)"
               echo "  12) EU: London (rtmp://lhr03.contribute.live-video.net/app/)"
               echo "  13) EU: Amsterdam (rtmp://ams03.contribute.live-video.net/app/)"
               echo "  14) Asia: Tokyo (rtmp://tyo01.contribute.live-video.net/app/)"
               echo "  15) Asia: Seoul (rtmp://icn01.contribute.live-video.net/app/)"
               echo "  16) Asia: Singapore (rtmp://sin01.contribute.live-video.net/app/)"
               echo "  17) Australia: Sydney (rtmp://syd01.contribute.live-video.net/app/)"
               echo "  18) Custom URL"
               echo -e "Option (Current URL: $TWITCH_URL): \c"
               read -r t_opt
               case $t_opt in
                   1) TWITCH_URL="rtmp://ingest.global-contribute.live-video.net/app/" ;;
                   2) TWITCH_URL="rtmp://127.0.0.1:19353/app/" ;;
                   3) TWITCH_URL="rtmp://iad05.contribute.live-video.net/app/" ;;
                   4) TWITCH_URL="rtmp://jfk05.contribute.live-video.net/app/" ;;
                   5) TWITCH_URL="rtmp://ord02.contribute.live-video.net/app/" ;;
                   6) TWITCH_URL="rtmp://mia05.contribute.live-video.net/app/" ;;
                   7) TWITCH_URL="rtmp://dfw01.contribute.live-video.net/app/" ;;
                   8) TWITCH_URL="rtmp://sjc05.contribute.live-video.net/app/" ;;
                   9) TWITCH_URL="rtmp://sea01.contribute.live-video.net/app/" ;;
                   10) TWITCH_URL="rtmp://lax05.contribute.live-video.net/app/" ;;
                   11) TWITCH_URL="rtmp://fra02.contribute.live-video.net/app/" ;;
                   12) TWITCH_URL="rtmp://lhr03.contribute.live-video.net/app/" ;;
                   13) TWITCH_URL="rtmp://ams03.contribute.live-video.net/app/" ;;
                   14) TWITCH_URL="rtmp://tyo01.contribute.live-video.net/app/" ;;
                   15) TWITCH_URL="rtmp://icn01.contribute.live-video.net/app/" ;;
                   16) TWITCH_URL="rtmp://sin01.contribute.live-video.net/app/" ;;
                   17) TWITCH_URL="rtmp://syd01.contribute.live-video.net/app/" ;;
                   18)
                      echo -e "Enter Custom Twitch Server URL: "
                      read -r t_url
                      if [ ! -z "$t_url" ]; then
                          TWITCH_URL="$t_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            3)
               prompt_for_key "Kick" "KICK_KEY"
               echo -e "Select Kick Server:"
               echo "  1) Standard (rtmp://live.kick.com/app/)"
               echo "  2) Secure (rtmps://fa723fc1b171.global-contribute.live-video.net:443 -> via Stunnel)"
               echo "  3) Custom URL"
               echo -e "Option (Current URL: $KICK_URL): \c"
               read -r k_opt
               case $k_opt in
                   1) KICK_URL="rtmp://live.kick.com/app/" ;;
                   2) KICK_URL="rtmp://127.0.0.1:19356/kick/" ;;
                   3)
                      echo -e "Enter Custom Kick Server URL: "
                      read -r k_url
                      if [ ! -z "$k_url" ]; then
                          KICK_URL="$k_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            4)
               prompt_for_key "TikTok" "TIKTOK_KEY"
               echo -e "Select TikTok Server:"
               echo "  1) Secure (rtmps://push-rtmp-f5-ap-southeast-1.tiktokcdn.com:443 -> via Stunnel)"
               echo "  2) Custom URL"
               echo -e "Option (Current URL: $TIKTOK_URL): \c"
               read -r tt_opt
               case $tt_opt in
                   1) TIKTOK_URL="rtmp://127.0.0.1:19358/s_v/" ;;
                   2)
                      echo -e "Enter Custom TikTok Server URL: "
                      read -r tt_url
                      if [ ! -z "$tt_url" ]; then
                          TIKTOK_URL="$tt_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            5)
               prompt_for_key "Facebook" "FACEBOOK_KEY"
               echo -e "Select Facebook Server:"
               echo "  1) Secure (rtmps://live-api-s.facebook.com:443 -> via Stunnel)"
               echo "  2) Custom URL"
               echo -e "Option (Current URL: $FACEBOOK_URL): \c"
               read -r f_opt
               case $f_opt in
                   1) FACEBOOK_URL="rtmp://127.0.0.1:19350/rtmp/" ;;
                   2)
                      echo -e "Enter Custom Facebook Server URL: "
                      read -r f_url
                      if [ ! -z "$f_url" ]; then
                          FACEBOOK_URL="$f_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            6)
               prompt_for_key "Instagram" "INSTAGRAM_KEY"
               echo -e "Select Instagram Server:"
               echo "  1) Secure (rtmps://live-upload.instagram.com:443 -> via Stunnel)"
               echo "  2) Custom URL"
               echo -e "Option (Current URL: $INSTAGRAM_URL): \c"
               read -r i_opt
               case $i_opt in
                   1) INSTAGRAM_URL="rtmp://127.0.0.1:19351/rtmp/" ;;
                   2)
                      echo -e "Enter Custom Instagram Server URL: "
                      read -r i_url
                      if [ ! -z "$i_url" ]; then
                          INSTAGRAM_URL="$i_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            7)
               prompt_for_key "X (Twitter)" "X_KEY"
               echo -e "Select X Server:"
               echo "  1) Secure (rtmps://va.pscp.tv:443 -> via Stunnel)"
               echo "  2) Custom URL"
               echo -e "Option (Current URL: $X_URL): \c"
               read -r x_opt
               case $x_opt in
                   1) X_URL="rtmp://127.0.0.1:19354/x/" ;;
                   2)
                      echo -e "Enter Custom X Server URL: "
                      read -r x_url
                      if [ ! -z "$x_url" ]; then
                          X_URL="$x_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            8)
               prompt_for_key "Trovo" "TROVO_KEY"
               echo -e "Select Trovo Server:"
               echo "  1) Primary (rtmp://livepush.trovo.live/live/)"
               echo "  2) Custom URL"
               echo -e "Option (Current URL: $TROVO_URL): \c"
               read -r tr_opt
               case $tr_opt in
                   1) TROVO_URL="rtmp://livepush.trovo.live/live/" ;;
                   2)
                      echo -e "Enter Custom Trovo Server URL: "
                      read -r tr_url
                      if [ ! -z "$tr_url" ]; then
                          TROVO_URL="$tr_url"
                      fi
                      ;;
               esac
               save_config
               ;;
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

configure_vertical_keys() {
    while true; do
        clear
        echo -e "${GREEN}=== Configure Vertical Stream Keys ===${NC}"
        echo -e "${YELLOW}Note: Vertical is officially supported on: YouTube, Twitch and TikTok.${NC}"
        echo "1) YouTube (Current: ${V_YOUTUBE_KEY:-None})"
        echo "2) Twitch (Current: ${V_TWITCH_KEY:-None})"
        echo "3) Kick (Current: ${V_KICK_KEY:-None})"
        echo "4) TikTok (Current: ${V_TIKTOK_KEY:-None})"
        echo "5) Facebook (Current: ${V_FACEBOOK_KEY:-None})"
        echo "6) Instagram (Current: ${V_INSTAGRAM_KEY:-None})"
        echo "7) X (Twitter) (Current: ${V_X_KEY:-None})"
        echo "8) Trovo (Current: ${V_TROVO_KEY:-None})"
        echo "9) Custom RTMP (Current URL: ${V_RTMP1_URL:-None})"
        echo "10) Mirror Horizontal Keys (Auto-fill from Horizontal)"
        echo "11) Back to Main Menu"
        echo -e "Select an option: \c"
        read -r choice

        case $choice in
            1)
               prompt_for_key "YouTube Vertical Key" "V_YOUTUBE_KEY"
               echo -e "Select YouTube Server:"
               echo "  1) Primary (rtmp://x.rtmp.youtube.com/live2/)"
               echo "  2) Backup (rtmp://b.rtmp.youtube.com/live2?backup=1)"
               echo "  3) Secure Primary (rtmps://a.rtmps.youtube.com/live2/ -> via Stunnel)"
               echo "  4) Secure Backup (rtmps://b.rtmps.youtube.com/live2?backup=1 -> via Stunnel)"
               echo "  5) Custom URL"
               echo -e "Option (Current URL: $V_YOUTUBE_URL): \c"
               read -r y_opt
               case $y_opt in
                   1) V_YOUTUBE_URL="rtmp://x.rtmp.youtube.com/live2/" ;;
                   2) V_YOUTUBE_URL="rtmp://b.rtmp.youtube.com/live2?backup=1" ;;
                   3) V_YOUTUBE_URL="rtmp://127.0.0.1:19355/live2/" ;;
                   4) V_YOUTUBE_URL="rtmp://127.0.0.1:19357/live2?backup=1" ;;
                   5)
                      echo -e "Enter Custom YouTube Server URL: "
                      read -r y_url
                      if [ ! -z "$y_url" ]; then
                          V_YOUTUBE_URL="$y_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            2)
               prompt_for_key "Twitch Vertical Key" "V_TWITCH_KEY"
               echo -e "Select Twitch Server:"
               echo "  1) Global (rtmp://ingest.global-contribute.live-video.net/app/)"
               echo "  2) Secure Global (rtmps://ingest.global-contribute.live-video.net:443 -> Stunnel)"
               echo "  3) US East: Ashburn (rtmp://iad05.contribute.live-video.net/app/)"
               echo "  4) US East: New York (rtmp://jfk05.contribute.live-video.net/app/)"
               echo "  5) US East: Chicago (rtmp://ord02.contribute.live-video.net/app/)"
               echo "  6) US East: Miami (rtmp://mia05.contribute.live-video.net/app/)"
               echo "  7) US Central: Dallas (rtmp://dfw01.contribute.live-video.net/app/)"
               echo "  8) US West: San Jose (rtmp://sjc05.contribute.live-video.net/app/)"
               echo "  9) US West: Seattle (rtmp://sea01.contribute.live-video.net/app/)"
               echo "  10) US West: Los Angeles (rtmp://lax05.contribute.live-video.net/app/)"
               echo "  11) EU: Frankfurt (rtmp://fra02.contribute.live-video.net/app/)"
               echo "  12) EU: London (rtmp://lhr03.contribute.live-video.net/app/)"
               echo "  13) EU: Amsterdam (rtmp://ams03.contribute.live-video.net/app/)"
               echo "  14) Asia: Tokyo (rtmp://tyo01.contribute.live-video.net/app/)"
               echo "  15) Asia: Seoul (rtmp://icn01.contribute.live-video.net/app/)"
               echo "  16) Asia: Singapore (rtmp://sin01.contribute.live-video.net/app/)"
               echo "  17) Australia: Sydney (rtmp://syd01.contribute.live-video.net/app/)"
               echo "  18) Custom URL"
               echo -e "Option (Current URL: $V_TWITCH_URL): \c"
               read -r t_opt
               case $t_opt in
                   1) V_TWITCH_URL="rtmp://ingest.global-contribute.live-video.net/app/" ;;
                   2) V_TWITCH_URL="rtmp://127.0.0.1:19353/app/" ;;
                   3) V_TWITCH_URL="rtmp://iad05.contribute.live-video.net/app/" ;;
                   4) V_TWITCH_URL="rtmp://jfk05.contribute.live-video.net/app/" ;;
                   5) V_TWITCH_URL="rtmp://ord02.contribute.live-video.net/app/" ;;
                   6) V_TWITCH_URL="rtmp://mia05.contribute.live-video.net/app/" ;;
                   7) V_TWITCH_URL="rtmp://dfw01.contribute.live-video.net/app/" ;;
                   8) V_TWITCH_URL="rtmp://sjc05.contribute.live-video.net/app/" ;;
                   9) V_TWITCH_URL="rtmp://sea01.contribute.live-video.net/app/" ;;
                   10) V_TWITCH_URL="rtmp://lax05.contribute.live-video.net/app/" ;;
                   11) V_TWITCH_URL="rtmp://fra02.contribute.live-video.net/app/" ;;
                   12) V_TWITCH_URL="rtmp://lhr03.contribute.live-video.net/app/" ;;
                   13) V_TWITCH_URL="rtmp://ams03.contribute.live-video.net/app/" ;;
                   14) V_TWITCH_URL="rtmp://tyo01.contribute.live-video.net/app/" ;;
                   15) V_TWITCH_URL="rtmp://icn01.contribute.live-video.net/app/" ;;
                   16) V_TWITCH_URL="rtmp://sin01.contribute.live-video.net/app/" ;;
                   17) V_TWITCH_URL="rtmp://syd01.contribute.live-video.net/app/" ;;
                   18)
                      echo -e "Enter Custom Twitch Server URL: "
                      read -r t_url
                      if [ ! -z "$t_url" ]; then
                          V_TWITCH_URL="$t_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            3)
               prompt_for_key "Kick Vertical" "V_KICK_KEY"
               echo -e "Select Kick Server:"
               echo "  1) Standard (rtmp://live.kick.com/app/)"
               echo "  2) Secure (rtmps://fa723fc1b171.global-contribute.live-video.net:443 -> via Stunnel)"
               echo "  3) Custom URL"
               echo -e "Option (Current URL: $V_KICK_URL): \c"
               read -r k_opt
               case $k_opt in
                   1) V_KICK_URL="rtmp://live.kick.com/app/" ;;
                   2) V_KICK_URL="rtmp://127.0.0.1:19356/kick/" ;;
                   3)
                      echo -e "Enter Custom Kick Server URL: "
                      read -r k_url
                      if [ ! -z "$k_url" ]; then
                          V_KICK_URL="$k_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            4)
               prompt_for_key "TikTok Vertical Key" "V_TIKTOK_KEY"
               echo -e "Select TikTok Server:"
               echo "  1) Secure (rtmps://push-rtmp-f5-ap-southeast-1.tiktokcdn.com:443 -> via Stunnel)"
               echo "  2) Custom URL"
               echo -e "Option (Current URL: $V_TIKTOK_URL): \c"
               read -r tt_opt
               case $tt_opt in
                   1) V_TIKTOK_URL="rtmp://127.0.0.1:19358/s_v/" ;;
                   2)
                      echo -e "Enter Custom TikTok Server URL: "
                      read -r tt_url
                      if [ ! -z "$tt_url" ]; then
                          V_TIKTOK_URL="$tt_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            5)
               prompt_for_key "Facebook Vertical" "V_FACEBOOK_KEY"
               echo -e "Select Facebook Server:"
               echo "  1) Secure (rtmps://live-api-s.facebook.com:443 -> via Stunnel)"
               echo "  2) Custom URL"
               echo -e "Option (Current URL: $V_FACEBOOK_URL): \c"
               read -r f_opt
               case $f_opt in
                   1) V_FACEBOOK_URL="rtmp://127.0.0.1:19350/rtmp/" ;;
                   2)
                      echo -e "Enter Custom Facebook Server URL: "
                      read -r f_url
                      if [ ! -z "$f_url" ]; then
                          V_FACEBOOK_URL="$f_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            6)
               prompt_for_key "Instagram Vertical" "V_INSTAGRAM_KEY"
               echo -e "Select Instagram Server:"
               echo "  1) Secure (rtmps://live-upload.instagram.com:443 -> via Stunnel)"
               echo "  2) Custom URL"
               echo -e "Option (Current URL: $V_INSTAGRAM_URL): \c"
               read -r i_opt
               case $i_opt in
                   1) V_INSTAGRAM_URL="rtmp://127.0.0.1:19351/rtmp/" ;;
                   2)
                      echo -e "Enter Custom Instagram Server URL: "
                      read -r i_url
                      if [ ! -z "$i_url" ]; then
                          V_INSTAGRAM_URL="$i_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            7)
               prompt_for_key "X Vertical" "V_X_KEY"
               echo -e "Select X Server:"
               echo "  1) Secure (rtmps://va.pscp.tv:443 -> via Stunnel)"
               echo "  2) Custom URL"
               echo -e "Option (Current URL: $V_X_URL): \c"
               read -r x_opt
               case $x_opt in
                   1) V_X_URL="rtmp://127.0.0.1:19354/x/" ;;
                   2)
                      echo -e "Enter Custom X Server URL: "
                      read -r x_url
                      if [ ! -z "$x_url" ]; then
                          V_X_URL="$x_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            8)
               prompt_for_key "Trovo Vertical" "V_TROVO_KEY"
               echo -e "Select Trovo Server:"
               echo "  1) Primary (rtmp://livepush.trovo.live/live/)"
               echo "  2) Custom URL"
               echo -e "Option (Current URL: $V_TROVO_URL): \c"
               read -r tr_opt
               case $tr_opt in
                   1) V_TROVO_URL="rtmp://livepush.trovo.live/live/" ;;
                   2)
                      echo -e "Enter Custom Trovo Server URL: "
                      read -r tr_url
                      if [ ! -z "$tr_url" ]; then
                          V_TROVO_URL="$tr_url"
                      fi
                      ;;
               esac
               save_config
               ;;
            9)
               echo -e "Enter Custom RTMP Vertical Server URL (Current: $V_RTMP1_URL): "
               read -r c_url
               if [ ! -z "$c_url" ]; then
                   V_RTMP1_URL="$c_url"
                   save_config
               fi
               prompt_for_key "Custom RTMP Vertical Key" "V_RTMP1_KEY"
               ;;
            10)
               echo -e "${YELLOW}Mirroring Horizontal keys...${NC}"
               V_YOUTUBE_KEY="$YOUTUBE_KEY"
               # For YouTube, if horizontal is using primary, automatically use backup for vertical to avoid conflicts
               if [[ "$YOUTUBE_URL" == *"x.rtmp.youtube.com"* ]] || [[ "$YOUTUBE_URL" == *"19355"* ]]; then
                   echo -e "${YELLOW}Note: Automatically selected YouTube Backup server for vertical stream.${NC}"
                   # If horizontal is using secure primary (19355), use secure backup (19357)
                   if [[ "$YOUTUBE_URL" == *"19355"* ]]; then
                       V_YOUTUBE_URL="rtmp://127.0.0.1:19357/live2?backup=1"
                   else
                       V_YOUTUBE_URL="rtmp://b.rtmp.youtube.com/live2?backup=1"
                   fi
               else
                   V_YOUTUBE_URL="$YOUTUBE_URL"
               fi
               V_TWITCH_KEY="$TWITCH_KEY"
               V_TWITCH_URL="$TWITCH_URL"
               V_TIKTOK_KEY="$TIKTOK_KEY"
               V_TIKTOK_URL="$TIKTOK_URL"
               V_KICK_KEY="$KICK_KEY"
               V_KICK_URL="$KICK_URL"
               V_FACEBOOK_KEY="$FACEBOOK_KEY"
               V_FACEBOOK_URL="$FACEBOOK_URL"
               V_INSTAGRAM_KEY="$INSTAGRAM_KEY"
               V_INSTAGRAM_URL="$INSTAGRAM_URL"
               V_X_KEY="$X_KEY"
               V_X_URL="$X_URL"
               V_TROVO_KEY="$TROVO_KEY"
               V_TROVO_URL="$TROVO_URL"
               V_RTMP1_KEY="$RTMP1_KEY"
               V_RTMP1_URL="$RTMP1_URL"
               save_config
               echo -e "${GREEN}Mirrored.${NC}"
               sleep 1
               ;;
            11) break ;;
            *) echo -e "${RED}Invalid option${NC}" ; sleep 1 ;;
        esac
    done
}

configure_obs() {
    clear
    echo -e "${GREEN}=== OBS Configuration ===${NC}"
    # Determine the public IP if possible, or fallback to placeholder
    SERVER_IP=$(curl -4 -s ifconfig.me || echo "<your_server_ip>")

    # Use Domain if set, otherwise IP
    DISPLAY_HOST=${SERVER_DOMAIN:-$SERVER_IP}

    echo -e "To stream to this server from OBS or another encoder:"
    echo -e "  ${YELLOW}Horizontal URL:${NC} rtmp://${DISPLAY_HOST}:1935/${APP_NAME}"
    echo -e "  ${YELLOW}Vertical URL:${NC}   rtmp://${DISPLAY_HOST}:1935/vertical"
    echo ""
    echo -e "--- Combined Chat ---"
    echo -e "You can use the combined chat as a browser source in OBS:"
    echo -e "  ${YELLOW}URL:${NC} http://${DISPLAY_HOST}:8081/chat.html?twitch=YOUR_CHANNEL&youtube=YOUR_VIDEO_ID"
    echo -e "  (Replace YOUR_CHANNEL and YOUR_VIDEO_ID as needed)"
    echo ""
    echo -e "--- Security Key ---"
    echo -e "PrismRTMPS requires a matching stream key to accept your stream."
    echo -e "Current Custom OBS Key: ${OBS_KEY:-None}"
    echo -e "Enter new Custom OBS Key (Type 'disable' to remove, or press Enter to keep current): "
    read -r obs_input
    if [ "$obs_input" == "disable" ] || [ "$obs_input" == "DISABLE" ]; then
        OBS_KEY=""
        echo -e "${GREEN}Custom OBS Key removed.${NC}"
    elif [ ! -z "$obs_input" ]; then
        OBS_KEY="$obs_input"
        echo -e "${GREEN}Custom OBS Key updated.${NC}"
    fi

    echo ""
    echo -e "--- Custom Application Name ---"
    echo -e "Current Path: /${APP_NAME}"
    echo -e "Enter new RTMP Path/Application name (e.g. cookies):"
    echo -e "(Leave blank to keep current):"
    read -r app_input
    if [ ! -z "$app_input" ]; then
        # Basic sanitization: remove everything except alphanumeric
        app_input=$(echo "$app_input" | sed 's/[^a-zA-Z0-9]//g')
        if [ ! -z "$app_input" ]; then
            APP_NAME="$app_input"
            echo -e "${GREEN}Application name updated to: $APP_NAME${NC}"
        else
             echo -e "${RED}Invalid application name. Keeping current: $APP_NAME${NC}"
        fi
    fi

    save_config
    sleep 2
}

configure_domain() {
    while true; do
        clear
        echo -e "${GREEN}=== Domain / Reverse Proxy Configuration ===${NC}"
        echo -e "1) Domain Name (Current: ${SERVER_DOMAIN:-None})"
        echo -e "2) Let's Encrypt Email (Current: ${LETSENCRYPT_EMAIL:-None})"
        echo -e "3) Back to Main Menu"
        echo -e "Select an option: \c"
        read -r dom_opt

        case $dom_opt in
            1)
                echo -e "Enter your domain (e.g. stream.yourdomain.com):"
                echo -e "(Leave blank to keep current, type 'disable' to use IP)"
                read -r dom_input
                if [ "$dom_input" == "disable" ] || [ "$dom_input" == "DISABLE" ]; then
                    SERVER_DOMAIN=""
                    echo -e "${GREEN}Domain disabled, using IP.${NC}"
                elif [ ! -z "$dom_input" ]; then
        # Basic sanitization for domain to prevent command injection
                    dom_input=$(echo "$dom_input" | sed 's/[^a-zA-Z0-9.-]//g')
                    if [ ! -z "$dom_input" ]; then
                        SERVER_DOMAIN="$dom_input"
                        echo -e "${GREEN}Domain updated to: $SERVER_DOMAIN${NC}"
                        echo -e "${YELLOW}Note: If using Cloudflare, ensure the record is 'DNS Only' (Grey Cloud).${NC}"
                    else
                        echo -e "${RED}Invalid domain name.${NC}"
                    fi
                fi
                save_config
                sleep 1
                ;;
            2)
                echo -e "Enter Email for Let's Encrypt (required for SSL):"
                read -r email_input
                if [ ! -z "$email_input" ]; then
                    LETSENCRYPT_EMAIL="$email_input"
                    save_config
                fi
                ;;
            3) break ;;
            *) echo -e "${RED}Invalid option${NC}" ; sleep 1 ;;
        esac
    done
}

configure_whitelist() {
    clear
    echo -e "${GREEN}=== IP Whitelist Configuration ===${NC}"
    echo -e "Current Accepted IPs: ${YELLOW}${ACCEPTED_IP:-None (Allow All)}${NC}"
    echo ""
    echo -e "Enter IP addresses to whitelist (comma-separated for multiple, e.g. 1.2.3.4,5.6.7.8):"
    echo -e "(Leave blank to keep current, type 'disable' to allow all):"
    read -r ip_input
    if [ "$ip_input" == "disable" ] || [ "$ip_input" == "DISABLE" ]; then
        ACCEPTED_IP=""
        echo -e "${GREEN}IP Whitelist disabled. All IPs allowed.${NC}"
    elif [ ! -z "$ip_input" ]; then
        # Basic sanitization: allow numbers, dots, and commas for whitelisted IPs
        ip_input=$(echo "$ip_input" | sed 's/[^0-9.,]//g')
        if [ ! -z "$ip_input" ]; then
            ACCEPTED_IP="$ip_input"
            echo -e "${GREEN}IP Whitelist updated to: $ACCEPTED_IP${NC}"
        else
            echo -e "${RED}Invalid IP format.${NC}"
        fi
    fi
    save_config
    sleep 2
}

configure_titles() {
    while true; do
        clear
        echo -e "${GREEN}=== Stream Titles & Twitch API Configuration ===${NC}"
        echo "1) Base Title (Current: $STREAM_BASE_TITLE)"
        echo "2) Twitch Client ID (Current: ${TWITCH_CLIENT_ID:-None})"
        echo "3) Twitch OAuth Token (Current: ${TWITCH_OAUTH_TOKEN:-None})"
        echo "4) Twitch Broadcaster ID (Current: ${TWITCH_BROADCASTER_ID:-None})"
        echo "5) Reset Episode Count"
        echo "6) Back to Main Menu"
        echo -e "Select an option: \c"
        read -r title_opt

        case $title_opt in
            1)
                echo -e "Enter Base Stream Title:"
                read -r title_input
                STREAM_BASE_TITLE="$title_input"
                save_config
                ;;
            2)
                echo -e "Enter Twitch Client ID:"
                read -r title_input
                TWITCH_CLIENT_ID="$title_input"
                save_config
                ;;
            3)
                echo -e "Enter Twitch OAuth Token (Bearer):"
                read -r title_input
                TWITCH_OAUTH_TOKEN="$title_input"
                save_config
                ;;
            4)
                echo -e "Enter Twitch Broadcaster ID (Numeric):"
                read -r title_input
                TWITCH_BROADCASTER_ID="$title_input"
                save_config
                ;;
            5)
                mkdir -p ./data
                echo "1" > ./data/episode_count.txt
                echo -e "${GREEN}Episode count reset to 1.${NC}"
                sleep 1
                ;;
            6) break ;;
            *) echo -e "${RED}Invalid option${NC}" ; sleep 1 ;;
        esac
    done
}

configure_chat() {
    while true; do
        clear
        echo -e "${GREEN}=== Combined Chat & Control Configuration ===${NC}"
        echo "1) Twitch Client ID (Current: ${TWITCH_CLIENT_ID:-None})"
        echo "2) Twitch Client Secret (Current: ${TWITCH_CLIENT_SECRET:+********})"
        echo "3) Twitch Redirect URI (Current: ${TWITCH_REDIRECT_URI:-None})"
        echo "4) YouTube Client ID (Current: ${YOUTUBE_CLIENT_ID:-None})"
        echo "5) YouTube Client Secret (Current: ${YOUTUBE_CLIENT_SECRET:+********})"
        echo "6) YouTube Redirect URI (Current: ${YOUTUBE_REDIRECT_URI:-None})"
        echo "7) Show Dashboard URL"
        echo "8) Back to Main Menu"
        echo -e "Select an option: \c"
        read -r chat_opt

        case $chat_opt in
            1)
                echo -e "Enter Twitch Client ID:"
                read -r chat_input
                TWITCH_CLIENT_ID="$chat_input"
                save_config
                ;;
            2)
                echo -e "Enter Twitch Client Secret:"
                read -r chat_input
                TWITCH_CLIENT_SECRET="$chat_input"
                save_config
                ;;
            3)
                SERVER_IP=$(curl -4 -s ifconfig.me || echo "<your_server_ip>")
                DISPLAY_HOST=${SERVER_DOMAIN:-$SERVER_IP}
                echo -e "Enter Twitch Redirect URI (Default: http://${DISPLAY_HOST}:8081/callback/twitch):"
                read -r chat_input
                TWITCH_REDIRECT_URI="${chat_input:-http://${DISPLAY_HOST}:8081/callback/twitch}"
                save_config
                ;;
            4)
                echo -e "Enter YouTube Client ID:"
                read -r chat_input
                YOUTUBE_CLIENT_ID="$chat_input"
                save_config
                ;;
            5)
                echo -e "Enter YouTube Client Secret:"
                read -r chat_input
                YOUTUBE_CLIENT_SECRET="$chat_input"
                save_config
                ;;
            6)
                SERVER_IP=$(curl -4 -s ifconfig.me || echo "<your_server_ip>")
                DISPLAY_HOST=${SERVER_DOMAIN:-$SERVER_IP}
                echo -e "Enter YouTube Redirect URI (Default: http://${DISPLAY_HOST}:8081/callback/youtube):"
                read -r chat_input
                YOUTUBE_REDIRECT_URI="${chat_input:-http://${DISPLAY_HOST}:8081/callback/youtube}"
                save_config
                ;;
            7)
                SERVER_IP=$(curl -4 -s ifconfig.me || echo "<your_server_ip>")
                DISPLAY_HOST=${SERVER_DOMAIN:-$SERVER_IP}
                echo -e "\n${YELLOW}Control Dashboard URL:${NC}"
                echo -e "${GREEN}http://${DISPLAY_HOST}:8081/chat.html${NC}"
                echo -e "\nPress Enter to continue..."
                read -r
                ;;
            8) break ;;
            *) echo -e "${RED}Invalid option${NC}" ; sleep 1 ;;
        esac
    done
}

configure_tiktok_dynamic() {
    while true; do
        clear
        echo -e "${GREEN}=== TikTok Dynamic Key Configuration (Streamlabs) ===${NC}"
        echo -e "${YELLOW}This allows PrismRTMPS to automatically generate a new TikTok stream key each time you go live.${NC}"
        echo -e "${YELLOW}Note: Dynamic keys are applied to the VERTICAL stream only.${NC}"
        echo -e "${YELLOW}If enabled, this will override manual TikTok stream key settings.${NC}"
        echo ""
        echo "1) Streamlabs TikTok Token (Current: ${TIKTOK_SL_TOKEN:+********})"
        echo "2) Stream Title (Current: $TIKTOK_TITLE)"
        echo "3) Game Category (Current: $TIKTOK_GAME_NAME)"
        echo "4) Back to Main Menu"
        echo -e "Select an option: \c"
        read -r tt_dyn_opt

        case $tt_dyn_opt in
            1)
                echo -e "Enter Streamlabs TikTok API Token:"
                read -r token_input
                TIKTOK_SL_TOKEN="$token_input"
                save_config
                ;;
            2)
                echo -e "Enter Stream Title:"
                read -r title_input
                TIKTOK_TITLE="$title_input"
                save_config
                ;;
            3)
                if [ -z "$TIKTOK_SL_TOKEN" ]; then
                    echo -e "${RED}Error: Set Streamlabs Token first!${NC}"
                    sleep 2
                    continue
                fi
                echo -e "Enter Game Name to search (e.g. 'Just Chatting', 'Minecraft'):"
                read -r search_query
                echo "Searching..."
                # Run search using a temporary python check
                SEARCH_RESULTS=$(TIKTOK_TOKEN="$TIKTOK_SL_TOKEN" SEARCH_QUERY="$search_query" python3 -c "
import requests, os
token = os.getenv('TIKTOK_TOKEN')
query = os.getenv('SEARCH_QUERY', '')[:25]
s = requests.session()
s.headers.update({'user-agent': 'Mozilla/5.0', 'authorization': f'Bearer {token}'})
try:
    r = s.get(f'https://streamlabs.com/api/v5/slobs/tiktok/info?category={query}').json()
    for c in r.get('categories', []):
        print(f\"{c['game_mask_id']}|{c['full_name']}\")
except:
    pass
" 2>/dev/null)
                
                if [ -z "$SEARCH_RESULTS" ]; then
                    echo -e "${RED}No categories found.${NC}"
                    sleep 2
                else
                    echo -e "\n${YELLOW}Search Results:${NC}"
                    IFS=$'\n'
                    count=1
                    declare -a ids
                    declare -a names
                    for line in $SEARCH_RESULTS; do
                        id=$(echo "$line" | cut -d'|' -f1)
                        name=$(echo "$line" | cut -d'|' -f2)
                        ids[$count]=$id
                        names[$count]=$name
                        echo "$count) $name"
                        ((count++))
                    done
                    echo -e "Select a category number: \c"
                    read -r cat_choice
                    if [[ "$cat_choice" =~ ^[0-9]+$ ]] && [ "$cat_choice" -lt "$count" ]; then
                        TIKTOK_GAME_ID="${ids[$cat_choice]}"
                        TIKTOK_GAME_NAME="${names[$cat_choice]}"
                        echo -e "${GREEN}Selected: $TIKTOK_GAME_NAME${NC}"
                        save_config
                    else
                        echo -e "${RED}Invalid selection.${NC}"
                    fi
                    sleep 2
                fi
                ;;
            4) break ;;
            *) echo -e "${RED}Invalid option${NC}" ; sleep 1 ;;
        esac
    done
}

configure_noalbs() {
    while true; do
        clear
        echo -e "${GREEN}=== NOALBS & OBS Scene Switcher ===${NC}"
        echo "1) Enable NOALBS (Current: ${NOALBS_ENABLED})"
        echo "2) Low Bitrate Threshold (Current: ${LOW_BITRATE} kbps)"
        echo "3) Restore Bitrate Threshold (Current: ${RESTORE_BITRATE} kbps)"
        echo "4) OBS WebSocket Host (Current: ${OBS_WS_HOST:-None})"
        echo "5) OBS WebSocket Port (Current: ${OBS_WS_PORT})"
        echo "6) OBS WebSocket Password (Current: ${OBS_WS_PASSWORD:+********})"
        echo "7) OBS Main Scene Name (Current: ${OBS_SCENE_LIVE})"
        echo "8) OBS BRB Scene Name (Current: ${OBS_SCENE_BRB})"
        echo "9) Upload BRB Video (Beta) (Current: ${BRB_VIDEO_PATH:-None})"
        echo "10) Back to Main Menu"
        echo -e "Select an option: \c"
        read -r no_opt

        case $no_opt in
            1)
                if [ "$NOALBS_ENABLED" == "true" ]; then NOALBS_ENABLED="false"; else NOALBS_ENABLED="true"; fi
                save_config
                ;;
            2)
                echo -e "Enter Low Bitrate Threshold (kbps, e.g. 1000):"
                read -r low_input
                LOW_BITRATE="${low_input:-1000}"
                save_config
                ;;
            3)
                echo -e "Enter Restore Bitrate Threshold (kbps, e.g. 1500):"
                read -r res_input
                RESTORE_BITRATE="${res_input:-1500}"
                save_config
                ;;
            4)
                echo -e "Enter OBS WebSocket Host (IP of your OBS PC):"
                read -r ws_host
                OBS_WS_HOST="$ws_host"
                save_config
                ;;
            5)
                echo -e "Enter OBS WebSocket Port (Default 4455):"
                read -r ws_port
                OBS_WS_PORT="${ws_port:-4455}"
                save_config
                ;;
            6)
                echo -e "Enter OBS WebSocket Password:"
                read -r ws_pass
                OBS_WS_PASSWORD="$ws_pass"
                save_config
                ;;
            7)
                echo -e "Enter Main Scene Name (Default: Main):"
                read -r scene_live
                OBS_SCENE_LIVE="${scene_live:-Main}"
                save_config
                ;;
            8)
                echo -e "Enter BRB Scene Name (Default: BRB):"
                read -r scene_brb
                OBS_SCENE_BRB="${scene_brb:-BRB}"
                save_config
                ;;
            9)
                echo -e "Enter full path to BRB video file (e.g. /home/user/brb.mp4):"
                read -r video_input
                if [ -f "$video_input" ]; then
                    BRB_VIDEO_PATH="$video_input"
                    echo -e "${GREEN}Video path saved.${NC}"
                    save_config
                else
                    echo -e "${RED}Error: File not found.${NC}"
                    sleep 1
                fi
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
        curl -4 -fsSL https://get.docker.com -o get-docker.sh
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

    # Auto-fill vertical from horizontal if horizontal is set but vertical is not (YouTube, Twitch, TikTok)
    if [ ! -z "$YOUTUBE_KEY" ] && [ -z "$V_YOUTUBE_KEY" ]; then
        V_YOUTUBE_KEY="$YOUTUBE_KEY"
        # For YouTube, if horizontal is using primary, automatically use backup for vertical to avoid conflicts
        if [[ "$YOUTUBE_URL" == *"x.rtmp.youtube.com"* ]] || [[ "$YOUTUBE_URL" == *"19355"* ]]; then
            # If horizontal is using secure primary (19355), use secure backup (19357)
            if [[ "$YOUTUBE_URL" == *"19355"* ]]; then
                V_YOUTUBE_URL="rtmp://127.0.0.1:19357/live2?backup=1"
            else
                V_YOUTUBE_URL="rtmp://b.rtmp.youtube.com/live2?backup=1"
            fi
        else
            V_YOUTUBE_URL="$YOUTUBE_URL"
        fi
    fi
    if [ ! -z "$TWITCH_KEY" ] && [ -z "$V_TWITCH_KEY" ]; then
        V_TWITCH_KEY="$TWITCH_KEY"
        V_TWITCH_URL="$TWITCH_URL"
    fi
    if [ ! -z "$TIKTOK_KEY" ] && [ -z "$V_TIKTOK_KEY" ]; then
        V_TIKTOK_KEY="$TIKTOK_KEY"
        V_TIKTOK_URL="$TIKTOK_URL"
    fi

    # Check if any keys are set
    ANY_KEY_SET=0
    for key in "$YOUTUBE_KEY" "$FACEBOOK_KEY" "$INSTAGRAM_KEY" "$TIKTOK_KEY" "$TWITCH_KEY" "$KICK_KEY" "$X_KEY" "$TROVO_KEY" "$RTMP1_KEY" \
               "$V_YOUTUBE_KEY" "$V_TWITCH_KEY" "$V_KICK_KEY" "$V_TIKTOK_KEY" "$V_FACEBOOK_KEY" "$V_INSTAGRAM_KEY" "$V_X_KEY" "$V_TROVO_KEY" "$V_RTMP1_KEY" \
               "$TIKTOK_SL_TOKEN"; do
        if [ ! -z "$key" ]; then
            ANY_KEY_SET=1
            break
        fi
    done

    if [ "$ANY_KEY_SET" -eq 0 ]; then
        echo -e "${RED}No stream keys (Horizontal or Vertical) have been configured.${NC}"
        echo -e "${YELLOW}Aborting installation as per configuration rules.${NC}"
        echo -e "Press Enter to return to menu..."
        read -r
        return
    fi

    echo -e "${GREEN}Building Docker Image...${NC}"
    docker build -t prism-rtmps .

    echo -e "${GREEN}Stopping any existing container...${NC}"
    docker stop prism-rtmps 2>/dev/null || true
    docker rm prism-rtmps 2>/dev/null || true

    echo -e "${GREEN}Starting container...${NC}"
    # Start the container
    # Handle BRB video volume mapping
    BRB_MAPPING=""
    if [ -f "$BRB_VIDEO_PATH" ]; then
        BRB_MAPPING="-v $BRB_VIDEO_PATH:/app/data/brb_video.mp4"
    fi

    docker run -d --name prism-rtmps \
        -v "$(pwd)/data:/app/data" \
        -v "$(pwd)/letsencrypt:/etc/letsencrypt" \
        -v "$(pwd)/certbot_www:/var/www/certbot" \
        $BRB_MAPPING \
        -p 1935:1935 \
        -p 80:80 \
        -p 443:443 \
        -p 8081:8081 \
        --restart unless-stopped \
        -e YOUTUBE_URL="$YOUTUBE_URL" \
        -e YOUTUBE_KEY="$YOUTUBE_KEY" \
        -e FACEBOOK_URL="$FACEBOOK_URL" \
        -e FACEBOOK_KEY="$FACEBOOK_KEY" \
        -e INSTAGRAM_URL="$INSTAGRAM_URL" \
        -e INSTAGRAM_KEY="$INSTAGRAM_KEY" \
        -e TIKTOK_URL="$TIKTOK_URL" \
        -e TIKTOK_KEY="$TIKTOK_KEY" \
        -e TWITCH_URL="$TWITCH_URL" \
        -e TWITCH_KEY="$TWITCH_KEY" \
        -e KICK_URL="$KICK_URL" \
        -e KICK_KEY="$KICK_KEY" \
        -e X_URL="$X_URL" \
        -e X_KEY="$X_KEY" \
        -e TROVO_URL="$TROVO_URL" \
        -e TROVO_KEY="$TROVO_KEY" \
        -e RTMP1_URL="$RTMP1_URL" \
        -e RTMP1_KEY="$RTMP1_KEY" \
        -e V_YOUTUBE_URL="$V_YOUTUBE_URL" \
        -e V_YOUTUBE_KEY="$V_YOUTUBE_KEY" \
        -e V_TWITCH_URL="$V_TWITCH_URL" \
        -e V_TWITCH_KEY="$V_TWITCH_KEY" \
        -e V_KICK_URL="$V_KICK_URL" \
        -e V_KICK_KEY="$V_KICK_KEY" \
        -e V_TIKTOK_URL="$V_TIKTOK_URL" \
        -e V_TIKTOK_KEY="$V_TIKTOK_KEY" \
        -e V_FACEBOOK_URL="$V_FACEBOOK_URL" \
        -e V_FACEBOOK_KEY="$V_FACEBOOK_KEY" \
        -e V_INSTAGRAM_URL="$V_INSTAGRAM_URL" \
        -e V_INSTAGRAM_KEY="$V_INSTAGRAM_KEY" \
        -e V_X_URL="$V_X_URL" \
        -e V_X_KEY="$V_X_KEY" \
        -e V_TROVO_URL="$V_TROVO_URL" \
        -e V_TROVO_KEY="$V_TROVO_KEY" \
        -e V_RTMP1_URL="$V_RTMP1_URL" \
        -e V_RTMP1_KEY="$V_RTMP1_KEY" \
        -e OBS_KEY="$OBS_KEY" \
        -e APP_NAME="$APP_NAME" \
        -e ACCEPTED_IP="$ACCEPTED_IP" \
        -e CHUNK_SIZE="$CHUNK_SIZE" \
        -e STREAM_BASE_TITLE="$STREAM_BASE_TITLE" \
        -e TWITCH_CLIENT_ID="$TWITCH_CLIENT_ID" \
        -e TWITCH_OAUTH_TOKEN="$TWITCH_OAUTH_TOKEN" \
        -e TWITCH_BROADCASTER_ID="$TWITCH_BROADCASTER_ID" \
        -e TWITCH_CLIENT_SECRET="$TWITCH_CLIENT_SECRET" \
        -e TWITCH_REDIRECT_URI="$TWITCH_REDIRECT_URI" \
        -e YOUTUBE_CLIENT_ID="$YOUTUBE_CLIENT_ID" \
        -e YOUTUBE_CLIENT_SECRET="$YOUTUBE_CLIENT_SECRET" \
        -e YOUTUBE_REDIRECT_URI="$YOUTUBE_REDIRECT_URI" \
        -e SECRET_KEY="$SECRET_KEY" \
        -e SERVER_DOMAIN="$SERVER_DOMAIN" \
        -e LETSENCRYPT_EMAIL="$LETSENCRYPT_EMAIL" \
        -e SRT_PORT="$SRT_PORT" \
        -e SRT_PASSPHRASE="$SRT_PASSPHRASE" \
        -e OBS_WS_HOST="$OBS_WS_HOST" \
        -e OBS_WS_PORT="$OBS_WS_PORT" \
        -e OBS_WS_PASSWORD="$OBS_WS_PASSWORD" \
        -e OBS_SCENE_LIVE="$OBS_SCENE_LIVE" \
        -e OBS_SCENE_BRB="$OBS_SCENE_BRB" \
        -e OBS_SCENE_INTRO="$OBS_SCENE_INTRO" \
        -e TIKTOK_SL_TOKEN="$TIKTOK_SL_TOKEN" \
        -e TIKTOK_TITLE="$TIKTOK_TITLE" \
        -e TIKTOK_GAME_ID="$TIKTOK_GAME_ID" \
        prism-rtmps

    if [ $? -eq 0 ]; then
        SERVER_IP=$(curl -4 -s ifconfig.me || echo "<your_server_ip>")
        DISPLAY_HOST=${SERVER_DOMAIN:-$SERVER_IP}
        echo -e "${GREEN}Container 'prism-rtmps' is running!${NC}"
        echo -e "You can stream to: rtmp://${DISPLAY_HOST}:1935/${APP_NAME}"
        echo -e "Vertical stream:  rtmp://${DISPLAY_HOST}:1935/vertical"
        echo -e "Stats available at: http://${DISPLAY_HOST}:8081/stat"
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

    echo -e "${YELLOW}Showing logs for prism-rtmps... (Press Ctrl+C to exit log view)${NC}"
    # Use a subshell and trap INT to ensure script doesn't exit on Ctrl+C
    (trap 'exit 0' INT; docker logs -f prism-rtmps)

    while true; do
        echo -e "\n${GREEN}=== Log Options ===${NC}"
        echo "1) Return to Main Menu"
        echo "2) Clear Logs"
        echo -e "Select an option: \c"
        read -r log_opt

        case $log_opt in
            1) break ;;
            2)
                echo -e "${YELLOW}Clearing logs...${NC}"
                # Truncate internal logs
                docker exec prism-rtmps sh -c 'truncate -s 0 /var/log/nginx/access.log /var/log/nginx/error.log' 2>/dev/null || true
                # Truncate Docker's own log file for the container
                LOG_PATH=$(docker inspect --format='{{.LogPath}}' prism-rtmps 2>/dev/null)
                if [ ! -z "$LOG_PATH" ]; then
                    sudo truncate -s 0 "$LOG_PATH" 2>/dev/null || truncate -s 0 "$LOG_PATH" 2>/dev/null || echo -e "${RED}Failed to truncate Docker log file. You may need sudo.${NC}"
                fi
                echo -e "${GREEN}Logs cleared.${NC}"
                sleep 1
                ;;
            *) echo -e "${RED}Invalid option${NC}" ; sleep 1 ;;
        esac
    done
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

# Cache Server IP for UI Performance
SERVER_IP=$(curl -4 -s ifconfig.me || echo "<your_server_ip>")

while true; do
    clear
    DISPLAY_HOST=${SERVER_DOMAIN:-$SERVER_IP}
    
    # Helper function to get status label
    get_status() {
        if [ "$1" == "true" ] || [ -n "$1" ]; then
            echo -e "${GREEN}(Enabled)${NC}"
        else
            echo -e "${YELLOW}(Optional; disabled)${NC}"
        fi
    }

    echo -e "${GREEN}=====================================${NC}"
    echo -e "${GREEN}     PrismRTMPS Quick Installer      ${NC}"
    echo -e "${GREEN}=====================================${NC}"
    echo -e "${YELLOW}Quick Reference:${NC}"
    echo -e "  RTMP Ingest:     rtmp://${DISPLAY_HOST}:1935/${APP_NAME}"
    echo -e "  Vertical Ingest: rtmp://${DISPLAY_HOST}:1935/vertical"
    echo -e "  Stats URL:       http://${DISPLAY_HOST}:8081/stat"
    echo -e "  Control Dashboard: http://${DISPLAY_HOST}:8081/chat.html"
    echo "-------------------------------------"
    echo "1) Install Docker (if not installed)"
    echo "2) Configure Stream Keys (Horizontal)"
    echo "3) Configure Stream Keys (Vertical)"
    echo "4) Configure OBS Setup & Security Key"
    echo -e "5) Configure Domain / Reverse Proxy $(get_status $SERVER_DOMAIN)"
    echo -e "6) Configure Combined Chat $(get_status $TWITCH_CLIENT_ID)"
    echo -e "7) Configure Stream Titles & Twitch API $(get_status $TWITCH_OAUTH_TOKEN)"
    echo -e "8) Configure IP Whitelist $(get_status $ACCEPTED_IP)"
    echo "9) Configure Optimizations (Chunk Size)"
    echo -e "10) Configure NOALBS Scene Switcher $(get_status $NOALBS_ENABLED)"
    echo -e "11) Configure TikTok Dynamic Key $(get_status $TIKTOK_SL_TOKEN)"
    echo "12) Build & Start Server"
    echo "13) Stop Server"
    echo "14) View Logs"
    echo "15) Quit"
    echo -e "Select an option: \c"
    read -r option

    case $option in
        1) install_docker ;;
        2) configure_keys ;;
        3) configure_vertical_keys ;;
        4) configure_obs ;;
        5) configure_domain ;;
        6) configure_chat ;;
        7) configure_titles ;;
        8) configure_whitelist ;;
        9) configure_optimizations ;;
        10) configure_noalbs ;;
        11) configure_tiktok_dynamic ;;
        12) build_and_run ;;
        13) stop_container ;;
        14) view_logs ;;
        15) clear; echo -e "${GREEN}Goodbye!${NC}"; break ;;
        *) echo -e "${RED}Invalid option${NC}"; sleep 1 ;;
    esac
done
