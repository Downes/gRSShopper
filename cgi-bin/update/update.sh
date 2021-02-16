#/bin/bash

repository="https://github.com/Downes/gRSShopper"
repoFolder="./update/repofolder"
repoCGI="./update/repofolder/cgi-bin/*"
repoJS="./update/repofolder/html/assets/js/*"
cgbackup="./cgbackup"
cgbackup="./jsbackup"
cp -R /var/www/html/cgi-bin/* $cgbackup
cp -R /var/www/html/cgi-bin/* $jsbackup
rm -R -f $repoFolder
git clone $repository $repoFolder
cp -R $repoCGI /var/www/html/cgi-bin
cp -R $repoJS /var/www/html/assets/js
chmod 775 /var/www/html/cgi-bin/update/update.sh
echo "Updated CGI"
