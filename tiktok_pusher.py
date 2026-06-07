import requests
import sys
import os
import subprocess
import time
import signal

class TikTokStream:
    def __init__(self, token):
        self.s = requests.session()
        self.s.headers.update({
            "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) StreamlabsDesktop/1.17.0 Chrome/122.0.6261.156 Electron/29.3.1 Safari/537.36",
            "authorization": f"Bearer {token}"
        })
        self.stream_id = None

    def start(self, title, category, audience_type='0'):
        url = "https://streamlabs.com/api/v5/slobs/tiktok/stream/start"
        files = {
            'title': (None, title),
            'device_platform': (None, 'win32'),
            'category': (None, category),
            'audience_type': (None, audience_type),
        }
        response = self.s.post(url, files=files).json()
        if "rtmp" in response and "key" in response:
            self.stream_id = response["id"]
            return response["rtmp"], response["key"]
        else:
            raise Exception(f"Failed to start TikTok stream: {response}")

    def end(self):
        if not self.stream_id:
            return False
        url = f"https://streamlabs.com/api/v5/slobs/tiktok/stream/{self.stream_id}/end"
        response = self.s.post(url).json()
        return response.get("success", False)

def main():
    token = os.getenv("TIKTOK_SL_TOKEN")
    title = os.getenv("TIKTOK_TITLE", "Live Stream")
    category = os.getenv("TIKTOK_GAME_ID", "")
    rtmp_in = sys.argv[1] # Expected: rtmp://127.0.0.1:1935/tiktok_relay/vertical

    if not token:
        print("TikTok Streamlabs Token not set.")
        sys.exit(1)

    tiktok = TikTokStream(token)

    try:
        print(f"Starting TikTok Vertical Live: {title}...")
        rtmp_out_base, stream_key = tiktok.start(title, category)
        rtmp_out = f"{rtmp_out_base}{stream_key}"
        print(f"TikTok Live Started. ID: {tiktok.stream_id}")

        # Start FFmpeg relay
        ffmpeg_cmd = [
            "ffmpeg", "-i", rtmp_in,
            "-c", "copy", "-f", "flv", rtmp_out
        ]

        process = subprocess.Popen(ffmpeg_cmd)

        def handle_signal(signum, frame):
            print("Received termination signal. Ending TikTok Live...")
            process.terminate()
            tiktok.end()
            sys.exit(0)

        signal.signal(signal.SIGTERM, handle_signal)
        signal.signal(signal.SIGINT, handle_signal)

        process.wait()
        print("Stream ended. Closing TikTok Live session...")
        tiktok.end()

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 tiktok_pusher.py <rtmp_input_url>")
        sys.exit(1)
    main()
