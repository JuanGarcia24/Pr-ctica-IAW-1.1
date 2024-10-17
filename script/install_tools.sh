#!/bin/bash

#Importamos el archivo de variables
source .env

#Para mostrar los comandos que se van ejecutando
set -ex 

echo "Instalación de la pila LAMP"

#Actualizo repositorios
apt update
apt upgrade -y

#Respuestas Automáticas para la instalación de PHPMyAdmin
echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_APP_PASSWORD" | debconf-set-selections
echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_APP_PASSWORD" | debconf-set-selections

#Instalamos PHPMyAdmin con sus paquetes
sudo apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y

#Instalación de Adminer

#Paso 1 - Creamos la carpeta para Adminer
mkdir -p /var/www/html/adminer

#Paso 2 - Instalamos Adminer
wget https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-mysql.php -P /var/www/html/adminer

#Paso 3 - Cambiamos el nombre del sitio
mv /var/www/html/adminer/adminer-4.8.1-mysql.php /var/www/html/adminer/index.php

#Paso 4 - Modificamos el propietario
chown -R www-data:www-data /var/www/html/adminer

#Creamos una base de datos de ejemplo
mysql -u root <<< "DROP DATABASE IF EXISTS $DB_NAME"
mysql -u root <<< "create database $DB_NAME"


mysql -u root <<< "DROP USER IF EXISTS '$DB_USER'@'%'"
mysql -u root <<< "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%'"

#Instalamos goacess
apt install goaccess -y

#Creamos un directorio para los informes estadísticos
mkdir -p /var/www/html/stats

#Creación de un archivo HTML en tiempo real en segundo plano
goaccess /var/log/apache2/access.log -o /var/www/html/stats/index.html --log-format=COMBINED --real-time-html --daemonize

#Control de acceso a un directorio con autenticación básica
cp ../conf/000-default-stats.conf /etc/apache2/sites-available

#Deshabilitamos el virtualhost que viene por defecto 
a2dissite 000-default.conf

#Habilitamos el nuevo virtualhost
a2ensite 000-default-stats.conf

#Reiniciamos el servicio
systemctl reload apache2

#Creación del archivo .htpasswd para establecer un usuario y contraseña para proteger la sección de estadísticas
sudo htpasswd -bc /etc/apache2/.htpasswd $STATS_USERNAME $STATS_PASSWORD

#Copiar el archivo 000-default-htaccess.conf a la carpeta de sites-available de Apache
cp ../conf/000-default-htaccess.conf /etc/apache2/sites-available

#Deshabilitamos el antiguo virtualhost#
a2dissite 000-default-htaccess.conf

#Habilitamos el nuevo virtualhost
a2ensite 000-default-htaccess.conf

#Copiamos el archivo .htacess a /var/www/html/stats
cp ../conf/.htaccess /var/www/html/stats