#! /bin/bash
temp="/tmp"
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

#verificamos que el paquete dialog este instalado
dialog --version &>/dev/null
if [ ! $? -eq 0 ]; then
   apt install -y -q dialog >>/dev/null 2>&1
fi
dialog --title "Dogdark" \
	--yesno "Bienvenidos al instalador Lamp\n\nEl sistema será preparado para instalar\nun sistema Lamp y laravel 12 de forma autómatica.\nInstalará los siguientes paquetes:\nApache2\nPhp 8.4\n${MYSQL}\nPhpmyadmin\nComposer\nNodeJs 24\nInstalador Laravel\nProyecto Nuevo\n¿Desea Continuar?" 0 0
	if [ $? -eq 0 ]; then
 	   clear
        else
	   clear
           echo "Saliendo del Instalador";
	   exit 1
	fi
proyecto=$(dialog --title "Dogdark" \
           --stdout \
           --inputbox "Nombre del Proyecto Laravel:" 10 50 )
passmyadmin=$(dialog --title "Dogdark" \
           --stdout \
           --inputbox "Password para Phpmyadmin" 10 50 )
passroot=$(dialog --title "Dogdark" \
           --stdout \
           --inputbox "Password para Root" 10 50 )
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







