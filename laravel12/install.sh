#!/bin/bash

# ==============================================================================
# Script de Instalación de Servidor LAMP para Laravel 12
# Versión: 2.2 (Optimización de Output en Consola)
# Compatibilidad:
#   - Ubuntu: 20.04 LTS (focal), 21.x, 22.04 LTS (jammy), 23.x, 24.04 LTS (noble)
#   - Debian: 11 (bullseye), 12 (bookworm)
#   - AlmaLinux: 8, 9
# ==============================================================================

# --- Variables Globales ---
DISTRIBUCION=""          # Almacena "Ubuntu/Debian" o "AlmaLinux"
SYSTEM_CODENAME=""       # Nombre clave de la distribución (e.g., noble, jammy, bullseye)
VERSO="2.2"              # Versión del script
PROJECT_NAME=""          # Nombre del proyecto Laravel
PHPMYADMIN_USER_PASS=""  # Contraseña del usuario phpMyAdmin
PHPMYADMIN_ROOT_PASS=""  # Contraseña del usuario root de phpMyAdmin (MySQL/MariaDB)
PHP_VERSION=""           # Versión de PHP seleccionada por el usuario (e.g., 8.2, 8.3, 8.4)
SELECTED_APPS=""         # Aplicaciones adicionales seleccionadas

# --- Configuración de Log ---
LOG_DIR="/tmp"
mkdir -p "$LOG_DIR" # Asegura que la carpeta /tmp exista
LOG_FILE="$LOG_DIR/lamp_install_$(date +%Y%m%d_%H%M%S).log"

# --- Arrays para el control de la instalación ---
UNINSTALLED_EXTENSIONS=() # Almacena extensiones PHP que no se pudieron instalar

# --- Funciones Auxiliares ---

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

# --- Validaciones Iniciales ---

# Validación de usuario root
if [ "$(id -u)" -ne 0 ]; then
    clear
    log_message "Error: Este script debe ejecutarse como usuario root." console
    exit 1
fi

# Validación de arquitectura de 64 bits
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "aarch64" ]; then
    clear
    log_message "Error: Este script solo se puede ejecutar en sistemas de 64 bits (x86_64 o aarch64)." console
    exit 1
fi

# Creación y limpieza del archivo de log al inicio
echo "Iniciando log de instalación LAMP. Fecha: $(date)" > "$LOG_FILE"
echo "===============================================" >> "$LOG_FILE"

# --- Detección de Distribución e Instalación de 'dialog' ---
log_message "Detectando distribución del sistema y verificando 'dialog'." console

if [ -f /etc/os-release ]; then
    . /etc/os-release # Carga las variables de identificación del sistema

    if [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == "debian" ]]; then
        DISTRIBUCION="Ubuntu/Debian"
        SYSTEM_CODENAME=$(lsb_release -cs 2>/dev/null || echo "$VERSION_CODENAME") # Captura el nombre clave
        if [ -z "$SYSTEM_CODENAME" ]; then
            log_message "Error: No se pudo determinar el nombre clave de la distribución. Abortando." console
            exit 1
        fi
        log_message "Distribución detectada: $ID ($ID_LIKE), Versión: $VERSION_ID, Nombre clave: $SYSTEM_CODENAME" console

        if ! is_package_installed "dialog" "dialog"; then
            log_message "Instalando dialog en Ubuntu/Debian..." console
            DEBIAN_FRONTEND=noninteractive apt-get update >> "$LOG_FILE" 2>&1
            DEBIAN_FRONTEND=noninteractive apt-get install -y dialog >> "$LOG_FILE" 2>&1
            if [ $? -ne 0 ]; then
                log_message "Error: No se pudo instalar el paquete 'dialog'. Por favor, intenta instalarlo manualmente con 'sudo apt-get install dialog' y revisa cualquier mensaje de error." console
                exit 1
            fi
            log_message "dialog instalado."
        else
            log_message "dialog ya está instalado en Ubuntu/Debian." console
        fi
    elif [[ "$ID" == "almalinux" || "$ID_LIKE" == "rhel fedora" || "$ID_LIKE" == "rhel" ]]; then
        DISTRIBUCION="AlmaLinux"
        log_message "Distribución detectada: $ID ($ID_LIKE), Versión: $VERSION_ID" console

        if ! is_package_installed "dialog" "dialog"; then
            log_message "Instalando dialog en AlmaLinux..." console
            dnf update -y >> "$LOG_FILE" 2>&1
            dnf install -y dialog >> "$LOG_FILE" 2>&1
            if [ $? -ne 0 ]; then
                log_message "Error: No se pudo instalar el paquete 'dialog'. Por favor, intenta instalarlo manualmente con 'sudo dnf install dialog' y revisa cualquier mensaje de error." console
                exit 1
            fi
            log_message "dialog instalado."
        else
            log_message "dialog ya está instalado en AlmaLinux." console
        fi
    else
        log_message "Error: La distribución ($ID) no está soportada por este script." console
        exit 1
    fi
else
    log_message "Error: No se pudo detectar la distribución del sistema (/etc/os-release no encontrado)." console
    exit 1
fi

# --- Diálogos de Entrada de Usuario ---

clear

# Diálogo de Bienvenida
dialog --backtitle "Script de Instalación Versión $VERSO" \
       --title "Bienvenida al Instalador" \
       --yesno "\n¡Bienvenido al script de instalación LAMP!\n\nEste script te ayudará a instalar y configurar el software necesario en tu sistema $DISTRIBUCION.\nPrepararemos un servidor LAMP para Laravel 12.\n\n¿Deseas continuar con la instalación?" 15 60
response=$?
if [ $response -ne 0 ]; then # El usuario eligió "No" o presionó ESC
    log_message "Instalación cancelada por el usuario en el diálogo de bienvenida."
    dialog --backtitle "Script de Instalación Versión $VERSO" --title "Cancelado" --msgbox "La instalación ha sido cancelada." 5 40
    clear
    exit 0
fi

# Diálogo para el nombre del proyecto Laravel
PROJECT_NAME=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                        --title "Nombre del Proyecto Laravel" \
                        --inputbox "Por favor, ingresa el nombre que deseas para tu proyecto Laravel 12 (ej. mi_proyecto):" 10 60 3>&1 1>&2 2>&3)
if [ $? -ne 0 ] || [ -z "$PROJECT_NAME" ]; then
    log_message "Instalación abortada: Nombre de proyecto no válido o cancelado."
    dialog --backtitle "Script de Instalación Versión $VERSO" --title "¡Atención!" --msgbox "No se ha ingresado un nombre de proyecto válido o la operación fue cancelada. La instalación será abortada." 8 60
    clear
    exit 1
fi
log_message "Nombre de proyecto Laravel elegido: $PROJECT_NAME"

# Diálogo para la contraseña del usuario phpMyAdmin
PHPMYADMIN_USER_PASS=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                                --title "Contraseña phpMyAdmin" \
                                --inputbox "Debes ingresar una contraseña para el usuario 'phpmyadmin':" 10 60 3>&1 1>&2 2>&3)
if [ $? -ne 0 ] || [ -z "$PHPMYADMIN_USER_PASS" ]; then
    log_message "Instalación abortada: Contraseña de phpmyadmin no válida o cancelada."
    dialog --backtitle "Script de Instalación Versión $VERSO" --title "¡Atención!" --msgbox "No se ha ingresado una contraseña para el usuario 'phpmyadmin' o la operación fue cancelada. La instalación será abortada." 8 70
    clear
    exit 1
fi
log_message "Contraseña para phpmyadmin ingresada (no se registra el valor)."

# Diálogo para la contraseña del usuario root de phpMyAdmin (MySQL/MariaDB root)
PHPMYADMIN_ROOT_PASS=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                                --title "Contraseña Root MySQL/MariaDB" \
                                --inputbox "Debes ingresar una contraseña para el usuario 'root' de MySQL/MariaDB:" 10 60 3>&1 1>&2 2>&3)
if [ $? -ne 0 ] || [ -z "$PHPMYADMIN_ROOT_PASS" ]; then
    log_message "Instalación abortada: Contraseña de root de MySQL/MariaDB no válida o cancelada."
    dialog --backtitle "Script de Instalación Versión $VERSO" --title "¡Atención!" --msgbox "No se ha ingresado una contraseña para el usuario 'root' de MySQL/MariaDB o la operación fue cancelada. La instalación será abortada." 8 70
    clear
    exit 1
fi
log_message "Contraseña para root de MySQL/MariaDB ingresada (no se registra el valor)."

# Diálogo para seleccionar la versión de PHP
PHP_VERSION=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                        --title "Seleccionar Versión de PHP" \
                        --menu "Elige la versión de PHP que deseas instalar:" 15 50 4 \
                        "8.2" "PHP 8.2 (Compatible con Laravel 12)" \
                        "8.3" "PHP 8.3 (Compatible con Laravel 12)" \
                        "8.4" "PHP 8.4 (Versión más reciente, compatible con Laravel 12)" 3>&1 1>&2 2>&3)
if [ $? -ne 0 ] || [ -z "$PHP_VERSION" ]; then
    log_message "Instalación abortada: Versión de PHP no seleccionada o cancelada."
    dialog --backtitle "Script de Instalación Versión $VERSO" --title "¡Atención!" --msgbox "No se ha seleccionado una versión de PHP o la operación fue cancelada. La instalación será abortada." 8 70
    clear
    exit 1
fi
log_message "Versión de PHP seleccionada: $PHP_VERSION"

# Diálogo para seleccionar aplicaciones adicionales
SELECTED_APPS=$(dialog --backtitle "Script de Instalación Versión $VERSO" \
                        --title "Seleccionar Aplicaciones Adicionales" \
                        --checklist "Elige qué programas adicionales quieres instalar:" 20 60 4 \
                        "vscode" "Visual Studio Code" OFF \
                        "sublimetext" "Sublime Text" OFF \
                        "brave" "Brave Browser" OFF \
                        "googlechrome" "Google Chrome" OFF 3>&1 1>&2 2>&3)
# No es un error crítico si no se seleccionan apps adicionales o se cancela.
log_message "Aplicaciones adicionales seleccionadas: $SELECTED_APPS"

clear

# --- SECCIÓN DE INSTALACIÓN PRINCIPAL (Barra de Progreso) ---
(
    log_message "Iniciando update y upgrade del sistema." console

    echo "XXXX"
    echo "Realizando update del sistema..."
    echo "XXXX"
    echo 10
    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
        DEBIAN_FRONTEND=noninteractive apt-get update >> "$LOG_FILE" 2>&1
    elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
        dnf update -y >> "$LOG_FILE" 2>&1
    fi
    if [ $? -ne 0 ]; then log_message "Advertencia: Fallo en el 'update' inicial del sistema." console; fi

    echo "XXXX"
    echo "Realizando upgrade del sistema..."
    echo "XXXX"
    echo 20
    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
        DEBIAN_FRONTEND=noninteractive apt-get upgrade -y >> "$LOG_FILE" 2>&1
    elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
        dnf upgrade -y >> "$LOG_FILE" 2>&1
    fi
    if [ $? -ne 0 ]; then log_message "Advertencia: Fallo en el 'upgrade' inicial del sistema." console; fi

    echo "XXXX"
    echo "Configurando repositorios adicionales..."
    echo "XXXX"
    echo 30

    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
        log_message "Configurando PPA de Ondrej Sury para PHP."

        # Limpieza agresiva de configuraciones y claves GPG anteriores de Ondrej
        log_message "Limpiando configuraciones y claves GPG antiguas de Ondrej Sury."
        find /etc/apt/sources.list.d/ -type f -name "*ondrej-*.list*" -delete >> "$LOG_FILE" 2>&1
        sudo rm -f /etc/apt/trusted.gpg.d/ondrej-php.gpg >> "$LOG_FILE" 2>&1 || true
        sudo rm -f /usr/share/keyrings/deb.sury.org-php.gpg >> "$LOG_FILE" 2>&1 || true

        # Limpiar el caché de apt y listas
        log_message "Limpiando caché y listas de apt."
        DEBIAN_FRONTEND=noninteractive apt-get clean >> "$LOG_FILE" 2>&1
        sudo rm -rf /var/lib/apt/lists/* >> "$LOG_FILE" 2>&1

        # Instalar paquetes esenciales para añadir repositorios y GPG
        log_message "Instalando apt-transport-https, software-properties-common, curl, gnupg2."
        DEBIAN_FRONTEND=noninteractive apt-get update >> "$LOG_FILE" 2>&1 # Update previo para asegurar que se encuentren
        DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https software-properties-common curl gnupg2 >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            log_message "Error CRÍTICO: No se pudieron instalar paquetes esenciales para gestionar repositorios (apt-transport-https, etc.). Abortando la instalación." console
            exit 1 # Salida crítica
        fi
        log_message "Paquetes esenciales instalados."

        # Añadir la llave GPG de Ondrej de forma segura y moderna
        log_message "Añadiendo la clave GPG del PPA de Ondrej Sury a /usr/share/keyrings/."
        curl -sSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /usr/share/keyrings/deb.sury.org-php.gpg >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            log_message "Error CRÍTICO: No se pudo añadir la clave GPG de Ondrej Sury. Los repositorios no serán confiables. Abortando la instalación." console
            exit 1 # Salida crítica
        fi
        log_message "Clave GPG de Ondrej Sury añadida con éxito."

        # Crear/actualizar el archivo de repositorio usando el SYSTEM_CODENAME detectado
        PPA_LIST_FILE="/etc/apt/sources.list.d/ondrej-php-${SYSTEM_CODENAME}.list"
        log_message "Creando/actualizando archivo de repositorio de Ondrej: $PPA_LIST_FILE para codename '$SYSTEM_CODENAME'."
        echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $SYSTEM_CODENAME main" | sudo tee "$PPA_LIST_FILE" >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            log_message "Error CRÍTICO: No se pudo crear/actualizar el archivo del repositorio de Ondrej Sury. Abortando la instalación." console
            exit 1 # Salida crítica
        fi
        log_message "Archivo de repositorio de Ondrej creado/actualizado con éxito."
        
        # Realizar un apt update final para cargar los nuevos repositorios
        log_message "Realizando 'apt update' después de configurar el repositorio de Ondrej."
        DEBIAN_FRONTEND=noninteractive apt-get update >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            log_message "Error CRÍTICO: 'apt update' falló después de configurar el PPA de Ondrej. Esto significa que los paquetes PHP no se encontrarán. Verifica tu conexión a internet o el nombre clave de tu distribución ($SYSTEM_CODENAME) para el repositorio de Ondrej (https://packages.sury.org/php/dists/). Abortando la instalación." console
            exit 1 # Salida crítica si el update falla aquí
        fi
        log_message "'apt update' después de Ondrej completado con éxito."

    elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
        log_message "Configurando repositorios EPEL y REMI para AlmaLinux."
        # Instalar EPEL (Extra Packages for Enterprise Linux)
        if ! is_package_installed "epel-release" "epel-release"; then
            log_message "Instalando epel-release."
            dnf install -y epel-release >> "$LOG_FILE" 2>&1
        else
            log_message "epel-release ya instalado."
        fi
        # Instalar REMI (para versiones más recientes de PHP)
        if ! is_package_installed "remi-release" "remi-release"; then
            log_message "Instalando remi-release."
            # Detectar si es AlmaLinux 8 o 9
            if grep -q "VERSION_ID=\"8\"" /etc/os-release; then
                dnf install -y https://rpms.remirepo.net/enterprise/remi-release-8.rpm >> "$LOG_FILE" 2>&1
            elif grep -q "VERSION_ID=\"9\"" /etc/os-release; then
                dnf install -y https://rpms.remirepo.net/enterprise/remi-release-9.rpm >> "$LOG_FILE" 2>&1
            else
                log_message "Advertencia: Versión de AlmaLinux no reconocida (no 8 o 9). Saltando instalación de remi-release específica." console
            fi
            log_message "Reseteando módulo PHP para asegurar preferencia de REMI."
            dnf module reset php -y >> "$LOG_FILE" 2>&1
        else
            log_message "remi-release ya instalado."
        fi
        dnf update -y >> "$LOG_FILE" 2>&1 # Update después de añadir los nuevos repositorios
        if [ $? -ne 0 ]; then
            log_message "Error: 'dnf update' falló después de configurar repositorios REMI/EPEL." console
        fi
    fi
    
    echo "XXXX"
    echo "Repositorios configurados."
    echo "XXXX"
    echo 40

    # --- Instalación de Componentes LAMP ---

    echo "XXXX"
    echo "Instalando Apache..."
    echo "XXXX"
    echo 45
    APACHE_PKG=""
    APACHE_SVC=""
    APACHE_CONF_DIR=""
    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
        APACHE_PKG="apache2"
        APACHE_SVC="apache2"
        APACHE_CONF_DIR="/etc/apache2"
    elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
        APACHE_PKG="httpd"
        APACHE_SVC="httpd"
        APACHE_CONF_DIR="/etc/httpd/conf"
    fi

    if ! is_package_installed "$APACHE_PKG" "$APACHE_PKG"; then
        log_message "Instalando $APACHE_PKG."
        if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y "$APACHE_PKG" >> "$LOG_FILE" 2>&1
        elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
            dnf install -y "$APACHE_PKG" >> "$LOG_FILE" 2>&1
            systemctl enable "$APACHE_SVC" >> "$LOG_FILE" 2>&1
            systemctl start "$APACHE_SVC" >> "$LOG_FILE" 2>&1
        fi
        if [ $? -ne 0 ]; then log_message "Error: No se pudo instalar $APACHE_PKG. Abortando." console; exit 1; fi
    else
        log_message "$APACHE_PKG ya está instalado."
    fi

    # Configurar ServerName para evitar la advertencia AH00558
    if ! grep -q "ServerName localhost" "$APACHE_CONF_DIR/$APACHE_PKG.conf" 2>/dev/null; then
        echo "ServerName localhost" | sudo tee -a "$APACHE_CONF_DIR/$APACHE_PKG.conf" >> "$LOG_FILE" 2>&1
        log_message "Añadido 'ServerName localhost' a la configuración de Apache."
    else
        log_message "'ServerName localhost' ya presente en la configuración de Apache."
    fi

    # Habilitar mod_rewrite y reiniciar/recargar Apache
    log_message "Habilitando mod_rewrite y recargando Apache."
    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
        a2enmod rewrite >> "$LOG_FILE" 2>&1
        systemctl reload "$APACHE_SVC" >> "$LOG_FILE" 2>&1
    elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
        # mod_rewrite suele estar habilitado por defecto o se activa con el servicio
        systemctl reload "$APACHE_SVC" >> "$LOG_FILE" 2>&1
    fi
    if [ $? -ne 0 ]; then log_message "Advertencia: Fallo al habilitar mod_rewrite o recargar Apache." console; fi


    echo "XXXX"
    echo "Instalando PHP $PHP_VERSION..."
    echo "XXXX"
    echo 60
    PHP_INSTALLED=false
    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
        if is_package_installed "php${PHP_VERSION}" "dummy"; then
            PHP_INSTALLED=true
            log_message "PHP ${PHP_VERSION} ya está instalado."
        else
            log_message "Instalando php${PHP_VERSION}."
            DEBIAN_FRONTEND=noninteractive apt-get install -y php${PHP_VERSION} >> "$LOG_FILE" 2>&1
            if [ $? -eq 0 ]; then
                PHP_INSTALLED=true
                log_message "php${PHP_VERSION} instalado con éxito."
            else
                log_message "Error: No se pudo instalar php${PHP_VERSION}. Revisa el log. Abortando." console
                exit 1 # Salida crítica
            fi
        fi
    elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
        # Habilitar el módulo REMI específico para la versión de PHP
        log_message "Habilitando módulo PHP:remi-${PHP_VERSION} para AlmaLinux."
        dnf module enable -y php:remi-${PHP_VERSION} >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then
            log_message "Error: No se pudo habilitar el módulo PHP:remi-${PHP_VERSION}. Revisa el log. Abortando." console
            exit 1 # Salida crítica
        fi
        log_message "Instalando paquete base de PHP en AlmaLinux."
        dnf install -y php php-cli php-fpm >> "$LOG_FILE" 2>&1 # Instala cli y fpm con el base
        if [ $? -eq 0 ]; then
            PHP_INSTALLED=true
            log_message "PHP ${PHP_VERSION} base, CLI y FPM instalados con éxito en AlmaLinux."
            # Asegurarse de que el comando 'php' apunte a la versión de Ondrej (Debian/Ubuntu) o Remi (AlmaLinux)
            if command -v update-alternatives >/dev/null && [ "$DISTRIBUCION" == "Ubuntu/Debian" ]; then
                log_message "Configurando update-alternatives para PHP ${PHP_VERSION} CLI."
                update-alternatives --set php /usr/bin/php${PHP_VERSION} >> "$LOG_FILE" 2>&1 || true
            fi
        else
            log_message "Error: No se pudo instalar el paquete base de PHP en AlmaLinux. Revisa el log. Abortando." console
            exit 1 # Salida crítica
        fi
    fi
    if [ "$PHP_INSTALLED" = false ]; then
        log_message "Error: La instalación base de PHP $PHP_VERSION falló o no se detectó. Las extensiones no se instalarán. Abortando." console
        exit 1 # Salida crítica si PHP base no se instaló
    fi

    # Lista de extensiones PHP a instalar y sus nombres de paquete por distribución
    # Formato: "Nombre_Mostrado|paquete_debian_suffix|paquete_almalinux_nombre"
    PHP_EXTENSIONS=(
        "CLI|cli|php-cli" # Base CLI, ya manejado por separado en Alma, pero se incluye para consistencia
        "FPM|fpm|php-fpm" # Base FPM, ya manejado por separado en Alma, pero se incluye para consistencia
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
        "XSL|xsl|php-xmlrpc" # XSL en AlmaLinux suele ser parte de php-xmlrpc
        "APCu|apcu|php-pecl-apcu"
        "Memcached|memcached|php-pecl-memcached"
        "MongoDB|mongodb|php-pecl-mongodb"
        "SSH2|ssh2|php-pecl-ssh2"
        "Sybase|sybase|php-sybase" # Puede requerir FreeTDS y confs adicionales
        "ODBC|odbc|php-odbc"
        "Pspell|pspell|php-pspell"
        "Igbinary|igbinary|php-pecl-igbinary"
        "Xdebug|xdebug|php-pecl-xdebug" # Herramienta de depuración, no siempre necesaria
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

    # Instalar herramientas de compilación para PECL si es AlmaLinux
    if [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
        log_message "Verificando e instalando herramientas de compilación para extensiones PECL (php-devel, gcc, make)."
        if ! is_package_installed "build-essential" "php-devel"; then # build-essential para Debian/Ubuntu, php-devel para AlmaLinux
            dnf install -y php-devel gcc make >> "$LOG_FILE" 2>&1
            if [ $? -ne 0 ]; then log_message "Advertencia: Fallo al instalar php-devel y herramientas de compilación. Algunas extensiones PECL podrían fallar." console; fi
        else
            log_message "Herramientas de compilación PECL ya instaladas."
        fi
    fi

    # Bucle de instalación de extensiones PHP
    TOTAL_EXTENSIONS=${#PHP_EXTENSIONS[@]}
    PERCENT_PER_EXT=$(echo "scale=2; 20 / $TOTAL_EXTENSIONS" | bc) # 20% del progreso total (de 60% a 80%)
    CURRENT_PROGRESS=60

    for EXTENSION_INFO in "${PHP_EXTENSIONS[@]}"; do
        IFS='|' read -r DISPLAY_NAME DEBIAN_SUFFIX ALMALINUX_PACKAGE <<< "$EXTENSION_INFO"
        
        # Incrementar progreso antes de cada intento de instalación
        CURRENT_PROGRESS=$(echo "scale=0; $CURRENT_PROGRESS + $PERCENT_PER_EXT" | bc)
        if (( CURRENT_PROGRESS > 80 )); then CURRENT_PROGRESS=80; fi
        echo "XXXX"
        echo "Instalando extensión PHP: $DISPLAY_NAME..."
        echo "XXXX"
        echo $CURRENT_PROGRESS

        PACKAGE_TO_INSTALL=""
        INSTALL_SUCCESS=false

        if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
            PACKAGE_TO_INSTALL="php${PHP_VERSION}-${DEBIAN_SUFFIX}"
            log_message "Intentando instalar Debian/Ubuntu paquete: '$PACKAGE_TO_INSTALL'" # Solo log, no console
            if is_package_installed "$PACKAGE_TO_INSTALL" "dummy"; then
                INSTALL_SUCCESS=true
                log_message "  $DISPLAY_NAME (paquete $PACKAGE_TO_INSTALL) ya está instalado." # Solo log, no console
            else
                DEBIAN_FRONTEND=noninteractive apt-get install -y "$PACKAGE_TO_INSTALL" >> "$LOG_FILE" 2>&1
                if [ $? -eq 0 ]; then INSTALL_SUCCESS=true; fi
            fi
        elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
            PACKAGE_TO_INSTALL="$ALMALINUX_PACKAGE"
            log_message "Intentando instalar AlmaLinux paquete: '$PACKAGE_TO_INSTALL'" # Solo log, no console
            if is_package_installed "dummy" "$PACKAGE_TO_INSTALL"; then
                INSTALL_SUCCESS=true
                log_message "  $DISPLAY_NAME (paquete $PACKAGE_TO_INSTALL) ya está instalado." # Solo log, no console
            else
                dnf install -y "$PACKAGE_TO_INSTALL" >> "$LOG_FILE" 2>&1
                if [ $? -eq 0 ]; then INSTALL_SUCCESS=true; fi
            fi
        fi
        
        if [ "$INSTALL_SUCCESS" = false ]; then
            UNINSTALLED_EXTENSIONS+=("$DISPLAY_NAME")
            log_message "  Advertencia: No se pudo instalar la extensión $DISPLAY_NAME (paquete $PACKAGE_TO_INSTALL)." console # Este sí en consola, es una advertencia
        else
            log_message "  $DISPLAY_NAME (paquete $PACKAGE_TO_INSTALL) instalado con éxito." # Solo log, no console
        fi
    done
    
    echo "XXXX"
    echo "Extensiones PHP procesadas."
    echo "XXXX"
    echo 80
    log_message "Procesamiento de extensiones PHP completado." console

    echo "XXXX"
    echo "Instalando base de datos (MySQL/MariaDB)..."
    echo "XXXX"
    echo 85
    DB_PKG_SERVER=""
    DB_PKG_CLIENT=""
    DB_SVC=""
    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
        DB_PKG_SERVER="mysql-server"
        DB_PKG_CLIENT="mysql-client"
        DB_SVC="mysql"
    elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
        DB_PKG_SERVER="mariadb-server"
        DB_PKG_CLIENT="mariadb"
        DB_SVC="mariadb"
    fi

    log_message "Instalando $DB_PKG_SERVER y $DB_PKG_CLIENT."
    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y "$DB_PKG_SERVER" "$DB_PKG_CLIENT" >> "$LOG_FILE" 2>&1
    elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
        dnf install -y "$DB_PKG_SERVER" "$DB_PKG_CLIENT" >> "$LOG_FILE" 2>&1
    fi
    if [ $? -ne 0 ]; then log_message "Error: No se pudo instalar la base de datos ($DB_PKG_SERVER). Abortando." console; exit 1; fi

    log_message "Habilitando y iniciando el servicio de base de datos."
    systemctl enable "$DB_SVC" >> "$LOG_FILE" 2>&1
    systemctl start "$DB_SVC" >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then log_message "Advertencia: Fallo al iniciar/habilitar el servicio $DB_SVC." console; fi

    # Configurar contraseña de root de MySQL/MariaDB y crear usuario phpmyadmin
    log_message "Configurando usuario root de MySQL/MariaDB y creando usuario phpmyadmin."
    MYSQL_SECURE_INSTALL_CMD="mysql -u root -e"
    
    # Intenta autenticación sin contraseña primero (para sistemas nuevos)
    if ! sudo $MYSQL_SECURE_INSTALL_CMD "exit" 2>/dev/null; then
      log_message "Intentando autenticar como root con sudo."
      MYSQL_SECURE_INSTALL_CMD="sudo mysql -u root -e"
      if ! sudo $MYSQL_SECURE_INSTALL_CMD "exit" 2>/dev/null; then
        log_message "Fallo al autenticar como root con sudo. Podría requerir contraseña o ser fresh install."
        MYSQL_SECURE_INSTALL_CMD="mysql -u root --password=$PHPMYADMIN_ROOT_PASS -e" # Asume que ya tiene una y la probamos
      fi
    fi

    # Configurar contraseña de root (si es necesario y posible)
    log_message "Configurando contraseña para 'root' de MySQL/MariaDB."
    $MYSQL_SECURE_INSTALL_CMD "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$PHPMYADMIN_ROOT_PASS';" >> "$LOG_FILE" 2>&1
    $MYSQL_SECURE_INSTALL_CMD "FLUSH PRIVILEGES;" >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then log_message "Advertencia: Fallo al configurar contraseña de 'root' para MySQL/MariaDB. Podría requerir intervención manual." console; fi

    # Crear usuario 'phpmyadmin'
    log_message "Creando usuario 'phpmyadmin'."
    $MYSQL_SECURE_INSTALL_CMD "CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED WITH mysql_native_password BY '$PHPMYADMIN_USER_PASS';" >> "$LOG_FILE" 2>&1
    $MYSQL_SECURE_INSTALL_CMD "GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;" >> "$LOG_FILE" 2>&1
    $MYSQL_SECURE_INSTALL_CMD "FLUSH PRIVILEGES;" >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then log_message "Advertencia: Fallo al crear usuario 'phpmyadmin'. Podría requerir intervención manual." console; fi
    
    log_message "Configuración básica de MySQL/MariaDB completada."


    echo "XXXX"
    echo "Instalando phpMyAdmin..."
    echo "XXXX"
    echo 90
    PHPMYADMIN_PKG=""
    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
        PHPMYADMIN_PKG="phpmyadmin"
    elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
        PHPMYADMIN_PKG="phpmyadmin" # El nombre es el mismo, pero el repo REMI lo proporciona
    fi

    if ! is_package_installed "$PHPMYADMIN_PKG" "$PHPMYADMIN_PKG"; then
        log_message "Instalando $PHPMYADMIN_PKG."
        if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
            # Para phpmyadmin en Debian/Ubuntu, se suelen usar debconf para preconfigurar
            # Simplemente instalaremos, si aparece el diálogo, el usuario tendrá que manejarlo
            DEBIAN_FRONTEND=noninteractive apt-get install -y "$PHPMYADMIN_PKG" >> "$LOG_FILE" 2>&1
            # Configuración automática básica para phpmyadmin (dpkg-reconfigure para Apache2)
            log_message "Configurando phpmyadmin con Apache2 (si aplica)."
            echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/appserv select apache2" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/mysql/admin-pass password $PHPMYADMIN_ROOT_PASS" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_USER_PASS" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
            dpkg-reconfigure -f noninteractive phpmyadmin >> "$LOG_FILE" 2>&1
            # Asegurarse de que el alias de phpmyadmin esté incluido en Apache
            if [ -f /etc/apache2/conf-available/phpmyadmin.conf ]; then
                a2enconf phpmyadmin >> "$LOG_FILE" 2>&1
                systemctl reload apache2 >> "$LOG_FILE" 2>&1
            fi

        elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
            dnf install -y "$PHPMYADMIN_PKG" >> "$LOG_FILE" 2>&1
            # Configuración para Apache en AlmaLinux
            cp /etc/httpd/conf.d/phpMyAdmin.conf /etc/httpd/conf.d/phpMyAdmin.conf.bak >> "$LOG_FILE" 2>&1
            # Permitir acceso desde cualquier lugar (puedes restringirlo más tarde)
            sed -i 's/Require ip 127.0.0.1/Require all granted/' /etc/httpd/conf.d/phpMyAdmin.conf >> "$LOG_FILE" 2>&1
            sed -i 's/Require host localhost/Require all granted/' /etc/httpd/conf.d/phpMyAdmin.conf >> "$LOG_FILE" 2>&1
            systemctl reload httpd >> "$LOG_FILE" 2>&1
        fi
        if [ $? -ne 0 ]; then log_message "Error: No se pudo instalar $PHPMYADMIN_PKG." console; fi
    else
        log_message "$PHPMYADMIN_PKG ya está instalado."
    fi

    log_message "Instalación de phpMyAdmin completada."

    echo "XXXX"
    echo "Instalando Composer..."
    echo "XXXX"
    echo 95
    if ! command -v composer >/dev/null; then
        log_message "Instalando Composer."
        curl -sS https://getcomposer.org/installer | php >> "$LOG_FILE" 2>&1
        mv composer.phar /usr/local/bin/composer >> "$LOG_FILE" 2>&1
        if [ $? -ne 0 ]; then log_message "Advertencia: Fallo al instalar Composer." console; fi
    else
        log_message "Composer ya está instalado."
    fi

    echo "XXXX"
    echo "Instalando Git..."
    echo "XXXX"
    echo 97
    GIT_PKG=""
    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
        GIT_PKG="git"
    elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
        GIT_PKG="git"
    fi
    if ! is_package_installed "$GIT_PKG" "$GIT_PKG"; then
        log_message "Instalando Git."
        if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y "$GIT_PKG" >> "$LOG_FILE" 2>&1
        elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
            dnf install -y "$GIT_PKG" >> "$LOG_FILE" 2>&1
        fi
        if [ $? -ne 0 ]; then log_message "Advertencia: Fallo al instalar Git." console; fi
    else
        log_message "Git ya está instalado."
    fi


    echo "XXXX"
    echo "Configurando proyecto Laravel..."
    echo "XXXX"
    echo 98

    # Crear directorio del proyecto Laravel
    LARAVEL_DIR="/var/www/html/$PROJECT_NAME"
    if [ ! -d "$LARAVEL_DIR" ]; then
        log_message "Creando directorio del proyecto Laravel: $LARAVEL_DIR."
        mkdir -p "$LARAVEL_DIR" >> "$LOG_FILE" 2>&1
        chmod 755 /var/www/html >> "$LOG_FILE" 2>&1
        chmod -R 755 "$LARAVEL_DIR" >> "$LOG_FILE" 2>&1
        chown -R www-data:www-data "$LARAVEL_DIR" >> "$LOG_FILE" 2>&1 # Ubuntu/Debian
        if [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
            chown -R apache:apache "$LARAVEL_DIR" >> "$LOG_FILE" 2>&1 # AlmaLinux
            semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/$PROJECT_NAME(/.*)?" >> "$LOG_FILE" 2>&1
            restorecon -Rv "/var/www/html/$PROJECT_NAME" >> "$LOG_FILE" 2>&1
        fi
    else
        log_message "El directorio del proyecto Laravel $LARAVEL_DIR ya existe. Saltando creación."
    fi

    # Configuración de Virtual Host para Apache
    log_message "Configurando Virtual Host para Apache."
    VHOST_CONF_FILE=""
    VHOST_SITE_ENABLE_DIR=""
    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
        VHOST_CONF_FILE="/etc/apache2/sites-available/$PROJECT_NAME.conf"
        VHOST_SITE_ENABLE_DIR="/etc/apache2/sites-enabled"
        # Deshabilitar el sitio por defecto de Apache
        if [ -f /etc/apache2/sites-enabled/000-default.conf ]; then
            a2dissite 000-default.conf >> "$LOG_FILE" 2>&1
            log_message "Deshabilitado sitio por defecto de Apache (000-default.conf)."
        fi
    elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
        VHOST_CONF_FILE="/etc/httpd/conf.d/$PROJECT_NAME.conf"
    fi

    echo "<VirtualHost *:80>
        ServerName $PROJECT_NAME.test
        DocumentRoot $LARAVEL_DIR/public

        <Directory $LARAVEL_DIR/public>
            AllowOverride All
            Order Allow,Deny
            Allow from All
        </Directory>

        ErrorLog \${APACHE_LOG_DIR}/$PROJECT_NAME-error.log
        CustomLog \${APACHE_LOG_DIR}/$PROJECT_NAME-access.log combined
    </VirtualHost>" | sudo tee "$VHOST_CONF_FILE" >> "$LOG_FILE" 2>&1

    # Habilitar el sitio en Debian/Ubuntu
    if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
        a2ensite "$PROJECT_NAME.conf" >> "$LOG_FILE" 2>&1
    fi

    # Añadir entrada al archivo hosts local para $PROJECT_NAME.test
    if ! grep -q "$PROJECT_NAME.test" /etc/hosts; then
        echo "127.0.0.1\t$PROJECT_NAME.test" | sudo tee -a /etc/hosts >> "$LOG_FILE" 2>&1
        log_message "Añadido $PROJECT_NAME.test a /etc/hosts."
    else
        log_message "$PROJECT_NAME.test ya está en /etc/hosts."
    fi

    # Reiniciar el servicio Apache
    log_message "Reiniciando Apache para aplicar cambios de Virtual Host."
    systemctl restart "$APACHE_SVC" >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then log_message "Error: Fallo al reiniciar Apache. Revisa el log." console; fi


    echo "XXXX"
    echo "Instalando aplicaciones adicionales..."
    echo "XXXX"
    echo 99

    if [[ -n "$SELECTED_APPS" ]]; then
        log_message "Iniciando instalación de aplicaciones adicionales: $SELECTED_APPS" console
        IFS=' ' read -r -a APPS_ARRAY <<< "$SELECTED_APPS" # Convertir string a array

        for APP in "${APPS_ARRAY[@]}"; do
            log_message "Intentando instalar $APP..."
            case "$APP" in
                "vscode")
                    if ! command -v code >/dev/null; then
                        log_message "Instalando Visual Studio Code."
                        if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                            curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
                            sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ >> "$LOG_FILE" 2>&1
                            sudo sh -c 'echo "deb [arch=amd64,arm64,armhf] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' >> "$LOG_FILE" 2>&1
                            rm microsoft.gpg
                            DEBIAN_FRONTEND=noninteractive apt-get update >> "$LOG_FILE" 2>&1
                            DEBIAN_FRONTEND=noninteractive apt-get install -y code >> "$LOG_FILE" 2>&1
                        elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                            rpm --import https://packages.microsoft.com/keys/microsoft.asc >> "$LOG_FILE" 2>&1
                            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo' >> "$LOG_FILE" 2>&1
                            dnf check-update >> "$LOG_FILE" 2>&1
                            dnf install -y code >> "$LOG_FILE" 2>&1
                        fi
                    else
                        log_message "Visual Studio Code ya está instalado."
                    fi
                    ;;
                "sublimetext")
                    if ! command -v subl >/dev/null; then
                        log_message "Instalando Sublime Text."
                        if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                            wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg >/dev/null >> "$LOG_FILE" 2>&1
                            echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list >> "$LOG_FILE" 2>&1
                            DEBIAN_FRONTEND=noninteractive apt-get update >> "$LOG_FILE" 2>&1
                            DEBIAN_FRONTEND=noninteractive apt-get install -y sublime-text >> "$LOG_FILE" 2>&1
                        elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                            rpm -v --import https://download.sublimetext.com/rpm/rpmkey.gpg >> "$LOG_FILE" 2>&1
                            sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo >> "$LOG_FILE" 2>&1
                            dnf install -y sublime-text >> "$LOG_FILE" 2>&1
                        fi
                    else
                        log_message "Sublime Text ya está instalado."
                    fi
                    ;;
                "brave")
                    if ! command -v brave-browser >/dev/null; then
                        log_message "Instalando Brave Browser."
                        if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                            sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg >> "$LOG_FILE" 2>&1
                            echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list >> "$LOG_FILE" 2>&1
                            DEBIAN_FRONTEND=noninteractive apt-get update >> "$LOG_FILE" 2>&1
                            DEBIAN_FRONTEND=noninteractive apt-get install -y brave-browser >> "$LOG_FILE" 2>&1
                        elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                            sudo dnf install -y dnf-plugins-core >> "$LOG_FILE" 2>&1
                            sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/ >> "$LOG_FILE" 2>&1
                            sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc >> "$LOG_FILE" 2>&1
                            sudo dnf install -y brave-browser >> "$LOG_FILE" 2>&1
                        fi
                    else
                        log_message "Brave Browser ya está instalado."
                    fi
                    ;;
                "googlechrome")
                    if ! command -v google-chrome >/dev/null; then
                        log_message "Instalando Google Chrome."
                        if [[ "$DISTRIBUCION" == "Ubuntu/Debian" ]]; then
                            wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | sudo tee /usr/share/keyrings/google-chrome.gpg >/dev/null >> "$LOG_FILE" 2>&1
                            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list >> "$LOG_FILE" 2>&1
                            DEBIAN_FRONTEND=noninteractive apt-get update >> "$LOG_FILE" 2>&1
                            DEBIAN_FRONTEND=noninteractive apt-get install -y google-chrome-stable >> "$LOG_FILE" 2>&1
                        elif [[ "$DISTRIBUCION" == "AlmaLinux" ]]; then
                            sudo dnf config-manager --add-repo https://dl.google.com/linux/chrome/rpm/stable/x86_64 >> "$LOG_FILE" 2>&1
                            sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub >> "$LOG_FILE" 2>&1
                            sudo dnf install -y google-chrome-stable >> "$LOG_FILE" 2>&1
                        fi
                    else
                        log_message "Google Chrome ya está instalado."
                    fi
                    ;;
                *)
                    log_message "Aplicación '$APP' no reconocida o no soportada para instalación automática." console
                    ;;
            esac
            if [ $? -ne 0 ]; then log_message "Advertencia: Fallo al instalar $APP." console; fi
        done
    else
        log_message "No se seleccionaron aplicaciones adicionales."
    fi

    echo "XXXX"
    echo "Instalación completada!"
    echo "XXXX"
    echo 100
    log_message "Script de instalación finalizado." console

) | dialog --backtitle "Script de Instalación Versión $VERSO" \
           --title "Progreso de la Instalación" \
           --gauge "Iniciando la instalación de componentes LAMP y Laravel..." 10 70 0

clear # Limpia la pantalla después de la barra de progreso

# --- MENSAJE FINAL ---
INSTALL_MESSAGE="\n¡La instalación ha finalizado con éxito!\n\n"
INSTALL_MESSAGE+="Tu servidor LAMP está configurado.\n"
INSTALL_MESSAGE+="Tu proyecto Laravel se configuró con el nombre: $PROJECT_NAME\n"
INSTALL_MESSAGE+="Puedes acceder a Laravel en http://$PROJECT_NAME.test\n"
INSTALL_MESSAGE+="Puedes acceder a phpMyAdmin en http://localhost/phpmyadmin\n"
INSTALL_MESSAGE+="Usuario phpMyAdmin: phpmyadmin\n"
INSTALL_MESSAGE+="Usuario root de MySQL/MariaDB: root\n\n"
INSTALL_MESSAGE+="Contraseñas establecidas durante la instalación.\n\n"

if [ ${#UNINSTALLED_EXTENSIONS[@]} -gt 0 ]; then
    INSTALL_MESSAGE+="\nSin embargo, las siguientes extensiones PHP no pudieron ser instaladas:\n\n"
    for ext in "${UNINSTALLED_EXTENSIONS[@]}"; do
        INSTALL_MESSAGE+="  - $ext\n"
    done
    INSTALL_MESSAGE+="\nPor favor, verifica si las necesitas y considera instalarlas manualmente si es necesario."
    log_message "Extensiones PHP no instaladas: ${UNINSTALLED_EXTENSIONS[*]}"
fi

INSTALL_MESSAGE+="\nPuedes revisar el archivo de log para más detalles: \n$LOG_FILE\n"
INSTALL_MESSAGE+="\n¡Disfruta desarrollando con Laravel!"

dialog --backtitle "Script de Instalación Versión $VERSO" \
       --title "Instalación Completada" \
       --msgbox "$INSTALL_MESSAGE" 25 80 # Aumentar el tamaño para el mensaje final

clear # Limpia la pantalla después del mensaje final
exit 0
