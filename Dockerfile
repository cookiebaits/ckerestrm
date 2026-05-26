FROM buildpack-deps:bookworm

# Versions of Nginx and nginx-rtmp-module to use
ENV NGINX_VERSION nginx-1.30.1
ENV NGINX_RTMP_MODULE_REPO https://github.com/cookiebaits/cookie-nginx-rtmp.git

ENV STUNNEL_VERSION 5.78

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends python3 python3-pip make gcc wget && \
    pip3 install --break-system-packages flask gunicorn && \
    apt-get install -y --no-install-recommends ca-certificates openssl libssl-dev gettext libpcre3-dev zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip3 cache purge

# Build Stunnel from source
RUN wget https://www.stunnel.org/downloads/stunnel-${STUNNEL_VERSION}.tar.gz && \
    tar -xzf stunnel-${STUNNEL_VERSION}.tar.gz && \
    cd stunnel-${STUNNEL_VERSION} && \
    ./configure && \
    make && make install && \
    cd .. && rm -rf stunnel-${STUNNEL_VERSION}* && \
    groupadd -r stunnel4 && useradd -r -g stunnel4 stunnel4 && \
    mkdir -p /var/log/stunnel4 && chown -R stunnel4:stunnel4 /var/log/stunnel4
	
# Download and decompress Nginx
RUN mkdir -p /tmp/build/nginx && \
    cd /tmp/build/nginx && \
    wget -O ${NGINX_VERSION}.tar.gz https://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar -zxf ${NGINX_VERSION}.tar.gz

# Download custom RTMP module
RUN mkdir -p /tmp/build/nginx-rtmp-module && \
    cd /tmp/build/nginx-rtmp-module && \
    git clone ${NGINX_RTMP_MODULE_REPO}

# Build and install Nginx
# The default puts everything under /usr/local/nginx, so it's needed to change
# it explicitly. Not just for order but to have it in the PATH
RUN cd /tmp/build/nginx/${NGINX_VERSION} && \
    ./configure \
        --sbin-path=/usr/local/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --pid-path=/var/run/nginx/nginx.pid \
        --lock-path=/var/lock/nginx/nginx.lock \
        --http-log-path=/var/log/nginx/access.log \
        --http-client-body-temp-path=/tmp/nginx-client-body \
        --with-http_ssl_module \
        --with-threads \
        --add-module=/tmp/build/nginx-rtmp-module/cookie-nginx-rtmp && \
    make -j $(getconf _NPROCESSORS_ONLN) CFLAGS="-Wno-error" && \
    make install && \
    mkdir /var/lock/nginx && \
    rm -rf /tmp/build

# Forward logs to Docker
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Set up config file
COPY nginx/nginx.conf.template /etc/nginx/nginx.conf.template
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Copy the validation server
COPY stream_validator.py /stream_validator.py

# Config Stunnel
RUN mkdir -p  /etc/stunnel/conf.d
# Set up config file 
COPY stunnel/stunnel.conf /etc/stunnel/stunnel.conf
COPY stunnel/stunnel4 /etc/default/stunnel4

#Facebook Stunnel Port 19350
COPY stunnel/facebook.conf /etc/stunnel/conf.d/facebook.conf

#Instagram Stunnel Port 19351
COPY stunnel/instagram.conf /etc/stunnel/conf.d/instagram.conf

#Cloudflare Stunnel Port 19352
COPY stunnel/cloudflare.conf /etc/stunnel/conf.d/cloudflare.conf

#Kick Stunnel Port 19353
COPY stunnel/kick.conf /etc/stunnel/conf.d/kick.conf

#X Stunnel Port 19354
COPY stunnel/x.conf /etc/stunnel/conf.d/x.conf
COPY stunnel/youtube.conf /etc/stunnel/conf.d/youtube.conf
COPY stunnel/youtube-backup.conf /etc/stunnel/conf.d/youtube-backup.conf
COPY stunnel/twitch.conf /etc/stunnel/conf.d/twitch.conf
COPY stunnel/tiktok.conf /etc/stunnel/conf.d/tiktok.conf

#Youtube
ENV YOUTUBE_URL rtmp://x.rtmp.youtube.com/live2/
ENV YOUTUBE_KEY ""

#Facebook
ENV FACEBOOK_URL rtmp://127.0.0.1:19350/rtmp/
ENV FACEBOOK_KEY ""

#Instagram
ENV INSTAGRAM_URL rtmp://127.0.0.1:19351/rtmp/
ENV INSTAGRAM_KEY ""

#Cloudflare
ENV CLOUDFLARE_URL rtmp://127.0.0.1:19352/live/
ENV CLOUDFLARE_KEY ""

#Twitch
ENV TWITCH_URL rtmp://ingest.global-contribute.live-video.net/app/
ENV TWITCH_KEY ""

#Rtmp1
ENV RTMP1_URL ""
ENV RTMP1_KEY ""

#Rtmp2
ENV RTMP2_URL ""
ENV RTMP2_KEY ""

#Rtmp3
ENV RTMP3_URL ""
ENV RTMP3_KEY ""

#Trovo
ENV TROVO_URL rtmp://livepush.trovo.live/live/
ENV TROVO_KEY ""

#Kick
ENV KICK_URL rtmp://127.0.0.1:19353/kick/
ENV KICK_KEY ""

ENV TIKTOK_URL ""
ENV TIKTOK_KEY ""

ENV X_URL rtmp://127.0.0.1:19354/x/
ENV X_KEY ""

ENV OBS_KEY ""

ENV CHUNK_SIZE "8192"

ENV TIKTOK_V_URL ""
ENV TIKTOK_V_KEY ""
ENV TWITCH_V_URL ""
ENV TWITCH_V_KEY ""
ENV YOUTUBE_V_URL ""
ENV YOUTUBE_V_KEY ""

ENV DEBUG ""

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

EXPOSE 1935

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
