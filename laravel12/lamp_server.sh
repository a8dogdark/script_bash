#! /bin/bash

# validaciones
# el sistema solo soporta ubuntu  derivados
# solo se permite sistema de 64 bits
clear

actualizar(){
    apt update -y -q >> /dev/null 2>&1
    apt upgrade -y -q >> /dev/null 2>&1
}

is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ]; then
    echo "El sistema solo debe ser de 64 bits"
    exit 1
fi
# validamos si es centos o almalinux, si es así no se instala
if [ -f "/etc/redhat-release" ]; then
    Centos6Check=$(cat /etc/redhat-release | grep ' 6.' | grep -iE 'centos|Red Hat')
    if [ "${Centos6Check}" ]; then
        echo "No soporta centos el instalador"
        exit 1
    fi
fi
# verificamos que el usuario sea root
if [ "$(id -u)" -eq 0 ]; then
    echo "Comenzamos con la instalación"
else
  echo "El programa debes ejecutarlo como root"
  echo "Para ingresar como root"
  echo "UBUNTU -> sudo su -"
  echo "DEBIAN -> su -"
  exit 1
fi

# Vemos si es ubuntu o debian
# Leer el ID de la distribución desde /etc/os-release
if [ -f "/etc/os-release" ]; then
    . /etc/os-release                             # Esto "carga" las variables del archivo en el entorno actual del script
    
    if [ "$ID" = "ubuntu" ]; then
        DISTRO="UBUNTU"
        MYSQL=mysql-server
    elif [ "$ID" = "debian" ]; then
        DISTRO="DEBIAN"
        MYSQL="mariadb-server"
    fi
else 
    echo "Hay error al encontrar la distribuición, no la reconoce el programa"
    exit 1
fi

actualizar

dialog --version &>/dev/null
if [ $? -eq 0 ]; then
   clear
else
   actualizar
   apt install -y -q dialog >>/dev/null 2>&1
fi

dialog --title "Dogdark" \
        --msgbox "\nBienvenidos al instalador Lamp\n\nEl sistema será preparado para instalar\nun sistema Lamp y laravel 12 de forma autómatica.\nInstalará los siguientes paquetes:\nApache2\nPhp 8.3\n${MYSQL}\nPhpmyadmin\nComposer\nNodeJS 24\nInstalador Laravel\nProyecto Nuevo" 0 0

dialog --title "Dogdark" \
       --yesno "¿Desea Continuar?" 10 30
if [ $? -eq 0 ]; then
   clear
else
   clear
   echo "Salimos del instalador"
   echo "Bye"
   exit 1
fi

proyecto=$(dialog --title "Dogdark" \
           --stdout \
           --inputbox "Cual será el nombre de tu proyecto laravel" 10 50)

userphpmyadmin=$(dialog --title "Dogdark" \
           --stdout \
           --inputbox "Ingresa una contraseña para el usuario de phpmyadmin:" 10 50)

userroot=$(dialog --title "Dogdark" \
           --stdout \
           --inputbox "Ingresa una contraseña para el usuario root de mysql:" 10 50)

programas=$(dialog --title "Dogdark" \
                   --stdout \
                   --checklist "Selecciona las opción:" 0 0 5 \
                               1 Lamp_Laravel on\
                               2 Visual_studio off\
                               3 Sublime_text off
                               4 Brave off
                               5 Chrome off)




# Captura la versión de Ubuntu en la variable 'ubuntu_version'
#ubuntu_version=$(lsb_release -rs)

# Muestra el contenido de la variable para verificar
#echo "La versión de Ubuntu es: $ubuntu_version"



