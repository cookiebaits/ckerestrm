import sys
import os
import requests

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
        print("    [!] Twitch API credentials missing (Need Client ID, OAuth Token, Broadcaster ID). Update skipped.")
        return

    print("    [*] Pushing to Twitch...")
    headers = {
        'Client-Id': client_id,
        'Authorization': f'Bearer {token}',
        'Content-Type': 'application/json'
    }
    url = f"https://api.twitch.tv/helix/channels?broadcaster_id={broadcaster_id}"
    data = {"title": title}

    try:
        response = requests.patch(url, headers=headers, json=data)
        if response.status_code == 204:
            print("    [+] Twitch Title updated successfully!")
        else:
            print(f"    [-] Twitch API Error: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"    [-] Failed to connect to Twitch: {e}")

def update_youtube(title):
    yt_api_key = env_vars.get("YOUTUBE_API_KEY", "")
    # YouTube requires OAuth2 for broadcast updates, making simple API key calls complex.
    # This acts as a functional stub requiring full google-auth client implementation if token exists.
    if not yt_api_key:
        print("    [!] YouTube API Token missing. Update skipped.")
        return
    print("    [-] YouTube Data API v3 requires full OAuth2 User Consent flow (google-auth). Cannot proceed with simple token.")

def main():
    if len(sys.argv) < 2:
        print("Error: No title provided.")
        sys.exit(1)

    title = sys.argv[1]

    print("\n---------------------------------------------------------")
    print(f"[*] Executing Title Update: \"{title}\"")
    print("---------------------------------------------------------")

    # Execute API calls
    update_twitch(title)
    update_youtube(title)

    print("    [!] Kick does not currently offer a public API for stream titles. Update skipped.")
    print("    [!] TikTok does not currently offer a public API for stream titles. Update skipped.")

    print("\n[i] NOTE: For full automation, set TWITCH_CLIENT_ID, TWITCH_OAUTH_TOKEN, and TWITCH_BROADCASTER_ID")
    print("          in your rtmp_config.env file.")
    print("---------------------------------------------------------\n")

if __name__ == "__main__":
    main()
