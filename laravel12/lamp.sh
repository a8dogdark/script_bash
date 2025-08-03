#!/bin/bash

clear

# Variables
VER="2.0"
PROYECTO=""
PASSADMIN=""
PASSROOT=""
PHPVERSION=""
SOFTWARES=""
DBASE=""
PACKAGE=""
DISTRO=""
VERDIS=""

# Verificar root
if [[ "$EUID" -ne 0 ]]; then
  echo "Este script debe ejecutarse como root."
  exit 1
fi

# Verificar arquitectura
if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "Este script solo funciona en sistemas de 64 bits."
  exit 1
fi

# Detección de distribución
source /etc/os-release

if [[ "$ID" == "ubuntu" && "$PRETTY_NAME" == *"AnduinOS"* ]]; then
  DISTRO="anduinos"
elif [[ "$ID" == "ubuntu" ]]; then
  DISTRO="ubuntu"
elif [[ "$ID" == "debian" ]]; then
  DISTRO="debian"
elif [[ "$ID" == "almalinux" || "$ID" == "centos" ]]; then
  DISTRO="almalinux"
else
  echo "Distribución no compatible."
  exit 1
fi

VERDIS="$VERSION_ID"

case "$DISTRO" in
  ubuntu|anduinos)
    DBASE="mysql-server"
    PACKAGE="apt-get"
    ;;
  debian)
    if [[ ! "$VERDIS" =~ ^(11|12)$ ]]; then
      echo "Debian soportado solo en versiones 11 o 12."
      exit 1
    fi
    DBASE="mariadb-server"
    PACKAGE="apt-get"
    ;;
  almalinux)
    if [[ ! "$VERDIS" =~ ^(8|9)$ ]]; then
      echo "AlmaLinux/CentOS soportado solo en versiones 8 o 9."
      exit 1
    fi
    DBASE="mariadb-server"
    PACKAGE="dnf"
    ;;
esac

# Instalar whiptail si no está presente
if ! command -v whiptail &>/dev/null; then
  echo "Instalando whiptail..."
  $PACKAGE install -y whiptail >/dev/null 2>&1
fi

# Bienvenida
whiptail --title "Bienvenido" --yesno \
"Bienvenido al instalador de Lamp para Laravel 12.

Se instalarán los siguientes paquetes:

Apache
PHP
Base de datos: $DBASE
PhpMyAdmin
Composer
NodeJS
Softwares adicionales
Proyecto Laravel 12" \
20 70

if [[ $? -ne 0 ]]; then
  whiptail --title "Cancelado" --msgbox "El usuario canceló la operación." 8 50
  exit 1
fi

# Nombre del proyecto
PROYECTO=$(whiptail --title "Nombre del proyecto" --inputbox \
"Ingrese el nombre del proyecto Laravel:" 10 60 3>&1 1>&2 2>&3)

if [[ $? -ne 0 ]]; then
  whiptail --title "Cancelado" --msgbox "El usuario canceló la operación." 8 50
  exit 1
fi

if [[ -z "$PROYECTO" ]]; then
  PROYECTO="crud"
fi

# Contraseña phpmyadmin
PASSADMIN=$(whiptail --title "Contraseña phpmyadmin" --passwordbox \
"Ingrese la contraseña para el usuario phpmyadmin (no puede estar vacía):" 10 60 3>&1 1>&2 2>&3)

if [[ $? -ne 0 || -z "$PASSADMIN" ]]; then
  whiptail --title "Cancelado" --msgbox "La contraseña no puede estar vacía o se canceló la operación." 8 60
  exit 1
fi

# Contraseña root DB
PASSROOT=$(whiptail --title "Contraseña root MySQL" --passwordbox \
"Ingrese la contraseña para el usuario root de la base de datos:" 10 60 3>&1 1>&2 2>&3)

if [[ $? -ne 0 || -z "$PASSROOT" ]]; then
  whiptail --title "Cancelado" --msgbox "La contraseña no puede estar vacía o se canceló la operación." 8 60
  exit 1
fi

# Versión de PHP
PHPVERSION=$(whiptail --title "Versión de PHP" --radiolist \
"Selecciona la versión de PHP para instalar (Laravel 12 soporta 8.2–8.4):" 15 70 3 \
"8.2" "PHP 8.2 (mínimo soportado)" OFF \
"8.3" "PHP 8.3 (recomendada para Laravel 12)" ON \
"8.4" "PHP 8.4 (requiere validación de compatibilidad)" OFF \
3>&1 1>&2 2>&3)

if [[ $? -ne 0 ]]; then
  whiptail --title "Cancelado" --msgbox "El usuario canceló la operación." 8 50
  exit 1
fi

# Check de softwares
SOFTWARES=$(whiptail --title "Softwares adicionales" --checklist \
"Seleccione los softwares adicionales a instalar:" 15 60 4 \
"VisualStudioCode" "Editor Visual Studio Code" OFF \
"FileZilla" "Cliente FTP FileZilla" OFF \
"Brave" "Navegador Brave" OFF \
"GoogleChrome" "Navegador Google Chrome" OFF \
3>&1 1>&2 2>&3)

if [[ $? -ne 0 ]]; then
  whiptail --title "Cancelado" --msgbox "El usuario canceló la operación." 8 50
  exit 1
fi

# Progreso de instalación con manejo de repositorios según distro
{
  echo "XXX"; echo "1"; echo "Actualizando sistema..."; echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    $PACKAGE update -y >/dev/null 2>&1
  elif [[ "$PACKAGE" == "dnf" ]]; then
    $PACKAGE makecache -y >/dev/null 2>&1
  fi
  sleep 1

  echo "XXX"; echo "3"; echo "Actualizando paquetes..."; echo "XXX"
  if [[ "$PACKAGE" == "apt-get" ]]; then
    $PACKAGE upgrade -y >/dev/null 2>&1
  elif [[ "$PACKAGE" == "dnf" ]]; then
    $PACKAGE upgrade -y >/dev/null 2>&1
  fi
  sleep 1

  if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "anduinos" ]]; then
    echo "XXX"; echo "5"; echo "Verificando repositorio ondrej/php..."; echo "XXX"
    if ! grep -Rq "^deb .*\bondrej/php\b" /etc/apt/sources.list /etc/apt/sources.list.d/ >/dev/null 2>&1; then
      $PACKAGE install -y software-properties-common >/dev/null 2>&1
      add-apt-repository -y ppa:ondrej/php >/dev/null 2>&1
      $PACKAGE update -y >/dev/null 2>&1
    fi
    sleep 1
  elif [[ "$DISTRO" == "almalinux" ]]; then
    echo "XXX"; echo "5"; echo "Configurando repositorio Remi para PHP..."; echo "XXX"
    if ! rpm -q remi-release >/dev/null 2>&1; then
      $PACKAGE install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm >/dev/null 2>&1
    fi
    $PACKAGE module reset php -y >/dev/null 2>&1
    $PACKAGE module enable php:remi-8.4 -y >/dev/null 2>&1
    $PACKAGE update -y >/dev/null 2>&1
    sleep 1
  fi

  echo "XXX"; echo "10"; echo "Verificando Apache..."; echo "XXX"
  if ! command -v apache2 >/dev/null 2>&1 && ! command -v httpd >/dev/null 2>&1; then
    if [[ "$PACKAGE" == "apt-get" ]]; then
      $PACKAGE install -y apache2 >/dev/null 2>&1
    else
      $PACKAGE install -y httpd >/dev/null 2>&1
    fi
  fi
  sleep 1

  echo "XXX"; echo "15"; echo "Verificando módulo rewrite de Apache..."; echo "XXX"
  if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" || "$DISTRO" == "anduinos" ]]; then
    if ! apache2ctl -M 2>/dev/null | grep -q rewrite_module; then
      a2enmod rewrite >/dev/null 2>&1
      systemctl restart apache2 >/dev/null 2>&1
    fi
  elif [[ "$DISTRO" == "almalinux" ]]; then
    if ! httpd -M 2>/dev/null | grep -q rewrite_module; then
      echo "El módulo rewrite debería estar habilitado en AlmaLinux por defecto. Si no, editar httpd.conf manualmente." >> /var/log/lamp_installer.log
    fi
    systemctl restart httpd >/dev/null 2>&1
  fi
  sleep 1

  echo "XXX"; echo "20"; echo "Verificando PHP versión $PHPVERSION..."; echo "XXX"
  if ! command -v php >/dev/null 2>&1 || [[ "$(php -r 'echo PHP_VERSION;')" != $PHPVERSION* ]]; then
    if [[ "$PACKAGE" == "apt-get" ]]; then
      $PACKAGE install -y php$PHPVERSION >/dev/null 2>&1
    elif [[ "$PACKAGE" == "dnf" ]]; then
      $PACKAGE install -y php$PHPVERSION >/dev/null 2>&1
    fi
  fi
  sleep 1

  echo "XXX"; echo "27"; echo "Verificando extensión PHP bcmath..."; echo "XXX"
  if ! php -m | grep -iq "^bcmath$"; then
    if [[ "$PACKAGE" == "apt-get" ]]; then
      $PACKAGE install -y php${PHPVERSION}-bcmath >/dev/null 2>&1
    else
      $PACKAGE install -y php-bcmath >/dev/null 2>&1
    fi
  fi
  sleep 1

  echo "XXX"; echo "34"; echo "Verificando extensión PHP ctype..."; echo "XXX"
  if ! php -m | grep -iq "^ctype$"; then
    if [[ "$PACKAGE" == "apt-get" ]]; then
      $PACKAGE install -y php${PHPVERSION}-ctype >/dev/null 2>&1
    else
      $PACKAGE install -y php-ctype >/dev/null 2>&1
    fi
  fi
  sleep 1

  echo "XXX"; echo "41"; echo "Verificando extensión PHP fileinfo..."; echo "XXX"
  if ! php -m | grep -iq "^fileinfo$"; then
    if [[ "$PACKAGE" == "apt-get" ]]; then
      $PACKAGE install -y php${PHPVERSION}-fileinfo >/dev/null 2>&1
    else
      $PACKAGE install -y php-fileinfo >/dev/null 2>&1
    fi
  fi
  sleep 1

  echo "XXX"; echo "48"; echo "Verificando extensión PHP json..."; echo "XXX"
  if ! php -m | grep -iq "^json$"; then
    if [[ "$PACKAGE" == "apt-get" ]]; then
      $PACKAGE install -y php${PHPVERSION}-json >/dev/null 2>&1
    else
      $PACKAGE install -y php-json >/dev/null 2>&1
    fi
  fi
  sleep 1

  echo "XXX"; echo "55"; echo "Verificando extensión PHP mbstring..."; echo "XXX"
  if ! php -m | grep -iq "^mbstring$"; then
    if [[ "$PACKAGE" == "apt-get" ]]; then
      $PACKAGE install -y php${PHPVERSION}-mbstring >/dev/null 2>&1
    else
      $PACKAGE install -y php-mbstring >/dev/null 2>&1
    fi
  fi
  sleep 1

  echo "XXX"; echo "62"; echo "Verificando extensión PHP openssl..."; echo "XXX"
  if ! php -m | grep -iq "^openssl$"; then
    if [[ "$PACKAGE" == "apt-get" ]]; then
      $PACKAGE install -y php${PHPVERSION}-openssl >/dev/null 2>&1
    else
      $PACKAGE install -y php-openssl >/dev/null 2>&1
    fi
  fi
  sleep 1

  echo "XXX"; echo "69"; echo "Verificando extensión PHP pdo..."; echo "XXX"
  if ! php -m | grep -iq "^pdo$"; then
    if [[ "$PACKAGE" == "apt-get" ]]; then
      $PACKAGE install -y php${PHPVERSION}-pdo >/dev/null 2>&1
    else
      $PACKAGE install -y php-pdo >/dev/null 2>&1
    fi
  fi
  sleep 1

  echo "XXX"; echo "76"; echo "Verificando extensión PHP tokenizer..."; echo "XXX"
  if ! php -m | grep -iq "^tokenizer$"; then
    if [[ "$PACKAGE" == "apt-get" ]]; then
      $PACKAGE install -y php${PHPVERSION}-tokenizer >/dev/null 2>&1
    else
      $PACKAGE install -y php-tokenizer >/dev/null 2>&1
    fi
  fi
  sleep 1

  echo "XXX"; echo "83"; echo "Verificando extensión PHP xml..."; echo "XXX"
  if ! php -m | grep -iq "^xml$"; then
    if [[ "$PACKAGE" == "apt-get" ]]; then
      $PACKAGE install -y php${PHPVERSION}-xml >/dev/null 2>&1
    else
      $PACKAGE install -y php-xml >/dev/null 2>&1
    fi
  fi
  sleep 1

  echo "XXX"; echo "90"; echo "Verificando extensión PHP zip..."; echo "XXX"
  if ! php -m | grep -iq "^zip$"; then
    if [[ "$PACKAGE" == "apt-get" ]]; then
      $PACKAGE install -y php${PHPVERSION}-zip >/dev/null 2>&1
    else
      $PACKAGE install -y php-zip >/dev/null 2>&1
    fi
  fi
  sleep 1

  if command -v apache2 >/dev/null 2>&1 || command -v httpd >/dev/null 2>&1; then
  if [[ ! -f "$APACHE_ROOT/info.php" ]]; then
    echo "<?php phpinfo(); ?>" > "$APACHE_ROOT/info.php"
    chown $APACHE_USER:$APACHE_GROUP "$APACHE_ROOT/info.php"
    chmod 644 "$APACHE_ROOT/info.php"
  fi
fi

  echo "XXX"; echo "100"; echo "Instalación finalizada"; echo "XXX"
  sleep 2
} | whiptail --title "Progreso de instalación" --gauge "Por favor espere..." 10 70 0
