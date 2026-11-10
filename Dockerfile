# Production image for The Pink Magnolia booking site (fork of Easy!Appointments).
# Build with docker-compose.prod.yml. The repo's docker-compose.yml is the upstream development stack.

# ---------- Stage 1: compile JS/CSS assets ----------
FROM node:22-alpine AS assets
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund
COPY . .
RUN npx gulp compile

# ---------- Stage 2: install PHP dependencies ----------
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-interaction --no-progress --prefer-dist --optimize-autoloader --ignore-platform-reqs --no-scripts

# ---------- Stage 3: runtime ----------
FROM php:8.3-apache

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
RUN install-php-extensions curl gd intl mbstring mysqli pdo_mysql zip exif bcmath ldap \
    && a2enmod rewrite headers \
    && sed -ri 's!AllowOverride None!AllowOverride All!g' /etc/apache2/apache2.conf \
    && printf "upload_max_filesize=32M\npost_max_size=32M\nmemory_limit=256M\n" > /usr/local/etc/php/conf.d/99-easyappointments.ini

WORKDIR /var/www/html

COPY --from=assets /app/application ./application
COPY --from=assets /app/assets ./assets
COPY --from=assets /app/system ./system
COPY --from=assets /app/storage ./storage
COPY --from=assets /app/index.php /app/composer.json /app/config-sample.php ./
COPY --from=vendor /app/vendor ./vendor
COPY docker/production/entrypoint.sh /usr/local/bin/ea-entrypoint

RUN chmod +x /usr/local/bin/ea-entrypoint \
    && chown -R www-data:www-data /var/www/html

ENTRYPOINT ["ea-entrypoint"]
CMD ["apache2-foreground"]
