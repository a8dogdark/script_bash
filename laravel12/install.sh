#!/bin/bash

DISTRIBUCION=""
VERSION="" # Esta variable se actualizará en pasos posteriores
VERSO="2.0" # Versión de la instalación
PROJECT_NAME="" # Nueva variable para el nombre del proyecto

# Validación de usuario root
if [ "$(id -u)" -ne 0 ]; then
    clear
    echo "Este script debe ejecutarse como usuario root."
    exit 1
fi

# Validación de arquitectura de 64 bits
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ]; then # x86_64 es para Intel/AMD 64-bit, aarch64 para ARM 64-bit
    clear
    echo "Este script solo se puede ejecutar en sistemas de 64 bits."
    exit 1
fi

# Instalación y Validación de 'dialog'
if [ -f /etc/os-release ]; then
    . /etc/os-release # Carga las variables de identificación del sistema
    
    # Detecta distribuciones basadas en Debian/Ubuntu
    if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == "debian" ]]; then
        DISTRIBUCION="Ubuntu/Debian"
        if ! dpkg -s dialog >/dev/null 2>&1; then # Verifica si dialog no está instalado
            DEBIAN_FRONTEND=noninteractive apt-get update >/dev/null 2>&1
            DEBIAN_FRONTEND=noninteractive apt-get install -y dialog >/dev/null 2>&1
            if [ $? -ne 0 ]; then # Si la instalación falló
                echo "Error: No se pudo instalar el paquete 'dialog'. Por favor, inténtelo manualmente."
                exit 1
            fi
        fi
    # Detecta distribuciones basadas en RHEL (como AlmaLinux)
    elif [[ "$ID" == "almalinux" || "$ID_LIKE" == "rhel fedora" || "$ID_LIKE" == "rhel" ]]; then
        DISTRIBUCION="AlmaLinux"
        if ! rpm -q dialog >/dev/null 2>&1; then # Verifica si dialog no está instalado
            dnf install -y dialog >/dev/null 2>&1
            if [ $? -ne 0 ]; then # Si la instalación falló
                echo "Error: No se pudo instalar el paquete 'dialog'. Por favor, inténtelo manualmente."
                exit 1
            fi
        fi
    else
        # Si la distribución no es una de las esperadas
        echo "Error: La distribución ($ID) no está soportada para la instalación automática de 'dialog'."
        echo "Por favor, instale 'dialog' manualmente si es necesario."
        exit 1
    fi
else
    # Si /etc/os-release no existe
    echo "Error: No se pudo detectar la distribución del sistema (/etc/os-release no encontrado)."
    echo "Por favor, instale 'dialog' manualmente si es necesario."
    exit 1
fi

# Diálogo de Bienvenida
# Limpia la pantalla antes de mostrar el diálogo
clear

# Muestra el diálogo de bienvenida con opción Sí/No
dialog --backtitle "Script de Instalación Versión $VERSO" \
       --title "Bienvenida al Instalador" \
       --yesno "\n¡Bienvenido al script de instalación!\n\nEste script te ayudará a instalar y configurar el software necesario en tu sistema $DISTRIBUCION.\nPrepararemos un servidor LAMP para Laravel 12.\n\n¿Deseas continuar con la instalación?" 15 60

# Captura la respuesta del usuario (0 para Sí, 1 para No, 255 para ESC)
response=$?

# Maneja la respuesta del usuario
case $response in
    0) # El usuario eligió "Sí"
        clear # Limpia la pantalla después del diálogo
        
        # --- AQUÍ EMPIEZA EL INPUTBOX ---
        PROJECT_NAME=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                                --title "Nombre del Proyecto Laravel" \
                                --inputbox "Por favor, ingresa el nombre que deseas para tu proyecto Laravel 12:" 10 60 3>&1 1>&2 2>&3)
        
        # Captura el estado de salida del inputbox (0 para OK, 1 para Cancelar, 255 para ESC)
        input_response=$?

        # Valida la entrada del usuario
        if [ $input_response -ne 0 ] || [ -z "$PROJECT_NAME" ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "¡Atención!" \
                   --msgbox "No se ha ingresado un nombre de proyecto válido o la operación fue cancelada. La instalación será abortada." 8 60
            exit 1
        fi

        # Si todo está bien, el script continuaría desde aquí con el $PROJECT_NAME
        clear
        ;;
    1) # El usuario eligió "No"
        clear # Limpia la pantalla antes de salir
        exit 0 # Sale del script sin errores
        ;;
    255) # El usuario presionó ESC
        clear # Limpia la pantalla antes de salir
        exit 1 # Sale del script con un código de error (por cancelación forzada)
        ;;
esac
