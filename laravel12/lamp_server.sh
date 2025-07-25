#! /bin/bash

// validaciones

//el sistema solo soporta ubuntu  derivados

//solo se permite sistema de 64 bits
is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ]; then
    echo "El sistema solo debe ser de 64 bits"
    exit 1
fi

//validamos si es centos o almalinux, si es así no se instala
if [ -f "/etc/redhat-release" ]; then
    Centos6Check=$(cat /etc/redhat-release | grep ' 6.' | grep -iE 'centos|Red Hat')
    if [ "${Centos6Check}" ]; then
        echo "No soporta centos el instalador"
        exit 1
    fi
fi

//verificamos que el usuario sea root
if [ "$(id -u)" -eq 0 ]; then
  echo "exito estas como root"
  exit 1
else
  echo "El programa debes ejecutarlo como root"
  echo "Para ingresar como root"
  echo "UBUNTU -> sudo su -"
  echo "DEBIAN -> su -"
  exit 1
fi
