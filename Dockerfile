FROM buildpack-deps:bookworm

# Versions of Nginx and nginx-rtmp-module to use
ENV NGINX_VERSION nginx-1.27.0

RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-pip git && \
    pip3 install --break-system-packages flask gunicorn requests && \
    apt-get install -y --no-install-recommends ca-certificates openssl libssl-dev stunnel4 gettext && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip3 cache purge
	
# Download and decompress Nginx
RUN mkdir -p /tmp/build/nginx && \
    cd /tmp/build/nginx && \
    wget -O ${NGINX_VERSION}.tar.gz https://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar -zxf ${NGINX_VERSION}.tar.gz

# Download RTMP module
RUN mkdir -p /tmp/build/nginx-rtmp-module && \
    cd /tmp/build/nginx-rtmp-module && \
    git clone https://github.com/cookiebaits/cookie-nginx-rtmp.git

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
        --with-http_realip_module \
        --with-threads \
        --with-ipv6 \
        --add-module=/tmp/build/nginx-rtmp-module/cookie-nginx-rtmp && \
    make -j $(getconf _NPROCESSORS_ONLN) CFLAGS="-Wno-error" && \
    make install && \
    mkdir /var/lock/nginx && \
    rm -rf /tmp/build

# Forward logs to Docker
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Create data directory for persistence
RUN mkdir -p /app/data

# Set up config file
COPY nginx/nginx.conf.template /etc/nginx/nginx.conf.template
COPY nginx/nginx.conf /etc/nginx/nginx.conf

# Copy mime.types and stat.xsl from Nginx source
RUN cp /tmp/build/nginx/${NGINX_VERSION}/conf/mime.types /etc/nginx/mime.types && \
    cp /tmp/build/nginx-rtmp-module/cookie-nginx-rtmp/stat.xsl /usr/local/nginx/html/stat.xsl

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

# Vertical Stream Destinations
ENV YOUTUBE_VERTICAL_URL rtmp://x.rtmp.youtube.com/live2/
ENV YOUTUBE_VERTICAL_KEY ""
ENV TWITCH_VERTICAL_URL rtmp://ingest.global-contribute.live-video.net/app/
ENV TWITCH_VERTICAL_KEY ""
ENV TIKTOK_VERTICAL_URL rtmp://127.0.0.1:19358/tiktok/
ENV TIKTOK_VERTICAL_KEY ""
ENV KICK_VERTICAL_URL rtmp://127.0.0.1:19353/kick/
ENV KICK_VERTICAL_KEY ""
ENV RTMP_VERTICAL_URL ""
ENV RTMP_VERTICAL_KEY ""

# Title Management
ENV STREAM_BASE_TITLE ""
ENV EPISODE_COUNT 1
ENV AUTO_INCREMENT_EPISODE "true"
ENV AUTO_DATE "true"

#Trovo
ENV TROVO_URL rtmp://livepush.trovo.live/live/
ENV TROVO_KEY ""

#Kick
ENV KICK_URL rtmp://127.0.0.1:19353/kick/
ENV KICK_KEY ""

ENV X_URL rtmp://127.0.0.1:19354/x/
ENV X_KEY ""

ENV OBS_KEY ""

ENV CHUNK_SIZE "8192"

ENV DEBUG ""

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

EXPOSE 1935

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
