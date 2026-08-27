import sys
import os
import requests

def update_twitch(title):
    client_id = os.getenv("TWITCH_CLIENT_ID", "")
    token = os.getenv("TWITCH_OAUTH_TOKEN", "")
    broadcaster_id = os.getenv("TWITCH_BROADCASTER_ID", "")

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
        requests.patch(url, headers=headers, json=data, timeout=5)
    except:
        pass

if __name__ == "__main__":
    if len(sys.argv) > 1:
        update_twitch(sys.argv[1])
