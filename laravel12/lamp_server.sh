#! /bin/bash

// validaciones
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

if [ "$(id -u)" -eq 0 ]; then
  echo "El programa debes ejecutarlo como root"
else
  echo "El script NO se está ejecutando como root"
fi
