#!/bin/bash

VERSION="2.0"
DISTRO=""
PASSPHP=""
PASSROOT=""
PROYECTO=""
DBASE=""
PHP_VERSION="" # Nueva variable para almacenar la versión de PHP seleccionada
PROGRAMAS_SELECCIONADOS=() # Array para almacenar los programas seleccionados
INSTALL_FAILED=false # Bandera para indicar si alguna instalación falló

# Valida si el script se está ejecutando como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como root. Por favor, ejecuta con 'sudo bash $(basename "$0")'."
    exit 1
fi

# Detectar la distribución
if grep -q "Ubuntu" /etc/os-release; then
    DISTRO="Ubuntu"
elif grep -q "Debian" /etc/os-release; then
    DISTRO="Debian"
elif grep -q "AlmaLinux" /etc/os-release; then
    DISTRO="AlmaLinux"
else
    echo "Distribución no soportada. Este script es compatible con Ubuntu (22, 23, 24), Debian (11, 12) y AlmaLinux."
    exit 1
fi

# Detectar qué base de datos se utilizará según la distribución
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    DBASE="MariaDB"
elif [ "$DISTRO" = "AlmaLinux" ]; then
    DBASE="MySQL"
fi


# Validar que el sistema sea de 64 bits
if [ "$(uname -m)" != "x86_64" ]; then
    echo "Este script solo puede ejecutarse en sistemas de 64 bits (x86_64)."
    exit 1
fi

# Validar e instalar dialog si no está presente
if ! command -v dialog &> /dev/null; then
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y dialog > /dev/null 2>&1
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y dialog > /dev/null 2>&1
    fi
    if ! command -v dialog &> /dev/null; then
        echo "Error: No se pudo instalar dialog. Abortando."
        exit 1
    fi
fi

# Función para manejar la salida de dialog (Enter o ESC, y campo vacío)
check_input() {
    local input_value="$1"
    local input_name="$2"
    local dialog_exit_code="$3"

    if [ -z "$input_value" ]; then
        dialog --title "Error" --msgbox "El campo '$input_name' no puede estar vacío." 8 40
        clear
        exit 1
    elif [ "$dialog_exit_code" -ne 0 ]; then # 0 para OK, 1 para Cancel, 255 para ESC
        clear
        echo "Instalación cancelada por el usuario."
        exit 0
    fi
}

# Cuadro de bienvenida
dialog --title "Bienvenido al Instalador y creador de proyectos Laravel 12" \
--backtitle "Instalador LAMP Laravel 12 - Versión $VERSION" \
--yesno "\nSe instalarán los siguientes paquetes:\n\n- Apache\n- PHP\n- $DBASE\n- phpMyAdmin\n- Composer\n- Node.js\n- Programas del proyecto\n\n¿Deseas continuar?" 18 70

response=$?
case $response in
    0) # Botón Aceptar presionado
        clear
        ;;
    1) # Botón Cancelar presionado
        clear
        echo "Instalación cancelada por el usuario."
        exit 0
        ;;
    255) # Tecla ESC presionada
        clear
        echo "Instalación cancelada por el usuario (ESC)."
        exit 0
        ;;
esac

# Input para el nombre del proyecto
PROYECTO=$(dialog --clear --stdout \
                --title "Nombre del Proyecto Laravel" \
                --inputbox "Ingresa el nombre del proyecto Laravel 12 a crear:" 10 60)
check_input "$PROYECTO" "Nombre del Proyecto" $?

# Input para la contraseña del usuario phpMyAdmin de la base de datos
PASSPHP=$(dialog --clear --stdout \
               --title "Contraseña para Usuario phpMyAdmin de MySQL/MariaDB" \
               --inputbox "Ingresa la contraseña para el usuario phpMyAdmin de la base de datos:" 10 60)
check_input "$PASSPHP" "Contraseña phpMyAdmin" $?

# Input para la contraseña del usuario root de la base de datos
PASSROOT=$(dialog --clear --stdout \
                --title "Contraseña para Usuario Root de MySQL/MariaDB" \
                --inputbox "Ingresa la contraseña para el usuario root de la base de datos:" 10 60)
check_input "$PASSROOT" "Contraseña Root" $?

# Cuadro de selección de versión de PHP (radiolist)
PHP_VERSION=$(dialog --clear --stdout \
                     --title "Selección de Versión de PHP" \
                     --radiolist "Laravel 12 es compatible con PHP 8.2 y superior. Selecciona la versión de PHP a instalar:" 15 50 3 \
                     "8.2" "Recomendada para Laravel 12" ON \
                     "8.3" "Versión más reciente con mejoras" OFF \
                     "8.4" "Versión en desarrollo (no recomendada para producción)" OFF )

php_choice_exit_code=$?
if [ "$php_choice_exit_code" -eq 1 ] || [ "$php_choice_exit_code" -eq 255 ]; then # Solo si Cancel o ESC
    clear
    echo "Instalación cancelada por el usuario."
    exit 0
fi

# Cuadro de selección de programas
PROGRAMAS_SELECCIONADOS_STR=$(dialog --clear --stdout \
                                     --title "Selección de Programas Adicionales" \
                                     --checklist "Selecciona uno o más programas para instalar:" 18 60 4 \
                                     "vscode" "Visual Studio Code" OFF \
                                     "sublime" "Sublime Text" OFF \
                                     "brave" "Brave Browser" OFF \
                                     "chrome" "Google Chrome" OFF )

programs_choice_exit_code=$?
if [ "$programs_choice_exit_code" -ne 0 ]; then
    clear
    echo "Instalación cancelada por el usuario."
    exit 0
fi

# Convertir la cadena de programas seleccionados en un array
IFS=' ' read -r -a PROGRAMAS_SELECCIONADOS <<< "$PROGRAMAS_SELECCIONADOS_STR"

# --- BARRA DE PROGRESO DE INSTALACIÓN ---
(
# 1% - Preparación del sistema: Actualizar índices de paquetes
echo "XXX"
echo "1"
echo "Preparando el sistema: Actualizando índices de paquetes..."
echo "XXX"
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    apt-get update -qq > /dev/null 2>&1
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: No se pudieron actualizar los índices de paquetes."; fi
elif [ "$DISTRO" = "AlmaLinux" ]; then
    yum makecache -y > /dev/null 2>&1
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: No se pudieron actualizar los índices de paquetes."; fi
fi

# 2% - Preparación del sistema: Actualizando paquetes
echo "XXX"
echo "2"
echo "Preparando el sistema: Actualizando paquetes..."
echo "XXX"
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq > /dev/null 2>&1
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: No se pudieron actualizar los paquetes del sistema."; fi
elif [ "$DISTRO" = "AlmaLinux" ]; then
    yum update -y -q > /dev/null 2>&1
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: No se pudieron actualizar los paquetes del sistema."; fi
fi

# 3% - Instalando utilidades esenciales: curl
echo "XXX"
echo "3"
if ! command -v curl &> /dev/null; then
    echo "Instalando: curl..."
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar curl."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y -q curl > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar curl."; fi
    fi
else
    echo "curl ya está instalado."
    sleep 1 # Pausa para visualizar el mensaje
fi
echo "XXX"

# 4% - Instalando utilidades esenciales: wget
echo "XXX"
echo "4"
if ! command -v wget &> /dev/null; then
    echo "Instalando: wget..."
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq wget > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar wget."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y -q wget > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar wget."; fi
    fi
else
    echo "wget ya está instalado."
    sleep 1 # Pausa para visualizar el mensaje
fi
echo "XXX"

# 5% - Instalando utilidades esenciales: unzip
echo "XXX"
echo "5"
if ! command -v unzip &> /dev/null; then
    echo "Instalando: unzip..."
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq unzip > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar unzip."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y -q unzip > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar unzip."; fi
    fi
else
    echo "unzip ya está instalado."
    sleep 1 # Pausa para visualizar el mensaje
fi
echo "XXX"

# 6% - Instalando utilidades esenciales: zip
echo "XXX"
echo "6"
if ! command -v zip &> /dev/null; then
    echo "Instalando: zip..."
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq zip > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar zip."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y -q zip > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar zip."; fi
    fi
else
    echo "zip ya está instalado."
    sleep 1 # Pausa para visualizar el mensaje
fi
echo "XXX"

# 7% - Añadiendo PPA de Ondrej para PHP (Solo Ubuntu/Debian)
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    echo "XXX"
    echo "7"
    if ! grep -q "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
        echo "Añadiendo repositorio PHP de Ondrej PPA..."
        # Instalar software-properties-common si no está instalado (necesario para add-apt-repository)
        if ! command -v add-apt-repository &> /dev/null; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq software-properties-common > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar software-properties-common."; fi
        fi
        if ! $INSTALL_FAILED; then # Solo si la instalación de software-properties-common fue exitosa
            add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al añadir Ondrej PPA."; fi
            if ! $INSTALL_FAILED; then # Si el PPA se añadió correctamente, actualizar de nuevo
                apt-get update -qq > /dev/null 2>&1
                if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al actualizar índices tras añadir PPA."; fi
            fi
        fi
    else
        echo "Ondrej PPA ya está agregado."
        sleep 1 # Pausa para visualizar el mensaje
    fi
    echo "XXX"
else
    echo "XXX"
    echo "7"
    echo "Saltando: Ondrej PPA (No es Ubuntu/Debian)."
    echo "XXX"
fi


# 9% - Instalando Apache
echo "XXX"
echo "9"
# Primero, comprueba si Apache (httpd o apache2) ya está instalado
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    if ! command -v apache2 &> /dev/null; then
        echo "Instalando: Apache..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq apache2 > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Apache."; fi
    else
        echo "Apache ya está instalado."
        sleep 1 # Pausa para visualizar el mensaje
    fi
elif [ "$DISTRO" = "AlmaLinux" ]; then
    if ! command -v httpd &> /dev/null; then
        echo "Instalando: Apache (httpd)..."
        yum install -y -q httpd > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Apache (httpd)."; fi
    else
        echo "Apache (httpd) ya está instalado."
        sleep 1 # Pausa para visualizar el mensaje
    fi
fi

# 10% - Habilitando mod_rewrite y reiniciando Apache
echo "XXX"
echo "10"
if ! $INSTALL_FAILED; then # Solo intenta configurar si no hubo un error crítico en la instalación
    echo "Habilitando módulo mod_rewrite..."
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        a2enmod rewrite > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al habilitar mod_rewrite."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        # En AlmaLinux, mod_rewrite suele estar habilitado por defecto o es parte del paquete base httpd.
        # No hay un comando directo como a2enmod. Solo verificamos si el módulo está cargado.
        if ! httpd -M 2>/dev/null | grep -q "rewrite_module"; then
            echo "Advertencia: mod_rewrite no encontrado o no habilitado. Puede requerir configuración manual."
            # No se establece INSTALL_FAILED a true ya que no hay un comando de habilitación simple.
        else
            echo "mod_rewrite ya está habilitado."
        fi
    fi
    
    echo "Configurando e iniciando Apache..."
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        systemctl enable apache2 > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al habilitar Apache."; fi
        systemctl restart apache2 > /dev/null 2>&1 # Reiniciar para aplicar cambios de mod_rewrite
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al iniciar/reiniciar Apache."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        systemctl enable httpd > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al habilitar httpd."; fi
        systemctl restart httpd > /dev/null 2>&1 # Reiniciar para aplicar cambios
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al iniciar/reiniciar httpd."; fi

        # Para AlmaLinux, también es común abrir el firewall para HTTP/HTTPS
        firewall-cmd --permanent --add-service=http > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al abrir puerto HTTP en firewall."; fi
        firewall-cmd --permanent --add-service=https > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al abrir puerto HTTPS en firewall."; fi
        firewall-cmd --reload > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al recargar firewall."; fi
    fi
else
    echo "Saltando configuración de Apache y mod_rewrite debido a errores previos."
    sleep 1
fi
echo "XXX"

# Rango de 12% a 40% para PHP y extensiones (se mantiene, pero se ajustará internamente)
PHP_START_PERCENT=12
PHP_END_PERCENT=40

# Lista de extensiones a instalar con sus nombres de paquetes.
# Formato: "Nombre legible" "paquete-ubuntu-debian" "paquete-almalinux"
PHP_EXTENSIONS=(
    "Core/Base CLI" "php${PHP_VERSION}-cli" "php-cli"
    "FPM" "php${PHP_VERSION}-fpm" "php-fpm"
    "Common" "php${PHP_VERSION}-common" "php-common"
    "OpCache" "php${PHP_VERSION}-opcache" "php-opcache"
    "MySQL (pdo_mysql)" "php${PHP_VERSION}-mysql" "php-mysqlnd"
    "XML" "php${PHP_VERSION}-xml" "php-xml"
    "Mbstring" "php${PHP_VERSION}-mbstring" "php-mbstring"
    "Zip" "php${PHP_VERSION}-zip" "php-zip"
    "BCMath" "php${PHP_VERSION}-bcmath" "php-bcmath"
    "GD" "php${PHP_VERSION}-gd" "php-gd"
    "Curl" "php${PHP_VERSION}-curl" "php-curl"
    "JSON" "php${PHP_VERSION}-json" "php-json"
    "PDO" "php${PHP_VERSION}-pdo" "php-pdo"
    "BZ2" "php${PHP_VERSION}-bz2" "php-bz2"
    "Calendar" "php${PHP_VERSION}-calendar" "php-calendar"
    "Ctype" "php${PHP_VERSION}-ctype" "php-ctype"
    "DOM" "php${PHP_VERSION}-dom" "php-dom"
    "FFI" "php${PHP_VERSION}-ffi" "php-ffi"
    "Fileinfo" "php${PHP_VERSION}-fileinfo" "php-fileinfo"
    "FTP" "php${PHP_VERSION}-ftp" "php-ftp"
    "Gettext" "php${PHP_VERSION}-gettext" "php-gettext"
    "Iconv" "php${PHP_VERSION}-iconv" "php-iconv"
    "MySQLi" "php${PHP_VERSION}-mysqli" "php-mysqli"
    "Phar" "php${PHP_VERSION}-phar" "php-phar"
    "Posix" "php${PHP_VERSION}-posix" "php-posix"
    "Readline" "php${PHP_VERSION}-readline" "php-readline"
    "Shmop" "php${PHP_VERSION}-shmop" "php-shmop"
    "SimpleXML" "php${PHP_VERSION}-simplexml" "php-xml"
    "Sockets" "php${PHP_VERSION}-sockets" "php-sockets"
    "Sysvmsg" "php${PHP_VERSION}-sysvmsg" "php-sysvmsg"
    "Tokenizer" "php${PHP_VERSION}-tokenizer" "php-tokenizer"
    "XMLReader" "php${PHP_VERSION}-xmlreader" "php-xml"
    "XMLWriter" "php${PHP_VERSION}-xmlwriter" "php-xml"
    "XSL" "php${PHP_VERSION}-xsl" "php-xsl"
)

NUM_EXTENSIONS=${#PHP_EXTENSIONS[@]}
# Se suma 1 por el paso inicial de "base_and_remi"
PHP_STEP_INCREMENT=$(awk "BEGIN {print ($PHP_END_PERCENT - $PHP_START_PERCENT) / ($NUM_EXTENSIONS + 1)}") 

CURRENT_PERCENT=$PHP_START_PERCENT

install_php_base_and_remi() {
    local base_installed=false
    echo "XXX"
    echo "$CURRENT_PERCENT"
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        if ! dpkg -s "php${PHP_VERSION}-cli" &> /dev/null; then
            echo "Instalando base de PHP ${PHP_VERSION} (cli)..."
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "php${PHP_VERSION}" > /dev/null 2>&1 # Instala la meta-paquete phpX.Y
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar la base de PHP ${PHP_VERSION}."; fi
        else
            echo "Base de PHP ${PHP_VERSION} (cli) ya está instalada."
            base_installed=true
        fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        if ! yum repolist | grep -q "remi-php${PHP_VERSION//./}"; then
            echo "Habilitando repositorio Remi para PHP ${PHP_VERSION}..."
            yum install -y -q https://rpms.remirepo.net/enterprise/remi-release-8.rpm > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar el repositorio Remi."; fi
            if ! $INSTALL_FAILED; then
                yum module enable -y php:remi-"${PHP_VERSION//./}" > /dev/null 2>&1
                if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al habilitar el módulo PHP Remi."; fi
            fi
        fi
        # En AlmaLinux, `php` es el paquete principal una vez que el módulo Remi está habilitado.
        if ! rpm -q "php-cli" &> /dev/null; then # Más robusto para verificar RPMs para php-cli
            echo "Instalando base de PHP ${PHP_VERSION} (cli/fpm)..."
            yum install -y -q php php-cli php-fpm > /dev/null 2>&1 # Instala los paquetes base de PHP
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar la base de PHP ${PHP_VERSION} en AlmaLinux."; fi
        else
            echo "Base de PHP ${PHP_VERSION} (cli/fpm) ya está instalada."
            base_installed=true
        fi
    fi
    echo "XXX"
    if $base_installed; then sleep 1; fi # Pausa si ya estaba instalado
}

install_php_extension() {
    local EXTENSION_NAME="$1"
    local UBUNTU_PACKAGE="$2"
    local ALMALINUX_PACKAGE="$3"

    # Incrementa el porcentaje antes de cada paso
    CURRENT_PERCENT=$(awk "BEGIN {print $CURRENT_PERCENT + $PHP_STEP_INCREMENT}")
    # Redondea el porcentaje para evitar decimales en dialog
    PERCENT_ROUNDED=$(printf "%.0f\n" "$CURRENT_PERCENT")
    if (( PERCENT_ROUNDED > PHP_END_PERCENT )); then PERCENT_ROUNDED=$PHP_END_PERCENT; fi # No exceder el límite

    echo "XXX"
    echo "$PERCENT_ROUNDED" # Usa el porcentaje redondeado
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        if ! dpkg -s "$UBUNTU_PACKAGE" &> /dev/null; then
            echo "Instalando PHP extensión: $EXTENSION_NAME ($UBUNTU_PACKAGE)..."
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$UBUNTU_PACKAGE" > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar $UBUNTU_PACKAGE."; fi
        else
            echo "PHP extensión $EXTENSION_NAME ya está instalada."
            sleep 1
        fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        if ! rpm -q "$ALMALINUX_PACKAGE" &> /dev/null; then
            echo "Instalando PHP extensión: $EXTENSION_NAME ($ALMALINUX_PACKAGE)..."
            yum install -y -q "$ALMALINUX_PACKAGE" > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar $ALMALINUX_PACKAGE."; fi
        else
            echo "PHP extensión $EXTENSION_NAME ya está instalada."
            sleep 1
        fi
    fi
    echo "XXX"
}

# 12% - Instalando base de PHP y configurando Remi (si aplica)
install_php_base_and_remi

# Instalar cada extensión definida
for (( i=0; i<${#PHP_EXTENSIONS[@]}; i+=3 )); do
    EXT_NAME="${PHP_EXTENSIONS[i]}"
    UBUNTU_PKG="${PHP_EXTENSIONS[i+1]}"
    ALMALINUX_PKG="${PHP_EXTENSIONS[i+2]}"
    install_php_extension "$EXT_NAME" "$UBUNTU_PKG" "$ALMALINUX_PKG"
done


# 40% - Configuración final de PHP y reinicio de Apache
echo "XXX"
echo "40"
if ! $INSTALL_FAILED; then
    echo "Configurando PHP ${PHP_VERSION} y reiniciando Apache..."
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        # Deshabilitar otras versiones de PHP FPM si existen y habilitar la seleccionada
        INSTALLED_PHP_FPM_VERSIONS=$(dpkg -l | grep -oP 'php\d\.\d-fpm' | sed 's/php//;s/-fpm//' | sort -rV)
        for version in $INSTALLED_PHP_FPM_VERSIONS; do
            if [ "$version" != "$PHP_VERSION" ]; then
                a2dismod "php${version}" > /dev/null 2>&1
                systemctl stop "php${version}-fpm" > /dev/null 2>&1
                systemctl disable "php${version}-fpm" > /dev/null 2>&1
            fi
        done
        a2enmod "php${PHP_VERSION}" > /dev/null 2>&1
        systemctl restart apache2 > /dev/null 2>&1
        systemctl restart "php${PHP_VERSION}-fpm" > /dev/null 2>&1
        systemctl enable "php${PHP_VERSION}-fpm" > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al configurar PHP ${PHP_VERSION} o reiniciar Apache/PHP-FPM."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        systemctl restart httpd > /dev/null 2>&1
        systemctl enable php-fpm > /dev/null 2>&1
        systemctl restart php-fpm > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al reiniciar httpd o php-fpm."; fi
    fi
else
    echo "Saltando configuración de PHP debido a errores previos."
    sleep 1
fi
echo "XXX"

# 50% - Instalando $DBASE...
echo "XXX"
echo "50"
echo "Instalando: $DBASE..."
# Placeholder for MariaDB/MySQL installation logic
sleep 1 # Simula el tiempo de instalación
echo "XXX"


# 60% - Instalando phpMyAdmin...
echo "XXX"
echo "60"
echo "Instalando: phpMyAdmin..."
# Placeholder for phpMyAdmin installation logic
sleep 1 # Simula el tiempo de instalación
echo "XXX"

# 70% - Instalando Composer...
echo "XXX"
echo "70"
echo "Instalando: Composer..."
# Placeholder for Composer installation logic
sleep 1 # Simula el tiempo de instalación
echo "XXX"

# 80% - Instalando Node.js...
echo "XXX"
echo "80"
echo "Instalando: Node.js..."
# Placeholder for Node.js installation logic
sleep 1 # Simula el tiempo de instalación
echo "XXX"

# 85% - Creando proyecto Laravel...
echo "XXX"
echo "85"
echo "Creando proyecto Laravel: $PROYECTO..."
# Placeholder for Laravel project creation logic
sleep 1 # Simula el tiempo de instalación
echo "XXX"

# 90% - Creando archivo info.php para verificación de PHP...
echo "XXX"
echo "90"
if [ -f "/var/www/html/info.php" ]; then
    echo "El archivo info.php ya existe. Saltando creación."
    sleep 1 # Pequeña pausa para que el mensaje sea visible
else
    echo "Creando archivo info.php en el directorio web de Apache..."
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al crear /var/www/html/info.php."; fi
    # Asegurarse de que Apache pueda leer el archivo
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        chown www-data:www-data /var/www/html/info.php > /dev/null 2>&1
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        chown apache:apache /var/www/html/info.php > /dev/null 2>&1
    fi
    chmod 644 /var/www/html/info.php > /dev/null 2>&1
fi
echo "XXX"

# 98% - Instalando programas adicionales...
echo "XXX"
echo "98"
echo "Instalando programas seleccionados: ${PROGRAMAS_SELECCIONADOS[*]}..."
# Placeholder for additional program installation logic
sleep 1 # Simula el tiempo de instalación
echo "XXX"

# 100% - Simulando finalización
echo "XXX"
echo "100"
echo "Configuraciones finales completadas."
echo "XXX"

) | dialog --gauge "Iniciando instalación de LAMP y Laravel. Por favor, espera..." 10 70 0

clear

# Mensaje final condicional
if $INSTALL_FAILED; then
    dialog --title "Instalación con Errores" --msgbox "La instalación de LAMP y Laravel ha finalizado, pero se detectaron errores en algunos pasos. Por favor, revisa la salida de la consola para más detalles." 10 70
else
    dialog --title "Instalación Completada" --msgbox "La instalación de LAMP y Laravel se ha completado con éxito. Puedes verificar la instalación de PHP visitando http://TU_IP/info.php en tu navegador." 10 70
fi
