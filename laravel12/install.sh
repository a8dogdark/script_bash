#! /bin/bash

# Script: install.sh
# Version: 2.0
# Descripcion:     Script de instalacion principal.
#                  Requiere privilegios de root para su ejecucion.
# Compatibilidad: Ubuntu 24.10, 23.10, 22.04 LTS, 24.04 LTS
#                 Debian 11 (Bullseye), 12 (Bookbook)
#                 AlmaLinux 9
# Autor:         [Tu Nombre o tu Organizacion, opcional]
# Fecha:         2025-07-29

clear # Limpiamos la pantalla al inicio del script

# Variables Globales
VER="2.0"
DISTRO=""
VERSION=""
DBASE="" # Se usará para definir el tipo de DB a instalar (ej. "mysql-server", "mariadb-server")
PACKAGE="" # Gestor de paquetes a usar (apt-get o dnf)
PASSROOT=""
PASSADMIN=""
PROYECTO=""
PHP_VERSION="" # Nueva variable para almacenar la versión de PHP seleccionada
SOFTWARE_ADICIONAL="" # Nueva variable para almacenar el software adicional seleccionado

# --- Validaciones Iniciales ---

# 1. Validar que el usuario sea root
if [ $EUID -ne 0 ]; then
  clear
  echo "Error: Este script debe ser ejecutado como root."
  echo "Por favor ingresa en la terminal y ejecuta"
  echo "Ubuntu    -> sudo su -"
  echo "Debian    -> su -"
  echo "Almalinux -> su -"
  exit 1
fi

# 2. Validar arquitectura de 64 bits
if [ "$(uname -m)" != "x86_64" ]; then
  clear
  echo "Error: Este script ('install.sh' v$VER) solo puede ejecutarse en sistemas de 64 bits (x86_64)."
  echo "Tu arquitectura actual es: $(uname -m)"
  echo "El script no puede continuar."
  exit 1
fi

# 3. Validar Distribucion y Version soportada
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu)
            case "$VERSION_ID" in
                22.04|23.10|24.04|24.10)
                    DISTRO="Ubuntu"
                    VERSION="$VERSION_ID"
                    DBASE="mysql-server"
                    PACKAGE="apt-get"
                    ;;
                *)
                    clear; echo "Error: Versión de Ubuntu ($VERSION_ID) no soportada."; exit 1
                    ;;
            esac
            ;;
        debian)
            case "$VERSION_ID" in
                11|12)
                    DISTRO="Debian"
                    VERSION="$VERSION_ID"
                    DBASE="mariadb-server"
                    PACKAGE="apt-get"
                    ;;
                *)
                    clear; echo "Error: Versión de Debian ($VERSION_ID) no soportada."; exit 1
                    ;;
            esac
            ;;
        almalinux)
            case "$VERSION_ID" in
                8|9)
                    DISTRO="AlmaLinux"
                    VERSION="$VERSION_ID"
                    DBASE="mariadb-server"
                    PACKAGE="dnf"
                    ;;
                *)
                    clear; echo "Error: Versión de AlmaLinux ($VERSION_ID) no soportada."; exit 1
                    ;;
            esac
            ;;
        *)
            clear; echo "Error: Distribución ($ID) no soportada."; exit 1
            ;;
    esac
else
    clear
    echo "Error: No se pudo detectar la distribución del sistema."
    echo "El archivo /etc/os-release no se encontró."
    exit 1
fi

# --- Instalación de Dialog (si no está instalado) ---
if ! command -v dialog &> /dev/null; then
    "$PACKAGE" install -yq dialog > /dev/null 2>&1
    if ! command -v dialog &> /dev/null; then
        clear
        echo "Error: No se pudo instalar el paquete 'dialog'."
        echo "Es necesario para el funcionamiento de este script."
        exit 1
    fi
fi

clear

# --- Caja de diálogo de bienvenida con opciones Aceptar/Cancelar ---
dialog --backtitle "Instalador de Entorno de Servidor (v$VER)" \
       --title "¡Bienvenido al Creador de Sistema LAMP para Laravel 12!" \
       --yesno "\nSe instalarán los siguientes paquetes:\n  - Apache\n  - PHP\n  - $DBASE\n  - PhpMyAdmin\n  - Composer\n  - Node.js\n  - Programas\n  - Proyecto base\n\nSu sistema ha sido detectado como:\n  Distribucion: $DISTRO $VERSION\n  Base de Datos: $DBASE\n  Gestor de Paquetes: $PACKAGE\n\n¿Desea continuar con la instalación?" \
       23 75

response=$?

if [ $response -ne 0 ]; then
    clear
    dialog --backtitle "Instalación Cancelada" \
           --title "Proceso Detenido" \
           --msgbox "\nLa instalación ha sido cancelada por el usuario." \
           10 50
    clear
    exit 0
fi

# --- Solicitud y Validación de Datos al Usuario ---

# 1. Solicitar Nombre del Proyecto
clear
PROYECTO=$(dialog --clear \
                  --backtitle "Configuración del Proyecto Laravel" \
                  --title "Nombre del Proyecto" \
                  --inputbox "\nPor favor, ingresa el nombre de tu proyecto Laravel 12 (ej. miapp sin guiones ni espacios):\n\n" \
                  10 60 "" 3>&1 1>&2 2>&3)
response=$?
clear
if [ $response -ne 0 ] || [ -z "$PROYECTO" ]; then
    dialog --backtitle "Error de Entrada" \
           --title "Campo Obligatorio" \
           --msgbox "\nEl nombre del proyecto es un campo obligatorio y no puede estar vacío.\n\nLa instalación será cancelada." \
           10 50
    clear
    exit 1
fi

# 2. Solicitar Password para PhpMyAdmin
clear
PASSADMIN=$(dialog --clear \
                   --backtitle "Configuración de PhpMyAdmin" \
                   --title "Contraseña PhpMyAdmin" \
                   --inputbox "\nPor favor, ingresa la contraseña para el usuario 'phpmyadmin':" \
                   12 60 "" 3>&1 1>&2 2>&3)
response=$?
clear
if [ $response -ne 0 ] || [ -z "$PASSADMIN" ]; then
    dialog --backtitle "Error de Entrada" \
           --title "Campo Obligatorio" \
           --msgbox "\nLa contraseña de PhpMyAdmin es un campo obligatorio y no puede estar vacío.\n\nLa instalación será cancelada." \
           10 50
    clear
    exit 1
fi

# 3. Solicitar Password para el usuario root de la Base de Datos
clear
PASSROOT=$(dialog --clear \
                  --backtitle "Configuración de la Base de Datos" \
                   --title "Contraseña Root de la Base de Datos" \
                   --inputbox "\nPor favor, ingresa la contraseña para el usuario 'root' de la base de datos:" \
                  12 60 "" 3>&1 1>&2 2>&3)
response=$?
clear
if [ $response -ne 0 ] || [ -z "$PASSROOT" ]; then
    dialog --backtitle "Error de Entrada" \
           --title "Campo Obligatorio" \
           --msgbox "\nLa contraseña del usuario 'root' de la base de datos es un campo obligatorio y no puede estar vacío.\n\nLa instalación será cancelada." \
           10 50
    clear
    exit 1
fi

# --- Selección de Versión de PHP ---
clear
PHP_VERSION=$(dialog --clear \
                     --backtitle "Selección de Versión de PHP" \
                     --title "Versión de PHP para Laravel 12" \
                     --radiolist "\nSelecciona la versión de PHP a instalar. PHP 8.4 es la más óptima para Laravel 12.\n\n" \
                     15 60 3 \
                     "8.2" "PHP 8.2" "off" \
                     "8.3" "PHP 8.3" "off" \
                     "8.4" "PHP 8.4 (Recomendado para Laravel 12)" "on" \
                     3>&1 1>&2 2>&3)
response=$?
clear

if [ $response -ne 0 ] || [ -z "$PHP_VERSION" ]; then
    dialog --backtitle "Error de Selección" \
           --title "Selección Obligatoria" \
           --msgbox "\nDebes seleccionar una versión de PHP para continuar con la instalación.\n\nLa instalación será cancelada." \
           10 50
    clear
    exit 1
fi

# --- Selección de Software Adicional (Opcional) ---
clear
SOFTWARE_ADICIONAL=$(dialog --clear \
                            --backtitle "Software Adicional (Opcional)" \
                            --title "Selecciona Software Opcional" \
                            --checklist "\nMarca los programas adicionales que deseas instalar (puedes seleccionar varios). Si no seleccionas nada o cancelas, la instalación principal continuará.\n\n" \
                            15 60 3 \
                            "vscode" "Visual Studio Code" "off" \
                            "brave" "Navegador Brave" "off" \
                            "chrome" "Google Chrome" "off" \
                            3>&1 1>&2 2>&3)
response=$?
# No hay mensaje de confirmación si no se seleccionó software adicional.
if [ $response -ne 0 ] || [ -z "$SOFTWARE_ADICIONAL" ]; then
    true # No hacer nada, solo asegurar que no haya un msgbox
fi


# --- Proceso de Instalación con Barra de Progreso Simple (con pausas y demo) ---

(
    # La caja de progreso mostrará "Instalando: <nombre_del_paquete/componente>"

    echo 0
    echo "# Iniciando instalación..."
    sleep 1

    echo 10
    echo "# Instalando: Repositorios"
    # AQUI VA EL CODIGO DE INSTALACION REAL DE REPOSITORIOS
    sleep 1

    echo 20
    echo "# Instalando: Apache2"
    # AQUI VA EL CODIGO DE INSTALACION REAL DE APACHE
    sleep 1

    echo 40
    echo "# Instalando: PHP $PHP_VERSION y Extensiones"
    # AQUI VA EL CODIGO DE INSTALACION REAL DE PHP
    sleep 1

    echo 60
    echo "# Instalando: $DBASE"
    # AQUI VA EL CODIGO DE INSTALACION REAL DE LA BASE DE DATOS
    sleep 1

    echo 75
    echo "# Instalando: PhpMyAdmin"
    # AQUI VA EL CODIGO DE INSTALACION REAL DE PHPMYADMIN
    sleep 1

    echo 85
    echo "# Instalando: Composer y Node.js"
    # AQUI VA EL CODIGO DE INSTALACION REAL DE COMPOSER Y NODE.JS
    sleep 1

    echo 95
    echo "# Instalando: Proyecto Laravel ($PROYECTO)"
    # AQUI VA EL CODIGO DE INSTALACION REAL DEL PROYECTO
    sleep 1

    echo 100
    echo "# Configurando permisos y finalizando..."
    # AQUI VA EL CODIGO DE CONFIGURACION FINAL
    sleep 1
) | dialog --gauge "Proceso de Instalación en Curso..." 12 70 0

# --- Mensaje de Finalización ---
clear
dialog --backtitle "Instalación Completada" \
       --title "¡Éxito!" \
       --msgbox "\nLa instalación de su entorno LAMP y Laravel 12 ha finalizado correctamente.\n\n¡Disfrute su nuevo entorno de desarrollo!" \
       10 60

clear
echo "¡Instalación finalizada!"
echo "Puede acceder a su proyecto en: http://localhost/$PROYECTO"
echo "PhpMyAdmin en: http://localhost/phpmyadmin"
echo "Versión de PHP instalada: $PHP_VERSION"
echo "Software adicional instalado: $SOFTWARE_ADICIONAL"
