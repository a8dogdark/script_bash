#!/bin/bash

VEROS="2.0"

# Validar si el usuario es root
if [ "$(id -u)" -ne 0 ]; then
    clear
    exit 1
fi

# Validar si el sistema es de 64 bits
if [ "$(uname -m)" != "x86_64" ]; then
    clear
    exit 1
fi

# Validar distribución y versión
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION=$VERSION_ID
else
    clear
    exit 1
fi

# Definir el paquete de base de datos y validar compatibilidad
case "$DISTRO" in
    ubuntu)
        if ! (( $(echo "$VERSION >= 22" | bc -l) )); then
            clear
            exit 1
        fi
        DB_PACKAGE="mysql-server"
        DB_TYPE="MySQL" # Variable para el tipo de DB
        DB_ROOT_USER="mysql"
        ;;
    debian)
        if ! (( $(echo "$VERSION >= 11" | bc -l) )); then
            clear
            exit 1
        fi
        DB_PACKAGE="mariadb-server"
        DB_TYPE="MariaDB" # Variable para el tipo de DB
        DB_ROOT_USER="mariadb"
        ;;
    almalinux)
        if ! [[ "$VERSION" =~ ^(8|9)\.[0-9]+$ ]]; then
            clear
            exit 1
        fi
        DB_PACKAGE="mariadb-server"
        DB_TYPE="MariaDB" # Variable para el tipo de DB
        DB_ROOT_USER="mariadb"
        ;;
    *)
        clear
        exit 1
        ;;
esac

# Validar e instalar 'dialog' en segundo plano si no está presente
if ! command -v dialog &> /dev/null; then
    case "$DISTRO" in
        ubuntu|debian)
            apt update > /dev/null 2>&1 &
            apt install -y dialog > /dev/null 2>&1 &
            ;;
        almalinux)
            dnf install -y dialog > /dev/null 2>&1 &
            ;;
    esac
    sleep 2
    # Esperar activamente a que 'dialog' esté disponible si se acaba de instalar
    while ! command -v dialog &> /dev/null; do
        sleep 1
    done
fi

# Cuadro de bienvenida con información de paquetes y opciones Aceptar/Salir
dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
--title "Bienvenido al Instalador de Laravel 12" \
--yesno "\nEste script preparara tu sistema para Laravel 12.\n\nSe instalaran los siguientes paquetes:\n- Apache2\n- PHP (y extensiones necesarias)\n- $DB_PACKAGE\n- phpMyAdmin\n\n¿Deseas continuar con la instalacion?" 18 70

response=$?
case $response in
    0) # Codigo de retorno 0 = Yes/Aceptar
        clear
        # El script continuaria aqui con las siguientes acciones de instalacion
        ;;
    1) # Codigo de retorno 1 = No/Salir
        clear
        exit 0
        ;;
    255) # Codigo de retorno 255 = ESC presionado o ventana cerrada
        clear
        exit 0
        ;;
esac

# Solicitar el nombre del proyecto Laravel
PROJECT_NAME=$(dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
--title "Nombre del Proyecto Laravel" \
--inputbox "\nIngresa el nombre para tu nuevo proyecto Laravel 12:\n(Ej: crud)" 10 60 "" 3>&1 1>&2 2>&3)

# Verificar si el usuario canceló o dejó el nombre vacío
if [ -z "$PROJECT_NAME" ]; then
    clear
    dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
    --title "Error" \
    --msgbox "\nNo se ha especificado un nombre de proyecto. Saliendo del instalador." 8 50
    clear
    exit 1
fi

# Solicitar la contraseña para el usuario de phpMyAdmin (visible)
PHPMYADMIN_PASSWORD=$(dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
--title "Contraseña de phpMyAdmin" \
--inputbox "\nIngresa la contraseña para el usuario 'phpmyadmin' de $DB_TYPE:" 10 60 "" 3>&1 1>&2 2>&3)

# Verificar si el usuario canceló o dejó la contraseña vacía
if [ -z "$PHPMYADMIN_PASSWORD" ]; then
    clear
    dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
    --title "Error" \
    --msgbox "\nNo se ha especificado una contraseña para phpMyAdmin. Saliendo del instalador." 8 50
    clear
    exit 1
fi

# Solicitar la contraseña para el usuario root de la base de datos (visible)
DB_ROOT_PASSWORD=$(dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
--title "Contraseña Root de $DB_PACKAGE" \
--inputbox "\nIngresa la contraseña para el usuario root de $DB_ROOT_USER:" 10 60 "" 3>&1 1>&2 2>&3)

# Verificar si el usuario canceló o dejó la contraseña vacía
if [ -z "$DB_ROOT_PASSWORD" ]; then
    clear
    dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
    --title "Error" \
    --msgbox "\nNo se ha especificado una contraseña para el usuario root de la base de datos. Saliendo del instalador." 8 50
    clear
    exit 1
fi
