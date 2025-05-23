#! /bin/bash

actualizar(){
    sudo apt update -y
    sudo apt upgrade -y
    sudo apt update -y
}

reiniciar_apache(){
  sudo service apache2 restart
}

is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ]; then
    echo "El sistema solo debe ser de 64 bits"
    exit 1
fi

if [ -f "/etc/redhat-release" ]; then
    Centos6Check=$(cat /etc/redhat-release | grep ' 6.' | grep -iE 'centos|Red Hat')
    if [ "${Centos6Check}" ]; then
        echo "No soporta centos el instalador"
        exit 1
    fi
fi

UbuntuCheck=$(cat /etc/issue | grep Ubuntu | awk '{print $2}' | cut -f 1 -d '.')
if [ "${UbuntuCheck}" -lt "20" ]; then
    echo "Ubuntu ${UbuntuCheck} no es soportado para esta instalación, use ubuntu 20/22/24/25"
    exit 1
fi

clear
echo "**********************************"
echo "*    INICIANDO EL INSTALADOR.    *"
echo "* VERSION DE LA DISTRO UBUNTU ${UbuntuCheck} *"
echo "* Ingrese su password de usuario *"
echo "**********************************"
echo "Agregamos librerías importantes al sistema"
sleep 1
sudo apt install curl wget unzip -y

curl -fsSL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh

echo "Instalamos node";
sleep 1
sudo -E bash nodesource_setup.sh

sudo apt-get install -y nodejs


actualizar
echo "*************************"
echo "* INSTALAMOS APACHE2    *"
echo "* INSTALAMOS PHP 8.3    *"
echo "* INSTALAMOS MYSQL      *"
echo "* INSTALAMOS PHPMYADMIN *"
echo "*************************"
sleep 2

sudo apt install curl unzip wget gpg lsb-release ca-certificates apt-transport-https software-properties-common git sed apache2 mysql-server php8.4 php8.4-{cli,xml,curl,mbstring,mysql,zip,mysqlnd,opcache,pdo,xml,bz2,calendar,ctype,curl,dom,exif,ffi,fileinfo,ftp,gd,gettext,iconv,mbstring,mcrypt,mysqli,phar,posix,readline,shmop,simplexml,sockets,sysvmsg,tokenizer,xmlreader,xmlwriter,xsl,zip,bcmath} phpmyadmin vsftpd -y

#agregamos modulo rewrite a apache2
sudo a2enmod rewrite
reiniciar_apache


echo "Pasamos password vacia a root de mysql"
sleep 1
sudo mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '12345';"

echo "Usuatio root Mysql";
echo "User->root";
echo "Password->12345;
sleep 1

echo "************************"
echo "* DESCARGAMOS COMPOSER *"
echo "************************"
sleep 1

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'.PHP_EOL; } else { echo 'Installer corrupt'.PHP_EOL; unlink('composer-setup.php'); exit(1); }"
php composer-setup.php
php -r "unlink('composer-setup.php');"

sudo mv composer.phar /usr/local/bin/composer

echo "#Agregando configuración bashrc"
sleep 1
sudo echo 'export PATH="~/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

echo "#Instalando Laravel 11"
sleep 1
composer global require laravel/installer

echo "Fin instalación";
