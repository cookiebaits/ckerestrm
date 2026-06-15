# PrismRTMPS: Secure, Self-hosted Multistreaming Solution (Fork)

[![Discord](https://img.shields.io/discord/1303046473985818654?label=Discord&logo=discord&style=for-the-badge)](http://wubu.cookiebaits.com)

**PrismRTMPS** is a high-performance, secure RTMP relay designed to empower streamers with total control over their broadcasts. Built on Nginx and a hardened RTMP module, it allows you to stream to multiple platforms simultaneously (Twitch, YouTube, TikTok, Kick, etc.) from a single ingest point, reducing your local upload requirements and eliminating third-party subscription fees.

---

## ⚡ Quick Reference: Network Ports

For full functionality, ensure the following ports are open on your VPS firewall:

| Port | Protocol | Description |
| :--- | :--- | :--- |
| **1935** | TCP | **RTMP Ingest** (Primary & Vertical stream entry) |
| **80** | TCP | **HTTP** (Let's Encrypt challenges & Automated Redirection) |
| **443** | TCP | **HTTPS** (Secure Dashboard & Stats access) |
| **8081** | TCP | **RTMP Stats** (Optional direct access, usually proxied) |

---

## ✨ Key Features

- **🛡️ Mandatory Authentication:** Prevents stream hijacking via `on_publish` validation against your configured keys.
- **📱 Dual-Format Streaming:** Dedicated support for simultaneous Horizontal and Vertical (Aitum Vertical) feeds.
- **🔒 Automated TLS (SSL):** Integrated Certbot with Let's Encrypt for automatic certificate generation and **auto-renewal**.
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
3. **Configure Domain / Reverse Proxy (#5):** Enter your domain and email for **Automated SSL**.
4. **Configure IP Whitelist (#8):** (Optional) Add your home IP to restrict access.
5. **Build & Start Server:** Launches the containerized environment.

### 4. Setup OBS Encoder
- **Service:** Custom...
- **Server:** `rtmp://your-domain.com:1935/live` (or `rtmps://...` if SSL is active)
- **Stream Key:** Use any of your configured destination keys or your custom Master Key.

---

## 🛠️ Advanced Automation

### NOALBS (OBS Scene Switcher)
Configure bitrate thresholds in the installer. If your bitrate drops below **1000kbps**, PrismRTMPS will tell OBS to switch to your "BRB" scene. When it recovers above **1500kbps**, it switches back to "Main" instantly.

### Automated SSL Auto-Renewal
The system includes a background watchdog process that runs every 12 hours. It automatically checks for certificate expiration and performs a `certbot renew` followed by an Nginx reload, ensuring your HTTPS dashboard and RTMPS ingest points never go down.

### TikTok Dynamic Key Setup
1. Enter your **Streamlabs TikTok Token** in the installer.
2. Select your **Game Category**.
3. PrismRTMPS will now automatically fetch a fresh key and start your TikTok Live session every time you begin streaming to the vertical app.

---

## 📂 Data Persistence
Your configuration, stream keys, OAuth sessions, and episode counts are persisted in the `./data` and `./letsencrypt` directories on the host machine. You can safely rebuild or update the container without losing your settings.

---

## 🤝 Support & Community
- **Join Discord:** [http://wubu.cookiebaits.com](http://wubu.cookiebaits.com)
- **Security Audit:** This fork was created to patch critical hijacking vulnerabilities in the original Prism project. We prioritize security and reliability (P0).

---
*Maintained with ❤️ by the Cookiebaits team.*
