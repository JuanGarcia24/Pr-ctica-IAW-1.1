# Práctica-IAW-1.1
Repositorio de la Práctica 1.1
# Práctica Aplicaciones Web - Instalación de LAMP con Herramientas Adicionales

## Objetivo de la Práctica

El objetivo de esta práctica es instalar una pila LAMP (Linux, Apache, MySQL, PHP), incluyendo también herramientas adicionales cómo **PHPMyAdmin**, **Adminer** y **GoAccess**, automatizando su instalación y configuración mediante scripts de bash. Se realizarán configuraciones de seguridad, como autenticación básica en ciertas rutas del servidor, y la generación de informes en tiempo real de las estadísticas de acceso al servidor web.

## Proceso de Instalación

A continuación, se detalla el proceso de instalación y configuración que se lleva a cabo en esta práctica, explicando la función de cada archivo involucrado en el repositorio.

- **`install_lamp.sh`**: Este script automatiza la instalación de Apache, PHP y MySQL, y configura Apache para que utilice el archivo PHP de prueba `index.php`.

#### Archivo `install_lamp.sh`:

1. **Actualización de repositorios**
    apt update
    apt upgrade -y

2. **Instalación de Servidor Web Apache y habilitamos el módulo rewrite**
    apt install apache2 -y
    a2enmod rewrite

3. **Instalación de PHP y reinicio de servicio apache**
    apt install php libapache2-mod-php php-mysql -y
    systemctl restart apache2
 
4. **Copiamos el archivo de configuración**: 
    cp ../conf/000-default.conf /etc/apache2/sites-available

5. **Instalación de MySQL Server**: Se instala MySQL Server, que proporcionará la base de datos.
    apt install mysql-server -y

6. **Copia del archivo de prueba PHP en /var/www/html**
    cp ../PHP/index.php /var/www/html
    
7. **Modificamos el propietario**
    chown -R www-data:www-data /var/www/html/adminer

### 2. Configuración de Herramientas Adicionales

Después de tener instalada la pila LAMP, el siguiente paso es instalar herramientas adicionales como **PHPMyAdmin** y **Adminer** para gestionar bases de datos, y **GoAccess** para generar informes de estadísticas en tiempo real.

- **`install_tools.sh`**: Este script instala y configura las herramientas adicionales necesarias. Utiliza variables definidas en el archivo `.env` para gestionar configuraciones, como contraseñas y nombres de usuarios.

#### Pasos realizados por `install_tools.sh`:

1. **Importamos el archivo de variables**
    source .env

2. **Mostrar los comandos que se van ejecutando**
    set -ex 
    echo "Instalación de la pila LAMP"

3. **Actualización de respositorios**
    apt update
    apt upgrade -y
      
5. **Respuestas Automáticas para la instalación de PHPMyAdmin**
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_APP_PASSWORD" | debconf-set-selections
    echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_APP_PASSWORD" | debconf-set-selections

6. **Instalación de PHPMyAdmin con sus paquetes**
    sudo apt install phpmyadmin php-mbstring php-zip php-gd php-json php-curl -y

7. **Instalación de Adminer**
    Paso 1 - Creamos la carpeta para Adminer
    mkdir -p /var/www/html/adminer
    
    Paso 2 - Instalamos Adminer
    wget https://github.com/vrana/adminer/releases/download/v4.8.1/adminer-4.8.1-mysql.php -P /var/www/html/adminer
    
    Paso 3 - Cambiamos el nombre del sitio
    mv /var/www/html/adminer/adminer-4.8.1-mysql.php /var/www/html/adminer/index.php
    
    Paso 4 - Modificamos el propietario
    chown -R www-data:www-data /var/www/html/adminer

3. **Creación de una Base de Datos y Usuario MySQL, y también le proporcionamos privilegios**
    mysql -u root <<< "DROP DATABASE IF EXISTS $DB_NAME"
    mysql -u root <<< "create database $DB_NAME"
    
    mysql -u root <<< "DROP USER IF EXISTS '$DB_USER'@'%'"
    mysql -u root <<< "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'"
    mysql -u root <<< "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%'"

4. **Instalación de GoAccess**
    apt install goaccess -y
    
5. **Creamos un directorio para los informes estadísticos**
    mkdir -p /var/www/html/stats

6. **Creación de un archivo HTML en tiempo real en segundo plano**
    goaccess /var/log/apache2/access.log -o /var/www/html/stats/index.html --log-format=COMBINED --real-time-html --daemonize

7. **Control de acceso a un directorio con autenticación básica**
    cp ../conf/000-default-stats.conf /etc/apache2/sites-available
    
8. **Deshabilitamos el virtualhost que viene por defecto**
    a2dissite 000-default.conf
   
10. **Habilitamos el nuevo virtualhost**
    a2ensite 000-default-stats.conf
     
11. **Reiniciamos el servicio**
    systemctl reload apache2
    
11. **Creamos el archivo de contraseñas**
    sudo htpasswd -bc /etc/apache2/.htpasswd $STATS_USERNAME $STATS_PASSWORD

12. **Copiar el archivo 000-default-htaccess.conf a la carpeta de sites-available de Apache**
    cp ../conf/000-default-htaccess.conf /etc/apache2/sites-available

13. **Deshabilitamos el antiguo virtualhost**
    a2dissite 000-default-htaccess.conf
  
14. **Habilitamos el nuevo virtualhost**
    a2ensite 000-default-htaccess.conf

15. **Copiamos el archivo .htacess a /var/www/html/stats**
    cp ../conf/.htaccess /var/www/html/stats

### 3. Configuración de Virtual Hosts y Seguridad

El siguiente paso es configurar los **Virtual Hosts** y proteger el acceso a ciertas rutas utilizando **autenticación básica**.

- **`000-default.conf`**: Este archivo de configuración define el virtual host principal de Apache, sirviendo el contenido de `/var/www/html`.
    ```apache
    <VirtualHost *:80>
        DocumentRoot /var/www/html
        DirectoryIndex index.php index.html
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
    </VirtualHost>
    ```

- **`000-default-stats.conf`**: Este archivo de configuración es específico para el acceso a la carpeta de estadísticas generadas por GoAccess. Además, implementa **autenticación básica** utilizando un archivo `.htpasswd`.
    ```apache
    <Directory "/var/www/html/stats">
        AuthType Basic
        AuthName "Acceso restringido"
        AuthBasicProvider file
        AuthUserFile "/etc/apache2/.htpasswd"
        Require valid-user
    </Directory>
    ```

- **`.htaccess`**: El archivo `.htaccess` también establece reglas de autenticación básica para proteger directorios.
    ```apache
    AuthType Basic
    AuthName "Acceso restringido"
    AuthBasicProvider file
    AuthUserFile "/etc/apache2/.htpasswd"
    Require valid-user
    ```

El script **`install_tools.sh`** se encarga de crear el archivo `.htpasswd` y establecer un usuario y contraseña para proteger la sección de estadísticas.

```bash
sudo htpasswd -bc /etc/apache2/.htpasswd $STATS_USERNAME $STATS_PASSWORD
