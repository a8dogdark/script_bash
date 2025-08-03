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

if [ "$EUID" -ne 0 ]; then
  echo "Este script debe ejecutarse como root. Usa 'sudo'."
  exit 1
fi

if ! uname -m | grep -Eq "64|x86_64"; then
  echo "Se requiere una arquitectura de 64 bits. Detectado: $(uname -m)"
  exit 1
fi

if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO="$NAME"
  VERDIS="$VERSION_ID"
else
  echo "No se pudo detectar la distribución. Abortando."
  exit 1
fi

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

whiptail --backtitle "Instalador de Lamp para Laravel 12 versión $VER" \
  --title "Bienvenido" \
  --msgbox "Bienvenido al instalador de Servidor Lamp para Laravel 12\n\nSe instalarán los siguientes paquetes:\n- Apache\n- PHP\n- Servidor de base de datos $DBASE\n- Phpmyadmin\n\nSoftwares a elección Proyecto Laravel 12" 18 70
