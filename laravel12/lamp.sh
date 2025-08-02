#!/bin/bash
clear

# Versión del script
VER="2.0"
PASSADMIN=""
PASSROOT=""
SOFTWARES=""
PHPVERSION=""
DBASE="mysql-server"
PACKAGE=""
PROYECTO=""

# Verificar root
if [[ "$EUID" -ne 0 ]]; then
  echo "Este script debe ejecutarse como root. Abortando."
  exit 1
fi

# Verificar arquitectura 64 bits
if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "Este script solo puede ejecutarse en sistemas de 64 bits. Abortando."
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
elif [[ "$ID" == "centos" ]]; then
  DISTRO="centos"
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
      echo "Debian soportado solo en versiones 11 o 12. Abortando."
      exit 1
    fi
    DBASE="mariadb-server"
    PACKAGE="apt-get"
    ;;
  almalinux|centos)
    if [[ ! "$DISTROVER" =~ ^(8|9)$ ]]; then
      echo "$DISTRO soportado solo en versiones 8 o 9. Abortando."
      exit 1
    fi
    DBASE="mariadb-server"
    PACKAGE="dnf"
    ;;
esac

# Instalar dialog si no está presente (modo silencioso y sin confirmación)
if ! command -v dialog >/dev/null 2>&1; then
  echo "Espere un momento por favor..."
  $PACKAGE install -y dialog >/dev/null 2>&1
fi

# Cuadro de bienvenida personalizado mostrando el valor real de DBASE
dialog --title "Bienvenido" \
--yes-label "Aceptar" \
--no-label "Cancelar" \
--yesno "Bienvenido al instalador de Lamp para Laravel 12.\n\nSe instalarán los siguientes paquetes:\n\n- Apache\n- PHP\n- $DBASE\n- PhpMyAdmin\n- Composer\n- NodeJs\n- Softwares\n- Proyecto Laravel 12" 18 60

if [[ $? -ne 0 ]]; then
  dialog --title "Operación cancelada" --msgbox "Ha cancelado la operación. El instalador se cerrará." 7 50
  clear
  exit 1
fi

# Capturar nombre del proyecto (sin variable extra para el código de salida)
PROYECTO=$(dialog --title "Nombre del proyecto" --inputbox "Ingrese el nombre del proyecto:" 8 50 3>&1 1>&2 2>&3)
if [[ $? -ne 0 ]]; then
  dialog --title "Operación cancelada" --msgbox "Ha cancelado la operación. El instalador se cerrará." 7 50
  clear
  exit 1
fi

if [[ -z "$PROYECTO" ]]; then
  PROYECTO="crud"
fi

# Capturar password de usuario phpMyAdmin (oculto)
PASSADMIN=$(dialog --title "Contraseña phpMyAdmin" --insecure --passwordbox "Ingrese la contraseña para el usuario phpMyAdmin:" 8 50 3>&1 1>&2 2>&3)
if [[ $? -ne 0 ]]; then
  dialog --title "Operación cancelada" --msgbox "Ha cancelado la operación. El instalador se cerrará." 7 50
  clear
  exit 1
fi
