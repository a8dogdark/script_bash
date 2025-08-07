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
VER="2.0"

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
# Validar la distribución, versión y definir variables
# ---------------------------------------------------------
# Define la versión de la distribución una vez
DISVER=$(grep -i 'VERSION_ID' /etc/os-release | cut -d= -f2 | tr -d '"')

if grep -qi 'AnduinOS' /etc/os-release; then
    if [[ "$DISVER" == "1.1" || "$DISVER" == "1.3" ]]; then
        DISTRO="AnduinOS"
        DBSERVER="mysql-server"
    else
        echo "Error: AnduinOS $DISVER no es una versión compatible. Se requiere 1.1.x o 1.3.x." 1>&2
        exit 1
    fi
elif grep -qi 'Ubuntu' /etc/os-release; then
    if [[ "$DISVER" == "22.04" || "$DISVER" == "24.04" ]]; then
        DISTRO="Ubuntu"
        DBSERVER="mysql-server"
    else
        echo "Error: Ubuntu $DISVER no es una versión compatible. Se requiere 22.04 o 24.04." 1>&2
        exit 1
    fi
elif grep -qi 'Debian' /etc/os-release; then
    if [[ "$DISVER" == "11" || "$DISVER" == "12" ]]; then
        DISTRO="Debian"
        DBSERVER="mariadb-server"
    else
        echo "Error: Debian $DISVER no es una versión compatible. Se requiere 11 o 12." 1>&2
        exit 1
    fi
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
VER="2.0"
MENSAJE_BIENVENIDA="Bienvenido al Instalador de Lamp para Laravel 12. Se instalarán los siguientes paquetes:\n\n- Apache\n- PHP\n- $DBSERVER\n- Phpmyadmin\n- Composer\n- NodeJs\n- Programas de Creación de proyecto\n\n¿Desea continuar con la instalación?"

if (whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Bienvenido" --yesno "$MENSAJE_BIENVENIDA" 16 70) then
    # El usuario seleccionó Aceptar, se continúa con la barra de progreso
    echo "" # Se agrega un salto de línea para separar la salida del whiptail
else
    # El usuario seleccionó Cancelar, se muestra un mensaje y se sale del script
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

# Asignar valor por defecto si el campo se dejó en blanco
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

# Asignar valor por defecto si el campo se dejó en blanco
if [ -z "$PASSADMIN" ]; then
    PASSADMIN="12345"
fi

# ---------------------------------------------------------
# Solicitar la contraseña de Root de la base de datos
# ---------------------------------------------------------
PASSROOT=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Contraseña de Root para la Base de Datos" --passwordbox "Por favor, introduce la contraseña para el usuario 'root' de la base de datos:\n(Si la dejas en blanco, se usará '12345' por defecto)" 10 70 "" 3>&1 1>&2 2>&3)

if [ $? -ne 0 ]; then
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
fi

# Asignar valor por defecto si el campo se dejó en blanco
if [ -z "$PASSROOT" ]; then
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
SOFTWARESUSER=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Software Adicional" --checklist "Seleccione el software adicional que desea instalar:" 15 60 4 \
"vscode" "Visual Studio Code" OFF \
"brave" "Brave Browser" OFF \
"chrome" "Google Chrome" OFF \
"filezilla" "FileZilla" OFF 3>&1 1>&2 2>&3)

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
    echo "Validando versión de PHP y agregando PPA de Ondrej si es necesario..."
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
    # Instalación de paquetes de utilidades
    # -----------------------------------------------------

    echo "XXX"
    echo "19"
    echo "Instalando zip..."
    echo "XXX"
    if ! dpkg -s "zip" >/dev/null 2>&1; then
        apt install -y "zip" >/dev/null 2>&1
    fi

    echo "XXX"
    echo "23"
    echo "Instalando gpg..."
    echo "XXX"
    if ! dpkg -s "gpg" >/dev/null 2>&1; then
        apt install -y "gpg" >/dev/null 2>&1
    fi

    echo "XXX"
    echo "27"
    echo "Instalando curl..."
    echo "XXX"
    if ! dpkg -s "curl" >/dev/null 2>&1; then
        apt install -y "curl" >/dev/null 2>&1
    fi

    echo "XXX"
    echo "31"
    echo "Instalando unzip..."
    echo "XXX"
    if ! dpkg -s "unzip" >/dev/null 2>&1; then
        apt install -y "unzip" >/dev/null 2>&1
    fi

    # Paso 4: Verificación e instalación de Apache
    echo "XXX"
    echo "35"
    echo "Verificando e instalando Apache..."
    echo "XXX"
    
    if ! dpkg -s apache2 >/dev/null 2>&1; then
        apt install -y apache2 >/dev/null 2>&1
    fi
    sleep 1
    
    # Nuevo paso: Habilitar mod_rewrite para URLs dinámicas
    echo "XXX"
    echo "39"
    echo "Habilitando mod_rewrite en Apache..."
    echo "XXX"

    if ! a2enmod rewrite >/dev/null 2>&1; then
        echo "Error al habilitar mod_rewrite."
    fi
    systemctl restart apache2 >/dev/null 2>&1
    sleep 1
    
    # Paso 5: Verificación e instalación de PHP base
    echo "XXX"
    echo "43"
    echo "Verificando e instalando PHP base..."
    echo "XXX"
    
    if [[ "$CURRENT_PHP_VERSION" != "$PHPUSER" ]]; then
        apt install -y "php$PHPUSER" "libapache2-mod-php$PHPUSER" >/dev/null 2>&1
    fi
    sleep 1

    # -----------------------------------------------------
    # Instalación de extensiones de PHP por separado
    # -----------------------------------------------------

    # Laravel/WordPress
    echo "XXX"
    echo "47"
    echo "Instalando php${PHPUSER}-xml (Laravel/WP)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-xml" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-xml" >/dev/null 2>&1
    fi

    echo "XXX"
    echo "51"
    echo "Instalando php${PHPUSER}-zip (Laravel/WP)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-zip" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-zip" >/dev/null 2>&1
    fi

    echo "XXX"
    echo "55"
    echo "Instalando php${PHPUSER}-mbstring (Laravel/WP)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-mbstring" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-mbstring" >/dev/null 2>&1
    fi

    echo "XXX"
    echo "59"
    echo "Instalando php${PHPUSER}-dom (Laravel/WP)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-dom" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-dom" >/dev/null 2>&1
    fi
    
    echo "XXX"
    echo "63"
    echo "Instalando php${PHPUSER}-curl (Laravel/WP)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-curl" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-curl" >/dev/null 2>&1
    fi
    
    echo "XXX"
    echo "67"
    echo "Instalando php${PHPUSER}-fileinfo (Laravel/WP)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-fileinfo" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-fileinfo" >/dev/null 2>&1
    fi

    # Laravel
    echo "XXX"
    echo "71"
    echo "Instalando php${PHPUSER}-bcmath (Laravel)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-bcmath" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-bcmath" >/dev/null 2>&1
    fi

    # WordPress
    echo "XXX"
    echo "75"
    echo "Instalando php${PHPUSER}-gmp (WordPress)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-gmp" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-gmp" >/dev/null 2>&1
    fi
    
    echo "XXX"
    echo "79"
    echo "Instalando php${PHPUSER}-imagick (WordPress)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-imagick" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-imagick" >/dev/null 2>&1
    fi
    
    echo "XXX"
    echo "83"
    echo "Instalando php${PHPUSER}-exif (WordPress)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-exif" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-exif" >/dev/null 2>&1
    fi
    
    echo "XXX"
    echo "87"
    echo "Instalando php${PHPUSER}-gd (WordPress)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-gd" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-gd" >/dev/null 2>&1
    fi

    echo "XXX"
    echo "91"
    echo "Instalando php${PHPUSER}-iconv (WordPress)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-iconv" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-iconv" >/dev/null 2>&1
    fi

    echo "XXX"
    echo "92"
    echo "Instalando php${PHPUSER}-mysql (Base de Datos)..."
    echo "XXX"
    if ! dpkg -s "php${PHPUSER}-mysql" >/dev/null 2>&1; then
        apt install -y "php${PHPUSER}-mysql" >/dev/null 2>&1
    fi

    # -----------------------------------------------------
    # Instalación y configuración de la base de datos
    # -----------------------------------------------------

    echo "XXX"
    echo "93"
    echo "Instalando MariaDB/MySQL Server..."
    echo "XXX"
    if ! dpkg -s "$DBSERVER" >/dev/null 2>&1; then
        apt install -y "$DBSERVER" >/dev/null 2>&1
    fi

    echo "XXX"
    echo "94"
    echo "Configurando contraseñas para la base de datos..."
    echo "XXX"
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$PASSROOT';" >/dev/null 2>&1
    mysql -e "CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED BY '$PASSADMIN';" >/dev/null 2>&1
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;" >/dev/null 2>&1
    mysql -e "FLUSH PRIVILEGES;" >/dev/null 2>&1
    systemctl restart mysql >/dev/null 2>&1
    
    # -----------------------------------------------------
    # Instalación y configuración de phpmyadmin
    # -----------------------------------------------------

    echo "XXX"
    echo "96"
    echo "Instalando y configurando Phpmyadmin..."
    echo "XXX"

    if ! dpkg -s phpmyadmin >/dev/null 2>&1; then
        # Configuración no interactiva para phpmyadmin
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
    # Validación y configuración de la versión de PHP
    # -----------------------------------------------------

    echo "XXX"
    echo "98"
    echo "Validando y configurando la versión de PHP..."
    echo "XXX"
    # Deshabilitar todas las versiones de PHP en Apache y habilitar la elegida
    a2dismod php* >/dev/null 2>&1
    a2enmod "php$PHPUSER" >/dev/null 2>&1
    # Asegurar que la versión del CLI sea la correcta
    update-alternatives --set php "/usr/bin/php$PHPUSER" >/dev/null 2>&1
    systemctl restart apache2 >/dev/null 2>&1
    
    # Paso Final: Fin de la instalación
    echo "XXX"
    echo "100"
    echo "Fin Instalación"
    echo "XXX"
    sleep 3
    
) | whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalador de componentes" --gauge "Iniciando la instalación..." 6 60 0



exit 0
