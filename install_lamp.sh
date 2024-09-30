#!/bin/bash

#Para mostrar los comandos que se van ejecutando
set -ex 

echo "Instalación de la pila LAMP"

#Actualizo repositorios
apt update

#Instalamos el servidor web apache
apt install apache2 -y
