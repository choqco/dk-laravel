# php:7-apache with apt-fast
FROM aimakun/php-boost

COPY dk-vhosts.conf /etc/apache2/sites-enabled/000-default.conf

RUN echo 'date.timezone = Asia/Bangkok' > /usr/local/etc/php/php.ini

# Install required extensions
RUN apt-fast update && apt-fast install -y \
		locales \
		git wget unzip wkhtmltopdf \
		libmcrypt-dev \
		zlib1g-dev \
		gettext \
		libfreetype6 libfreetype6-dev \
		libjpeg62 libjpeg62-turbo-dev \
		libpng12-dev \
	--no-install-recommends \
	&& rm -r /var/lib/apt/lists/*

RUN docker-php-ext-install -j$(nproc) zip mcrypt pdo_mysql

RUN ["/bin/bash", "-c", "docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/"]
RUN docker-php-ext-install -j$(nproc) gd exif

# Install PHP extensions
RUN a2enmod rewrite && a2enmod headers


# Setup locale & timezone
RUN locale-gen en_US.UTF-8
RUN locale-gen sv_SE.UTF-8

# Install Composer
RUN wget https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer -O - -q | php -- --quiet
RUN mv composer.phar /usr/local/bin/composer

# Install PHPUnit
RUN wget https://phar.phpunit.de/phpunit.phar
RUN chmod +x phpunit.phar
RUN mv phpunit.phar /usr/local/bin/phpunit

# Set default volume for image
# This would be overrided by docker-compose for updatable source code between development
COPY . /data
WORKDIR /data

# Fixes user permissions for Mac OS [https://github.com/boot2docker/boot2docker/issues/581]
RUN usermod -u 1000 www-data

# Inherit from based image
CMD ["apache2-foreground"]