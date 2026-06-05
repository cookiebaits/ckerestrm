FROM buildpack-deps:trixie

# Versions of Nginx and nginx-rtmp-module to use
ENV NGINX_VERSION nginx-1.30.2
ENV NGINX_RTMP_MODULE_VERSION cookie-nginx-rtmp

RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-pip && \
    pip3 install --break-system-packages flask gunicorn requests flask-session google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client && \
    apt-get install -y --no-install-recommends ca-certificates openssl libssl-dev stunnel4 gettext && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip3 cache purge
	
# Download and decompress Nginx
RUN mkdir -p /tmp/build/nginx && \
    cd /tmp/build/nginx && \
    wget -O ${NGINX_VERSION}.tar.gz https://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar -zxf ${NGINX_VERSION}.tar.gz

# Copy RTMP module
COPY cookie-nginx-rtmp /tmp/build/cookie-nginx-rtmp
COPY chat.html /tmp/build/chat.html

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
        --add-module=/tmp/build/cookie-nginx-rtmp && \
    make -j $(getconf _NPROCESSORS_ONLN) CFLAGS="-Wno-error" && \
    make install && \
    cp /tmp/build/cookie-nginx-rtmp/stat.xsl /usr/local/nginx/html/stat.xsl && \
    cp /tmp/build/chat.html /usr/local/nginx/html/chat.html && \
    cp /tmp/build/nginx/${NGINX_VERSION}/conf/mime.types /etc/nginx/mime.types && \
    mkdir /var/lock/nginx && \
    rm -rf /tmp/build

# Forward logs to Docker
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Set up config file
COPY nginx/nginx.conf.template /etc/nginx/nginx.conf.template

# Copy the validation server
COPY stream_validator.py /stream_validator.py

# Config Stunnel
RUN mkdir -p /etc/stunnel/conf.d
# Set up config file 
COPY stunnel/stunnel.conf /etc/stunnel/stunnel.conf
COPY stunnel/stunnel4 /etc/default/stunnel4

# Copy all stunnel configs
COPY stunnel/facebook.conf /etc/stunnel/conf.d/facebook.conf
COPY stunnel/instagram.conf /etc/stunnel/conf.d/instagram.conf
COPY stunnel/tiktok.conf /etc/stunnel/conf.d/tiktok.conf
COPY stunnel/kick.conf /etc/stunnel/conf.d/kick.conf
COPY stunnel/x.conf /etc/stunnel/conf.d/x.conf
COPY stunnel/youtube.conf /etc/stunnel/conf.d/youtube.conf
COPY stunnel/youtube-backup.conf /etc/stunnel/conf.d/youtube-backup.conf
COPY stunnel/twitch.conf /etc/stunnel/conf.d/twitch.conf

#Youtube
ENV YOUTUBE_URL rtmp://x.rtmp.youtube.com/live2/
ENV YOUTUBE_KEY ""

#Facebook
ENV FACEBOOK_URL rtmp://127.0.0.1:19350/rtmp/
ENV FACEBOOK_KEY ""

#Instagram
ENV INSTAGRAM_URL rtmp://127.0.0.1:19351/rtmp/
ENV INSTAGRAM_KEY ""

#Tiktok
ENV TIKTOK_URL rtmp://127.0.0.1:19358/s_v/
ENV TIKTOK_KEY ""

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
ENV KICK_URL rtmp://127.0.0.1:19356/kick/
ENV KICK_KEY ""

ENV X_URL rtmp://127.0.0.1:19354/x/
ENV X_KEY ""

ENV OBS_KEY ""

ENV APP_NAME "live"

ENV ACCEPTED_IP ""

ENV CHUNK_SIZE "8192"

ENV DEBUG ""

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

EXPOSE 1935

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
