#!/bin/bash

VERSION="2.0"
DISTRO=""
PASSPHP=""
PASSROOT=""
PROYECTO=""
DBASE=""
PHP_VERSION="" # Nueva variable para almacenar la versión de PHP seleccionada
PROGRAMAS_SELECCIONADOS=() # Array para almacenar los programas seleccionados

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

# Detectar qué base de datos se utilizará según la distribución
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    DBASE="MariaDB"
elif [ "$DISTRO" = "AlmaLinux" ]; then
    DBASE="MySQL"
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

# Cuadro de selección de versión de PHP (radiolist)
PHP_VERSION=$(dialog --clear --stdout \
                     --title "Selección de Versión de PHP" \
                     --radiolist "Laravel 12 es compatible con PHP 8.2 y superior. Selecciona la versión de PHP a instalar:" 15 50 3 \
                     "8.2" "Recomendada para Laravel 12" ON \
                     "8.3" "Versión más reciente con mejoras" OFF \
                     "8.4" "Versión en desarrollo (no recomendada para producción)" OFF )

php_choice_exit_code=$?
if [ "$php_choice_exit_code" -eq 1 ] || [ "$php_choice_exit_code" -eq 255 ]; then # Solo si Cancel o ESC
    clear
    echo "Instalación cancelada por el usuario."
    exit 0
fi

# Cuadro de selección de programas
PROGRAMAS_SELECCIONADOS_STR=$(dialog --clear --stdout \
                                     --title "Selección de Programas Adicionales" \
                                     --checklist "Selecciona uno o más programas para instalar:" 18 60 4 \
                                     "vscode" "Visual Studio Code" OFF \
                                     "sublime" "Sublime Text" OFF \
                                     "brave" "Brave Browser" OFF \
                                     "chrome" "Google Chrome" OFF )

programs_choice_exit_code=$?
if [ "$programs_choice_exit_code" -ne 0 ]; then
    clear
    echo "Instalación cancelada por el usuario."
    exit 0
fi

# Convertir la cadena de programas seleccionados en un array
IFS=' ' read -r -a PROGRAMAS_SELECCIONADOS <<< "$PROGRAMAS_SELECCIONADOS_STR"

# --- BARRA DE PROGRESO DE INSTALACIÓN ---
(
# 1% - Preparación del sistema: Actualizar índices de paquetes
echo "XXX"
echo "1"
echo "Preparando el sistema: Actualizando índices de paquetes..."
echo "XXX"
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    apt-get update -qq > /dev/null
elif [ "$DISTRO" = "AlmaLinux" ]; then
    yum makecache -y > /dev/null
fi

# 2% - Preparación del sistema: Actualizando paquetes
echo "XXX"
echo "2"
echo "Preparando el sistema: Actualizando paquetes..."
echo "XXX"
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq > /dev/null
elif [ "$DISTRO" = "AlmaLinux" ]; then
    yum update -y -q > /dev/null
fi

# 3% - Instalando utilidades esenciales: curl
echo "XXX"
echo "3"
if ! command -v curl &> /dev/null; then
    echo "Instalando: curl..." # Mensaje visible en la barra de progreso
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl > /dev/null
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y -q curl > /dev/null
    fi
else
    echo "curl ya está instalado." # Mensaje visible si ya está instalado
fi
echo "XXX" # Cierre del bloque de mensaje/porcentaje

# 4% - Instalando utilidades esenciales: wget
echo "XXX"
echo "4"
if ! command -v wget &> /dev/null; then
    echo "Instalando: wget..." # Mensaje visible en la barra de progreso
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq wget > /dev/null
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y -q wget > /dev/null
    fi
else
    echo "wget ya está instalado." # Mensaje visible si ya está instalado
fi
echo "XXX" # Cierre del bloque de mensaje/porcentaje

# 5% - Instalando utilidades esenciales: unzip
echo "XXX"
echo "5"
if ! command -v unzip &> /dev/null; then
    echo "Instalando: unzip..." # Mensaje visible en la barra de progreso
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq unzip > /dev/null
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y -q unzip > /dev/null
    fi
else
    echo "unzip ya está instalado." # Mensaje visible si ya está instalado
fi
echo "XXX" # Cierre del bloque de mensaje/porcentaje

# 6% - Instalando utilidades esenciales: zip
echo "XXX"
echo "6"
if ! command -v zip &> /dev/null; then
    echo "Instalando: zip..." # Mensaje visible en la barra de progreso
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq zip > /dev/null
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y -q zip > /dev/null
    fi
else
    echo "zip ya está instalado." # Mensaje visible si ya está instalado
fi
echo "XXX" # Cierre del bloque de mensaje/porcentaje

# Aquí se agregarán los siguientes pasos de instalación con sus porcentajes...
# Por ejemplo:
# 10% - Instalando Apache...
# 20% - Instalando $DBASE...
# 30% - Instalando PHP $PHP_VERSION...
# etc.


# 100% - Simulando finalización
echo "XXX"
echo "100"
echo "Configuraciones finales completadas."
echo "XXX"

) | dialog --gauge "Iniciando instalación de LAMP y Laravel. Por favor, espera..." 10 70 0

clear
dialog --title "Instalación Completada" --msgbox "La instalación de LAMP y Laravel se ha completado con éxito, o ha sido cancelada si hubo errores." 10 50
