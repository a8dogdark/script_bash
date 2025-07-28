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

# Detectar la distribución
if grep -q "Ubuntu" /etc/os-release; then
    DISTRO="Ubuntu"
elif grep -q "Debian" /etc/os-release; then
    DISTRO="Debian"
elif grep -q "AlmaLinux" /etc/os-release; then
    DISTRO="AlmaLinux"
else
    echo "Distribución no soportada. Este script es compatible con Ubuntu (22, 23, 24), Debian (11, 12) y AlmaLinux."
    exit 1
fi

# Detectar si MySQL o MariaDB está instalado
if command -v mysql &> /dev/null; then
    if mysql -V 2>&1 | grep -q "MariaDB"; then
        DBASE="MariaDB"
    elif mysql -V 2>&1 | grep -q "MySQL"; then
        DBASE="MySQL"
    fi
else
    # Si no se detecta, establecer un valor predeterminado o indicar que se elegirá
    DBASE="MySQL o MariaDB (se elegirá)"
fi

# Validar que el sistema sea de 64 bits
if [ "$(uname -m)" != "x86_64" ]; then
    echo "Este script solo puede ejecutarse en sistemas de 64 bits (x86_64)."
    exit 1
fi

# Validar e instalar dialog si no está presente
if ! command -v dialog &> /dev/null; then
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        apt-get install -y dialog > /dev/null
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y dialog > /dev/null
    fi
    if ! command -v dialog &> /dev/null; then
        echo "Error: No se pudo instalar dialog. Abortando."
        exit 1
    fi
fi

# Función para manejar la salida de dialog (Enter o ESC, y campo vacío)
check_input() {
    local input_value="$1"
    local input_name="$2"
    local dialog_exit_code="$3"

    if [ -z "$input_value" ]; then
        dialog --title "Error" --msgbox "El campo '$input_name' no puede estar vacío." 8 40
        clear
        exit 1
    elif [ "$dialog_exit_code" -ne 0 ]; then # 0 para OK, 1 para Cancel, 255 para ESC
        clear
        echo "Instalación cancelada por el usuario."
        exit 0
    fi
}

# Cuadro de bienvenida
dialog --title "Bienvenido al Instalador y creador de proyectos Laravel 12" \
--backtitle "Instalador LAMP Laravel 12 - Versión $VERSION" \
--yesno "\nSe instalarán los siguientes paquetes:\n\n- Apache\n- PHP\n- $DBASE\n- phpMyAdmin\n- Composer\n- Node.js\n- Programas del proyecto\n\n¿Deseas continuar?" 18 70

response=$?
case $response in
    0) # Botón Aceptar presionado
        clear
        ;;
    1) # Botón Cancelar presionado
        clear
        echo "Instalación cancelada por el usuario."
        exit 0
        ;;
    255) # Tecla ESC presionada
        clear
        echo "Instalación cancelada por el usuario (ESC)."
        exit 0
        ;;
esac

# Input para el nombre del proyecto
PROYECTO=$(dialog --clear --stdout \
                --title "Nombre del Proyecto Laravel" \
                --inputbox "Ingresa el nombre del proyecto Laravel 12 a crear:" 10 60)
check_input "$PROYECTO" "Nombre del Proyecto" $?

# Input para la contraseña del usuario phpMyAdmin de la base de datos
PASSPHP=$(dialog --clear --stdout \
               --title "Contraseña para Usuario phpMyAdmin de MySQL/MariaDB" \
               --inputbox "Ingresa la contraseña para el usuario phpMyAdmin de la base de datos:" 10 60)
check_input "$PASSPHP" "Contraseña phpMyAdmin" $?

# Input para la contraseña del usuario root de la base de datos
PASSROOT=$(dialog --clear --stdout \
                --title "Contraseña para Usuario Root de MySQL/MariaDB" \
                --inputbox "Ingresa la contraseña para el usuario root de la base de datos:" 10 60)
check_input "$PASSROOT" "Contraseña Root" $?

# Este script instalará LAMP y las dependencias necesarias para Laravel 12.
# Está diseñado para ser ejecutado en Ubuntu 24 y es compatible con Ubuntu 23, 22, Debian 11, 12 y AlmaLinux.

# Parte 1: Instalación de Apache, MySQL y PHP
# Parte 2: Configuración de MySQL
# Parte 3: Instalación de Composer
# Parte 4: Instalación de Node.js y npm
# Parte 5: Configuración adicional y permisos
