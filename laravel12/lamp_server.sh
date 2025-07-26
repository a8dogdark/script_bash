#! /bin/bash

# validaciones
# el sistema solo soporta ubuntu  derivados
# solo se permite sistema de 64 bits
#varables del sistema
mensaje=""
name=""
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
	apt install -y -q ${paquete} >>/dev/null 2>&1
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

#damos la bienvenida
mensaje="\nBienvenidos al instalador Lamp\n\nEl sistema será preparado para instalar\nun sistema Lamp y laravel 12 de forma autómatica.\nInstalará los siguientes paquetes:\nApache2\nPhp 8.3\n${MYSQL}\nPhpmyadmin\nComposer\nNodeJs 24\nInstalador Laravel\nProyecto Nuevo\n¿Desea Continuar?"
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
	paquete="apt-transport-https ca-certificates"
	progress_dialog
	instalar_paquetes

	porcentaje="6"
	mensaje="Agregamos Repositorio Ondrej Php"
	progress_dialog
	add-apt-repository ppa:ondrej/php

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









































#agregamos la libreria de ondrej para php 8.3



porcentaje="2"
mensaje="Instalando Apache"
paquete="apache2"
progress_dialog

sleep 5
porcentaje="5"
mensaje="Instalando phpmyadmin"
progress_dialog
sleep 5
clear
exit 1
