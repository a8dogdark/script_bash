#!/bin/bash

#####################################
# Instalador de servidor Lamp para  #
# Laravel 12 y creador de proyectos #
#####################################

# se debe instalar como usuario root 
if [ "$EUID" -ne 0 ]; then
  echo "Este script debe ser ejecutado como root."
  exit 1
fi
# validamos que sea de 64 bits
if [ "$(uname -m)" != "x86_64" ]; then
  echo "Este script solo funciona en sistemas de 64 bits (x86_64)."
  exit 1
fi

# Carga datos del sistema operativo
. /etc/os-release

DISTRO=$ID
VERDISTRO=$VERSION_ID

if ! { { [ "$DISTRO" = "ubuntu" ] && { [ "$VERDISTRO" = "22.04" ] || [ "$VERDISTRO" = "24.04" ]; }; } || \
       { [ "$DISTRO" = "debian" ] && { [ "$VERDISTRO" = "11" ] || [ "$VERDISTRO" = "12" ]; }; } \
     }; then
  echo "Sistema no soportado. Solo Ubuntu 22.04, 24.04 o Debian 11, 12."
  exit 1
fi


read -rp "Ingrese el nombre del proyecto: " PROYECTO

if [ -z "$PROYECTO" ]; then
  echo "No ingresó un nombre de proyecto. Saliendo."
  exit 1
fi

echo "El nombre del proyecto es: $PROYECTO"
