#!/usr/bin/env bash
set -e

if [[ -f /var/www/magento2/app/etc/config.php ]]; then
    echo "Change owner for config.php"
    sudo chown www-data:www-data /var/www/magento2/app/etc/config.php
fi

if [[ ! -f /var/www/magento2/app/etc/env.php ]]; then
	# wait some time to make sure mysql server is up & running
	sleep 5

	echo "Create databases"
    mysql -u${MYSQL_USER} -p"${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST} -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE_MAIN} CHARACTER SET UTF8; \
    GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE_MAIN}.* TO '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"

    mysql -u${MYSQL_USER} -p"${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST} -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE_QUOTE} CHARACTER SET UTF8; \
    GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE_QUOTE}.* TO '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"

    mysql -u${MYSQL_USER} -p"${MYSQL_ROOT_PASSWORD}" -h ${MYSQL_HOST} -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE_SALES} CHARACTER SET UTF8; \
    GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE_SALES}.* TO '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"

    echo "Install magento"
	php /var/www/magento2/bin/magento setup:install \
	  --base-url=$MAGENTO_URL \
	  --backend-frontname=$MAGENTO_BACKEND_FRONTNAME \
	  --language=$MAGENTO_LANGUAGE \
	  --currency=$MAGENTO_DEFAULT_CURRENCY \
	  --db-host=$MYSQL_HOST \
	  --db-name=$MYSQL_DATABASE_MAIN \
	  --db-user=$MYSQL_USER \
	  --db-password=$MYSQL_ROOT_PASSWORD \
	  --use-secure=$MAGENTO_USE_SECURE \
	  --base-url-secure=$MAGENTO_BASE_URL_SECURE \
	  --use-secure-admin=$MAGENTO_USE_SECURE_ADMIN \
	  --admin-firstname=$MAGENTO_ADMIN_FIRSTNAME \
	  --admin-lastname=$MAGENTO_ADMIN_LASTNAME \
	  --admin-email=$MAGENTO_ADMIN_EMAIL \
	  --admin-user=$MAGENTO_ADMIN_USERNAME \
	  --admin-password=$MAGENTO_ADMIN_PASSWORD \
	  --session-save=redis \
	  --session-save-redis-host=$MAGENTO_SESSION_REDIS_HOST \
	  --session-save-redis-port=$MAGENTO_REDIS_PORT \
	  --session-save-redis-timeout=$MAGENTO_REDIS_TIMEOUT \
	  --session-save-redis-db=$MAGENTO_SESSION_REDIS_DB \
	  --session-save-redis-compression-threshold=$MAGENTO_SESSION_REDIS_COMPRESSION_THRESHOLD \
	  --session-save-redis-compression-lib=$MAGENTO_SESSION_REDIS_COMPRESSION_LIB \
	  --session-save-redis-log-level=$MAGENTO_SESSION_REDIS_LOG_LEVEL \
	  --session-save-redis-max-concurrency=$MAGENTO_SESSION_REDIS_MAX_CONCURRENCY \
	  --session-save-redis-break-after-frontend=$MAGENTO_SESSION_REDIS_BREAK_AFTER_FRONTEND \
	  --session-save-redis-break-after-adminhtml=$MAGENTO_SESSION_REDIS_BREAK_AFTER_ADMINHTML \
	  --session-save-redis-first-lifetime=$MAGENTO_SESSION_REDIS_FIRST_LIFETIME \
	  --session-save-redis-bot-first-lifetime=$MAGENTO_SESSION_REDIS_BOT_FIRST_LIFETIME \
	  --session-save-redis-bot-lifetime=$MAGENTO_SESSION_REDIS_BOT_LIFETIME \
	  --session-save-redis-disable-locking=$MAGENTO_SESSION_REDIS_DISABLE_LOCKING \
	  --session-save-redis-min-lifetime=$MAGENTO_SESSION_REDIS_MIN_LIFETIME \
	  --session-save-redis-max-lifetime=$MAGENTO_SESSION_REDIS_MAX_LIFETIME \
	  --cache-backend=redis \
	  --cache-backend-redis-server=$MAGENTO_CACHE_BACKEND_REDIS_SERVER \
	  --cache-backend-redis-db=$MAGENTO_CACHE_BACKEND_REDIS_DB \
	  --cache-backend-redis-port=$MAGENTO_REDIS_PORT \
	  --page-cache=redis \
	  --page-cache-redis-server=$MAGENTO_PAGE_CACHE_REDIS_SERVER \
	  --page-cache-redis-db=$MAGENTO_PAGE_CACHE_REDIS_DB \
	  --page-cache-redis-port=$MAGENTO_REDIS_PORT \
	  --page-cache-redis-compress-data=$MAGENTO_PAGE_CACHE_REDIS_COMPRESS_DATA \
	  --amqp-host=$RABBITMQ_HOST \
	  --amqp-port=$RABBITMQ_PORT \
	  --amqp-user=$RABBITMQ_DEFAULT_USER \
	  --amqp-password=$RABBITMQ_DEFAULT_PASS

	echo "Split database...Create quote.* tables"
    php /var/www/magento2/bin/magento setup:db-schema:split-quote --host=$MYSQL_HOST --dbname=$MYSQL_DATABASE_QUOTE --username=$MYSQL_USER --password=$MYSQL_ROOT_PASSWORD

    echo "Split database...Create sales.* tables"
    php /var/www/magento2/bin/magento setup:db-schema:split-sales --host=$MYSQL_HOST --dbname=$MYSQL_DATABASE_SALES --username=$MYSQL_USER --password=$MYSQL_ROOT_PASSWORD

	echo "Upgrade..."
    php /var/www/magento2/bin/magento setup:upgrade

    echo "Setting developer mode"
    php /var/www/magento2/bin/magento deploy:mode:set $MAGENTO_DEPLOY_MODE
fi

sudo /etc/init.d/cron start

echo "Initial crontab for www-data"
crontab /etc/cron.d/crontab

echo "Restart cron service"
sudo /etc/init.d/cron restart

echo "Change owner for config.php"
sudo chown www-data:www-data /var/www/magento2/app/etc/config.php

exec "$@"
