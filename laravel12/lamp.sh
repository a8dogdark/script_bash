#!/bin/bash
clear

DBASE=""  # Asigna aquí la base de datos recomendada, por ejemplo: "MySQL"
DISTRO=""
PACKAGE=""
PASSADMIN=""
PASSROOT=""
PHPVERSION=""
PROYECTO=""
SOFTWARES=""
VER="2.0"
VERDIS=""

# Verificación de root
if [ "$EUID" -ne 0 ]; then
  echo "Este script debe ejecutarse como root. Usa 'sudo'."
  exit 1
fi

# Verificación de arquitectura 64 bits
if ! uname -m | grep -Eq "64|x86_64"; then
  echo "Se requiere una arquitectura de 64 bits. Detectado: $(uname -m)"
  exit 1
fi

# Detectar distribución y versión
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO="$ID"
  VERDIS="$VERSION_ID"
else
  echo "No se pudo detectar la distribución. Abortando."
  exit 1
fi

# Convertir DISTRO a minúsculas para comparación segura
DISTRO_LC=$(echo "$DISTRO" | tr '[:upper:]' '[:lower:]')

# Validar distribución y versión
if [[ "$DISTRO_LC" == "ubuntu" ]]; then
  if [[ "$VERDIS" != "22.04" && "$VERDIS" != "24.04" ]]; then
    echo "Solo se permite Ubuntu 22.04 o 24.04. Detectado: $VERDIS"
    exit 1
  fi
elif [[ "$DISTRO_LC" == "debian" ]]; then
  if [[ "$VERDIS" != "11" && "$VERDIS" != "12" ]]; then
    echo "Solo se permite Debian 11 o 12. Detectado: $VERDIS"
    exit 1
  fi
elif [[ "$DISTRO" == "AnduinOS" ]]; then
  if [[ "$VERDIS" != "1.1.7" ]]; then
    echo "Solo se permite AnduinOS versión 1.1.7. Detectado: $VERDIS"
    exit 1
  fi
else
  echo "Solo se permite Ubuntu, Debian o AnduinOS. Detectado: $DISTRO"
  exit 1
fi

# Verificar si whiptail está instalado
if ! command -v whiptail >/dev/null 2>&1; then
  if [[ "$DISTRO_LC" == "ubuntu" || "$DISTRO_LC" == "debian" || "$DISTRO" == "AnduinOS" ]]; then
    echo "Espere por favor ..."
    apt-get install -y whiptail >/dev/null 2>&1 &
  else
    echo "No se puede instalar whiptail automáticamente en esta distribución."
    exit 1
  fi
fi

# Mostrar cuadro de bienvenida con botones Aceptar y Cancelar
whiptail --backtitle "Instalador de Lamp para Laravel 12 - Versión: $VER" --title "Bienvenido" --yesno "Bienvenido a la Instalación del servidor LAMP para Laravel 12.\n\nSe instalarán los siguientes paquetes:\n- Apache\n- PHP\n- $DBASE (versión recomendada)\n- PhpMyAdmin" 15 60

RESPUESTA=$?

if [ $RESPUESTA -ne 0 ]; then
  whiptail --backtitle "Instalador de Lamp para Laravel 12 - Versión: $VER" --title "Instalación Cancelada" --msgbox "Has cancelado la instalación." 8 40
  exit 1
fi

echo "Comenzando la instalación..."
# Aquí seguiría el resto del script de instalación
