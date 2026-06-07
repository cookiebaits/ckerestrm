import requests
import sys
import os
import subprocess
import time
import signal

# Management files
PID_FILE = "/tmp/tiktok_pusher.pid"
TYPE_FILE = "/tmp/tiktok_pusher.type"

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

def cleanup_existing(current_type):
    if os.path.exists(PID_FILE):
        try:
            with open(PID_FILE, 'r') as f:
                old_pid = int(f.read().strip())

            old_type = ""
            if os.path.exists(TYPE_FILE):
                with open(TYPE_FILE, 'r') as f:
                    old_type = f.read().strip()

            # Priority: vertical > live (horizontal)
            if old_type == 'vertical' and current_type == 'live':
                print("Existing Vertical stream has priority. Exiting Horizontal relay.")
                sys.exit(0)

            print(f"Terminating existing {old_type} TikTok relay (PID: {old_pid})...")
            os.kill(old_pid, signal.SIGTERM)
            time.sleep(2) # Give it time to end the session
        except (ProcessLookupError, ValueError, OverflowError):
            pass
        except Exception as e:
            print(f"Cleanup error: {e}")

def main():
    token = os.getenv("TIKTOK_SL_TOKEN")
    title = os.getenv("TIKTOK_TITLE", "Live Stream")
    category = os.getenv("TIKTOK_GAME_ID", "")
    rtmp_in = sys.argv[1] # Expected: rtmp://127.0.0.1:1935/tiktok_relay/stream_name
    stream_type = rtmp_in.split('/')[-1] # 'live' or 'vertical'

    if not token:
        print("TikTok Streamlabs Token not set.")
        sys.exit(1)

    # Manage concurrency and priority
    cleanup_existing(stream_type)

    # Register current process
    with open(PID_FILE, 'w') as f:
        f.write(str(os.getpid()))
    with open(TYPE_FILE, 'w') as f:
        f.write(stream_type)

    tiktok = TikTokStream(token)

    try:
        print(f"Starting TikTok Live ({stream_type}): {title}...")
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
            print(f"Received termination signal. Ending TikTok {stream_type} Live...")
            process.terminate()
            tiktok.end()
            # Clean up files if we are still the registered process
            try:
                with open(PID_FILE, 'r') as f:
                    if int(f.read().strip()) == os.getpid():
                        os.remove(PID_FILE)
                        os.remove(TYPE_FILE)
            except:
                pass
            sys.exit(0)

        signal.signal(signal.SIGTERM, handle_signal)
        signal.signal(signal.SIGINT, handle_signal)

        process.wait()
        print(f"TikTok {stream_type} stream ended. Closing session...")
        tiktok.end()

    except Exception as e:
        print(f"Error: {e}")
        # Ensure we don't leave stale PID files on error
        try:
            os.remove(PID_FILE)
            os.remove(TYPE_FILE)
        except:
            pass
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 tiktok_pusher.py <rtmp_input_url>")
        sys.exit(1)
    main()
