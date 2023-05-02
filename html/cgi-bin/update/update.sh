#/bin/bash
repository="https://github.com/Downes/gRSShopper"
CGIfolder="../"
JSfolder="../../assets/js"
CSSfolder="../../assets/css"
repoFolder="./update/repofolder"
repoCGI="./update/repofolder/cgi-bin/*"
repoJS="./update/repofolder/html/assets/js/*"
repoCSS="./update/repofolder/html/assets/css/*"
cgbackup="./cgbackup"
cgbackup="./jsbackup"
cgbackup="./cssbackup"
cp -R /var/www/html/cgi-bin/* $cgbackup
cp -R /var/www/html/assets/js/* $jsbackup
cp -R /var/www/html/assets/css/* $cssbackup
rm -R -f $repoFolder
git clone $repository $repoFolder || echo "Git clone failed $?"
cp -R $repoCGI $CGIfolder || echo "CGI copy to $CGIfolder failed $?"
cp -R $repoJS $JSfolder || echo "JS copy to $JSfolder failed $?"
cp -R $repoCSS $CSSfolder || echo "CSS copy to $JSfolder failed $?"
chmod 775 ./update.sh || echo "Failed to renew update script $?"
echo "Updated CGI"
