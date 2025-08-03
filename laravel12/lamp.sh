# Detectar distribución y versión
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO_NAME="$NAME"
  DISTRO_ID="$ID"
  VERDIS="$VERSION_ID"
else
  echo "No se pudo detectar la distribución. Abortando."
  exit 1
fi

# Validar distribución y versión
if [[ "$DISTRO_NAME" == "AnduinOS" && "$VERDIS" == "1.1.7" && "$DISTRO_ID" == "ubuntu" ]]; then
  # AnduinOS 1.1.7 basado en Ubuntu, permitido
  :
elif [[ "$DISTRO_ID" == "ubuntu" ]]; then
  if [[ "$VERDIS" != "22.04" && "$VERDIS" != "24.04" ]]; then
    echo "Solo se permite Ubuntu 22.04 o 24.04. Detectado: $VERDIS"
    exit 1
  fi
elif [[ "$DISTRO_ID" == "debian" ]]; then
  if [[ "$VERDIS" != "11" && "$VERDIS" != "12" ]]; then
    echo "Solo se permite Debian 11 o 12. Detectado: $VERDIS"
    exit 1
  fi
else
  echo "Solo se permite Ubuntu, Debian o AnduinOS 1.1.7. Detectado: $DISTRO_NAME"
  exit 1
fi
