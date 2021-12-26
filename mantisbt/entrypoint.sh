#!/bin/sh
MANTIS_DIR="/opt/mtbt"

if [ "${INSTALL_DST_DIR}" == "" ]; then
    echo "INSTALL_DST_DIR env variable is not defined!"
    exit 2
fi

if [ ! -w "${INSTALL_DST_DIR}" ]; then
    echo "${INSTALL_DST_DIR} does not exist or is not writable!"
    exit 2
fi

if [ ! -z "$(ls -A ${INSTALL_DST_DIR}/)" ]; then
    echo "The target installation directory is not empty! Skip installation!"
    exit 0
fi

echo "Waiting for mysql..."
while :
do
    if nc -w 2 -z mysql 3306; then
        break
    fi

    sleep 1
done

echo "Configure the environment..."
cd ${MANTIS_DIR}

php -f ./install.php &>/dev/null || (echo "Failed to configure environment..."; exit 1)

rm install.php

if [ -d ./admin ]; then
    rm -rf ./admin
fi

cp -r ./* ${INSTALL_DST_DIR}/
chown -R www-data:www-data ${INSTALL_DST_DIR}

echo "done"
