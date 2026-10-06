
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx openssl gettext-base libfcgi-bin && \
    rm -rf /var/lib/apt/lists/*

COPY conf/wordpress.conf.template /etc/nginx/templates/wordpress.conf.template
COPY tools/init_nginx.sh /usr/local/bin/init_nginx.sh
RUN chmod +x /usr/local/bin/init_nginx.sh

EXPOSE 443

ENTRYPOINT ["init_nginx.sh"]
