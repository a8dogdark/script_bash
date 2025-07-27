#!/bin/bash

# Validar si el usuario es root
if [ "$(id -u)" -ne 0 ]; then
    clear
    echo "Este script debe ejecutarse como root. Por favor, ejecuta con sudo."
    exit 1
fi

# Validar si el sistema es de 64 bits
if [ "$(uname -m)" != "x86_64" ]; then
    clear
    echo "Este script requiere un sistema de 64 bits (x86_64)."
    echo "Tu sistema no cumple con los requisitos de hardware."
    exit 1
fi

# Validar distribución y versión
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION=$VERSION_ID
else
    clear
    echo "No se pudo detectar la distribución del sistema."
    echo "Este script solo soporta Ubuntu (22+), Debian (11+) y AlmaLinux (estable)."
    exit 1
fi

case "$DISTRO" in
    ubuntu)
        if (( $(echo "$VERSION >= 22" | bc -l) )); then
            echo "Ubuntu versión $VERSION detectada. Compatible."
        else
            clear
            echo "Ubuntu versión $VERSION no compatible. Se requiere Ubuntu 22 o superior."
            exit 1
        fi
        ;;
    debian)
        if (( $(echo "$VERSION >= 11" | bc -l) )); then
            echo "Debian versión $VERSION detectada. Compatible."
        else
            clear
            echo "Debian versión $VERSION no compatible. Se requiere Debian 11 o superior."
            exit 1
        fi
        ;;
    almalinux)
        # AlmaLinux LTS versions: 8.x, 9.x are considered stable for this context
        if [[ "$VERSION" =~ ^(8|9)\.[0-9]+$ ]]; then
            echo "AlmaLinux versión $VERSION detectada. Compatible."
        else
            clear
            echo "AlmaLinux versión $VERSION no compatible. Se requieren versiones estables (8.x, 9.x)."
            exit 1
        fi
        ;;
    *)
        clear
        echo "Distribución '$DISTRO' no soportada."
        echo "Este script solo soporta Ubuntu (22+), Debian (11+) y AlmaLinux (estable)."
        exit 1
        ;;
esac
