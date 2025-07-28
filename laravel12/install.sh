#!/bin/bash
# install.sh - Versión 2.0
# Utiliza 'dialog' para la comunicación con el usuario
# Todas las instalaciones y procesos deben ejecutarse en segundo plano sin confirmaciones

clear

# Distribuciones objetivo:
# - Ubuntu 22.04, 23.10, 24.10
# - Debian 11, 12
# - AlmaLinux

# Por defecto se usará MySQL Server en Ubuntu 24.10.
# Para las demás distribuciones se seleccionará la base de datos más adecuada y compatible.

# Validar si el script se ejecuta como root
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31mEste script debe ejecutarse como root. Saliendo...\e[0m"
  exit 1
fi
