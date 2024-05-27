#! /bin/bash

# Confirmamos que el sistema sea de 64bits
# We confirm that the system is 64-bit
is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ]; then
    echo "El sistema solo debe ser de 64 bits"
    exit 1
fi

