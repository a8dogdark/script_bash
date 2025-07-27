#!/bin/bash

DISTRIBUCION=""
VERSION="" # Esta variable se actualizará en pasos posteriores
VERSO="2.0" # Versión de la instalación
PROJECT_NAME="" # Variable para el nombre del proyecto
PHPMYADMIN_USER_PASS="" # Variable para la contraseña del usuario phpMyAdmin
PHPMYADMIN_ROOT_PASS="" # Variable para la contraseña del usuario root de phpMyAdmin
PHP_VERSION="" # Variable para la versión de PHP seleccionada

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
        
        # Diálogo para pedir el nombre del proyecto Laravel
        PROJECT_NAME=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                                --title "Nombre del Proyecto Laravel" \
                                --inputbox "Por favor, ingresa el nombre que deseas para tu proyecto Laravel 12:" 10 60 3>&1 1>&2 2>&3)
        
        # Captura el estado de salida del inputbox (0 para OK, 1 para Cancelar, 255 para ESC)
        input_response=$?

        # Valida la entrada del usuario para el nombre del proyecto
        if [ $input_response -ne 0 ] || [ -z "$PROJECT_NAME" ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "¡Atención!" \
                   --msgbox "No se ha ingresado un nombre de proyecto válido o la operación fue cancelada. La instalación será abortada." 8 60
            exit 1
        fi

        clear # Limpia la pantalla antes del siguiente diálogo

        # Diálogo para pedir la contraseña del usuario phpMyAdmin
        PHPMYADMIN_USER_PASS=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                                        --title "Contraseña phpMyAdmin" \
                                        --inputbox "Debes ingresar una contraseña para el usuario 'phpmyadmin':" 10 60 3>&1 1>&2 2>&3)
        
        input_response=$? # Reutiliza la variable para la respuesta

        # Valida la entrada del usuario para la contraseña de phpmyadmin
        if [ $input_response -ne 0 ] || [ -z "$PHPMYADMIN_USER_PASS" ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "¡Atención!" \
                   --msgbox "No se ha ingresado una contraseña para el usuario 'phpmyadmin' o la operación fue cancelada. La instalación será abortada." 8 70
            exit 1
        fi

        clear # Limpia la pantalla antes del siguiente diálogo

        # Diálogo para pedir la contraseña del usuario root de phpMyAdmin
        PHPMYADMIN_ROOT_PASS=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                                        --title "Contraseña Root phpMyAdmin" \
                                        --inputbox "Debes ingresar una contraseña para el usuario 'root' de phpMyAdmin:" 10 60 3>&1 1>&2 2>&3)
        
        input_response=$? # Reutiliza la variable para la respuesta

        # Valida la entrada del usuario para la contraseña root de phpmyadmin
        if [ $input_response -ne 0 ] || [ -z "$PHPMYADMIN_ROOT_PASS" ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "¡Atención!" \
                   --msgbox "No se ha ingresado una contraseña para el usuario 'root' de phpMyAdmin o la operación fue cancelada. La instalación será abortada." 8 70
            exit 1
        fi

        clear # Limpia la pantalla antes del siguiente diálogo

        # Diálogo para seleccionar la versión de PHP
        PHP_VERSION=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                                --title "Seleccionar Versión de PHP" \
                                --menu "Elige la versión de PHP que deseas instalar:" 15 50 4 \
                                "8.2" "PHP 8.2 (Recomendado para Laravel 12)" \
                                "8.3" "PHP 8.3" \
                                "8.4" "PHP 8.4 (Versión más reciente)" 3>&1 1>&2 2>&3)
        
        menu_response=$? # Captura el estado de salida del menú

        # Valida la selección del usuario
        if [ $menu_response -ne 0 ] || [ -z "$PHP_VERSION" ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "¡Atención!" \
                   --msgbox "No se ha seleccionado una versión de PHP o la operación fue cancelada. La instalación será abortada." 8 70
            exit 1
        fi

        clear # Limpia la pantalla después de la selección de PHP

        # --- Barra de Progreso: Update y Upgrade del sistema ---
        (
            echo "XXXX"
            echo "Realizando update del sistema..."
            echo "XXXX"
            echo 40
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                DEBIAN_FRONTEND=noninteractive apt-get update >/dev/null 2>&1
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                dnf update -y >/dev/null 2>&1
            fi
            
            echo "XXXX"
            echo "Realizando upgrade del sistema..."
            echo "XXXX"
            echo 80
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >/dev/null 2>&1
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                dnf upgrade -y >/dev/null 2>&1
            fi
            
            echo "XXXX"
            echo "Sistema actualizado"
            echo "XXXX"
            echo 100
            sleep 2
        ) | dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "Progreso de la Instalación" \
                   --gauge "Iniciando operaciones..." 10 70 0
        
        clear # Limpia la pantalla después de que la barra de progreso termine

        # --- Barra de Progreso: Instalación de LAMP ---
        (
            echo "XXXX"
            echo "Instalando Apache2..."
            echo "XXXX"
            echo 10
            sleep 3 # Simula la instalación de Apache2

            echo "XXXX"
            echo "Instalando PHP $PHP_VERSION..."
            echo "XXXX"
            echo 35
            sleep 5 # Simula la instalación de PHP

            # Determina si es MySQL o MariaDB
            DB_SYSTEM=""
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                DB_SYSTEM="MySQL"
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                DB_SYSTEM="MariaDB"
            fi
            echo "XXXX"
            echo "Instalando $DB_SYSTEM..."
            echo "XXXX"
            echo 65
            sleep 5 # Simula la instalación de la base de datos

            echo "XXXX"
            echo "Instalando phpMyAdmin..."
            echo "XXXX"
            echo 90
            sleep 4 # Simula la instalación de phpMyAdmin

            echo "XXXX"
            echo "Componentes LAMP instalados."
            echo "XXXX"
            echo 100
            sleep 2 # Pausa de 2 segundos al 100%
        ) | dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "Instalación de Componentes LAMP" \
                   --gauge "Preparando el entorno LAMP..." 10 70 0

        clear # Limpia la pantalla después de que la barra de progreso de LAMP termine
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
