#! /bin/bash
clear
echo "***********************************"
echo "* INGRESE LA PASSWORD DEL SISTEMA *"
echo "*     PARA FUNCIONES DE ROOT      *"
echo "***********************************"
sudo apt install curl -y
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
curl -fsSL https://deb.nodesource.com/setup_21.x | sudo -E bash -

clear
echo "***************************"
echo "* actualizamos el sistema *"
echo "***************************"
sleep 2
sudo apt update -y
sudo apt upgrade -y
sudo apt update -y

clear
echo "**********************************************"
echo "* Agregamos librerías importantes al sistema *"
echo "**********************************************"
sleep 2

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

echo "*********************"
echo "* INSTALAMOS php8.3-zip *"
echo "*********************"
sleep 2
sudo apt install php8.3-zip -y


























echo "******************************"
echo "* INSTALAMOS ca-certificates *"
echo "******************************"
sleep 2
sudo apt install ca-certificates -y




echo "******************************"
echo "* INSTALAMOS ca-certificates *"
echo "******************************"
sleep 2
sudo apt install ca-certificates -y
echo "******************************"
echo "* INSTALAMOS ca-certificates *"
echo "******************************"
sleep 2
sudo apt install ca-certificates -y
echo "******************************"
echo "* INSTALAMOS ca-certificates *"
echo "******************************"
sleep 2
sudo apt install ca-certificates -y
echo "******************************"
echo "* INSTALAMOS ca-certificates *"
echo "******************************"
sleep 2
sudo apt install ca-certificates -y
echo "******************************"
echo "* INSTALAMOS ca-certificates *"
echo "******************************"
sleep 2
sudo apt install ca-certificates -y
