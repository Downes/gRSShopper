#/bin/bash

repository="https://github.com/Downes/gRSShopper"
repoFolder="./update/repofolder"
repoCGI="./update/repofolder/cgi-bin/*"
backup="./backup"
cp -R /var/www/html/cgi-bin/* $backup
rm -R -f $repoFolder
git clone $repository $repoFolder
cp -R $repoCGI /var/www/html/cgi-bin
chmod 775 /var/www/html/cgi-bin/update.sh
echo "Updated CGI"
