FROM php:8.4-fpm

# 1. Installer systemavhengigheter
RUN apt-get update && apt-get install -y \
    git unzip libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
    libicu-dev libxml2-dev libonig-dev libpq-dev libmagickwand-dev nginx \
    && rm -rf /var/lib/apt/lists/*

# 2. Kompiler PHP-utvidelser
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd zip intl xml mbstring pdo pdo_mysql pdo_pgsql bcmath calendar \
    && pecl install imagick apcu \
    && docker-php-ext-enable imagick apcu

ENV COMPOSER_ALLOW_SUPERUSER=1
COPY --from=composer:2.5 /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . .

# 3. Installer avhengigheter
RUN composer install --no-dev --optimize-autoloader --no-interaction

# 4. ENDRE EIER OG RETTIGHETER PÅ MAPPER (Dette fikser 500-feilen)
RUN chown -R www-data:www-data /app \
    && chmod -R 775 /app/storage /app/bootstrap/cache

# 5. Setup Nginx
RUN echo 'server { \
    listen 80; \
    root /app/public; \
    index index.php index.html; \
    location / { try_files $uri $uri/ /index.php?$query_string; } \
    location ~ \.php$ { \
        include fastcgi_params; \
        fastcgi_pass 127.0.0.1:9000; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
    } \
}' > /etc/nginx/sites-available/default

EXPOSE 80
CMD php-fpm -D && nginx -g "daemon off;"
