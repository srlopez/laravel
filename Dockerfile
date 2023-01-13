FROM ubuntu
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Madrid
ENV NODE_VERSION=18
ENV APP=example-app

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get update 
RUN apt-get install -y gnupg gosu curl ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev python2 dnsutils  \
    && curl -sS 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x14aa40ec0831756756d7f66c4f4ea0aae5267a6c' | gpg --dearmor | tee /usr/share/keyrings/ppa_ondrej_php.gpg > /dev/null  \
    && echo "deb [signed-by=/usr/share/keyrings/ppa_ondrej_php.gpg] https://ppa.launchpadcontent.net/ondrej/php/ubuntu jammy main" > /etc/apt/sources.list.d/ppa_ondrej_php.list  \
    && apt-get update  \
    && apt-get install -y php8.2-cli php8.2-dev \
        php8.2-pgsql php8.2-sqlite3 php8.2-gd \
        php8.2-curl  \
        php8.2-imap php8.2-mysql php8.2-mbstring \
        php8.2-xml php8.2-zip php8.2-bcmath php8.2-soap \
        php8.2-intl php8.2-readline \
        php8.2-ldap \
        php8.2-msgpack php8.2-igbinary php8.2-redis php8.2-swoole \
        php8.2-memcached php8.2-pcov php8.2-xdebug  \
    && php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer  \
    && curl -sLS https://deb.nodesource.com/setup_$NODE_VERSION.x | bash -  \
    && apt-get install -y nodejs  \
    && npm install -g npm  \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarn.gpg >/dev/null  \
    && echo "deb [signed-by=/usr/share/keyrings/yarn.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list  \
    && apt-get update  \
    && apt-get install -y yarn  \
    && apt-get install -y mysql-client  \
    && apt-get install -y apache2 libapache2-mod-php \
    && apt-get -y autoremove  \
    && apt-get clean  \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY \src /src
RUN cd /src/$APP \
    && npm install \
    && composer install
COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY php.ini /etc/php/8.2/cli/conf.d/laravel.ini
RUN chmod -R 775 /src/$APP/ \
    && chown -R www-data:www-data /src/$APP/

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
