#! /bin/bash
#cursor invisible
echo -e "\e[?25l"
temp="/tmp"
NODE_VERSION=24
progress(){
    (
    	echo ${porcentaje}
    ) | dialog --title "Dogdark" --gauge "${mensaje}" 10 70 0
    echo -e "\e[?25l"
}

mensajesino(){
    echo -e "\e[?25l"
    dialog --title "Dogdark" \
	   --yesno "${mensaje}" 0 0
	if [ ! $? -eq 0 ]; then  
	   echo -e "\e[?25h"
 	   clear
           echo "Saliendo del Instalador";
	   exit 1
	fi
}

#limpimamos la pantalla
clear
#verificamos que el sistema este en root
if [ "$(id -u)" -eq 0 ]; then
    echo " "
else
  echo "El programa debes ejecutarlo como root"
  echo "Para ingresar como root"
  echo "UBUNTU -> sudo su -"
  echo "DEBIAN -> su -"
  exit 1
fi
#verficamos si el sistema es de 64bits
is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ]; then
	#Enviamos mensaje a la pantalla
	clear
    	mensaje="El sistema solo debe ser de 64 bits"
	exit 1
fi
# validamos si es centos o almalinux, si es así no se instala
if [ -f "/etc/redhat-release" ]; then
    Centos6Check=$(cat /etc/redhat-release | grep ' 6.' | grep -iE 'centos|Red Hat')
    if [ "${Centos6Check}" ]; then
    	clear
        mensaje="No soporta centos el instalador"
        exit 1
    fi
fi
# Vemos si es ubuntu o debian
# Leer el ID de la distribución desde /etc/os-release
if [ -f "/etc/os-release" ]; then
    . /etc/os-release                             # Esto "carga" las variables del archivo en el entorno actual del script
    
    if [ "$ID" = "ubuntu" ]; then
        DISTRO="UBUNTU"
        MYSQL="mysql-server"
	VERDISTRO=$(lsb_release -sr | cut -d'.' -f1)
    elif [ "$ID" = "debian" ]; then
        DISTRO="DEBIAN"
        MYSQL="mariadb-server"
    fi
    
else 
    echo "Hay error al encontrar la distribuición, no la reconoce el programa"
    exit 1
fi


#validamos si existe la carpeta tmp
if [ ! -d "${temp}" ]; then
	#creamos la carpeta tmp
	cd /
	mkdir tmp
fi

#validamos si existe la carpeta temporal
if [ ! -d "${temp}/temporal" ]; then
	#creamos la carpeta tmp
	mkdir ${temp}/temporal
fi

carpeta_trabajo_temporal="${temp}/temporal"

#ingresamos a la carpeta temporal para trabajar
cd $carpeta_trabajo_temporal

clear
#actualizamos el sistema
echo "Update al sistema. Espere por favor"
sudo apt update -y -q >>/dev/null 2>&1
clear
echo "Upgrade al sistema. Espere por favor"
sudo apt upgrade -y -q >>/dev/null 2>&1
clear
echo "Update al sistema. Espere por favor"
sudo apt update -y -q >>/dev/null 2>&1
clear
#verificamos que el paquete dialog este instalado
dialog --version &>/dev/null
if [ ! $? -eq 0 ]; then
   apt install -y -q dialog >>/dev/null 2>&1
fi
clear
mensaje="Bienvenidos al instalador Lamp\n\nEl sistema será preparado para instalar\nun sistema Lamp y laravel 12 de forma autómatica.\n\n¿Desea Continuar?"
mensajesino

clear
nombre_proyecto=$(dialog --inputbox "Nombre del proyecto de Laravel 12:" 8 70 2>&1 >/dev/tty)
status=$?
# Verifica si el usuario presionó Cancelar o Escape
if [ -z "$nombre_proyecto" ] || [ $status -ne 0 ]; then
    dialog --msgbox "Operación cancelada." 5 30
    clear
    exit 1
fi
     
clear
passmyadmin=$(dialog --title "Dogdark" --stdout --inputbox "Password para phpmyadmin ${MYSQL}:" 10 50 )
status=$?
if [ -z "$passmyadmin" ] || [ $status -ne 0 ]; then
    dialog --msgbox "Operación cancelada." 5 30
    clear
    exit 1
fi

clear
passroot=$(dialog --title "Dogdark" --stdout --inputbox "Password para root ${MYSQL}:" 10 50 )
status=$?
if [ -z "$passroot" ] || [ $status -ne 0 ]; then
    dialog --msgbox "Operación cancelada." 5 30
    clear
    exit 1
fi
clear
#opciones para instalar software adicional
OPCIONES_SOFTWARES=(
	1 "Visual Studio" off
	2 "Sublime text" off
	3 "Brave" off
	4 "Chrome" off
)
programas=$(dialog --title "Dogdark" \
	--stdout \
       	--checklist "Selecciona el software deseado:" 0 0 4 \
       	"${OPCIONES_SOFTWARES[@]}" \
       	)
status=$?
mensaje+="Datos:\nNombre proyecto: ${nombre_pryecto}\nPassword Phpmyadmin: ${passmyadmin}\nPassword root phpmyadmin: ${passroot}\n\nSe va a instalar\nApache2\nPhp 8.4 y librerías\n${MYSQL}\nPhpmyadmin\nComposer\nNodeJs 24\nInstalador Laravel\nProyecto Nuevo"

if [ -z "$programas" ] || [ "$status" -ne 0 ]; then
    # Si 'programas' está vacío O el usuario presionó Cancelar/Escape (status no es 0)
    mensaje+="\n"
else
    # Si 'programas' NO está vacío y el usuario no canceló, significa que hay selecciones.
#eliminar las comillas dobles de salida
    programas=$(echo "$programas" | tr -d '"')

    #contamos cuantos registros existen
    cuantos_programas=$(echo "$programas" | wc -w)

    IFS=' ' read -r -a TEMP_PROGRAMAS <<< $programas

    # Itera sobre cada tag de programa seleccionado (ej. "1", "3")
    for tag_seleccionado in "${TEMP_PROGRAMAS[@]}"; do
        # Busca la descripción correspondiente para el tag seleccionado
        # Itera sobre OPCIONES_SOFTWARES en pasos de 3 (tag, descripción, estado)
        for (( i=0; i<${#OPCIONES_SOFTWARES[@]}; i+=3 )); do
            current_tag="${OPCIONES_SOFTWARES[$i]}"
            current_description="${OPCIONES_SOFTWARES[$((i+1))]}"

            if [ "$tag_seleccionado" == "$current_tag" ]; then
                mensaje+="\n$current_description" # Agrega la descripción al mensaje
                break # Encontró la coincidencia, no necesita verificar otras opciones
            fi
        done
    done
fi

mensaje+="\n¿Desea Continuar?"
mensajesino

mensaje="Preparando sistema para instalar lamp"
porcentaje=0
progress

if ! dpkg -l | grep -q "^ii curl " 2>/dev/null; then
    mensaje="Instalando Curl"
    porcentaje=2
    progress
    sudo apt install -y -q curl > /dev/null 2>&1
fi

if ! dpkg -l | grep -q "^ii unzip " 2>/dev/null; then
    mensaje="Instalando Unzip"
    porcentaje=3
    progress
    sudo apt install -y -q unzip > /dev/null 2>&1
fi

if ! dpkg -l | grep -q "^ii wget " 2>/dev/null; then
    mensaje="Instalando Wget"
    porcentaje=4
    progress
    sudo apt install -y -q wget > /dev/null 2>&1
fi

if ! dpkg -l | grep -q "^ii git " 2>/dev/null; then
    mensaje="Instalando Git"
    porcentaje=5
    progress
    sudo apt install -y -q git > /dev/null 2>&1
fi

if ! dpkg -l | grep -q "^ii sed " 2>/dev/null; then
    mensaje="Instalando Sed"
    porcentaje=6
    progress
    sudo apt install -y -q sed > /dev/null 2>&1
fi

if ! dpkg -l | grep -q "^ii debconf-utils " 2>/dev/null; then
    mensaje="Instalando Debconf-utils"
    porcentaje=7
    progress
    sudo apt install -y -q debconf-utils > /dev/null 2>&1
fi

clear

#Validamos si existen las app agregadas
if [ "${DISTRO}" = "UBUNTU" ]; then
    # Si NO está el PPA de Ondřej, lo añadimos e instalamos
    if ! grep -q "^deb .*ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null && \
       ! sudo apt-add-repository --list | grep -q "ondrej/php" 2>/dev/null; then
        # Ejecución completamente silenciosa para Ubuntu
        mensaje="Actualizando sistema"
        porcentaje=8
        progress
        sudo apt update -y -q > /dev/null 2>&1
        mensaje="Agregando certificados"
        porcentaje=9
        progress
        sudo apt install -y -q apt-transport-https ca-certificates curl gnupg software-properties-common > /dev/null 2>&1
        mensaje="Agregando repositorio Ondrej"
        porcentaje=10
        progress
        sudo add-apt-repository ppa:ondrej/php -y -q > /dev/null 2>&1
    fi
elif [ "${DISTRO}" = "DEBIAN" ]; then
    # Si NO está el repositorio directo de Ondřej, lo añadimos e instalamos
    if ! grep -q "packages.sury.org/php" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
        # Ejecución completamente silenciosa para Debian
        mensaje="Actualizando sistema"
        porcentaje=8
        progress
        sudo apt update -y -q > /dev/null 2>&1
        mensaje="Agregando certificados"
        porcentaje=9
        progress
        sudo apt install -y -q apt-transport-https ca-certificates curl gnupg software-properties-common > /dev/null 2>&1
        mensaje="Agregando Gpg"
        porcentaje=10
        progress
        sudo curl -sSL https://packages.sury.org/php/apt.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/deb.sury.org-php.gpg >/dev/null
        mensaje="Agregando App Ondrej"
        porcentaje=11
        progress
        echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list >/dev/null
    fi
fi  
 
#NodeJs 24
NODE_REPO_PATTERN="[nodesource.com/node_$](https://nodesource.com/node_$){NODE_VERSION}.x"

if [ "${DISTRO}" = "UBUNTU" ] || [ "${DISTRO}" = "DEBIAN" ]; then
    # Verifica si el repositorio de NodeSource para la versión 24 NO está presente
    if ! grep -q "$NODE_REPO_PATTERN" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
    	mensaje="Agregando App NodeJs ${NODE_VERSION}"
        porcentaje=12
        progress
        curl -fsSL "[https://deb.nodesource.com/setup_$](https://deb.nodesource.com/setup_$){NODE_VERSION}.x" | sudo -E bash - > /dev/null 2>&1 
    fi
fi

clear
#validamos si algun software si instalara, agregaremos las app
if [ -n "$programas" ] && [ "$status" -eq 0 ]; then
    IFS=' ' read -r -a programas_array <<< "$(echo "$programas" | tr -d '"')"
    nombres_para_resumen=""
    for tag in "${programas_array[@]}"; do
        if [ -z "$nombres_para_resumen" ]; then
            nombres_para_resumen="${NOMBRES_PROGRAMAS_MAP[$tag]}"
        else
            nombres_para_resumen+=", ${NOMBRES_PROGRAMAS_MAP[$tag]}"
        fi
    done
    for tag_seleccionado in "${programas_array[@]}"; do
        case "$tag_seleccionado" in
            1)
                # Visual Studio Code
                mensaje="Agregando app Visual studio code"
                porcentaje=13
                progress
                sudo apt-get install -y -q wget gpg apt-transport-https > /dev/null 2>&1 
                wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg > /dev/null 2>&1 
                sudo install -y -q -D -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft.gpg > /dev/null 2>&1 
                rm -f microsoft.gpg > /dev/null 2>&1 
                touch /etc/apt/sources.list.d/vscode.sources
                sudo echo 'Types: deb\nURIs: https://packages.microsoft.com/repos/code\nSuites: stable\nComponents: main\nArchitectures: amd64,arm64,armhf\nSigned-By: /usr/share/keyrings/microsoft.gpg' >> /etc/apt/sources.list.d/vscode.sources
                ;;
            2)
                # Sublime Text
                mensaje="Agregando app Sublime text"
                porcentaje=14
                progress
                wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo tee /etc/apt/keyrings/sublimehq-pub.asc > /dev/null 2>&1
                echo -e 'Types: deb\nURIs: https://download.sublimetext.com/\nSuites: apt/stable/\nSigned-By: /etc/apt/keyrings/sublimehq-pub.asc' | sudo tee /etc/apt/sources.list.d/sublime-text.sources > /dev/null 2>&1
                ;;
            3)
                # Brave Browser
                mensaje="Agregando app Brave"
                porcentaje=15
                progress
                sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg > /dev/null 2>&1
                sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources > /dev/null 2>&1
                ;;
            4)
                # Google Chrome
                mensaje="Google Chrome sin app"
                porcentaje=16
                progress
                ;;
            *)
                mensaje="Error... Software no reconocido"
                porcentaje=100
                progress
                sleep 3
                clear 
                exit 1
                ;;
        esac
    done
fi

#instalamos lamp
#instalando apache
if ! dpkg -l | grep -q "^ii  apache2 " 2>/dev/null; then
    mensaje="Instalando Apache"
    porcentaje=20
    progress
    sudo apt install -y -q apache2 > /dev/null 2>&1
fi

mensaje="Habilitando url Dinamicas Apache"
porcentaje=21
progress
sudo a2enmod rewrite > /dev/null 2>&1
sleep 1
mensaje="Reiniciamos Apache"
porcentaje=22
progress
sudo service apache2 restart
sleep 1

#instalando apache
mensaje="Instalando Php 8.4"
porcentaje=25
progress
if ! dpkg -l | grep -q "^ii  php8.4-cli " 2>/dev/null; then
    sudo apt install -y -q php8.4 > /dev/null 2>&1
    sleep 1s
    mensaje="Instalando librerías Php 8.4"
    porcentaje=30
    progress
    php8.4-{cli,xml,curl,mbstring,mysql,mysqlnd,mysqli,zip,common,opcache,phar,pdo,posix,readline,bz2,calendar,ctype,dom,exif,ffi,fileinfo,gd,gettext,iconv,mcrypt,shmop,simplexml,sockets,sysvmsg,tokenizer,xmlreader,xmlwriter,xsl,bcmath,json}
fi

#instalando apache
mensaje="Instalando ${MYSQL}"
porcentaje=40
progress
if ! dpkg -l | grep -q "^ii  ${MYSQL} " 2>/dev/null; then
    sudo apt install -y -q ${MYSQL} > /dev/null 2>&1
    mensaje="Agregamos la password a root"
    porcentaje=45
    progress
    sleep 1s
    if [ "$VERDISTRO" -ge 25 ]; then
    	#la versión principal de Ubuntu ($VERDISTRO) es 25 o posterior."
  	mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '${passroot}';" >>/dev/null 2>&1
        sudo mysql --execute="FLUSH PRIVILEGES;"
    else
    	#la versión principal de Ubuntu ($VERDISTRO) es anterior a la 25."
    	mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${passroot}';" >>/dev/null 2>&1
        sudo mysql --execute="FLUSH PRIVILEGES;"
    fi
fi
#instalamos phpmyadmin
mensaje="Instalando phpmyadmin"
porcentaje=50
progress
if ! dpkg -l | grep -q "^ii  phpmyadmin " 2>/dev/null; then
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections >>/dev/null
    echo "phpmyadmin phpmyadmin/app-password-conf password ${passmyadmin}" | sudo debconf-set-selections
    # Opcional: Solo si el instalador necesita la contraseña de root de MySQL para configurar la DB. Si ya tienes un usuario 'phpmyadmin' creado en MySQL, esto no es necesario.
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password ${passwordroot}" | sudo debconf-set-selections 
    echo "phpmyadmin phpmyadmin/mysql/app-pass password ${passmyadmin}" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections
    # Para sistemas más antiguos, asegura que se haga el setup common
    echo "phpmyadmin phpmyadmin/setup-common boolean true" | sudo debconf-set-selections
    sleep 1s
    mensaje="Actualizando el índice de paquetes"
    porcentaje=52
    progress
    sudo apt update -y -q > /dev/null 2>&1
    mensaje="Agregando phpMyAdmin"
    porcentaje=54
    progress
    sudo apt install -y -q phpmyadmin > /dev/null 2>&1

    if [ ! -f "/etc/apache2/conf-available/phpmyadmin.conf" ]; then
        mensaje="Configurando phpMyAdmin"
        porcentaje=56
        progress
        sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/conf-available/phpmyadmin.conf
    fi
    mensaje="Reiniciando Apache"
    porcentaje=58
    progress
    sleep 1s
    sudo systemctl reload apache2 > /dev/null 2>&1
fi
#instalamos composer
if ! command -v composer >/dev/null 2>&1; then
    mensaje="Instalando Composer"
    porcentaje=60
    progress
    curl -sS https://getcomposer.org/installer -o /tmp/composer-setup.php
    sudo php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer > /dev/null 2>&1
    rm /tmp/composer-setup.php 2>/dev/null
    sudo echo 'export PATH="~/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
fi
#instalamos node
if ! command -v nodejs >/dev/null 2>&1 || [[ "$(nodejs -v 2>/dev/null | sed -E 's/^v([0-9]+)\..*/\1/')" != "24" ]]; then
    mensaje="Instalando Node24"
    porcentaje=70
    progress
    sudo apt-get install -y -q nodejs > /dev/null 2>&1
fi
#instalamos los softwares adicionales
#validamos si algun software si instalara, agregaremos las app
if [ -n "$programas" ] && [ "$status" -eq 0 ]; then
    IFS=' ' read -r -a programas_array <<< "$(echo "$programas" | tr -d '"')"
    nombres_para_resumen=""
    for tag in "${programas_array[@]}"; do
        if [ -z "$nombres_para_resumen" ]; then
            nombres_para_resumen="${NOMBRES_PROGRAMAS_MAP[$tag]}"
        else
            nombres_para_resumen+=", ${NOMBRES_PROGRAMAS_MAP[$tag]}"
        fi
    done
    for tag_seleccionado in "${programas_array[@]}"; do
        case "$tag_seleccionado" in
            1)
                # Visual Studio Code
                mensaje="Instalando Visual studio code"
                porcentaje=80
                progress
                sudo apt install -y -q code > /dev/null 2>&1
                ;;
            2)
                # Sublime Text
                mensaje="Instalando Sublime text"
                porcentaje=83
                progress
                sudo apt-get install -y -q sublime-text > /dev/null 2>&1
                ;;
            3)
                # Brave Browser
                mensaje="Agregando app Brave"
                porcentaje=86
                progress
                sudo apt install -y -q brave-browser > /dev/null 2>&1
                ;;
            4)
                # Google Chrome
                mensaje="Google Chrome sin app"
                porcentaje=89
                progress
                wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb > /dev/null 2>&1
                sudo dpkg -i google-chrome-stable_current_amd64.deb > /dev/null 2>&1
                sudo apt --fix-broken install > /dev/null 2>&1
                ;;
            *)
                mensaje="Error... Software no reconocido"
                porcentaje=100
                progress
                sleep 3
                clear 
                exit 1
                ;;
        esac
    done
fi
#creamos el nuevo proyecto
mensaje="Preparando el nuevo proyecto"
porcentaje=90
progress
if [ ! -d "/var/www" ]; then
    #La carpeta /var/www NO existe.
    sudo mkdir -p /var/www > /dev/null 2>&1
fi
if [ ! -d "/var/www/laravel" ]; then
    #La carpeta /var/www NO existe.
    sudo mkdir -p /var/www/laravel > /dev/null 2>&1
fi
sudo chmod 777 -R /var/www > /dev/null 2>&1
#instalamos laravel new con composer
mensaje="Preparando el nuevo proyecto"
porcentaje=92
progress
sudo COMPOSER_ALLOW_SUPERUSER=1 composer global require laravel/installer > /dev/null 2>&1
#creamos la carpeta de los proyectos laravel

#terminamos la instalacion

mensaje="Eliminando temporales"
porcentaje=99
progress
if [ ! -d "/var/www" ]; then
    rm -R ${temp}/temporal > /dev/null 2>&1
fi
mensaje="Fin instalación"
porcentaje=100
progress
sleep 2
#cursor visible
echo -e "\e[?25h"
clear
exit 1
