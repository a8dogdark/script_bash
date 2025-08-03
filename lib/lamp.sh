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

run_ok "apt update > /dev/null 2>&1 &" "Actualizando el sistema"
run_ok "apt upgrade -y > /dev/null 2>&1 &" "Actualizando paquetes"

# Validar e instalar git si no está instalado
if ! dpkg -l | grep -qw git; then
    run_ok "apt install -y git > /dev/null 2>&1 &" "Instalando git"
fi

# Validar e instalar zip si no está instalado
if ! dpkg -l | grep -qw zip; then
    run_ok "apt install -y zip > /dev/null 2>&1 &" "Instalando zip"
fi

# Validar e instalar unzip si no está instalado
if ! dpkg -l | grep -qw unzip; then
    run_ok "apt install -y unzip > /dev/null 2>&1 &" "Instalando unzip"
fi

# Validar e instalar gpg si no está instalado
if ! dpkg -l | grep -qw gpg; then
    run_ok "apt install -y gpg > /dev/null 2>&1 &" "Instalando gpg"
fi

# Validar e instalar curl si no está instalado
if ! dpkg -l | grep -qw curl; then
    run_ok "apt install -y curl > /dev/null 2>&1 &" "Instalando curl"
fi

# Verificar si repositorio Ondřej Surý está agregado
if ! grep -h "^deb .*\bondrej/php\b" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null | grep -q .; then
    run_ok "add-apt-repository ppa:ondrej/php -y > /dev/null 2>&1 &" "Agregando repositorio Ondřej Surý"
fi

# Actualizar el sistema siempre después de validar/agregar repositorios
run_ok "apt update > /dev/null 2>&1 &" "Actualizando el sistema"
run_ok "apt upgrade -y > /dev/null 2>&1 &" "Actualizando paquetes"

# Validar e instalar Apache si no está instalado
if ! dpkg -l | grep -qw apache2; then
    run_ok "apt install -y apache2 > /dev/null 2>&1 &" "Instalando apache"
fi

# Habilitar módulo rewrite de Apache si no está habilitado
if ! apache2ctl -M 2>/dev/null | grep -qw rewrite_module; then
    run_ok "a2enmod rewrite > /dev/null 2>&1 &" "Habilitando módulo rewrite de Apache"
    run_ok "systemctl restart apache2 > /dev/null 2>&1 &" "Reiniciando Apache para aplicar cambios"
fi

# Validar e instalar PHP si no está instalado
if ! dpkg -l | grep -qw "php$PHPVERSION"; then
    run_ok "apt install -y php$PHPVERSION > /dev/null 2>&1 &" "Instalando PHP $PHPVERSION"
fi

# Extensiones PHP necesarias para Laravel 12 y WordPress (una por una)

# Laravel 12
if ! php -m | grep -iq bcmath; then
    run_ok "apt install -y php$PHPVERSION-bcmath > /dev/null 2>&1 &" "Instalando extensión PHP: bcmath"
fi
if ! php -m | grep -iq ctype; then
    run_ok "apt install -y php$PHPVERSION-ctype > /dev/null 2>&1 &" "Instalando extensión PHP: ctype"
fi
if ! php -m | grep -iq curl; then
    run_ok "apt install -y php$PHPVERSION-curl > /dev/null 2>&1 &" "Instalando extensión PHP: curl"
fi
if ! php -m | grep -iq dom; then
    run_ok "apt install -y php$PHPVERSION-dom > /dev/null 2>&1 &" "Instalando extensión PHP: dom"
fi
if ! php -m | grep -iq fileinfo; then
    run_ok "apt install -y php$PHPVERSION-fileinfo > /dev/null 2>&1 &" "Instalando extensión PHP: fileinfo"
fi
if ! php -m | grep -iq mbstring; then
    run_ok "apt install -y php$PHPVERSION-mbstring > /dev/null 2>&1 &" "Instalando extensión PHP: mbstring"
fi
if ! php -m | grep -iq openssl; then
    run_ok "apt install -y php$PHPVERSION-openssl > /dev/null 2>&1 &" "Instalando extensión PHP: openssl"
fi
if ! php -m | grep -iq pdo; then
    run_ok "apt install -y php$PHPVERSION-pdo > /dev/null 2>&1 &" "Instalando extensión PHP: pdo"
fi
if ! php -m | grep -iq tokenizer; then
    run_ok "apt install -y php$PHPVERSION-tokenizer > /dev/null 2>&1 &" "Instalando extensión PHP: tokenizer"
fi
if ! php -m | grep -iq xml; then
    run_ok "apt install -y php$PHPVERSION-xml > /dev/null 2>&1 &" "Instalando extensión PHP: xml"
fi
if ! php -m | grep -iq json; then
    run_ok "apt install -y php$PHPVERSION-json > /dev/null 2>&1 &" "Instalando extensión PHP: json"
fi
if ! php -m | grep -iq zip; then
    run_ok "apt install -y php$PHPVERSION-zip > /dev/null 2>&1 &" "Instalando extensión PHP: zip"
fi

# Extensiones PHP para bases de datos MySQL/MariaDB
if ! php -m | grep -iq mysqli; then
    run_ok "apt install -y php$PHPVERSION-mysqli > /dev/null 2>&1 &" "Instalando extensión PHP: mysqli"
fi
if ! php -m | grep -iq pdo_mysql; then
    run_ok "apt install -y php$PHPVERSION-mysql > /dev/null 2>&1 &" "Instalando extensión PHP: pdo_mysql"
fi

# Extensiones PHP adicionales para WordPress
if ! php -m | grep -iq gd; then
    run_ok "apt install -y php$PHPVERSION-gd > /dev/null 2>&1 &" "Instalando extensión PHP: gd"
fi
if ! php -m | grep -iq xmlrpc; then
    run_ok "apt install -y php$PHPVERSION-xmlrpc > /dev/null 2>&1 &" "Instalando extensión PHP: xmlrpc"
fi
if ! php -m | grep -iq exif; then
    run_ok "apt install -y php$PHPVERSION-exif > /dev/null 2>&1 &" "Instalando extensión PHP: exif"
fi
if ! php -m | grep -iq soap; then
    run_ok "apt install -y php$PHPVERSION-soap > /dev/null 2>&1 &" "Instalando extensión PHP: soap"
fi
if ! php -m | grep -iq gettext; then
    run_ok "apt install -y php$PHPVERSION-gettext > /dev/null 2>&1 &" "Instalando extensión PHP: gettext"
fi

# Validar si info.php existe en /var/www/html y crearlo si no existe (usando tee para evitar problemas de permisos)
if [[ ! -f /var/www/html/info.php ]]; then
    echo "<?php phpinfo(); ?>" | tee /var/www/html/info.php > /dev/null
    chmod 644 /var/www/html/info.php
fi

# Validar e instalar el servidor de base de datos si no está instalado
if ! dpkg -l | grep -qw "$DBSERVER"; then
    run_ok "apt install -y $DBSERVER > /dev/null 2>&1 &" "Instalando $DBSERVER"
fi

# Configurar usuarios en base de datos (silencioso, sin mostrar salida)
mysql -uroot > /dev/null 2>&1 <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${PHPROOT}';
FLUSH PRIVILEGES;
CREATE USER IF NOT EXISTS 'phpmyadmin'@'localhost' IDENTIFIED BY '${PHPADMIN}';
GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

if [[ $? -ne 0 ]]; then
    echo "Error: No se pudieron configurar los usuarios de base de datos."
    exit 1
fi


# Eliminar carpeta tmp y todo su contenido
rm -rf ./tmp

echo
echo "Fin de Instalación."

