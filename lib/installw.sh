#!/bin/bash

# =========================================================
# Script de instalación para Ubuntu/Debian/AnduinOS (64 bits)
# =========================================================

clear

# ---------------------------------------------------------
# Declaración de variables
# ---------------------------------------------------------
DBSERVER=""
DISTRO=""
PASSADMIN=""
PASSROOT=""
PHPUSER=""
PROYECTO=""
SOFTWARESUSER=""
VER="3.6" # Versión actualizada con instalación granular de PHP

# ---------------------------------------------------------
# Validar si se ejecuta como root
# ---------------------------------------------------------
if [[ "$EUID" -ne 0 ]]; then
    echo "Error: Este script debe ser ejecutado como usuario root." 1>&2
    exit 1
fi

# ---------------------------------------------------------
# Validar si el sistema es de 64 bits
# ---------------------------------------------------------
if [[ "$(uname -m)" != "x86_64" ]]; then
    echo "Error: Este script es solo para sistemas de 64 bits (x86_64)." 1>&2
    exit 1
fi

# ---------------------------------------------------------
# Validar que sea Ubuntu, Debian o AnduinOS, y definir DISTRO, DISVER y DBSERVER
# ---------------------------------------------------------
if grep -qi 'AnduinOS' /etc/os-release; then
    DISTRO="AnduinOS"
    DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')
    DBSERVER="mysql-server"
elif grep -qi 'Ubuntu' /etc/os-release; then
    DISTRO="Ubuntu"
    DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')
    DBSERVER="mysql-server"
elif grep -qi 'Debian' /etc/os-release; then
    DISTRO="Debian"
    DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')
    DBSERVER="mariadb-server"
else
    echo "Error: Este script solo puede ejecutarse en Ubuntu, Debian o AnduinOS." 1>&2
    exit 1
fi

# ---------------------------------------------------------
# Instalar whiptail si no está presente
# ---------------------------------------------------------
if ! command -v whiptail &> /dev/null; then
    apt install -y whiptail >/dev/null 2>&1
fi

# ---------------------------------------------------------
# Cuadro de bienvenida
# ---------------------------------------------------------
if (whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Bienvenido" --yesno "Bienvenido al Instalador de Lamp para Laravel 12. Se instalarán los siguientes paquetes:\n\n- Apache\n- PHP\n- $DBSERVER\n- Phpmyadmin\n- Composer\n- NodeJs\n- Programas de Creación de proyecto\n\n¿Desea continuar con la instalación?" 16 70) then
    echo ""
else
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
fi

# ---------------------------------------------------------
# Solicitar el nombre del proyecto
# ---------------------------------------------------------
PROYECTO=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Nombre del Proyecto" --inputbox "Por favor, introduce el nombre de tu proyecto:\n(Si lo dejas en blanco, se usará 'crud' por defecto)" 10 60 "" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
fi

if [ -z "$PROYECTO" ]; then
    PROYECTO="crud"
fi

# ---------------------------------------------------------
# Solicitar la contraseña de Phpmyadmin
# ---------------------------------------------------------
PASSADMIN=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Contraseña de Phpmyadmin" --passwordbox "Por favor, introduce la contraseña para el usuario 'pma' de Phpmyadmin:\n(Si la dejas en blanco, se usará '12345' por defecto)" 10 70 "" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
fi

if [ -z "$PASSADMIN" ]; then
    PASSADMIN="12345"
fi

# ---------------------------------------------------------
# Solicitar la contraseña de Root de la base de datos o crear otro usuario
# ---------------------------------------------------------
USER_CHOICE=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Seleccionar Usuario de Base de Datos" --radiolist "Seleccione el tipo de usuario de base de datos a configurar:" 15 70 2 \
"1" "Crear el usuario root" ON \
"2" "Crear otro usuario" OFF 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
fi

if [ "$USER_CHOICE" == "1" ]; then
    PASSROOT=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Contraseña de Root para la Base de Datos" --passwordbox "Por favor, introduce la contraseña para el usuario 'root' de la base de datos:\n(Si la dejas en blanco, se usará '12345' por defecto)" 10 70 "" 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
        whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
        exit 1
    fi
    if [ -z "$PASSROOT" ]; then
        PASSROOT="12345"
    fi
elif [ "$USER_CHOICE" == "2" ]; then
    NEWUSER=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Nombre del Nuevo Usuario" --inputbox "Por favor, introduce el nombre del nuevo usuario de la base de datos:" 10 70 "" 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
        whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
        exit 1
    fi
    NEWUSERPASS=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Contraseña del Nuevo Usuario" --passwordbox "Por favor, introduce la contraseña para el nuevo usuario de la base de datos:" 10 70 "" 3>&1 1>&2 2>&3)
    if [ $? -ne 0 ]; then
        whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
        exit 1
    fi
    PASSROOT="12345"
fi

# ---------------------------------------------------------
# Selección de versión de PHP
# ---------------------------------------------------------
PHPUSER=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Seleccionar versión de PHP" --radiolist "Seleccione la versión de PHP a instalar:" 15 60 3 \
"8.2" "Recomendada para Laravel 12" ON \
"8.3" "" OFF \
"8.4" "" OFF 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
fi

# ---------------------------------------------------------
# Selección de software adicional
# ---------------------------------------------------------
SOFTWARESUSER=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Software Adicional" --checklist "Seleccione el software adicional que desea instalar:" 15 60 5 \
"vscode" "Visual Studio Code" OFF \
"brave" "Brave Browser" OFF \
"chrome" "Google Chrome" OFF \
"filezilla" "FileZilla" OFF \
"obs" "OBS Studio" OFF 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
fi

# ---------------------------------------------------------
# Barra de progreso con whiptail
# ---------------------------------------------------------
(
    # Paso 1: Actualización de repositorios
    echo "XXX"
    echo "5"
    echo "Actualizando lista de repositorios..."
    echo "XXX"
    apt update >/dev/null 2>&1
    sleep 1

    # Paso 2: Actualización de sistema
    echo "XXX"
    echo "10"
    echo "Actualizando el sistema..."
    echo "XXX"
    apt upgrade -y >/dev/null 2>&1
    sleep 1

    # Paso 3: Validar e integrar el repositorio de Ondrej si la versión de PHP no es la del sistema
    echo "XXX"
    echo "15"
    echo "Agregando PPA de Ondrej si es necesario..."
    echo "XXX"
    if command -v php &>/dev/null; then
        CURRENT_PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;")
    else
        CURRENT_PHP_VERSION="none"
    fi
    if [[ "$CURRENT_PHP_VERSION" != "$PHPUSER" ]]; then
        if ! grep -q "^deb .*ondrej/php" /etc/apt/sources.list.d/* 2>/dev/null; then
            apt install -y software-properties-common >/dev/null 2>&1
            add-apt-repository ppa:ondrej/php -y >/dev/null 2>&1
            apt update >/dev/null 2>&1
        fi
    fi
    sleep 1
    
    # -----------------------------------------------------
    # Instalación de paquetes de utilidades (Detallada)
    # -----------------------------------------------------
    echo "XXX"
    echo "16"
    echo "Instalando paquete zip..."
    echo "XXX"
    apt install -y zip >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "17"
    echo "Instalando paquete gpg..."
    echo "XXX"
    apt install -y gpg >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "18"
    echo "Instalando paquete curl..."
    echo "XXX"
    apt install -y curl >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "19"
    echo "Instalando paquete unzip..."
    echo "XXX"
    apt install -y unzip >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "20"
    echo "Instalando paquete git..."
    echo "XXX"
    apt install -y git >/dev/null 2>&1
    sleep 1
    
    # Paso 4: Verificación e instalación de Apache
    echo "XXX"
    echo "25"
    echo "Verificando e instalando Apache..."
    echo "XXX"
    if ! dpkg -s apache2 >/dev/null 2>&1; then
        apt install -y apache2 >/dev/null 2>&1
    fi
    sleep 1
    
    # Nuevo paso: Habilitar mod_rewrite para URLs dinámicas
    echo "XXX"
    echo "30"
    echo "Habilitando mod_rewrite en Apache..."
    echo "XXX"
    if ! a2enmod rewrite >/dev/null 2>&1; then
        echo "Error al habilitar mod_rewrite." 1>&2
    fi
    systemctl restart apache2 >/dev/null 2>&1
    sleep 1
    
    # Paso 5: Verificación e instalación de PHP y extensiones (granular)
    echo "XXX"
    echo "35"
    echo "Verificando e instalando PHP y libapache2-mod-php..."
    echo "XXX"
    if [[ "$CURRENT_PHP_VERSION" != "$PHPUSER" ]]; then
        apt install -y "php$PHPUSER" "libapache2-mod-php$PHPUSER" >/dev/null 2>&1
    fi
    sleep 1

    echo "XXX"
    echo "37"
    echo "Instalando php${PHPUSER}-xml..."
    echo "XXX"
    apt install -y "php${PHPUSER}-xml" >/dev/null 2>&1
    sleep 1
    
    echo "XXX"
    echo "39"
    echo "Instalando php${PHPUSER}-zip..."
    echo "XXX"
    apt install -y "php${PHPUSER}-zip" >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "41"
    echo "Instalando php${PHPUSER}-mbstring..."
    echo "XXX"
    apt install -y "php${PHPUSER}-mbstring" >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "43"
    echo "Instalando php${PHPUSER}-dom..."
    echo "XXX"
    apt install -y "php${PHPUSER}-dom" >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "45"
    echo "Instalando php${PHPUSER}-curl..."
    echo "XXX"
    apt install -y "php${PHPUSER}-curl" >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "47"
    echo "Instalando php${PHPUSER}-fileinfo..."
    echo "XXX"
    apt install -y "php${PHPUSER}-fileinfo" >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "49"
    echo "Instalando php${PHPUSER}-bcmath..."
    echo "XXX"
    apt install -y "php${PHPUSER}-bcmath" >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "51"
    echo "Instalando php${PHPUSER}-gmp..."
    echo "XXX"
    apt install -y "php${PHPUSER}-gmp" >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "53"
    echo "Instalando php${PHPUSER}-imagick..."
    echo "XXX"
    apt install -y "php${PHPUSER}-imagick" >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "55"
    echo "Instalando php${PHPUSER}-exif..."
    echo "XXX"
    apt install -y "php${PHPUSER}-exif" >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "57"
    echo "Instalando php${PHPUSER}-gd..."
    echo "XXX"
    apt install -y "php${PHPUSER}-gd" >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "59"
    echo "Instalando php${PHPUSER}-iconv..."
    echo "XXX"
    apt install -y "php${PHPUSER}-iconv" >/dev/null 2>&1
    sleep 1

    echo "XXX"
    echo "61"
    echo "Instalando php${PHPUSER}-mysql..."
    echo "XXX"
    apt install -y "php${PHPUSER}-mysql" >/dev/null 2>&1
    sleep 1

    # -----------------------------------------------------
    # Instalación y configuración de la base de datos
    # -----------------------------------------------------
    echo "XXX"
    echo "65"
    echo "Instalando y configurando la base de datos..."
    echo "XXX"
    if ! dpkg -s "$DBSERVER" >/dev/null 2>&1; then
        apt install -y "$DBSERVER" >/dev/null 2>&1
    fi

    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$PASSROOT';" >/dev/null 2>&1
    mysql -e "FLUSH PRIVILEGES;" >/dev/null 2>&1
    if [ "$USER_CHOICE" == "2" ]; then
        mysql -u root -p"$PASSROOT" -e "CREATE USER '$NEWUSER'@'localhost' IDENTIFIED BY '$NEWUSERPASS';" >/dev/null 2>&1
        mysql -u root -p"$PASSROOT" -e "GRANT ALL PRIVILEGES ON *.* TO '$NEWUSER'@'localhost' WITH GRANT OPTION;" >/dev/null 2>&1 # Se dan todos los privilegios al nuevo usuario
        mysql -u root -p"$PASSROOT" -e "FLUSH PRIVILEGES;" >/dev/null 2>&1
        DB_USERNAME="$NEWUSER"
        DB_PASSWORD="$NEWUSERPASS"
        DB_DATABASE="$NEWUSER"
    else
        mysql -u root -p"$PASSROOT" -e "CREATE DATABASE $PROYECTO;" >/dev/null 2>&1
        DB_USERNAME="root"
        DB_PASSWORD="$PASSROOT"
        DB_DATABASE="$PROYECTO"
    fi
    
    mysql -u root -p"$PASSROOT" -e "CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED BY '$PASSADMIN';" >/dev/null 2>&1
    mysql -u root -p"$PASSROOT" -e "GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;" >/dev/null 2>&1
    mysql -u root -p"$PASSROOT" -e "FLUSH PRIVILEGES;" >/dev/null 2>&1
    systemctl restart mysql >/dev/null 2>&1
    
    # -----------------------------------------------------
    # Instalación y configuración de phpmyadmin
    # -----------------------------------------------------
    echo "XXX"
    echo "70"
    echo "Instalando y configurando Phpmyadmin..."
    echo "XXX"
    if ! dpkg -s phpmyadmin >/dev/null 2>&1; then
        echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
        echo "phpmyadmin phpmyadmin/app-password-confirm password $PASSADMIN" | debconf-set-selections
        echo "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSROOT" | debconf-set-selections
        echo "phpmyadmin phpmyadmin/mysql/app-pass password $PASSADMIN" | debconf-set-selections
        echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
        apt install -y phpmyadmin >/dev/null 2>&1
        ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf >/dev/null 2>&1
        a2enconf phpmyadmin >/dev/null 2>&1
    fi

    # -----------------------------------------------------
    # Crear archivo info.php para verificar la instalación
    # -----------------------------------------------------
    echo "XXX"
    echo "72"
    echo "Creando archivo info.php y configurando permisos..."
    echo "XXX"
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
    chown www-data:www-data /var/www/html/info.php >/dev/null 2>&1

    # -----------------------------------------------------
    # Validación y configuración de la versión de PHP
    # -----------------------------------------------------
    echo "XXX"
    echo "75"
    echo "Configurando la versión de PHP en Apache..."
    echo "XXX"
    a2dismod php* >/dev/null 2>&1
    a2enmod "php$PHPUSER" >/dev/null 2>&1
    update-alternatives --set php "/usr/bin/php$PHPUSER" >/dev/null 2>&1
    systemctl restart apache2 >/dev/null 2>&1

    # -----------------------------------------------------
    # Instalación de software adicional (Corregido)
    # -----------------------------------------------------
    echo "XXX"
    echo "77"
    echo "Instalando software adicional..."
    echo "XXX"
    
    # Instalación de Visual Studio Code
    if [[ " $SOFTWARESUSER " =~ "vscode" ]]; then
        if ! command -v code &> /dev/null; then
            echo "XXX"
            echo "78"
            echo "Instalando Visual Studio Code..."
            echo "XXX"
            wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
            install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
            sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
            rm -f packages.microsoft.gpg
            apt update >/dev/null 2>&1
            apt install -y code >/dev/null 2>&1
        fi
    fi

    # Instalación de Brave Browser
    if [[ " $SOFTWARESUSER " =~ "brave" ]]; then
        if ! dpkg -s brave-browser >/dev/null 2>&1; then
            echo "XXX"
            echo "79"
            echo "Instalando Brave Browser..."
            echo "XXX"
            curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg >/dev/null 2>&1
            echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null 2>&1
            apt update >/dev/null 2>&1
            apt install -y brave-browser >/dev/null 2>&1
        fi
    fi
    
    # Instalación de Google Chrome
    if [[ " $SOFTWARESUSER " =~ "chrome" ]]; then
        if ! dpkg -s google-chrome-stable >/dev/null 2>&1; then
            echo "XXX"
            echo "80"
            echo "Instalando Google Chrome..."
            echo "XXX"
            wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb >/dev/null 2>&1
            apt install -y /tmp/google-chrome.deb >/dev/null 2>&1
            rm /tmp/google-chrome.deb
        fi
    fi
    
    # Instalación de FileZilla
    if [[ " $SOFTWARESUSER " =~ "filezilla" ]]; then
        if ! dpkg -s filezilla >/dev/null 2>&1; then
            echo "XXX"
            echo "81"
            echo "Instalando FileZilla..."
            echo "XXX"
            apt install -y filezilla >/dev/null 2>&1
        fi
    fi

    # Instalación de OBS Studio
    if [[ " $SOFTWARESUSER " =~ "obs" ]]; then
        if ! dpkg -s obs-studio >/dev/null 2>&1; then
            echo "XXX"
            echo "82"
            echo "Instalando OBS Studio..."
            echo "XXX"
            apt install -y obs-studio >/dev/null 2>&1
        fi
    fi
    
    # -----------------------------------------------------
    # Creación del proyecto de Laravel
    # -----------------------------------------------------
    echo "XXX"
    echo "85"
    echo "Instalando Node y Composer..."
    echo "XXX"
    if ! command -v node >/dev/null 2>&1; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - >/dev/null 2>&1
        apt install -y nodejs >/dev/null 2>&1
    fi
    if ! command -v composer >/dev/null 2>&1; then
        curl -sS https://getcomposer.org/installer | php >/dev/null 2>&1
        mv composer.phar /usr/local/bin/composer >/dev/null 2>&1
    fi

    echo "XXX"
    echo "88"
    echo "Creando el proyecto de Laravel ($PROYECTO)..."
    echo "XXX"
    mkdir -p "/var/www/laravel" >/dev/null 2>&1
    cd "/var/www/laravel" >/dev/null 2>&1
    composer create-project laravel/laravel "$PROYECTO" --no-interaction >/dev/null 2>&1

    # -----------------------------------------------------
    # Configuración de Virtual Host de Apache, hosts y .env
    # -----------------------------------------------------
    echo "XXX"
    echo "92"
    echo "Configurando el Virtual Host, el archivo hosts y la conexión a la base de datos..."
    echo "XXX"
    ENV_FILE="/var/www/laravel/$PROYECTO/.env"
    
    # Crear la configuración de Apache para el Virtual Host
    echo "<VirtualHost *:80>
        ServerName $PROYECTO.test
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/laravel/$PROYECTO/public
        <Directory /var/www/laravel/$PROYECTO>
            AllowOverride All
        </Directory>
        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined
    </VirtualHost>" > "/etc/apache2/sites-available/$PROYECTO.conf"
    
    a2ensite "$PROYECTO.conf" >/dev/null 2>&1
    systemctl restart apache2 >/dev/null 2>&1
    echo "127.0.0.1 $PROYECTO.test" >> /etc/hosts
    
    # Modificación del archivo .env
    sed -i "s|^APP_URL=.*|APP_URL=http://$PROYECTO.test|" "$ENV_FILE"
    sed -i "s|^DB_CONNECTION=.*|DB_CONNECTION=mysql|" "$ENV_FILE"
    sed -i "s|^# DB_HOST=.*|DB_HOST=127.0.0.1|" "$ENV_FILE"
    sed -i "s|^DB_HOST=.*|DB_HOST=127.0.0.1|" "$ENV_FILE"
    sed -i "s|^# DB_PORT=.*|DB_PORT=3306|" "$ENV_FILE"
    sed -i "s|^DB_PORT=.*|DB_PORT=3306|" "$ENV_FILE"
    sed -i "s|^# DB_DATABASE=.*|DB_DATABASE=$DB_DATABASE|" "$ENV_FILE"
    sed -i "s|^DB_DATABASE=.*|DB_DATABASE=$DB_DATABASE|" "$ENV_FILE"
    sed -i "s|^# DB_USERNAME=.*|DB_USERNAME=$DB_USERNAME|" "$ENV_FILE"
    sed -i "s|^DB_USERNAME=.*|DB_USERNAME=$DB_USERNAME|" "$ENV_FILE"
    sed -i "s|^# DB_PASSWORD=.*|DB_PASSWORD=$DB_PASSWORD|" "$ENV_FILE"
    sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$DB_PASSWORD|" "$ENV_FILE"


    # -----------------------------------------------------
    # Pasos finales: Node, migraciones, enlace y permisos
    # -----------------------------------------------------
    cd "/var/www/laravel/$PROYECTO"
    
    echo "XXX"
    echo "94"
    echo "Instalando dependencias de Node para Vite..."
    echo "XXX"
    npm install --silent >/dev/null 2>&1
    
    echo "XXX"
    echo "96"
    echo "Compilando assets de frontend con Vite..."
    echo "XXX"
    npm run build --silent >/dev/null 2>&1
    
    echo "XXX"
    echo "97"
    echo "Ejecutando migraciones de base de datos..."
    echo "XXX"
    php artisan migrate --force --no-interaction >/dev/null 2>&1

    echo "XXX"
    echo "98"
    echo "Creando el enlace simbólico para la carpeta storage..."
    echo "XXX"
    php artisan storage:link >/dev/null 2>&1
    
    echo "XXX"
    echo "99"
    echo "Asignando permisos a la carpeta del proyecto..."
    echo "XXX"
    chmod -R 777 "/var/www/laravel/$PROYECTO"


    # Paso Final: Fin de la instalación
    echo "XXX"
    echo "100"
    echo "Fin Instalación"
    echo "XXX"
    sleep 3
    
) | whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalador de componentes" --gauge "Iniciando la instalación..." 6 60 0

exit 0
