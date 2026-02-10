#/bin/bash
set -e
repository="https://github.com/Downes/gRSShopper"
base="/srv/www/$1/"
echo "Base is ${base}"
html="${base}html/"
mkdir -p "${html}"
fcgi="${html}cgi-bin/"
mkdir -p "${fcgi}"
js="${html}assets/js/"
mkdir -p "${js}"
css="${html}assets/css/"
mkdir -p "${css}"

repo="${base}repofolder/"
repohtml="${repo}html/"
repocgi="${repo}html/cgi-bin/"
repojs="${repo}html/assets/js/"
repocss="${repo}html/assets/css/"



rm -R -f $repo

echo "Updating from $repository\n"
git clone $repository $repo || echo "Git clone failed $? \n"
echo "Synchronizing:\n";
rsync -rv --exclude 'multisite.txt' $repohtml $html || echo "Failed to sync $repohtml with $html : $? \n"
cgstr="${fcgi}*.cgi"
echo "cgistr is $cgstr"
find "${cgstr%/*}" -name "${cgstr##*/}" -exec chmod 775 {} +


echo "Updated CGI"
