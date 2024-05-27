#! /bin/bash

# Confirmamos que el sistema sea de 64bits
# We confirm that the system is 64-bit
is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ]; then
    echo "El sistema solo debe ser de 64 bits"
    exit 1
fi

# Si es centos no instalamos
# If it is centos we do not install

if [ -f "/etc/redhat-release" ]; then
    Centos6Check=$(cat /etc/redhat-release | grep ' 6.' | grep -iE 'centos|Red Hat')
    if [ "${Centos6Check}" ]; then
        echo "No soporta centos el instalador"
        exit 1
    fi
fi
# si la versión de ubuntu es menor a 20 no instalamos
# If the Ubuntu version is less than 20, we do not install
# -gt mayor que
# -lt menor que
# -ge mayor o igual que
# -le menor o igual que
# -eq igual que
# -ne sitinto de
DEB_VERSION="/etc/issue"
DIRECTORIO=$HOME

if [[ $(grep 'Ubuntu' $DEB_VERSION) ]]; then
    DISTRIBUICION="ubuntu"
elif [[ $(grep 'Debian' $DEB_VERSION) ]]; then
    DISTRIBUICION="debian"
fi

echo $DISTRIBUICION

exit 1
versionubuntu=$(cat /etc/issue | grep Ubuntu | awk '{print $2}' | cut -f 1 -d '.')
if [ "${versionubuntu}" -lt "20" ]; then
    echo "Ubuntu ${versionubuntu} no es soportado para esta instalación, use ubuntu 20/22/24"
    exit 1
fi

