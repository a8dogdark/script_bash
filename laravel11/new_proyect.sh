#! /bin/bash

clear
echo "***********************************"
echo "* Creador de proyectos Laravel 11 *"
echo "***********************************"
echo "Ingrese el nombre del proyecto"
read titulo

echo "Creamos el proyecto ${titulo}"
sleep 1

laravel new ${titulo}

echo "movemos el proyecto a html"
sudo chmod 777 /var/www/html
sudo mv ${titulo} /var/www/html/${titulo}

#creamos el dominio local
#sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default-sample.conf
echo "creamos el nuevo archivo para apache ${titulo}.test.conf"
sleep 1
sudo touch /etc/apache2/sites-available/${titulo}.test.conf


echo "agregamos la información"
sleep 1
sudo chmod 777 /etc/apache2/sites-available/${titulo}.test.conf
sudo echo -e '<VirtualHost *:80>\n
ServerName '${titulo}'.test
ServerAlias www.'${titulo}'.test
ServerAdmin '${titulo}'@localhost\n
DocumentRoot /var/www/html/'${titulo}'/public\n
\n
ErrorLog ${APACHE_LOG_DIR}/error.log\n
CustomLog ${APACHE_LOG_DIR}/access.log combined\n
\n
<Directory /var/www/html/'${titulo}'/public>\n
Options Indexes FollowSymLinks MultiViews\n
AllowOverride All\n
Order allow,deny\n
allow from all\n
</Directory>\n
</VirtualHost>' >> /etc/apache2/sites-available/${titulo}.test.conf
sudo chmod 644 /etc/apache2/sites-available/${titulo}.test.conf

echo "agregamos el dominio ${titulo}.test a hosts"
sleep 1
sudo chmod 777 /etc/hosts
sudo echo -e '\n127.0.0.1      '${titulo}'.test' >> /etc/hosts
sudo chmod 644 /etc/hosts

echo "cambiamos los permisos a la carpeta ${titulo} para escritura"
sudo chmod 755 -R /var/www/html
sudo chmod 777 -R /var/www/html/${titulo}

sudo a2ensite ${titulo}.test.conf
sudo service apache2 restart

sed -i 's/localhost/'${titulo}'.test/' /var/www/html/${titulo}/.env

echo -e "fin creando ${titulo}\n
        abre tu navegador con la siguiente url\n
        la carpeta de trabajo es /var/www/html/${titulo}\n
        http://${titulo}.test
"
