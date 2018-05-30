#!/bin/bash -ex

CHOICE=$1

WEBROOT=/var/www/suitecrm

if [ $CHOICE == 'Risky' ]
then
        chown -R www-data:www-data $WEBROOT
else
        chown -R root:root $WEBROOT
        for i in cache custom modules upload config.php sugarcrm.log suitecrm.log install.log config_override.php .htaccess; do
        chown -R www-data:www-data $WEBROOT/$i
        done   
fi


