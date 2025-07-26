#! /bin/bash

# validaciones
# el sistema solo soporta ubuntu  derivados
# solo se permite sistema de 64 bits
#varables del sistema
mensaje=""
name=""
temp="/tmp"
#funciones del sistema
actualizar(){
	#actualizamos el sistema en segundo plano
    	apt update -y -q >> /dev/null 2>&1
    	apt upgrade -y -q >> /dev/null 2>&1
}
mensaje_dialog(){
	dialog --title "Dogdark" \
	--msgbox "${mensaje}" 0 0
}
mensaje_yesno(){
	dialog --title "Dogdark" \
	--yesno "${mensaje}" 0 0
	if [ $? -eq 0 ]; then
		clear
	else
		clear
		mensaje="Saliendo del Instalador"
		mensaje_dialog
		clear
		exit 1
	fi
}
input_dialog()
{
    INPUT_VALOR=$(dialog --title "Dogdark" \
           --stdout \
           --inputbox "${mensaje}" 10 50 )
		eval "name=\"$INPUT_VALOR\""
}
progress_dialog()
{
	(
		echo "${porcentaje}"
	) | dialog --gauge "Instalando ${mensaje}" 10 70 0
}
instalar_paquetes()
{
	#validamos si ya existe el paquete
	if ! dpkg -s ${paquete} &> /dev/null; then
		apt install -y -q ${paquete} >>/dev/null 2>&1
	else
		mensaje="${paquete} esta en su versión más reciente"
		progress_dialog
		sleep 1
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
#verificamos que el paquete dialog este instalado
dialog --version &>/dev/null
if [ $? -eq 0 ]; then
   clear
else
   actualizar
   apt install -y -q dialog >>/dev/null 2>&1
fi
#verficamos si el sistema es de 64bits
is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ]; then
	#Enviamos mensaje a la pantalla
    	mensaje="El sistema solo debe ser de 64 bits"
	mensaje_dialog
	exit 1
fi
# validamos si es centos o almalinux, si es así no se instala
if [ -f "/etc/redhat-release" ]; then
    Centos6Check=$(cat /etc/redhat-release | grep ' 6.' | grep -iE 'centos|Red Hat')
    if [ "${Centos6Check}" ]; then
        mensaje="No soporta centos el instalador"
	mensaje_dialog
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
	echo "no existe la carpeta tmp"
fi

#validamos si existe la carpeta temporal
if [ ! -d "${temp}/temporal" ]; then
	#creamos la carpeta tmp
	mkdir ${temp}/temporal
fi

carpeta_trabajo_temporal="${temp}/temporal"

#ingresamos a la carpeta temporal para trabajar
cd $carpeta_trabajo_temporal

#damos la bienvenida
mensaje="\nBienvenidos al instalador Lamp\n\nEl sistema será preparado para instalar\nun sistema Lamp y laravel 12 de forma autómatica.\nInstalará los siguientes paquetes:\nApache2\nPhp 8.4\n${MYSQL}\nPhpmyadmin\nComposer\nNodeJs 24\nInstalador Laravel\nProyecto Nuevo\n¿Desea Continuar?"
mensaje_yesno

clear
#nombre del proyecto
name="proyecto"
mensaje="Cual será el nombre de tu proyecto laravel"
input_dialog
nombre_proyecto=$name
if [ -z "$nombre_proyecto" ]; then
	nombre_proyecto="crud"
	mensaje="Por defecto se llamará ${nombre_proyecto}"
	mensaje_dialog
fi
#ingresaremos una password para el usuario de mysql y phpmyadmin
name="passphpmyadmin"
mensaje="Ingresa una contraseña para el usuario de phpmyadmin:"
input_dialog
passphpmyadmin=$name
if [ -z "$passphpmyadmin" ]; then
	passphpmyadmin="12345"
	mensaje="Por defecto será ${passphpmyadmin}"
	mensaje_dialog
fi
#ingresaremos una password para el usuario de mysql y phpmyadmin
name="passroot"
mensaje="ngresa una contraseña para el usuario root de mysql:"
input_dialog
passroot=$name
if [ -z "$passroot" ]; then
	passroot="12345"
	mensaje="Por defecto será ${passroot}"
	mensaje_dialog
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

#eliminar las comillas dobles de salida
programas=$(echo "$programas" | tr -d '"')

#contamos cuantos registros existen
cuantos_programas=$(echo "$programas" | wc -w)

IFS=' ' read -r -a TEMP_PROGRAMAS <<< $programas

#echo "total elegidos $cuantos_programas"

#id_programa=${TEMP_PROGRAMAS[0]}

#echo "el id es $id_programa"


#instalando lamp

#actualizamos el sistema
porcentaje="0"
mensaje="Actualizamos el sistema"
progress_dialog
actualizar

if [ ${DISTRO} == "UBUNTU" ]; then
	porcentaje="2"
	mensaje="Respaldamos versión de php en el sistema"
	progress_dialog
	#copiamos la version de php disponible
	dpkg -l | grep php | tee packages.txt >>/dev/null 2>&1
	sleep 1

	porcentaje="4"
	mensaje="Agregamos Dependencias para Ondrej Php"
	paquete="lsb-release ca-certificates apt-transport-https software-properties-common"
	progress_dialog
	instalar_paquetes

	porcentaje="6"
	mensaje="Agregamos Repositorio Ondrej Php"
	progress_dialog
	(
		apt install -y software-properties-common && \
		add-apt-repository -y ppa:ondrej/php && \
		apt update
	) disown

	porcentaje="8"
	mensaje="Actualizamos el sistema"
	progress_dialog
	actualizar
else
	#debian
	porcentaje="2"
	mensaje="Instalando certificados para php"
	progress_dialog
	paquete="curl apt-transport-https ca-certificates"
	instalar_paquetes

	porcentaje="4"
	mensaje="Agregando Claves GPG"
	progress_dialog
	curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/php.gpg >>/dev/null 2>&1

	porcentaje="6"
	mensaje="Agregando Repositorio Ondrej"
	progress_dialog
	echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list >>/dev/null 2>&1

	porcentaje="8"
	mensaje="Actualizando sistema"
	progress_dialog
	actualizar
fi

#instalacion de lamp
porcentaje="10"
mensaje="Instalando Paquetes adicionales"
progress_dialog
sleep 1

#instalando curl
porcentaje="12"
mensaje="Instalando Curl"
progress_dialog
paquete="curl"
instalar_paquetes

#instalando Unzip
porcentaje="14"
mensaje="Instalando Unzip"
progress_dialog
paquete="unzip"
instalar_paquetes

#instalando Wget
porcentaje="16"
mensaje="Instalando Wget"
progress_dialog
paquete="wget"
instalar_paquetes

#instalando git
porcentaje="18"
mensaje="Instalando Git"
progress_dialog
paquete="git"
instalar_paquetes

#instalando Sed
porcentaje="20"
mensaje="Instalando Sed"
progress_dialog
paquete="sed"
instalar_paquetes

#instalando Sed
porcentaje="25"
mensaje="Instalando Debconf-utils"
progress_dialog
paquete="debconf-utils"
instalar_paquetes

#instalando Apache
porcentaje="30"
mensaje="Instalando Apache"
progress_dialog
paquete="apache2"
instalar_paquetes

#instalando Apache
porcentaje="34"
mensaje="Habilitando url Dinamicas Apache"
progress_dialog
a2enmod rewrite

#instalando Apache
porcentaje="38"
mensaje="Reiniciando Apache"
progress_dialog
service apache2 restart

#instalando PHP 8.4
porcentaje="40"
mensaje="Instalando PHP 8.4"
progress_dialog
paquete="php8.4"
instalar_paquetes

#instalando PHP 8.4
porcentaje="41"
mensaje="Instalando librerías PHP 8.4 Cli"
progress_dialog
paquete="php8.4-{cli}"
instalar_paquetes

porcentaje="42"
mensaje="Instalando librerías PHP 8.4 xml"
progress_dialog
paquete="php8.4-{xml}"
instalar_paquetes

porcentaje="43"
mensaje="Instalando librerías PHP 8.4 curl"
progress_dialog
paquete="php8.4-{curl}"
instalar_paquetes

porcentaje="44"
mensaje="Instalando librerías PHP 8.4 mbstring"
progress_dialog
paquete="php8.4-{mbstring}"
instalar_paquetes

porcentaje="45"
mensaje="Instalando librerías PHP 8.4 Mysql"
progress_dialog
paquete="php8.4-{mysql}"
instalar_paquetes

porcentaje="46"
mensaje="Instalando librerías PHP 8.4 Zip"
progress_dialog
paquete="php8.4-{zip}"
instalar_paquetes

porcentaje="47"
mensaje="Instalando librerías PHP 8.4 Mysqlnd"
progress_dialog
paquete="php8.4-{mysqlnd}"
instalar_paquetes

porcentaje="48"
mensaje="Instalando librerías PHP 8.4 Opcache"
progress_dialog
paquete="php8.4-{opcache}"
instalar_paquetes

porcentaje="49"
mensaje="Instalando librerías PHP 8.4 Pdo"
progress_dialog
paquete="php8.4-{pdo}"
instalar_paquetes

porcentaje="50"
mensaje="Instalando librerías PHP 8.4 Bz2"
progress_dialog
paquete="php8.4-{bz2}"
instalar_paquetes

porcentaje="51"
mensaje="Instalando librerías PHP 8.4 Calendar"
progress_dialog
paquete="php8.4-{calendar}"
instalar_paquetes

porcentaje="52"
mensaje="Instalando librerías PHP 8.4 Ctype"
progress_dialog
paquete="php8.4-{ctype}"
instalar_paquetes

porcentaje="53"
mensaje="Instalando librerías PHP 8.4 Dom"
progress_dialog
paquete="php8.4-{dom}"
instalar_paquetes

porcentaje="54"
mensaje="Instalando librerías PHP 8.4 Exif"
progress_dialog
paquete="php8.4-{exif}"
instalar_paquetes

porcentaje="55"
mensaje="Instalando librerías PHP 8.4 Ffi"
progress_dialog
paquete="php8.4-{ffi}"
instalar_paquetes

porcentaje="56"
mensaje="Instalando librerías PHP 8.4 Fileinfo"
progress_dialog
paquete="php8.4-{fileinfo}"
instalar_paquetes

porcentaje="57"
mensaje="Instalando librerías PHP 8.4 ftp"
progress_dialog
paquete="php8.4-{ftp}"
instalar_paquetes

porcentaje="58"
mensaje="Instalando librerías PHP 8.4 Gd"
progress_dialog
paquete="php8.4-{gd}"
instalar_paquetes

porcentaje="59"
mensaje="Instalando librerías PHP 8.4 Gettext"
progress_dialog
paquete="php8.4-{gettext}"
instalar_paquetes

porcentaje="60"
mensaje="Instalando librerías PHP 8.4 Iconv"
progress_dialog
paquete="php8.4-{iconv}"
instalar_paquetes

porcentaje="61"
mensaje="Instalando librerías PHP 8.4 Mcrypt"
progress_dialog
paquete="php8.4-{mcrypt}"
instalar_paquetes

porcentaje="62"
mensaje="Instalando librerías PHP 8.4 Mysqli"
progress_dialog
paquete="php8.4-{mysqli}"
instalar_paquetes

porcentaje="63"
mensaje="Instalando librerías PHP 8.4 Phar"
progress_dialog
paquete="php8.4-{phar}"
instalar_paquetes

porcentaje="64"
mensaje="Instalando librerías PHP 8.4 Posix"
progress_dialog
paquete="php8.4-{posix}"
instalar_paquetes

porcentaje="65"
mensaje="Instalando librerías PHP 8.4 Readline"
progress_dialog
paquete="php8.4-{readline}"
instalar_paquetes

porcentaje="66"
mensaje="Instalando librerías PHP 8.4 Shmop"
progress_dialog
paquete="php8.4-{shmop}"
instalar_paquetes

porcentaje="67"
mensaje="Instalando librerías PHP 8.4 Simplexml"
progress_dialog
paquete="php8.4-{simplexml}"
instalar_paquetes

porcentaje="68"
mensaje="Instalando librerías PHP 8.4 Sockets"
progress_dialog
paquete="php8.4-{sockets}"
instalar_paquetes

porcentaje="69"
mensaje="Instalando librerías PHP 8.4 Sysvmsg"
progress_dialog
paquete="php8.4-{sysvmsg}"
instalar_paquetes

porcentaje="70"
mensaje="Instalando librerías PHP 8.4 Tokenizer"
progress_dialog
paquete="php8.4-{tokenizer}"
instalar_paquetes

porcentaje="71"
mensaje="Instalando librerías PHP 8.4 Xmlreader"
progress_dialog
paquete="php8.4-{xmlreader}"
instalar_paquetes

porcentaje="72"
mensaje="Instalando librerías PHP 8.4 Xmlwriter"
progress_dialog
paquete="php8.4-{xmlwriter}"
instalar_paquetes

porcentaje="73"
mensaje="Instalando librerías PHP 8.4 Xsl"
progress_dialog
paquete="php8.4-{xsl}"
instalar_paquetes

porcentaje="74"
mensaje="Instalando librerías PHP 8.4 Bcmath"
progress_dialog
paquete="php8.4-{bcmath}"
instalar_paquetes

porcentaje="75"
mensaje="Instalando librerías PHP 8.4 Json"
progress_dialog
paquete="php8.4-{json}"
instalar_paquetes

#instalando Mysql
porcentaje="80"
mensaje="Instalando ${MYSQL}"
progress_dialog
paquete="${MYSQL}"
instalar_paquetes

porcentaje="80"
mensaje="Agregando la password a Root de mysql "
progress_dialog
mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${passroot}';" >>/dev/null 2>&1

#instalando phpmyadmin
porcentaje="90"
mensaje="Instalando Phpmyadmin"
progress_dialog
(
    # Preconfigurar las respuestas para phpMyAdmin
    # Reemplaza 'TU_CONTRASEÑA_PHPMYADMIN' con una contraseña segura para el usuario 'phpmyadmin'
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/app-password-confirm password ${passphpmyadmin}" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/app-pass password ${passphpmyadmin}" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password ${passroot}" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2" | sudo debconf-set-selections

    # Instalar phpMyAdmin y las extensiones PHP necesarias
	apt install -y -q phpmyadmin
    systemctl reload apache2
) disown

#instalando composer
porcentaje="82"
mensaje="Instalando Composer"
progress_dialog
(
	wget -q -O composer.phar https://getcomposer.org/composer.phar && mv composer.phar /usr/local/bin/composer &
	echo 'export PATH="~/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc 
	source ~/.bashrc
) disown

#instalando Node Js
porcentaje="84"
mensaje="Instalando Node Js"
progress_dialog
(
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
	apt install -y -q nodejs
) disown

porcentaje="100"
mensaje="Fin instalacion"
progress_dialog
sleep 3

mensaje="Sistema instalado con exito"
mensaje_dialog

rm -R /tmp/temporal

exit 1
