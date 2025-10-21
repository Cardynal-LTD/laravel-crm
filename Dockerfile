# Dockerfile
FROM php:8.2-fpm-alpine

# Paquets système + libs nécessaires aux extensions
RUN apk add --no-cache \
  git curl bash tzdata shadow \
  libpng libpng-dev libjpeg-turbo libjpeg-turbo-dev freetype freetype-dev \
  oniguruma oniguruma-dev libzip libzip-dev icu icu-dev zlib zlib-dev \
  mariadb-connector-c-dev

# Outils de compilation pour docker-php-ext-install
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS

# Extensions PHP (ajout de calendar)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) gd zip intl mbstring bcmath pdo pdo_mysql exif opcache calendar

# On peut retirer les build-deps après compilation
RUN apk del .build-deps

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Installer les deps en cache
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# Copier le code app
COPY . .

# Liens & pré-optimisations
RUN php artisan storage:link || true

ENV PORT=8080
EXPOSE 8080

# Démarrage : clé, migrations (best-effort), puis serveur PHP natif
CMD sh -lc 'php artisan key:generate --force || true \
  && php artisan migrate --force || true \
  && php -S 0.0.0.0:${PORT} -t public'
