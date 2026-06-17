import requests
import sys

def search_game(token, query):
    s = requests.session()
    s.headers.update({
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) StreamlabsDesktop/1.17.0 Chrome/122.0.6261.156 Electron/29.3.1 Safari/537.36",
        "authorization": f"Bearer {token}"
    })

    query = query[:25]
    url = f"https://streamlabs.com/api/v5/slobs/tiktok/info?category={query}"
    try:
        info = s.get(url).json()
        categories = info.get("categories", [])
        for cat in categories:
            print(f"{cat['game_mask_id']}|{cat['full_name']}")
    except Exception as e:
        sys.stderr.write(f"Error: {e}\n")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 tiktok_search.py <token> <query>")
        sys.exit(1)
    search_game(sys.argv[1], sys.argv[2])
