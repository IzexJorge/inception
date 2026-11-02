#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MARKER="/var/lib/mysql/.initialized"

chown -R mysql:mysql /var/lib/mysql

if [ ! -f "$MARKER" ]; then
	echo "Initializing the database for the first time..."

	if [ ! -d /var/lib/mysql/mysql ]; then
		mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null
	fi

	# Bootstrap mode runs the SQL in the foreground without networking and exits,
	# so no temporary server has to be sent to background. The grant tables are
	# not loaded in this mode until FLUSH PRIVILEGES, which user statements need.
	mariadbd --user=mysql --bootstrap <<-EOSQL
		FLUSH PRIVILEGES;
		CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
		GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
		FLUSH PRIVILEGES;
	EOSQL

	touch "$MARKER"
fi

exec mariadbd --user=mysql --bind-address=0.0.0.0 --port="${MYSQL_PORT}"
