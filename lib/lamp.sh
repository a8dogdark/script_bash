#!/bin/bash

clear

# Validar si se ejecuta como root
if [[ "$EUID" -ne 0 ]]; then
    echo "Este script debe ejecutarse como root."
    exit 1
fi

# Validar arquitectura de 64 bits
if [[ "$(uname -m)" != "x86_64" && "$(uname -m)" != "aarch64" ]]; then
    echo "Este script solo puede ejecutarse en sistemas de 64 bits."
    exit 1
fi

# Validar que sea Ubuntu, Debian o AnduinOS, y definir DISTRO, DISVER y DBSERVER
if grep -qi 'AnduinOS' /etc/os-release; then
    DISTRO="AnduinOS"
    DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')
    DBSERVER="mysql-server"
elif grep -qi 'Ubuntu' /etc/os-release; then
    DISTRO="Ubuntu"
    DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')
    DBSERVER="mysql-server"
elif grep -qi 'Debian' /etc/os-release; then
    DISTRO="Debian"
    DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')
    DBSERVER="mariadb-server"
else
    echo "Este script solo puede ejecutarse en Ubuntu, Debian o AnduinOS."
    exit 1
fi

echo "*****************************************"
echo "* Bienvenido al isntalador de lamp      *"
echo "* Para Laravel 12 by Dogdark            *"
echo "* Se instalaran los siguientes paquetes *"
echo "*****************************************"
echo " "
echo "- Apache"
echo "- Php"
echo "- $DBSERVER"
echo "- Phpmyadmin"
echo "- Composer"
echo "- NodeJS"
echo "- Softwares"
echo "- Proyecto Laravel 12"

read -rp "Ingresa el nombre del proyecto Laravel a crear (sin guiones ni espacios, ejemplo: crud): " PROYECTO

# Si está vacío, usar valor por defecto
if [[ -z "$PROYECTO" ]]; then
    PROYECTO="crud"
fi

# Validar que no tenga espacios ni guiones
if [[ "$PROYECTO" =~ [-[:space:]] ]]; then
    echo "Error: el nombre no puede contener guiones ni espacios."
    exit 1
fi

read -rp "Ingresa la contraseña para el usuario phpMyAdmin: " PHPADMIN
if [[ -z "$PHPADMIN" ]]; then
    echo "Error: la contraseña de phpMyAdmin no puede estar vacía."
    exit 1
fi

read -rp "Ingresa la contraseña para el usuario root de la base de datos: " PHPROOT
if [[ -z "$PHPROOT" ]]; then
    echo "Error: la contraseña root no puede estar vacía."
    exit 1
fi

# Selección versión PHP
echo "Elige la versión de PHP a instalar (recomendada para Laravel 12: PHP 8.3):"
echo "1) PHP 8.2"
echo "2) PHP 8.3 (Recomendada)"
echo "3) PHP 8.4"

read -rp "Ingresa el número de la versión que deseas instalar [2]: " PHPOPTION
PHPOPTION=${PHPOPTION:-2}

case $PHPOPTION in
    1) PHPVERSION="8.2" ;;
    2) PHPVERSION="8.3" ;;
    3) PHPVERSION="8.4" ;;
    *)
        echo "Opción inválida. Saliendo."
        exit 1
        ;;
esac

# Menú de selección de software adicional
echo
echo "Selecciona uno o varios softwares para instalar, separa con espacios:"
echo "1) Visual Studio Code"
echo "2) Brave"
echo "3) Google Chrome"
echo "4) FtpZilla"

read -rp "Ingresa los números de las opciones elegidas (ejemplo: 1 3 4): " -a SELECCIONES

# Array con los nombres
SOFTWARES=("Visual Studio Code" "Brave" "Google Chrome" "FtpZilla")

SOFTWARES_SELECCIONADOS=()

for num in "${SELECCIONES[@]}"; do
    if [[ "$num" =~ ^[1-4]$ ]]; then
        SOFTWARES_SELECCIONADOS+=("${SOFTWARES[$((num-1))]}")
    else
        echo "Opción inválida: $num. Saliendo."
        exit 1
    fi
done

echo
echo "Resumen de configuración:"
echo "-------------------------"
echo "Nombre del proyecto Laravel: $PROYECTO"
echo "Contraseña phpMyAdmin: $PHPADMIN"
echo "Contraseña root base de datos: $PHPROOT"
echo "Versión PHP seleccionada: PHP $PHPVERSION"
echo "Softwares seleccionados:"

if [ ${#SOFTWARES_SELECCIONADOS[@]} -eq 0 ]; then
    echo "  Ninguno"
else
    for software in "${SOFTWARES_SELECCIONADOS[@]}"; do
        echo "  - $software"
    done
fi

read -rp "¿Quieres continuar? [s/n]: " RESPUESTA

case "${RESPUESTA,,}" in  # convierte a minúscula
    s) 
        echo "Continuando..." 
        ;;
    *)
        echo "Instalación cancelada."
        exit 1
        ;;
esac

# Crear carpeta tmp solo si no existe
if [[ ! -d ./tmp ]]; then
    mkdir ./tmp
fi

# Descargar slib.sh solo si no existe o está vacío
if [[ ! -s ./tmp/slib.sh ]]; then
    wget -q --https-only --no-check-certificate -O ./tmp/slib.sh "https://raw.githubusercontent.com/a8dogdark/script_bash/refs/heads/main/lib/slib.sh" > /dev/null 2>&1
    if [[ $? -ne 0 || ! -s ./tmp/slib.sh ]]; then
        echo "Error: no se pudo descargar correctamente el archivo slib.sh"
        exit 1
    fi
    chmod +x ./tmp/slib.sh
fi

# Incluir slib.sh
source ./tmp/slib.sh

# Actualizar sistema en primer plano para que espere a terminar
run_ok "apt update > /dev/null 2>&1" "Actualizando el sistema"
run_ok "apt upgrade -y > /dev/null 2>&1" "Actualizando paquetes"

# Validar e instalar paquetes esenciales antes de Ondrej
if ! dpkg -l | grep -qw git; then
    run_ok "apt install -y git > /dev/null 2>&1" "Instalando git"
fi

if ! dpkg -l | grep -qw zip; then
    run_ok "apt install -y zip > /dev/null 2>&1" "Instalando zip"
fi

if ! dpkg -l | grep -qw unzip; then
    run_ok "apt install -y unzip > /dev/null 2>&1" "Instalando unzip"
fi

if ! dpkg -l | grep -qw gpg; then
    run_ok "apt install -y gpg > /dev/null 2>&1" "Instalando gpg"
fi

if ! dpkg -l | grep -qw curl; then
    run_ok "apt install -y curl > /dev/null 2>&1" "Instalando curl"
fi

if ! dpkg -l | grep -qw apt-transport-https; then
    run_ok "apt install -y apt-transport-https > /dev/null 2>&1" "Instalando apt-transport-https"
fi

# Verificar si repositorio Ondřej Surý está agregado
if ! grep -h "^deb .*\bondrej/php\b" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null | grep -q .; then
    run_ok "add-apt-repository ppa:ondrej/php -y > /dev/null 2>&1" "Agregando repositorio Ondřej Surý"
fi

# Actualizar sistema en primer plano para que espere a terminar
run_ok "apt update > /dev/null 2>&1" "Actualizando el sistema"
run_ok "apt upgrade -y > /dev/null 2>&1" "Actualizando paquetes"
    
# Validar e instalar Apache si no está instalado
if ! dpkg -l | grep -qw apache2; then
    run_ok "apt install -y apache2 > /dev/null 2>&1" "Instalando apache"
fi

# Habilitar módulo rewrite de Apache si no está habilitado
if ! apache2ctl -M 2>/dev/null | grep -qw rewrite_module; then
    run_ok "a2enmod rewrite > /dev/null 2>&1" "Habilitando módulo rewrite de Apache"
    run_ok "systemctl restart apache2 > /dev/null 2>&1" "Reiniciando Apache para aplicar cambios"
fi

# Validar e instalar PHP si no está instalado
if ! dpkg -l | grep -qw "php$PHPVERSION"; then
    run_ok "apt install -y php$PHPVERSION > /dev/null 2>&1" "Instalando PHP $PHPVERSION"
fi

# Validar e instalar extensiones PHP requeridas para Laravel, WordPress y MySQL/MariaDB

if ! php -m | grep -iw bcmath > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-bcmath > /dev/null 2>&1" 'Instalando extensión PHP: bcmath'
fi

if ! php -m | grep -iw ctype > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-ctype > /dev/null 2>&1" 'Instalando extensión PHP: ctype'
fi

if ! php -m | grep -iw json > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-json > /dev/null 2>&1" 'Instalando extensión PHP: json'
fi

if ! php -m | grep -iw mbstring > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-mbstring > /dev/null 2>&1" 'Instalando extensión PHP: mbstring'
fi

if ! php -m | grep -iw openssl > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-openssl > /dev/null 2>&1" 'Instalando extensión PHP: openssl'
fi

if ! php -m | grep -iw pdo > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-pdo > /dev/null 2>&1" 'Instalando extensión PHP: pdo'
fi

if ! php -m | grep -iw tokenizer > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-tokenizer > /dev/null 2>&1" 'Instalando extensión PHP: tokenizer'
fi

if ! php -m | grep -iw xml > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-xml > /dev/null 2>&1" 'Instalando extensión PHP: xml'
fi

if ! php -m | grep -iw curl > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-curl > /dev/null 2>&1" 'Instalando extensión PHP: curl'
fi

if ! php -m | grep -iw intl > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-intl > /dev/null 2>&1" 'Instalando extensión PHP: intl'
fi

if ! php -m | grep -iw mysqli > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-mysqli > /dev/null 2>&1" 'Instalando extensión PHP: mysqli'
fi

if ! php -m | grep -iw pdo_mysql > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-pdo-mysql > /dev/null 2>&1" 'Instalando extensión PHP: pdo_mysql'
fi

if ! php -m | grep -iw dom > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-xml > /dev/null 2>&1" 'Instalando extensión PHP: dom (xml)'
fi

if ! php -m | grep -iw simplexml > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-xml > /dev/null 2>&1" 'Instalando extensión PHP: simplexml (xml)'
fi

if ! php -m | grep -iw zip > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-zip > /dev/null 2>&1" 'Instalando extensión PHP: zip'
fi

if ! php -m | grep -iw exif > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-exif > /dev/null 2>&1" 'Instalando extensión PHP: exif'
fi

if ! php -m | grep -iw gd > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-gd > /dev/null 2>&1" 'Instalando extensión PHP: gd'
fi

if ! php -m | grep -iw imagick > /dev/null; then
    run_ok "apt install -y php$PHPVERSION-imagick > /dev/null 2>&1" "Instalando extensión PHP: imagick para PHP $PHPVERSION"
fi

# Validar si info.php existe en /var/www/html y crearlo si no existe (usando tee para evitar problemas de permisos)
if [[ ! -f /var/www/html/info.php ]]; then
    echo "<?php phpinfo(); ?>" | tee /var/www/html/info.php > /dev/null
    chmod 644 /var/www/html/info.php
fi

# Validar e instalar el servidor de base de datos si no está instalado
if ! dpkg -l | grep -qw "$DBSERVER"; then
    run_ok "apt install -y $DBSERVER > /dev/null 2>&1" "Instalando $DBSERVER"
fi

# Configurar usuarios en base de datos (silencioso, sin mostrar salida)
mysql -uroot > /dev/null 2>&1 <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${PHPROOT}';
FLUSH PRIVILEGES;
EOF

if [[ $? -ne 0 ]]; then
    echo "Error: No se pudieron configurar los usuarios de base de datos."
    exit 1
fi

# Instalar phpMyAdmin si no está instalado
if ! dpkg -l | grep -qw phpmyadmin; then
    # Preconfigurar phpMyAdmin para instalación no interactiva
    run_ok "echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections" "Configurando phpMyAdmin (no interactivo)"
    run_ok "echo 'phpmyadmin phpmyadmin/app-password-confirm password $PHPADMIN' | debconf-set-selections" "Confirmando password admin"
    run_ok "echo 'phpmyadmin phpmyadmin/mysql/admin-pass password $PHPROOT' | debconf-set-selections" "Configurando password usuario"
    run_ok "echo 'phpmyadmin phpmyadmin/mysql/app-pass password $PHPADMIN' | debconf-set-selections" "Configurando password mysql"
    run_ok "echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections" "Reconfigurando apache"

    # Instalar phpMyAdmin
    run_ok "apt install -y phpmyadmin > /dev/null 2>&1" "Instalando phpMyAdmin"

    # Configurar Apache para phpMyAdmin si existe la configuración
    if [[ -f /etc/phpmyadmin/apache.conf ]]; then
        if [[ ! -L /etc/apache2/conf-enabled/phpmyadmin.conf ]]; then
            run_ok "ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-enabled/phpmyadmin.conf" "Habilitando configuración de phpMyAdmin en Apache"
        fi
        run_ok "systemctl reload apache2" "Recargando Apache"
    fi

    # Restaurar versión PHP CLI elegida por el usuario (por si fue cambiada)
    if update-alternatives --list php | grep -q "/usr/bin/php$PHPVERSION"; then
        run_ok "update-alternatives --set php /usr/bin/php$PHPVERSION > /dev/null 2>&1" "Restaurando PHP CLI a $PHPVERSION tras instalar phpMyAdmin"
    fi
fi

# Instalar Composer globalmente si no está instalado
if ! command -v composer >/dev/null 2>&1; then
    run_ok "curl -sS https://getcomposer.org/installer | php > /dev/null 2>&1" "Descargando instalador de Composer"
    run_ok "mv composer.phar /usr/local/bin/composer" "Moviendo composer.phar a /usr/local/bin/composer"
    run_ok "chmod +x /usr/local/bin/composer" "Dando permisos de ejecución a composer"
fi

# Instalar Node.js última versión estable si no está instalado
if ! command -v node >/dev/null 2>&1; then
    run_ok "curl -fsSL https://deb.nodesource.com/setup_current.x | bash - > /dev/null 2>&1" "Agregando repositorio NodeSource para Node.js última versión"
    run_ok "apt-get install -y nodejs > /dev/null 2>&1" "Instalando Node.js última versión estable"
fi

# Instalar Visual Studio Code si fue seleccionado y no está instalado
if [[ " ${SOFTWARES_SELECCIONADOS[*]} " == *"Visual Studio Code"* ]]; then
    if ! command -v code >/dev/null 2>&1; then
        run_ok "wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg" "Descargando clave GPG de Visual Studio Code"
        run_ok "install -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg" "Instalando clave GPG de Visual Studio Code"
        rm -f microsoft.gpg
        echo "Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg" > /etc/apt/sources.list.d/vscode.sources
        run_ok "apt update > /dev/null 2>&1" "Actualizando repositorios"
        run_ok "apt install -y code > /dev/null 2>&1" "Instalando Visual Studio Code"
    fi
fi

# Instalar Brave si fue seleccionado y no está instalado
if [[ " ${SOFTWARES_SELECCIONADOS[*]} " == *"Brave"* ]]; then
    if ! command -v brave-browser >/dev/null 2>&1; then
        run_ok "curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg" "Agregando clave GPG Brave"
        run_ok "echo 'deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main' > /etc/apt/sources.list.d/brave-browser-release.list" "Agregando repositorio Brave"
        run_ok "apt update > /dev/null 2>&1" "Actualizando repositorios"
        run_ok "apt install -y brave-browser > /dev/null 2>&1" "Instalando Brave"
    fi
fi

# Instalar Google Chrome si fue seleccionado y no está instalado
if [[ " ${SOFTWARES_SELECCIONADOS[*]} " == *"Google Chrome"* ]]; then
    if ! command -v google-chrome >/dev/null 2>&1; then
        run_ok "wget -q -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" "Descargando paquete Google Chrome"
        run_ok "apt install -y /tmp/google-chrome.deb > /dev/null 2>&1" "Instalando Google Chrome"
        rm -f /tmp/google-chrome.deb
    fi
fi

# Instalar FileZilla si fue seleccionado y no está instalado
if [[ " ${SOFTWARES_SELECCIONADOS[*]} " == *"FtpZilla"* ]]; then
    if ! command -v filezilla >/dev/null 2>&1; then
        run_ok "apt install -y filezilla > /dev/null 2>&1" "Instalando FileZilla"
    fi
fi

# Crear carpeta laravel dentro de /var/www si no existe
if [[ ! -d /var/www/laravel ]]; then
    mkdir -p /var/www/laravel
    chown -R www-data:www-data /var/www/laravel
fi

# Crear el proyecto Laravel 12 en modo silencioso (ignorar errores con || true)
cd /var/www/laravel || exit 1
run_ok "composer create-project --prefer-dist laravel/laravel:^12.0 $PROYECTO --quiet || true" "Creando proyecto Laravel 12 en /var/www/laravel/$PROYECTO"

# Cambiar permisos de la carpeta del proyecto para www-data
#chown -R www-data:www-data "/var/www/laravel/$PROYECTO"

# Crear carpeta logs si no existe y asignar permisos para evitar error 500
#mkdir -p "/var/www/laravel/$PROYECTO/storage/logs"
#chown -R www-data:www-data "/var/www/laravel/$PROYECTO/storage"
#chown -R www-data:www-data "/var/www/laravel/$PROYECTO/bootstrap/cache"
#chmod -R 775 "/var/www/laravel/$PROYECTO/storage"
#chmod -R 775 "/var/www/laravel/$PROYECTO/bootstrap/cache"

# Preparar archivo .env y generar key de aplicación
cd "/var/www/laravel/$PROYECTO" || exit 1
if [ ! -f .env ]; then
    cp .env.example .env
fi

# Configurar conexión MySQL en .env
run_ok "sed -i \"s/^DB_CONNECTION=.*/DB_CONNECTION=mysql/\" .env" "Configurando DB_CONNECTION en .env"
run_ok "sed -i \"s/^DB_HOST=.*/DB_HOST=127.0.0.1/\" .env" "Configurando DB_HOST en .env"
run_ok "sed -i \"s/^DB_PORT=.*/DB_PORT=3306/\" .env" "Configurando DB_PORT en .env"
run_ok "sed -i \"s/^DB_DATABASE=.*/DB_DATABASE=${PROYECTO}_db/\" .env" "Configurando DB_DATABASE en .env"
run_ok "sed -i \"s/^DB_USERNAME=.*/DB_USERNAME=root/\" .env" "Configurando DB_USERNAME en .env"
run_ok "sed -i \"s/^DB_PASSWORD=.*/DB_PASSWORD=${PHPROOT}/\" .env" "Configurando DB_PASSWORD en .env"

# Crear archivo mysql client config temporal para root, evitar warning contraseña en CLI
run_ok "
cat > /root/.my.cnf <<EOF
[client]
user=root
password=\"${PHPROOT}\"
EOF
chmod 600 /root/.my.cnf

mysql -e \"CREATE DATABASE IF NOT EXISTS ${PROYECTO}_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;\"

rm -f /root/.my.cnf
" "Creando base de datos MySQL"


run_ok "bash -c 'sudo -u www-data php artisan key:generate > /dev/null 2>&1'" "Generando key de aplicación Laravel"
run_ok "bash -c 'sudo -u www-data php artisan cache:clear > /dev/null 2>&1'" "Limpiando cache Laravel"
run_ok "bash -c 'sudo -u www-data php artisan migrate --force > /dev/null 2>&1'" "Ejecutando migraciones Laravel"
run_ok "sudo -u www-data php artisan config:clear > /dev/null 2>&1" "Limpiando configuración Laravel"
run_ok "chown -R www-data:www-data /var/www/laravel/$PROYECTO" "Asignando propiedad www-data a proyecto"
run_ok "chmod -R 755 /var/www/laravel/$PROYECTO" "Ajustando permisos del proyecto"

# Volver al directorio original
cd - > /dev/null 2>&1

# Crear archivo de configuración Apache para el dominio $PROYECTO.test
APACHE_CONF="/etc/apache2/sites-available/${PROYECTO}.test.conf"

run_ok "bash -c 'cat > \"$APACHE_CONF\" <<EOF
<VirtualHost *:80>
    ServerName ${PROYECTO}.test
    DocumentRoot /var/www/laravel/${PROYECTO}/public

    <Directory /var/www/laravel/${PROYECTO}/public>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \\\${APACHE_LOG_DIR}/${PROYECTO}_error.log
    CustomLog \\\${APACHE_LOG_DIR}/${PROYECTO}_access.log combined
</VirtualHost>
EOF
'" "Creando configuración Apache para ${PROYECTO}.test"

# Habilitar el nuevo sitio
run_ok "a2ensite \"${PROYECTO}.test.conf\" > /dev/null 2>&1" "Activando sitio ${PROYECTO}.test"

# Recargar Apache para aplicar cambios
run_ok "systemctl reload apache2" "Recargando Apache para aplicar configuración de ${PROYECTO}.test"

# Agregar entrada al archivo hosts si no existe
run_ok "bash -c 'grep -q \"^127.0.0.1\\s\\+${PROYECTO}.test\" /etc/hosts || echo \"127.0.0.1    ${PROYECTO}.test\" >> /etc/hosts'" "Agregando entrada en /etc/hosts para ${PROYECTO}.test"



# Eliminar carpeta tmp y todo su contenido
rm -rf ./tmp

# Dar permisos totales a la carpeta /var/www/laravel para que cualquier usuario pueda crear y modificar proyectos
chmod -R 777 /var/www/laravel

echo
echo "La carpeta /var/www/laravel y todo su contenido tienen permisos 777."
echo "Esto permite que cualquier usuario pueda crear o modificar proyectos Laravel en esa ubicación."
echo "Si quieres restringir los permisos, puedes ajustarlos manualmente luego."

echo
echo "Fin de Instalación."
