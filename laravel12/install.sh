#!/bin/bash

VEROS="2.0"

# --- Funciones de Utilidad ---
is_ubuntu_debian() {
    [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]
}

is_almalinux() {
    [[ "$DISTRO" == "almalinux" ]]
}

# Validar si el usuario es root
if [ "$(id -u)" -ne 0 ]; then
    clear
    dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
    --title "Error de Permisos" \
    --msgbox "\nEste script debe ser ejecutado como usuario root.\nPor favor, usa 'sudo bash install.sh'." 10 60
    clear
    exit 1
fi

# Validar si el sistema es de 64 bits
if [ "$(uname -m)" != "x86_64" ]; then
    clear
    dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
    --title "Error de Arquitectura" \
    --msgbox "\nEste script solo soporta sistemas de 64 bits (x86_64)." 10 60
    clear
    exit 1
fi

# Validar distribución y versión
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
    VERSION=$VERSION_ID
else
    clear
    dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
    --title "Error de Distribucion" \
    --msgbox "\nNo se pudo detectar la distribucion de Linux. Saliendo." 10 60
    clear
    exit 1
fi

# Definir el paquete de base de datos y validar compatibilidad
DB_PACKAGE=""
DB_TYPE=""
DB_ROOT_USER=""
DB_PORT="3306"

case "$DISTRO" in
    ubuntu)
        if ! (( $(echo "$VERSION >= 22" | bc -l) )); then
            clear
            dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
            --title "Version de Ubuntu Incompatible" \
            --msgbox "\nEste script requiere Ubuntu 22.04 LTS o superior." 10 60
            clear
            exit 1
        fi
        DB_PACKAGE="mysql-server"
        DB_TYPE="MySQL"
        DB_ROOT_USER="mysql" # Usuario para autenticar comandos mysql -u
        ;;
    debian)
        if ! (( $(echo "$VERSION >= 11" | bc -l) )); then
            clear
            dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
            --title "Version de Debian Incompatible" \
            --msgbox "\nEste script requiere Debian 11 (Bullseye) o superior." 10 60
            clear
            exit 1
        fi
        DB_PACKAGE="mariadb-server"
        DB_TYPE="MariaDB"
        DB_ROOT_USER="mariadb" # Usuario para autenticar comandos mysql -u
        ;;
    almalinux)
        if ! [[ "$VERSION" =~ ^(8|9)\.[0-9]+$ ]]; then
            clear
            dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
            --title "Version de AlmaLinux Incompatible" \
            --msgbox "\nEste script requiere AlmaLinux 8 o 9." 10 60
            clear
            exit 1
        fi
        DB_PACKAGE="mariadb-server"
        DB_TYPE="MariaDB"
        DB_ROOT_USER="mariadb" # Usuario para autenticar comandos mysql -u
        ;;
    *)
        clear
        dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
        --title "Distribucion Incompatible" \
        --msgbox "\nEsta distribucion de Linux no es compatible con el script." 10 60
        clear
        exit 1
        ;;
esac

# Validar e instalar 'dialog' en segundo plano si no está presente
if ! command -v dialog &> /dev/null; then
    case "$DISTRO" in
        ubuntu|debian)
            apt update > /dev/null 2>&1 &
            apt install -y dialog > /dev/null 2>&1 &
            ;;
        almalinux)
            dnf install -y dialog > /dev/null 2>&1 &
            ;;
    esac
    while ! command -v dialog &> /dev/null; do
        sleep 1
    done
fi

# Cuadro de bienvenida con información de paquetes y opciones Aceptar/Salir
dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
--title "Bienvenido al Instalador de Laravel 12" \
--yesno "\nEste script preparara tu sistema para Laravel 12.\n\nSe instalaran los siguientes paquetes:\n- Apache2\n- PHP (y extensiones necesarias)\n- $DB_PACKAGE\n- phpMyAdmin\n- Node.js\n- Git, Unzip y Curl (utilidades esenciales)\n\n¿Deseas continuar con la instalacion?" 18 70

response=$?
case $response in
    0) # Codigo de retorno 0 = Yes/Aceptar
        clear
        ;;
    1) # Codigo de retorno 1 = No/Salir
        clear
        exit 0
        ;;
    255) # Codigo de retorno 255 = ESC presionado o ventana cerrada
        clear
        exit 0
        ;;
esac

# Solicitar el nombre del proyecto Laravel
PROJECT_NAME=$(dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
--title "Nombre del Proyecto Laravel" \
--inputbox "\nIngresa el nombre para tu nuevo proyecto Laravel 12:\n(Ej: crud)" 10 60 "" 3>&1 1>&2 2>&3)

# Verificar si el usuario canceló o dejó el nombre vacío
if [ -z "$PROJECT_NAME" ]; then
    clear
    dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
    --title "Error" \
    --msgbox "\nNo se ha especificado un nombre de proyecto. Saliendo del instalador." 8 50
    clear
    exit 1
fi

# Solicitar la contraseña para el usuario de phpMyAdmin (visible)
PHPMYADMIN_PASSWORD=$(dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
--title "Contraseña de phpMyAdmin" \
--inputbox "\nIngresa la contraseña para el usuario 'phpmyadmin' de $DB_TYPE:" 10 60 "" 3>&1 1>&2 2>&3)

# Verificar si el usuario canceló o dejó la contraseña vacía
if [ -z "$PHPMYADMIN_PASSWORD" ]; then
    clear
    dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
    --title "Error" \
    --msgbox "\nNo se ha especificado una contraseña para phpMyAdmin. Saliendo del instalador." 8 50
    clear
    exit 1
fi

# Solicitar la contraseña para el usuario root de la base de datos (visible)
DB_ROOT_PASSWORD=$(dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
--title "Contraseña Root de $DB_PACKAGE" \
--inputbox "\nIngresa la contraseña para el usuario root de $DB_ROOT_USER:" 10 60 "" 3>&1 1>&2 2>&3)

# Verificar si el usuario canceló o dejó la contraseña vacía
if [ -z "$DB_ROOT_PASSWORD" ]; then
    clear
    dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
    --title "Error" \
    --msgbox "\nNo se ha especificado una contraseña para el usuario root de la base de datos. Saliendo del instalador." 8 50
    clear
    exit 1
fi

# Seleccionar la versión de PHP para phpMyAdmin
PHP_VERSION=$(dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
--title "Version de PHP para phpMyAdmin" \
--radiolist "\nSelecciona la version de PHP a usar para phpMyAdmin:\n(Recomendada para Laravel 12: PHP 8.3)" 15 60 3 \
"8.2" "PHP 8.2" OFF \
"8.3" "PHP 8.3" ON \
"8.4" "PHP 8.4" OFF \
3>&1 1>&2 2>&3)

# Verificar si el usuario canceló la selección
if [ -z "$PHP_VERSION" ]; then
    clear
    dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
    --title "Error" \
    --msgbox "\nNo se ha seleccionado una version de PHP para phpMyAdmin. Saliendo del instalador." 8 60
    clear
    exit 1
fi

# Seleccionar programas adicionales para instalar
ADDITIONAL_SOFTWARE=$(dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
--title "Programas Adicionales" \
--checklist "\nSelecciona los programas adicionales que deseas instalar:" 18 60 4 \
"vscode" "Visual Studio Code" OFF \
"sublime" "Sublime Text" OFF \
"brave" "Brave Browser" OFF \
"chrome" "Google Chrome" OFF \
3>&1 1>&2 2>&3)

# --- Inicio de la Barra de Progreso ---

# Archivo temporal para la comunicación con dialog --gauge
PROGRESS_FILE=$(mktemp)

# Función para limpiar el archivo temporal y cerrar dialog en caso de interrupción
trap "rm -f $PROGRESS_FILE; clear" EXIT

# Inicializar la barra de progreso en segundo plano
(
    # Definición de las tareas y sus "pesos" relativos
    declare -A TASK_WEIGHTS
    TASK_WEIGHTS["Actualizando listas de paquetes..."]=2
    TASK_WEIGHTS["Actualizando paquetes del sistema..."]=2
    TASK_WEIGHTS["Instalando utilidades esenciales (curl, unzip, git)..."]=3
    TASK_WEIGHTS["Verificando e integrando PPA de Ondrej..."]=3
    TASK_WEIGHTS["Añadiendo repositorio de Node.js 20 (LTS)..."]=3
    TASK_WEIGHTS["Instalando Node.js y npm..."]=5
    TASK_WEIGHTS["Verificando e instalando Apache2..."]=5
    TASK_WEIGHTS["Habilitando mod_rewrite y reiniciando Apache..."]=2
    
    # PHP installation - sum of its sub-steps (adjust based on DISTRO)
    if is_ubuntu_debian; then
        TASK_WEIGHTS["Instalando PHP ${PHP_VERSION}..."]=2 # Base PHP
        TASK_WEIGHTS["Instalando PHP ${PHP_VERSION}-cli..."]=1
        TASK_WEIGHTS["Instalando PHP ${PHP_VERSION}-common..."]=1
        TASK_WEIGHTS["Instalando PHP ${PHP_VERSION}-mysql..."]=1
        TASK_WEIGHTS["Instalando PHP ${PHP_VERSION}-xml..."]=1
        TASK_WEIGHTS["Instalando PHP ${PHP_VERSION}-mbstring..."]=1
        TASK_WEIGHTS["Instalando PHP ${PHP_VERSION}-zip..."]=1
        TASK_WEIGHTS["Instalando PHP ${PHP_VERSION}-gd..."]=1
        TASK_WEIGHTS["Instalando PHP ${PHP_VERSION}-curl..."]=1
        TASK_WEIGHTS["Instalando PHP ${PHP_VERSION}-fpm..."]=1
        TASK_WEIGHTS["Configurando módulo PHP para Apache..."]=2 # This includes libapache2-mod-php and a2enmod
    elif is_almalinux; then
        TASK_WEIGHTS["Instalando PHP (paquete base) para AlmaLinux..."]=2
        TASK_WEIGHTS["Instalando PHP CLI..."]=1
        TASK_WEIGHTS["Instalando PHP MySQLnd..."]=1
        TASK_WEIGHTS["Instalando PHP XML..."]=1
        TASK_WEIGHTS["Instalando PHP MBString..."]=1
        TASK_WEIGHTS["Instalando PHP ZIP..."]=1
        TASK_WEIGHTS["Instalando PHP GD..."]=1
        TASK_WEIGHTS["Instalando PHP cURL..."]=1
        TASK_WEIGHTS["Instalando PHP-FPM..."]=1
        TASK_WEIGHTS["Instalando httpd-devel (para PHP-FPM)..."]=1
        TASK_WEIGHTS["Configurando PHP-FPM y Apache para AlmaLinux..."]=2
    fi

    TASK_WEIGHTS["Verificando e instalando $DB_TYPE..."]=5
    TASK_WEIGHTS["Configurando contraseña de root para $DB_TYPE..."]=3
    TASK_WEIGHTS["Verificando e instalando phpMyAdmin..."]=5
    TASK_WEIGHTS["Configurando phpMyAdmin y usuario de base de datos..."]=3
    TASK_WEIGHTS["Verificando e instalando Composer..."]=3
    TASK_WEIGHTS["Configurando PATH para Laravel Installer..."]=1 # Peso reducido, es una tarea interna ahora
    TASK_WEIGHTS["Instalando Laravel Installer..."]=7 # Aumentado por ser una descarga importante
    TASK_WEIGHTS["Creando directorio /var/www/laravel..."]=1
    TASK_WEIGHTS["Creando proyecto Laravel '$PROJECT_NAME' con Pest en /var/www/laravel..."]=15 # Laravel new es pesado
    TASK_WEIGHTS["Configurando archivo .env para la base de datos..."]=1
    TASK_WEIGHTS["Creando base de datos '$DB_NAME' para el proyecto..."]=2
    TASK_WEIGHTS["Ejecutando migraciones de Laravel..."]=3
    TASK_WEIGHTS["Instalando paquete de idioma español (laravel-lang/lang)..."]=2
    TASK_WEIGHTS["Publicando archivos de idioma español..."]=1
    TASK_WEIGHTS["Configurando idioma por defecto a español en config/app.php..."]=1
    TASK_WEIGHTS["Ejecutando npm install para dependencias frontend..."]=10 # npm install es pesado
    TASK_WEIGHTS["Compilando assets frontend con npm run build..."]=10 # npm run build es pesado
    TASK_WEIGHTS["Configurando permisos del proyecto Laravel..."]=2
    TASK_WEIGHTS["Configurando Virtual Host de Apache para '$PROJECT_NAME.test'..." ]=3
    TASK_WEIGHTS["Agregando '$PROJECT_NAME.test' al archivo /etc/hosts..." ]=1

    # Pesos para software adicional (si se seleccionan)
    if [[ "$ADDITIONAL_SOFTWARE" == *"vscode"* ]]; then
        if ! command -v code &> /dev/null; then
            TASK_WEIGHTS["Instalando Visual Studio Code..."]=5
        else
            TASK_WEIGHTS["Visual Studio Code ya está instalado. Omitiendo..."]=1
        fi
    fi
    if [[ "$ADDITIONAL_SOFTWARE" == *"sublime"* ]]; then
        if ! command -v subl &> /dev/null; then
            TASK_WEIGHTS["Instalando Sublime Text..."]=5
        else
            TASK_WEIGHTS["Sublime Text ya está instalado. Omitiendo..."]=1
        fi
    fi
    if [[ "$ADDITIONAL_SOFTWARE" == *"brave"* ]]; then
        if ! command -v brave-browser &> /dev/null; then
            TASK_WEIGHTS["Instalando Brave Browser..."]=5
        else
            TASK_WEIGHTS["Brave Browser ya está instalado. Omitiendo..."]=1
        fi
    fi
    if [[ "$ADDITIONAL_SOFTWARE" == *"chrome"* ]]; then
        if ! command -v google-chrome &> /dev/null; then
            TASK_WEIGHTS["Instalando Google Chrome..."]=5
        else
            TASK_WEIGHTS["Google Chrome ya está instalado. Omitiendo..."]=1
        fi
    fi
    
    TASK_WEIGHTS["Finalizando configuraciones..."]=2

    # Calcular el total de pasos sumando los pesos
    total_steps=0
    for task_msg in "${!TASK_WEIGHTS[@]}"; do
        total_steps=$((total_steps + ${TASK_WEIGHTS[$task_msg]}))
    done

    current_progress=0

    # Función para actualizar la barra de progreso
    # Ahora, `message` es la clave del array asociativo `TASK_WEIGHTS`
    update_progress() {
        message=$1
        increment_weight=${TASK_WEIGHTS["$message"]}
        
        # Si el peso no está definido, o ya hemos contabilizado esta tarea, salimos.
        # Esto evita sumar múltiples veces el mismo paso o pasos no definidos.
        if [ -z "$increment_weight" ]; then
             # Para depuración, puedes quitar >/dev/stderr para ver si hay mensajes no mapeados
             echo "ADVERTENCIA: Mensaje de progreso no mapeado: '$message'" >/dev/stderr
             return
        fi

        current_progress=$((current_progress + increment_weight))
        
        # Asegurarse de que el porcentaje no exceda 100
        percentage=$((current_progress * 100 / total_steps))
        if (( percentage > 100 )); then percentage=100; fi

        echo "$percentage"
        echo "XXX"
        echo "$message"
        echo "XXX"
    }

    # --- INICIO DE LOS PASOS REALES DE INSTALACIÓN ---

    # 1. Actualizar listas de paquetes
    update_progress "Actualizando listas de paquetes..."
    if is_ubuntu_debian; then
        apt update > /dev/null 2>&1
    elif is_almalinux; then
        dnf check-update > /dev/null 2>&1
    fi
    sleep 1

    # 2. Actualizar paquetes del sistema
    update_progress "Actualizando paquetes del sistema..."
    if is_ubuntu_debian; then
        apt upgrade -y > /dev/null 2>&1
    elif is_almalinux; then
        dnf upgrade -y > /dev/null 2>&1
    fi
    sleep 1

    # 3. Instalar utilidades esenciales: curl, unzip, git (con validación y más robusto)
    # ***********************************************************************************
    # ESTE ES EL PASO CLAVE PARA CURL, NO OMITIR
    # ***********************************************************************************
    update_progress "Instalando utilidades esenciales (curl, unzip, git)..."
    INSTALL_PACKAGES=""
    if is_ubuntu_debian; then
        if ! command -v curl &> /dev/null; then INSTALL_PACKAGES+=" curl"; fi
        if ! command -v unzip &> /dev/null; then INSTALL_PACKAGES+=" unzip"; fi
        if ! command -v git &> /dev/null; then INSTALL_PACKAGES+=" git"; fi
        if [ -n "$INSTALL_PACKAGES" ]; then
            apt install -y $INSTALL_PACKAGES > /dev/null 2>&1
        fi
    elif is_almalinux; then
        if ! command -v curl &> /dev/null; then INSTALL_PACKAGES+=" curl"; fi
        if ! command -v unzip &> /dev/null; then INSTALL_PACKAGES+=" unzip"; fi
        if ! command -v git &> /dev/null; then INSTALL_PACKAGES+=" git"; fi
        if [ -n "$INSTALL_PACKAGES" ]; then
            dnf install -y $INSTALL_PACKAGES > /dev/null 2>&1
        fi
    fi
    sleep 1


    # 4. Añadir repositorio PPA de Ondrej (Solo para Debian/Ubuntu, si no existe)
    if is_ubuntu_debian; then
        update_progress "Verificando e integrando PPA de Ondrej..."
        if ! grep -q "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
            # Asegurar que software-properties-common, ca-certificates, apt-transport-https, lsb-release estén instalados
            APT_DEPS_PHP_PPA=""
            if ! dpkg -s software-properties-common &> /dev/null; then APT_DEPS_PHP_PPA+=" software-properties-common"; fi
            if ! dpkg -s ca-certificates &> /dev/null; then APT_DEPS_PHP_PPA+=" ca-certificates"; fi
            if ! dpkg -s apt-transport-https &> /dev/null; then APT_DEPS_PHP_PPA+=" apt-transport-https"; fi
            if ! dpkg -s lsb-release &> /dev/null; then APT_DEPS_PHP_PPA+=" lsb-release"; fi
            
            if [ -n "$APT_DEPS_PHP_PPA" ]; then
                apt install -y $APT_DEPS_PHP_PPA > /dev/null 2>&1
            fi

            add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1
            apt update > /dev/null 2>&1
        fi
        sleep 1
    else
        sleep 0.5 # Mínimo sleep para consistencia de progreso en distros no-Debian/Ubuntu
    fi

    # 5. Añadir repositorio de NodeSource para Node.js 20 (LTS)
    update_progress "Añadiendo repositorio de Node.js 20 (LTS)..."
    # La comprobación para `curl` se hizo antes, así que debería estar disponible ahora.
    if ! command -v node &> /dev/null || [[ "$(node -v)" != "v20."* ]]; then
        if is_ubuntu_debian; then
            curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
        elif is_almalinux; then
            curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
        fi
    fi
    sleep 1

    # 6. Instalar Node.js y npm
    update_progress "Instalando Node.js y npm..."
    if ! command -v node &> /dev/null || [[ "$(node -v)" != "v20."* ]]; then
        if is_ubuntu_debian; then
            apt install -y nodejs > /dev/null 2>&1
        elif is_almalinux; then
            dnf install -y nodejs > /dev/null 2>&1
        fi
    fi
    sleep 1

    # 7. Instalar Apache2 (si no está instalado)
    update_progress "Verificando e instalando Apache2..."
    if is_ubuntu_debian; then
        if ! dpkg -s apache2 &> /dev/null; then
            apt install -y apache2 > /dev/null 2>&1
        fi
    elif is_almalinux; then
        if ! rpm -q httpd &> /dev/null; then
            dnf install -y httpd > /dev/null 2>&1
            systemctl enable --now httpd > /dev/null 2>&1
        fi
        systemctl is-active --quiet httpd || systemctl start httpd > /dev/null 2>&1
        systemctl is-enabled --quiet httpd || systemctl enable httpd > /dev/null 2>&1
    fi
    sleep 1

    # 8. Habilitar módulo mod_rewrite para Apache
    update_progress "Habilitando mod_rewrite y reiniciando Apache..."
    if is_ubuntu_debian; then
        a2enmod rewrite > /dev/null 2>&1
        systemctl restart apache2 > /dev/null 2>&1
    elif is_almalinux; then
        systemctl restart httpd > /dev/null 2>&1
    fi
    sleep 1

    # 9. Instalar PHP y extensiones (granular)
    if is_ubuntu_debian; then
        # Instalación del paquete principal de PHP
        update_progress "Instalando PHP ${PHP_VERSION}..."
        if ! dpkg -s php${PHP_VERSION} &> /dev/null; then
            apt install -y php${PHP_VERSION} > /dev/null 2>&1
        fi
        sleep 0.5

        # Instalación de extensiones de PHP
        update_progress "Instalando PHP ${PHP_VERSION}-cli..."
        if ! dpkg -s php${PHP_VERSION}-cli &> /dev/null; then
            apt install -y php${PHP_VERSION}-cli > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP ${PHP_VERSION}-common..."
        if ! dpkg -s php${PHP_VERSION}-common &> /dev/null; then
            apt install -y php${PHP_VERSION}-common > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP ${PHP_VERSION}-mysql..."
        if ! dpkg -s php${PHP_VERSION}-mysql &> /dev/null; then
            apt install -y php${PHP_VERSION}-mysql > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP ${PHP_VERSION}-xml..."
        if ! dpkg -s php${PHP_VERSION}-xml &> /dev/null; then
            apt install -y php${PHP_VERSION}-xml > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP ${PHP_VERSION}-mbstring..."
        if ! dpkg -s php${PHP_VERSION}-mbstring &> /dev/null; then
            apt install -y php${PHP_VERSION}-mbstring > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP ${PHP_VERSION}-zip..."
        if ! dpkg -s php${PHP_VERSION}-zip &> /dev/null; then
            apt install -y php${PHP_VERSION}-zip > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP ${PHP_VERSION}-gd..."
        if ! dpkg -s php${PHP_VERSION}-gd &> /dev/null; then
            apt install -y php${PHP_VERSION}-gd > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP ${PHP_VERSION}-curl..."
        if ! dpkg -s php${PHP_VERSION}-curl &> /dev/null; then
            apt install -y php${PHP_VERSION}-curl > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP ${PHP_VERSION}-fpm..."
        if ! dpkg -s php${PHP_VERSION}-fpm &> /dev/null; then
            apt install -y php${PHP_VERSION}-fpm > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Configurando módulo PHP para Apache..."
        if ! dpkg -s libapache2-mod-php${PHP_VERSION} &> /dev/null; then
             apt install -y libapache2-mod-php${PHP_VERSION} > /dev/null 2>&1
        fi
        a2enmod php${PHP_VERSION} > /dev/null 2>&1
        systemctl restart apache2 > /dev/null 2>&1
        sleep 0.5
    elif is_almalinux; then
        # Instalación del paquete principal de PHP
        update_progress "Instalando PHP (paquete base) para AlmaLinux..."
        if ! rpm -q php &> /dev/null; then
            dnf install -y php > /dev/null 2>&1
        fi
        sleep 0.5

        # Instalación de extensiones de PHP
        update_progress "Instalando PHP CLI..."
        if ! rpm -q php-cli &> /dev/null; then
            dnf install -y php-cli > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP MySQLnd..."
        if ! rpm -q php-mysqlnd &> /dev/null; then
            dnf install -y php-mysqlnd > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP XML..."
        if ! rpm -q php-xml &> /dev/null; then
            dnf install -y php-xml > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP MBString..."
        if ! rpm -q php-mbstring &> /dev/null; then
            dnf install -y php-mbstring > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP ZIP..."
        if ! rpm -q php-zip &> /dev/null; then
            dnf install -y php-zip > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP GD..."
        if ! rpm -q php-gd &> /dev/null; then
            dnf install -y php-gd > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP cURL..."
        if ! rpm -q php-curl &> /dev/null; then
            dnf install -y php-curl > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando PHP-FPM..."
        if ! rpm -q php-fpm &> /dev/null; then
            dnf install -y php-fpm > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Instalando httpd-devel (para PHP-FPM)..."
        if ! rpm -q httpd-devel &> /dev/null; then
            dnf install -y httpd-devel > /dev/null 2>&1
        fi
        sleep 0.5

        update_progress "Configurando PHP-FPM y Apache para AlmaLinux..."
        systemctl enable --now php-fpm > /dev/null 2>&1
        systemctl is-active --quiet php-fpm || systemctl start php-fpm > /dev/null 2>&1
        systemctl is-enabled --quiet php-fpm || systemctl enable php-fpm > /dev/null 2>&1
        # Añadir configuración ProxyPassMatch solo si no existe para evitar duplicados
        if ! grep -q "ProxyPassMatch" /etc/httpd/conf.d/php-fpm.conf &> /dev/null; then
            echo "<FilesMatch \.php$>" | tee -a /etc/httpd/conf.d/php-fpm.conf > /dev/null
            echo "    SetHandler \"proxy:fcgi://127.0.0.1:9000\"" | tee -a /etc/httpd/conf.d/php-fpm.conf > /dev/null
            echo "</FilesMatch>" | tee -a /etc/httpd/conf.d/php-fpm.conf > /dev/null
            echo "ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/var/www/html/$1" | tee -a /etc/httpd/conf.d/php-fpm.conf > /dev/null
            systemctl restart httpd > /dev/null 2>&1
        fi
        sleep 0.5
    fi
    sleep 1 # Un sleep final para el bloque de PHP

    # 10. Instalar la base de datos (MySQL/MariaDB)
    update_progress "Verificando e instalando $DB_TYPE..."
    if is_ubuntu_debian; then
        if ! dpkg -s "$DB_PACKAGE" &> /dev/null; then
            DEBIAN_FRONTEND=noninteractive apt install -y "$DB_PACKAGE" > /dev/null 2>&1
        fi
    elif is_almalinux; then
        if ! rpm -q "$DB_PACKAGE" &> /dev/null; then
            dnf install -y "$DB_PACKAGE" > /dev/null 2>&1
        fi
        systemctl enable --now "$DB_PACKAGE" > /dev/null 2>&1
        systemctl is-active --quiet "$DB_PACKAGE" || systemctl start "$DB_PACKAGE" > /dev/null 2>&1
        systemctl is-enabled --quiet "$DB_PACKAGE" || systemctl enable "$DB_PACKAGE" > /dev/null 2>&1
    fi
    sleep 1

    # 11. Configurar contraseña para el usuario root de la base de datos
    update_progress "Configurando contraseña de root para $DB_TYPE..."
    # En Debian/Ubuntu, MySQL/MariaDB por defecto usa auth_socket.
    # Necesitamos cambiarlo a mysql_native_password para poder usar la contraseña.
    # En AlmaLinux, MariaDB por defecto también puede usar auth_socket.
    # Aseguramos que el usuario root pueda autenticarse con la contraseña.
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DB_ROOT_PASSWORD';" > /dev/null 2>&1
    mysql -u root -p"$DB_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;" > /dev/null 2>&1
    sleep 1

    # 12. Instalar phpMyAdmin
    update_progress "Verificando e instalando phpMyAdmin..."
    if is_ubuntu_debian; then
        if ! dpkg -s phpmyadmin &> /dev/null; then
            # Pre-seed answers for debconf to automate phpMyAdmin installation
            echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_PASSWORD" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DB_ROOT_PASSWORD" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_PASSWORD" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
            DEBIAN_FRONTEND=noninteractive apt install -y phpmyadmin > /dev/null 2>&1
        fi
    elif is_almalinux; then
        if ! rpm -q phpmyadmin &> /dev/null; then
            # Enable EPEL if not already enabled (phpMyAdmin is in EPEL)
            if ! rpm -q epel-release &> /dev/null; then
                dnf install -y epel-release > /dev/null 2>&1
            fi
            dnf install -y phpmyadmin > /dev/null 2>&1
        fi
    fi
    sleep 1

    # 13. Configurar phpMyAdmin y crear usuario de base de datos
    update_progress "Configurando phpMyAdmin y usuario de base de datos..."
    if is_ubuntu_debian; then
        # dbconfig-common debería haber creado el usuario. Solo aseguramos permisos.
        mysql -u root -p"$DB_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'phpmyadmin'@'localhost' IDENTIFIED BY '$PHPMYADMIN_PASSWORD';" > /dev/null 2>&1
        mysql -u root -p"$DB_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;" > /dev/null 2>&1
        systemctl restart apache2 > /dev/null 2>&1
    elif is_almalinux; then
        # Crear usuario phpmyadmin en la base de datos
        mysql -u root -p"$DB_ROOT_PASSWORD" -e "CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED BY '$PHPMYADMIN_PASSWORD';" > /dev/null 2>&1
        mysql -u root -p"$DB_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;" > /dev/null 2>&1
        mysql -u root -p"$DB_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;" > /dev/null 2>&1

        # Configurar Apache para phpMyAdmin (Alias) si no existe
        if ! grep -q "Alias /phpmyadmin" /etc/httpd/conf.d/phpmyadmin.conf &> /dev/null; then
            echo "Alias /phpmyadmin /usr/share/phpMyAdmin" | tee /etc/httpd/conf.d/phpmyadmin.conf > /dev/null
            echo "<Directory /usr/share/phpMyAdmin>" | tee -a /etc/httpd/conf.d/phpmyadmin.conf > /dev/null
            echo "    AddType application/x-httpd-php .php" | tee -a /etc/httpd/conf.d/phpmyadmin.conf > /dev/null
            echo "    DirectoryIndex index.php" | tee -a /etc/httpd/conf.d/phpmyadmin.conf > /dev/null
            echo "    <IfModule mod_authz_core.c>" | tee -a /etc/httpd/conf.d/phpmyadmin.conf > /dev/null
            echo "        # Apache 2.4" | tee -a /etc/httpd/conf.d/phpmyadmin.conf > /dev/null
            echo "        Require all granted" | tee -a /etc/httpd/conf.d/phpmyadmin.conf > /dev/null
            echo "    </IfModule>" | tee -a /etc/httpd/conf.d/phpmyadmin.conf > /dev/null
            systemctl restart httpd > /dev/null 2>&1
        fi
    fi
    sleep 1

    # 14. Instalar Composer
    update_progress "Verificando e instalando Composer..."
    if ! command -v composer &> /dev/null; then
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" > /dev/null 2>&1
        php composer-setup.php --install-dir=/usr/local/bin --filename=composer > /dev/null 2>&1
        rm composer-setup.php > /dev/null 2>&1
    fi
    sleep 1

    # 15. Instalar Laravel Installer y configurar PATH (MEJORA CLAVE)
    update_progress "Instalando Laravel Installer..."
    
    # Directorio donde Composer instala los binarios globales
    COMPOSER_GLOBAL_BIN_DIR=""
    # Primero intentamos el path moderno
    if [ -d "/root/.config/composer/vendor/bin" ]; then
        COMPOSER_GLOBAL_BIN_DIR="/root/.config/composer/vendor/bin"
    # Si no, el path antiguo
    elif [ -d "/root/.composer/vendor/bin" ]; then
        COMPOSER_GLOBAL_BIN_DIR="/root/.composer/vendor/bin"
    fi

    # -----------------------------------------------------------------------------------
    # *** ESTA ES LA LÍNEA CRÍTICA PARA EL PROBLEMA DEL PATH EN TIEMPO DE EJECUCIÓN ***
    # Asegura que el PATH del *script actual* se actualice si el directorio de Composer existe
    # -----------------------------------------------------------------------------------
    if [ -n "$COMPOSER_GLOBAL_BIN_DIR" ] && [[ ":$PATH:" != *":$COMPOSER_GLOBAL_BIN_DIR:"* ]]; then
        export PATH="$PATH:$COMPOSER_GLOBAL_BIN_DIR"
        echo "DEBUG: PATH actualizado a: $PATH" > /dev/stderr # Línea de depuración para ver el PATH
    fi

    # Instalar laravel/installer si no está ya disponible
    if ! command -v laravel &> /dev/null; then
        if ! command -v composer &> /dev/null; then
            echo "ERROR: Composer no encontrado en PATH. No se puede instalar Laravel Installer." > /dev/stderr
            echo 100
            echo "XXX"
            echo "ERROR: Composer no encontrado. Revisa la instalación."
            echo "XXX"
            sleep 2
            exit 1
        fi
        composer global require laravel/installer --no-interaction > /dev/null 2>&1
        
        # Después de la instalación global, volvemos a verificar y exportar el PATH
        # por si la instalación creó el directorio binario o lo cambió
        if [ -d "/root/.config/composer/vendor/bin" ]; then
            COMPOSER_GLOBAL_BIN_DIR="/root/.config/composer/vendor/bin"
        elif [ -d "/root/.composer/vendor/bin" ]; then
            COMPOSER_GLOBAL_BIN_DIR="/root/.composer/vendor/bin"
        fi
        
        if [ -n "$COMPOSER_GLOBAL_BIN_DIR" ] && [[ ":$PATH:" != *":$COMPOSER_GLOBAL_BIN_DIR:"* ]]; then
            export PATH="$PATH:$COMPOSER_GLOBAL_BIN_DIR"
            echo "DEBUG: PATH RE-actualizado después de instalar laravel/installer: $PATH" > /dev/stderr # Línea de depuración
        fi
    fi
    
    # Finalmente, agrega la línea al .bashrc para futuras sesiones (para el usuario root)
    # Solo si no existe ya
    EXPORT_PATH_LINE="export PATH=\"\$PATH:$COMPOSER_GLOBAL_BIN_DIR\""
    if [ -n "$COMPOSER_GLOBAL_BIN_DIR" ] && ! grep -qxF "$EXPORT_PATH_LINE" "/root/.bashrc"; then
        echo "$EXPORT_PATH_LINE" >> "/root/.bashrc"
    fi
    sleep 1 # Pequeña pausa después de la configuración del PATH

    # 16. Crear directorio /var/www/laravel
    update_progress "Creando directorio /var/www/laravel..."
    mkdir -p /var/www/laravel > /dev/null 2>&1
    sleep 1

    # 17. Crear proyecto Laravel dentro de /var/www/laravel con Pest
    update_progress "Creando proyecto Laravel '$PROJECT_NAME' con Pest en /var/www/laravel..."
    # Mover al directorio donde se creará el proyecto
    cd /var/www/laravel/ > /dev/null 2>&1

    # --- INICIO DE DEPURACION ---
    echo "DEBUG: Valor de PROJECT_NAME antes de laravel new: '$PROJECT_NAME'" > /dev/stderr
    echo "DEBUG: Comando a ejecutar: laravel new \"$PROJECT_NAME\" --no-interaction --pest" > /dev/stderr
    echo "DEBUG: PATH actual para la ejecución de laravel new: $PATH" > /dev/stderr # Añadida para depurar el PATH
    # --- FIN DE DEPURACION ---

    # Ejecutar el comando laravel new. La salida NO se redirige a /dev/null para ver errores.
    laravel new "$PROJECT_NAME" --no-interaction --pest
    # Verificar el código de salida del comando anterior
    if [ $? -ne 0 ]; then
        echo "ERROR: Falló la creación del proyecto Laravel con 'laravel new \"$PROJECT_NAME\"'. Revisa los mensajes de error anteriores." > /dev/stderr
        echo 100
        echo "XXX"
        echo "ERROR: Falló la creación del proyecto Laravel."
        echo "XXX"
        sleep 2
        exit 1
    fi

    sleep 2

    # 18. Configurar .env del proyecto Laravel para la base de datos
    update_progress "Configurando archivo .env para la base de datos..."
    PROJECT_PATH="/var/www/laravel/$PROJECT_NAME"
    DB_NAME=$(echo "$PROJECT_NAME" | tr '-' '_' | tr '.' '_') # Convierte el nombre del proyecto a un nombre de BD válido
    DB_CONNECTION_TYPE="mysql" # Asumiendo MySQL para Laravel, incluso si el backend es MariaDB

    # Edita el archivo .env para configurar la conexión a la base de datos
    sed -i "/^DB_DATABASE=/c\DB_DATABASE=$DB_NAME" "$PROJECT_PATH/.env" > /dev/null 2>&1
    sed -i "/^DB_USERNAME=/c\DB_USERNAME=$DB_ROOT_USER" "$PROJECT_PATH/.env" > /dev/null 2>&1
    sed -i "/^DB_PASSWORD=/c\DB_PASSWORD=$DB_ROOT_PASSWORD" "$PROJECT_PATH/.env" > /dev/null 2>&1
    sed -i "/^DB_CONNECTION=/c\DB_CONNECTION=$DB_CONNECTION_TYPE" "$PROJECT_PATH/.env" > /dev/null 2>&1
    sed -i "/^DB_PORT=/c\DB_PORT=$DB_PORT" "$PROJECT_PATH/.env" > /dev/null 2>&1
    sleep 1

    # 19. Crear la base de datos para el proyecto
    update_progress "Creando base de datos '$DB_NAME' para el proyecto..."
    mysql -u "$DB_ROOT_USER" -p"$DB_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" > /dev/null 2>&1
    sleep 1

    # 20. Ejecutar php artisan migrate
    update_progress "Ejecutando migraciones de Laravel..."
    cd "$PROJECT_PATH" > /dev/null 2>&1
    php artisan migrate --force > /dev/null 2>&1
    sleep 2

    # 21. Instalar paquete de idioma español para Laravel
    update_progress "Instalando paquete de idioma español (laravel-lang/lang)..."
    cd "$PROJECT_PATH" > /dev/null 2>&1
    composer require laravel-lang/lang --no-interaction > /dev/null 2>&1
    sleep 2

    # 22. Publicar archivos de idioma español
    update_progress "Publicando archivos de idioma español..."
    php artisan lang:publish es --no-interaction > /dev/null 2>&1
    sleep 1

    # 23. Configurar el idioma por defecto en config/app.php
    update_progress "Configurando idioma por defecto a español en config/app.php..."
    sed -i "s/^    'locale' => 'en',/    'locale' => 'es',/" "$PROJECT_PATH/config/app.php" > /dev/null 2>&1
    sleep 0.5

    # 24. Ejecutar npm install
    update_progress "Ejecutando npm install para dependencias frontend..."
    cd "$PROJECT_PATH" > /dev/null 2>&1
    # La salida no se redirige a /dev/null para ver errores.
    npm install --silent
    sleep 3

    # 25. Ejecutar npm run build (o npm run dev)
    update_progress "Compilando assets frontend con npm run build..."
    cd "$PROJECT_PATH" > /dev/null 2>&1
    # La salida no se redirige a /dev/null para ver errores.
    npm run build --silent
    sleep 3

    # 26. Configurar permisos del proyecto Laravel
    update_progress "Configurando permisos del proyecto Laravel..."
    # Establecer propietario del directorio del proyecto al usuario de Apache
    if is_ubuntu_debian; then
        chown -R www-data:www-data "/var/www/laravel/$PROJECT_NAME" > /dev/null 2>&1
    elif is_almalinux; then
        chown -R apache:apache "/var/www/laravel/$PROJECT_NAME" > /dev/null 2>&1
    fi
    # Establecer permisos de escritura para storage y bootstrap/cache
    chmod -R 775 "/var/www/laravel/$PROJECT_NAME/storage" > /dev/null 2>&1
    chmod -R 775 "/var/www/laravel/$PROJECT_NAME/bootstrap/cache" > /dev/null 2>&1
    sleep 1

    # 27. Configurar Virtual Host de Apache para el proyecto Laravel
    update_progress "Configurando Virtual Host de Apache para '$PROJECT_NAME.test'..."
    # El nombre de dominio local
    LOCAL_DOMAIN="$PROJECT_NAME.test"

    VHOST_CONFIG="<VirtualHost *:80>
    ServerAdmin webmaster@$LOCAL_DOMAIN
    DocumentRoot /var/www/laravel/$PROJECT_NAME/public
    ServerName $LOCAL_DOMAIN
    <Directory /var/www/laravel/$PROJECT_NAME/public>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>"

    if is_ubuntu_debian; then
        echo "$VHOST_CONFIG" | tee "/etc/apache2/sites-available/$PROJECT_NAME.test.conf" > /dev/null
        a2ensite "$PROJECT_NAME.test.conf" > /dev/null 2>&1
        a2dissite 000-default.conf > /dev/null 2>&1 # Deshabilitar el sitio por defecto si aún está habilitado
        systemctl restart apache2 > /dev/null 2>&1
    elif is_almalinux; then
        echo "$VHOST_CONFIG" | tee "/etc/httpd/conf.d/$PROJECT_NAME.test.conf" > /dev/null
        systemctl restart httpd > /dev/null 2>&1
    fi
    sleep 1

    # 28. Modificar el archivo /etc/hosts para el dominio local
    update_progress "Agregando '$PROJECT_NAME.test' al archivo /etc/hosts..."
    LOCAL_HOSTS_ENTRY="127.0.0.1\t$LOCAL_DOMAIN"
    # Verificar si la entrada ya existe para evitar duplicados
    if ! grep -q -P "^127\.0\.0\.1\s+${LOCAL_DOMAIN//./\\.}" /etc/hosts; then # Usamos -P para regex de Perl y escapamos los puntos
        echo -e "$LOCAL_HOSTS_ENTRY" | tee -a /etc/hosts > /dev/null
    fi
    sleep 0.5

    # Lógica para software adicional (ahora solo si el usuario lo seleccionó)
    if [[ "$ADDITIONAL_SOFTWARE" == *"vscode"* ]]; then
        update_progress "Instalando Visual Studio Code..." # Esto se actualizará en base al peso de esta tarea en TASK_WEIGHTS
        # Verificar si VS Code ya está instalado
        if ! command -v code &> /dev/null; then
            # Comandos de instalación para VS Code
            if is_ubuntu_debian; then
                VSCODE_DEPS=""
                if ! dpkg -s wget &> /dev/null; then VSCODE_DEPS+=" wget"; fi
                if ! dpkg -s apt-transport-https &> /dev/null; then VSCODE_DEPS+=" apt-transport-https"; fi
                if [ -n "$VSCODE_DEPS" ]; then apt install -y $VSCODE_DEPS > /dev/null 2>&1; fi

                wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
                install -D -o -g -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg > /dev/null 2>&1
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null
                rm packages.microsoft.gpg
                apt update > /dev/null 2>&1
                apt install -y code > /dev/null 2>&1
            elif is_almalinux; then
                if ! rpm -q wget &> /dev/null; then dnf install -y wget > /dev/null 2>&1; fi
                rpm --import https://packages.microsoft.com/keys/microsoft.asc > /dev/null 2>&1
                echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null
                dnf check-update > /dev/null 2>&1
                dnf install -y code > /dev/null 2>&1
            fi
            sleep 3
        else
            update_progress "Visual Studio Code ya está instalado. Omitiendo..."
            sleep 0.5
        fi
    fi

    if [[ "$ADDITIONAL_SOFTWARE" == *"sublime"* ]]; then
        update_progress "Instalando Sublime Text..."
        # Verificar si Sublime Text ya está instalado
        if ! command -v subl &> /dev/null; then # 'subl' es el comando para Sublime Text
            # Comandos de instalación para Sublime Text
            if is_ubuntu_debian; then
                SUBLIME_DEPS=""
                if ! dpkg -s wget &> /dev/null; then SUBLIME_DEPS+=" wget"; fi
                if ! dpkg -s apt-transport-https &> /dev/null; then SUBLIME_DEPS+=" apt-transport-https"; fi
                if [ -n "$SUBLIME_DEPS" ]; then apt install -y $SUBLIME_DEPS > /dev/null 2>&1; fi

                wget -qO - https://download.sublimetext.com/apt/rpm-pub-key.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
                echo "deb https://download.sublimetext.com/apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list > /dev/null
                apt update > /dev/null 2>&1
                apt install -y sublime-text > /dev/null 2>&1
            elif is_almalinux; then
                if ! rpm -q wget &> /dev/null; then dnf install -y wget > /dev/null 2>&1; fi
                rpm -v --import https://download.sublimetext.com/rpm/rpmkey.gpg > /dev/null 2>&1
                echo -e "[sublime-text]\nname=Sublime Text\nbaseurl=https://download.sublimetext.com/rpm/stable/\nenabled=1\ngpgcheck=1\nrpm_gpg_check=1" | tee /etc/yum.repos.d/sublime-text.repo > /dev/null
                dnf install -y sublime-text > /dev/null 2>&1
            fi
            sleep 3
        else
            update_progress "Sublime Text ya está instalado. Omitiendo..."
            sleep 0.5
        fi
    fi

    if [[ "$ADDITIONAL_SOFTWARE" == *"brave"* ]]; then
        update_progress "Instalando Brave Browser..."
        # Verificar si Brave Browser ya está instalado
        if ! command -v brave-browser &> /dev/null; then
            # Comandos de instalación para Brave Browser
            if is_ubuntu_debian; then
                # curl ya se instala en el paso 3
                curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg > /dev/null 2>&1
                echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
                apt update > /dev/null 2>&1
                apt install -y brave-browser > /dev/null 2>&1
            elif is_almalinux; then
                # curl ya se instala en el paso 3
                rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc > /dev/null 2>&1
                echo -e "[brave-browser]\nname=Brave Browser\nbaseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64/\nenabled=1\ngpgcheck=1\ngpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc" | tee /etc/yum.repos.d/brave-browser.repo > /dev/null
                dnf install -y brave-browser > /dev/null 2>&1
            fi
            sleep 3
        else
            update_progress "Brave Browser ya está instalado. Omitiendo..."
            sleep 0.5
        fi
    fi

    if [[ "$ADDITIONAL_SOFTWARE" == *"chrome"* ]]; then
        update_progress "Instalando Google Chrome..."
        # Verificar si Google Chrome ya está instalado
        if ! command -v google-chrome &> /dev/null; then
            # Comandos de instalación para Google Chrome
            if is_ubuntu_debian; then
                CHROME_DEPS=""
                if ! dpkg -s wget &> /dev/null; then CHROME_DEPS+=" wget"; fi
                if ! dpkg -s apt-transport-https &> /dev/null; then CHROME_DEPS+=" apt-transport-https"; fi
                if ! dpkg -s gnupg &> /dev/null; then CHROME_DEPS+=" gnupg"; fi
                if [ -n "$CHROME_DEPS" ]; then apt install -y $CHROME_DEPS > /dev/null 2>&1; fi

                # Descargar la clave de Google
                wget -qO- https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /etc/apt/keyrings/google-chrome.gpg > /dev/null
                # Añadir el repositorio de Google Chrome
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
                # Actualizar listas de paquetes e instalar Google Chrome
                apt update > /dev/null 2>&1
                apt install -y google-chrome-stable > /dev/null 2>&1
            elif is_almalinux; then
                if ! rpm -q wget &> /dev/null; then dnf install -y wget > /dev/null 2>&1; fi
                # Añadir el repositorio de Google Chrome para Fedora/RHEL
                echo -e "[google-chrome]\nname=google-chrome\nbaseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64\nenabled=1\ngpgcheck=1\ngpgkey=https://dl.google.com/linux/linux_signing_key.pub" | tee /etc/yum.repos.d/google-chrome.repo > /dev/null
                dnf install -y google-chrome-stable > /dev/null 2>&1
            fi
            sleep 3
        else
            update_progress "Google Chrome ya está instalado. Omitiendo..."
            sleep 0.5
        fi
    fi

    update_progress "Finalizando configuraciones..."
    sleep 2

    echo 100
    echo "XXX"
    echo "Instalación completada."
    echo "XXX"
    sleep 1

) | dialog --gauge "Instalando paquetes y configurando el entorno..." 10 70 0

# --- Fin de la Barra de Progreso ---

clear
# Mensaje final detallado para el usuario
dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
--title "Instalacion Finalizada" \
--msgbox "\n¡La instalacion de Laravel 12 y los componentes seleccionados ha finalizado con exito!\n\nTu proyecto Laravel '$PROJECT_NAME' ha sido creado en /var/www/laravel/$PROJECT_NAME.\n\nLa base de datos '$DB_NAME' ha sido creada y configurada en el archivo .env.\n\nEl idioma español se ha configurado como predeterminado para tu proyecto.\n\nEl dominio local 'http://$PROJECT_NAME.test' ha sido configurado en Apache y añadido a tu archivo /etc/hosts.\n\nAhora puedes acceder a tu proyecto en el navegador visitando:\n    http://$PROJECT_NAME.test\n\nPara que el comando 'laravel' funcione, por favor, abre una nueva terminal o ejecuta:\n\n    source ~/.bashrc\n\nPresiona OK para salir." 24 75
clear

exit 0
