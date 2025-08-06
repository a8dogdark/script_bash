#!/bin/bash

# =========================================================
# Script de instalación para Ubuntu/Debian/AnduinOS (64 bits)
# =========================================================

clear

# ---------------------------------------------------------
# Declaración de variables
# ---------------------------------------------------------
DBSERVER=""
DISTRO=""
PASSADMIN=""
PASSROOT=""
PHPUSER=""
PROYECTO=""
SOFTWARESUSER=""
VER="2.0"

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
MENSAJE_BIENVENIDA="Bienvenido al Instalador de Lamp para Laravel 12. Se instalarán los siguientes paquetes:\n\n- Apache\n- PHP\n- $DBSERVER\n- Phpmyadmin\n- Composer\n- NodeJs\n- Programas de Creación de proyecto\n\n¿Desea continuar con la instalación?"

if (whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Bienvenido" --yesno "$MENSAJE_BIENVENIDA" 16 70) then
    # El usuario seleccionó Aceptar, se continúa con la barra de progreso
    echo "" # Se agrega un salto de línea para separar la salida del whiptail
else
    # El usuario seleccionó Cancelar, se muestra un mensaje y se sale del script
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
fi

# ---------------------------------------------------------
# Solicitar el nombre del proyecto
# ---------------------------------------------------------
PROYECTO=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Nombre del Proyecto" --inputbox "Por favor, introduce el nombre de tu proyecto:\n(Si lo dejas en blanco, se usará 'crud' por defecto)" 10 60 "" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
fi

# Asignar valor por defecto si el campo se dejó en blanco
if [ -z "$PROYECTO" ]; then
    PROYECTO="crud"
fi

# ---------------------------------------------------------
# Solicitar la contraseña de Phpmyadmin
# ---------------------------------------------------------
PASSADMIN=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Contraseña de Phpmyadmin" --passwordbox "Por favor, introduce la contraseña para el usuario 'pma' de Phpmyadmin:\n(Si la dejas en blanco, se usará '12345' por defecto)" 10 70 "" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
fi

# Asignar valor por defecto si el campo se dejó en blanco
if [ -z "$PASSADMIN" ]; then
    PASSADMIN="12345"
fi

# ---------------------------------------------------------
# Solicitar la contraseña de Root de la base de datos
# ---------------------------------------------------------
PASSROOT=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Contraseña de Root para la Base de Datos" --passwordbox "Por favor, introduce la contraseña para el usuario 'root' de la base de datos:\n(Si la dejas en blanco, se usará '12345' por defecto)" 10 70 "" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
fi

# Asignar valor por defecto si el campo se dejó en blanco
if [ -z "$PASSROOT" ]; then
    PASSROOT="12345"
fi

# ---------------------------------------------------------
# Selección de versión de PHP
# ---------------------------------------------------------
PHPUSER=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Seleccionar versión de PHP" --radiolist "Seleccione la versión de PHP a instalar:" 15 60 3 \
"8.2" "Recomendada para Laravel 12" ON \
"8.3" "" OFF \
"8.4" "" OFF 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
fi

# ---------------------------------------------------------
# Selección de software adicional
# ---------------------------------------------------------
SOFTWARESUSER=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Software Adicional" --checklist "Seleccione el software adicional que desea instalar:" 15 60 4 \
"vscode" "Visual Studio Code" OFF \
"brave" "Brave Browser" OFF \
"chrome" "Google Chrome" OFF \
"filezilla" "FileZilla" OFF 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
fi

    # -----------------------------------------------------
    # Instalación de extensiones de PHP por separado
    # -----------------------------------------------------

    # Laravel/WordPress
    echo "XXX"
    echo "45"
    echo "Instalando php${PHPUSER}-xml (Laravel/WP)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-xml" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-xml" >/dev/null 2>&1
    fi

    echo "XXX"
    echo "50"
    echo "Instalando php${PHPUSER}-zip (Laravel/WP)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-zip" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-zip" >/dev/null 2>&1
    fi

    echo "XXX"
    echo "55"
    echo "Instalando php${PHPUSER}-mbstring (Laravel/WP)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-mbstring" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-mbstring" >/dev/null 2>&1
    fi

    echo "XXX"
    echo "60"
    echo "Instalando php${PHPUSER}-dom (Laravel/WP)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-dom" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-dom" >/dev/null 2>&1
    fi
    
    echo "XXX"
    echo "65"
    echo "Instalando php${PHPUSER}-curl (Laravel/WP)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-curl" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-curl" >/dev/null 2>&1
    fi
    
    echo "XXX"
    echo "70"
    echo "Instalando php${PHPUSER}-fileinfo (Laravel/WP)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-fileinfo" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-fileinfo" >/dev/null 2>&1
    fi

    # Laravel
    echo "XXX"
    echo "75"
    echo "Instalando php${PHPUSER}-bcmath (Laravel)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-bcmath" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-bcmath" >/dev/null 2>&1
    fi

    # WordPress
    echo "XXX"
    echo "80"
    echo "Instalando php${PHPUSER}-gmp (WordPress)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-gmp" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-gmp" >/dev/null 2>&1
    fi
    
    echo "XXX"
    echo "85"
    echo "Instalando php${PHPUSER}-imagick (WordPress)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-imagick" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-imagick" >/dev/null 2>&1
    fi

    echo "XXX"
    echo "90"
    echo "Instalando php${PHPUSER}-exif (WordPress)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-exif" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-exif" >/dev/null 2>&1
    fi
    
    # Base de datos
    echo "XXX"
    echo "95"
    echo "Instalando php${PHPUSER}-mysql (Base de Datos)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-mysql" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-mysql" >/dev/null 2>&1
    fi

    # Paso Final: Fin de la instalación
    echo "XXX"
    echo "100"
    echo "Fin Instalación"
    echo "XXX"
    sleep 3
    
) | whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalador de componentes" --gauge "Iniciando la instalación..." 6 60 0

exit 0
