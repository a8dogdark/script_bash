#! /bin/bash
clear
echo "***********************************"
echo "* INGRESE LA PASSWORD DEL SISTEMA *"
echo "*     PARA FUNCIONES DE ROOT      *"
echo "***********************************"
sudo apt install curl -y
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list

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

