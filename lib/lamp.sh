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

echo -n "Ingresa el nombre del proyecto Laravel a crear (sin guiones ni espacios, Esc para salir): "
read -rsn1 PROYECTO

if [[ -z "$PROYECTO" ]]; then
    # Si no escribió nada y presionó Enter (no letra)
    read -rp "" PROYECTO
    if [[ -z "$PROYECTO" ]]; then
        PROYECTO="crud"
    fi
elif [[ $PROYECTO == $'\e' ]]; then
    echo -e "\nSe presionó ESC. Saliendo de la instalación."
    exit 1
else
    # Si ingresó una letra, leer el resto de la línea (por si escribe más)
    read -r RESTO
    PROYECTO+="$RESTO"
fi






