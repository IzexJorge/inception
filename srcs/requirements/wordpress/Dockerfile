
FROM debian:bookworm-slim
ARG WP_PORT

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        php-fpm php-cli php-mysqli php-gd php-curl php-xml \
        php-mbstring php-zip php-intl mariadb-client curl \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN curl -o /usr/local/bin/wp -sSL \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

RUN mkdir -p /usr/src/wordpress && \
    wp core download --path=/usr/src/wordpress --allow-root

RUN ln -sf /dev/stderr /var/log/php8.2-fpm.log

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/init_wp.sh /usr/local/bin/init_wp.sh
RUN chmod +x /usr/local/bin/init_wp.sh

WORKDIR /var/www/html

EXPOSE ${WP_PORT}

ENTRYPOINT ["init_wp.sh"]
