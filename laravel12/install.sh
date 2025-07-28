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
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "php${PHP_VERSION}" > /dev/null 2>&1
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
            yum install -y -q php php-cli php-fpm > /dev/null 2>&1
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
    
    # Redondea el porcentaje a un entero. Redirige stderr para evitar mensajes de error de printf en la barra de progreso.
    PERCENT_ROUNDED=$(printf "%.0f" "$CURRENT_PERCENT" 2>/dev/null)
    
    # Validación adicional: Si PERCENT_ROUNDED está vacío o no es numérico, usa el valor anterior o un valor por defecto.
    if ! [[ "$PERCENT_ROUNDED" =~ ^[0-9]+$ ]]; then
        # Intenta redondear de nuevo, si falla (e.g., CURRENT_PERCENT es inválido), usa PHP_START_PERCENT
        PERCENT_ROUNDED=$(printf "%.0f" "$CURRENT_PERCENT" 2>/dev/null || echo "$PHP_START_PERCENT")
        if (( $(echo "$PERCENT_ROUNDED < $PHP_START_PERCENT" | bc -l) )); then PERCENT_ROUNDED=$PHP_START_PERCENT; fi
    fi

    if (( PERCENT_ROUNDED > PHP_END_PERCENT )); then PERCENT_ROUNDED=$PHP_END_PERCENT; fi # No exceder el límite del rango PHP (40%)
    if (( PERCENT_ROUNDED > 100 )); then PERCENT_ROUNDED=100; fi # No exceder el 100% total
    if (( PERCENT_ROUNDED < 0 )); then PERCENT_ROUNDED=0; fi # No ser menor a 0%

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

# 45% - Instalando y configurando la base de datos (MariaDB o MySQL)
echo "XXX"
echo "45"
echo "Instalando y configurando: $DBASE..."
DB_PACKAGE_INSTALLED=false
if [ "$DBASE" = "MariaDB" ]; then
    if ! dpkg -s mariadb-server &> /dev/null; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mariadb-server mariadb-client > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar MariaDB."; fi
    else
        echo "MariaDB ya está instalado."
        DB_PACKAGE_INSTALLED=true
    fi
elif [ "$DBASE" = "MySQL" ]; then
    if ! rpm -q mysql-server &> /dev/null; then
        yum install -y -q mysql-server > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar MySQL."; fi
    else
        echo "MySQL ya está instalado."
        DB_PACKAGE_INSTALLED=true
    fi
fi

if ! $INSTALL_FAILED && ! $DB_PACKAGE_INSTALLED; then # Solo configurar si se instaló ahora o si no estaba y no hubo error.
    echo "Habilitando e iniciando $DBASE..."
    if [ "$DBASE" = "MariaDB" ]; then
        systemctl enable mariadb > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al habilitar MariaDB."; fi
        systemctl start mariadb > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al iniciar MariaDB."; fi
    elif [ "$DBASE" = "MySQL" ]; then
        systemctl enable mysqld > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al habilitar MySQL."; fi
        systemctl start mysqld > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al iniciar MySQL."; fi
    fi

    # Configuración de contraseñas de la base de datos (solo si no hay errores previos)
    if ! $INSTALL_FAILED; then
        echo "Configurando contraseñas de $DBASE..."
        if [ "$DBASE" = "MariaDB" ]; then
            # Secure installation for MariaDB
            mysql -u root <<EOF_SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '$PASSROOT';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED BY '$PASSPHP';
GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF_SQL
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al configurar MariaDB con contraseñas."; fi
        elif [ "$DBASE" = "MySQL" ]; then
            # Secure installation for MySQL
            mysql -u root <<EOF_SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '$PASSROOT';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED BY '$PASSPHP';
GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF_SQL
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al configurar MySQL con contraseñas."; fi
        fi
    fi
else
    echo "Saltando configuración de $DBASE debido a errores o porque ya estaba instalado."
    sleep 1
fi
echo "XXX"

# 50% - Instalando phpMyAdmin...
echo "XXX"
echo "50"
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    if ! dpkg -s phpmyadmin &> /dev/null; then
        echo "Instalando: phpMyAdmin (Ubuntu/Debian)..."
        # Pre-configurar debconf para instalación silenciosa
        echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
        echo "phpmyadmin phpmyadmin/app-password-confirm password $PASSPHP" | debconf-set-selections
        echo "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSROOT" | debconf-set-selections
        echo "phpmyadmin phpmyadmin/mysql/app-pass password $PASSPHP" | debconf-set-selections
        echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
        
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq phpmyadmin > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar phpMyAdmin."; fi
    else
        echo "phpMyAdmin ya está instalado."
        sleep 1
    fi
elif [ "$DISTRO" = "AlmaLinux" ]; then
    if ! rpm -q phpmyadmin &> /dev/null; then
        echo "Instalando: phpMyAdmin (AlmaLinux)..."
        yum install -y -q phpmyadmin > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar phpMyAdmin."; fi

        # Configurar Apache para phpMyAdmin en AlmaLinux (si no existe ya)
        if ! grep -q "Include /etc/httpd/conf.d/phpMyAdmin.conf" /etc/httpd/conf/httpd.conf; then
            echo "Alias /phpmyadmin /usr/share/phpmyadmin" > /etc/httpd/conf.d/phpMyAdmin.conf
            echo "<Directory /usr/share/phpmyadmin>" >> /etc/httpd/conf.d/phpMyAdmin.conf
            echo "    AddType application/x-httpd-php .php" >> /etc/httpd/conf.d/phpMyAdmin.conf
            echo "    DirectoryIndex index.php" >> /etc/httpd/conf.d/phpMyAdmin.conf
            echo "    Require all granted" >> /etc/httpd/conf.d/phpMyAdmin.conf
            echo "</Directory>" >> /etc/httpd/conf.d/phpMyAdmin.conf
            
            # Reiniciar Apache para aplicar la configuración
            systemctl restart httpd > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al reiniciar Apache después de configurar phpMyAdmin."; fi
        else
            echo "Configuración de phpMyAdmin para Apache ya existe."
        fi
    else
        echo "phpMyAdmin ya está instalado."
        sleep 1
    fi
fi
echo "XXX"

# 60% - Instalando Composer...
echo "XXX"
echo "60"
if ! command -v composer &> /dev/null; then
    echo "Instalando: Composer..."
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al descargar el instalador de Composer."; fi
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Composer."; fi
    rm composer-setup.php
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al eliminar el instalador de Composer."; fi
else
    echo "Composer ya está instalado."
    sleep 1
fi
echo "XXX"

# 70% - Instalando Node.js...
echo "XXX"
echo "70"
if ! command -v node &> /dev/null; then
    echo "Instalando: Node.js..."
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        # Usar Node.js 20 para Ubuntu/Debian (LTS actual)
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al añadir el repositorio de NodeSource."; fi
        if ! $INSTALL_FAILED; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Node.js."; fi
        fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        # Usar Node.js 20 para AlmaLinux (LTS actual)
        curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al añadir el repositorio de NodeSource."; fi
        if ! $INSTALL_FAILED; then
            yum install -y -q nodejs > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Node.js."; fi
        fi
    fi
else
    echo "Node.js ya está instalado."
    sleep 1
fi
echo "XXX"

# 80% - Creando la carpeta de proyectos Laravel y el proyecto en sí...
echo "XXX"
echo "80"
echo "Creando estructura de directorios para proyectos Laravel..."

LARAVEL_PROJECTS_DIR="/var/www/laravel"
PROJECT_PATH="${LARAVEL_PROJECTS_DIR}/${PROYECTO}"
VIRTUAL_HOST_CONF=""

# Crear la carpeta base /var/www/laravel si no existe
if [ ! -d "$LARAVEL_PROJECTS_DIR" ]; then
    mkdir -p "$LARAVEL_PROJECTS_DIR" > /dev/null 2>&1
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al crear el directorio $LARAVEL_PROJECTS_DIR."; fi
else
    echo "Directorio $LARAVEL_PROJECTS_DIR ya existe."
    sleep 1
fi

if ! $INSTALL_FAILED; then
    # Crear proyecto Laravel si la carpeta no existe
    if [ ! -d "$PROJECT_PATH" ]; then
        echo "Creando proyecto Laravel: $PROYECTO en $PROJECT_PATH (esto puede tardar unos minutos)..."
        # Usamos `sudo -u www-data` para que el proyecto se cree con los permisos correctos de Apache
        # En AlmaLinux, el usuario de Apache es 'apache'
        APACHE_USER=""
        if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
            APACHE_USER="www-data"
        elif [ "$DISTRO" = "AlmaLinux" ]; then
            APACHE_USER="apache"
        fi

        if [ -n "$APACHE_USER" ]; then
            sudo -u "$APACHE_USER" composer create-project laravel/laravel "$PROJECT_PATH" > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al crear el proyecto Laravel."; fi
        else
            INSTALL_FAILED=true; echo "ERROR: Usuario de Apache no definido para la distribución.";
        fi

        if ! $INSTALL_FAILED; then
            echo "Estableciendo permisos adecuados para el proyecto Laravel..."
            chown -R "$APACHE_USER":"$APACHE_USER" "$PROJECT_PATH" > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al establecer propietario de Laravel."; fi
            chmod -R 755 "$PROJECT_PATH" > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al establecer permisos de Laravel."; fi
            chmod -R 775 "${PROJECT_PATH}/storage" "${PROJECT_PATH}/bootstrap/cache" > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al establecer permisos de escritura para storage/cache."; fi

            # Ejecutar npm install y npm run build dentro del proyecto Laravel
            echo "Ejecutando 'npm install' en el proyecto Laravel (esto puede tardar)..."
            (cd "$PROJECT_PATH" && sudo -u "$APACHE_USER" npm install > /dev/null 2>&1)
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al ejecutar 'npm install' en el proyecto Laravel."; fi

            if ! $INSTALL_FAILED; then
                echo "Ejecutando 'npm run build' en el proyecto Laravel..."
                (cd "$PROJECT_PATH" && sudo -u "$APACHE_USER" npm run build > /dev/null 2>&1)
                if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al ejecutar 'npm run build' en el proyecto Laravel."; fi
            fi
        fi
    else
        echo "El proyecto Laravel '$PROYECTO' ya existe en $PROJECT_PATH. Saltando creación."
        sleep 1
    fi
else
    echo "Saltando creación de proyecto Laravel debido a errores previos."
    sleep 1
fi
echo "XXX"

# 85% - Configurando base de datos y ejecutando migraciones para Laravel
echo "XXX"
echo "85"
if ! $INSTALL_FAILED; then
    echo "Creando base de datos '${PROYECTO}' y configurando .env..."
    # Crear la base de datos si no existe
    mysql -u root -p"$PASSROOT" -e "CREATE DATABASE IF NOT EXISTS \`${PROYECTO}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" > /dev/null 2>&1
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al crear la base de datos '${PROYECTO}'. Asegúrate de que $DBASE esté corriendo y la contraseña root sea correcta."; fi

    if ! $INSTALL_FAILED; then
        # Actualizar el archivo .env del proyecto Laravel
        ENV_FILE="${PROJECT_PATH}/.env"
        
        # Primero, asegurar que .env existe y tiene permisos de escritura temporales para root
        if [ ! -f "$ENV_FILE" ]; then
            echo "Advertencia: .env no encontrado en $PROJECT_PATH. Creando desde .env.example."
            cp "${PROJECT_PATH}/.env.example" "$ENV_FILE" > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al copiar .env.example a .env."; fi
        fi
        
        if ! $INSTALL_FAILED; then
            # Temporalmente dar permisos de escritura para que `sed` pueda modificarlo
            # Luego se restauran los permisos para el usuario de Apache
            chmod 664 "$ENV_FILE" > /dev/null 2>&1
            
            sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${PROYECTO}/" "$ENV_FILE"
            sed -i "s/^DB_USERNAME=.*/DB_USERNAME=root/" "$ENV_FILE"
            sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${PASSROOT}/" "$ENV_FILE"
            
            # Restaurar permisos y propietario al usuario de Apache
            chmod 644 "$ENV_FILE" > /dev/null 2>&1
            chown "$APACHE_USER":"$APACHE_USER" "$ENV_FILE" > /dev/null 2>&1

            # Ejecutar migraciones de Laravel
            echo "Ejecutando migraciones de Laravel..."
            (cd "$PROJECT_PATH" && sudo -u "$APACHE_USER" php artisan migrate --force > /dev/null 2>&1)
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al ejecutar 'php artisan migrate'."; fi
        fi
    fi
else
    echo "Saltando configuración de base de datos y migraciones debido a errores previos."
    sleep 1
fi
echo "XXX"

# 90% - Configurando idioma español en Laravel
echo "XXX"
echo "90"
if ! $INSTALL_FAILED; then
    echo "Configurando idioma español para el proyecto Laravel..."
    # Instalar el paquete de traducciones de Laravel
    (cd "$PROJECT_PATH" && sudo -u "$APACHE_USER" composer require laravel-lang/lang > /dev/null 2>&1)
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar el paquete laravel-lang/lang."; fi

    if ! $INSTALL_FAILED; then
        # Publicar los archivos de idioma
        (cd "$PROJECT_PATH" && sudo -u "$APACHE_USER" php artisan lang:publish es > /dev/null 2>&1)
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al publicar las traducciones en español."; fi
    fi

    if ! $INSTALL_FAILED; then
        # Cambiar el locale por defecto en config/app.php
        APP_CONFIG_FILE="${PROJECT_PATH}/config/app.php"
        if [ -f "$APP_CONFIG_FILE" ]; then
            # Temporalmente dar permisos de escritura
            chmod 664 "$APP_CONFIG_FILE" > /dev/null 2>&1
            
            sed -i "s/'locale' => 'en'/'locale' => 'es'/" "$APP_CONFIG_FILE"
            sed -i "s/'faker_locale' => 'en_US'/'faker_locale' => 'es_ES'/" "$APP_CONFIG_FILE"
            
            # Restaurar permisos y propietario
            chmod 644 "$APP_CONFIG_FILE" > /dev/null 2>&1
            chown "$APACHE_USER":"$APACHE_USER" "$APP_CONFIG_FILE" > /dev/null 2>&1
            echo "Idioma español configurado correctamente en config/app.php."
        else
            INSTALL_FAILED=true; echo "ERROR: Archivo config/app.php no encontrado en $PROJECT_PATH.";
        fi
    fi
else
    echo "Saltando configuración de idioma español debido a errores previos."
    sleep 1
fi
echo "XXX"


# 93% - Configurando Virtual Host para Laravel...
echo "XXX"
echo "93"
if ! $INSTALL_FAILED; then
    echo "Configurando Virtual Host para ${PROYECTO}.test..."
    # Configuración de Virtual Host para Apache
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        VIRTUAL_HOST_CONF="/etc/apache2/sites-available/${PROYECTO}.conf"
        
        # Eliminar archivo de configuración si ya existe (para evitar duplicados en re-ejecuciones)
        if [ -f "$VIRTUAL_HOST_CONF" ]; then
            a2dissite "${PROYECTO}.conf" > /dev/null 2>&1
            rm "$VIRTUAL_HOST_CONF" > /dev/null 2>&1
            if [ $? -ne 0 ]; then echo "Advertencia: Fallo al limpiar configuración antigua de Virtual Host."; fi
        fi

        echo "<VirtualHost *:80>" > "$VIRTUAL_HOST_CONF"
        echo "    ServerName ${PROYECTO}.test" >> "$VIRTUAL_HOST_CONF"
        echo "    DocumentRoot ${PROJECT_PATH}/public" >> "$VIRTUAL_HOST_CONF"
        echo "    <Directory ${PROJECT_PATH}/public>" >> "$VIRTUAL_HOST_CONF"
        echo "        AllowOverride All" >> "$VIRTUAL_HOST_CONF"
        echo "        Require all granted" >> "$VIRTUAL_HOST_CONF"
        echo "    </Directory>" >> "$VIRTUAL_HOST_CONF"
        echo "    ErrorLog \${APACHE_LOG_DIR}/${PROYECTO}_error.log" >> "$VIRTUAL_HOST_CONF"
        echo "    CustomLog \${APACHE_LOG_DIR}/${PROYECTO}_access.log combined" >> "$VIRTUAL_HOST_CONF"
        echo "</VirtualHost>" >> "$VIRTUAL_HOST_CONF"

        a2ensite "${PROYECTO}.conf" > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al habilitar Virtual Host."; fi
        systemctl restart apache2 > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al reiniciar Apache después de configurar Virtual Host."; fi

    elif [ "$DISTRO" = "AlmaLinux" ]; then
        VIRTUAL_HOST_CONF="/etc/httpd/conf.d/${PROYECTO}.conf"

        # Eliminar archivo de configuración si ya existe
        if [ -f "$VIRTUAL_HOST_CONF" ]; then
            rm "$VIRTUAL_HOST_CONF" > /dev/null 2>&1
            if [ $? -ne 0 ]; then echo "Advertencia: Fallo al limpiar configuración antigua de Virtual Host."; fi
        fi

        echo "<VirtualHost *:80>" > "$VIRTUAL_HOST_CONF"
        echo "    ServerName ${PROYECTO}.test" >> "$VIRTUAL_HOST_CONF"
        echo "    DocumentRoot ${PROJECT_PATH}/public" >> "$VIRTUAL_HOST_CONF"
        echo "    <Directory ${PROJECT_PATH}/public>" >> "$VIRTUAL_HOST_CONF"
        echo "        AllowOverride All" >> "$VIRTUAL_HOST_CONF"
        echo "        Require all granted" >> "$VIRTUAL_HOST_CONF"
        echo "    </Directory>" >> "$VIRTUAL_HOST_CONF"
        echo "    ErrorLog /var/log/httpd/${PROYECTO}_error.log" >> "$VIRTUAL_HOST_CONF"
        echo "    CustomLog /var/log/httpd/${PROYECTO}_access.log combined" >> "$VIRTUAL_HOST_CONF"
        echo "</VirtualHost>" >> "$VIRTUAL_HOST_CONF"

        systemctl restart httpd > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al reiniciar Apache después de configurar Virtual Host."; fi
        
        # Enforce SELinux contexts for new directories
        echo "Aplicando contexto SELinux para el proyecto Laravel..."
        semanage fcontext -a -t httpd_sys_rw_content_t "${PROJECT_PATH}/storage(/.*)?" > /dev/null 2>&1
        semanage fcontext -a -t httpd_sys_rw_content_t "${PROJECT_PATH}/bootstrap/cache(/.*)?" > /dev/null 2>&1
        restorecon -Rv "${PROJECT_PATH}" > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al aplicar contexto SELinux. Esto podría causar problemas de permisos."; fi
    fi
    
    # Añadir entrada a /etc/hosts si no existe
    if ! grep -q "${PROYECTO}.test" /etc/hosts; then
        echo "Añadiendo entrada a /etc/hosts para ${PROYECTO}.test..."
        echo "127.0.0.1    ${PROYECTO}.test" >> /etc/hosts
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al añadir entrada a /etc/hosts."; fi
    else
        echo "Entrada para ${PROYECTO}.test ya existe en /etc/hosts."
    fi
else
    echo "Saltando configuración de Virtual Host debido a errores previos."
    sleep 1
fi
echo "XXX"

# 95% - Creando archivo info.php para verificación de PHP...
echo "XXX"
echo "95"
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

# 98% - Instalando programas adicionales seleccionados...
echo "XXX"
echo "98"
echo "Instalando programas seleccionados: ${PROGRAMAS_SELECCIONADOS[*]}..."

for PROGRAMA in "${PROGRAMAS_SELECCIONADOS[@]}"; do
    case "$PROGRAMA" in
        "vscode")
            if ! command -v code &> /dev/null; then
                echo "Instalando: Visual Studio Code..."
                if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
                    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
                    install -D -o -g 0 -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
                    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null
                    rm packages.microsoft.gpg

                    apt-get update -qq > /dev/null 2>&1
                    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq code > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Visual Studio Code."; fi
                elif [ "$DISTRO" = "AlmaLinux" ]; then
                    rpm --import https://packages.microsoft.com/keys/microsoft.asc > /dev/null 2>&1
                    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo
                    yum check-update -q > /dev/null 2>&1
                    yum install -y -q code > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Visual Studio Code."; fi
                fi
            else
                echo "Visual Studio Code ya está instalado."
            fi
            ;;
        "sublime")
            if ! command -v subl &> /dev/null; then
                echo "Instalando: Sublime Text..."
                if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
                    wget -qO - https://download.sublimetext.com/apt/rpm-pub-key.gpg | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null
                    echo "deb https://download.sublimetext.com/apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list > /dev/null
                    apt-get update -qq > /dev/null 2>&1
                    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq sublime-text > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Sublime Text."; fi
                elif [ "$DISTRO" = "AlmaLinux" ]; then
                    rpm -v --import https://download.sublimetext.com/rpm/rpmkey.gpg > /dev/null 2>&1
                    yum-config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo > /dev/null 2>&1
                    yum check-update -q > /dev/null 2>&1
                    yum install -y -q sublime-text > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Sublime Text."; fi
                fi
            else
                echo "Sublime Text ya está instalado."
            fi
            ;;
        "brave")
            if ! command -v brave-browser &> /dev/null; then
                echo "Instalando: Brave Browser..."
                if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
                    curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg > /dev/null 2>&1
                    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
                    apt-get update -qq > /dev/null 2>&1
                    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq brave-browser > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Brave Browser."; fi
                elif [ "$DISTRO" = "AlmaLinux" ]; then
                    rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc > /dev/null 2>&1
                    yum-config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/ > /dev/null 2>&1
                    yum check-update -q > /dev/null 2>&1
                    yum install -y -q brave-browser brave-keyring > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Brave Browser."; fi
                fi
            else
                echo "Brave Browser ya está instalado."
            fi
            ;;
        "chrome")
            if ! command -v google-chrome &> /dev/null; then
                echo "Instalando: Google Chrome..."
                if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
                    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | sudo tee /usr/share/keyrings/google-chrome.gpg > /dev/null
                    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
                    apt-get update -qq > /dev/null 2>&1
                    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq google-chrome-stable > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Google Chrome."; fi
                elif [ "$DISTRO" = "AlmaLinux" ]; then
                    curl https://dl.google.com/linux/linux_signing_key.pub | sudo rpm --import - > /dev/null 2>&1
                    echo -e "[google-chrome]\nname=google-chrome\nbaseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64\nenabled=1\ngpgcheck=1\ngpgkey=https://dl.google.com/linux/linux_signing_key.pub" > /etc/yum.repos.d/google-chrome.repo
                    yum check-update -q > /dev/null 2>&1
                    yum install -y -q google-chrome-stable > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Google Chrome."; fi
                fi
            else
                echo "Google Chrome ya está instalado."
            fi
            ;;
        *)
            echo "Programa desconocido seleccionado: $PROGRAMA. Saltando."
            ;;
    esalac
    sleep 1 # Pequeña pausa para visualizar los mensajes de instalación
done
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
    # Construir el mensaje para el cuadro de diálogo final
    MESSAGE="¡La instalación de LAMP y Laravel se ha completado con éxito!\n\n"
    MESSAGE+="\Z1**Datos de tu proyecto:**\Z0\n"
    MESSAGE+="-   **URL del Proyecto:** http://${PROYECTO}.test\n"
    MESSAGE+="-   **Ubicación del Proyecto:** ${PROJECT_PATH}\n"
    MESSAGE+="-   **Verificación PHP:** http://TU_IP/info.php\n"
    MESSAGE+="-   **phpMyAdmin:** http://TU_IP/phpmyadmin\n\n"
    MESSAGE+="\Z1**Credenciales de Base de Datos:**\Z0\n"
    MESSAGE+="-   **Usuario Root (${DBASE}):** root\n"
    MESSAGE+="-   **Contraseña Root (${DBASE}):** ${PASSROOT}\n"
    MESSAGE+="-   **Usuario phpMyAdmin:** phpmyadmin\n"
    MESSAGE+="-   **Contraseña phpMyAdmin:** ${PASSPHP}\n\n"
    MESSAGE+="\Z1**¡IMPORTANTE!**\Z0 En tu equipo local (no en el servidor), debes añadir la siguiente línea a tu archivo \`/etc/hosts\` (o \`C:\\Windows\\System32\\drivers\\etc\\hosts\` en Windows) para que el dominio \`${PROYECTO}.test\` funcione:\n"
    MESSAGE+="    \Z4**127.0.0.1    ${PROYECTO}.test**\Z0\n\n"
    MESSAGE+="Presiona ENTER para limpiar la pantalla."

    dialog --title "Instalación Completada con Éxito" --msgbox "$MESSAGE" 25 80
fi

clear # Limpia la pantalla después de que el usuario presione Enter
