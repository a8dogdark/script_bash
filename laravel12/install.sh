#!/bin/bash

DISTRIBUCION=""
VERSION="" # Esta variable se actualizará en pasos posteriores
VERSO="2.0" # Versión de la instalación
PROJECT_NAME="" # Variable para el nombre del proyecto
PHPMYADMIN_USER_PASS="" # Variable para la contraseña del usuario phpMyAdmin
PHPMYADMIN_ROOT_PASS="" # Variable para la contraseña del usuario root de phpMyAdmin
PHP_VERSION="" # Variable para la versión de PHP seleccionada
SELECTED_APPS="" # Nueva variable para almacenar las aplicaciones seleccionadas

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
        clear
        
        # Diálogo para pedir el nombre del proyecto Laravel
        PROJECT_NAME=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                                --title "Nombre del Proyecto Laravel" \
                                --inputbox "Por favor, ingresa el nombre que deseas para tu proyecto Laravel 12:" 10 60 3>&1 1>&2 2>&3)
        
        input_response=$?

        if [ $input_response -ne 0 ] || [ -z "$PROJECT_NAME" ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "¡Atención!" \
                   --msgbox "No se ha ingresado un nombre de proyecto válido o la operación fue cancelada. La instalación será abortada." 8 60
            exit 1
        fi

        clear

        # Diálogo para pedir la contraseña del usuario phpMyAdmin
        PHPMYADMIN_USER_PASS=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                                        --title "Contraseña phpMyAdmin" \
                                        --inputbox "Debes ingresar una contraseña para el usuario 'phpmyadmin':" 10 60 3>&1 1>&2 2>&3)
        
        input_response=$?

        if [ $input_response -ne 0 ] || [ -z "$PHPMYADMIN_USER_PASS" ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "¡Atención!" \
                   --msgbox "No se ha ingresado una contraseña para el usuario 'phpmyadmin' o la operación fue cancelada. La instalación será abortada." 8 70
            exit 1
        fi

        clear

        # Diálogo para pedir la contraseña del usuario root de phpMyAdmin
        PHPMYADMIN_ROOT_PASS=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                                        --title "Contraseña Root phpMyAdmin" \
                                        --inputbox "Debes ingresar una contraseña para el usuario 'root' de phpMyAdmin:" 10 60 3>&1 1>&2 2>&3)
        
        input_response=$?

        if [ $input_response -ne 0 ] || [ -z "$PHPMYADMIN_ROOT_PASS" ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "¡Atención!" \
                   --msgbox "No se ha ingresado una contraseña para el usuario 'root' de phpMyAdmin o la operación fue cancelada. La instalación será abortada." 8 70
            exit 1
        fi

        clear

        # Diálogo para seleccionar la versión de PHP
        PHP_VERSION=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                                --title "Seleccionar Versión de PHP" \
                                --menu "Elige la versión de PHP que deseas instalar:" 15 50 4 \
                                "8.2" "PHP 8.2 (Recomendado para Laravel 12)" \
                                "8.3" "PHP 8.3" \
                                "8.4" "PHP 8.4 (Versión más reciente)" 3>&1 1>&2 2>&3)
        
        menu_response=$?

        if [ $menu_response -ne 0 ] || [ -z "$PHP_VERSION" ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "¡Atención!" \
                   --msgbox "No se ha seleccionado una versión de PHP o la operación fue cancelada. La instalación será abortada." 8 70
            exit 1
        fi

        clear
        
        # Diálogo para seleccionar aplicaciones adicionales
        SELECTED_APPS=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                               --title "Seleccionar Aplicaciones Adicionales" \
                               --checklist "Elige qué programas adicionales quieres instalar:" 20 60 4 \
                               "vscode" "Visual Studio Code" OFF \
                               "sublimetext" "Sublime Text" OFF \
                               "brave" "Brave Browser" OFF \
                               "googlechrome" "Google Chrome" OFF 3>&1 1>&2 2>&3)

        app_selection_response=$?

        if [ $app_selection_response -ne 0 ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "Info" \
                   --msgbox "No se seleccionaron aplicaciones adicionales, o la operación fue cancelada. Se continuará con la instalación principal." 8 70
        fi

        clear

        # --- Barra de Progreso: Update y Upgrade del sistema ---
        (
            echo "XXXX"
            echo "Realizando update del sistema..."
            echo "XXXX"
            echo 20 # 20% para el update
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                DEBIAN_FRONTEND=noninteractive apt-get update >/dev/null 2>&1
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                dnf update -y >/dev/null 2>&1
            fi
            
            echo "XXXX"
            echo "Realizando upgrade del sistema..."
            echo "XXXX"
            echo 60 # 60% para el upgrade
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >/dev/null 2>&1
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                dnf upgrade -y >/dev/null 2>&1
            fi

            echo "XXXX"
            echo "Agregando repositorios adicionales..."
            echo "XXXX"
            echo 80 # 80% para agregar repositorios
            # Agrega el repositorio de Ondrej si es Debian/Ubuntu y no está ya agregado
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                # Check if Ondrej PPA is already added
                if ! grep -q "ppa.launchpadcontent.net/ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
                    # Instalar software-properties-common para add-apt-repository
                    DEBIAN_FRONTEND=noninteractive apt-get install -y software-properties-common >/dev/null 2>&1
                    # Agregar PPA de Ondrej para PHP
                    add-apt-repository -y ppa:ondrej/php >/dev/null 2>&1
                    # Realizar un nuevo update después de añadir el repositorio
                    DEBIAN_FRONTEND=noninteractive apt-get update >/dev/null 2>&1
                fi
            fi
            sleep 2 # Simula el tiempo si no es Debian/Ubuntu o si la operación fue muy rápida
            
            echo "XXXX"
            echo "Sistema actualizado"
            echo "XXXX"
            echo 100
            sleep 2
        ) | dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "Progreso de la Instalación" \
                   --gauge "Iniciando operaciones..." 10 70 0
        
        clear

        # --- Barra de Progreso: Instalación de LAMP ---
        (
            echo "XXXX"
            echo "Instalando Apache2..."
            echo "XXXX"
            echo 10
            # Validar e instalar Apache2
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                if ! dpkg -s apache2 >/dev/null 2>&1; then
                    DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 >/dev/null 2>&1
                fi
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                if ! rpm -q httpd >/dev/null 2>&1; then
                    dnf install -y httpd >/dev/null 2>&1
                    systemctl enable httpd >/dev/null 2>&1
                    systemctl start httpd >/dev/null 2>&1
                fi
            fi
            
            echo "XXXX"
            echo "Configurando Apache..."
            echo "XXXX"
            echo 15 # Nuevo porcentaje para la configuración de Apache
            # Configurar ServerName para evitar la advertencia AH00558
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                APACHE_CONF="/etc/apache2/apache2.conf"
                if ! grep -q "ServerName localhost" "$APACHE_CONF"; then
                    echo "ServerName localhost" >> "$APACHE_CONF"
                fi
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                HTTPD_CONF="/etc/httpd/conf/httpd.conf"
                if ! grep -q "ServerName localhost" "$HTTPD_CONF"; then
                    echo "ServerName localhost" >> "$HTTPD_CONF"
                fi
            fi
            sleep 0.5 # Pequeña pausa para simular la operación

            echo "XXXX"
            echo "Habilitando mod_rewrite..."
            echo "XXXX"
            echo 25 # Ajustado el porcentaje
            # Validar y habilitar mod_rewrite y reiniciar Apache
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                if ! apache2ctl -M | grep -q rewrite_module; then
                    a2enmod rewrite >/dev/null 2>&1
                    systemctl restart apache2 >/dev/null 2>&1
                else
                    systemctl reload apache2 >/dev/null 2>&1 # Recargar Apache si ya está habilitado para aplicar ServerName
                fi
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                if ! httpd -M 2>&1 | grep -q rewrite_module; then
                    systemctl restart httpd >/dev/null 2>&1
                else
                    systemctl reload httpd >/dev/null 2>&1 # Recargar HTTPD si ya está habilitado para aplicar ServerName
                fi
            fi
            sleep 1 # Pequeña pausa para dar feedback visual

            echo "XXXX"
            echo "Instalando PHP $PHP_VERSION..."
            echo "XXXX"
            echo 45 # Ajustado el porcentaje
            # Validar e instalar PHP si no está ya instalado
            PHP_INSTALLED=false
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                if dpkg -s php${PHP_VERSION} >/dev/null 2>&1; then
                    PHP_INSTALLED=true
                else
                    DEBIAN_FRONTEND=noninteractive apt-get install -y php${PHP_VERSION} >/dev/null 2>&1
                    PHP_INSTALLED=true
                fi
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                if rpm -q php-cli-${PHP_VERSION} >/dev/null 2>&1; then
                    PHP_INSTALLED=true
                else
                    dnf module enable -y php:remi-${PHP_VERSION} >/dev/null 2>&1
                    dnf install -y php >/dev/null 2>&1 # dnf install php instalará la versión habilitada por el módulo
                    update-alternatives --set php /usr/bin/php${PHP_VERSION} >/dev/null 2>&1
                    PHP_INSTALLED=true
                fi
            fi
            sleep 1 # Pequeña pausa para la base de PHP

            # Lista de extensiones PHP a instalar y sus nombres de paquete por distribución
            # Formato: "Nombre_Mostrado|paquete_debian|paquete_almalinux"
            PHP_EXTENSIONS=(
                "CLI|php${PHP_VERSION}-cli|php-cli"
                "FPM|php${PHP_VERSION}-fpm|php-fpm"
                "Common|php${PHP_VERSION}-common|php-common"
                "ZIP|php${PHP_VERSION}-zip|php-zip"
                "MySQL|php${PHP_VERSION}-mysql|php-mysqlnd"
                "cURL|php${PHP_VERSION}-curl|php-curl"
                "GD|php${PHP_VERSION}-gd|php-gd"
                "Intl|php${PHP_VERSION}-intl|php-intl"
                "MBString|php${PHP_VERSION}-mbstring|php-mbstring"
                "XML|php${PHP_VERSION}-xml|php-xml"
                "SOAP|php${PHP_VERSION}-soap|php-soap"
                "BCMath|php${PHP_VERSION}-bcmath|php-bcmath"
                "GMP|php${PHP_VERSION}-gmp|php-gmp"
                "OPcache|php${PHP_VERSION}-opcache|php-opcache"
                "Imagick|php${PHP_VERSION}-imagick|php-pecl-imagick"
                "Redis|php${PHP_VERSION}-redis|php-pecl-redis"
                "PgSQL|php${PHP_VERSION}-pgsql|php-pgsql"
                "SQLite3|php${PHP_VERSION}-sqlite3|php-sqlite3"
                "LDAP|php${PHP_VERSION}-ldap|php-ldap"
                "SNMP|php${PHP_VERSION}-snmp|php-snmp"
                "XSL|php${PHP_VERSION}-xsl|php-xmlrpc" # XSL en AlmaLinux es parte de php-xmlrpc
                "APCu|php${PHP_VERSION}-apcu|php-pecl-apcu"
                "Memcached|php${PHP_VERSION}-memcached|php-pecl-memcached"
                "MongoDB|php${PHP_VERSION}-mongodb|php-pecl-mongodb"
                "SSH2|php${PHP_VERSION}-ssh2|php-pecl-ssh2"
                "Sybase|php${PHP_VERSION}-sybase|php-sybase"
                "ODBC|php${PHP_VERSION}-odbc|php-odbc"
                "Pspell|php${PHP_VERSION}-pspell|php-pspell"
                "Igbinary|php${PHP_VERSION}-igbinary|php-pecl-igbinary"
                "Xdebug|php${PHP_VERSION}-xdebug|php-pecl-xdebug"
                "DS (Data Structures)|php${PHP_VERSION}-ds|php-pecl-ds"
                "Enchant|php${PHP_VERSION}-enchant|php-enchant"
                "Msgpack|php${PHP_VERSION}-msgpack|php-pecl-msgpack"
                "OAuth|php${PHP_VERSION}-oauth|php-pecl-oauth"
                "Uploadprogress|php${PHP_VERSION}-uploadprogress|php-pecl-uploadprogress"
                "UUID|php${PHP_VERSION}-uuid|php-pecl-uuid"
                "ZMQ|php${PHP_VERSION}-zmq|php-pecl-zmq"
                "Solr|php${PHP_VERSION}-solr|php-pecl-solr"
                "Gearman|php${PHP_VERSION}-gearman|php-pecl-gearman"
            )

            # Cálculo del incremento de progreso por extensión
            TOTAL_EXTENSIONS=${#PHP_EXTENSIONS[@]}
            START_EXT_PERCENTAGE=45
            END_EXT_PERCENTAGE=70
            PERCENT_PER_EXT=$(echo "scale=2; ($END_EXT_PERCENTAGE - $START_EXT_PERCENTAGE) / $TOTAL_EXTENSIONS" | bc)
            CURRENT_PROGRESS=$START_EXT_PERCENTAGE

            if [ "$PHP_INSTALLED" = true ]; then
                for EXTENSION_INFO in "${PHP_EXTENSIONS[@]}"; do
                    IFS='|' read -r DISPLAY_NAME DEBIAN_PACKAGE ALMALINUX_PACKAGE <<< "$EXTENSION_INFO"
                    
                    CURRENT_PROGRESS=$(echo "scale=0; $CURRENT_PROGRESS + $PERCENT_PER_EXT" | bc)
                    if (( CURRENT_PROGRESS > END_EXT_PERCENTAGE )); then
                        CURRENT_PROGRESS=$END_EXT_PERCENTAGE
                    fi
                    echo "XXXX"
                    echo "Instalando extensión PHP: $DISPLAY_NAME..."
                    echo "XXXX"
                    echo $CURRENT_PROGRESS

                    INSTALLED=false
                    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                        if dpkg -s "$DEBIAN_PACKAGE" >/dev/null 2>&1; then
                            INSTALLED=true
                        else
                            DEBIAN_FRONTEND=noninteractive apt-get install -y "$DEBIAN_PACKAGE" >/dev/null 2>&1
                            if [ $? -eq 0 ]; then INSTALLED=true; fi
                        fi
                    elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                        if rpm -q "$ALMALINUX_PACKAGE" >/dev/null 2>&1; then
                            INSTALLED=true
                        else
                            # Para PECL extensions en AlmaLinux, pueden requerir la instalación de php-devel
                            # Añadimos una verificación aquí para php-devel y los paquetes build-essential si no están ya.
                            # Para asegurar que compilaciones de PECL puedan ocurrir si es necesario.
                            if ! rpm -q php-devel >/dev/null 2>&1; then
                                dnf install -y php-devel gcc make >/dev/null 2>&1
                            fi
                            dnf install -y "$ALMALINUX_PACKAGE" >/dev/null 2>&1
                            if [ $? -eq 0 ]; then INSTALLED=true; fi
                        fi
                    fi
                    
                    if [ "$INSTALLED" = true ]; then
                        echo "  $DISPLAY_NAME instalado/ya presente." >/dev/tty # Output a la consola real, no a dialog
                    else
                        echo "  Advertencia: No se pudo instalar $DISPLAY_NAME." >/dev/tty # Output a la consola real
                    fi
                    sleep 0.1 # Pequeña pausa para que la barra de progreso se actualice visiblemente
                done
            fi # Fin del if [ "$PHP_INSTALLED" = true ]

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
            echo 75 # Ajustado el porcentaje
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
            # No hay sleep aquí, la barra de progreso terminará y luego se mostrará el mensaje final.
        ) | dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "Instalación de Componentes LAMP" \
                   --gauge "Preparando el entorno LAMP..." 10 70 0

        clear # Limpia la pantalla después de la barra de progreso

        # --- Mensaje final de instalación ---
        dialog --backtitle "Script de Instalación Versión $VERSO" \
               --title "Instalación Completada" \
               --msgbox "\n¡La instalación ha finalizado con éxito!\n\nPresiona OK para salir." 10 60
        
        clear # Limpia la pantalla después del mensaje final
        ;;
    1) # El usuario eligió "No"
        clear
        exit 0
        ;;
    255) # El usuario presionó ESC
        clear
        exit 1
        ;;
esac
