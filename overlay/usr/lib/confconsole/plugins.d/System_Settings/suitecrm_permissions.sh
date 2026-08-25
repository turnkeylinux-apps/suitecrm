#!/bin/bash -e

CHOICE=$1

WEBROOT=/var/www/suitecrm

case "$CHOICE" in
    Risky)
        chown -R www-data:www-data "$WEBROOT"
        ;;
    Default)
        chown -R root:root "$WEBROOT"
        for path in \
            cache logs tmp .env.local \
            public/legacy/cache public/legacy/custom \
            public/legacy/modules public/legacy/upload \
            public/legacy/config.php public/legacy/config_override.php \
            public/legacy/.htaccess; do
            if [ -e "$WEBROOT/$path" ]; then
                chown -R www-data:www-data "$WEBROOT/$path"
            fi
        done
        ;;
    *)
        echo "Usage: $0 Default|Risky" >&2
        exit 2
        ;;
esac

