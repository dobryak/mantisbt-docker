ARG PHP_IMG_VER=5.6-fpm

FROM php:${PHP_IMG_VER}-alpine AS runtime

ARG USER_ID=1000
ARG GROUP_ID=1000

COPY ./mtbt.ini /tmp/

RUN set -e && apk add --no-cache libpng-dev shadow && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install gd && \
    mkdir -p /opt/mtbt &&  cd /opt/mtbt && \
    chown -R www-data:www-data /opt/mtbt && \
    mv /tmp/mtbt.ini "$PHP_INI_DIR/conf.d/" && \
    usermod -u ${USER_ID} www-data && \
    groupmod -g ${GROUP_ID} www-data

WORKDIR /opt/mtbt/



FROM runtime AS install

ARG MANTIS_GIT_URL=https://github.com/mantisbt/mantisbt.git
ARG MANTIS_BRANCH=release-1.3.20

COPY ./install.php ./entrypoint.sh /tmp/

RUN set -e && apk add --no-cache git composer && \
    git clone --single-branch --branch=${MANTIS_BRANCH} ${MANTIS_GIT_URL} . && \
    git submodule init && git submodule update && \
    mv /tmp/install.php /opt/mtbt/ && \
    mv /tmp/entrypoint.sh /usr/local/bin/mantisbt-install && \
    chmod +x /usr/local/bin/mantisbt-install && \
    if [ -f /opt/mtbt/composer.lock ]; then \
        composer install --no-dev; \
        chown -R www-data:www-data ./; \
    fi

ENTRYPOINT /usr/local/bin/mantisbt-install
