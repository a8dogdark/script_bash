#!/bin/bash

clear

# Validar si se ejecuta como root
if [[ "$EUID" -ne 0 ]]; then
    echo "Este script debe ejecutarse como root."
    exit 1
fi

# Validar arquitectura de 64 bits
if [[ "$(uname -m)" != "x86_64" && "$(uname -m)" != "aarch64" ]]; then
    echo "Este script solo puede ejecutarse en sistemas de 64 bits."
    exit 1
fi

# Validar que sea Ubuntu, Debian o AnduinOS, y definir DISTRO, DISVER y DBSERVER
if grep -qi 'AnduinOS' /etc/os-release; then
    DISTRO="AnduinOS"
    DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')
    DBSERVER="mysql-server"
elif grep -qi 'Ubuntu' /etc/os-release; then
    DISTRO="Ubuntu"
    DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')
    DBSERVER="mysql-server"
elif grep -qi 'Debian' /etc/os-release; then
    DISTRO="Debian"
    DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')
    DBSERVER="mariadb-server"
else
    echo "Este script solo puede ejecutarse en Ubuntu, Debian o AnduinOS."
    exit 1
fi

echo "*****************************************"
echo "* Bienvenido al isntalador de lamp      *"
echo "* Para Laravel 12 by Dogdark            *"
echo "* Se instalaran los siguientes paquetes *"
echo "*****************************************"
echo " "
echo "- Apache"
echo "- Php"
echo "- $DBSERVER"
echo "- Phpmyadmin"
echo "- Composer"
echo "- NodeJS"
echo "- Softwares"
echo "- Proyecto Laravel 12"

read -rp "Ingresa el nombre del proyecto Laravel a crear (sin guiones ni espacios, ejemplo: crud): " PROYECTO

# Si está vacío, usar valor por defecto
if [[ -z "$PROYECTO" ]]; then
    PROYECTO="crud"
fi

# Validar que no tenga espacios ni guiones
if [[ "$PROYECTO" =~ [-[:space:]] ]]; then
    echo "Error: el nombre no puede contener guiones ni espacios."
    exit 1
fi

read -rp "Ingresa la contraseña para el usuario phpMyAdmin: " PHPADMIN
if [[ -z "$PHPADMIN" ]]; then
    echo "Error: la contraseña de phpMyAdmin no puede estar vacía."
    exit 1
fi

read -rp "Ingresa la contraseña para el usuario root de la base de datos: " PHPROOT
if [[ -z "$PHPROOT" ]]; then
    echo "Error: la contraseña root no puede estar vacía."
    exit 1
fi

echo "Elige la versión de PHP a instalar (recomendada para Laravel 12: PHP 8.3):"
echo "1) PHP 8.2"
echo "2) PHP 8.3 (Recomendada)"
echo "3) PHP 8.4"

read -rp "Ingresa el número de la versión que deseas instalar: " PHPOPTION

case $PHPOPTION in
    1) PHPVERSION="8.2" ;;
    2) PHPVERSION="8.3" ;;
    3) PHPVERSION="8.4" ;;
    *)
        echo "Opción inválida. Saliendo."
        exit 1
        ;;
esac

echo
echo "Selecciona uno o varios softwares para instalar, separa con espacios:"
echo "1) Visual Studio Code"
echo "2) Brave"
echo "3) Google Chrome"
echo "4) FtpZilla"

read -rp "Ingresa los números de las opciones elegidas (ejemplo: 1 3 4): " -a SELECCIONES

# Array con los nombres
SOFTWARES=("Visual Studio Code" "Brave" "Google Chrome" "FtpZilla")

SOFTWARES_SELECCIONADOS=()

for num in "${SELECCIONES[@]}"; do
    if [[ "$num" =~ ^[1-4]$ ]]; then
        SOFTWARES_SELECCIONADOS+=("${SOFTWARES[$((num-1))]}")
    else
        echo "Opción inválida: $num. Saliendo."
        exit 1
    fi
done

echo
echo "Resumen de configuración:"
echo "-------------------------"
echo "Nombre del proyecto Laravel: $PROYECTO"
echo "Contraseña phpMyAdmin: $PHPADMIN"
echo "Contraseña root base de datos: $PHPROOT"
echo "Versión PHP seleccionada: PHP $PHPVERSION"
echo "Softwares seleccionados:"

if [ ${#SOFTWARES_SELECCIONADOS[@]} -eq 0 ]; then
    echo "  Ninguno"
else
    for software in "${SOFTWARES_SELECCIONADOS[@]}"; do
        echo "  - $software"
    done
fi

read -rp "¿Quieres continuar? [s/n]: " RESPUESTA

case "${RESPUESTA,,}" in  # convierte a minúscula
    s) 
        echo "Continuando..." 
        ;;
    *)
        echo "Instalación cancelada."
        exit 1
        ;;
esac

# Crear carpeta tmp solo si no existe
if [[ ! -d ./tmp ]]; then
    mkdir ./tmp
fi

# Descargar slib.sh solo si no existe o está vacío
if [[ ! -s ./tmp/slib.sh ]]; then
    wget -q --https-only --no-check-certificate -O ./tmp/slib.sh "https://raw.githubusercontent.com/a8dogdark/script_bash/refs/heads/main/lib/slib.sh" > /dev/null 2>&1
    if [[ $? -ne 0 || ! -s ./tmp/slib.sh ]]; then
        echo "Error: no se pudo descargar correctamente el archivo slib.sh"
        exit 1
    fi
    chmod +x ./tmp/slib.sh
fi

# Incluir slib.sh
source ./tmp/slib.sh



run_ok "" "Actualizando el equipo"
