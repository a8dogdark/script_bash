#! /bin/bash
TEMPORAL="/tmp/temporal"
VER="2.0"
DISTRIBUICION=""
VERSION=""
MYSQL=""
apago_cursor()
{
  echo -e "\e[?25l"
}
enciendo_cursor()
{
  echo -e "\e[?25h"
}
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
        DISTRIBUICION="UBUNTU"
        MYSQL="mysql-server"
        VERSION=$(awk -F= '/^VERSION_ID=/ {print $2}' /etc/os-release)
    elif [ "$ID" = "debian" ]; then
        DISTRO="DEBIAN"
        MYSQL="mariadb-server"
    fi
else 
    echo "Hay error al encontrar la distribuicion, no la reconoce el programa"
    exit 1
fi

apago_cursor
clear
printf "*************************\n"
printf "* Instalador de lamp y  *\n"
printf "* laravel 12 By Dogdark *\n"
printf "*************************\n"
sleep 1s

enciendo_cursor
clear
read -p "Nombre del proyecto: " PROYECTO_LARAVEL
if [ -z "$PROYECTO_LARAVEL" ]; then
  echo "el campo no puede venir vacio"
fi
read -p "Password para root Mysql: " PASS_ROOT
if [ -z "$PASS_ROOT" ]; then
  echo "el campo no puede venir vacio"
fi

apago_cursor

clear
printf "****************************\n"
printf "* Actualizamos el sistema  *\n"
printf "****************************\n"

sudo apt update -y
sudo apt upgrade -y

printf "*******************\n"
printf "* Instalamos Curl *\n"
printf "*******************\n"
sudo apt install -y curl

printf "********************\n"
printf "* Instalamos Unzip *\n"
printf "********************\n"
sudo apt install -y unzip

printf "*******************\n"
printf "* Instalamos Wget *\n"
printf "*******************\n"
sudo apt install -y wget

printf "******************\n"
printf "* Instalamos Git *\n"
printf "******************\n"
sudo apt install -y git

printf "******************\n"
printf "* Instalamos Sed *\n"
printf "******************\n"
sudo apt install -y sed

printf "**************************\n"
printf "* Instalamos lsb-release *\n"
printf "**************************\n"
sudo apt install -y lsb-release

printf "******************************\n"
printf "* Instalamos ca-certificates *\n"
printf "******************************\n"
sudo apt install -y ca-certificates

printf "**********************************\n"
printf "* Instalamos apt-transport-https *\n"
printf "**********************************\n"
sudo apt install -y apt-transport-https

printf "*****************************************\n"
printf "* Instalamos software-properties-common *\n"
printf "*****************************************\n"
sudo apt install -y software-properties-common

printf "*********************\n"
printf "* Instalamos Apache *\n"
printf "*********************\n"
sudo apt install -y apache2
sudo a2enmod rewrite
sudo systemctl restart apache2

printf "**********************\n"
printf "* Instalamos php 8.4 *\n"
printf "**********************\n"

sudo add-apt-repository -y ppa:ondrej/php
sudo apt update -y
sudo apt install -y php8.4

printf "********************************\n"
printf "* Instalamos librerias php 8.4 *\n"
printf "********************************\n"

sudo apt install php8.4-{cli,fpm,common,zip,mysql,curl,gd,intl,mbstring,xml,soap,bcmath,gmp,opcache,imagick,redis,pgsql,sqlite3,ldap,snmp,xsl,apcu,memcached,mongodb,ssh2,sybase,odbc,pspell,igbinary,xdebug,ds,enchant,msgpack,oauth,uploadprogress,uuid,zmq,solr,gearman} -y
sudo touch /var/www/html/info.php > /dev/null 2>&1 &
sudo sh -c "echo '<?php phpinfo(); ?>' > /var/www/html/info.php" > /dev/null 2>&1 &
sudo chmod 644 /var/www/html/info.php


printf "***********************\n"
printf "* Instalamos ${MYSQL} *\n"
printf "***********************\n"
sudo apt install -y ${MYSQL}


printf "*******************\n"
printf "* fIN INSTALACION *\n"
printf "*******************\n"
sleep 2

exit 1
