#!/bin/bash

#Para mostrar los comandos que se van ejecutando
set -ex 

echo "Instalación de la pila LAMP"

#Actualizo repositorios
apt update
apt upgrade -y

#Instalamos el servidor web apache
apt install apache2 -y

#Habilitamos el módulo rewrite
a2enmod rewrite

#Instalamos PHP
sudo apt install php libapache2-mod-php php-mysql -y

#Reiniciamos el servicio de Apache
 systemctl restart apache2

#Copiamos archivo de configuración
cp ../conf/000-default.conf /etc/apache2/sites-available 

#Instalamos MySQL Server
sudo apt install mysql-server -y

#Copiamos el script de prueba de PHP en /var/www/html
cp ../PHP/index.php /var/www/html

#Modificamos el propietario
chown -R www-data:www-data /var/www/html/adminer

