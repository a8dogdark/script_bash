#! /bin/bash
apago_cursor()
{
  echo -e "\e[?25l"
}
enciendo_cursor()
{
  echo -e "\e[?25h"
}
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
