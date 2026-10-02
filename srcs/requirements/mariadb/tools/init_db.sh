
#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

if [ ! -f "/var/lib/mysql/.initialized" ]; then
	echo "Initializing the database for the first time..."

	mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

	mariadbd --user=mysql --skip-networking &
	pid="$!"

	RETRIES=30
	until mariadb-admin ping --silent 2>/dev/null; do
		RETRIES=$((RETRIES - 1))
		if [ "$RETRIES" -le 0 ]; then
			echo "Error: MariaDB didn't respond in time during the initialization" >&2
			exit 1
		fi
		sleep 1
	done

	mariadb -u root <<-EOSQL
		CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
		GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
		FLUSH PRIVILEGES;
	EOSQL

	mariadb-admin -u root -p"${DB_ROOT_PASSWORD}" shutdown
	wait "$pid"

	touch /var/lib/mysql/.initialized
fi

exec mariadbd --user=mysql --bind-address=0.0.0.0
