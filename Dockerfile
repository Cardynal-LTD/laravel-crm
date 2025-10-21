FROM php:8.2-fpm-alpine

# Paquets système
RUN apk add --no-cache \
  git curl bash tzdata shadow \
  libpng libpng-dev libjpeg-turbo libjpeg-turbo-dev freetype freetype-dev \
  oniguruma oniguruma-dev libzip libzip-dev icu icu-dev zlib zlib-dev \
  mariadb-connector-c-dev

# Outils build
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS

# Extensions PHP (inclut calendar pour ar-php)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) gd zip intl mbstring bcmath pdo pdo_mysql exif opcache calendar

# Nettoyage
RUN apk del .build-deps

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# ---------- PASS 1 : deps PHP sans scripts (pas encore d'artisan) ----------
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --no-progress --no-scripts

# ---------- PASS 2 : on ajoute le code puis on finalise ----------
COPY . .

# Option A (recommandé) : relancer install pour exécuter les scripts (package:discover, etc.)
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# Option B (alternative si tu veux aller vite) :
# RUN composer dump-autoload -o && php artisan package:discover --ansi || true

# Pré-ops
RUN php artisan storage:link || true

ENV PORT=8080
EXPOSE 8080

CMD sh -lc 'php artisan key:generate --force || true \
  && php artisan migrate --force || true \
  && php artisan serve --host=0.0.0.0 --port=${PORT:-8080}'
