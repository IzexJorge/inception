
#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MARKER="/var/lib/mysql/.initialized"

if [ ! -f "$MARKER" ]; then
	echo "Initializing the database for the first time..."
	find /var/lib/mysql -mindepth 1 -delete

	mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /dev/null

	mariadbd --user=mysql --skip-networking &
	pid="$!"

	RETRIES=15
	until mariadb-admin ping --silent 2>/dev/null; do
		RETRIES=$((RETRIES - 1))
		if [ "$RETRIES" -le 0 ]; then
			echo "Error: The temporary MariaDB instance didn't respond within the expected time (30s) during the initialization" >&2
			exit 1
		fi
		sleep 2
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

	touch "$MARKER"
fi

exec mariadbd --user=mysql --bind-address=0.0.0.0
