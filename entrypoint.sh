#!/bin/sh +x

ZPUSH_CONFIG='/usr/local/lib/z-push/config.php'
ZPUSH_BACKEND_CONFIG='/usr/local/lib/z-push/backend/zimbra/config.php'
ZPUSH_AUTODISCOVER_CONFIG='/usr/local/lib/z-push/autodiscover/config.php'

#Prepare config file

if [ ! -f  "${ZPUSH_CONFIG}.bkp" ]; then
    # Backun original file
    if [ -f "$ZPUSH_CONFIG" ]; then
        cp $ZPUSH_CONFIG $ZPUSH_CONFIG.bkp
    fi
fi

if [ ! -f  "${ZPUSH_CONFIG}" ]; then
    cat <<- EOF >> $ZPUSH_CONFIG
# Zimbra config
define('BACKEND_PROVIDER', '');
define('TIMEZONE','');
define('ZIMBRA_USER_DIR','zimbra');
define('ZIMBRA_SYNC_CONTACT_PICTURES', true);
define('ZIMBRA_VIRTUAL_CONTACTS',true);
define('ZIMBRA_VIRTUAL_APPOINTMENTS',true);
define('ZIMBRA_VIRTUAL_NOTES',true);
define('ZIMBRA_VIRTUAL_TASKS',true);
define('ZIMBRA_IGNORE_EMAILED_CONTACTS',true);
define('ZIMBRA_HTML',true);
define('ZIMBRA_ENFORCE_VALID_EMAIL',false);
define('ZIMBRA_SMART_FOLDERS',false);
EOF
fi

if [ -z  $ZPUSH_URL_IN_HTTP ]; then
    ZPUSH_URL_PROTO="https:\/\/"
else
    ZPUSH_URL_PROTO="http:\/\/"
fi 

if [ -z  $ZIMBRA_URL_IN_HTTP ]; then
    ZIMBRA_URL_PROTO="https:\/\/"
else
    ZIMBRA_URL_PROTO="http:\/\/"
fi 

# Config Zimbra backend
sed -i "/BACKEND_PROVIDER/s/'[^']*'/'BackendZimbra'/2" $ZPUSH_CONFIG
sed -i "/BACKEND_PROVIDER/s/'[^']*'/'BackendZimbra'/2" $ZPUSH_AUTODISCOVER_CONFIG

sed -i -e "/ZPUSH_HOST/sx// xx" -e "/ZPUSH_HOST/s/'[^']*'/'$ZPUSH_HOST'/2" $ZPUSH_AUTODISCOVER_CONFIG
sed -i "/ZIMBRA_URL/s/'[^']*'/'$ZIMBRA_URL_PROTO$ZIMBRA_URL'/2" $ZPUSH_BACKEND_CONFIG

# Set timezone if exist
if  [ ! -z $TIMEZONE ]; then  
    rm /etc/localtime -rf
    ln -fs /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    dpkg-reconfigure --frontend noninteractive tzdata

    TIMEZONE=`echo $TIMEZONE | sed 's:/:\\\/:'`
    sed -i "/TIMEZONE/s/'[^']*'/'$TIMEZONE'/2" $ZPUSH_CONFIG
    sed -i "/TIMEZONE/s/'[^']*'/'$TIMEZONE'/2" $ZPUSH_AUTODISCOVER_CONFIG
    sed -i "/USE_FULLEMAIL_FOR_LOGIN/s/false/true/" $ZPUSH_AUTODISCOVER_CONFIG
fi

cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini

# apache2-foreground 

rm /var/log/apache2/{access.log,error.log,other_vhosts_access.log}

apache2ctl start

/bin/bash
