#!/bin/bash

# =========================================================
# Script de instalación para Ubuntu/Debian/AnduinOS (64 bits)
# =========================================================

# ---------------------------------------------------------
# Validar si se ejecuta como root
# ---------------------------------------------------------
if [[ "$EUID" -ne 0 ]]; then
    echo "Error: Este script debe ser ejecutado como usuario root." 1>&2
    exit 1
fi

# ---------------------------------------------------------
# Validar si el sistema es de 64 bits
# ---------------------------------------------------------
if [[ "$(uname -m)" != "x86_64" ]]; then
    echo "Error: Este script es solo para sistemas de 64 bits (x86_64)." 1>&2
    exit 1
fi

# ---------------------------------------------------------
# Validar la distribución y definir variables
# ---------------------------------------------------------
if grep -qi 'AnduinOS' /etc/os-release; then
    DISTRO="AnduinOS"
    DBSERVER="mysql-server"
elif grep -qi 'Ubuntu' /etc/os-release; then
    DISTRO="Ubuntu"
    DBSERVER="mysql-server"
elif grep -qi 'Debian' /etc/os-release; then
    DISTRO="Debian"
    DBSERVER="mariadb-server"
else
    echo "Error: Este script solo puede ejecutarse en Ubuntu, Debian o AnduinOS." 1>&2
    exit 1
fi

# Definir la versión de la distribución una vez
DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')

# ---------------------------------------------------------
# Instalar whiptail si no está presente
# ---------------------------------------------------------
if ! command -v whiptail &> /dev/null; then
    apt install -y whiptail >/dev/null 2>&1
fi

# ---------------------------------------------------------
# Barra de progreso con whiptail
# ---------------------------------------------------------
(
    # Paso 1: Acción de instalación (0-20%)
    echo "XXX"
    echo "10"
    echo "Ejecutando el primer paso..."
    echo "XXX"
    # Aquí puedes añadir tu primer comando

    # Paso 2: Acción de instalación (20-60%)
    echo "XXX"
    echo "40"
    echo "Ejecutando el segundo paso..."
    echo "XXX"
    # Aquí puedes añadir tu segundo comando

    # Paso 3: Acción de instalación (60-90%)
    echo "XXX"
    echo "75"
    echo "Ejecutando el tercer paso..."
    echo "XXX"
    # Aquí puedes añadir tu tercer comando

    # Paso 4: Finalizar y limpiar (90-100%)
    echo "XXX"
    echo "95"
    echo "Finalizando la instalación..."
    echo "XXX"
    # Aquí puedes añadir tu comando final
    
    # Finalización
    echo "XXX"
    echo "100"
    echo "Instalación completada."
    echo "XXX"

) | whiptail --title "Instalador de componentes" --gauge "Iniciando la instalación..." 6 60 0

exit 0
