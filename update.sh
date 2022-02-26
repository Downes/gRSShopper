#/bin/bash
repository="https://github.com/Downes/gRSShopper"
base="/var/www/"
html="${base}html/"
cgi="${html}cgi-bin/"
js="${html}assets/js/"
css="${html}assets/css/"

repo="${base}repofolder/"
repocgi="${repo}html/cgi-bin/"
repojs="${repo}html/assets/js"
repocss="${repo}html/assets/css"

backup="${base}backup/"
mkdir -p "${backup}"
cgibackup="${backup}cgibackup"
mkdir -p "${cgibackup}"
jsbackup="${backup}jsbackup"
mkdir -p "${jsbackup}"
cssbackup="${backup}cssbackup"
mkdir -p "${cssbackup}"

cp -R $cgi $cgibackup || echo "failed to back up $cgi to $cgibackup $?"
cp -R $js $jsbackup || echo "failed to back up $js to $jsbackup $?"
cp -R $css $cssbackup || echo "failed to back up $css to $cssbackup $?"

rm -R -f $repoFolder

git clone $repository $repo || echo "Git clone failed $?"
cp $repoCGI $cgi || echo "$repoCGI copy to $cgi failed $?"
cp "${repoCGI}api" "${cgi}api" || echo "${repoCGI}api copy to ${cgi}api failed $?"
cp "${repoCGI}editor" "${cgi}editor" || echo "${repoCGI}editor copy to ${cgi}editor failed $?"
cp "${repoCGI}harvest" "${cgi}harvest" || echo "${repoCGI}harvest copy to ${cgi}harvest failed $?"
cp "${repoCGI}languages" "${cgi}languages" || echo "${repoCGI}languages copy to ${cgi}languages failed $?"
cp -R "${repoCGI}modules" "${cgi}modules" || echo "${repoCGI}modules copy to ${cgi}modules failed $?"
cp "${repoCGI}services" "${cgi}services" || echo "${repoCGI}services copy to ${cgi}services failed $?"
cp $repoJS $js || echo "$repoJS to $js failed $?"
cp $repoCSS $css || echo "$repoCSS to $css failed $?"

echo "Updated CGI"
