# from https://www.drupal.org/requirements/php#drupalversions
FROM php:7.0-apache
ARG DEBIAN_FRONTEND=noninteractive

COPY cnf/php.ini /usr/local/etc/php/

EXPOSE 80

RUN a2enmod rewrite

RUN service apache2 restart

# install the PHP extensions we need
RUN apt-get update && apt-get install -y --fix-missing \
        apt-utils \
        git \
        vim \
        libpng12-dev \
        libjpeg-dev \
        libpq-dev \
        mysql-client \
        libnotify-bin \
        sendmail \
        rsyslog \
        gcc \
        make \
        autoconf \
        libc-dev \
        libpcre3-dev \
        pkg-config \
	&& rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd mbstring opcache pdo pdo_mysql zip bcmath pcntl

# Install Oauth support
RUN pecl install oauth \
    && echo 'extension=oauth.so' >> /usr/local/etc/php/conf.d/oauth.ini

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install latest NPM and Node.js
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get install -y nodejs

# Install Gulp
RUN npm install -g gulp

# TODO: Why does this break (slow down) drush (name, import of DB)???
# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
#RUN echo "opcache.memory_consumption=128\n\
#opcache.interned_strings_buffer=8\n\
#opcache.max_accelerated_files=4000\n\
#opcache.revalidate_freq=60\n\
#opcache.fast_shutdown=1\n\
#opcache.enable_cli=1\n"\
#>> /usr/local/etc/php/conf.d/opcache-recommended.ini

# Configure Sendmail
RUN echo 'sendmail_path = /usr/sbin/sendmail -t -i' >> /usr/local/etc/php/conf.d/sendmail.ini

# Add crontab file in the cron directory
ADD cnf/crontab /etc/cron.d/drupal-cron

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/drupal-cron

# Create the log file to be able to run tail
RUN touch /var/log/cron.log

ENV TZ=America/Chicago
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /var/www
