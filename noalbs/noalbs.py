import requests
import time
import os
import logging
import xml.etree.ElementTree as ET
import obsws_python as obs

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger("NOALBS")

class Noalbs:
    def __init__(self):
        self.enabled = os.getenv("NOALBS_ENABLED", "false").lower() == "true"
        self.low_threshold = int(os.getenv("LOW_BITRATE", 1000))
        self.restore_threshold = int(os.getenv("RESTORE_BITRATE", 1500))
        self.obs_host = os.getenv("OBS_WS_HOST", "")
        self.obs_port = int(os.getenv("OBS_WS_PORT", 4455))
        self.obs_password = os.getenv("OBS_WS_PASSWORD", "")
        self.scene_main = os.getenv("OBS_SCENE_LIVE", "Main")
        self.scene_brb = os.getenv("OBS_SCENE_BRB", "BRB")
        self.app_name = os.getenv("APP_NAME", "live")
        self.stats_url = "http://127.0.0.1:8081/stat"
        self.is_low = False
        self.is_streaming = False

    def get_bitrate(self):
        try:
            r = requests.get(self.stats_url, timeout=2)
            if r.status_code != 200: return 0
            
            root = ET.fromstring(r.text)
            # Find the live application and its inbound stream
            for app in root.findall('.//application'):
                if app.find('name').text == self.app_name:
                    live = app.find('live')
                    if live is not None:
                        for stream in live.findall('stream'):
                            if stream.find('publishing') is not None:
                                # bw_in is in bytes per second, convert to kbps
                                return int(int(stream.find('bw_in').text) * 8 / 1024)
            return 0
        except Exception as e:
            # logger.error(f"Stats Error: {e}")
            return 0

    def switch_scene(self, scene):
        if not self.obs_host: return
        try:
            cl = obs.ReqClient(host=self.obs_host, port=self.obs_port, password=self.obs_password, timeout=3)
            cl.set_current_program_scene(scene)
            logger.info(f"Switched OBS to: {scene}")
        except Exception as e:
            logger.error(f"OBS WebSocket Error: {e}")

    def run(self):
        if not self.enabled:
            logger.info("NOALBS is disabled.")
            return

        logger.info(f"NOALBS Started. Monitoring {self.app_name} on {self.stats_url}")
        
        low_count = 0
        while True:
            bitrate = self.get_bitrate()
            
            if bitrate > 0:
                if not self.is_streaming:
                    logger.info("Stream detected.")
                    self.is_streaming = True
                
                if bitrate < self.low_threshold:
                    low_count += 1
                    if low_count >= 3 and not self.is_low:
                        logger.warning(f"Low bitrate: {bitrate}kbps. Switching to {self.scene_brb}")
                        self.switch_scene(self.scene_brb)
                        self.is_low = True
                else:
                    low_count = 0
                    if bitrate >= self.restore_threshold and self.is_low:
                        logger.info(f"Bitrate restored: {bitrate}kbps. Switching to {self.scene_main}")
                        self.switch_scene(self.scene_main)
                        self.is_low = False
            else:
                if self.is_streaming:
                    logger.info("Stream disconnected.")
                    self.is_streaming = False
                    self.is_low = False
                    low_count = 0
            
            time.sleep(2)

if __name__ == "__main__":
    Noalbs().run()
