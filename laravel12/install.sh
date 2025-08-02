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
APACHE_HTML_DIR=""

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
    APACHE_HTML_DIR="/var/www/html"
    ;;
  debian)
    if [[ ! "$DISTROVER" =~ ^(11|12)$ ]]; then
      echo "Debian soportado solo en versiones 11 o 12."
      exit 1
    fi
    DBASE="mariadb-server"
    PACKAGE="apt-get"
    APACHE_HTML_DIR="/var/www/html"
    ;;
  almalinux)
    if [[ ! "$DISTROVER" =~ ^(8|9)$ ]]; then
      echo "AlmaLinux soportado solo en versiones 8 o 9."
      exit 1
    fi
    DBASE="mariadb-server"
    PACKAGE="dnf"
    APACHE_HTML_DIR="/var/www/html"
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

# Inputbox para nombre del proyecto Laravel (campo en blanco)
PROYECTO=$(dialog --backtitle "Instalador Lamp Laravel 12 - Script versión $VERSO" \
  --title "Nombre del Proyecto Laravel" \
  --inputbox "Ingrese el nombre del proyecto Laravel:" 10 50 "" 3>&1 1>&2 2>&3)

if [[ -z "$PROYECTO" ]]; then
  PROYECTO="crud"
fi

# Inputbox para password phpmyadmin
PHPADMIN=$(dialog --backtitle "Instalador Lamp Laravel 12 - Script versión $VERSO" \
  --title "Contraseña phpmyadmin" \
  --insecure --passwordbox "Ingresa la contraseña para el usuario phpmyadmin:" 8 60 3>&1 1>&2 2>&3)

if [[ -z "$PHPADMIN" ]]; then
  clear
  echo "No se ingresó contraseña para phpMyAdmin. Saliendo."
  exit 1
fi

# Inputbox para password root base de datos
PHPROOT=$(dialog --backtitle "Instalador Lamp Laravel 12 - Script versión $VERSO" \
  --title "Contraseña root base de datos" \
  --insecure --passwordbox "Ingresa la contraseña para el usuario root de la base de datos:" 8 60 3>&1 1>&2 2>&3)

if [[ -z "$PHPROOT" ]]; then
  clear
  echo "No se ingresó contraseña para root de base de datos. Saliendo."
  exit 1
fi

# Selección versión PHP (con opción recomendada preseleccionada)
PHPVER=$(dialog --backtitle "Instalador Lamp Laravel 12 - Script versión $VERSO" \
  --title "Versión de PHP" \
  --radiolist "Seleccione la versión de PHP recomendada para Laravel 12 (8.4):" 15 50 3 \
  8.2 "PHP 8.2" off \
  8.3 "PHP 8.3" off \
  8.4 "PHP 8.4 (Recomendada)" on 3>&1 1>&2 2>&3)

if [[ -z "$PHPVER" ]]; then
  PHPVER="8.4"
fi

if [[ $? -ne 0 ]]; then
  clear
  echo "Cancelado por el usuario. Saliendo."
  exit 1
fi

# Cuadro para seleccionar softwares adicionales (multi-selección)
OPSOFTWARE=$(dialog --backtitle "Instalador Lamp Laravel 12 - Script versión $VERSO" \
  --title "Seleccionar Softwares Adicionales" \
  --checklist "Seleccione los softwares que desea instalar (espacio para marcar):" 15 50 4 \
  "vscode" "Visual Studio Code" off \
  "brave" "Brave" off \
  "chrome" "Google Chrome" off \
  "ftpzilla" "FileZilla" off 3>&1 1>&2 2>&3)

if [[ $? -ne 0 ]]; then
  clear
  echo "Cancelado por el usuario. Saliendo."
  exit 1
fi

IFS=' ' read -r -a OPSOFTWARE <<< "$OPSOFTWARE"

# Progressbar - Instalación paso a paso con porcentajes fijos y únicos entre 1 y 99

{
  echo "XXX"
  echo "1"
  echo "Actualizando lista de paquetes (update)..."
  echo "XXX"
  $PACKAGE update -y &>/dev/null
  sleep 1

  echo "XXX"
  echo "5"
  echo "Actualizando paquetes (upgrade)..."
  echo "XXX"
  $PACKAGE upgrade -y &>/dev/null
  sleep 1

  echo "XXX"
  echo "9"
  echo "Agregando repositorio ondrej/php si no existe..."
  echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    if ! grep -q "^deb .\+ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
      add-apt-repository -y ppa:ondrej/php &>/dev/null
      $PACKAGE update -y &>/dev/null
    fi
  fi
  sleep 1

  echo "XXX"
  echo "13"
  echo "Validando e instalando wget..."
  echo "XXX"
  if ! command -v wget &>/dev/null; then
    $PACKAGE install -y wget &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "17"
  echo "Validando e instalando unzip..."
  echo "XXX"
  if ! command -v unzip &>/dev/null; then
    $PACKAGE install -y unzip &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "21"
  echo "Validando e instalando zip..."
  echo "XXX"
  if ! command -v zip &>/dev/null; then
    $PACKAGE install -y zip &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "25"
  echo "Validando e instalando gpg..."
  echo "XXX"
  if ! command -v gpg &>/dev/null; then
    $PACKAGE install -y gnupg &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "29"
  echo "Validando e instalando git..."
  echo "XXX"
  if ! command -v git &>/dev/null; then
    $PACKAGE install -y git &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "33"
  echo "Actualizando lista de paquetes (update) después de git..."
  echo "XXX"
  $PACKAGE update -y &>/dev/null
  sleep 1

  echo "XXX"
  echo "37"
  echo "Validando e instalando Apache2..."
  echo "XXX"
  if ! command -v apache2 &>/dev/null && ! command -v httpd &>/dev/null; then
    $PACKAGE install -y apache2 &>/dev/null || $PACKAGE install -y httpd &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "41"
  echo "Validando módulo rewrite de Apache..."
  echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    a2enmod rewrite &>/dev/null
    systemctl restart apache2 &>/dev/null
  else
    systemctl restart httpd &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "45"
  echo "Instalando PHP $PHPVER..."
  echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    $PACKAGE install -y php$PHPVER &>/dev/null
  else
    $PACKAGE install -y php &>/dev/null
  fi
  sleep 1

  # Extensiones PHP independientes cada una con porcentaje único

  echo "XXX"
  echo "49"
  echo "Instalando php$PHPVER-mbstring..."
  echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    $PACKAGE install -y php$PHPVER-mbstring &>/dev/null
  else
    $PACKAGE install -y php-mbstring &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "53"
  echo "Instalando php$PHPVER-xml..."
  echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    $PACKAGE install -y php$PHPVER-xml &>/dev/null
  else
    $PACKAGE install -y php-xml &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "57"
  echo "Instalando php$PHPVER-curl..."
  echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    $PACKAGE install -y php$PHPVER-curl &>/dev/null
  else
    $PACKAGE install -y php-curl &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "61"
  echo "Instalando php$PHPVER-mysql..."
  echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    $PACKAGE install -y php$PHPVER-mysql &>/dev/null
  else
    $PACKAGE install -y php-mysqlnd &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "65"
  echo "Instalando php$PHPVER-zip..."
  echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    $PACKAGE install -y php$PHPVER-zip &>/dev/null
  else
    $PACKAGE install -y php-zip &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "69"
  echo "Instalando php$PHPVER-bcmath..."
  echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    $PACKAGE install -y php$PHPVER-bcmath &>/dev/null
  else
    $PACKAGE install -y php-bcmath &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "73"
  echo "Instalando php$PHPVER-gd..."
  echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    $PACKAGE install -y php$PHPVER-gd &>/dev/null
  else
    $PACKAGE install -y php-gd &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "77"
  echo "Instalando php$PHPVER-tokenizer..."
  echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    $PACKAGE install -y php$PHPVER-tokenizer &>/dev/null
  else
    $PACKAGE install -y php-tokenizer &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "81"
  echo "Instalando php$PHPVER-fileinfo..."
  echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    $PACKAGE install -y php$PHPVER-fileinfo &>/dev/null
  else
    $PACKAGE install -y php-fileinfo &>/dev/null
  fi
  sleep 1

  echo "XXX"
  echo "85"
  echo "Instalando php$PHPVER-opcache..."
  echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    $PACKAGE install -y php$PHPVER-opcache &>/dev/null
  else
    $PACKAGE install -y php-opcache &>/dev/null
  fi
  sleep 1

  # Crear info.php para verificar PHP en navegador antes de instalar la base de datos
  echo "XXX"
  echo "89"
  echo "Creando archivo info.php para ver información PHP..."
  echo "XXX"
  echo "<?php phpinfo(); ?>" > "$APACHE_HTML_DIR/info.php"
  chmod 644 "$APACHE_HTML_DIR/info.php"
  sleep 1

  # Instalación de base de datos según distro
  echo "XXX"
  echo "93"
  echo "Instalando base de datos $DBASE..."
  echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    if ! dpkg -l | grep -qw "$DBASE"; then
      $PACKAGE install -y $DBASE &>/dev/null
    fi
  else
    if ! rpm -q $DBASE &>/dev/null; then
      $PACKAGE install -y $DBASE &>/dev/null
    fi
  fi
  sleep 1

} | dialog --title "Progreso de instalación" --gauge "Por favor espere..." 15 70 0

clear
echo "Instalación base completada. Continuaremos con los siguientes pasos..."
