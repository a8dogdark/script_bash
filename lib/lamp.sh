#!/bin/bash

clear

# Validar si se ejecuta como root
if [[ "$EUID" -ne 0 ]]; then
    echo "Este script debe ejecutarse como root."
    exit 1
fi

# Validar arquitectura de 64 bits
if [[ "$(uname -m)" != "x86_64" && "$(uname -m)" != "aarch64" ]]; then
    echo "Este script solo puede ejecutarse en sistemas de 64 bits."
    exit 1
fi

# Validar que sea Ubuntu, Debian o AnduinOS y guardar en DISTRO y DISVER
if grep -qi 'AnduinOS' /etc/os-release; then
    DISTRO="AnduinOS"
    DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')
elif grep -qi 'Ubuntu' /etc/os-release; then
    DISTRO="Ubuntu"
    DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')
elif grep -qi 'Debian' /etc/os-release; then
    DISTRO="Debian"
    DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')
else
    echo "Este script solo puede ejecutarse en Ubuntu, Debian o AnduinOS."
    exit 1
fi
