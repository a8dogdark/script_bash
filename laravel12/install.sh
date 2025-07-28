#!/bin/bash

VERSION="2.0"
DISTRO=""
PASSPHP=""
PASSROOT=""
PROYECTO=""
DBASE=""
PHP_VERSION="" # Variable para almacenar la versión de PHP seleccionada
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
    echo "Instalando 'dialog'..."
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get update -qq > /dev/null 2>&1 || { echo "Error: Fallo al actualizar apt para instalar dialog."; exit 1; }
        DEBIAN_FRONTEND=noninteractive apt-get install -y dialog -qq > /dev/null 2>&1 || { echo "Error: No se pudo instalar dialog."; exit 1; }
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y dialog -q > /dev/null 2>&1 || { echo "Error: No se pudo instalar dialog."; exit 1; }
    fi
    if ! command -v dialog &> /dev/null; then
        echo "Error: 'dialog' no pudo ser instalado. Abortando."
        exit 1
    fi
    clear # Limpiar la pantalla después de la instalación de dialog
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
--yesno "\nSe instalarán los siguientes paquetes:\n\n- Apache\n- PHP\n- $DBASE\n- phpMyAdmin\n- Composer\n- Node.js\n- Programas del proyecto (Opcional)\n\n¿Deseas continuar?" 18 70

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
                --backtitle "Instalador LAMP Laravel 12 - Versión $VERSION" \
                --title "Nombre del Proyecto Laravel" \
                --inputbox "Ingresa el nombre del proyecto Laravel 12 a crear (Ej: mi_proyecto_web):" 10 60)
check_input "$PROYECTO" "Nombre del Proyecto" $?
clear # Limpiar después de que el usuario interactúe

# Input para la contraseña del usuario phpMyAdmin de la base de datos
# *** CAMBIO: Usando --inputbox para que se vea lo que se ingresa ***
echo "Por favor, ingresa la contraseña para el usuario phpMyAdmin de la base de datos y presiona ENTER."
PASSPHP=$(dialog --clear --stdout \
               --backtitle "Instalador LAMP Laravel 12 - Versión $VERSION" \
               --title "Contraseña para Usuario phpMyAdmin de MySQL/MariaDB" \
               --inputbox "Ingresa la contraseña para el usuario phpMyAdmin de la base de datos:" 10 60)
check_input "$PASSPHP" "Contraseña phpMyAdmin" $?
clear # Limpiar después de que el usuario interactúe

# Input para la contraseña del usuario root de la base de datos
# *** CAMBIO: Usando --inputbox para que se vea lo que se ingresa ***
echo "Por favor, ingresa la contraseña para el usuario root de la base de datos y presiona ENTER."
PASSROOT=$(dialog --clear --stdout \
                --backtitle "Instalador LAMP Laravel 12 - Versión $VERSION" \
                --title "Contraseña para Usuario Root de MySQL/MariaDB" \
               --inputbox "Ingresa la contraseña para el usuario root de la base de datos:" 10 60)
check_input "$PASSROOT" "Contraseña Root" $?
clear # Limpiar después de que el usuario interactúe

# Cuadro de selección de versión de PHP (radiolist)
PHP_VERSION=$(dialog --clear --stdout \
                     --backtitle "Instalador LAMP Laravel 12 - Versión $VERSION" \
                     --title "Selección de Versión de PHP" \
                     --radiolist "Laravel 12 es compatible con PHP 8.2 y superior. Selecciona la versión de PHP a instalar:" 15 50 3 \
                     "8.2" "Recomendada para Laravel 12" ON \
                     "8.3" "Versión más reciente con mejoras" OFF \
                     "8.4" "Versión en desarrollo (no recomendada para producción)" OFF )

php_choice_exit_code=$?
if [ "$php_choice_exit_code" -eq 1 ] || [ "$php_choice_exit_code" -eq 255 ]; then # Solo if Cancel or ESC
    clear
    echo "Instalación cancelada por el usuario."
    exit 0
fi
clear # Limpiar después de que el usuario interactúe

# Cuadro de selección de programas adicionales
PROGRAMAS_SELECCIONADOS_STR=$(dialog --clear --stdout \
                                     --backtitle "Instalador LAMP Laravel 12 - Versión $VERSION" \
                                     --title "Selección de Programas Adicionales" \
                                     --checklist "Selecciona uno o más programas para instalar (opcional):" 18 60 3 \
                                     "vscode" "Visual Studio Code" OFF \
                                     "brave" "Brave Browser" OFF \
                                     "chrome" "Google Chrome" OFF )

programs_choice_exit_code=$?
if [ "$programs_choice_exit_code" -ne 0 ]; then
    # No es un error crítico si el usuario cancela la selección de programas adicionales
    echo "Selección de programas adicionales cancelada o vacía. Continuando con la instalación principal."
    PROGRAMAS_SELECCIONADOS=() # Asegurar que el array esté vacío si se cancela
else
    # Convertir la cadena de programas seleccionados en un array
    IFS=' ' read -r -a PROGRAMAS_SELECCIONADOS <<< "$PROGRAMAS_SELECCIONADOS_STR"
fi
clear # Limpiar después de que el usuario interactúe


# --- BARRA DE PROGRESO DE INSTALACIÓN ---
# Ejecutar toda la lógica de instalación dentro de un subshell para que dialog pueda leer su salida
(
CURRENT_PERCENT=0 # Porcentaje actual, se mantendrá como entero

# Helper function to update progress
update_progress() {
    local new_percent="$1"
    local message="$2"
    
    # Asegurarse de que el nuevo porcentaje no sea menor que el actual ni mayor que 100
    if [ "$new_percent" -gt "$CURRENT_PERCENT" ]; then
        CURRENT_PERCENT="$new_percent"
    fi
    if [ "$CURRENT_PERCENT" -gt 100 ]; then
        CURRENT_PERCENT=100
    fi

    echo "XXX"
    echo "$CURRENT_PERCENT"
    echo "$message"
    echo "XXX"
}


# 1% - Preparación del sistema: Actualizar índices de paquetes
update_progress 1 "Preparando el sistema: Actualizando índices de paquetes..."
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    apt-get update -qq > /dev/null 2>&1
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: No se pudieron actualizar los índices de paquetes."; fi
elif [ "$DISTRO" = "AlmaLinux" ]; then
    yum makecache -y -q > /dev/null 2>&1
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: No se pudieron actualizar los índices de paquetes."; fi
fi

# 2% - Preparación del sistema: Actualizando paquetes
update_progress 2 "Preparando el sistema: Actualizando paquetes..."
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq > /dev/null 2>&1
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: No se pudieron actualizar los paquetes del sistema."; fi
elif [ "$DISTRO" = "AlmaLinux" ]; then
    yum update -y -q > /dev/null 2>&1
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: No se pudieron actualizar los paquetes del sistema."; fi
fi

# 3% - Instalando utilidades esenciales: curl
update_progress 3 "Instalando: curl..."
if ! command -v curl &> /dev/null; then
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq curl > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar curl."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y -q curl > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar curl."; fi
    fi
fi

# 4% - Instalando utilidades esenciales: wget
update_progress 4 "Instalando: wget..."
if ! command -v wget &> /dev/null; then
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq wget > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar wget."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y -q wget > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar wget."; fi
    fi
fi

# 5% - Instalando utilidades esenciales: unzip
update_progress 5 "Instalando: unzip..."
if ! command -v unzip &> /dev/null; then
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq unzip > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar unzip."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y -q unzip > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar unzip."; fi
    fi
fi

# 6% - Instalando utilidades esenciales: zip
update_progress 6 "Instalando: zip..."
if ! command -v zip &> /dev/null; then
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq zip > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar zip."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y -q zip > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar zip."; fi
    fi
fi

# 7% - Instalando gpg (gnupg)
update_progress 7 "Instalando: gnupg (gpg)..."
if ! command -v gpg &> /dev/null; then
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq gnupg > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar gnupg."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        yum install -y -q gnupg > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar gnupg."; fi
    fi
fi

# 8% - Instalando apt-transport-https (solo si es Ubuntu/Debian)
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    update_progress 8 "Instalando: apt-transport-https..."
    if ! dpkg -s apt-transport-https &> /dev/null; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq apt-transport-https > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar apt-transport-https."; fi
    fi
else
    update_progress 8 "Saltando: apt-transport-https (No es Ubuntu/Debian)."
fi


# 9% - Añadiendo PPA de Ondrej para PHP (Solo Ubuntu/Debian)
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    update_progress 9 "Añadiendo repositorio PHP de Ondrej PPA..."
    if ! grep -q "ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
        # Instalar software-properties-common si no está instalado (necesario para add-apt-repository)
        if ! command -v add-apt-repository &> /dev/null; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq software-properties-common > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar software-properties-common."; fi
        fi
        if ! $INSTALL_FAILED; then
            add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al añadir Ondrej PPA."; fi
            if ! $INSTALL_FAILED; then
                apt-get update -qq > /dev/null 2>&1
                if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al actualizar índices tras añadir PPA."; fi
            fi
        fi
    fi
else
    update_progress 9 "Saltando: Ondrej PPA (No es Ubuntu/Debian)."
fi


# 10% - Instalando Apache
update_progress 10 "Instalando: Apache..."
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    if ! command -v apache2 &> /dev/null; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq apache2 > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Apache."; fi
    fi
elif [ "$DISTRO" = "AlmaLinux" ]; then
    if ! command -v httpd &> /dev/null; then
        yum install -y -q httpd > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Apache (httpd)."; fi
    fi
fi

# 11% - Habilitando mod_rewrite y reiniciando Apache
update_progress 11 "Habilitando módulo mod_rewrite y configurando Apache..."
if ! $INSTALL_FAILED; then # Solo intenta configurar si no hubo un error crítico en la instalación
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        a2enmod rewrite > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al habilitar mod_rewrite."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        # En AlmaLinux, mod_rewrite suele estar habilitado por defecto o es parte del paquete base httpd.
        # Solo verificamos si el módulo está cargado.
        if ! httpd -M 2>/dev/null | grep -q "rewrite_module"; then
            echo "Advertencia: mod_rewrite no encontrado o no habilitado. Puede requerir configuración manual."
        fi
    fi
    
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
fi

# Rango de 12% a 38% para PHP y extensiones
PHP_START_PERCENT=12
PHP_END_PERCENT=38

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

# Calcular el número total de "pasos" dentro del bloque PHP
NUM_PHP_SUB_STEPS=$(( ${#PHP_EXTENSIONS[@]}/3 )) # Solo contamos las extensiones como pasos individuales
PHP_PROGRESS_POINTS_PER_STEP=0
if [ "$NUM_PHP_SUB_STEPS" -gt 0 ]; then
    PHP_PROGRESS_POINTS_PER_STEP=$(( (PHP_END_PERCENT - PHP_START_PERCENT) / NUM_PHP_SUB_STEPS ))
fi
PHP_CURRENT_SUB_PERCENT=$PHP_START_PERCENT # Usaremos un entero para calcular los sub-pasos

# 12% - Instalando base de PHP y configurando Remi (si aplica)
# No usamos update_progress directamente para los sub-pasos de PHP para mayor granularidad.
# Incrementamos y actualizamos la barra directamente.
PHP_CURRENT_SUB_PERCENT=$(( PHP_CURRENT_SUB_PERCENT + (PHP_PROGRESS_POINTS_PER_STEP / 2) )) # Dar un poco de peso a la base
if [ "$PHP_CURRENT_SUB_PERCENT" -gt "$PHP_END_PERCENT" ]; then PHP_CURRENT_SUB_PERCENT="$PHP_END_PERCENT"; fi

echo "XXX"
echo "$PHP_CURRENT_SUB_PERCENT"
echo "Instalando base de PHP ${PHP_VERSION} y sus componentes esenciales..."
if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    if ! dpkg -s "php${PHP_VERSION}-cli" &> /dev/null; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "php${PHP_VERSION}" > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar la base de PHP ${PHP_VERSION}."; fi
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
    # Instalar php-cli y php-fpm si no están presentes (ya que son la "base")
    if ! rpm -q "php-cli" &> /dev/null || ! rpm -q "php-fpm" &> /dev/null; then
        yum install -y -q php php-cli php-fpm > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar la base de PHP ${PHP_VERSION} en AlmaLinux."; fi
    fi
fi
echo "XXX"


# Instalar cada extensión definida
for (( i=0; i<${#PHP_EXTENSIONS[@]}; i+=3 )); do
    EXT_NAME="${PHP_EXTENSIONS[i]}"
    UBUNTU_PKG="${PHP_EXTENSIONS[i+1]}"
    ALMALINUX_PKG="${PHP_EXTENSIONS[i+2]}"

    # Incrementar el porcentaje para esta extensión
    PHP_CURRENT_SUB_PERCENT=$(( PHP_CURRENT_SUB_PERCENT + PHP_PROGRESS_POINTS_PER_STEP ))
    if [ "$PHP_CURRENT_SUB_PERCENT" -gt "$PHP_END_PERCENT" ]; then PHP_CURRENT_SUB_PERCENT="$PHP_END_PERCENT"; fi
    
    echo "XXX"
    echo "$PHP_CURRENT_SUB_PERCENT"
    
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        if ! dpkg -s "$UBUNTU_PKG" &> /dev/null; then
            echo "Instalando PHP extensión: $EXT_NAME ($UBUNTU_PKG)..."
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$UBUNTU_PKG" > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar $UBUNTU_PKG."; fi
        fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        if ! rpm -q "$ALMALINUX_PKG" &> /dev/null; then
            echo "Instalando PHP extensión: $EXT_NAME ($ALMALINUX_PKG)..."
            yum install -y -q "$ALMALINUX_PKG" > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar $ALMALINUX_PKG."; fi
        fi
    fi
    echo "XXX"
done

# Asegurarse de que el porcentaje final de PHP sea 38%
update_progress 38 "Configuración final de PHP y reinicio de Apache..."
if ! $INSTALL_FAILED; then
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        # Deshabilitar versiones de PHP-FPM que no sean la seleccionada (si existen múltiples)
        INSTALLED_PHP_FPM_VERSIONS=$(dpkg -l | grep -oP 'php\d\.\d-fpm' | sed 's/php//;s/-fpm//' | sort -rV)
        for version in $INSTALLED_PHP_FPM_VERSIONS; do
            if [ "$version" != "$PHP_VERSION" ]; then
                a2dismod "php${version}" > /dev/null 2>&1
                systemctl stop "php${version}-fpm" > /dev/null 2>&1
                systemctl disable "php${version}-fpm" > /dev/null 2>&1
            fi
        done
        a2enmod "php${PHP_VERSION}" > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al habilitar el módulo PHP ${PHP_VERSION} en Apache."; fi
        systemctl restart apache2 > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al reiniciar Apache."; fi
        systemctl enable "php${PHP_VERSION}-fpm" > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al habilitar php${PHP_VERSION}-fpm."; fi
        systemctl restart "php${PHP_VERSION}-fpm" > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al reiniciar php${PHP_VERSION}-fpm."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        systemctl restart httpd > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al reiniciar httpd."; fi
        systemctl enable php-fpm > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al habilitar php-fpm."; fi
        systemctl restart php-fpm > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al reiniciar php-fpm."; fi
    fi
fi

# 45% - Instalando y configurando la base de datos (MariaDB o MySQL)
update_progress 45 "Instalando y configurando: $DBASE..."
DB_INSTALLED_FLAG=false # Nueva bandera para saber si la DB ya estaba instalada
if [ "$DBASE" = "MariaDB" ]; then
    if ! dpkg -s mariadb-server &> /dev/null; then
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq mariadb-server mariadb-client > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar MariaDB."; fi
    else
        DB_INSTALLED_FLAG=true
    fi
elif [ "$DBASE" = "MySQL" ]; then
    if ! rpm -q mysql-server &> /dev/null; then
        yum install -y -q mysql-server > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar MySQL."; fi
    else
        DB_INSTALLED_FLAG=true
    fi
fi

if ! $INSTALL_FAILED; then # Procede solo si la instalación de la DB base no falló
    if ! $DB_INSTALLED_FLAG; then # Si la DB no estaba instalada, la iniciamos y configuramos
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

        if ! $INSTALL_FAILED; then
            echo "Configurando contraseñas de $DBASE y plugin de autenticación para root y phpmyadmin..."
            # Esperar un momento si el servicio acaba de iniciar
            sleep 5 
            if [ "$DBASE" = "MariaDB" ]; then
                mysql -u root <<EOF_SQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '$PASSROOT';
UPDATE mysql.user SET plugin='mysql_native_password' WHERE User='root' AND Host='localhost';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED BY '$PASSPHP';
GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF_SQL
                if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al configurar MariaDB con contraseñas y plugin."; fi
            elif [ "$DBASE" = "MySQL" ]; then
                mysql -u root <<EOF_SQL
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$PASSROOT';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
CREATE USER 'phpmyadmin'@'localhost' IDENTIFIED BY '$PASSPHP';
GRANT ALL PRIVILEGES ON *.* TO 'phpmyadmin'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF_SQL
                if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al configurar MySQL con contraseñas y plugin."; fi
            fi
        fi
    else
        echo "$DBASE ya instalado. Asumiendo configuración previa o saltando configuración inicial de usuario."
    fi
fi


# 50% - Instalando phpMyAdmin...
update_progress 50 "Instalando: phpMyAdmin..."
if ! $INSTALL_FAILED; then
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        if ! dpkg -s phpmyadmin &> /dev/null; then
            # Pre-seed debconf selections for phpMyAdmin for unattended installation
            echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/app-password-confirm password $PASSPHP" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSROOT" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/mysql/app-pass password $PASSPHP" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
            
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq phpmyadmin > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar phpMyAdmin."; fi
        else
            # Si ya está instalado, reconfiguramos para asegurarnos de que la contraseña sea la deseada.
            echo "phpMyAdmin ya está instalado. Reconfigurando para asegurar las credenciales..."
            echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/app-password-confirm password $PASSPHP" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/mysql/admin-pass password $PASSROOT" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/mysql/app-pass password $PASSPHP" | debconf-set-selections
            echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | debconf-set-selections
            dpkg-reconfigure -f noninteractive phpmyadmin > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al reconfigurar phpMyAdmin."; fi
        fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        if ! rpm -q phpmyadmin &> /dev/null; then
            yum install -y -q phpmyadmin > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar phpMyAdmin."; fi

            if ! grep -q "Include /etc/httpd/conf.d/phpMyAdmin.conf" /etc/httpd/conf/httpd.conf; then
                echo "Creando archivo de configuración de phpMyAdmin para Apache en AlmaLinux..."
                echo "Alias /phpmyadmin /usr/share/phpmyadmin" > /etc/httpd/conf.d/phpMyAdmin.conf
                echo "<Directory /usr/share/phpmyadmin>" >> "/etc/httpd/conf.d/phpMyAdmin.conf"
                echo "    AddType application/x-httpd-php .php" >> "/etc/httpd/conf.d/phpMyAdmin.conf"
                echo "    DirectoryIndex index.php" >> "/etc/httpd/conf.d/phpMyAdmin.conf"
                echo "    Require all granted" >> "/etc/httpd/conf.d/phpMyAdmin.conf"
                echo "</Directory>" >> "/etc/httpd/conf.d/phpMyAdmin.conf"
                
                systemctl restart httpd > /dev/null 2>&1
                if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al reiniciar Apache después de configurar phpMyAdmin."; fi
            fi
        fi
    fi
fi


# 55% - Instalando Composer...
update_progress 55 "Instalando: Composer..."
if ! command -v composer &> /dev/null; then
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al descargar el instalador de Composer."; fi
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer > /dev/null 2>&1
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Composer."; fi
    rm -f composer-setup.php > /dev/null 2>&1 # Usar -f para evitar error si no existe por alguna razón
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al eliminar el instalador de Composer."; fi
fi

# 60% - Instalando Node.js...
update_progress 60 "Instalando: Node.js (v20.x)..."
if ! command -v node &> /dev/null; then
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        # Check if nodesource repo is already added to prevent adding it multiple times
        if ! grep -q "nodesource.com/setup_20.x" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
            curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al añadir el repositorio de NodeSource."; fi
        fi
        if ! $INSTALL_FAILED; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nodejs > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Node.js."; fi
        fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        # Check if nodesource repo is already added
        if ! yum repolist | grep -q "nodesource"; then
            curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al añadir el repositorio de NodeSource."; fi
        fi
        if ! $INSTALL_FAILED; then
            yum install -y -q nodejs > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Node.js."; fi
        fi
    fi
fi

# 70% - Creando la carpeta de proyectos Laravel y el proyecto en sí...
update_progress 70 "Creando estructura de directorios y proyecto Laravel..."

LARAVEL_PROJECTS_DIR="/var/www/laravel"
PROJECT_PATH="${LARAVEL_PROJECTS_DIR}/${PROYECTO}"
APACHE_USER=""

if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
    APACHE_USER="www-data"
elif [ "$DISTRO" = "AlmaLinux" ]; then
    APACHE_USER="apache"
fi

if [ ! -d "$LARAVEL_PROJECTS_DIR" ]; then
    mkdir -p "$LARAVEL_PROJECTS_DIR" > /dev/null 2>&1
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al crear el directorio $LARAVEL_PROJECTS_DIR."; fi
fi

if ! $INSTALL_FAILED; then
    if [ ! -d "$PROJECT_PATH" ]; then
        echo "Creando proyecto Laravel: $PROYECTO en $PROJECT_PATH (esto puede tardar unos minutos)..."
        if [ -n "$APACHE_USER" ]; then
            # Composer create-project runs as the current user, then sets permissions.
            # We need it to run as apache user for correct ownership from the start.
            if ! command -v sudo > /dev/null; then
                echo "ERROR: 'sudo' no está instalado. Necesario para ejecutar composer como $APACHE_USER."
                INSTALL_FAILED=true
            else
                sudo -u "$APACHE_USER" composer create-project laravel/laravel "$PROJECT_PATH" > /dev/null 2>&1
                if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al crear el proyecto Laravel. Revisa si Composer y PHP están bien configurados."; fi
            fi
        else
            INSTALL_FAILED=true; echo "ERROR: Usuario de Apache no definido para la distribución. No se puede crear el proyecto Laravel.";
        fi

        if ! $INSTALL_FAILED; then
            echo "Estableciendo permisos adecuados para el proyecto Laravel..."
            # Asegurar que el propietario es el usuario de Apache
            chown -R "$APACHE_USER":"$APACHE_USER" "$PROJECT_PATH" > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al establecer propietario del proyecto Laravel."; fi
            
            # Permisos de directorios y archivos
            chmod -R 755 "$PROJECT_PATH" > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al establecer permisos base de Laravel."; fi
            
            # Permisos de escritura específicos para storage y bootstrap/cache
            # Asegúrate de que el grupo tenga permisos de escritura (g+w)
            chmod -R 775 "${PROJECT_PATH}/storage" "${PROJECT_PATH}/bootstrap/cache" > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al establecer permisos de escritura para storage/cache."; fi

            echo "Ejecutando 'npm install' en el proyecto Laravel (esto puede tardar)..."
            (cd "$PROJECT_PATH" && sudo -u "$APACHE_USER" npm install > /dev/null 2>&1)
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al ejecutar 'npm install' en el proyecto Laravel. Revisa si Node.js y NPM están bien instalados."; fi

            if ! $INSTALL_FAILED; then
                echo "Ejecutando 'npm run build' en el proyecto Laravel..."
                (cd "$PROJECT_PATH" && sudo -u "$APACHE_USER" npm run build > /dev/null 2>&1)
                if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al ejecutar 'npm run build' en el proyecto Laravel."; fi
            fi
        fi
    else
        echo "El proyecto Laravel '$PROYECTO' ya existe en $PROJECT_PATH. Saltando creación."
    fi
fi

# 80% - Configurando base de datos y ejecutando migraciones para Laravel
update_progress 80 "Configurando base de datos y ejecutando migraciones para Laravel..."
if ! $INSTALL_FAILED; then
    echo "Creando base de datos '${PROYECTO}' y configurando .env..."
    # Usar -A para no leer el archivo .my.cnf del usuario root, forzando la contraseña
    mysql -u root -p"$PASSROOT" -e "CREATE DATABASE IF NOT EXISTS \`${PROYECTO}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" > /dev/null 2>&1
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al crear la base de datos '${PROYECTO}'. Asegúrate de que $DBASE esté corriendo y la contraseña root sea correcta."; fi

    if ! $INSTALL_FAILED; then
        ENV_FILE="${PROJECT_PATH}/.env"
        if [ ! -f "$ENV_FILE" ]; then
            echo "Advertencia: .env no encontrado en $PROJECT_PATH. Creando desde .env.example."
            cp "${PROJECT_PATH}/.env.example" "$ENV_FILE" > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al copiar .env.example a .env."; fi
        fi
        
        if ! $INSTALL_FAILED; then
            # Temporalmente dar permisos de escritura para sed
            chmod 664 "$ENV_FILE" > /dev/null 2>&1
            
            sed -i "s/^DB_DATABASE=.*/DB_DATABASE=${PROYECTO}/" "$ENV_FILE"
            sed -i "s/^DB_USERNAME=.*/DB_USERNAME=root/" "$ENV_FILE"
            sed -i "s/^DB_PASSWORD=.*/DB_PASSWORD=${PASSROOT}/" "$ENV_FILE"
            
            # Restaurar permisos y propietario
            chmod 644 "$ENV_FILE" > /dev/null 2>&1
            chown "$APACHE_USER":"$APACHE_USER" "$ENV_FILE" > /dev/null 2>&1

            echo "Ejecutando migraciones de Laravel..."
            (cd "$PROJECT_PATH" && sudo -u "$APACHE_USER" php artisan migrate --force > /dev/null 2>&1)
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al ejecutar 'php artisan migrate'. Revisa las credenciales de la base de datos en .env."; fi
        fi
    fi
fi

# 85% - Configurando idioma español en Laravel
update_progress 85 "Configurando idioma español en Laravel..."
if ! $INSTALL_FAILED; then
    echo "Instalando paquete de traducciones para Laravel..."
    (cd "$PROJECT_PATH" && sudo -u "$APACHE_USER" composer require laravel-lang/lang > /dev/null 2>&1)
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar el paquete laravel-lang/lang."; fi

    if ! $INSTALL_FAILED; then
        echo "Publicando archivos de traducción en español..."
        (cd "$PROJECT_PATH" && sudo -u "$APACHE_USER" php artisan lang:publish es > /dev/null 2>&1)
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al publicar las traducciones en español."; fi
    fi

    if ! $INSTALL_FAILED; then
        APP_CONFIG_FILE="${PROJECT_PATH}/config/app.php"
        if [ -f "$APP_CONFIG_FILE" ]; then
            chmod 664 "$APP_CONFIG_FILE" > /dev/null 2>&1 # Temporalmente dar permisos de escritura para sed
            sed -i "s/'locale' => 'en'/'locale' => 'es'/" "$APP_CONFIG_FILE"
            sed -i "s/'faker_locale' => 'en_US'/'faker_locale' => 'es_ES'/" "$APP_CONFIG_FILE"
            chmod 644 "$APP_CONFIG_FILE" > /dev/null 2>&1 # Restaurar permisos
            chown "$APACHE_USER":"$APACHE_USER" "$APP_CONFIG_FILE" > /dev/null 2>&1 # Restaurar propietario
            echo "Idioma español configurado correctamente en config/app.php."
        else
            INSTALL_FAILED=true; echo "ERROR: Archivo config/app.php no encontrado en $PROJECT_PATH.";
        fi
    fi
fi


# 90% - Configurando Virtual Host para Laravel...
update_progress 90 "Configurando Virtual Host para Laravel..."
if ! $INSTALL_FAILED; then
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        VIRTUAL_HOST_CONF="/etc/apache2/sites-available/${PROYECTO}.conf"
        
        # Deshabilitar y eliminar si existe una configuración antigua
        if [ -f "$VIRTUAL_HOST_CONF" ]; then
            a2dissite "${PROYECTO}.conf" > /dev/null 2>&1
            rm -f "$VIRTUAL_HOST_CONF" > /dev/null 2>&1
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

        if [ -f "$VIRTUAL_HOST_CONF" ]; then
            rm -f "$VIRTUAL_HOST_CONF" > /dev/null 2>&1
            if [ $? -ne 0 ]; then echo "Advertencia: Fallo al limpiar configuración antigua de Virtual Host."; fi
        fi

        echo "<VirtualHost *:80>" > "$VIRTUAL_HOST_CONF"
        echo "    ServerName ${PROYECTO}.test" >> "$VIRTUAL_HOST_CONF"
        echo "    DocumentRoot ${PROJECT_PATH}/public" >> "$VIRTUAL_HOST_CONF"
        echo "    <Directory ${PROJECT_PATH}/public>" >> "$VIRTUAL_HOST_CONF"
        echo "        AllowOverride All" >> "$VIRTUAL_HOST_CONF"
        echo "        Require all granted" >> "$VIRTUAL_HOST_CONF"
        echo "</Directory>" >> "$VIRTUAL_HOST_CONF"
        echo "    ErrorLog /var/log/httpd/${PROYECTO}_error.log" >> "$VIRTUAL_HOST_CONF"
        echo "    CustomLog /var/log/httpd/${PROYECTO}_access.log combined" >> "$VIRTUAL_HOST_CONF"
        echo "</VirtualHost>" >> "$VIRTUAL_HOST_CONF"

        systemctl restart httpd > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al reiniciar Apache después de configurar Virtual Host."; fi
        
        echo "Aplicando contexto SELinux para el proyecto Laravel..."
        # Se asume que semanage y restorecon están disponibles
        if command -v semanage &> /dev/null && command -v restorecon &> /dev/null; then
            semanage fcontext -a -t httpd_sys_rw_content_t "${PROJECT_PATH}/storage(/.*)?" > /dev/null 2>&1
            semanage fcontext -a -t httpd_sys_rw_content_t "${PROJECT_PATH}/bootstrap/cache(/.*)?" > /dev/null 2>&1
            restorecon -Rv "${PROJECT_PATH}" > /dev/null 2>&1
            if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al aplicar contexto SELinux. Esto podría causar problemas de permisos."; fi
        else
            echo "Advertencia: semanage o restorecon no encontrados. Puede que necesites configurar SELinux manualmente."
        fi
    fi
    
    # Añadir entrada a /etc/hosts si no existe
    if ! grep -q "${PROYECTO}.test" /etc/hosts; then
        echo "Añadiendo entrada a /etc/hosts para ${PROYECTO}.test..."
        echo "127.0.0.1    ${PROYECTO}.test" >> /etc/hosts
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al añadir entrada a /etc/hosts."; fi
    fi
fi

# 93% - Creando archivo info.php para verificación de PHP...
update_progress 93 "Creando archivo info.php para verificación de PHP..."
if [ -f "/var/www/html/info.php" ]; then
    echo "El archivo info.php ya existe. Asegurando permisos..."
else
    echo "<?php phpinfo(); ?>" > /var/www/html/info.php
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al crear /var/www/html/info.php."; fi
fi

if ! $INSTALL_FAILED; then # Solo intenta cambiar permisos si el archivo existe o se creó
    if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
        chown www-data:www-data /var/www/html/info.php > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al cambiar propietario de info.php."; fi
    elif [ "$DISTRO" = "AlmaLinux" ]; then
        chown apache:apache /var/www/html/info.php > /dev/null 2>&1
        if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al cambiar propietario de info.php."; fi
    fi
    chmod 644 /var/www/html/info.php > /dev/null 2>&1
    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al cambiar permisos de info.php."; fi
fi


# 95% - Instalando programas adicionales seleccionados...
PROGRAMS_TOTAL=${#PROGRAMAS_SELECCIONADOS[@]}
REMAINING_PERCENT=$((100 - CURRENT_PERCENT))
PROGRAM_INCREMENT=0
if [ "$PROGRAMS_TOTAL" -gt 0 ]; then
    PROGRAM_INCREMENT=$(( REMAINING_PERCENT / PROGRAMS_TOTAL ))
    if [ "$PROGRAM_INCREMENT" -eq 0 ] && [ "$PROGRAMS_TOTAL" -le "$REMAINING_PERCENT" ]; then
        PROGRAM_INCREMENT=1
    fi
fi

for PROGRAMA in "${PROGRAMAS_SELECCIONADOS[@]}"; do
    CURRENT_PERCENT=$(( CURRENT_PERCENT < 98 ? CURRENT_PERCENT + PROGRAM_INCREMENT : 98 ))
    update_progress "$CURRENT_PERCENT" "Instalando programa adicional: $PROGRAMA..."

    case "$PROGRAMA" in
        "vscode")
            if ! command -v code &> /dev/null; then
                echo "Intentando instalar Visual Studio Code..."
                if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
                    rm -f /etc/apt/sources.list.d/vscode.list > /dev/null 2>&1
                    rm -f /etc/apt/sources.list.d/vscode.sources > /dev/null 2>&1
                    rm -f /usr/share/keyrings/microsoft.gpg > /dev/null 2>&1

                    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /usr/share/keyrings/microsoft.gpg > /dev/null
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al descargar o añadir la clave GPG de Microsoft para VS Code."; continue; fi

                    VSCODE_SOURCES_FILE="/etc/apt/sources.list.d/vscode.sources"
                    {
                        echo "Types: deb"
                        echo "URIs: https://packages.microsoft.com/repos/code"
                        echo "Suites: stable"
                        echo "Components: main"
                        echo "Architectures: amd64,arm64,armhf"
                        echo "Signed-By: /usr/share/keyrings/microsoft.gpg"
                    } | tee "$VSCODE_SOURCES_FILE" > /dev/null
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al crear el archivo de repositorio de VS Code."; continue; fi

                    apt-get update -qq > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al ejecutar apt update después de añadir el repositorio de VS Code."; continue; fi

                    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq code > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Visual Studio Code. (Paquete 'code')"; fi

                elif [ "$DISTRO" = "AlmaLinux" ]; then
                    rpm --import https://packages.microsoft.com/keys/microsoft.asc > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al importar clave RPM para VS Code."; continue; fi

                    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al crear archivo de repositorio para VS Code."; continue; fi

                    yum check-update -q > /dev/null 2>&1 # No es crítico si falla
                    yum install -y -q code > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Visual Studio Code en AlmaLinux."; fi
                fi
            fi
            ;;
        "brave")
            if ! command -v brave-browser &> /dev/null; then
                echo "Intentando instalar Brave Browser..."
                if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
                    curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al descargar clave de Brave Browser."; continue; fi
                    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al configurar repositorio de Brave Browser."; continue; fi
                    apt-get update -qq > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al actualizar índices para Brave Browser."; continue; fi
                    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq brave-browser > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Brave Browser."; fi
                elif [ "$DISTRO" = "AlmaLinux" ]; then
                    rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al importar clave RPM para Brave Browser."; continue; fi
                    yum-config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/ > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al añadir repositorio para Brave Browser."; continue; fi
                    yum check-update -q > /dev/null 2>&1
                    yum install -y -q brave-browser brave-keyring > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Brave Browser."; fi
                fi
            fi
            ;;
        "chrome")
            if ! command -v google-chrome &> /dev/null; then
                echo "Intentando instalar Google Chrome..."
                if [ "$DISTRO" = "Ubuntu" ] || [ "$DISTRO" = "Debian" ]; then
                    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /usr/share/keyrings/google-chrome.gpg > /dev/null
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al descargar clave de Google Chrome."; continue; fi
                    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list > /dev/null
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al configurar repositorio de Google Chrome."; continue; fi
                    apt-get update -qq > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al actualizar índices para Google Chrome."; continue; fi
                    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq google-chrome-stable > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Google Chrome."; fi
                elif [ "$DISTRO" = "AlmaLinux" ]; then
                    curl https://dl.google.com/linux/linux_signing_key.pub | rpm --import - > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al importar clave RPM para Google Chrome."; continue; fi
                    echo -e "[google-chrome]\nname=google-chrome\nbaseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64\nenabled=1\ngpgcheck=1\ngpgkey=https://dl.google.com/linux/linux_signing_key.pub" | tee /etc/yum.repos.d/google-chrome.repo > /dev/null
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al crear archivo de repositorio para Google Chrome."; continue; fi
                    yum check-update -q > /dev/null 2>&1
                    yum install -y -q google-chrome-stable > /dev/null 2>&1
                    if [ $? -ne 0 ]; then INSTALL_FAILED=true; echo "ERROR: Fallo al instalar Google Chrome."; fi
                fi
            fi
            ;;
        *)
            echo "Programa desconocido seleccionado: $PROGRAMA. Saltando."
            ;;
    esac
    # Pausa breve para que el mensaje de la barra de progreso sea visible
    sleep 0.5
done

# 100% - Simulando finalización
update_progress 100 "Configuraciones finales completadas."

) | dialog --gauge "Iniciando instalación de LAMP y Laravel. Por favor, espera..." 10 70 0

clear

# Mensaje final al usuario
if $INSTALL_FAILED; then
    dialog --title "Instalación con Errores" --msgbox "La instalación de LAMP y Laravel ha finalizado, pero se detectaron errores en algunos pasos. Por favor, revisa la salida de la consola (o los logs si redirigiste la salida) para más detalles." 10 70
else
    # Obtener la IP local de la máquina
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    if [ -z "$LOCAL_IP" ]; then
        LOCAL_IP="TU_IP_DEL_SERVIDOR" # Fallback si no se puede obtener la IP
    fi

    MESSAGE="¡La instalación de LAMP y Laravel se ha completado con éxito!\n\n"
    MESSAGE+="Datos de tu proyecto:\n"
    MESSAGE+="-   URL del Proyecto: http://${PROYECTO}.test\n"
    MESSAGE+="-   Ubicación del Proyecto: ${PROJECT_PATH}\n"
    MESSAGE+="-   Verificación PHP: http://${LOCAL_IP}/info.php\n"
    MESSAGE+="-   phpMyAdmin: http://${LOCAL_IP}/phpmyadmin\n\n"
    MESSAGE+="Credenciales de Base de Datos:\n"
    MESSAGE+="-   Usuario Root (${DBASE}): root\n"
    MESSAGE+="-   Contraseña Root (${DBASE}): ${PASSROOT}\n"
    MESSAGE+="-   Usuario phpMyAdmin: phpmyadmin\n"
    MESSAGE+="-   Contraseña phpMyAdmin: ${PASSPHP}\n\n"
    MESSAGE+="¡IMPORTANTE! En tu equipo local (donde usas el navegador, NO en el servidor/VM), si deseas acceder al proyecto con '${PROYECTO}.test', debes añadir la siguiente línea a tu archivo `/etc/hosts` (en Linux/macOS) o `C:\\Windows\\System32\\drivers\\etc\\hosts` (en Windows):\n"
    MESSAGE+="    ${LOCAL_IP}    ${PROYECTO}.test\n"
    MESSAGE+="Asegúrate de que 'IP_DE_TU_MAQUINA_VIRTUAL' es la dirección IP real de tu máquina virtual.\n\n"
    MESSAGE+="Presiona ENTER para finalizar."

    dialog --title "Instalación Completada con Éxito" --msgbox "$MESSAGE" 30 85 # Aumentado el tamaño del cuadro para el mensaje largo
fi

clear

exit 0
