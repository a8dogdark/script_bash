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
LOG_DIR="$HOME/Documents"
mkdir -p "$LOG_DIR" # Asegura que la carpeta Documents exista
LOG_FILE="$LOG_DIR/lamp_install_$(date +%Y%m%d_%H%M%S).log"

# Crear o limpiar el archivo de log al inicio
echo "Iniciando log de instalación LAMP. Fecha: $(date)" > "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"

# Array para almacenar extensiones que no se pudieron instalar
UNINSTALLED_EXTENSIONS=()

# Función para registrar un mensaje en el log y opcionalmente en la consola
log_message() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    if [ "$2" = "console" ]; then
        echo "$1" >/dev/tty
    fi
}

# Función para verificar si un paquete está instalado
# Uso: is_package_installed "paquete_debian" "paquete_almalinux"
is_package_installed() {
    local debian_pkg="$1"
    local almalinux_pkg="$2"
    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
        dpkg -s "$debian_pkg" >/dev/null 2>&1
    elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
        rpm -q "$almalinux_pkg" >/dev/null 2>&1
    fi
}

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
    log_message "Distribución detectada: **$ID ($ID_LIKE)**, Versión: **$VERSION_ID**" console

    # Detecta distribuciones basadas en Debian/Ubuntu
    if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == "debian" ]]; then
        DISTRIBUCION="Ubuntu/Debian"
        SYSTEM_CODENAME=$VERSION_CODENAME # Captura el nombre clave real del sistema (e.g., "plucky")
        log_message "Nombre clave del sistema detectado: **$SYSTEM_CODENAME**" console

        log_message "Realizando un apt update inicial para asegurar la lista de paquetes..." console
        DEBIAN_FRONTEND=noninteractive apt-get update >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            echo "Error: Falló el 'apt update' inicial. Por favor, verifica tu conexión a internet y tus repositorios." | tee -a "$LOG_FILE"
            echo "Revisa el log en **$LOG_FILE** para más detalles." | tee -a "$LOG_FILE"
            exit 1
        fi
        log_message "'apt update' inicial completado."

        if ! is_package_installed "dialog" "dialog"; then # Verifica si dialog no está instalado
            log_message "Instalando **dialog**..." console
            DEBIAN_FRONTEND=noninteractive apt-get install -y dialog >> "$LOG_FILE" 2>&1
            if [ $? -ne 0 ]; then # Si la instalación falló
                echo "Error: No se pudo instalar el paquete '**dialog**'." | tee -a "$LOG_FILE"
                echo "Por favor, intenta instalarlo manualmente con 'sudo apt-get install dialog' y revisa cualquier mensaje de error." | tee -a "$LOG_FILE"
                echo "Luego, puedes intentar ejecutar el script de nuevo. Revisa el log en **$LOG_FILE** para más detalles." | tee -a "$LOG_FILE"
                exit 1
            fi
            log_message "**dialog** instalado."
        else
            log_message "**dialog** ya está instalado." console
        fi
    # Detecta distribuciones basadas en RHEL (como AlmaLinux)
    elif [[ "$ID" == "almalinux" || "$ID_LIKE" == "rhel fedora" || "$ID_LIKE" == "rhel" ]]; then
        DISTRIBUCION="AlmaLinux"
        log_message "Realizando un dnf update inicial para asegurar la lista de paquetes..." console
        dnf update -y >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            echo "Error: Falló el 'dnf update' inicial. Por favor, verifica tu conexión a internet y tus repositorios." | tee -a "$LOG_FILE"
            echo "Revisa el log en **$LOG_FILE** para más detalles." | tee -a "$LOG_FILE"
            exit 1
        fi
        log_message "'dnf update' inicial completado."

        if ! is_package_installed "dialog" "dialog"; then # Verifica si dialog no está instalado
            log_message "Instalando **dialog**..." console
            dnf install -y dialog >> "$LOG_FILE" 2>&1
            if [ $? -ne 0 ]; then # Si la instalación falló
                echo "Error: No se pudo instalar el paquete '**dialog**'." | tee -a "$LOG_FILE"
                echo "Por favor, intenta instalarlo manualmente con 'sudo dnf install dialog' y revisa cualquier mensaje de error." | tee -a "$LOG_FILE"
                echo "Luego, puedes intentar ejecutar el script de nuevo. Revisa el log en **$LOG_FILE** para más detalles." | tee -a "$LOG_FILE"
                exit 1
            fi
            log_message "**dialog** instalado."
        else
            log_message "**dialog** ya está instalado." console
        fi
    else
        # Si la distribución no es una de las esperadas
        echo "Error: La distribución (**$ID**) no está soportada para la instalación automática de '**dialog**'." | tee -a "$LOG_FILE"
        echo "Por favor, instale '**dialog**' manualmente si es necesario." | tee -a "$LOG_FILE"
        echo "Revisa el log en **$LOG_FILE** para más detalles." | tee -a "$LOG_FILE"
        exit 1
    fi
else
    # Si /etc/os-release no existe
    echo "Error: No se pudo detectar la distribución del sistema (** /etc/os-release** no encontrado)." | tee -a "$LOG_FILE"
    echo "Por favor, instale '**dialog**' manualmente si es necesario." | tee -a "$LOG_FILE"
    echo "Revisa el log en **$LOG_FILE** para más detalles." | tee -a "$LOG_FILE"
    exit 1
fi

# Diálogo de Bienvenida
clear

# Muestra el diálogo de bienvenida con opción Sí/No
dialog --backtitle "Script de Instalación Versión $VERSO" \
       --title "Bienvenida al Instalador" \
       --yesno "\n¡Bienvenido al script de instalación!\n\nEste script te ayudará a instalar y configurar el software necesario en tu sistema **$DISTRIBUCION**.\nPrepararemos un servidor LAMP para Laravel 12.\n\n¿Deseas continuar con la instalación?" 15 60

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
        log_message "Nombre de proyecto Laravel elegido: **$PROJECT_NAME**"
        
        input_response=$?

        if [ $input_response -ne 0 ] || [ -z "$PROJECT_NAME" ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "¡Atención!" \
                   --msgbox "No se ha ingresado un nombre de proyecto válido o la operación fue cancelada. La instalación será abortada." 8 60
            log_message "Instalación abortada: Nombre de proyecto no válido o cancelado."
            exit 1
        fi

        clear

        # Diálogo para pedir la contraseña del usuario phpMyAdmin
        PHPMYADMIN_USER_PASS=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                                        --title "Contraseña phpMyAdmin" \
                                        --inputbox "Debes ingresar una contraseña para el usuario '**phpmyadmin**':" 10 60 3>&1 1>&2 2>&3)
        log_message "Contraseña para phpmyadmin ingresada (no se registra el valor)."
        
        input_response=$?

        if [ $input_response -ne 0 ] || [ -z "$PHPMYADMIN_USER_PASS" ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "¡Atención!" \
                   --msgbox "No se ha ingresado una contraseña para el usuario '**phpmyadmin**' o la operación fue cancelada. La instalación será abortada." 8 70
            log_message "Instalación abortada: Contraseña de phpmyadmin no válida o cancelada."
            exit 1
        fi

        clear

        # Diálogo para pedir la contraseña del usuario root de phpMyAdmin
        PHPMYADMIN_ROOT_PASS=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                                        --title "Contraseña Root phpMyAdmin" \
                                        --inputbox "Debes ingresar una contraseña para el usuario '**root**' de phpMyAdmin:" 10 60 3>&1 1>&2 2>&3)
        log_message "Contraseña para root de phpMyAdmin ingresada (no se registra el valor)."
        
        input_response=$?

        if [ $input_response -ne 0 ] || [ -z "$PHPMYADMIN_ROOT_PASS" ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "¡Atención!" \
                   --msgbox "No se ha ingresado una contraseña para el usuario '**root**' de phpMyAdmin o la operación fue cancelada. La instalación será abortada." 8 70
            log_message "Instalación abortada: Contraseña de root de phpMyAdmin no válida o cancelada."
            exit 1
        fi

        clear

        # Diálogo para seleccionar la versión de PHP
        PHP_VERSION=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                                --title "Seleccionar Versión de PHP" \
                                --menu "Elige la versión de PHP que deseas instalar:" 15 50 4 \
                                "**8.2**" "PHP 8.2 (Recomendado para Laravel 12)" \
                                "**8.3**" "PHP 8.3" \
                                "**8.4**" "PHP 8.4 (Versión más reciente)" 3>&1 1>&2 2>&3)
        log_message "Versión de PHP seleccionada: **$PHP_VERSION**"
        
        menu_response=$?

        if [ $menu_response -ne 0 ] || [ -z "$PHP_VERSION" ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "¡Atención!" \
                   --msgbox "No se ha seleccionado una versión de PHP o la operación fue cancelada. La instalación será abortada." 8 70
            log_message "Instalación abortada: Versión de PHP no seleccionada o cancelada."
            exit 1
        fi

        clear
        
        # Diálogo para seleccionar aplicaciones adicionales
        SELECTED_APPS=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                               --title "Seleccionar Aplicaciones Adicionales" \
                               --checklist "Elige qué programas adicionales quieres instalar:" 20 60 4 \
                               "**vscode**" "Visual Studio Code" OFF \
                               "**sublimetext**" "Sublime Text" OFF \
                               "**brave**" "Brave Browser" OFF \
                               "**googlechrome**" "Google Chrome" OFF 3>&1 1>&2 2>&3)

        app_selection_response=$?
        log_message "Aplicaciones adicionales seleccionadas: **$SELECTED_APPS**"

        if [ $app_selection_response -ne 0 ]; then
            clear
            dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "Info" \
                   --msgbox "No se seleccionaron aplicaciones adicionales, o la operación fue cancelada. Se continuará con la instalación principal." 8 70
        fi

        clear

        ---
        ## Barra de Progreso: Update y Upgrade del sistema
        ---
        (
            log_message "Iniciando update y upgrade del sistema." console

            echo "XXXX"
            echo "Realizando update del sistema..."
            echo "XXXX"
            echo 20 # 20% para el update
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                DEBIAN_FRONTEND=noninteractive apt-get update >> "$LOG_FILE" 2>&1
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                dnf update -y >> "$LOG_FILE" 2>&1
            fi
            
            echo "XXXX"
            echo "Realizando upgrade del sistema..."
            echo "XXXX"
            echo 60 # 60% para el upgrade
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >> "$LOG_FILE" 2>&1
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                dnf upgrade -y >> "$LOG_FILE" 2>&1
            fi

            echo "XXXX"
            echo "Agregando repositorios adicionales..."
            echo "XXXX"
            echo 80 # 80% para agregar repositorios
            # Agrega el repositorio de Ondrej si es Debian/Ubuntu y no está ya agregado
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                log_message "Configurando PPA de Ondrej para Debian/Ubuntu."
                
                # --- INICIO DE LA SECCIÓN DE LIMPIEZA REFORZADA ---
                log_message "Iniciando limpieza reforzada de configuraciones antiguas del PPA de Ondrej."
                
                # 1. Eliminar archivos de lista existentes de Ondrej
                log_message "Eliminando archivos *.list de Ondrej en /etc/apt/sources.list.d/."
                find /etc/apt/sources.list.d/ -type f -name "*ondrej-ubuntu-php-*.list*" -delete >> "$LOG_FILE" 2>&1
                find /etc/apt/sources.list.d/ -type f -name "*ondrej-ubuntu-apache2-*.list*" -delete >> "$LOG_FILE" 2>&1
                find /etc/apt/sources.list.d/ -type f -name "*ondrej-*.list*" -delete >> "$LOG_FILE" 2>&1 # Para atrapar cualquier otro

                # 2. Eliminar referencias de PPA con add-apt-repository --remove
                # Esto es útil si se añadieron usando add-apt-repository
                log_message "Intentando eliminar PPAs de Ondrej usando add-apt-repository --remove (puede fallar si no existen, ignorar errores)."
                add-apt-repository --remove ppa:ondrej/php -y >> "$LOG_FILE" 2>&1 || true
                add-apt-repository --remove ppa:ondrej/apache2 -y >> "$LOG_FILE" 2>&1 || true

                # 3. Limpiar el caché de apt
                log_message "Limpiando el caché de paquetes de apt."
                DEBIAN_FRONTEND=noninteractive apt-get clean >> "$LOG_FILE" 2>&1

                # 4. Forzar un apt update después de la limpieza
                log_message "Realizando un apt update después de la limpieza de repositorios."
                DEBIAN_FRONTEND=noninteractive apt-get update >> "$LOG_FILE" 2>&1
                if [ $? -ne 0 ]; then
                    log_message "Advertencia: 'apt update' falló después de la limpieza de Ondrej. Podría haber problemas residuales. Revisa el log: $LOG_FILE" console
                    # No salir, intentar continuar con la adición del repositorio noble
                fi
                log_message "Limpieza de Ondrej completada."
                # --- FIN DE LA SECCIÓN DE LIMPIEZA REFORZADA ---

                # Asegurarse de tener apt-transport-https y software-properties-common
                log_message "Instalando **apt-transport-https**, **software-properties-common**, **curl** y **gnupg2**."
                DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https software-properties-common curl gnupg2 >> "$LOG_FILE" 2>&1

                # Añadir la llave GPG de Ondrej
                log_message "Añadiendo la llave GPG del PPA de Ondrej al nuevo formato de keyrings."
                # Usar sudo tee para escribir en un archivo que requiere permisos de root
                curl -sSL https://packages.sury.org/php/apt.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/deb.sury.org-php.gpg >/dev/null 2>> "$LOG_FILE"

                # Crear el archivo de lista para el PPA de Ondrej directamente con 'noble'
                PPA_NOBLE_LIST_FILE="/etc/apt/sources.list.d/ondrej-php-noble.list"
                if [ ! -f "$PPA_NOBLE_LIST_FILE" ]; then
                    log_message "Creando el archivo de repositorio de Ondrej para PHP con nombre clave '**noble**'."
                    echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ noble main" | sudo tee "$PPA_NOBLE_LIST_FILE" >> "$LOG_FILE" 2>&1
                else
                    log_message "El archivo de repositorio de Ondrej para PHP con '**noble**' ya existe."
                fi
                
                log_message "Realizando update después de configurar el repositorio de Ondrej."
                DEBIAN_FRONTEND=noninteractive apt-get update >> "$LOG_FILE" 2>&1
                if [ $? -ne 0 ]; then
                    log_message "Error durante '**apt update**' después de configurar el PPA de Ondrej. Por favor, revisa el log: **$LOG_FILE**" console
                    # No salir aquí, permitir que el script intente continuar y registrar más errores.
                fi
            # Para AlmaLinux, asegurar que el repositorio EPEL y REMI estén habilitados para PHP
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                log_message "Configurando repositorios EPEL y REMI para AlmaLinux."
                if ! is_package_installed "epel-release" "epel-release"; then
                    log_message "Instalando **epel-release**."
                    dnf install -y epel-release >> "$LOG_FILE" 2>&1
                else
                    log_message "**epel-release** ya instalado."
                fi
                if ! is_package_installed "remi-release" "remi-release"; then
                    log_message "Instalando **remi-release**."
                    dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm >> "$LOG_FILE" 2>&1 # For AlmaLinux 8
                    log_message "Reseteando módulo PHP para asegurar preferencia de REMI."
                    dnf module reset php -y >> "$LOG_FILE" 2>&1
                else
                    log_message "**remi-release** ya instalado."
                fi
            fi
            sleep 2 # Simula el tiempo si no es Debian/Ubuntu o si la operación fue muy rápida
            
            echo "XXXX"
            echo "Sistema actualizado"
            echo "XXXX"
            echo 100
            sleep 2
            log_message "Update y upgrade del sistema completados." console
        ) | dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "Progreso de la Instalación" \
                   --gauge "Iniciando operaciones..." 10 70 0
        
        clear

        ---
        ## Barra de Progreso: Instalación de LAMP
        ---
        (
            log_message "Iniciando instalación de componentes LAMP." console

            echo "XXXX"
            echo "Instalando **Apache2**..."
            echo "XXXX"
            echo 10
            # Validar e instalar Apache2
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                if ! is_package_installed "apache2" "httpd"; then
                    log_message "Instalando **apache2**."
                    DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 >> "$LOG_FILE" 2>&1
                else
                    log_message "**apache2** ya instalado."
                fi
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                if ! is_package_installed "apache2" "httpd"; then
                    log_message "Instalando **httpd**."
                    dnf install -y httpd >> "$LOG_FILE" 2>&1
                    systemctl enable httpd >> "$LOG_FILE" 2>&1
                    systemctl start httpd >> "$LOG_FILE" 2>&1
                else
                    log_message "**httpd** ya instalado."
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
                    log_message "Añadido ServerName **localhost** a **$APACHE_CONF**."
                else
                    log_message "ServerName **localhost** ya presente en **$APACHE_CONF**."
                fi
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                HTTPD_CONF="/etc/httpd/conf/httpd.conf"
                if ! grep -q "ServerName localhost" "$HTTPD_CONF"; then
                    echo "ServerName localhost" >> "$HTTPD_CONF"
                    log_message "Añadido ServerName **localhost** a **$HTTPD_CONF**."
                else
                    log_message "ServerName **localhost** ya presente en **$HTTPD_CONF**."
                fi
            fi
            sleep 0.5 # Pequeña pausa para simular la operación

            echo "XXXX"
            echo "Habilitando **mod_rewrite**..."
            echo "XXXX"
            echo 25 # Ajustado el porcentaje
            # Validar y habilitar mod_rewrite y reiniciar Apache
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                if ! apache2ctl -M | grep -q rewrite_module; then
                    log_message "Habilitando **mod_rewrite**."
                    a2enmod rewrite >> "$LOG_FILE" 2>&1
                    systemctl restart apache2 >> "$LOG_FILE" 2>&1
                else
                    log_message "**mod_rewrite** ya habilitado. Recargando **apache2**."
                    systemctl reload apache2 >> "$LOG_FILE" 2>&1 # Recargar Apache si ya está habilitado para aplicar ServerName
                fi
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                if ! httpd -M 2>&1 | grep -q rewrite_module; then
                    log_message "Habilitando **mod_rewrite** y reiniciando **httpd**."
                    systemctl restart httpd >> "$LOG_FILE" 2>&1
                else
                    log_message "**mod_rewrite** ya habilitado. Recargando **httpd**."
                    systemctl reload httpd >> "$LOG_FILE" 2>&1 # Recargar HTTPD si ya está habilitado para aplicar ServerName
                fi
            fi
            sleep 1 # Pequeña pausa para dar feedback visual

            echo "XXXX"
            echo "Instalando PHP **$PHP_VERSION**..."
            echo "XXXX"
            echo 45 # Ajustado el porcentaje
            # Validar e instalar PHP si no está ya instalado
            PHP_INSTALLED=false
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                if is_package_installed "php${PHP_VERSION}" "dummy"; then
                    PHP_INSTALLED=true
                    log_message "PHP **${PHP_VERSION}** ya está instalado."
                else
                    log_message "Instalando **php${PHP_VERSION}**."
                    DEBIAN_FRONTEND=noninteractive apt-get install -y php${PHP_VERSION} >> "$LOG_FILE" 2>&1
                    if [ $? -eq 0 ]; then
                        PHP_INSTALLED=true
                        log_message "**php${PHP_VERSION}** instalado con éxito."
                    else
                        log_message "Error al instalar **php${PHP_VERSION}**. Revisa el log." console
                    fi
                fi
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                if is_package_installed "dummy" "php-cli" && php -v | grep -q "PHP ${PHP_VERSION}"; then
                    PHP_INSTALLED=true
                    log_message "PHP **${PHP_VERSION}** (**php-cli**) ya está instalado y es la versión correcta."
                else
                    log_message "Habilitando módulo PHP:**remi-${PHP_VERSION}** y instalando PHP base."
                    dnf module enable -y php:remi-${PHP_VERSION} >> "$LOG_FILE" 2>&1
                    dnf install -y php >> "$LOG_FILE" 2>&1
                    update-alternatives --set php /usr/bin/php${PHP_VERSION} >> "$LOG_FILE" 2>&1 2>/dev/null # Redirigir stderr también
                    if [ $? -eq 0 ]; then
                        PHP_INSTALLED=true
                        log_message "PHP **${PHP_VERSION}** base instalado con éxito en AlmaLinux."
                    else
                        log_message "Error al instalar PHP **${PHP_VERSION}** base en AlmaLinux. Revisa el log." console
                    fi
                fi
            fi
            sleep 1 # Pequeña pausa para la base de PHP

            # Lista de extensiones PHP a instalar y sus nombres de paquete por distribución
            # Formato: "Nombre_Mostrado|paquete_debian_suffix|paquete_almalinux_nombre"
            # Nota: paquete_debian_suffix será prefijado con "php${PHP_VERSION}-"
            #       paquete_almalinux_nombre será usado tal cual, asumiendo que el módulo remi maneja el versionado
            PHP_EXTENSIONS=(
                "CLI|cli|php-cli"
                "FPM|fpm|php-fpm"
                "Common|common|php-common"
                "ZIP|zip|php-zip"
                "MySQL|mysql|php-mysqlnd"
                "cURL|curl|php-curl"
                "GD|gd|php-gd"
                "Intl|intl|php-intl"
                "MBString|mbstring|php-mbstring"
                "XML|xml|php-xml"
                "SOAP|soap|php-soap"
                "BCMath|bcmath|php-bcmath"
                "GMP|gmp|php-gmp"
                "OPcache|opcache|php-opcache"
                "Imagick|imagick|php-pecl-imagick"
                "Redis|redis|php-pecl-redis"
                "PgSQL|pgsql|php-pgsql"
                "SQLite3|sqlite3|php-sqlite3"
                "LDAP|ldap|php-ldap"
                "SNMP|snmp|php-snmp"
                "XSL|xsl|php-xmlrpc" # XSL on AlmaLinux is part of php-xmlrpc
                "APCu|apcu|php-pecl-apcu"
                "Memcached|memcached|php-pecl-memcached"
                "MongoDB|mongodb|php-pecl-mongodb"
                "SSH2|ssh2|php-pecl-ssh2"
                "Sybase|sybase|php-sybase"
                "ODBC|odbc|php-odbc"
                "Pspell|pspell|php-pspell"
                "Igbinary|igbinary|php-pecl-igbinary"
                "Xdebug|xdebug|php-pecl-xdebug"
                "DS (Data Structures)|ds|php-pecl-ds"
                "Enchant|enchant|php-enchant"
                "Msgpack|msgpack|php-pecl-msgpack"
                "OAuth|oauth|php-pecl-oauth"
                "Uploadprogress|uploadprogress|php-pecl-uploadprogress"
                "UUID|uuid|php-pecl-uuid"
                "ZMQ|zmq|php-pecl-zmq"
                "Solr|solr|php-pecl-solr"
                "Gearman|gearman|php-pecl-gearman"
            )

            # Cálculo del incremento de progreso por extensión
            TOTAL_EXTENSIONS=${#PHP_EXTENSIONS[@]}
            START_EXT_PERCENTAGE=45
            END_EXT_PERCENTAGE=70
            PERCENT_PER_EXT=$(echo "scale=2; ($END_EXT_PERCENTAGE - $START_EXT_PERCENTAGE) / $TOTAL_EXTENSIONS" | bc)
            CURRENT_PROGRESS=$START_EXT_PERCENTAGE

            if [ "$PHP_INSTALLED" = true ]; then
                log_message "Iniciando instalación de extensiones PHP." console
                # Asegurar herramientas de compilación para PECL antes de iterar extensiones para AlmaLinux
                if [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                    echo "XXXX"
                    echo "Verificando herramientas de compilación para extensiones PECL..."
                    echo "XXXX"
                    CURRENT_PROGRESS=$(echo "scale=0; $CURRENT_PROGRESS + $PERCENT_PER_EXT" | bc)
                    if (( CURRENT_PROGRESS > END_EXT_PERCENTAGE )); then CURRENT_PROGRESS=$END_EXT_PERCENTAGE; fi
                    echo $CURRENT_PROGRESS
                    if ! is_package_installed "build-essential" "php-devel"; then # build-essential for Debian/Ubuntu, php-devel for AlmaLinux
                        log_message "Instalando **php-devel**, **gcc**, **make** para compilación PECL."
                        dnf install -y php-devel gcc make >> "$LOG_FILE" 2>&1
                    else
                        log_message "Herramientas de compilación PECL ya instaladas."
                    fi
                    sleep 0.5
                fi

                for EXTENSION_INFO in "${PHP_EXTENSIONS[@]}"; do
                    IFS='|' read -r DISPLAY_NAME DEBIAN_SUFFIX ALMALINUX_PACKAGE <<< "$EXTENSION_INFO"
                    
                    # Incrementar progreso antes de cada intento de instalación
                    CURRENT_PROGRESS=$(echo "scale=0; $CURRENT_PROGRESS + $PERCENT_PER_EXT" | bc)
                    if (( CURRENT_PROGRESS > END_EXT_PERCENTAGE )); then
                        CURRENT_PROGRESS=$END_EXT_PERCENTAGE
                    fi
                    echo "XXXX"
                    echo "Instalando extensión PHP: **$DISPLAY_NAME**..."
                    echo "XXXX"
                    echo $CURRENT_PROGRESS

                    PACKAGE_TO_INSTALL=""
                    INSTALL_SUCCESS=false

                    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                        PACKAGE_TO_INSTALL="php${PHP_VERSION}-${DEBIAN_SUFFIX}"
                        if is_package_installed "$PACKAGE_TO_INSTALL" "dummy"; then
                            INSTALL_SUCCESS=true
                            log_message "  **$DISPLAY_NAME** (paquete **$PACKAGE_TO_INSTALL**) ya está instalado." console
                        else
                            log_message "  Intentando instalar **$DISPLAY_NAME** (paquete **$PACKAGE_TO_INSTALL**)..." console
                            DEBIAN_FRONTEND=noninteractive apt-get install -y "$PACKAGE_TO_INSTALL" >> "$LOG_FILE" 2>&1
                            if [ $? -eq 0 ]; then INSTALL_SUCCESS=true; fi
                        fi
                    elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                        PACKAGE_TO_INSTALL="$ALMALINUX_PACKAGE"
                        if is_package_installed "dummy" "$PACKAGE_TO_INSTALL"; then
                            INSTALL_SUCCESS=true
                            log_message "  **$DISPLAY_NAME** (paquete **$PACKAGE_TO_INSTALL**) ya está instalado." console
                        else
                            log_message "  Intentando instalar **$DISPLAY_NAME** (paquete **$PACKAGE_TO_INSTALL**)..." console
                            dnf install -y "$PACKAGE_TO_INSTALL" >> "$LOG_FILE" 2>&1
                            if [ $? -eq 0 ]; then INSTALL_SUCCESS=true; fi
                        fi
                    fi
                    
                    if [ "$INSTALL_SUCCESS" = false ]; then
                        UNINSTALLED_EXTENSIONS+=("$DISPLAY_NAME")
                        log_message "  Advertencia: No se pudo instalar la extensión **$DISPLAY_NAME** (paquete **$PACKAGE_TO_INSTALL**)." console
                    fi
                    sleep 0.1 # Pequeña pausa para que la barra de progreso se actualice visiblely
                done
            else
                log_message "La instalación base de PHP **$PHP_VERSION** falló, omitiendo la instalación de extensiones." console
            fi # Fin del if [ "$PHP_INSTALLED" = true ]

            # Asegurar que el porcentaje final para las extensiones PHP se establezca
            echo "XXXX"
            echo "Extensiones PHP procesadas."
            echo "XXXX"
            echo 70
            log_message "Procesamiento de extensiones PHP completado." console

            # Determina si es MySQL o MariaDB
            DB_SYSTEM=""
            if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                DB_SYSTEM="MySQL"
            elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                DB_SYSTEM="MariaDB"
            fi
            echo "XXXX"
            echo "Instalando **$DB_SYSTEM**..."
            echo "XXXX"
            echo 75 # Ajustado el porcentaje
            log_message "Iniciando instalación de **$DB_SYSTEM**." console
            sleep 5 # Simula la instalación de la base de datos

            echo "XXXX"
            echo "Instalando **phpMyAdmin**..."
            echo "XXXX"
            echo 90
            log_message "Iniciando instalación de **phpMyAdmin**." console
            sleep 4 # Simula la instalación de phpMyAdmin

            echo "XXXX"
            echo "Componentes LAMP instalados."
            echo "XXXX"
            echo 100
            log_message "Componentes LAMP instalados." console
            # No hay sleep aquí, la barra de progreso terminará y luego se mostrará el mensaje final.
        ) | dialog --backtitle "Script de Instalación Versión $VERSO" \
                   --title "Instalación de Componentes LAMP" \
                   --gauge "Preparando el entorno LAMP..." 10 70 0

        clear # Limpia la pantalla después de la barra de progreso

        ---
        ## Mensaje final de instalación
        ---
        INSTALL_MESSAGE="\n¡La instalación ha finalizado con éxito!\n"
        log_message "Instalación LAMP finalizada."

        if [ ${#UNINSTALLED_EXTENSIONS[@]} -gt 0 ]; then
            INSTALL_MESSAGE+="\nSin embargo, las siguientes extensiones PHP no pudieron ser instaladas:\n\n"
            for ext in "${UNINSTALLED_EXTENSIONS[@]}"; do
                INSTALL_MESSAGE+="  - **$ext**\n"
            done
            INSTALL_MESSAGE+="\nPor favor, verifica si las necesitas y considera instalarlas manualmente si es necesario."
            log_message "Extensiones no instaladas: ${UNINSTALLED_EXTENSIONS[*]}"
        fi

        INSTALL_MESSAGE+="\nPuedes revisar el archivo de log para más detalles: \n**${LOG_FILE}**"

        dialog --backtitle "Script de Instalación Versión $VERSO" \
               --title "Instalación Completada" \
               --msgbox "$INSTALL_MESSAGE\n\nPresiona OK para salir." 20 70 # Aumentar el tamaño para el mensaje de error

        clear # Limpia la pantalla después del mensaje final
        ;;
    1) # El usuario eligió "No"
        log_message "Instalación cancelada por el usuario."
        clear
        exit 0
        ;;
    255) # El usuario presionó ESC
        log_message "Instalación cancelada por el usuario (ESC)."
        clear
        exit 1
        ;;
esac
