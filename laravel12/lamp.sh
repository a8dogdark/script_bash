#! /bin/bash
#cursor invisible
echo -e "\e[?25l"
temp="/tmp"
NODE_VERSION=24
#sudo apt install zenity -y

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
if [ -z "$programas" ] || [ $status -ne 0 ]; then
    dialog --msgbox "Operación cancelada." 5 30
    clear
    exit 1
fi

#eliminar las comillas dobles de salida
programas=$(echo "$programas" | tr -d '"')

#contamos cuantos registros existen
cuantos_programas=$(echo "$programas" | wc -w)

IFS=' ' read -r -a TEMP_PROGRAMAS <<< $programas

#mensaje de datos
mensaje+="Datos:\nNombre proyecto: ${nombre_pryecto}\nPassword Phpmyadmin: ${passmyadmin}\nPassword root phpmyadmin: ${passroot}\n\nSe va a instalar\nApache2\nPhp 8.4 y librerías\n${MYSQL}\nPhpmyadmin\nComposer\nNodeJs 24\nInstalador Laravel\nProyecto Nuevo"

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

mensaje+="\n¿Desea Continuar?"
mensajesino

mensaje="Preparando sistema para instalar lamp"
porcentaje=0
progress

clear
#Validamos si existen las app agregadas

#Ondrej
if [ "${DISTRO}" = "UBUNTU" ]; then
    # Si NO está el PPA de Ondřej, lo añadimos e instalamos
    if ! grep -q "ppa.launchpadcontent.net/ondrej/php" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
        # Ejecución completamente silenciosa para Ubuntu
        mensaje="Actualizando sistema"
	porcentaje=1
	progress
        sudo apt update > /dev/null 2>&1
        mensaje="Agregando certificados"
	porcentaje=2
	progress
        sudo apt install -y apt-transport-https ca-certificates curl gnupg software-properties-common > /dev/null 2>&1
        mensaje="Agregando repositorio Ondrej"
	porcentaje=3
	progress
        sudo add-apt-repository ppa:ondrej/php -y > /dev/null 2>&1
    fi
elif [ "${DISTRO}" = "DEBIAN" ]; then
    # Si NO está el repositorio directo de Ondřej, lo añadimos e instalamos
    if ! grep -q "packages.sury.org/php" /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null; then
        # Ejecución completamente silenciosa para Debian
        mensaje="Actualizando sistema"
	porcentaje=1
	progress
        sudo apt update > /dev/null 2>&1
        mensaje="Agregando certificados"
	porcentaje=2
	progress
        sudo apt install -y apt-transport-https ca-certificates curl gnupg software-properties-common > /dev/null 2>&1
        mensaje="Agregando Gpg"
	porcentaje=3
	progress
        sudo curl -sSL https://packages.sury.org/php/apt.gpg | gpg --dearmor | sudo tee /usr/share/keyrings/deb.sury.org-php.gpg >/dev/null
        mensaje="Agregando App Ondrej"
	porcentaje=4
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
	porcentaje=6
	progress
        curl -fsSL "[https://deb.nodesource.com/setup_$](https://deb.nodesource.com/setup_$){NODE_VERSION}.x" | sudo -E bash - > /dev/null 2>&1 
    fi
fi
  
mensaje="Agregando App NodeJs ${NODE_VERSION}"
porcentaje=8
progress
sudo apt update > /dev/null 2>&1
sleep 2s

mensaje="agregando app"
porcentaje=2
progress

sleep 2s

#cursor visible
echo -e "\e[?25h"
clear
exit 1







