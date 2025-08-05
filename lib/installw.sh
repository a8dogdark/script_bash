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
# Validar la distribución, versión y definir variables
# ---------------------------------------------------------
# Define la versión de la distribución una vez
DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')

if grep -qi 'AnduinOS' /etc/os-release; then
    if [[ "$DISVER" == "1.1" || "$DISVER" == "1.3" ]]; then
        DISTRO="AnduinOS"
        DBSERVER="mysql-server"
    else
        echo "Error: AnduinOS $DISVER no es una versión compatible. Se requiere 1.1.x o 1.3.x." 1>&2
        exit 1
    fi
elif grep -qi 'Ubuntu' /etc/os-release; then
    if [[ "$DISVER" == "22.04" || "$DISVER" == "24.04" ]]; then
        DISTRO="Ubuntu"
        DBSERVER="mysql-server"
    else
        echo "Error: Ubuntu $DISVER no es una versión compatible. Se requiere 22.04 o 24.04." 1>&2
        exit 1
    fi
elif grep -qi 'Debian' /etc/os-release; then
    if [[ "$DISVER" == "11" || "$DISVER" == "12" ]]; then
        DISTRO="Debian"
        DBSERVER="mariadb-server"
    else
        echo "Error: Debian $DISVER no es una versión compatible. Se requiere 11 o 12." 1>&2
        exit 1
    fi
else
    echo "Error: Este script solo puede ejecutarse en Ubuntu, Debian o AnduinOS." 1>&2
    exit 1
fi

# ---------------------------------------------------------
# Instalar whiptail si no está presente
# ---------------------------------------------------------
if ! command -v whiptail &> /dev/null; then
    apt install -y whiptail >/dev/null 2>&1
fi

# ---------------------------------------------------------
# Cuadro de bienvenida
# ---------------------------------------------------------
VER="2.0"

if (whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Bienvenido" --yesno "Este script instalará los componentes necesarios en su sistema $DISTRO $DISVER.\n\nEl servidor de base de datos a instalar será: $DBSERVER.\n\n¿Desea continuar con la instalación?" 12 70) then
    # El usuario seleccionó Aceptar, se continúa con la barra de progreso
    echo "" # Se agrega un salto de línea para separar la salida del whiptail
else
    # El usuario seleccionó Cancelar, se muestra un mensaje y se sale del script
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
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
