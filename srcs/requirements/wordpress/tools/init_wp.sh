#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)
MARKER="/var/www/html/.initialized"

if [[ "${WP_ADMIN_USER,,}" == *admin* ]]; then
	echo "Error: WP_ADMIN_USER cannot contain 'admin' in its name in srcs/.env" >&2
	exit 1
fi

echo "Waiting for MariaDB to accept connections..."
RETRIES=45
until mysqladmin ping -h"mariadb" -P"${MYSQL_PORT}" -u"${MYSQL_USER}" -p"${DB_PASSWORD}" --silent 2>/dev/null; do
	RETRIES=$((RETRIES - 1))
	if [ "$RETRIES" -le 0 ]; then
		echo "Error: MariaDB didn't respond within the expected time (90s) during the initialization" >&2
		exit 1
	fi
	sleep 2
done

if [ ! -f "$MARKER" ]; then

	if [ ! -f /var/www/html/wp-config.php ]; then
		echo "Copying WordPress into the volume..."
		cp -r /usr/src/wordpress/. /var/www/html/
		wp config create \
			--path=/var/www/html \
			--dbname="${MYSQL_DATABASE}" \
			--dbuser="${MYSQL_USER}" \
			--dbpass="${DB_PASSWORD}" \
			--dbhost="mariadb:${MYSQL_PORT}" \
			--allow-root
	fi

	if ! wp core is-installed --path=/var/www/html --allow-root 2>/dev/null; then
		echo "Installing WordPress..."
		wp core install \
			--path=/var/www/html \
			--url="https://${DOMAIN_NAME}" \
			--title="${WP_TITLE}" \
			--admin_user="${WP_ADMIN_USER}" \
			--admin_password="${WP_ADMIN_PASSWORD}" \
			--admin_email="${WP_ADMIN_EMAIL}" \
			--allow-root
	fi

	if ! wp user get "${WP_USER}" --path=/var/www/html --allow-root >/dev/null 2>&1; then
		echo "Creating WordPress user..."
		wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
			--path=/var/www/html \
			--role=author \
			--user_pass="${WP_USER_PASSWORD}" \
			--allow-root
	fi

	chown -R www-data:www-data /var/www/html
	touch "$MARKER"
fi

wp config set DB_HOST "mariadb:${MYSQL_PORT}" --path=/var/www/html --allow-root

exec php-fpm8.2 -F
