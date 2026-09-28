FROM php:8.4-fpm

# Install system dependencies & PHP extensions required by UnoPim
RUN apt-get update && apt-get install -y \
    git unzip libpng-dev libjpeg-dev libfreetype6-dev libzip-dev \
    libicu-dev libxml2-dev libonig-dev libpq-dev libmagickwand-dev nginx \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd zip intl xml mbstring pdo pdo_mysql pdo_pgsql bcmath calendar \
    && pecl install imagick apcu \
    && docker-php-ext-enable imagick apcu

# Install Composer
COPY --from=composer:2.5 /usr/bin/composer /usr/bin/composer

# Set up application directory
WORKDIR /app
COPY . .

# Install UnoPim PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Setup Nginx Configuration
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

# Expose port and run Nginx + PHP-FPM together
EXPOSE 80
CMD php-fpm -D && nginx -g "daemon off;"
