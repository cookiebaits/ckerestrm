# PrismRTMPS: Secure, Self-hosted Multistreaming Solution (Fork)

[![Discord](https://img.shields.io/discord/1303046473985818654?label=Discord&logo=discord&style=for-the-badge)](http://wubu.cookiebaits.com)

**PrismRTMPS** is a high-performance, secure RTMP relay designed to empower streamers with total control over their broadcasts. Built on Nginx and a hardened RTMP module, it allows you to stream to multiple platforms simultaneously (Twitch, YouTube, TikTok, Kick, etc.) from a single ingest point, reducing your local upload requirements and eliminating third-party subscription fees.

---

## ⚡ Quick Reference: Network Ports

For full functionality, ensure the following ports are open on your VPS firewall:

| Port | Protocol | Description |
| :--- | :--- | :--- |
| **1935** | TCP | **RTMP Ingest** (Primary & Vertical stream entry) |
| **8081** | TCP | **Stats & Control API** (Should be handled by your host reverse proxy) |

---

## ✨ Key Features

- **🛡️ Mandatory Authentication:** Prevents stream hijacking via `on_publish` validation against your configured keys.
- **📱 Dual-Format Streaming:** Dedicated support for simultaneous Horizontal and Vertical (Aitum Vertical) feeds.
- **🔒 Proxy-Ready:** Optimized for use behind host-level reverse proxies (Nginx, Apache, Caddy).
- **🤖 NOALBS Integration:** Bitrate-aware scene switcher that autonomously manages OBS via WebSocket.
- **🎵 Unified Dashboard:** A polished, modern dark-themed control panel for aggregated chat and title management.
- **🎬 TikTok Automation:** Dynamic stream key rotation via Streamlabs API (auto-starts/ends TikTok sessions).
- **🚀 Hardened Infrastructure:** Nginx 1.30.2, Stunnel TLS 1.3, and Enhanced RTMP support (HEVC/AV1/VP9).
- **📋 Multiple IP Whitelist:** Restrict ingest access to specific trusted IP addresses.

---

## 🚀 Deployment Steps

### 1. Connect to your VPS
Login via SSH to your clean Ubuntu/Debian server:
```bash
ssh root@your_server_ip
```

### 2. Run the Universal Installer
Clone the repository and launch the interactive setup script:
```bash
git clone https://github.com/cookiebaits/prism-rtmps.git && cd prism-rtmps
chmod +x install.sh
./install.sh
```

### 3. Configure Your Environment
Follow the menu prompts in order:
1. **Install Docker** (if not already present).
2. **Configure Stream Keys** for your destinations.
3. **Configure Domain (#5):** Enter your domain for OBS instruction generation.
4. **Configure IP Whitelist (#8):** (Optional) Add your home IP to restrict access.
5. **Build & Start Server:** Launches the containerized environment.

### 4. Setup OBS Encoder
- **Service:** Custom...
- **Server:** `rtmp://your-domain.com:1935/live`
- **Stream Key:** Use any of your configured destination keys or your custom Master Key.

---

## 🛠️ Advanced Automation

### NOALBS (OBS Scene Switcher)
Configure bitrate thresholds in the installer. If your bitrate drops below **1000kbps**, PrismRTMPS will tell OBS to switch to your "BRB" scene. When it recovers above **1500kbps**, it switches back to "Main" instantly.

### Host-Level Reverse Proxy (Recommended)
PrismRTMPS is designed to run behind a host-level reverse proxy (like Nginx or Caddy) for inbound SSL. Point your proxy to port **8081** for the Dashboard and Stats page.

### TikTok Dynamic Key Setup
1. Enter your **Streamlabs TikTok Token** in the installer.
2. Select your **Game Category**.
3. PrismRTMPS will now automatically fetch a fresh key and start your TikTok Live session every time you begin streaming to the vertical app.

---

## 📂 Data Persistence
Your configuration, stream keys, OAuth sessions, and episode counts are persisted in the `./data` directory on the host machine. You can safely rebuild or update the container without losing your settings.

---

## 🤝 Support & Community
- **Join Discord:** [http://wubu.cookiebaits.com](http://wubu.cookiebaits.com)
- **Security Audit:** This fork was created to patch critical hijacking vulnerabilities in the original Prism project. We prioritize security and reliability (P0).

---
*Maintained with ❤️ by the Cookiebaits team.*
