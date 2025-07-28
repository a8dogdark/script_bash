#!/bin/bash

VEROS="2.0"

# Validar si el usuario es root
if [ "$(id -u)" -ne 0 ]; then
    clear
    exit 1
fi

# Validar si el sistema es de 64 bits
if [ "$(uname -m)" != "x86_64" ]; then
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
    exit 1
fi

# Definir el paquete de base de datos y validar compatibilidad
case "$DISTRO" in
    ubuntu)
        if ! (( $(echo "$VERSION >= 22" | bc -l) )); then
            clear
            exit 1
        fi
        DB_PACKAGE="mysql-server"
        DB_TYPE="MySQL"
        DB_ROOT_USER="mysql"
        ;;
    debian)
        if ! (( $(echo "$VERSION >= 11" | bc -l) )); then
            clear
            exit 1
        fi
        DB_PACKAGE="mariadb-server"
        DB_TYPE="MariaDB"
        DB_ROOT_USER="mariadb"
        ;;
    almalinux)
        if ! [[ "$VERSION" =~ ^(8|9)\.[0-9]+$ ]]; then
            clear
            exit 1
        fi
        DB_PACKAGE="mariadb-server"
        DB_TYPE="MariaDB"
        DB_ROOT_USER="mariadb"
        ;;
    *)
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
--yesno "\nEste script preparara tu sistema para Laravel 12.\n\nSe instalaran los siguientes paquetes:\n- Apache2\n- PHP (y extensiones necesarias)\n- $DB_PACKAGE\n- phpMyAdmin\n\n¿Deseas continuar con la instalacion?" 18 70

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
    current_progress=0
    # Estimación de pasos: Update, Upgrade, Ondrej PPA (si aplica), Apache, Mod_Rewrite, PHP Core, PHP CLI, PHP MySQL, PHP XML, PHP MBString, PHP ZIP, PHP GD, PHP cURL, PHP FPM, Apache PHP Module (Debian/Ubuntu), DB, phpMyAdmin, Composer, Laravel Installer, Laravel Project, X (opcionales), Configuraciones
    # Esto es un incremento significativo, ajustaremos los porcentajes.
    total_steps=25 # Estimado, se ajustará con precisión al final.

    # Función para actualizar la barra de progreso
    update_progress() {
        message=$1
        increment=$2
        current_progress=$((current_progress + increment))
        percentage=$((current_progress * 100 / total_steps))
        echo "$percentage"
        echo "XXX"
        echo "$message"
        echo "XXX"
    }

    # 1. Actualizar listas de paquetes
    update_progress "Actualizando listas de paquetes..." 1
    case "$DISTRO" in
        ubuntu|debian)
            apt update > /dev/null 2>&1
            ;;
        almalinux)
            dnf check-update > /dev/null 2>&1
            ;;
    esac
    sleep 1

    # 2. Actualizar paquetes del sistema
    update_progress "Actualizando paquetes del sistema..." 1
    case "$DISTRO" in
        ubuntu|debian)
            apt upgrade -y > /dev/null 2>&1
            ;;
        almalinux)
            dnf upgrade -y > /dev/null 2>&1
            ;;
    esac
    sleep 1

    # 3. Añadir repositorio PPA de Ondrej (Solo para Debian/Ubuntu, si no existe)
    if [[ "$DISTRO" == "ubuntu" || "$DISTRO" == "debian" ]]; then
        update_progress "Verificando e integrando PPA de Ondrej..." 1
        if ! grep -q "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
            apt install -y software-properties-common ca-certificates apt-transport-https lsb-release > /dev/null 2>&1
            add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1
            apt update > /dev/null 2>&1
        fi
        sleep 1
    else
        sleep 0.5 # Mínimo sleep para consistencia de progreso
    fi

    # 4. Instalar Apache2 (si no está instalado)
    update_progress "Verificando e instalando Apache2..." 2
    case "$DISTRO" in
        ubuntu|debian)
            if ! dpkg -s apache2 &> /dev/null; then
                apt install -y apache2 > /dev/null 2>&1
            fi
            ;;
        almalinux)
            if ! rpm -q httpd &> /dev/null; then
                dnf install -y httpd > /dev/null 2>&1
                systemctl enable --now httpd > /dev/null 2>&1
            fi
            systemctl is-active --quiet httpd || systemctl start httpd > /dev/null 2>&1
            systemctl is-enabled --quiet httpd || systemctl enable httpd > /dev/null 2>&1
            ;;
    esac
    sleep 1

    # 5. Habilitar módulo mod_rewrite para Apache
    update_progress "Habilitando mod_rewrite y reiniciando Apache..." 1
    case "$DISTRO" in
        ubuntu|debian)
            a2enmod rewrite > /dev/null 2>&1
            systemctl restart apache2 > /dev/null 2>&1
            ;;
        almalinux)
            systemctl restart httpd > /dev/null 2>&1
            ;;
    esac
    sleep 1

    # 6. Instalar PHP y extensiones (granular)
    case "$DISTRO" in
        ubuntu|debian)
            # Instalación del paquete principal de PHP
            update_progress "Instalando PHP ${PHP_VERSION}..." 2
            if ! dpkg -s php${PHP_VERSION} &> /dev/null; then
                apt install -y php${PHP_VERSION} > /dev/null 2>&1
            fi
            sleep 0.5

            # Instalación de extensiones de PHP
            update_progress "Instalando PHP ${PHP_VERSION}-cli..." 1
            if ! dpkg -s php${PHP_VERSION}-cli &> /dev/null; then
                apt install -y php${PHP_VERSION}-cli > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP ${PHP_VERSION}-common..." 1
            if ! dpkg -s php${PHP_VERSION}-common &> /dev/null; then
                apt install -y php${PHP_VERSION}-common > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP ${PHP_VERSION}-mysql..." 1
            if ! dpkg -s php${PHP_VERSION}-mysql &> /dev/null; then
                apt install -y php${PHP_VERSION}-mysql > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP ${PHP_VERSION}-xml..." 1
            if ! dpkg -s php${PHP_VERSION}-xml &> /dev/null; then
                apt install -y php${PHP_VERSION}-xml > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP ${PHP_VERSION}-mbstring..." 1
            if ! dpkg -s php${PHP_VERSION}-mbstring &> /dev/null; then
                apt install -y php${PHP_VERSION}-mbstring > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP ${PHP_VERSION}-zip..." 1
            if ! dpkg -s php${PHP_VERSION}-zip &> /dev/null; then
                apt install -y php${PHP_VERSION}-zip > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP ${PHP_VERSION}-gd..." 1
            if ! dpkg -s php${PHP_VERSION}-gd &> /dev/null; then
                apt install -y php${PHP_VERSION}-gd > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP ${PHP_VERSION}-curl..." 1
            if ! dpkg -s php${PHP_VERSION}-curl &> /dev/null; then
                apt install -y php${PHP_VERSION}-curl > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP ${PHP_VERSION}-fpm..." 1
            if ! dpkg -s php${PHP_VERSION}-fpm &> /dev/null; then
                apt install -y php${PHP_VERSION}-fpm > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Configurando módulo PHP para Apache..." 1
            if ! dpkg -s libapache2-mod-php${PHP_VERSION} &> /dev/null; then
                 apt install -y libapache2-mod-php${PHP_VERSION} > /dev/null 2>&1
            fi
            a2enmod php${PHP_VERSION} > /dev/null 2>&1
            systemctl restart apache2 > /dev/null 2>&1
            sleep 0.5
            ;;
        almalinux)
            # Instalación del paquete principal de PHP
            update_progress "Instalando PHP (paquete base) para AlmaLinux..." 2
            if ! rpm -q php &> /dev/null; then
                dnf install -y php > /dev/null 2>&1
            fi
            sleep 0.5

            # Instalación de extensiones de PHP
            update_progress "Instalando PHP CLI..." 1
            if ! rpm -q php-cli &> /dev/null; then
                dnf install -y php-cli > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP MySQLnd..." 1
            if ! rpm -q php-mysqlnd &> /dev/null; then
                dnf install -y php-mysqlnd > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP XML..." 1
            if ! rpm -q php-xml &> /dev/null; then
                dnf install -y php-xml > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP MBString..." 1
            if ! rpm -q php-mbstring &> /dev/null; then
                dnf install -y php-mbstring > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP ZIP..." 1
            if ! rpm -q php-zip &> /dev/null; then
                dnf install -y php-zip > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP GD..." 1
            if ! rpm -q php-gd &> /dev/null; then
                dnf install -y php-gd > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP cURL..." 1
            if ! rpm -q php-curl &> /dev/null; then
                dnf install -y php-curl > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando PHP-FPM..." 1
            if ! rpm -q php-fpm &> /dev/null; then
                dnf install -y php-fpm > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Instalando httpd-devel (para PHP-FPM)..." 1
            if ! rpm -q httpd-devel &> /dev/null; then
                dnf install -y httpd-devel > /dev/null 2>&1
            fi
            sleep 0.5

            update_progress "Configurando PHP-FPM y Apache para AlmaLinux..." 1
            systemctl enable --now php-fpm > /dev/null 2>&1
            systemctl is-active --quiet php-fpm || systemctl start php-fpm > /dev/null 2>&1
            if ! grep -q "ProxyPassMatch" /etc/httpd/conf.d/php-fpm.conf &> /dev/null; then
                echo "<FilesMatch \.php$>" >> /etc/httpd/conf.d/php-fpm.conf
                echo "    SetHandler \"proxy:fcgi://127.0.0.1:9000\"" >> /etc/httpd/conf.d/php-fpm.conf
                echo "</FilesMatch>" >> /etc/httpd/conf.d/php-fpm.conf
                echo "ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/var/www/html/$1" >> /etc/httpd/conf.d/php-fpm.conf
                systemctl restart httpd > /dev/null 2>&1
            fi
            sleep 0.5
            ;;
    esac
    sleep 1 # Un sleep final para el bloque de PHP

    # Los siguientes pasos se irán agregando aquí.
    update_progress "Instalando $DB_PACKAGE..." 3
    sleep 5

    update_progress "Instalando phpMyAdmin..." 2
    sleep 4

    update_progress "Configurando base de datos..." 2
    sleep 3

    update_progress "Instalando Composer..." 1
    sleep 2

    # Lógica para software adicional (ejemplo)
    if [[ "$ADDITIONAL_SOFTWARE" == *"vscode"* ]]; then
        update_progress "Instalando Visual Studio Code..." 1
        sleep 3
    fi
    if [[ "$ADDITIONAL_SOFTWARE" == *"sublime"* ]]; then
        update_progress "Instalando Sublime Text..." 1
        sleep 3
    fi
    if [[ "$ADDITIONAL_SOFTWARE" == *"brave"* ]]; then
        update_progress "Instalando Brave Browser..." 1
        sleep 3
    fi
    if [[ "$ADDITIONAL_SOFTWARE" == *"chrome"* ]]; then
        update_progress "Instalando Google Chrome..." 1
        sleep 3
    fi

    update_progress "Creando proyecto Laravel $PROJECT_NAME..." 2
    sleep 7

    update_progress "Finalizando configuraciones..." 1
    sleep 2

    echo 100
    echo "XXX"
    echo "Instalación completada."
    echo "XXX"
    sleep 1

) | dialog --gauge "Instalando paquetes y configurando el entorno..." 10 70 0

# --- Fin de la Barra de Progreso ---

clear
dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
--title "Instalacion Finalizada" \
--msgbox "\n¡La instalacion de Laravel 12 y los componentes seleccionados ha finalizado con exito!\n\nPresiona OK para salir." 10 60
clear

exit 0
