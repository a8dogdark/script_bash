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
        DB_PORT="3306"
        ;;
    debian)
        if ! (( $(echo "$VERSION >= 11" | bc -l) )); then
            clear
            exit 1
        fi
        DB_PACKAGE="mariadb-server"
        DB_TYPE="MariaDB"
        DB_ROOT_USER="mariadb"
        DB_PORT="3306"
        ;;
    almalinux)
        if ! [[ "$VERSION" =~ ^(8|9)\.[0-9]+$ ]]; then
            clear
            exit 1
        fi
        DB_PACKAGE="mariadb-server"
        DB_TYPE="MariaDB"
        DB_ROOT_USER="mariadb"
        DB_PORT="3306"
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
--yesno "\nEste script preparara tu sistema para Laravel 12.\n\nSe instalaran los siguientes paquetes:\n- Apache2\n- PHP (y extensiones necesarias)\n- $DB_PACKAGE\n- phpMyAdmin\n- Node.js\n\n¿Deseas continuar con la instalacion?" 18 70

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
    # Estimación de pasos: Update, Upgrade, Ondrej PPA (si aplica), NodeSource Repo, Node.js, Apache, Mod_Rewrite, PHP Core, PHP CLI, PHP MySQL, PHP XML, PHP MBString, PHP ZIP, PHP GD, PHP cURL, PHP FPM, Apache PHP Module (Debian/Ubuntu), DB, DB Root Password, phpMyAdmin, phpMyAdmin config, Composer, Composer PATH, Laravel Installer, Create Laravel Dir, Laravel Project (con Pest), Configure .env, Create DB for Project, Migrate DB, Install Laravel-lang, Publish Laravel-lang, Configure app.php locale, Npm Install, Npm Run Build, Permissions, Apache Virtual Host, Update Hosts File, X (opcionales), Configuraciones
    total_steps=48 # Ajustado para incluir la modificación del archivo hosts

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

    # 4. Añadir repositorio de NodeSource para Node.js 20 (LTS)
    update_progress "Añadiendo repositorio de Node.js 20 (LTS)..." 2
    if ! command -v node &> /dev/null || [[ "$(node -v)" != "v20."* ]]; then
        case "$DISTRO" in
            ubuntu|debian)
                curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
                ;;
            almalinux)
                curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
                ;;
        esac
    fi
    sleep 1

    # 5. Instalar Node.js y npm
    update_progress "Instalando Node.js y npm..." 2
    if ! command -v node &> /dev/null || [[ "$(node -v)" != "v20."* ]]; then
        case "$DISTRO" in
            ubuntu|debian)
                apt install -y nodejs > /dev/null 2>&1
                ;;
            almalinux)
                dnf install -y nodejs > /dev/null 2>&1
                ;;
        esac
    fi
    sleep 1

    # 6. Instalar Apache2 (si no está instalado)
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

    # 7. Habilitar módulo mod_rewrite para Apache
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

    # 8. Instalar PHP y extensiones (granular)
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

    # 9. Instalar la base de datos (MySQL/MariaDB)
    update_progress "Verificando e instalando $DB_TYPE..." 3
    case "$DISTRO" in
        ubuntu|debian)
            if ! dpkg -s "$DB_PACKAGE" &> /dev/null; then
                DEBIAN_FRONTEND=noninteractive apt install -y "$DB_PACKAGE" > /dev/null 2>&1
            fi
            ;;
        almalinux)
            if ! rpm -q "$DB_PACKAGE" &> /dev/null; then
                dnf install -y "$DB_PACKAGE" > /dev/null 2>&1
            fi
            systemctl enable --now "$DB_PACKAGE" > /dev/null 2>&1
            systemctl is-active --quiet "$DB_PACKAGE" || systemctl start "$DB_PACKAGE" > /dev/null 2>&1
            systemctl is-enabled --quiet "$DB_PACKAGE" || systemctl enable "$DB_PACKAGE" > /dev/null 2>&1
            ;;
    esac
    sleep 1

    # 10. Configurar contraseña para el usuario root de la base de datos
    update_progress "Configurando contraseña de root para $DB_TYPE..." 2
    case "$DISTRO" in
        ubuntu|debian)
            # En Debian/Ubuntu, MySQL/MariaDB por defecto usa auth_socket.
            # Necesitamos cambiarlo a mysql_native_password para poder usar la contraseña.
            mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DB_ROOT_PASSWORD';" > /dev/null 2>&1
            mysql -u root -p"$DB_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;" > /dev/null 2>&1
            ;;
        almalinux)
            # En AlmaLinux, MariaDB por defecto también puede usar auth_socket.
            # Aseguramos que el usuario root pueda autenticarse con la contraseña.
            mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';" > /dev/null 2>&1
            mysql -u root -p"$DB_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;" > /dev/null 2>&1
            ;;
    esac
    sleep 1

    # 11. Instalar phpMyAdmin
    update_progress "Verificando e instalando phpMyAdmin..." 2
    case "$DISTRO" in
        ubuntu|debian)
            if ! dpkg -s phpmyadmin &> /dev/null; then
                # Pre-seed answers for debconf to automate phpMyAdmin installation
                echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
                echo "phpmyadmin phpmyadmin/app-password-confirm password $PHPMYADMIN_PASSWORD" | debconf-set-selections
                echo "phpmyadmin phpmyadmin/mysql/admin-pass password $DB_ROOT_PASSWORD" | debconf-set-selections
                echo "phpmyadmin phpmyadmin/mysql/app-pass password $PHPMYADMIN_PASSWORD" | debconf-set-selections
                echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
                DEBIAN_FRONTEND=noninteractive apt install -y phpmyadmin > /dev/null 2>&1
            fi
            ;;
        almalinux)
            if ! rpm -q phpmyadmin &> /dev/null; then
                # Enable EPEL if not already enabled (phpMyAdmin is in EPEL)
                if ! rpm -q epel-release &> /dev/null; then
                    dnf install -y epel-release > /dev/null 2>&1
                fi
                dnf install -y phpmyadmin > /dev/null 2>&1
            fi
            ;;
    esac
    sleep 1

    # 12. Configurar phpMyAdmin y crear usuario de base de datos
    update_progress "Configurando phpMyAdmin y usuario de base de datos..." 2
    case "$DISTRO" in
        ubuntu|debian)
            # dbconfig-common debería haber creado el usuario. Solo aseguramos permisos.
            mysql -u root -p"$DB_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'phpmyadmin'@'localhost' IDENTIFIED BY '$PHPMYADMIN_PASSWORD';" > /dev/null 2>&1
            mysql -u root -p"$DB_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;" > /dev/null 2>&1
            systemctl restart apache2 > /dev/null 2>&1
            ;;
        almalinux)
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
                echo "</Directory>" | tee -a /etc/httpd/conf.d/phpmyadmin.conf > /dev/null
                systemctl restart httpd > /dev/null 2>&1
            fi
            ;;
    esac
    sleep 1

    # 13. Instalar Composer
    update_progress "Verificando e instalando Composer..." 1
    if ! command -v composer &> /dev/null; then
        php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" > /dev/null 2>&1
        php composer-setup.php --install-dir=/usr/local/bin --filename=composer > /dev/null 2>&1
        rm composer-setup.php > /dev/null 2>&1
    fi
    sleep 1

    # 14. Configurar PATH para el instalador global de Composer (Laravel Installer)
    update_progress "Configurando PATH para Laravel Installer..." 1
    # Directorio de binarios globales de Composer
    COMPOSER_BIN_DIR="$HOME/.config/composer/vendor/bin"
    if [ ! -d "$COMPOSER_BIN_DIR" ]; then
        COMPOSER_BIN_DIR="$HOME/.composer/vendor/bin" # Ubicación alternativa para versiones antiguas de Composer
    fi

    # Línea a agregar al .bashrc
    EXPORT_PATH_LINE="export PATH=\"\$PATH:$COMPOSER_BIN_DIR\""

    # Verificar si la línea ya existe en .bashrc para evitar duplicados
    if ! grep -qxF "$EXPORT_PATH_LINE" "$HOME/.bashrc"; then
        echo "$EXPORT_PATH_LINE" >> "$HOME/.bashrc"
    fi
    # Nota: El usuario tendrá que recargar .bashrc o abrir una nueva terminal para que esto surta efecto.
    sleep 1

    # 15. Instalar Laravel Installer
    update_progress "Instalando Laravel Installer..." 1
    if ! command -v laravel &> /dev/null; then
        composer global require laravel/installer > /dev/null 2>&1
    fi
    sleep 1

    # 16. Crear directorio /var/www/laravel
    update_progress "Creando directorio /var/www/laravel..." 1
    mkdir -p /var/www/laravel > /dev/null 2>&1
    sleep 1

    # 17. Crear proyecto Laravel dentro de /var/www/laravel con Pest
    update_progress "Creando proyecto Laravel '$PROJECT_NAME' con Pest en /var/www/laravel..." 3
    # Mover al directorio donde se creará el proyecto
    cd /var/www/laravel/ > /dev/null 2>&1
    laravel new "$PROJECT_NAME" --no-interaction --pest > /dev/null 2>&1
    sleep 2

    # 18. Configurar .env del proyecto Laravel para la base de datos
    update_progress "Configurando archivo .env para la base de datos..." 2
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
    update_progress "Creando base de datos '$DB_NAME' para el proyecto..." 2
    mysql -u $DB_ROOT_USER -p"$DB_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;" > /dev/null 2>&1
    sleep 1

    # 20. Ejecutar php artisan migrate
    update_progress "Ejecutando migraciones de Laravel..." 2
    cd "$PROJECT_PATH" > /dev/null 2>&1
    php artisan migrate --force > /dev/null 2>&1
    sleep 2

    # 21. Instalar paquete de idioma español para Laravel
    update_progress "Instalando paquete de idioma español (laravel-lang/lang)..." 2
    cd "$PROJECT_PATH" > /dev/null 2>&1
    composer require laravel-lang/lang --no-interaction > /dev/null 2>&1
    sleep 2

    # 22. Publicar archivos de idioma español
    update_progress "Publicando archivos de idioma español..." 2
    php artisan lang:publish es --no-interaction > /dev/null 2>&1
    sleep 1

    # 23. Configurar el idioma por defecto en config/app.php
    update_progress "Configurando idioma por defecto a español en config/app.php..." 1
    sed -i "s/^    'locale' => 'en',/    'locale' => 'es',/" "$PROJECT_PATH/config/app.php" > /dev/null 2>&1
    sleep 0.5

    # 24. Ejecutar npm install
    update_progress "Ejecutando npm install para dependencias frontend..." 3
    cd "$PROJECT_PATH" > /dev/null 2>&1
    npm install --silent > /dev/null 2>&1
    sleep 3

    # 25. Ejecutar npm run build (o npm run dev)
    update_progress "Compilando assets frontend con npm run build..." 3
    cd "$PROJECT_PATH" > /dev/null 2>&1
    npm run build --silent > /dev/null 2>&1
    sleep 3

    # 26. Configurar permisos del proyecto Laravel
    update_progress "Configurando permisos del proyecto Laravel..." 2
    # Establecer propietario del directorio del proyecto al usuario de Apache
    case "$DISTRO" in
        ubuntu|debian)
            chown -R www-data:www-data "/var/www/laravel/$PROJECT_NAME" > /dev/null 2>&1
            ;;
        almalinux)
            chown -R apache:apache "/var/www/laravel/$PROJECT_NAME" > /dev/null 2>&1
            ;;
    esac
    # Establecer permisos de escritura para storage y bootstrap/cache
    chmod -R 775 "/var/www/laravel/$PROJECT_NAME/storage" > /dev/null 2>&1
    chmod -R 775 "/var/www/laravel/$PROJECT_NAME/bootstrap/cache" > /dev/null 2>&1
    sleep 1

    # 27. Configurar Virtual Host de Apache para el proyecto Laravel
    update_progress "Configurando Virtual Host de Apache para '$PROJECT_NAME.test'..." 2
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

    case "$DISTRO" in
        ubuntu|debian)
            echo "$VHOST_CONFIG" | tee "/etc/apache2/sites-available/$PROJECT_NAME.test.conf" > /dev/null
            a2ensite "$PROJECT_NAME.test.conf" > /dev/null 2>&1
            a2dissite 000-default.conf > /dev/null 2>&1 # Deshabilitar el sitio por defecto si aún está habilitado
            systemctl restart apache2 > /dev/null 2>&1
            ;;
        almalinux)
            echo "$VHOST_CONFIG" | tee "/etc/httpd/conf.d/$PROJECT_NAME.test.conf" > /dev/null
            systemctl restart httpd > /dev/null 2>&1
            ;;
    esac
    sleep 1

    # 28. Modificar el archivo /etc/hosts para el dominio local
    update_progress "Agregando '$PROJECT_NAME.test' al archivo /etc/hosts..." 1
    LOCAL_HOSTS_ENTRY="127.0.0.1\t$LOCAL_DOMAIN"
    # Verificar si la entrada ya existe para evitar duplicados
    if ! grep -q -P "^127\.0\.0\.1\s+${LOCAL_DOMAIN//./\\.}" /etc/hosts; then # Usamos -P para regex de Perl y escapamos los puntos
        echo -e "$LOCAL_HOSTS_ENTRY" | tee -a /etc/hosts > /dev/null
    fi
    sleep 0.5

    # Lógica para software adicional (ejemplo) con validación
    if [[ "$ADDITIONAL_SOFTWARE" == *"vscode"* ]]; then
        # Verificar si VS Code ya está instalado
        if ! command -v code &> /dev/null; then
            update_progress "Instalando Visual Studio Code..." 1
            # Comandos de instalación para VS Code
            case "$DISTRO" in
                ubuntu|debian)
                    apt install -y wget apt-transport-https > /dev/null 2>&1
                    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
                    install -D -o -g -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg > /dev/null 2>&1
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null
                    rm packages.microsoft.gpg
                    apt update > /dev/null 2>&1
                    apt install -y code > /dev/null 2>&1
                    ;;
                almalinux)
                    rpm --import https://packages.microsoft.com/keys/microsoft.asc > /dev/null 2>&1
                    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null
                    dnf check-update > /dev/null 2>&1
                    dnf install -y code > /dev/null 2>&1
                    ;;
            esac
            sleep 3
        else
            update_progress "Visual Studio Code ya está instalado. Omitiendo..." 1
            sleep 0.5
        fi
    fi

    if [[ "$ADDITIONAL_SOFTWARE" == *"sublime"* ]]; then
        # Verificar si Sublime Text ya está instalado
        if ! command -v subl &> /dev/null; then # 'subl' es el comando para Sublime Text
            update_progress "Instalando Sublime Text..." 1
            # Comandos de instalación para Sublime Text
            case "$DISTRO" in
                ubuntu|debian)
                    apt install -y wget apt-transport-https > /dev/null 2>&1
                    wget -qO - https://download.sublimetext.com/apt/rpm-pub-key.gpg | gpg --dearmor | tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
                    echo "deb https://download.sublimetext.com/apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list > /dev/null
                    apt update > /dev/null 2>&1
                    apt install -y sublime-text > /dev/null 2>&1
                    ;;
                almalinux)
                    rpm -v --import https://download.sublimetext.com/rpm/rpmkey.gpg > /dev/null 2>&1
                    echo -e "[sublime-text]\nname=Sublime Text\nbaseurl=https://download.sublimetext.com/rpm/stable/\nenabled=1\ngpgcheck=1\nrpm_gpg_check=1" | tee /etc/yum.repos.d/sublime-text.repo > /dev/null
                    dnf install -y sublime-text > /dev/null 2>&1
                    ;;
            esac
            sleep 3
        else
            update_progress "Sublime Text ya está instalado. Omitiendo..." 1
            sleep 0.5
        fi
    fi

    if [[ "$ADDITIONAL_SOFTWARE" == *"brave"* ]]; then
        # Verificar si Brave Browser ya está instalado
        if ! command -v brave-browser &> /dev/null; then
            update_progress "Instalando Brave Browser..." 1
            # Comandos de instalación para Brave Browser
            case "$DISTRO" in
                ubuntu|debian)
                    apt install -y curl > /dev/null 2>&1
                    curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg > /dev/null 2>&1
                    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
                    apt update > /dev/null 2>&1
                    apt install -y brave-browser > /dev/null 2>&1
                    ;;
                almalinux)
                    dnf install -y curl > /dev/null 2>&1
                    rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc > /dev/null 2>&1
                    echo -e "[brave-browser]\nname=Brave Browser\nbaseurl=https://brave-browser-rpm-release.s3.brave.com/x86_64/\nenabled=1\ngpgcheck=1\ngpgkey=https://brave-browser-rpm-release.s3.brave.com/brave-core.asc" | tee /etc/yum.repos.d/brave-browser.repo > /dev/null
                    dnf install -y brave-browser > /dev/null 2>&1
                    ;;
            esac
            sleep 3
        else
            update_progress "Brave Browser ya está instalado. Omitiendo..." 1
            sleep 0.5
        fi
    fi

    if [[ "$ADDITIONAL_SOFTWARE" == *"chrome"* ]]; then
        # Verificar si Google Chrome ya está instalado
        if ! command -v google-chrome &> /dev/null; then
            update_progress "Instalando Google Chrome..." 1
            # Comandos de instalación para Google Chrome
            case "$DISTRO" in
                ubuntu|debian)
                    apt install -y wget > /dev/null 2>&1
                    wget -q -O /tmp/google-chrome-stable_current_amd64.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb > /dev/null 2>&1
                    dpkg -i /tmp/google-chrome-stable_current_amd64.deb > /dev/null 2>&1
                    apt --fix-broken install -y > /dev/null 2>&1 # Para arreglar dependencias si las hubiera
                    rm /tmp/google-chrome-stable_current_amd64.deb > /dev/null 2>&1
                    ;;
                almalinux)
                    dnf install -y wget > /dev/null 2>&1
                    wget -q -O /tmp/google-chrome-stable_current_x86_64.rpm https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm > /dev/null 2>&1
                    dnf localinstall -y /tmp/google-chrome-stable_current_x86_64.rpm > /dev/null 2>&1
                    rm /tmp/google-chrome-stable_current_x86_64.rpm > /dev/null 2>&1
                    ;;
            esac
            sleep 3
        else
            update_progress "Google Chrome ya está instalado. Omitiendo..." 1
            sleep 0.5
        fi
    fi

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
# Mensaje final detallado para el usuario
dialog --clear --backtitle "Instalador de Sistema v$VEROS" \
--title "Instalacion Finalizada" \
--msgbox "\n¡La instalacion de Laravel 12 y los componentes seleccionados ha finalizado con exito!\n\nTu proyecto Laravel '$PROJECT_NAME' ha sido creado en /var/www/laravel/$PROJECT_NAME.\n\nLa base de datos '$DB_NAME' ha sido creada y configurada en el archivo .env.\n\nEl idioma español se ha configurado como predeterminado para tu proyecto.\n\nEl dominio local 'http://$PROJECT_NAME.test' ha sido configurado en Apache y añadido a tu archivo /etc/hosts.\n\nAhora puedes acceder a tu proyecto en el navegador visitando:\n    http://$PROJECT_NAME.test\n\nPara que el comando 'laravel' funcione, por favor, abre una nueva terminal o ejecuta:\n\n    source ~/.bashrc\n\nPresiona OK para salir." 24 75
clear

exit 0
