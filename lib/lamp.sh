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


# Crear carpeta ./tmp si no existe
mkdir -p ./tmp

# Descargar archivo dentro de ./tmp
wget -q --https-only --no-check-certificate -O ./tmp/slib.sh "https://raw.githubusercontent.com/a8dogdark/script_bash/refs/heads/main/lib/slib.sh" > /dev/null 2>&1

# Verificar si la descarga fue exitosa
if [[ $? -ne 0 || ! -s ./tmp/slib.sh ]]; then
    echo "Error: no se pudo descargar correctamente el archivo slib.sh"
    exit 1
fi

# Crear carpeta ./tmp si no existe
mkdir -p ./tmp

# Descargar archivo dentro de ./tmp
wget -q --https-only --no-check-certificate -O ./tmp/slib.sh "https://raw.githubusercontent.com/a8dogdark/script_bash/refs/heads/main/lib/slib.sh" > /dev/null 2>&1

# Verificar si la descarga fue exitosa
if [[ $? -ne 0 || ! -s ./tmp/slib.sh ]]; then
    echo "Error: no se pudo descargar correctamente el archivo slib.sh"
    exit 1
fi

# Dar permisos de lectura y ejecución
chmod +x ./tmp/slib.sh

# Incluir el archivo en el script
source ./tmp/slib.sh



