# Cookie-RTMPS: Secure, Self-hosted Multistreaming Solution

**Cookie-RTMPS** is a modern, high-performance RTMPS server and tooling solution built by cookiebaits. It provides secure, self-hosted multistreaming capabilities.

## Overview

Would you like to stream to Twitch, YouTube, Kick, Trovo, Facebook, Instagram, X (Twitter), Cloudflare, and custom RTMP destinations at once, without the upload strain on your computer or recurring fees of commercial services?

You can host **Cookie-RTMPS** on a server to act as a **secure and efficient** tool for your streamed content!

You stream **one** high-quality feed to your Cookie-RTMPS server, and it will:
1.  **Validate** the incoming stream to ensure it's from you, preventing unauthorized access.
2.  **Relay** your stream to all the platforms you configure.

### Key Features
*   **NOALBS Scene Switcher & Cloud BRB:** Integrated NGINX OBS Automatic Low Bitrate Switching (NOALBS). Automatically detects stream drops or low bitrates and plays a Cloud BRB fallback video (or optionally switches OBS scenes) to keep your stream alive at the ingest endpoints, ensuring seamless viewing experiences.
*   **Automated Server IP Whitelisting:** The interactive installer now supports securely auto-detecting and adding your server's public IP (useful for VPNs/VPS) to the broadcast whitelist.
*   **Vertical Streaming Support:** Optimized for use with the **OBS Aitum Vertical plugin**. Push a second, independent vertical feed to specialized targets (TikTok, YouTube Vertical, Twitch Vertical) alongside your horizontal stream.
*   **Automated Stream Titles:** Automatically set and update your stream titles in the format: `Base Title / Episode # / Date`. Episode numbers are persisted and increment automatically! (Current support: Twitch API).
*   **Cloudflare Reverse Proxy:** Built-in support for Cloudflare Real IP, allowing you to secure your stats page behind a Cloudflare proxy.
*   **Nginx 1.30.1 & Custom RTMP:** Uses the latest stable Nginx with a custom, hardened RTMP module for maximum reliability.
*   **Robust Pre-Deployment Checks:** The installation script automatically verifies that all essential host dependencies (like Docker, curl, and networking tools) are present before building, and explicitly verifies that Nginx and Stunnel processes start successfully within the container to catch configuration errors early.
*   **Resilient Nginx Configuration:** The proxy routing is designed to gracefully handle environments without domains configured, preventing crashes during initialization by intelligently defaulting internal domains.

## Prerequisites

You need a VPS server. Key considerations:
*   **Network Performance:** Good bandwidth, low latency, and stable routing between your VPS and your chosen streaming platforms are crucial, especially for 1080p 60fps.
*   **Resources:** A 2 vCore, 2GB RAM VPS (like those from Ionos, Linode, Digital Ocean, Vultr, Hetzner Cloud) is often sufficient. Choose a location strategically.

## Installation & Setup

1.  **SSH into your VPS server:**
    ```bash
    ssh root@<your_server_ip_address>
    ```

2.  **Clone the repository & Run Installer:**
    ```bash
    git clone https://github.com/cookiebaits/cookie-rtmps.git && cd cookie-rtmps && chmod +x install.sh && ./install.sh
    ```
    *   Use the menu to easily install Docker (if needed).
    *   Configure your stream keys and set any desired optimizations.
    *   Select "Build & Start Server" to launch your customized RTMP relay.

3.  **Configure OBS (or other streaming software):**
    *   Service: `Custom...`
    *   **Horizontal Server:** `rtmp://<your_vps_ip_address>:1935/live`
    *   **Vertical Server:** `rtmp://<your_vps_ip_address>:1935/vertical` (For Aitum Vertical)
    *   Stream Key: **Use ONE of the actual stream keys you configured during the setup process** (or the custom Master OBS Key if you set one).

4.  **Begin streaming from OBS!**

We advise testing with one or two destinations first.

## Usage Instructions

*   **STOP** the container: `docker stop cookie-rtmps`
*   **START** the container: `docker start cookie-rtmps`
*   **VIEW LOGS:** `docker logs cookie-rtmps` (or `docker logs -f cookie-rtmps` for live logs)
*   **EDIT Destinations / Keys:** Stop, remove (`docker rm cookie-rtmps`), and re-run the setup script or `docker run` command.
*   **UNINSTALL:** Stop, remove container, then `docker rmi cookie-rtmps`.

## Troubleshooting Common Issues

*   **Lag / Falling Behind Stream:** Often a network bottleneck. Try different ingest servers, a different VPS location, or lower stream bitrate.
*   **Stream Rejects / "Invalid Key":**
    *   OBS key *must exactly match* one key configured.
    *   Ensure at least one destination key is active in the container configuration.
    *   Check validator logs: `docker exec cookie-rtmps tail /tmp/validator.log` or `docker logs cookie-rtmps`.
*   **One Destination Not Working:** Check URL/Key configuration. Check Nginx/Stunnel logs. Ensure stream is active on the platform.

## Configuration

Environment variables and configuration settings use the `cookie-rtmps` naming convention. For example:
- `COOKIE_RTMPS_OBS_KEY` (if master key is enabled)

Check the installer script `install.sh` to explore all available configurations.

## License & Author

Built and maintained by **cookiebaits**.
