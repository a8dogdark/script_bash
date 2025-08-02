#!/bin/bash

# Validar si es root
if [[ $EUID -ne 0 ]]; then
  clear
  echo "Debes ser usuario root para ejecutar el programa."
  exit 1
fi

# Validar si el sistema es de 64 bits
if [[ $(uname -m) != "x86_64" ]]; then
  clear
  echo "Este script solo es compatible con sistemas de 64 bits."
  exit 1
fi

# Obtener los datos de la distribución y su versión
DISTRO=$(lsb_release -si)
VERDISTRO=$(lsb_release -sr)

# Validar distribución y versión
case $DISTRO in
  Ubuntu|AnduinOS)
    case $VERDISTRO in
      20.04|22.04|24.04)
        ;;
      *)
        clear
        echo "Este script solo es compatible con versiones LTS de Ubuntu/AnduinOS (20.04, 22.04, 24.04)."
        exit 1
        ;;
    esac
    ;;
  Debian)
    case $VERDISTRO in
      11*|12*)
        ;;
      *)
        clear
        echo "Este script solo es compatible con Debian 11 o 12."
        exit 1
        ;;
    esac
    ;;
  AlmaLinux)
    case $VERDISTRO in
      8*|9*)
        ;;
      *)
        clear
        echo "Este script solo es compatible con AlmaLinux 8 o 9."
        exit 1
        ;;
    esac
    ;;
  *)
    clear
    echo "Este script solo es compatible con Ubuntu/AnduinOS LTS, Debian 11/12 o AlmaLinux 8/9."
    exit 1
    ;;
esac
