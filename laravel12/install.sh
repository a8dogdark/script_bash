#!/bin/bash

DISTRIBUCION=""
VERSION="" # Esta variable se actualizará en pasos posteriores
VERSO="2.0" # Versión de la instalación
PROJECT_NAME="" # Variable para el nombre del proyecto
PHPMYADMIN_USER_PASS="" # Variable para la contraseña del usuario phpMyAdmin
PHPMYADMIN_ROOT_PASS="" # Variable para la contraseña del usuario root de phpMyAdmin
PHP_VERSION="" # Variable para la versión de PHP seleccionada
SELECTED_APPS="" # Nueva variable para almacenar las aplicaciones seleccionadas

# Archivo de log para depuración
# CAMBIO: Se ajusta la ubicación del log para que sea accesible desde el usuario de escritorio.
# Se usa SUDO_USER para obtener el nombre del usuario que ejecutó 'sudo'.
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(eval echo "~$SUDO_USER") # Obtiene el directorio home del usuario original
    LOG_DIR="$USER_HOME/Documents"
else
    # Fallback si SUDO_USER no está definido (aunque debería estarlo con sudo)
    LOG_DIR="$HOME/Documents" # Esto sería /root/Documents si es root directamente
fi

mkdir -p "$LOG_DIR" # Asegura que la carpeta Documents exista para el usuario
LOG_FILE="$LOG_DIR/lamp_install_$(date +%Y%m%d_%H%M%S).log"

# Crear o limpiar el archivo de log al inicio
echo "Iniciando log de instalación LAMP. Fecha: $(date)" > "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"
# ... el resto de tu script sigue igual ...
