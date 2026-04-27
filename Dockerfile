FROM buildpack-deps:bullseye

# Versions of Nginx and nginx-rtmp-module to use
ENV NGINX_VERSION nginx-1.26.1
ENV NGINX_RTMP_MODULE_VERSION 1.2.2

RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-pip sqlite3 ffmpeg procps wget && \
    pip3 install flask gunicorn requests && \
    apt-get install -y --no-install-recommends ca-certificates openssl libssl-dev stunnel4 gettext && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    pip3 cache purge

# Install Official Ookla Speedtest CLI (more reliable for uploads)
RUN mkdir -p /tmp/speedtest && cd /tmp/speedtest && \
    wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz && \
    tar -zxvf ookla-speedtest-1.2.0-linux-x86_64.tgz && \
    mv speedtest /usr/local/bin/speedtest && \
    rm -rf /tmp/speedtest

# Create stunnel log directory
RUN mkdir -p /var/log/stunnel4 && chown stunnel4:stunnel4 /var/log/stunnel4
	
# Download and decompress Nginx
RUN mkdir -p /tmp/build/nginx && \
    cd /tmp/build/nginx && \
    wget -O ${NGINX_VERSION}.tar.gz https://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar -zxf ${NGINX_VERSION}.tar.gz

# Download and decompress RTMP module
RUN mkdir -p /tmp/build/nginx-rtmp-module && \
    cd /tmp/build/nginx-rtmp-module && \
    wget -O nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    tar -zxf nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    cd nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}

# Build and install Nginx
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
        --with-ipv6 \
        --add-module=/tmp/build/nginx-rtmp-module/nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} && \
    make -j $(getconf _NPROCESSORS_ONLN) CFLAGS="-Wno-error" && \
    make install && \
    mkdir /var/lock/nginx && \
    rm -rf /tmp/build

# Forward logs to Docker
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Set up config file
COPY nginx/nginx.conf.template /etc/nginx/nginx.conf.template

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

# Incoming RTMPS Port 1936
COPY stunnel/incoming_rtmps.conf /etc/stunnel/conf.d/incoming_rtmps.conf

# Setup Flask Web Dashboard
COPY app /app

# Ensure Dokploy data persistence
VOLUME ["/app/data"]

ENV ADMIN_USERNAME "admin"
ENV ADMIN_PASSWORD "P4sswerd"
ENV DEBUG ""

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 1935
EXPOSE 1936
EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
