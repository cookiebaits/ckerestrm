# PrismRTMPS: Secure, Self-hosted Multistreaming Solution (Fork)

[![Discord](https://img.shields.io/discord/1303046473985818654?label=Discord&logo=discord&style=for-the-badge)](http://wubu.cookiebaits.com)

**CRITICAL SECURITY ADVISORY & PROJECT CONTEXT (Read First!)**

This project (`cookiebaits/PrismRTMPS`) is a **fork** of the `MorrowShore/Prism` RTMP relay. It was created primarily to address a **critical security vulnerability** in the original version that allows for **stream hijacking**, and to provide ongoing maintenance and improvements.

*   **The Vulnerability (Original `MorrowShore/Prism` Pre-May 2025):** The original project historically lacked mandatory stream key validation (`on_publish` check). This meant if a server's IP address and port (usually 1935) were known, **anyone could stream to the server using *any* stream key**, and the original Prism would relay that unauthorized stream to all configured destinations (Twitch, YouTube, etc.).
*   **Attempted Contribution:** A Pull Request was submitted to `MorrowShore/Prism` with a robust fix for this vulnerability (implementing `on_publish` key validation via `stream_validator.py`). Unfortunately, this PR was closed by the original maintainer with comments focusing on the perceived use of AI in its generation and an unrelated, since-reverted funding file modification, rather than the technical merits of the security fix. Communication on the PR was subsequently limited.
*   **The "Fix" in Original `MorrowShore/Prism` (Post-May 7, 2025):** Following the closure of the PR, the original maintainer implemented their own changes. These changes include randomizing the RTMP application path (e.g., `rtmp://<ip>/<random_string>`). While this adds a minor layer of *obscurity*, it **does not fundamentally fix the stream hijacking vulnerability**. The random path is often logged and easily discoverable, and if found, hijacking is still possible because the stream key itself is *still not validated*. Their README continues to state "Your Stream Key Does Not Matter," and their commit messages for this "fix" reflect a focus on issues other than robust authentication.
*   **The Solution in This Fork (`cookiebaits/PrismRTMPS`):** This fork implements **proper stream key validation**. When a stream connects, its key is checked against your configured destination keys. Only streams with a matching key are relayed. This is the industry-standard approach to securing RTMP relays.

**Recommendation:** Due to the persistent lack of true stream key validation in the `MorrowShore/Prism` repository, users concerned about stream security are strongly advised to use this fork (`cookiebaits/PrismRTMPS`) or implement their own robust validation.

---

## Introduction (cookiebaits/PrismRTMPS)

Would you like to stream to Twitch, YouTube, Kick, Trovo, Facebook, Instagram, X (Twitter), Cloudflare, and custom RTMP destinations at once, without the upload strain on your computer or recurring fees of commercial services?

You can host **PrismRTMPS** on a server to act as a **secure and efficient** prism for your streamed content!

You stream **one** high-quality feed to your PrismRTMPS server, and it will:
1.  **Validate** the incoming stream to ensure it's from you, preventing unauthorized access.
2.  **Relay** your stream to all the platforms you configure.

This fork also includes performance tuning (optimized `chunk_size`), updated core components for better stability and security, and active maintenance.

### Key New Features (v3.4+)
*   **Vertical Streaming Support:** Optimized for use with the **OBS Aitum Vertical plugin**. Push a second, independent vertical feed to specialized targets (TikTok, YouTube Vertical, Twitch Vertical) alongside your horizontal stream.
*   **Automated Stream Titles:** Automatically set and update your stream titles in the format: `Base Title / Episode # / Date`. Episode numbers are persisted and increment automatically! (Current support: Twitch API).
*   **Cloudflare Reverse Proxy:** Built-in support for Cloudflare Real IP, allowing you to secure your stats page behind a Cloudflare proxy.
*   **Nginx 1.30.2 & Custom RTMP:** Updated to the latest stable Nginx with a custom, hardened RTMP module for maximum reliability.
*   **NOALBS Scene Switcher:** Integrated Nginx OBS Automatic Low Bitrate Switcher to autonomously manage OBS scenes based on real-time bitrate.
*   **Unified Control Dashboard:** Integrated OAuth-powered dashboard for combined Twitch/YouTube chat and synchronized title management.
*   **TikTok Dynamic Stream Key:** Integration with Streamlabs TikTok API to automatically generate and rotate TikTok stream keys each time you go live.

## Prequisites

You'd need a VPS server. Key considerations:
*   **Network Performance:** Good bandwidth, low latency, and stable routing between your VPS and your chosen streaming platforms are crucial, especially for 1080p 60fps.
*   **Resources:** A 2 vCore, 2GB RAM VPS (like those from Ionos, Linode, Digital Ocean, Vultr, Hetzner Cloud) is often sufficient. This fork has been tested and runs effectively on such configurations. Choose a location strategically.

## How To Set up `cookiebaits/PrismRTMPS`

*   1- **SSH into your VPS server:**
    ```bash
    ssh root@<your_server_ip_address>
    ```

*   2- **Clone the repository & Set permissions:**
    ```bash
    git clone https://github.com/cookiebaits/prism-rtmps.git && cd prism-rtmps && chmod +x install.sh && ./install.sh
    ```

*   3- **Configure OBS (or other streaming software):**
    *   Service: `Custom...`
    *   **Horizontal Server:** `rtmp://<your_vps_ip_address>:1935/live`
    *   **Vertical Server:** `rtmp://<your_vps_ip_address>:1935/vertical` (For Aitum Vertical)
    *   Stream Key: **Use ONE of the actual stream keys you configured during the setup process** (or the custom Master OBS Key if you set one).

*   4- **Begin streaming from OBS!**

We advise testing with one or two destinations first.

## NOALBS & OBS Automation Setup

PrismRTMPS includes **NOALBS** to autonomously manage your OBS scenes based on your ingest bitrate. This ensures your viewers always see a "BRB" screen instead of a frozen frame if your connection weakens.

### 1. Configure in `install.sh`
*   Run `./install.sh` and go to the **"Configure NOALBS Scene Switcher"** menu.
*   **Enable NOALBS:** Set to `true`.
*   **Bitrate Thresholds:**
    *   **Low Bitrate:** Below this speed (default `1000kbps`), OBS switches to your **"BRB"** scene.
    *   **Restore Bitrate:** Above this speed (default `1500kbps`), OBS switches back to your **"Main"** scene.
*   **OBS WebSocket:** Enter your OBS PC's IP and WebSocket credentials (v5).
*   **Scene Names:** Define your **"Main"** and **"BRB"** scene names exactly as they appear in OBS.

### 2. How it Works
*   **Real-time Monitoring:** NOALBS monitors the local Nginx stats page every second.
*   **Automatic Switching:** If the bitrate drops below the "Low" threshold for 3 seconds, it triggers the "BRB" scene.
*   **Instant Recovery:** As soon as the bitrate exceeds the "Restore" threshold, OBS instantly returns to the "Main" scene.

## TikTok Dynamic Key Setup

PrismRTMPS can automatically manage your TikTok Live sessions, generating a new URL and Key every time you start your stream.

### 1. Obtain Streamlabs TikTok Token
*   Install Streamlabs Desktop and log in with your TikTok account.
*   Navigate to Settings -> Advanced -> API Token (or use a token retriever).

### 2. Configure in `install.sh`
*   Go to **"Configure TikTok Dynamic Key"**.
*   Enter your **Streamlabs Token**.
*   Search and select your **Game Category** (e.g., Minecraft, Just Chatting).
*   Set your default **Stream Title**.

### 3. Usage
*   When you start streaming from OBS to PrismRTMPS, the system will automatically:
    1. Call the Streamlabs API to start a new TikTok Live session.
    2. Retrieve the fresh RTMP URL and Key.
    3. Relay your stream to TikTok.
    4. Automatically end the TikTok Live session when you stop streaming in OBS.

## How To Manage PrismRTMPS

*   **STOP** the container: `docker stop prism-rtmps`
*   **START** the container: `docker start prism-rtmps`
*   **VIEW LOGS:** `docker logs prism-rtmps` (or `docker logs -f prism-rtmps` for live logs)
*   **EDIT Destinations / Keys:** Stop, remove (`docker rm prism-rtmps`), and re-run the `docker run` command.
*   **UNINSTALL:** Stop, remove container, then `docker rmi prism-rtmps`.

## Troubleshooting Common Issues

*   **Lag / Falling Behind Stream:** Often a network bottleneck. This fork uses `chunk_size: 8192` for improved performance.
    *   **Diagnosis:** Test one destination at a time. Use `mtr <destination_hostname>` from VPS.
    *   **Solutions:** Different ingest servers, different VPS location, or lower stream bitrate.
*   **Stream Rejects / "Invalid Key":**
    *   OBS key *must exactly match* one key from `docker run`.
    *   Ensure at least one destination key is active in `docker run`.
    *   Check validator logs: `docker exec prism-rtmps tail /tmp/validator.log` or `docker logs prism-rtmps`.
*   **One Destination Not Working:** Check URL/Key in `docker run`. Check Nginx/Stunnel logs. Ensure stream is active on the platform.

## Support & Contributing to This Fork

Need help or have suggestions for **this fork**? Your contributions and feedback are welcome!

*   Raise an Issue: [https://github.com/cookiebaits/PrismRTMPS/issues](https://github.com/cookiebaits/PrismRTMPS/issues)
*   Join our Discord: [http://wubu.cookiebaits.com](http://wubu.cookiebaits.com) (Shield above also links here)

---
**Regarding the Original `MorrowShore/Prism` Repository:**

As noted in the advisory at the top, attempts to contribute essential security fixes to the original `MorrowShore/Prism` repository were met with dismissal and a subsequent "fix" that does not adequately address the core stream hijacking vulnerability. The maintainer's focus appeared to be on the perceived method of contribution rather than the critical security implications for users.

Given this, `cookiebaits/PrismRTMPS` will serve as an actively maintained, secure, and performance-tuned alternative for the community. We encourage users to prioritize their security.
