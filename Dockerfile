FROM php:7.1.10-apache
ARG DEBIAN_FRONTEND=noninteractive

ENV LETSENCRYPT_HOME /etc/letsencrypt

RUN echo 'deb http://ftp.debian.org/debian jessie-backports main' >> /etc/apt/sources.list \
    && curl -sS http://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb http://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y --fix-missing \
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
        autoconf \
        supervisor \
        libxml2-dev \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd mbstring opcache pdo pdo_mysql zip bcmath pcntl mysqli soap \
    && a2enmod rewrite headers expires ssl actions \
    && apt-get install -y python-certbot-apache -t jessie-backports \
    && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g gulp bower \
    && apt-get install yarn \
    && pear install -a Mail_Mime \
    && pear install Mail_mimeDecode \
    && php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer \
    && chmod -R 755 /var/www/html \
    && chown -R www-data:www-data /var/www/html \
    && chmod -R 644 /etc/cron.d/* \
    && chown -R root:root /etc/cron.d/* \
	&& apt-get autoclean -y \
	&& apt-get clean -y \
	&& apt-get autoremove -y

COPY config/drupal-cron /etc/cron.d/
RUN chmod 644 /etc/cron.d/*

COPY config/php.ini /usr/local/etc/php
RUN ln -sfT /dev/stderr "$APACHE_LOG_DIR/error.log"

COPY config/supervisord.conf /etc/supervisor/supervisord.conf
COPY config/scripts/pmg-* /usr/local/bin/
RUN chmod +x /usr/local/bin/pmg-*

ENV TZ=America/Chicago
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /var/www

CMD ["/usr/bin/supervisord"]
