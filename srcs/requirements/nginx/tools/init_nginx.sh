
#!/bin/bash
set -e

CERT_DIR="/etc/nginx/ssl"
MARKER="$CERT_DIR/.initialized"

mkdir -p "$CERT_DIR"

if [ ! -f "$MARKER" ]; then
	echo "Generating autosigned certificate for ${DOMAIN_NAME}..."
	openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
		-keyout "$CERT_DIR/${DOMAIN_NAME}.key" \
		-out "$CERT_DIR/${DOMAIN_NAME}.crt" \
		-subj "/C=ES/O=42/OU=Inception/CN=${DOMAIN_NAME}"

	touch "$MARKER"
fi

echo "Waiting for WordPress (php-fpm) to be ready..."
RETRIES=75
until bash -c "echo > /dev/tcp/wordpress/9000" 2>/dev/null; do
    RETRIES=$((RETRIES - 1))
    if [ "$RETRIES" -le 0 ]; then
		echo "Error: WordPress didn't respond within the expected time (150s) during the initialization" >&2
        exit 1
    fi
    sleep 2
done

envsubst '${DOMAIN_NAME}' < /etc/nginx/templates/wordpress.conf.template \
	> /etc/nginx/sites-available/wordpress.conf

ln -sf /etc/nginx/sites-available/wordpress.conf /etc/nginx/sites-enabled/wordpress.conf
rm -f /etc/nginx/sites-enabled/default

exec nginx -g "daemon off;"
