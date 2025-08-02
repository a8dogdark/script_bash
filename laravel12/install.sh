#!/bin/bash

clear

# Versión del script
VERSO="2.0"

# Variables
DBASE=""
PHPADMIN=""
PHPROOT=""
PHPVER=""
OPSOFTWARE=()
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
- Softwares adicionales
- Proyecto Laravel 12

¿Deseas continuar?" 20 60

case $? in
  1|255)
    dialog --title "Cancelado" --msgbox "Has cancelado, saldremos de la instalación." 10 40
    clear
    exit 1
    ;;
esac

# Nombre del proyecto Laravel
PROYECTO=$(dialog --backtitle "Instalador Lamp Laravel 12 - Script versión $VERSO" \
  --title "Nombre del Proyecto Laravel" \
  --inputbox "Ingrese el nombre del proyecto Laravel:" 10 50 "" 3>&1 1>&2 2>&3)
[[ -z "$PROYECTO" ]] && PROYECTO="crud"

# Contraseñas
PHPADMIN=$(dialog --backtitle "Instalador Lamp Laravel 12 - Script versión $VERSO" \
  --title "Contraseña phpmyadmin" \
  --insecure --passwordbox "Ingresa la contraseña para el usuario phpmyadmin:" 8 60 3>&1 1>&2 2>&3)
[[ -z "$PHPADMIN" ]] && { clear; echo "No se ingresó contraseña para phpMyAdmin. Saliendo."; exit 1; }

PHPROOT=$(dialog --backtitle "Instalador Lamp Laravel 12 - Script versión $VERSO" \
  --title "Contraseña root base de datos" \
  --insecure --passwordbox "Ingresa la contraseña para el usuario root de la base de datos:" 8 60 3>&1 1>&2 2>&3)
[[ -z "$PHPROOT" ]] && { clear; echo "No se ingresó contraseña para root de base de datos. Saliendo."; exit 1; }

# Versión de PHP
PHPVER=$(dialog --backtitle "Instalador Lamp Laravel 12 - Script versión $VERSO" \
  --title "Versión de PHP" \
  --radiolist "Seleccione la versión de PHP recomendada para Laravel 12 (8.4):" 15 50 3 \
  8.2 "PHP 8.2" off \
  8.3 "PHP 8.3" off \
  8.4 "PHP 8.4 (Recomendada)" on 3>&1 1>&2 2>&3)
[[ -z "$PHPVER" ]] && PHPVER="8.4"

# Software adicional
OPSOFTWARE=$(dialog --backtitle "Instalador Lamp Laravel 12 - Script versión $VERSO" \
  --title "Seleccionar Softwares Adicionales" \
  --checklist "Seleccione los softwares que desea instalar (espacio para marcar):" 15 50 4 \
  "vscode" "Visual Studio Code" off \
  "brave" "Brave" off \
  "chrome" "Google Chrome" off \
  "ftpzilla" "FileZilla" off 3>&1 1>&2 2>&3)
[[ $? -ne 0 ]] && { clear; echo "Cancelado por el usuario."; exit 1; }

# Barra de progreso
{
  echo "XXX"; echo 1; echo "Actualizando sistema..."; echo "XXX"
  $PACKAGE update -y &>/dev/null

  echo "XXX"; echo 5; echo "Actualizando paquetes..."; echo "XXX"
  $PACKAGE upgrade -y &>/dev/null

  if [[ "$PACKAGE" == "apt-get" ]]; then
    echo "XXX"; echo 10; echo "Agregando repositorio de Ondrej si no existe..."; echo "XXX"
    add-apt-repository -y ppa:ondrej/php &>/dev/null
    $PACKAGE update -y &>/dev/null
  fi

  echo "XXX"; echo 15; echo "Instalando wget..."; echo "XXX"
  command -v wget &>/dev/null || $PACKAGE install -y wget &>/dev/null

  echo "XXX"; echo 20; echo "Instalando unzip..."; echo "XXX"
  command -v unzip &>/dev/null || $PACKAGE install -y unzip &>/dev/null

  echo "XXX"; echo 25; echo "Instalando zip..."; echo "XXX"
  command -v zip &>/dev/null || $PACKAGE install -y zip &>/dev/null

  echo "XXX"; echo 30; echo "Instalando gpg..."; echo "XXX"
  command -v gpg &>/dev/null || $PACKAGE install -y gpg &>/dev/null

  echo "XXX"; echo 35; echo "Instalando git..."; echo "XXX"
  command -v git &>/dev/null || $PACKAGE install -y git &>/dev/null

  echo "XXX"; echo 40; echo "Actualizando sistema nuevamente..."; echo "XXX"
  $PACKAGE update -y &>/dev/null

  echo "XXX"; echo 45; echo "Instalando Apache..."; echo "XXX"
  command -v apache2 &>/dev/null || $PACKAGE install -y apache2 &>/dev/null

  echo "XXX"; echo 50; echo "Activando módulo rewrite..."; echo "XXX"
  a2enmod rewrite &>/dev/null

  echo "XXX"; echo 55; echo "Instalando PHP $PHPVER..."; echo "XXX"
  $PACKAGE install -y php$PHPVER &>/dev/null

  echo "XXX"; echo 60; echo "Instalando extensión php-cli..."; echo "XXX"
  $PACKAGE install -y php$PHPVER-cli &>/dev/null

  echo "XXX"; echo 63; echo "Instalando php-mbstring..."; echo "XXX"
  $PACKAGE install -y php$PHPVER-mbstring &>/dev/null

  echo "XXX"; echo 66; echo "Instalando php-tokenizer..."; echo "XXX"
  $PACKAGE install -y php$PHPVER-tokenizer &>/dev/null

  echo "XXX"; echo 69; echo "Instalando php-xml..."; echo "XXX"
  $PACKAGE install -y php$PHPVER-xml &>/dev/null

  echo "XXX"; echo 72; echo "Instalando php-curl..."; echo "XXX"
  $PACKAGE install -y php$PHPVER-curl &>/dev/null

  echo "XXX"; echo 75; echo "Instalando php-zip..."; echo "XXX"
  $PACKAGE install -y php$PHPVER-zip &>/dev/null

  echo "XXX"; echo 78; echo "Instalando php-bcmath..."; echo "XXX"
  $PACKAGE install -y php$PHPVER-bcmath &>/dev/null

  echo "XXX"; echo 81; echo "Instalando php-mysql..."; echo "XXX"
  $PACKAGE install -y php$PHPVER-mysql &>/dev/null

  echo "XXX"; echo 84; echo "Creando info.php..."; echo "XXX"
  echo "<?php phpinfo(); ?>" > /var/www/html/info.php
  chmod 644 /var/www/html/info.php

  echo "XXX"; echo 87; echo "Instalando $DBASE..."; echo "XXX"
  $PACKAGE install -y $DBASE &>/dev/null

  echo "XXX"; echo 90; echo "Configurando base de datos..."; echo "XXX"
  if command -v mysql &>/dev/null; then
    mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$PHPROOT';
CREATE USER IF NOT EXISTS 'phpmyadmin'@'localhost' IDENTIFIED BY '$PHPADMIN';
GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost';
FLUSH PRIVILEGES;
EOF
  fi

  echo "XXX"; echo 94; echo "Instalando PhpMyAdmin..."; echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    [[ -d /usr/share/phpmyadmin ]] || $PACKAGE install -y phpmyadmin &>/dev/null
    ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin &>/dev/null
  elif [[ "$PACKAGE" == "dnf" ]]; then
    [[ -d /usr/share/phpMyAdmin ]] || $PACKAGE install -y phpmyadmin &>/dev/null
    ln -s /usr/share/phpMyAdmin /var/www/html/phpmyadmin &>/dev/null
  fi

  echo "XXX"; echo 98; echo "Reiniciando Apache..."; echo "XXX"
  systemctl restart apache2 &>/dev/null || systemctl restart httpd &>/dev/null

  echo "XXX"; echo 99; echo "Finalizando instalación..."; echo "XXX"
  sleep 1

} | dialog --title "Progreso de instalación" --gauge "Por favor espere..." 10 70 0

clear
echo "Instalación completada con éxito. Accede a:"
echo "  http://localhost/info.php"
echo "  http://localhost/phpmyadmin"
