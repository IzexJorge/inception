
FROM debian:bookworm-slim
ARG MYSQL_PORT

RUN apt-get update && \
    apt-get install -y --no-install-recommends mariadb-server && \
    rm -rf /var/lib/apt/lists/*

COPY conf/my.cnf /etc/mysql/mariadb.conf.d/custom.cnf
COPY tools/init_db.sh /usr/local/bin/init_db.sh
RUN chmod +x /usr/local/bin/init_db.sh

EXPOSE ${MYSQL_PORT}

ENTRYPOINT ["init_db.sh"]
