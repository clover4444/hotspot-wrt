#!/bin/bash
echo "[INFO] Menginstall paket yang di butuhkan....."
echo "[INFO] Installing sudo..."
opkg remove sudo
wget https://downloads.openwrt.org/releases/packages-19.07/x86_64/packages/sudo_1.8.28p1-2_x86_64.ipk && opkg install sudo_1.8.28p1-2_x86_64.ipk && chmod u+w /etc/sudoers
rm -f sudo_1.8.28p1-2_x86_64.ipk
clear
echo "[INFO] Installing mariadb server dan client..."
sleep 5
opkg update && opkg install mariadb-server mariadb-client mariadb-server-extra mariadb-client-extra
clear
echo "[INFO] Downloading konfigurasi mariadb..."
sleep 5
rm -f /etc/mysql/my.cnf && wget -O /etc/mysql/my.cnf https://raw.githubusercontent.com/clover4444/hotspot-wrt/main/mysql/my.cnf
rm -f /etc/mysql/conf.d/50-server.cnf && wget -O /etc/mysql/conf.d/50-server.cnf https://raw.githubusercontent.com/clover4444/hotspot-wrt/main/mysql/50-server.cnf
sed -i "s/option enabled '0'/option enabled '1'/g" /etc/config/mysqld
mysql_install_db --force
sudo chown -R mariadb:mariadb /media/data/mysql
echo "[INFO] Starting mysql server..."
/etc/init.d/mysqld start
mysqladmin -u root password "indonesia"
echo "[INFO] default password : indonesia"
echo "[INFO] Creating database"
echo -n "Masukan password: "
read pwd
mysql -u root -p$pwd -e "CREATE DATABASE radiusdb;"
echo -n "Masukan password lagi: "
read pwd
mysql -u root -p$pwd -e 'GRANT ALL ON radiusdb.* TO root@localhost IDENTIFIED BY "indonesia";'
clear
echo "[INFO] Installing freeradius..."
sleep 5
opkg update && opkg install freeradius3-default freeradius3-mod-sql-mysql freeradius3-utils
echo -n "Masukan password: "
read pwd
mysql -u root -p$pwd radiusdb < /etc/freeradius3/mods-config/sql/main/mysql/schema.sql
rm -f /etc/freeradius3/mods-enabled/sql && wget -O /etc/freeradius3/mods-enabled/sql https://raw.githubusercontent.com/clover4444/hotspot-wrt/main/freeradius/sql
rm -f /etc/freeradius3/mods-config/sql/main/mysql/queries.conf && wget -O /etc/freeradius3/mods-config/sql/main/mysql/queries.conf https://raw.githubusercontent.com/clover4444/hotspot-wrt/main/freeradius/queries.conf
echo "[INFO] Starting freeradius..."
/etc/init.d radiusd start
/etc/init.d radiusd enable
/etc/init.d/radiusd restart
clear
echo "[INFO] Installing paket tambahan php..."
sleep 3
opkg update && opkg install php7-cli php7-mod-xml && mv /usr/bin/php-cli /usr/bin/php
wget https://pear.php.net/go-pear.phar -O /root/go-pear.php
cd /root/
php go-pear.php
wget http://download.pear.php.net/package/DB-1.11.0.tgz
pear install DB-1.11.0.tgz
rm -f DB-1.11.0.tgz
clear
echo "[INFO] Installing phpmyadmin...."
sleep 3
opkg update && opkg install php7-mod-mbstring php7-mod-json php7-mod-session php7-mod-mysqli php7-mod-gd php7-pecl-mcrypt php7-mod-filter
wget https://files.phpmyadmin.net/phpMyAdmin/5.2.0/phpMyAdmin-5.2.0-all-languages.zip --no-check-certificate
unzip phpMyAdmin-5.2.0-all-languages.zip
rm -f phpMyAdmin-5.2.0-all-languages.zip
mv phpMyAdmin-5.2.0-all-languages /www/phpmyadmin
cp /www/phpmyadmin/config.sample.inc.php /www/phpmyadmin/config.inc.php
chmod 644 /www/phpmyadmin/config.inc.php
sed -i 's/localhost/127.0.0.1/g' "/www/phpmyadmin/config.inc.php"
export SECRET=`php -r 'echo base64_encode(random_bytes(24));'`
echo "\$cfg['blowfish_secret'] = '$SECRET';" \
    >> /www/phpmyadmin/config.inc.php
clear
echo "[INFO] Installing daloradius..."
wget https://github.com/lirantal/daloradius/archive/master.zip
unzip master.zip
rm -f master.zip
mv daloradius-master /www/daloradius
cd /www/daloradius
echo -n "Masukan password: "
read pwd
mysql -u root -p$pwd radiusdb < contrib/db/fr2-mysql-daloradius-and-freeradius.sql
echo -n "Masukan password lagi: "
read pwd
mysql -u root -p$pwd radiusdb < contrib/db/mysql-daloradius.sql
wget -O /www/daloradius/library/daloradius.conf.php https://raw.githubusercontent.com/clover4444/hotspot-wrt/main/daloradius/daloradius.conf.php
rm -f /www/daloradius/library/opendb.php && wget -O /www/daloradius/library/opendb.php https://raw.githubusercontent.com/clover4444/hotspot-wrt/main/daloradius/opendb.php
rm -f /www/daloradius/include/management/userReports.php && wget -O /www/daloradius/include/management/userReports.php https://raw.githubusercontent.com/clover4444/hotspot-wrt/main/daloradius/userReports.php
clear
echo "[INFO] Installing template coovachilli..."
sleep 5
sed -i "s/list index_page 'index.php'/list index_page 'index.php hotspotlogin.php'/g" /etc/config/uhttpd
cd /www/
wget -c https://github.com/mongramosjr/hotspot-login/archive/master.zip -O /www/hotspot-login-master.zip
unzip /www/hotspot-login-master.zip
rm -f /www/hotspot-login-master.zip
mv /www/hotspot-login-master /www/hotspot-login
rm -f /www/hotspot-login/hotspotlogin.php && wget -O /www/hotspot-login/hotspotlogin.php https://raw.githubusercontent.com/clover4444/hotspot-wrt/main/coovachilli/hotspotlogin.php
/etc/init.d/uhttpd restart
echo "[INFO] Installing coovachilli..."
sleep 5
opkg update && opkg install coova-chilli kmod-tun
/etc/init.d/chilli stop
/etc/init.d/chilli disable
mv /etc/config/chilli /etc/config/chilli.backup && wget -O /etc/config/chilli https://raw.githubusercontent.com/clover4444/hotspot-wrt/main/coovachilli/chilli
echo 'client management {
    ipaddr = 192.168.0.0/24
    secret = testing123
}' | sudo tee -a /etc/freeradius3/clients.conf
ms=$(/etc/init.d/mysqld status)
rs=$(/etc/init.d/radiusd status)
us=$(/etc/init.d/uhttpd status)
cs=$(/etc/init.d/chilli status)
clear
echo "======[INFORMASI]======"
echo "Mysql service : $ms"
echo "Freeradius service : $rs"
echo "Uhttpd service : $us"
echo "Coovachilli service : $cs"
echo "default user/pw daloRADIUS : administrator/radius"
echo "default user/pw phpMyAdmin : root/indonesia"
echo "======================="
echo "Buat username dan password di http://192.168.1.1/daloradius"
echo "Starting coovachilli dalam 10 detik...."
echo "Wifi akan disconnect dan meminta untuk login..."
#/etc/init.d/chilli enable
sleep 10
/etc/init.d/chilli start
