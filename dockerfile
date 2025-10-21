# PHP + extensions pour Laravel + PhpSpreadsheet
FROM php:8.2-fpm-alpine

# Paquets système
RUN apk add --no-cache \
    git curl bash tzdata \
    libpng libpng-dev libjpeg-turbo libjpeg-turbo-dev freetype freetype-dev \
    oniguruma-dev libzip libzip-dev icu icu-dev

# Extensions PHP (GD, ZIP, INTL, etc.)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j$(nproc) gd zip intl mbstring bcmath pdo pdo_mysql exif opcache

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Install deps en cache
COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-interaction --optimize-autoloader

# Code
COPY . .

# Pré-optimisations Laravel (laissent passer si .env pas encore prêt)
RUN php artisan storage:link || true

ENV PORT=8080
EXPOSE 8080

# Démarrage : migrations (si DB OK) puis serveur PHP natif sur 0.0.0.0:8080
CMD php artisan migrate --force || true && php -S 0.0.0.0:${PORT} -t public
