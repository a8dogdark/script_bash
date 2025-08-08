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
VER="2.3" # Versión actualizada
CREAR_PROYECTO=0

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

# Validar que sea Ubuntu, Debian o AnduinOS, y definir DISTRO, DISVER y DBSERVER
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
    echo "Este script solo puede ejecutarse en Ubuntu, Debian o AnduinOS."
    exit 1
fi

# ---------------------------------------------------------
# Instalar whiptail si no está presente
# ---------------------------------------------------------
if ! command -v whiptail &> /dev/null; then
    apt install -y whiptail >/dev/null 2>&1
    sleep 1
fi

# ---------------------------------------------------------
# Cuadro de bienvenida
# ---------------------------------------------------------
if (whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Bienvenido" --yesno "Bienvenido al Instalador de Lamp para Laravel 12. Se instalarán los siguientes paquetes:\n\n- Apache\n- PHP\n- $DBSERVER\n- Phpmyadmin\n- Composer\n- NodeJs\n- Software Adicional (Opcional)\n\n¿Desea continuar con la instalación?" 16 70) then
    # El usuario seleccionó Aceptar, se continúa con la barra de progreso
    echo "" # Se agrega un salto de línea para separar la salida del whiptail
else
    # El usuario seleccionó Cancelar, se muestra un mensaje y se sale del script
    whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación cancelada" --msgbox "Has cancelado la instalación." 8 40
    exit 1
fi

# ---------------------------------------------------------
# Preguntar el nombre del proyecto Laravel (sin la pregunta de confirmación)
# ---------------------------------------------------------
CREAR_PROYECTO=1
PROYECTO=$(whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Nombre del Proyecto Laravel" --inputbox "Por favor, introduce el nombre del proyecto Laravel a crear en /var/www/html/:\n(Si lo dejas en blanco, se usará 'crud' por defecto)" 10 70 "" 3>&1 1>&2 2>&3)
    
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
    echo "18"
    echo "Instalando zip..."
    echo "XXX"
    if ! dpkg -s "zip" >/dev/null 2>&1; then
        apt install -y "zip" >/dev/null 2>&1
        sleep 1
    fi

    echo "XXX"
    echo "21"
    echo "Instalando gpg..."
    echo "XXX"
    if ! dpkg -s "gpg" >/dev/null 2>&1; then
        apt install -y "gpg" >/dev/null 2>&1
        sleep 1
    fi

    echo "XXX"
    echo "24"
    echo "Instalando curl..."
    echo "XXX"
    if ! dpkg -s "curl" >/dev/null 2>&1; then
        apt install -y "curl" >/dev/null 2>&1
        sleep 1
    fi

    echo "XXX"
    echo "27"
    echo "Instalando unzip..."
    echo "XXX"
    if ! dpkg -s "unzip" >/dev/null 2>&1; then
        apt install -y "unzip" >/dev/null 2>&1
        sleep 1
    fi
    
    # Nuevo: Instalar apt-transport-https antes de la instalación de VS Code
    echo "XXX"
    echo "29"
    echo "Verificando e instalando apt-transport-https..."
    echo "XXX"
    if ! dpkg -s apt-transport-https >/dev/null 2>&1; then
        apt install -y apt-transport-https >/dev/null 2>&1
        sleep 1
    fi
    

    # Paso 4: Verificación e instalación de Apache
    echo "XXX"
    echo "30"
    echo "Verificando e instalando Apache..."
    echo "XXX"
    
    if ! dpkg -s apache2 >/dev/null 2>&1; then
        apt install -y apache2 >/dev/null 2>&1
    fi
    sleep 1
    
    # Nuevo paso: Habilitar mod_rewrite para URLs dinámicas
    echo "XXX"
    echo "33"
    echo "Habilitando mod_rewrite en Apache..."
    echo "XXX"

    if ! a2enmod rewrite >/dev/null 2>&1; then
        echo "Error al habilitar mod_rewrite." 1>&2
    fi
    systemctl restart apache2 >/dev/null 2>&1
    sleep 1
    
    # Paso 5: Verificación e instalación de PHP base y todas sus extensiones
    echo "XXX"
    echo "36"
    echo "Verificando e instalando PHP base y extensiones..."
    echo "XXX"
    
    if [[ "$CURRENT_PHP_VERSION" != "$PHPUSER" ]]; then
        apt install -y "php$PHPUSER" "libapache2-mod-php$PHPUSER" "php${PHPUSER}-xml" "php${PHPUSER}-zip" "php${PHPUSER}-mbstring" "php${PHPUSER}-dom" "php${PHPUSER}-curl" "php${PHPUSER}-fileinfo" "php${PHPUSER}-bcmath" "php${PHPUSER}-gmp" "php${PHPUSER}-imagick" "php${PHPUSER}-exif" "php${PHPUSER}-gd" "php${PHPUSER}-iconv" "php${PHPUSER}-mysql" >/dev/null 2>&1
    else
        # Si la versión de PHP ya está instalada, solo se verifican las extensiones
        apt install -y "php${PHPUSER}-xml" "php${PHPUSER}-zip" "php${PHPUSER}-mbstring" "php${PHPUSER}-dom" "php${PHPUSER}-curl" "php${PHPUSER}-fileinfo" "php${PHPUSER}-bcmath" "php${PHPUSER}-gmp" "php${PHPUSER}-imagick" "php${PHPUSER}-exif" "php${PHPUSER}-gd" "php${PHPUSER}-iconv" "php${PHPUSER}-mysql" >/dev/null 2>&1
    fi
    sleep 1

    # -----------------------------------------------------
    # Instalación y configuración de la base de datos
    # -----------------------------------------------------

    echo "XXX"
    echo "60"
    echo "Instalando MariaDB/MySQL Server..."
    echo "XXX"
    if ! dpkg -s "$DBSERVER" >/dev/null 2>&1; then
        apt install -y "$DBSERVER" >/dev/null 2>&1
    fi
    sleep 1

    echo "XXX"
    echo "65"
    echo "Configurando contraseñas para la base de datos..."
    echo "XXX"
    # Configuración de usuario root y phpmyadmin
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$PASSROOT';" >/dev/null 2>&1
    mysql -e "FLUSH PRIVILEGES;" >/dev/null 2>&1
    mysql -u root -p"$PASSROOT" -e "CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED BY '$PASSADMIN';" >/dev/null 2>&1
    mysql -u root -p"$PASSROOT" -e "GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;" >/dev/null 2>&1
    mysql -u root -p"$PASSROOT" -e "FLUSH PRIVILEGES;" >/dev/null 2>&1
    systemctl restart mysql >/dev/null 2>&1
    sleep 1
    
    # -----------------------------------------------------
    # Instalación y configuración de phpmyadmin
    # -----------------------------------------------------

    echo "XXX"
    echo "70"
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
    sleep 1
    # -----------------------------------------------------
    # Validación y configuración de la versión de PHP
    # -----------------------------------------------------

    echo "XXX"
    echo "75"
    echo "Validando y configurando la versión de PHP..."
    echo "XXX"
    # Deshabilitar todas las versiones de PHP en Apache y habilitar la elegida
    a2dismod php* >/dev/null 2>&1
    a2enmod "php$PHPUSER" >/dev/null 2>&1
    # Asegurar que la versión del CLI sea la correcta
    update-alternatives --set php "/usr/bin/php$PHPUSER" >/dev/null 2>&1
    systemctl restart apache2 >/dev/null 2>&1
    sleep 1
    
    # -----------------------------------------------------
    # Crear archivo info.php para verificar la instalación
    # -----------------------------------------------------
    echo "XXX"
    echo "80"
    echo "Creando archivo info.php y configurando permisos..."
    echo "XXX"
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
    chown www-data:www-data /var/www/html/info.php >/dev/null 2>&1
    sleep 1

    # -----------------------------------------------------
    # Instalación de Composer
    # -----------------------------------------------------
    echo "XXX"
    echo "85"
    echo "Verificando e instalando Composer..."
    echo "XXX"
    if ! command -v composer &> /dev/null; then
        curl -sS https://getcomposer.org/installer | php >/dev/null 2>&1
        mv composer.phar /usr/local/bin/composer >/dev/null 2>&1
        chmod +x /usr/local/bin/composer >/dev/null 2>&1
    fi
    sleep 1
    # -----------------------------------------------------
    # Instalación de NodeJs si no está presente
    # -----------------------------------------------------
    echo "XXX"
    echo "90"
    echo "Verificando e instalando NodeJs si es necesario..."
    echo "XXX"
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - >/dev/null 2>&1
        apt install -y nodejs >/dev/null 2>&1
    fi
    sleep 1
    # -----------------------------------------------------
    # Instalación de software adicional
    # -----------------------------------------------------
    
    # Instalación de Visual Studio Code
    # Se ha corregido la validación para que reconozca correctamente la opción
    if [[ " $SOFTWARESUSER " =~ "vscode" ]]; then
        if ! command -v code &> /dev/null; then
            echo "XXX"
            echo "92"
            echo "Instalando Visual Studio Code: Paso 1 de 3..."
            echo "XXX"
            # Paso 1: Añadir la clave GPG de Microsoft
            curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/share/keyrings/microsoft-archive-keyring.gpg >/dev/null
            sleep 1
            
            echo "XXX"
            echo "93"
            echo "Instalando Visual Studio Code: Paso 2 de 3..."
            echo "XXX"
            # Paso 2: Añadir el repositorio de VS Code
            echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vscode.list >/dev/null
            sleep 1
            
            echo "XXX"
            echo "94"
            echo "Instalando Visual Studio Code: Paso 3 de 3..."
            echo "XXX"
            # Paso 3: Actualizar los repositorios e instalar VS Code
            apt update >/dev/null 2>&1
            apt install -y code >/dev/null 2>&1
            sleep 1
        fi
    fi

    # Instalación de Brave Browser
    if [[ " $SOFTWARESUSER " =~ "brave" ]]; then
        if ! dpkg -s brave-browser >/dev/null 2>&1; then
            echo "XXX"
            echo "95"
            echo "Instalando Brave Browser..."
            echo "XXX"
            apt install -y apt-transport-https curl >/dev/null 2>&1
            curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg >/dev/null 2>&1
            echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list >/dev/null 2>&1
            apt update >/dev/null 2>&1
            apt install -y brave-browser >/dev/null 2>&1
            sleep 1
        fi
    fi

    # Instalación de Google Chrome
    if [[ " $SOFTWARESUSER " =~ "chrome" ]]; then
        if ! dpkg -s google-chrome-stable >/dev/null 2>&1; then
            echo "XXX"
            echo "97"
            echo "Instalando Google Chrome..."
            echo "XXX"
            wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add - >/dev/null 2>&1
            sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list' >/dev/null 2>&1
            apt update >/dev/null 2>&1
            apt install -y google-chrome-stable >/dev/null 2>&1
            sleep 1
        fi
    fi
    
    # Instalación de FileZilla
    if [[ " $SOFTWARESUSER " =~ "filezilla" ]]; then
        if ! dpkg -s filezilla >/dev/null 2>&1; then
            echo "XXX"
            echo "99"
            echo "Instalando FileZilla..."
            echo "XXX"
            apt install -y filezilla >/dev/null 2>&1
            sleep 1
        fi
    fi
    
    
    # Paso Final: Fin de la instalación
    echo "XXX"
    echo "100"
    echo "Fin Instalación"
    echo "XXX"
    sleep 3
    
) | whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalador de componentes" --gauge "Iniciando la instalación..." 6 60 0

# ---------------------------------------------------------
# Mensaje final de éxito
# ---------------------------------------------------------

# Mensaje de éxito
whiptail --backtitle "Instalador Lamp para Laravel 12 V$VER" --title "Instalación completada" --msgbox "La instalación de los componentes LAMP y software adicional ha sido completada.\n\nPara verificar la instalación:\n- Apache: http://localhost\n- Phpinfo: http://localhost/info.php\n- Phpmyadmin: http://localhost/phpmyadmin\n\nContraseña de root de la DB: $PASSROOT\nContraseña de phpmyadmin: $PASSADMIN" 16 70

exit 0
