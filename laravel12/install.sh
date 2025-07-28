#!/bin/bash
# install.sh - Versión 2.0
# Utiliza 'dialog' para la comunicación con el usuario
# Todas las instalaciones y procesos deben ejecutarse en segundo plano sin confirmaciones

clear

# Distribuciones objetivo:
# - Ubuntu 22, 23, 24
# - Debian 11, 12
# - AlmaLinux

# Por defecto se usará MySQL Server en Ubuntu 24.10.
# Para las demás distribuciones se seleccionará la base de datos más adecuada y compatible.

# Validar si el script se ejecuta como root
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31mEste script debe ejecutarse como root. Saliendo...\e[0m"
  exit 1
fi

# Validar que la arquitectura sea 64 bits
ARCH=$(uname -m)
if [[ "$ARCH" != "x86_64" && "$ARCH" != "amd64" ]]; then
  echo -e "\e[31mEste script solo es compatible con sistemas de 64 bits. Saliendo...\e[0m"
  exit 1
fi

# Validar distribución y versión
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS_NAME=$ID
  OS_VERSION=$VERSION_ID
else
  echo -e "\e[31mNo se pudo determinar la distribución del sistema. Saliendo...\e[0m"
  exit 1
fi

case "$OS_NAME" in
  ubuntu)
    UBUNTU_MAJOR=$(echo "$OS_VERSION" | cut -d '.' -f1)
    if [[ "$UBUNTU_MAJOR" -ge 22 && "$UBUNTU_MAJOR" -le 24 ]]; then
      :
    else
      echo -e "\e[31mUbuntu versión no soportada. Solo 22.x, 23.x o 24.x son permitidos. Saliendo...\e[0m"
      exit 1
    fi
    ;;
  debian)
    if [[ "$OS_VERSION" == "11" || "$OS_VERSION" == "12" ]]; then
      :
    else
      echo -e "\e[31mDebian versión no soportada. Solo 11 o 12 son permitidos. Saliendo...\e[0m"
      exit 1
    fi
    ;;
  almalinux)
    # AlmaLinux aceptado cualquier versión
    ;;
  *)
    echo -e "\e[31mDistribución $OS_NAME no soportada. Saliendo...\e[0m"
    exit 1
    ;;
esac

# Mostrar cuadro de bienvenida con dialog
dialog --backtitle "Instalador LAMP para Laravel 12" \
       --yes-label "Continuar" --no-label "Salir" \
       --yesno "Bienvenido al instalador LAMP para Laravel 12.\n\n¿Deseas continuar?" 10 50

response=$?

if [ $response -eq 1 ]; then
  dialog --backtitle "Salir" --msgbox "Has elegido salir. El programa se cerrará." 7 40
  clear
  exit 0
fi

clear
