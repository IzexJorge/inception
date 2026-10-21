
FROM debian:bookworm-slim
ARG NGINX_PORT

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx openssl gettext-base libfcgi-bin && \
    rm -rf /var/lib/apt/lists/*

RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log

COPY conf/wordpress.conf.template /etc/nginx/templates/wordpress.conf.template
COPY tools/init_nginx.sh /usr/local/bin/init_nginx.sh
RUN chmod +x /usr/local/bin/init_nginx.sh

EXPOSE ${NGINX_PORT}

ENTRYPOINT ["init_nginx.sh"]
