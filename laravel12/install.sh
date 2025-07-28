#!/bin/bash

VERSION_SCRIPT="2.0"

# Verificar si el usuario es root
if [ "$EUID" -ne 0 ]; then
    echo "Este script debe ejecutarse como root."
    exit 1
fi

# Verificar que el sistema es de 64 bits
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
    echo "Este script solo puede ejecutarse en sistemas de 64 bits (x86_64)."
    exit 1
fi

# Detectar información del sistema
source /etc/os-release

# Determinar distribución
DISTRO=""
case "$ID" in
    ubuntu)
        DISTRO="ubuntu"
        ;;
    debian)
        DISTRO="debian"
        ;;
    almalinux)
        DISTRO="almalinux"
        ;;
    *)
        echo "Distribución no compatible: $ID"
        exit 1
        ;;
esac

# Determinar versión simplificada
VERSION_SO=""
if [[ "$DISTRO" == "ubuntu" ]]; then
    VERSION_MAJOR=$(echo "$VERSION_ID" | cut -d'.' -f1)
    if [[ "$VERSION_MAJOR" == "22" || "$VERSION_MAJOR" == "23" || "$VERSION_MAJOR" == "24" ]]; then
        VERSION_SO="$VERSION_MAJOR"
    elif [[ "$VERSION_MAJOR" == "25" ]]; then
        echo "Este script no es compatible con Ubuntu 25.x"
        exit 1
    else
        echo "Versión de Ubuntu no soportada: $VERSION_ID"
        exit 1
    fi
elif [[ "$DISTRO" == "debian" || "$DISTRO" == "almalinux" ]]; then
    VERSION_MAJOR=$(echo "$VERSION_ID" | cut -d'.' -f1)
    if [[ "$VERSION_MAJOR" == "11" || "$VERSION_MAJOR" == "12" ]]; then
        VERSION_SO="$VERSION_MAJOR"
    else
        echo "Versión de $DISTRO no soportada: $VERSION_ID"
        exit 1
    fi
fi

echo "Sistema detectado: $DISTRO $VERSION_SO ($PRETTY_NAME)"
echo "Versión del script: $VERSION_SCRIPT"

# Instalar dialog si no está instalado (en segundo plano)
if ! command -v dialog &> /dev/null; then
    echo "dialog no encontrado, instalando en segundo plano..."
    (
        apt-get install -y dialog
    ) &
    PID=$!
    wait $PID
fi

# Determinar qué servidor de base de datos se instalará según distro
if [[ "$DISTRO" == "almalinux" ]]; then
    DB_SERVER="MariaDB"
else
    DB_SERVER="MySQL"
fi

# Mensaje para dialog
WELCOME_MSG="Bienvenido al instalador de Laravel con LAMP.\n
Se instalarán los siguientes paquetes:\n
- Apache2\n
- PHP y librerías\n
- $DB_SERVER\n
- PhpMyAdmin\n
- Composer\n
- Node.js\n
- Programas adicionales\n
- Proyecto Laravel 12"

# Mostrar cuadro de diálogo de bienvenida
dialog --title "Bienvenida" \
       --yesno "$WELCOME_MSG" 15 60

response=$?
if [ $response -ne 0 ]; then
    clear
    echo "Instalación cancelada por el usuario."
    exit 0
fi

clear

# Preguntar nombre del proyecto Laravel
dialog --title "Nombre del Proyecto" \
       --inputbox "Ingresa el nombre del proyecto Laravel que deseas crear:" 10 60 2> /tmp/project_name

response=$?
PROJECT_NAME=$(cat /tmp/project_name)
rm -f /tmp/project_name

if [ $response -ne 0 ] || [ -z "$PROJECT_NAME" ]; then
    dialog --title "Error" \
           --msgbox "No ingresaste ningún nombre de proyecto." 8 50
    clear
    echo "Instalación cancelada por falta de nombre de proyecto."
    exit 0
fi

clear
echo "Nombre del proyecto: $PROJECT_NAME"
