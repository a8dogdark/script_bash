#! /bin/bash
clear
echo "*********************************"
echo "* Instalador de servicio lamp y *"
echo "*          laravel 11           *"
echo "*********************************"
sudo apt install curl -y
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash -

clear
echo "****************************************************"
echo "* Descargamos algunos paquetes para la instalación *"
echo "****************************************************"
sleep 2
wget https://raw.githubusercontent.com/a8dogdark/script_bash/main/laravel11/new_proyect.sh
sudo chmod +x new_proyect.sh
wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip

clear
echo "***************************"
echo "* actualizamos el sistema *"
echo "***************************"
sleep 2
sudo apt update -y
sudo apt upgrade -y
sudo apt update -y

clear
echo "**************************"
echo "* INSTALAMOS lsb-release *"
echo "**************************"
sleep 2
sudo apt install lsb-release -y

echo "******************************"
echo "* INSTALAMOS ca-certificates *"
echo "******************************"
sleep 2
sudo apt install ca-certificates -y

echo "**********************************"
echo "* INSTALAMOS apt-transport-https *"
echo "**********************************"
sleep 2
sudo apt install apt-transport-https -y

echo "******************************************"
echo "* INSTALAMOS software-properties-common *"
echo "*****************************************"
sleep 2
sudo apt install software-properties-common -y

echo "******************"
echo "* INSTALAMOS git *"
echo "******************"
sleep 2
sudo apt install git -y

echo "******************"
echo "* INSTALAMOS sed *"
echo "******************"
sleep 2
sudo apt install sed -y

echo "******************"
echo "* INSTALAMOS zip *"
echo "******************"
sleep 2
sudo apt install unzip -y

echo "**********************"
echo "* INSTALAMOS apache2 *"
echo "**********************"
sleep 2
sudo apt install apache2 -y

echo "***************************"
echo "* INSTALAMOS mysql-server *"
echo "***************************"
sleep 2
sudo apt install mysql-server -y

echo "*********************"
echo "* INSTALAMOS php8.3 *"
echo "*********************"
sleep 2
sudo apt install php8.3 -y

echo "*************************"
echo "* INSTALAMOS php8.3-cli *"
echo "************************"
sleep 2
sudo apt install php8.3-cli -y

echo "*************************"
echo "* INSTALAMOS php8.3-xml *"
echo "*************************"
sleep 2
sudo apt install php8.3-xml -y

echo "**************************"
echo "* INSTALAMOS php8.3-curl *"
echo "*************************"
sleep 2
sudo apt install php8.3-curl -y

echo "******************************"
echo "* INSTALAMOS php8.3-mbstring *"
echo "******************************"
sleep 2
sudo apt install php8.3-mbstring -y

echo "****************************"
echo "* INSTALAMOS php8.3-mysql *"
echo "***************************"
sleep 2
sudo apt install php8.3-mysql -y

echo "*************************"
echo "* INSTALAMOS php8.3-zip *"
echo "*************************"
sleep 2
sudo apt install php8.3-zip -y

echo "*********************"
echo "* INSTALAMOS NodeJs *"
echo "*********************"
sleep 2
sudo apt install nodejs -y

echo "********************"
echo "* INSTALAMOS Gdebi *"
echo "********************"
sleep 2
sudo apt install gdebi -y

echo "*********************"
echo "* INSTALAMOS obs-studio *"
echo "*********************"
sleep 2
sudo apt install obs-studio -y

echo "********************"
echo "* INSTALAMOS brave *"
echo "********************"
sleep 2
sudo apt install brave-browser -y

echo "*********************************"
echo "* INSTALAMOS Visual Studio Code *"
echo "*********************************"
sleep 2
sudo snap install code --classic

echo "*********************************"
echo "* Procesamos el servidor apache *"
echo "*********************************"
sleep 2

echo "*****************************"
echo "* Cambiamos index a apache2 *"
echo "*****************************"
sleep 2
sudo chmod 777 -R /var/www/html
sudo rm /var/www/html/index.html
sudo touch /var/www/html/index.html
sudo chmod 777 /var/www/html/index.html 
sudo echo '<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Laravel 11 By Dogdark</title></head><body><h1>Instalador de Laravel 11 By dogdark</h1></body></html>' >> /var/www/html/index.html
sudo chmod 777 -R /var/www/html

echo "**************************************"
echo "* Agregamos modulo rewrite a apache2 *"
echo "**************************************"
sleep 2
sudo a2enmod rewrite
sudo service apache2 restart

echo "******************************************"
echo "* Pasamos password vacia a root de mysql *"
echo "******************************************"
sleep 2
sudo mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';"
#echo "*********************************"
#echo "* Creamos la base de datos crud *"
#echo "*********************************"
#sleep 2
#sudo mysql --execute="create database crud;"


echo "*****************************"
echo "* DESCOMPRIMIMOS PHPMYADMIN *"
echo "*****************************"
sleep 2
sudo unzip phpMyAdmin-5.2.1-all-languages.zip -d /var/www/html
sudo rm phpMyAdmin-5.2.1-all-languages.zip
sudo mv /var/www/html/phpMyAdmin-5.2.1-all-languages /var/www/html/phpmyadmin

echo "****************************************"
echo "* Modificando configuración PhpMyAdmin *"
echo "****************************************"
sleep 2
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
sudo service apache2 restart

echo "************************"
echo "* DESCARGAMOS COMPOSER *"
echo "************************"
sleep 2

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"

sudo mv composer.phar /usr/local/bin/composer

echo "#Agregando configuración bashrc"
sleep 1
sudo echo 'export PATH="~/.config/composer/vendor/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

echo "*************************"
echo "* Instalamos Laravel 11 *"
echo "*************************"
sleep 2
composer global require laravel/installer

echo "********************************"
echo "* Clonamos el repositorio crud *"
echo "********************************"
sleep 2

git clone https://github.com/a8dogdark/crud.git
sudo cp -r crud /var/www/html/crud
sudo rm -r crud

echo "fin instalacion reinicie sistema"
exit 1
