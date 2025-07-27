#!/bin/bash

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

case "$DISTRO" in
    ubuntu)
        if ! (( $(echo "$VERSION >= 22" | bc -l) )); then
            clear
            exit 1
        fi
        ;;
    debian)
        if ! (( $(echo "$VERSION >= 11" | bc -l) )); then
            clear
            exit 1
        fi
        ;;
    almalinux)
        if ! [[ "$VERSION" =~ ^(8|9)\.[0-9]+$ ]]; then
            clear
            exit 1
        fi
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
fi
