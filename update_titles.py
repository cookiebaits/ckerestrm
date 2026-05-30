import sys
import os
import requests
from datetime import datetime

# Load config securely if present
env_vars = {}
try:
    with open('rtmp_config.env', 'r') as f:
        for line in f:
            if '=' in line:
                key, val = line.strip().split('=', 1)
                env_vars[key] = val.strip('"').strip("'")
except FileNotFoundError:
    pass

def update_twitch(title):
    client_id = env_vars.get("TWITCH_CLIENT_ID", "")
    token = env_vars.get("TWITCH_OAUTH_TOKEN", "")
    broadcaster_id = env_vars.get("TWITCH_BROADCASTER_ID", "")
    
    if not (client_id and token and broadcaster_id):
        return
        
    headers = {
        'Client-Id': client_id,
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    url = f"https://api.twitch.tv/helix/channels?broadcaster_id={broadcaster_id}"
    data = {"title": title}
    
    try:
        requests.patch(url, headers=headers, json=data)
    except:
        pass

def update_youtube(title):
    # Stub - Requires full OAuth2
    pass

def main():
    auto_title = env_vars.get("AUTO_TITLE", "off")
    if auto_title != "on":
        return

    static_title = env_vars.get("STATIC_TITLE", "Streaming")
    episode = env_vars.get("EPISODE_COUNT", "1")
    date_str = datetime.now().strftime("%Y-%m-%d")
    
    full_title = f"{static_title} | Ep.{episode} | {date_str}"
    
    update_twitch(full_title)
    update_youtube(full_title)
    
    # Increment episode count in config file
    try:
        new_episode = int(episode) + 1
        lines = []
        with open('rtmp_config.env', 'r') as f:
            lines = f.readlines()

        with open('rtmp_config.env', 'w') as f:
            for line in lines:
                if line.startswith('EPISODE_COUNT='):
                    f.write(f'EPISODE_COUNT="{new_episode}"\n')
                else:
                    f.write(line)
    except:
        pass

if __name__ == "__main__":
    main()
