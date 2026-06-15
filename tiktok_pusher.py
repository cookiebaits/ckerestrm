import requests
import sys
import os
import subprocess
import time
import signal
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("TikTokPusher")

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

        max_retries = 5
        for attempt in range(max_retries):
            try:
                response = self.s.post(url, files=files, timeout=30)
                response.raise_for_status()
                data = response.json()
                if "rtmp" in data and "key" in data:
                    self.stream_id = data["id"]
                    return data["rtmp"], data["key"]
                else:
                    logger.warning(f"TikTok API Start attempt {attempt+1} failed: {data}")
            except Exception as e:
                logger.warning(f"TikTok API Start attempt {attempt+1} error: {e}")

            if attempt < max_retries - 1:
                # Exponential backoff
                wait_time = 2 ** (attempt + 1)
                logger.info(f"Retrying in {wait_time} seconds...")
                time.sleep(wait_time)

        raise Exception("Failed to start TikTok stream after 5 attempts")

    def end(self):
        if not self.stream_id:
            return False
        url = f"https://streamlabs.com/api/v5/slobs/tiktok/stream/{self.stream_id}/end"
        try:
            response = self.s.post(url, timeout=30).json()
            return response.get("success", False)
        except Exception as e:
            logger.error(f"Error ending TikTok session: {e}")
            return False

def main():
    token = os.getenv("TIKTOK_SL_TOKEN")
    title = os.getenv("TIKTOK_TITLE", "Live Stream")
    category = os.getenv("TIKTOK_GAME_ID", "")
    rtmp_in = sys.argv[1] # Expected: rtmp://127.0.0.1:1935/tiktok_relay/vertical

    if not token:
        logger.error("TikTok Streamlabs Token not set.")
        sys.exit(1)

    tiktok = TikTokStream(token)

    try:
        logger.info(f"Starting TikTok Vertical Live: {title}...")
        rtmp_out_base, stream_key = tiktok.start(title, category)
        rtmp_out = f"{rtmp_out_base}{stream_key}"
        logger.info(f"TikTok Live Started. ID: {tiktok.stream_id}")

        # Start FFmpeg relay with robust buffering
        ffmpeg_cmd = [
            "ffmpeg", "-hide_banner", "-loglevel", "warning",
            "-i", rtmp_in,
            "-c", "copy",
            "-f", "flv",
            "-flvflags", "no_duration_filesize",
            rtmp_out
        ]

        process = subprocess.Popen(ffmpeg_cmd)

        def handle_signal(signum, frame):
            logger.info(f"Received signal {signum}. Terminating...")
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
            tiktok.end()
            sys.exit(0)

        signal.signal(signal.SIGTERM, handle_signal)
        signal.signal(signal.SIGINT, handle_signal)

        # Monitor process
        while process.poll() is None:
            time.sleep(2)

        logger.info("Relay process finished.")

    except KeyboardInterrupt:
        logger.info("Interrupted by user.")
    except Exception as e:
        logger.error(f"Pusher Error: {e}")
        sys.exit(1)
    finally:
        if tiktok.stream_id:
            logger.info(f"Ending TikTok session {tiktok.stream_id}...")
            if tiktok.end():
                logger.info("Session ended successfully.")
            else:
                logger.warning("Failed to end session via API.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 tiktok_pusher.py <rtmp_input_url>")
        sys.exit(1)
    main()
