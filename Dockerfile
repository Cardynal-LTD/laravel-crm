# Dockerfile
FROM php:8.2-fpm-alpine

# Paquets système (libs pour gd/zip/intl/etc.)
RUN apk add --no-cache \
  git curl bash tzdata shadow \
  libpng libpng-dev libjpeg-turbo libjpeg-turbo-dev freetype freetype-dev \
  oniguruma oniguruma-dev libzip libzip-dev icu icu-dev zlib zlib-dev \
  mariadb-connector-c-dev

# Outils de build pour compiler les extensions
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS

# ✅ Extensions PHP (AJOUT de `calendar`)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) gd zip intl mbstring bcmath pdo pdo_mysql exif opcache calendar

# Nettoyage des dépendances de build
RUN apk del .build-deps

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Installer les deps en cache
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# Code app
COPY . .

# Pré-ops
RUN php artisan storage:link || true

ENV PORT=8080
EXPOSE 8080

# Démarrage (best-effort si la DB n’est pas prête)
CMD sh -lc 'php artisan key:generate --force || true \
  && php artisan migrate --force || true \
  && php -S 0.0.0.0:${PORT} -t public'
