FROM php:7.1.20-apache-stretch

COPY dk-vhosts.conf /etc/apache2/sites-enabled/000-default.conf

# Install required extensions
RUN apt-get update && apt-get install -y \
		locales \
		git wget unzip \
		libmcrypt-dev \
		zlib1g-dev \
		zip \
		gettext \
		libfreetype6 libfreetype6-dev \
		libjpeg62 libjpeg62-turbo-dev \
		libpng-dev libmagickwand-dev \
	--no-install-recommends \
	&& rm -r /var/lib/apt/lists/*

RUN echo "th_TH.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen th_TH.UTF-8 && \
    dpkg-reconfigure locales

RUN docker-php-ext-install -j$(nproc) zip mcrypt pdo_mysql

RUN ["/bin/bash", "-c", "docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/"]
RUN docker-php-ext-install -j$(nproc) gd

RUN pecl install imagick && docker-php-ext-enable imagick

# Install PHP extensions
RUN a2enmod rewrite && a2enmod headers

# Install Composer
RUN wget https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer -O - -q | php -- --quiet
RUN mv composer.phar /usr/local/bin/composer

# Install PHPUnit
RUN wget https://phar.phpunit.de/phpunit.phar
RUN chmod +x phpunit.phar
RUN mv phpunit.phar /usr/local/bin/phpunit

# Install AWS CLI
# ENV PATH=/usr/local/bin:$PATH
RUN apt-get install python3 -y

RUN cd /usr/bin \
	&& ln -s idle3 idle \
	&& ln -s pydoc3 pydoc \
	&& ln -s python3 python \
	&& ln -s python3-config python-config

ENV PYTHON_PIP_VERSION 18.0
RUN set -ex; \
	\
	wget -O get-pip.py 'https://bootstrap.pypa.io/get-pip.py'; \
	\
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		"pip==$PYTHON_PIP_VERSION" \
	; \
	pip --version; \
	\
	find /usr/local -depth \
		\( \
			\( -type d -a \( -name test -o -name tests \) \) \
			-o \
			\( -type f -a \( -name '*.pyc' -o -name '*.pyo' \) \) \
		\) -exec rm -rf '{}' +; \
	rm -f get-pip.py

RUN pip install awscli --upgrade --user

# Set default volume for image
# This would be overrided by docker-compose for updatable source code between development
COPY . /data
WORKDIR /data

# Fixes user permissions for Mac OS [https://github.com/boot2docker/boot2docker/issues/581]
RUN usermod -u 1000 www-data

RUN rm -rf /var/lib/apt/lists/*

COPY font.conf /etc/fonts/conf.d/100-wkhtmltoimage-special.conf