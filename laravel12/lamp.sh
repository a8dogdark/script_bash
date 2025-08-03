#!/bin/bash

clear

DBASE="" # Esta variable ahora almacenará la base de datos recomendada
DISTRO=""
PACKAGE=""
PACKAGES=""
PASSADMIN=""
PASSROOT=""
PHPVERSION=""
PROYECTO=""
SOFTWARES=""
VER="2.0"
VERDIS=""

if [ "$EUID" -ne 0 ]; then
  echo "Este script debe ejecutarse como root. Por favor, usa 'sudo'."
  exit 1
fi

if ! (uname -m | grep -q "64" || uname -m | grep -q "x86_64"); then
  echo "Este script requiere una distribución de 64 bits. Tu arquitectura es: $(uname -m)"
  exit 1
fi

# Detecta y guarda la distribución y su versión
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
    VERDIS=$VERSION_ID
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    DISTRO=$(echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]')
    VERDIS=$DISTRIB_RELEASE
elif [ -f /etc/debian_version ]; then
    DISTRO="debian"
    VERDIS=$(cat /etc/debian_version | cut -d'.' -f1)
elif [ -f /etc/redhat-release ]; then
    DISTRO=$(cat /etc/redhat-release | awk '{print tolower($1)}')
    VERDIS=$(cat /etc/redhat-release | sed 's/.*release //;s/ (.*)//')
else
    echo "Error: No se pudo detectar la distribución de Linux. Saliendo."
    exit 1
fi

if [ -z "$DISTRO" ] || [ -z "$VERDIS" ]; then
    echo "Error: No se pudo obtener la información completa de la distribución. Saliendo."
    exit 1
fi

# --- Validación de la distribución y versión soportada ---
case "$DISTRO" in
    ubuntu)
        if [ "$VERDIS" == "1.1.7" ]; then
            : # Válido: Es Anduinos 1.1.7 identificado como Ubuntu
        elif [ "$VERDIS" == "22.04" ] || [ "$VERDIS" == "24.04" ]; then
            : # Válido: Es Ubuntu LTS (22.04 o 24.04)
        else
            echo "Error: Distribución Ubuntu no soportada. Debe ser versión 22.04 (LTS), 24.04 (LTS) o Anduinos 1.1.7."
            exit 1
        fi
        PACKAGES="apt"
        DBASE="mysql-server" # Para Ubuntu/Anduinos, se asigna mysql-server a la variable
        ;;
    debian)
        if [ "$VERDIS" == "11" ] || [ "$VERDIS" == "12" ]; then
            : # Válido
        else
            echo "Error: Distribución Debian no soportada. Debe ser versión 11 o 12."
            exit 1
        fi
        PACKAGES="apt"
        DBASE="mariadb-server" # MariaDB es la opción preferida y por defecto en Debian
        ;;
    almalinux)
        if [ "$VERDIS" == "8" ] || [ "$VERDIS" == "9" ]; then
            : # Válido
        else
            echo "Error: Distribución AlmaLinux no soportada. Debe ser versión 8 o 9."
            exit 1
        fi
        if command -v dnf &> /dev/null; then
            PACKAGES="dnf"
        else
            PACKAGES="yum"
        fi
        DBASE="mariadb-server" # MariaDB es también la opción por defecto en AlmaLinux/RHEL
        ;;
    *) # Cualquier otra distribución
        echo "Error: Distribución '$DISTRO' con versión '$VERDIS' no soportada. Saliendo."
        exit 1
        ;;
esac

# --- Instalación de Whiptail ---
if ! command -v whiptail &> /dev/null; then
    if [ "$PACKAGES" == "apt" ]; then
        apt update && apt install -y whiptail
        if [ $? -ne 0 ]; then
            echo "Error: No se pudo instalar whiptail. Saliendo."
            exit 1
        else
            echo "Espere un momento por favor...."
        fi
    elif [ "$PACKAGES" == "yum" ] || [ "$PACKAGES" == "dnf" ]; then
        "$PACKAGES" install -y newt
        if [ $? -ne 0 ]; then
            echo "Error: No se pudo instalar whiptail. Saliendo."
            exit 1
        else
            echo "Espere un momento por favor...."
        fi
    else
        echo "Error: No se sabe cómo instalar whiptail en esta distribución ($DISTRO). Saliendo."
        exit 1
    fi
fi
