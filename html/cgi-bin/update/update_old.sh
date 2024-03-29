#/bin/bash
repository="https://github.com/Downes/gRSShopper"
SCRIPTPATH=$(dirname $0)
fcgi=$(dirname ${SCRIPTPATH})
fcgi="${fcgi}/"
echo " CGI directory is ${fcgi}\n"
html=$(dirname ${fcgi})
html="${html}/"
echo " HTML directory is ${html}\n"
base=$(dirname ${html})
base="${base}/"
echo " Base directory is ${base}\n"

js="${html}assets/js/"
css="${html}assets/css/"

repo="${base}repofolder/"
repocgi="${repo}html/cgi-bin/"
repojs="${repo}html/assets/js/"
repocss="${repo}html/assets/css/"

backup="${base}backup/"
mkdir -p "${backup}"
cgibackup="${backup}cgibackup"
mkdir -p "${cgibackup}"
jsbackup="${backup}jsbackup"
mkdir -p "${jsbackup}"
cssbackup="${backup}cssbackup"
mkdir -p "${cssbackup}"

echo "Backing up data:"
rsync -rv $fcgi $cgibackup || echo "failed to back up $fcgi to $cgibackup $?"
rsync -rv $js $jsbackup || echo "failed to back up $js to $jsbackup $?"
rsync -rv $css $cssbackup || echo "failed to back up $css to $cssbackup $?"

rm -R -f $repo

echo "Updating from $repository"
git clone $repository $repo || echo "Git clone failed $?"
echo "Synchronizing:";
rsync -rv --exclude 'multisite.txt' $repocgi $fcgi || echo "Failed to sync $repocgi with $fcgi : $?"
rsync -rv $repojs $js || echo "Failed to sync $repojs to $js : $?"
rsync -rv $repocss $css || echo "Failed to sync $repocss to $css : $?"

echo "Updated CGI"
