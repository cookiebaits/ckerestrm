import requests
import time
import os
import logging
import xml.etree.ElementTree as ET
import obsws_python as obs
import subprocess
import signal
import threading

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger("NOALBS")

class Noalbs:
    def __init__(self):
        self.enabled = os.getenv("NOALBS_ENABLED", "false").lower() == "true"
        self.low_threshold = int(os.getenv("LOW_BITRATE", 1000))
        self.restore_threshold = int(os.getenv("RESTORE_BITRATE", 1500))
        self.obs_host = os.getenv("OBS_WS_HOST", "127.0.0.1")
        self.obs_port = int(os.getenv("OBS_WS_PORT", 4455))
        self.obs_password = os.getenv("OBS_WS_PASSWORD", "")
        self.scene_main = os.getenv("OBS_SCENE_LIVE", "Main")
        self.scene_brb = os.getenv("OBS_SCENE_BRB", "BRB")
        self.app_name = os.getenv("APP_NAME", "live")
        # NOALBS uses internal port 8081 for stats
        self.stats_url = "http://127.0.0.1:8081/stat"

        self.cloud_brb_enabled = os.getenv("CLOUD_BRB", "false").lower() == "true"
        self.brb_video_path = "/app/data/brb_video.mp4"
        self.cloud_process = None

        self.is_low = False
        self.is_streaming = False
        self.obs_client = None
        self.cloud_brb_start_time = None
        self.cloud_brb_timeout = False
        self.session = requests.Session()

    def get_obs_client(self):
        if self.obs_client:
            return self.obs_client
        try:
            # Using ReqClient for scene switching
            self.obs_client = obs.ReqClient(host=self.obs_host, port=self.obs_port, password=self.obs_password, timeout=3)
            return self.obs_client
        except Exception as e:
            logger.error(f"Failed to connect to OBS: {e}")
            self.obs_client = None
            return None

    def get_hardware_encoder(self):
        try:
            # Test NVENC
            nvenc_test = subprocess.run(
                ["ffmpeg", "-v", "error", "-f", "lavfi", "-i", "nullsrc=s=128x128:d=1", "-c:v", "h264_nvenc", "-f", "null", "-"],
                capture_output=True
            )
            if nvenc_test.returncode == 0:
                return "nvenc"

            # Test AMF
            amf_test = subprocess.run(
                ["ffmpeg", "-v", "error", "-f", "lavfi", "-i", "nullsrc=s=128x128:d=1", "-c:v", "h264_amf", "-f", "null", "-"],
                capture_output=True
            )
            if amf_test.returncode == 0:
                return "amf"

            return None
        except Exception as e:
            logger.error(f"Error checking hardware encoder support: {e}")
            return None

    def get_bitrate(self):
        try:
            r = self.session.get(self.stats_url, timeout=1)
            if r.status_code != 200:
                return 0

            root = ET.fromstring(r.text)
            total_bitrate = 0
            # Monitor both horizontal (app_name) and vertical applications
            for app in root.findall('.//application'):
                app_name_node = app.find('name')
                if app_name_node is not None:
                    app_name_text = app_name_node.text
                    if app_name_text in [self.app_name, "vertical", "youtube"]:
                        live = app.find('live')
                        if live is not None:
                            for stream in live.findall('stream'):
                                name = stream.find('name')
                                if name is not None and name.text == 'cloud_brb_loop':
                                    continue
                                if stream.find('publishing') is not None:
                                    bw_in = stream.find('bw_in')
                                    if bw_in is not None:
                                        # Convert bytes/s to kbps
                                        total_bitrate += int(int(bw_in.text) * 8 / 1024)
            return total_bitrate
        except Exception as e:
            logger.debug(f"Bitrate fetch error: {e}")
            return 0

    def start_cloud_brb(self):
        if not self.cloud_brb_enabled or self.cloud_process:
            return

        if not os.path.exists(self.brb_video_path):
            logger.error(f"Cloud BRB video not found at {self.brb_video_path}")
            return

        logger.info("Starting Cloud BRB stream...")
        # FFmpeg command to loop the video and push to the local ingest
        # This keeps the stream alive at the ingest points if the source drops
        cmd = [
            "ffmpeg", "-re", "-stream_loop", "-1", "-i", self.brb_video_path,
            "-c:v", "libx264", "-preset", "veryfast", "-tune", "zerolatency",
            "-b:v", "1500k", "-maxrate", "1500k", "-bufsize", "3000k",
            "-c:a", "aac", "-ac", "2", "-ar", "48000", "-b:a", "160k",
            "-f", "flv", f"rtmp://127.0.0.1:1935/{self.app_name}/cloud_brb_loop"
        cmd_base = [
            "ffmpeg", "-nostdin", "-re", "-stream_loop", "-1", "-fflags", "+genpts",
            "-thread_queue_size", "1024", "-i", self.brb_video_path
        ]

        hw_encoder = self.get_hardware_encoder()

        if hw_encoder == "nvenc":
            logger.info("NVENC supported, using NVIDIA hardware acceleration for Cloud BRB.")
            cmd_video = [
                "-c:v", "h264_nvenc", "-preset", "p3", "-tune", "ll", "-rc", "cbr",
                "-b:v", "3000k", "-maxrate", "3000k", "-bufsize", "6000k"
            ]
        elif hw_encoder == "amf":
            logger.info("AMF supported, using AMD hardware acceleration for Cloud BRB.")
            cmd_video = [
                "-c:v", "h264_amf", "-quality", "speed", "-rc", "cbr",
                "-b:v", "3000k", "-maxrate", "3000k", "-bufsize", "6000k"
            ]
        else:
            logger.info("Hardware acceleration not supported, falling back to libx264 for Cloud BRB.")
            cmd_video = [
                "-c:v", "libx264", "-preset", "veryfast", "-tune", "zerolatency",
                "-b:v", "3000k", "-maxrate", "3000k", "-bufsize", "6000k"
            ]

        cmd_rest = [
            "-r", "30", "-g", "60", "-keyint_min", "60", "-sc_threshold", "0", "-pix_fmt", "yuv420p",
            "-c:a", "aac", "-b:a", "160k", "-ac", "2", "-ar", "48000",
            "-max_muxing_queue_size", "1024",
            "-f", "tee", f"[f=flv:onfail=ignore]rtmp://127.0.0.1:1935/{self.app_name}/cloud_brb_loop|[f=flv:onfail=ignore]rtmp://127.0.0.1:1935/vertical/cloud_brb_loop|[f=flv:onfail=ignore]rtmp://127.0.0.1:1935/youtube/cloud_brb_loop"
        ]

        cmd = cmd_base + cmd_video + cmd_rest
        try:
            self.cloud_process = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            self.cloud_brb_start_time = time.time()
        except Exception as e:
            logger.error(f"Failed to start Cloud BRB process: {e}")

    def stop_cloud_brb(self):
        if self.cloud_process:
            logger.info("Scheduling Cloud BRB stream stop in 3 seconds to overlap transition.")

            def delayed_kill(proc):
                time.sleep(3)
                proc.kill()
                try:
                    proc.wait(timeout=1)
                except subprocess.TimeoutExpired:
                    pass

            threading.Thread(target=delayed_kill, args=(self.cloud_process,), daemon=True).start()

            self.cloud_process = None
            self.cloud_brb_start_time = None

    def switch_scene(self, scene):
        client = self.get_obs_client()
        if not client:
            return
        try:
            client.set_current_program_scene(scene)
            logger.info(f"Successfully switched OBS scene to: {scene}")
        except Exception as e:
            logger.error(f"OBS WebSocket Switch Error: {e}")
            self.obs_client = None # Force reconnect next time

    def run(self):
        if not self.enabled:
            logger.info("NOALBS is disabled.")
            return

        logger.info(f"NOALBS Started. Monitoring {self.app_name} & vertical on {self.stats_url}")

        consecutive_low = 0
        while True:
            bitrate = self.get_bitrate()
            
            # Check for Cloud BRB timeout (5 minutes)
            if self.cloud_process and self.cloud_brb_start_time:
                if time.time() - self.cloud_brb_start_time > 300:
                    logger.info("Cloud BRB has been running for 300 seconds. Stopping it to fully drop the stream.")
                    self.stop_cloud_brb()
                    self.cloud_brb_timeout = True

            if bitrate > 0:
                self.stop_cloud_brb()
                if not self.is_streaming:
                    logger.info(f"Stream detected at {bitrate}kbps.")
                    self.is_streaming = True
                    self.cloud_brb_timeout = False # Reset timeout flag when user connects
                    # If it was an intentional stop previously, we still need to switch to main
                    # if the bitrate is good. So we mark it as low if we are not on main.
                    # This ensures the restore logic triggers if we start streaming again.
                    if not self.is_low:
                        self.is_low = True

                if bitrate < self.low_threshold:
                    consecutive_low += 1
                    if consecutive_low >= 2 and not self.is_low:
                        logger.warning(f"Low bitrate ({bitrate}kbps) detected quickly. Switching to {self.scene_brb}")
                    if consecutive_low >= 3 and not self.is_low:
                        logger.warning(f"Low bitrate ({bitrate}kbps) for 3s. Switching to {self.scene_brb}")
                        self.switch_scene(self.scene_brb)
                        self.is_low = True
                else:
                    consecutive_low = 0
                    # When restoring, also restore if we just started streaming (in case we were on BRB from a previous session)
                    if bitrate >= self.low_threshold: # Restore at low_threshold per user request "over 1000kbps"
                        if self.is_low or not hasattr(self, '_initial_scene_set'):
                            logger.info(f"Bitrate restored/good ({bitrate}kbps). Switching to {self.scene_main}")
                            self.switch_scene(self.scene_main)
                            self.is_low = False
                            self._initial_scene_set = True
            else:
                consecutive_low = 0
                if self.is_streaming:
                    logger.warning("Source stream completely disconnected. Switching to BRB scene and starting Cloud BRB.")
                    self.switch_scene(self.scene_brb)
                    self.is_low = True
                    if self.cloud_brb_enabled and not self.cloud_brb_timeout:
                        self.start_cloud_brb()
                    self.is_streaming = False

            time.sleep(0.5)
            time.sleep(1.0)

if __name__ == "__main__":
    Noalbs().run()
