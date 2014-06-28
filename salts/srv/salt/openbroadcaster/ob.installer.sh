#!/bin/bash

# Copyright 2012-2013 OpenBroadcaster, Inc.

# This file is part of OpenBroadcaster Server.

# OpenBroadcaster Server is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# OpenBroadcaster Server is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.

# You should have received a copy of the GNU Affero General Public License
# along with OpenBroadcaster Server. If not, see <http://www.gnu.org/licenses/>.

## First, let's gather some data from our Administrator about how OpenBroadcaster
## should be configured on this system:

WEBROOT={{ WEBROOT }}
MEDIAROOT={{ MEDIAROOT }}
WEBUSER={{ WEBUSER }}
OBUSER={{ OBUSER }}

USEDBRT=y
DBSU={{ DBSU }}
DBSUPASS={{ DBSUPASS }}

OBDBNM={{ OBDBNM }}
OBDBUSER={{ OBDBUSER }}
OBDBPASS={{ OBDBPASS }}
DBHOST={{ DBHOST }}
TBLPRE={{ TBLPRE }}

CSSPRE={{ CSSPRE }}
OBFQDN={{ OBFQDN }}
OBIP={{ OBIP }}

OBRPLYML={{ OBRPLYML }}
OBMLNM={{ OBMLNM }}
OBADMINPASS={{ OBADMINPASS }}
SALT={{ OBSALT }}

## Now we need some variables defined to make the rest of the script easier to
## deal with. We will also use this section to set any default variables not set
## by the user

CWD=$(pwd)

if [[ $(echo $WEBROOT) == "" ]]; then
    WEBROOT=/var/www/openbroadcaster
fi
if [[ $(echo $MEDIAROOT) == "" ]]; then
    MEDIAROOT=/media/openbroadcaster
fi
if [[ $(echo $WEBUSER) == "" ]]; then
    WEBUSER=www-data
fi
if [[ $(echo $OBUSER) == "" ]]; then
    OBUSER=www-data
fi
if [[ $(echo $DBSU) == "" ]]; then
    DBSU=root
fi
if [[ $(echo $OBDBNM) == "" ]]; then
    OBDBNM=openbroadcaster
fi
if [[ $(echo $OBDBUSER) == "" ]]; then
    OBDBUSER=obdbuser
fi
if [[ $(echo $OBDBPASS) == "" ]]; then
    OBDBPASS=$(apg -m 16 -x 20 -a 1 -n 1 -M NCL)
fi
if [[ $(echo $DBHOST) == "" ]]; then
    DBHOST=localhost
fi
if [[ $(echo $OBFQDN) == "" ]]; then
    OBFQDN="openbroadcaster.example.com"
fi
if [[ $(echo $OBIP) == "" ]]; then
    OBIP="192.168.25.10"
fi
if [[ $(echo $OBRPLYML) == "" ]]; then
    OBRPLYML=noreply@example.com
fi
if [[ $(echo $OBMLNM) == "" ]]; then
    OBMLNM="OpenBroadcaster"
fi
if [[ $(echo $SALT) == "" ]]; then
    SALT=$(apg -m 16 -x 20 -a 1 -n 1 -M NCL)
fi

## Get the rest of our environment the way it needs to be.

## Dunno if I like this
# if [[ $(grep openbroadcaster /etc/passwd) == "" ]]; then
#   useradd -r -U openbroadcaster
# fi

if [ -e $CWD/ob.apache.conf ]; then
    rm $CWD/ob.apache.conf
fi
if [ -e $CWD/config.php ]; then 
    rm $CWD/config.php
fi
OBSLTPASS=$(echo -n "$SALT$OBADMINPASS" | openssl sha1)

## We will start with the easy stuff first, make the database and populate it.

if [[ $USEDBRT == "y" ]]; then
    mysqladmin -u $DBSU -p"$DBSUPASS" create $OBDBNM
    mysql -u $DBSU -p$DBSUPASS -e "GRANT CREATE,SELECT,INSERT,UPDATE,DELETE,ALTER on $OBDBNM.* to '$OBDBUSER'@'$DBHOST' IDENTIFIED BY '$OBDBPASS';"
fi
mysql -u $OBDBUSER -p"$OBDBPASS" $OBDBNM < $CWD/db/dbclean.sql
mysql -u $OBDBUSER -p"$OBDBPASS" $OBDBNM -e "UPDATE users SET password='$OBSLTPASS' WHERE username='admin';"

# echo "Database created and populated..."

## Now let's put create our media directory and populate it:

mkdir -p $MEDIAROOT/{archive,uploads,cache}
chown -R $WEBUSER:$WEBUSER $MEDIAROOT
chmod -R 2770 $MEDIAROOT

# echo "Media directory created and ready to use..."

## Now, let's populate our DocumentRoot:

mkdir -p $WEBROOT/assets/uploads
cp -ra $CWD/* $WEBROOT
chown -R $OBUSER:$OBUSER $WEBROOT
chown -R $WEBUSER:$WEBUSER $WEBROOT/assets
chmod -R 2770 $WEBROOT/assets
rm $WEBROOT/ob.installer.sh

# echo "Site files are in place..."

##Set up any cron jobs:
echo "*/5 * * * * $WEBUSER /usr/bin/php $WEBROOT/cron.php" > /etc/cron.d/openbroadcaster

## We need to create a file full of variables for OB to access the DB and such.
echo \
"<?

const OB_HASH_SALT     = '$SALT';
const OB_DB_USER       = '$OBDBUSER';
const OB_DB_PASS       = '$OBDBPASS';
const OB_DB_HOST       = '$DBHOST';
const OB_DB_NAME       = '$OBDBNM';
const OB_MEDIA         = '$MEDIAROOT';
const OB_MEDIA_UPLOADS = '$MEDIAROOT/uploads';
const OB_MEDIA_ARCHIVE = '$MEDIAROOT/archive';
const OB_CACHE         = '$MEDIAROOT/cache';
const OB_SITE          = 'http://$OBFQDN';
const OB_EMAIL_REPLY   = '$OBRPLYML';
const OB_EMAIL_FROM    = '$OBMLNM';" >> $WEBROOT/config.php

chown $OBUSER:$OBUSER $WEBROOT/config.php
chmod 640 $WEBROOT/config.php

# echo "constants file created and populated..."

## Last, we will create an apache config file for our intrepid users...
echo \
"<VirtualHost $OBIP:80>
    ServerName $OBFQDN
    DocumentRoot $WEBROOT
    <Directory $WEBROOT>
        Options Indexes FollowSymLinks MultiViews
        Order allow,deny
        allow from all
    </Directory>
    <Directory $WEBROOT/tools>
        Order allow,deny
        deny from all
    </Directory>
    <Directory $WEBROOT/db>
        Order allow,deny
        deny from all
    </Directory>
ErrorLog /var/log/apache2/$OBFQDN/err.log
LogLevel warn
CustomLog /var/log/apache2/$OBFQDN/access.log combined
</VirtualHost>" >> /etc/apache2/sites-available/ob.apache.conf