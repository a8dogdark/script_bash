#!/bin/bash

clear

# Versión del script
VERSO="2.0"

# Variables
DBASE=""
PHPADMIN=""
PHPROOT=""
PHPVER=""
PROYECTO=""
PACKAGE=""

# Validar si es root
if [[ $EUID -ne 0 ]]; then
  clear
  echo "Debes ser usuario root para ejecutar el programa."
  exit 1
fi

# Validar arquitectura 64 bits
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" ]]; then
  clear
  echo "Este script solo funciona en sistemas de 64 bits."
  exit 1
fi

# Obtener datos de la distro
source /etc/os-release

if [[ "$ID" == "ubuntu" && "$PRETTY_NAME" == *"AnduinOS"* ]]; then
  DISTRO="anduinos"
elif [[ "$ID" == "ubuntu" ]]; then
  DISTRO="ubuntu"
elif [[ "$ID" == "debian" ]]; then
  DISTRO="debian"
elif [[ "$ID" == "almalinux" ]]; then
  DISTRO="almalinux"
else
  echo "Sistema operativo no compatible."
  exit 1
fi

DISTROVER="$VERSION_ID"

case "$DISTRO" in
  ubuntu|anduinos)
    DBASE="mysql-server"
    PACKAGE="apt-get"
    ;;
  debian)
    if [[ ! "$DISTROVER" =~ ^(11|12)$ ]]; then
      echo "Debian soportado solo en versiones 11 o 12."
      exit 1
    fi
    DBASE="mariadb-server"
    PACKAGE="apt-get"
    ;;
  almalinux)
    if [[ ! "$DISTROVER" =~ ^(8|9)$ ]]; then
      echo "AlmaLinux soportado solo en versiones 8 o 9."
      exit 1
    fi
    DBASE="mariadb-server"
    PACKAGE="dnf"
    ;;
esac

# Instalar dialog si no está instalado (silencioso)
if ! command -v dialog &>/dev/null; then
  $PACKAGE install -y dialog &>/dev/null
fi

# Cuadro bienvenida
dialog --backtitle "Instalador Lamp Laravel 12" \
  --title "Instalador Lamp para Laravel 12 VER $VERSO" \
  --yesno "Bienvenido al instalador de Lamp para Laravel 12 en Linux. Se instalarán los siguientes paquetes:
- Apache
- PHP
- $DBASE
- PhpMyAdmin
- Composer
- NodeJS
- Proyecto Laravel 12

¿Deseas continuar?" 20 60

case $? in
  1|255)
    dialog --title "Cancelado" --msgbox "Has cancelado, saldremos de la instalación." 10 40
    clear
    exit 1
    ;;
esac

# Nombre del Proyecto Laravel
PROYECTO=$(dialog --backtitle "Instalador Lamp Laravel 12 - Script versión $VERSO" \
  --title "Nombre del Proyecto Laravel" \
  --inputbox "Ingrese el nombre del proyecto Laravel:" 10 50 "" 3>&1 1>&2 2>&3)

[[ -z "$PROYECTO" ]] && PROYECTO="crud"

# Passwords
PHPADMIN=$(dialog --backtitle "Instalador Lamp Laravel 12 - Script versión $VERSO" \
  --title "Contraseña phpmyadmin" \
  --insecure --passwordbox "Ingresa la contraseña para el usuario phpmyadmin:" 8 60 3>&1 1>&2 2>&3)

[[ -z "$PHPADMIN" ]] && { clear; echo "No se ingresó contraseña para phpMyAdmin. Saliendo."; exit 1; }

PHPROOT=$(dialog --backtitle "Instalador Lamp Laravel 12 - Script versión $VERSO" \
  --title "Contraseña root base de datos" \
  --insecure --passwordbox "Ingresa la contraseña para el usuario root de la base de datos:" 8 60 3>&1 1>&2 2>&3)

[[ -z "$PHPROOT" ]] && { clear; echo "No se ingresó contraseña para root de base de datos. Saliendo."; exit 1; }

# Versión PHP
PHPVER=$(dialog --backtitle "Instalador Lamp Laravel 12 - Script versión $VERSO" \
  --title "Versión de PHP" \
  --radiolist "Seleccione la versión de PHP recomendada para Laravel 12 (8.3):" 15 50 3 \
  8.2 "PHP 8.2" off \
  8.3 "PHP 8.3 (Recomendada)" on \
  8.4 "PHP 8.4" off 3>&1 1>&2 2>&3)

[[ -z "$PHPVER" ]] && PHPVER="8.3"

# PROGRESSBAR
{
echo "XXX"; echo "1"; echo "Actualizando sistema..."; echo "XXX"
$PACKAGE update -y &>/dev/null

echo "XXX"; echo "2"; echo "Actualizando paquetes..."; echo "XXX"
$PACKAGE upgrade -y &>/dev/null

if [[ "$PACKAGE" == "apt-get" ]] && ! grep -q ondrej /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
  add-apt-repository ppa:ondrej/php -y &>/dev/null
  $PACKAGE update -y &>/dev/null
fi

echo "XXX"; echo "3"; echo "Instalando wget..."; echo "XXX"
$PACKAGE install -y wget &>/dev/null

echo "XXX"; echo "4"; echo "Instalando unzip..."; echo "XXX"
$PACKAGE install -y unzip &>/dev/null

echo "XXX"; echo "5"; echo "Instalando zip..."; echo "XXX"
$PACKAGE install -y zip &>/dev/null

echo "XXX"; echo "6"; echo "Instalando gpg..."; echo "XXX"
$PACKAGE install -y gpg &>/dev/null

echo "XXX"; echo "7"; echo "Instalando git..."; echo "XXX"
$PACKAGE install -y git &>/dev/null

echo "XXX"; echo "8"; echo "Instalando Apache..."; echo "XXX"
$PACKAGE install -y apache2 &>/dev/null

echo "XXX"; echo "9"; echo "Habilitando mod_rewrite..."; echo "XXX"
a2enmod rewrite &>/dev/null
systemctl restart apache2 &>/dev/null

echo "XXX"; echo "10"; echo "Instalando PHP $PHPVER..."; echo "XXX"
$PACKAGE install -y php$PHPVER &>/dev/null

echo "XXX"; echo "11"; echo "Instalando php$PHPVER-cli..."; echo "XXX"
$PACKAGE install -y php$PHPVER-cli &>/dev/null

echo "XXX"; echo "12"; echo "Instalando php$PHPVER-common..."; echo "XXX"
$PACKAGE install -y php$PHPVER-common &>/dev/null

echo "XXX"; echo "13"; echo "Instalando php$PHPVER-mbstring..."; echo "XXX"
$PACKAGE install -y php$PHPVER-mbstring &>/dev/null

echo "XXX"; echo "14"; echo "Instalando php$PHPVER-xml..."; echo "XXX"
$PACKAGE install -y php$PHPVER-xml &>/dev/null

echo "XXX"; echo "15"; echo "Instalando php$PHPVER-curl..."; echo "XXX"
$PACKAGE install -y php$PHPVER-curl &>/dev/null

echo "XXX"; echo "16"; echo "Instalando php$PHPVER-intl..."; echo "XXX"
$PACKAGE install -y php$PHPVER-intl &>/dev/null

echo "XXX"; echo "17"; echo "Instalando php$PHPVER-mysql..."; echo "XXX"
$PACKAGE install -y php$PHPVER-mysql &>/dev/null

echo "XXX"; echo "18"; echo "Instalando php$PHPVER-zip..."; echo "XXX"
$PACKAGE install -y php$PHPVER-zip &>/dev/null

echo "XXX"; echo "19"; echo "Instalando php$PHPVER-bcmath..."; echo "XXX"
$PACKAGE install -y php$PHPVER-bcmath &>/dev/null

echo "XXX"; echo "20"; echo "Instalando php$PHPVER-tokenizer..."; echo "XXX"
$PACKAGE install -y php$PHPVER-tokenizer &>/dev/null

echo "XXX"; echo "21"; echo "Instalando php$PHPVER-fileinfo..."; echo "XXX"
$PACKAGE install -y php$PHPVER-fileinfo &>/dev/null

echo "XXX"; echo "22"; echo "Creando info.php..."; echo "XXX"
echo "<?php phpinfo(); ?>" > /var/www/html/info.php
chmod 644 /var/www/html/info.php

echo "XXX"; echo "23"; echo "Instalando $DBASE..."; echo "XXX"
$PACKAGE install -y $DBASE &>/dev/null

echo "XXX"; echo "24"; echo "Configurando usuarios base de datos..."; echo "XXX"
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$PHPROOT';
CREATE USER IF NOT EXISTS 'phpmyadmin'@'localhost' IDENTIFIED BY '$PHPADMIN';
GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

# Instalar phpMyAdmin siempre que no esté instalado
if ! command -v phpmyadmin &>/dev/null; then
  echo "XXX"; echo "25"; echo "Instalando phpMyAdmin..."; echo "XXX"
  echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPADMIN" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/mysql/admin-pass password $PHPROOT" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPADMIN" | debconf-set-selections
  echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
  $PACKAGE install -y phpmyadmin &>/dev/null
fi

# Instalar Composer si no existe
if ! command -v composer &>/dev/null; then
  echo "XXX"; echo "26"; echo "Instalando Composer..."; echo "XXX"
  EXPECTED_SIG=$(wget -q -O - https://composer.github.io/installer.sig)
  php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
  ACTUAL_SIG=$(php -r "echo hash_file('sha384', 'composer-setup.php');")
  if [[ "$EXPECTED_SIG" == "$ACTUAL_SIG" ]]; then
    php composer-setup.php --quiet
    mv composer.phar /usr/local/bin/composer
  fi
  rm composer-setup.php
fi

# Instalar Node.js LTS si no existe
if ! command -v node &>/dev/null; then
  echo "XXX"; echo "27"; echo "Instalando Node.js..."; echo "XXX"
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - &>/dev/null
  $PACKAGE install -y nodejs &>/dev/null
fi

echo "XXX"; echo "28"; echo "Creando carpeta /var/www/laravel y proyecto $PROYECTO..."; echo "XXX"
mkdir -p /var/www/laravel
cd /var/www/laravel || exit 1
if [[ ! -d "$PROYECTO" ]]; then
  composer create-project laravel/laravel "$PROYECTO" "12.*" --quiet
fi
cd "$PROYECTO" || exit 1
php artisan optimize:clear
npm install --silent
npm run build --silent

echo "XXX"; echo "29"; echo "Finalizando instalación..."; echo "XXX"
sleep 2

} | dialog --title "Progreso de instalación" --gauge "Por favor espere..." 10 70 0

dialog --backtitle "Instalador Lamp Laravel 12" --msgbox "Instalación completada exitosamente. Presiona OK para salir." 8 50

clear
echo "Instalación finalizada correctamente."
