#! /bin/bash

# validaciones
# el sistema solo soporta ubuntu  derivados
# solo se permite sistema de 64 bits
clear
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
    elif [ "$ID" = "debian" ]; then
        DISTRO="DEBIAN"
    fi
else 
    echo "Hay error al encontrar la distribuición, no la reconoce el programa"
    exit 1
fi

dialog --version &>/dev/null
if [ $? -eq 0 ]; then
   clear
else
   apt update -y -q >>/dev/null
   apt upgrade -y -q >>/dev/null
   apt install -y -q dialog >>/dev/null
fi

dialog --title "LAMP" \
        --text="Bienvenidos al instalador de lamp local"

# Captura la versión de Ubuntu en la variable 'ubuntu_version'
#ubuntu_version=$(lsb_release -rs)

# Muestra el contenido de la variable para verificar
#echo "La versión de Ubuntu es: $ubuntu_version"



