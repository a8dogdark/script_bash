#!/bin/bash

clear

DBASE=""
DISTRO=""
VERDIS=""
PACKAGE=""
PASSADMIN=""
PASSROOT=""
PHPVERSION=""
PROYECTO=""
SOFTWARES=""
VER="2.0"

# Validar ejecución como root
if [ "$EUID" -ne 0 ]; then
  echo "Este script debe ejecutarse como root. Usa 'sudo'."
  exit 1
fi

# Validar arquitectura 64 bits
if ! uname -m | grep -Eq "64|x86_64"; then
  echo "Se requiere una arquitectura de 64 bits. Detectado: $(uname -m)"
  exit 1
fi

# Detectar distro y versión
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO="$NAME"
  VERDIS="$VERSION_ID"
else
  echo "No se pudo detectar la distribución. Abortando."
  exit 1
fi

# Validar distro y asignar servidor base de datos
if [[ "$DISTRO" == "AnduinOS" && "$VERDIS" == "1.1.7" && "$ID" == "ubuntu" ]]; then
  DBASE="mysql-server"
elif [[ "$ID" == "ubuntu" ]]; then
  if [[ "$VERDIS" != "22.04" && "$VERDIS" != "24.04" ]]; then
    echo "Solo se permite Ubuntu 22.04 o 24.04. Detectado: $VERDIS"
    exit 1
  fi
  DBASE="mysql-server"
elif [[ "$ID" == "debian" ]]; then
  if [[ "$VERDIS" != "11" && "$VERDIS" != "12" ]]; then
    echo "Solo se permite Debian 11 o 12. Detectado: $VERDIS"
    exit 1
  fi
  DBASE="mariadb-server"
else
  echo "Solo se permite Ubuntu, Debian o AnduinOS 1.1.7. Detectado: $DISTRO"
  exit 1
fi

# Cuadro bienvenida con sí/no
if whiptail --backtitle "Instalador de Lamp para Laravel 12 version $VER" \
  --title "Bienvenido" \
  --yesno "Bienvenido al instalador de Servidor Lamp para Laravel 12\n\nSe instalaran los siguientes paquetes:\n- Apache\n- PHP\n- Servidor de base de datos $DBASE\n- Phpmyadmin\n- Softwares a elección\n- Proyecto Laravel 12\n\nPresiona Sí para continuar o No para cancelar." 20 70; then
    echo "Continuando con la instalación..."
else
  whiptail --backtitle "Instalador de Lamp para Laravel 12 version $VER" \
    --title "Cancelado" \
    --msgbox "Has cancelado la instalación." 8 50
  clear
  exit 1
fi

# Input nombre proyecto
PROYECTO=$(whiptail --backtitle "Instalador de Lamp para Laravel 12 version $VER" \
  --inputbox "Ingrese el nombre del proyecto (default: crud):" 10 60 3>&1 1>&2 2>&3)
if [ $? -ne 0 ]; then
  whiptail --backtitle "Instalador de Lamp para Laravel 12 version $VER" \
    --title "Cancelado" --msgbox "Instalación cancelada." 8 50
  clear
  exit 1
fi
if [ -z "$PROYECTO" ]; then
  PROYECTO="crud"
fi

# Input contraseña phpmyadmin
PASSADMIN=$(whiptail --backtitle "Instalador de Lamp para Laravel 12 version $VER" \
  --passwordbox "Ingrese la contraseña para el usuario phpmyadmin:" 10 60 3>&1 1>&2 2>&3)
if [ $? -ne 0 ] || [ -z "$PASSADMIN" ]; then
  whiptail --backtitle "Instalador de Lamp para Laravel 12 version $VER" \
    --title "Cancelado" --msgbox "Contraseña phpmyadmin vacía o cancelada. Instalación cancelada." 8 60
  clear
  exit 1
fi

# Input contraseña root
PASSROOT=$(whiptail --backtitle "Instalador de Lamp para Laravel 12 version $VER" \
  --passwordbox "Ingrese la contraseña para el usuario root de la base de datos:" 10 60 3>&1 1>&2 2>&3)
if [ $? -ne 0 ] || [ -z "$PASSROOT" ]; then
  whiptail --backtitle "Instalador de Lamp para Laravel 12 version $VER" \
    --title "Cancelado" --msgbox "Contraseña root vacía o cancelada. Instalación cancelada." 8 60
  clear
  exit 1
fi

# Progressbar estructura con porcentajes fijos entre 0 y 99, y 100 con mensaje final y espera 3s
{
  echo 10
  echo "Preparando instalación de Apache..."
  sleep 1

  echo 25
  echo "Preparando instalación de PHP..."
  sleep 1

  echo 40
  echo "Preparando instalación del servidor de base de datos $DBASE..."
  sleep 1

  echo 60
  echo "Preparando instalación de phpMyAdmin..."
  sleep 1

  echo 80
  echo "Preparando instalación de softwares adicionales..."
  sleep 1

  echo 99
  echo "Finalizando preparación..."
  sleep 1

  echo 100
  echo "Fin Instalación"
  sleep 3
} | whiptail --title "Progreso de instalación" --gauge "Por favor espere..." 10 70 0

clear
