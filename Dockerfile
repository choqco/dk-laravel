FROM php:5.6-apache

COPY dk-vhosts.conf /etc/apache2/sites-enabled/001-docker.conf

# Install required extensions
RUN apt-get update && apt-get install -y \
		locales \
		wget \
	--no-install-recommends && rm -r /var/lib/apt/lists/*

# Setup locale & timezone
RUN locale-gen en_US.UTF-8
# RUN echo 'date.timezone = Asia/Bangkok' > /etc/php5/apache2/php.ini

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