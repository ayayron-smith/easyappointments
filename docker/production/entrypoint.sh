#!/bin/sh
# Writes config.php from environment variables on every start, then hands off to Apache.
set -e

php -r '
$values = [
    "BASE_URL"    => getenv("BASE_URL") ?: "http://localhost",
    "LANGUAGE"    => getenv("LANGUAGE") ?: "english",
    "DEBUG_MODE"  => filter_var(getenv("DEBUG_MODE") ?: "false", FILTER_VALIDATE_BOOLEAN),
    "DB_HOST"     => getenv("DB_HOST") ?: "mysql",
    "DB_NAME"     => getenv("DB_NAME") ?: "easyappointments",
    "DB_USERNAME" => getenv("DB_USERNAME") ?: "user",
    "DB_PASSWORD" => getenv("DB_PASSWORD") ?: "password",
];
$out = "<?php\nclass Config\n{\n";
foreach ($values as $k => $v) {
    $out .= "    const $k = " . var_export($v, true) . ";\n";
}
$out .= "}\n";
file_put_contents("/var/www/html/config.php", $out);
'

chown www-data:www-data /var/www/html/config.php
chown -R www-data:www-data /var/www/html/storage

exec "$@"
