#!/bin/bash

VERSION="2.0"
DISTRO=""
PASSPHP=""
PASSROOT=""
PROYECTO=""
DBASE=""

# Valida si el script se está ejecutando como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como root. Por favor, ejecuta con 'sudo bash $(basename "$0")'."
    exit 1
fi

# Este script instalará LAMP y las dependencias necesarias para Laravel 12.
# Está diseñado para ser ejecutado en Ubuntu 24 y es compatible con Ubuntu 23, 22, Debian 11, 12 y AlmaLinux.

# Parte 1: Instalación de Apache, MySQL y PHP
# Parte 2: Configuración de MySQL
# Parte 3: Instalación de Composer
# Parte 4: Instalación de Node.js y npm
# Parte 5: Configuración adicional y permisos
