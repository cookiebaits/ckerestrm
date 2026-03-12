FROM debian:bookworm-slim

# Avoid interactive prompts during package installs
ENV DEBIAN_FRONTEND=noninteractive

# Versions of Nginx and nginx-rtmp-module to use
ENV NGINX_VERSION=nginx-1.28.2
ENV NGINX_RTMP_MODULE_VERSION=1.2.2

# Install system dependencies
RUN set -x && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        openssl \
        libssl-dev \
        stunnel4 \
        gettext \
        wget \
        build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Python and required modules using a virtual environment
RUN set -x && \
    apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-pip python3-venv && \
    python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install flask gunicorn && \
    rm -rf /var/lib/apt/lists/*   

# Download and decompress Nginx
RUN set -x && \
    mkdir -p /tmp/build/nginx && \
    cd /tmp/build/nginx && \
    wget -O ${NGINX_VERSION}.tar.gz https://nginx.org/download/${NGINX_VERSION}.tar.gz && \
    tar -zxf ${NGINX_VERSION}.tar.gz

# Download and decompress RTMP module
RUN set -x && \
    mkdir -p /tmp/build/nginx-rtmp-module && \
    cd /tmp/build/nginx-rtmp-module && \
    wget -O nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz \
        https://github.com/arut/nginx-rtmp-module/archive/refs/tags/v${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    tar -zxf nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION}.tar.gz && \
    mv nginx-rtmp-module-${NGINX_RTMP_MODULE_VERSION} /tmp/build/nginx-rtmp-module-final   
    
# Build and install Nginx
RUN set -x && \
    cd /tmp/build/nginx/${NGINX_VERSION} && \
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
    mkdir -p /var/lock/nginx && \
    rm -rf /tmp/build

# Forward logs to Docker
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

# Rest of your configuration files copying...
COPY nginx/nginx.conf.template /etc/nginx/nginx.conf.template
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY stream_validator.py /stream_validator.py
COPY stunnel/stunnel.conf /etc/stunnel/stunnel.conf
COPY stunnel/stunnel4 /etc/default/stunnel4
COPY stunnel/facebook.conf /etc/stunnel/conf.d/facebook.conf
COPY stunnel/instagram.conf /etc/stunnel/conf.d/instagram.conf
COPY stunnel/cloudflare.conf /etc/stunnel/conf.d/cloudflare.conf
COPY stunnel/kick.conf /etc/stunnel/conf.d/kick.conf
COPY stunnel/x.conf /etc/stunnel/conf.d/x.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 1935

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
