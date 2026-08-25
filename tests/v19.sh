#!/bin/bash

set -euo pipefail

: "${TKL_TEST_RESULT:?TKL_TEST_RESULT must name the result file}"

WEBROOT=/var/www/suitecrm
tmp=$(mktemp -d /tmp/suitecrm-v19-test.XXXXXXXX)
cleanup() {
    rm -rf -- "$tmp"
}
trap cleanup EXIT HUP INT TERM

test "$(tr -d '[:space:]' < "$WEBROOT/VERSION")" = 8.10.2
php -r 'exit(version_compare(PHP_VERSION, "8.2.0", ">=") ? 0 : 1);'
systemctl is-active --quiet apache2
systemctl is-active --quiet mariadb
systemctl is-active --quiet cron

openssl s_client -connect 127.0.0.1:443 -servername localhost \
    -showcerts </dev/null 2>/dev/null \
    | openssl x509 -outform PEM > "$tmp/server.pem"
openssl verify -CAfile /etc/ssl/certs/ca-certificates.crt "$tmp/server.pem"
tls_name=$({ openssl x509 -in "$tmp/server.pem" -noout \
    -ext subjectAltName || true; } \
    | tr ',' '\n' | sed -n 's/^[[:space:]]*DNS://p' | sed -n '1p')
if [ -z "$tls_name" ]; then
    tls_name=$(openssl x509 -in "$tmp/server.pem" -noout \
        -subject -nameopt RFC2253 \
        | sed -n 's/^subject=.*CN=\([^,]*\).*$/\1/p')
fi
[[ "$tls_name" =~ ^[A-Za-z0-9.-]+$ ]]
BASE_URL="https://$tls_name"
configured_site_url=$(runuser -u www-data -- php -r \
    'include $argv[1]; print($sugar_config["site_url"] ?? "");' \
    "$WEBROOT/public/legacy/config.php")
[[ "$configured_site_url" =~ ^https://[A-Za-z0-9.-]+$ ]]

admin_pass=$(cat /proc/sys/kernel/random/uuid)
admin_md5=$(printf '%s' "$admin_pass" | md5sum | cut -d ' ' -f 1)
admin_hash=$(php -r \
    'print(password_hash($argv[1], PASSWORD_BCRYPT));' "$admin_md5")
mariadb suitecrm --execute \
    "UPDATE users SET user_hash='$admin_hash' WHERE user_name='admin';"
unset admin_md5 admin_hash
grep -q '^DATABASE_URL=' "$WEBROOT/.env.local"
grep -Eq '^APP_SECRET=.+$' "$WEBROOT/.env.local"

root_status=$(curl --silent --show-error --noproxy '*' \
    --resolve "$tls_name:443:127.0.0.1" \
    --cookie-jar "$tmp/cookies" --output "$tmp/index.html" \
    --write-out '%{http_code}' "$BASE_URL/")
if [ "$root_status" != 200 ]; then
    echo "SuiteCRM root returned HTTP $root_status" >&2
    stat --format '%U:%G %a %n' \
        "$WEBROOT/.env.local" "$WEBROOT/cache" "$WEBROOT/logs" \
        "$WEBROOT/public/legacy/config.php" >&2 || true
    for log in "$WEBROOT/logs/prod/prod.log" /var/log/apache2/error.log; do
        if [ -f "$log" ]; then
            echo "Relevant errors from $log:" >&2
            grep -Ei 'CRITICAL|ERROR|Fatal|Uncaught|Exception|SQLSTATE|Permission denied' \
                "$log" | tail -n 40 \
                | sed -E \
                    -e 's#(mysql://[^:[:space:]]+:)[^@[:space:]]+@#\1[REDACTED]@#g' \
                    -e 's#((password|passwd|token|secret)[^:=,;}]*[:=])[[:space:]]*[^,;}[:space:]]+#\1[REDACTED]#Ig' \
                >&2 || true
        fi
    done
    exit 1
fi
grep -q 'SuiteCRM' "$tmp/index.html"
asset=$(grep -o 'src="dist/[^"]*\.js"' "$tmp/index.html" \
    | sed -n '1p' | cut -d '"' -f 2)
test -n "$asset"
curl --fail --silent --show-error --noproxy '*' \
    --resolve "$tls_name:443:127.0.0.1" \
    --output "$tmp/asset.js" "$BASE_URL/$asset"
test "$(stat --format %s "$tmp/asset.js")" -gt 10000

xsrf=$(awk '$6 == "XSRF-TOKEN" { print $7 }' "$tmp/cookies" | tail -n 1)
test -n "$xsrf"
curl --fail --silent --show-error --noproxy '*' \
    --resolve "$tls_name:443:127.0.0.1" \
    --cookie "$tmp/cookies" --cookie-jar "$tmp/cookies" \
    --header 'Content-Type: application/json' \
    --header "X-XSRF-TOKEN: $xsrf" \
    --data-binary "{\"username\":\"admin\",\"password\":\"$admin_pass\"}" \
    --output "$tmp/login.json" "$BASE_URL/login"
grep -q '"login_success": "true"' "$tmp/login.json"

curl --fail --silent --show-error --noproxy '*' \
    --resolve "$tls_name:443:127.0.0.1" \
    --cookie "$tmp/cookies" --output "$tmp/session.json" \
    "$BASE_URL/session-status"
grep -q '"active":true' "$tmp/session.json"
grep -q '"userName":"admin"' "$tmp/session.json"

record_name="TurnKey v19 account $(cat /proc/sys/kernel/random/uuid)"
record_id=$(runuser -u www-data -- env RECORD_NAME="$record_name" \
    php <<'PHP'
<?php
$_SERVER['PHP_SELF'] = 'turnkey-v19-fixture.php';
chdir('/var/www/suitecrm/public/legacy');
define('sugarEntry', true);
require 'include/entryPoint.php';
global $current_user;
$current_user = BeanFactory::getBean('Users', '1');
$record = BeanFactory::newBean('Accounts');
$record->name = getenv('RECORD_NAME');
$id = $record->save();
if (!$id) {
    fwrite(STDERR, "Account create failed\n");
    exit(1);
}
$loaded = BeanFactory::getBean('Accounts', $id);
if (!$loaded || $loaded->name !== getenv('RECORD_NAME')) {
    fwrite(STDERR, "Account read failed\n");
    exit(1);
}
echo $id;
PHP
)
[[ "$record_id" =~ ^[0-9a-f-]{36}$ ]]
db_count=$(mariadb --batch --skip-column-names suitecrm \
    --execute "SELECT COUNT(*) FROM accounts WHERE id='$record_id' AND name='$record_name' AND deleted=0;")
test "$db_count" = 1

runuser -u www-data -- env RECORD_ID="$record_id" php <<'PHP'
<?php
$_SERVER['PHP_SELF'] = 'turnkey-v19-cleanup.php';
chdir('/var/www/suitecrm/public/legacy');
define('sugarEntry', true);
require 'include/entryPoint.php';
$record = BeanFactory::getBean('Accounts', getenv('RECORD_ID'));
if (!$record || !$record->id) {
    fwrite(STDERR, "Account cleanup read failed\n");
    exit(1);
}
$record->mark_deleted($record->id);
PHP

runuser -u www-data -- "$WEBROOT/bin/console" schedulers:run \
    > "$tmp/scheduler.log"
grep -q 'Running Schedulers' "$tmp/scheduler.log"
grep -q '(Passed)' "$tmp/scheduler.log"
grep -Fq '* * * * * www-data /usr/bin/php /var/www/suitecrm/bin/console schedulers:run' \
    /etc/cron.d/suitecrm

bash -n /usr/lib/confconsole/plugins.d/System_Settings/suitecrm_permissions.sh
test -x /usr/local/sbin/suitecrm-update
suitecrm-update --check > "$tmp/updater"
grep -q '^installed_version=8\.10\.2$' "$tmp/updater"
grep -q '^channel=stable$' "$tmp/updater"
grep -Eq '^status=(up-to-date|update-available|newer-than-channel)$' "$tmp/updater"
grep -Eq '^integrity=sha256:[0-9a-f]{64}$' "$tmp/updater"
updater_status=$(sed -n 's/^status=//p' "$tmp/updater")
eligible_version=$(sed -n 's/^eligible_version=//p' "$tmp/updater")

install -d -m 0755 "$(dirname "$TKL_TEST_RESULT")"
cat > "$TKL_TEST_RESULT" <<EOF
package_source=official SuiteCRM-Core v8.10.2 production release archive
installed_version=8.10.2
runtime_checks=HTTPS assets, admin login, Account create/read, MariaDB row, scheduler and cleanup passed
updater_command=suitecrm-update --check
updater_result=$updater_status; eligible=$eligible_version
updater_channel=official SuiteCRM stable GitHub release channel
integrity_evidence=build pin and official release metadata SHA-256 ac4693d10ea2d6cd20b3256098781d134599d88878fb24e8dc127038d624f5a8
EOF
