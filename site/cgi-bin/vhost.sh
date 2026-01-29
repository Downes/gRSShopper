#!/bin/bash
# This script is used for create virtual hosts on CentOs.
# Created by alexnogard from http://alexnogard.com
# Improved by mattmezza from http://you.canmakethat.com
# Feel free to modify it
#   PARAMETERS
#
# $usr          - User
# $dir          - directory of web files
# $servn        - webserver address without www.
# $cname        - cname of webserver
# EXAMPLE
# Web directory = /var/www/
# ServerName    = domain.com
# cname            = devel
#
#
# Check if you execute the script as root user
#
# This will check if directory already exist then create it with path : /directory/you/choose/domain.com
# Set the ownership, permissions and create a test index.php file
# Create a vhost file domain in your /etc/httpd/conf.d/ directory.
# And add the new vhost to the hosts.
#
#
if [ "$(whoami)" != 'root' ]; then
echo "You have to execute this script as root user"
exit 1;
fi
read -p "Enter the server name your want (without www) : " servn
read -p "Enter a CNAME (e.g. :www or dev for dev.website.com) : " cname
read -p "Enter the path of directory you wanna use (e.g. : /var/www/, dont forget the /): " dir
read -p "Enter the user you wanna use (e.g. : apache) : " usr
read -p "Enter the listened IP for the server (e.g. : *): " listen

if [ -d "$dir$cname" ]; then
    echo "$dir$cname already exists! Try a different CNAME"

else
echo "Web directory created with success !"
mkdir -p $dir$cname;
mkdir -p $dir$cname/html/;
mkdir -p $dir$cname/html/cgi-bin/;
fi
echo "<h1>$cname $servn</h1>" > $dir$cname/html/index.html
chown -R $usr:$usr $dir$cname
chmod -R '755' $dir$cname
chmod -R '755' $dir$cname/html/cgi-bin/
chmod -R '555' $dir$cname/html/
mkdir /var/log/$cname

alias=$cname.$servn
if [[ "${cname}" == "" ]]; then
alias=$servn
fi

echo "#### $cname $servn
<VirtualHost $listen:80>
ServerName $alias
ServerAlias $alias
DocumentRoot $dir$cname/html/
<Directory $dir$cname>
Options Indexes FollowSymLinks MultiViews
AllowOverride All
Order allow,deny
Allow from all
Require all granted
</Directory>
</VirtualHost>" > /etc/apache2/sites-enabled/$cname.$servn.conf
if [ -e "/etc/apache2/sites-enabled/$cname.$servn.conf" ]; then
echo "Virtual host /etc/apache2/sites-enabled/$cname.$servn.conf created !"
else
echo "Virtual host /etc/apache2/sites-enabled/$cname.$servn.conf wasn't created !"
fi
echo "Would you like me to create ssl virtual host [y/n]? "
read q
if [[ "${q}" == "yes" ]] || [[ "${q}" == "y" ]]; then
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/certs/$cname.$servn.key -out /etc/ssl/certs/$cname.$servn.crt
if [ -e "/etc/ssl/certs/$cname.$servn.key" ]; then
echo "Certificate key created !"
else
echo "Certificate key wasn't created !"
fi
if [ -e "/etc/ssl/certs/$cname.$servn.crt" ]; then
echo "Certificate created !"
else
echo "Certificate wasn't created !"
fi

echo "#### ssl $cname $servn
<VirtualHost $listen:443>
SSLEngine on
SSLCertificateFile /etc/ssl/certs/$cname.$servn.crt
SSLCertificateKeyFile /etc/ssl/certs/$cname.$servn.key
ServerName $alias
ServerAlias $alias
DocumentRoot $dir$cname/html/
<Directory $dir$cname>
Options Indexes FollowSymLinks MultiViews
AllowOverride All
Order allow,deny
Allow from all
Satisfy Any
</Directory>
</VirtualHost>" > /etc/apache2/sites-enabled/ssl.$cname.$servn.conf
if ! echo -e /etc/apache2/sites-enabled/ssl.$cname.$servn.conf; then
echo "SSL Virtual host wasn't created !"
else
echo "SSL Virtual host created !"
fi
fi

echo "127.0.0.1 $servn" >> /etc/hosts
if [ "$alias" != "$servn" ]; then
echo "127.0.0.1 $alias" >> /etc/hosts
fi
echo "Testing configuration"
apachectl configtest
apachectl -t
echo "Would you like me to restart the server [y/n]? "
read q
if [[ "${q}" == "yes" ]] || [[ "${q}" == "y" ]]; then
apache2ctl -k graceful
systemctl reload apache2 
fi
echo "======================================"
echo "All work done! You should be able to see your website at http://$servn"
echo ""
echo "Share the love! <3"
echo "======================================"
echo ""
echo "Original script? https://gist.github.com/mattmezza/2e326ba2f1352a4b42b8"
echo "Updated for ubuntu / Apache2 https://gist.github.com/Downes/adc7e0baa21eb18bcfe1415dc5f6b697"