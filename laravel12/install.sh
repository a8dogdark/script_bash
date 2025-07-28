#!/bin/bash

# Este script está diseñado para instalar LAMP para Laravel 12 en múltiples distribuciones Linux.
# Trabajará en modo silencioso, y las validaciones se manejarán con 'dialog'.

VERSION="2.0" # Versión del script

# Validación de usuario root
if [ "$EUID" -ne 0 ]; then
  exit 1
fi

# Validación de arquitectura del sistema (64 bits)
if ! uname -m | grep -q "64"; then
  exit 1
fi

# Detectar y validar el sistema operativo
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    VERSION_ID_RAW=$VERSION_ID # Guardamos la versión ID original
else
    exit 1
fi

# Asignar la variable DISTRO y validar la versión
case "$OS_ID" in
    ubuntu)
        DISTRO="ubuntu"
        case "$VERSION_ID_RAW" in
            "22.04"|"23.10"|"24.10")
                VERSION_SO="$VERSION_ID_RAW"
                ;;
            *)
                exit 1 # Versión de Ubuntu no soportada
                ;;
        esac
        ;;
    debian)
        DISTRO="debian"
        case "$VERSION_ID_RAW" in
            "11"|"12")
                VERSION_SO="$VERSION_ID_RAW"
                ;;
            *)
                exit 1 # Versión de Debian no soportada
                ;;
        esac
        ;;
    almalinux)
        DISTRO="almalinux"
        # AlmaLinux no necesita una validación de versión específica aquí a menos que se especifique
        # Asignamos la versión para consistencia, aunque no la validemos estrictamente de momento.
        VERSION_SO="$VERSION_ID_RAW"
        ;;
    *)
        exit 1 # Sistema operativo no soportado
        ;;
esac

# Instalar dialog si no está presente (en modo silencioso)
if ! command -v dialog &> /dev/null; then
    case "$DISTRO" in
        ubuntu|debian)
            apt install -y dialog >/dev/null 2>&1
            ;;
        almalinux)
            dnf install -y dialog >/dev/null 2>&1
            ;;
    esac
fi

# Cuadro de Bienvenida Yes/No
dialog --backtitle "Instalador de LAMP y Laravel 12 - v$VERSION" \
       --title "¡Bienvenido!" \
       --yesno "Este script instalará un entorno LAMP y las dependencias necesarias para Laravel 12 en tu sistema $DISTRO $VERSION_SO.\n\n\
Los componentes a instalar incluyen:\n\
- Apache\n\
- PHP y extensiones\n\
- MySQL o MariaDB (según el sistema operativo)\n\
- PhpMyAdmin\n\
- Composer\n\
- Node.js\n\
- Programas adicionales\n\
- Proyecto Laravel 12\n\n\
¿Deseas continuar con la instalación?" 20 75

# Capturar la respuesta del cuadro Yes/No
response=$?

# Si la respuesta es No (255 para yesno significa "No")
if [ $response -ne 0 ]; then
    dialog --backtitle "Instalador de LAMP y Laravel 12 - v$VERSION" \
           --title "Saliendo..." \
           --msgbox "Sales de nuestro instalador. ¡Esperamos verte pronto!" 8 50
    exit 0
fi
