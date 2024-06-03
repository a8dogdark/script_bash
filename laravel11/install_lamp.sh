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
    echo "Ubuntu ${UbuntuCheck} no es soportado para esta instalación, use ubuntu 20/22/24"
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
curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash -
#si es menor a ubuntu 24 agregue la app de ondrej
if [ "${UbuntuCheck}" -lt "24" ]; then
  echo "La versión de Ubuntu es ${UbuntuCheck} agregamos la ppa de ondrej"
  sleep 1
  sudo add-apt-repository ppa:ondrej/php -y
     #si es igual a ubuntu 23 modifique el distro
     if [ "${UbuntuCheck}" -eq "23" ]; then
      echo "Ubuntu es 23 modificamos distro"
      sleep 1
      sudo sed -i 's/mantic/jammy/' /etc/apt/sources.list.d/ondrej-ubuntu-php-mantic.sources
     fi
   actualizar
fi
actualizar
echo "*************************"
echo "* INSTALAMOS APACHE2    *"
echo "* INSTALAMOS PHP 8.3    *"
echo "* INSTALAMOS MYSQL      *"
echo "* INSTALAMOS PHPMYADMIN *"
echo "*************************"
sleep 2
sudo apt install lsb-release ca-certificates apt-transport-https software-properties-common git sed apache2 mysql-server php8.3 php8.3-{cli,xml,curl,mbstring,mysql,zip} nodejs -y

echo "cambiamos index a apache2"
sleep 1
sudo chmod 777 -R /var/www/html
sudo rm /var/www/html/index.html
sudo touch /var/www/html/index.html
sudo chmod 777 /var/www/html/index.html 
sudo echo '<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Laravel 11 By Dogdark</title></head><body><h1>Instalador de Laravel 11 By dogdark</h1></body></html>' >> /var/www/html/index.html
sudo chmod 777 -R /var/www/html

#agregamos modulo rewrite a apache2
sudo a2enmod rewrite
reiniciar_apache

echo "Pasamos password vacia a root de mysql"
sleep 1
sudo mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';"

echo "**************************"
echo "* DESCARGAMOS PHPMYADMIN *"
echo "**************************"
sleep 1

wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip
echo "*****************************"
echo "* DESCOMPRIMIMOS PHPMYADMIN *"
echo "*****************************"
sleep 1

sudo unzip phpMyAdmin-5.2.1-all-languages.zip -d /var/www/html
sudo rm phpMyAdmin-5.2.1-all-languages.zip
sudo mv /var/www/html/phpMyAdmin-5.2.1-all-languages /var/www/html/phpmyadmin

echo "****************************************"
echo "* Modificando configuración PhpMyAdmin *"
echo "****************************************"
sleep 1
sudo cp /var/www/html/phpmyadmin/config.sample.inc.php /var/www/html/phpmyadmin/config.inc.php

variable1="#cfg['blowfish_secret'] = 'oXRvsNmlVQBczroJ3m0AjIrcAf1lVjSf';"

sudo sed -i '16d' /var/www/html/phpmyadmin/config.inc.php
sudo sed -i "16i ${variable1}" /var/www/html/phpmyadmin/config.inc.php
sudo sed -i "16 s/#/$/g" /var/www/html/phpmyadmin/config.inc.php
sudo sed -i '32 s/false/true/g' /var/www/html/phpmyadmin/config.inc.php
sudo chmod 777 -R /var/www/html/phpmyadmin
sudo mkdir /var/www/html/phpmyadmin/tmp
sudo chown -R www-data:www-data /var/www/html/phpmyadmin/tmp
sudo chmod 755 -R /var/www/html
reiniciar_apache


echo "************************"
echo "* DESCARGAMOS COMPOSER *"
echo "************************"
sleep 1

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
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

#sudo rm install_lamp

echo "fin instalacion reinicie sistema"
exit 1
