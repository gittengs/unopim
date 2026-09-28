FROM php:8.4-fpm

# 1. Install system dependencies
RUN apt-get update && apt-get install -y \
    git unzip libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
    libicu-dev libxml2-dev libonig-dev libpq-dev libmagickwand-dev nginx \
    && rm -rf /var/lib/apt/lists/*

# 2. Compile and enable PHP extensions (GD and Zip are forced here)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd zip intl xml mbstring pdo pdo_mysql pdo_pgsql bcmath calendar \
    && pecl install imagick apcu \
    && docker-php-ext-enable imagick apcu

# 3. Set environment variable to allow Composer to run cleanly as root
ENV COMPOSER_ALLOW_SUPERUSER=1

# 4. Install Composer
COPY --from=composer:2.5 /usr/bin/composer /usr/bin/composer

# 5. Copy project files and run Composer
WORKDIR /app
COPY . .

# Run composer installation
RUN composer install --no-dev --optimize-autoloader --no-interaction

# 6. Setup Nginx Configuration
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
