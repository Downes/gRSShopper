downes/grsshopper
==========

![docker_logo](https://raw.githubusercontent.com/downes/grsshopper/master/docker_139x115.png)![docker_fauria_logo](https://raw.githubusercontent.com/downes/grsshopper/master/docker_fauria_161x115.png)![grsshopper_logo](https://raw.githubusercontent.com/downes/grsshopper/master/grsshopper_header.jpg)

[![Docker Pulls](https://img.shields.io/docker/pulls/downes/grsshopper.svg?style=plastic)](https://hub.docker.com/r/downes/grsshopper-ple/)
[![Docker Build Status](https://img.shields.io/docker/build/downes/grsshopper.svg?style=plastic)](https://hub.docker.com/r/downes/grsshopper-ple/builds/)
[![](https://images.microbadger.com/badges/image/downes/grsshopper.svg)](https://microbadger.com/images/downes/grsshopper-ple "downes/grsshopper-ple")




gRSShopper is a tool that aggregates, organizes and distributes resources to support online learning. Read more here: https://grsshopper.downes.ca/


Docker image is here: https://hub.docker.com/r/downes/grsshopper-ple

**Note: don't use Docker imagejust now, run from this GitHub repository**

To run:
shell```
docker pull downes/grsshopper

docker run -p 80:80 -p 443:443 --detach --name gr1 grsshopper
```


OR, run from the GitHub repository as follows:

Process:

shell```
git clone  https://github.com/Downes/gRSShopper
```

        (or git pull origin master if reloading the changed repo)


shell```
cd gRSShopper

docker build --tag grsshopper .

docker run -p 80:80 -p 443:443 --detach --name gr1 grsshopper
```

Testing the server on localhost

http://localhost  (should show gRSShopper start page)

http://localhost/cgi-bin/server_test.cgi  (should show Perl test page)     

(Note: on localhost you will run into CORS problems running the PLE
engine at PLE.htm - the Docker image should be placed in the cloud and run under SSL) 

If Perl CGI isn't running properly, try:
```
docker exec -it gr1 /etc/init.d/apache2 reload
```

   (you can't docker exec -it bb3 apache2ctl restart because it crashes the entire container - see https://stackoverflow.com/questions/37523338/how-to-restart-apache2-without-terminating-docker-container )

   ( if you crash it, docker start bb3 )

Open a shell inside
```
docker exec -e TERM=xterm -i -t gr1 bash
```

(A lot of sites say ```docker exec -it gr1 bash``` but I find it generates an error. Also if you want to be able to use nano when entering a container, you will need to set -e TERM=xterm).

Credits
=======

I did the coding, etc., but here are some resources that really helped along the way

https://mariadb.com/kb/en/making-backups-with-mysqldump/ - Maria db making backups with mysqldump

https://hub.docker.com/r/fauria/lamp - Fauria LAMP Docker image

https://www.edureka.co/community/10534/copying-files-from-host-to-docker-container - Copying files into a container

https://www.reclaim.cloud - Reclaim's cloud hosting service

https://www.drdobbs.com/web-development/session-management-with-cgisession/184415974 - Session management in Perl

https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie - Set Cookie

https://metacpan.org/ - cpan Perl archive

https://metacpan.org/pod/CGI::Cookie - CGI::Cookie

https://docs.jelastic.com/ - cloud management tool used by Reclaim

https://www.server-world.info/en/note?os=Ubuntu_18.04&p=httpd&f=2 

https://registry.hub.docker.com/r/mattrayner/lamp/ - LAMP in containers

https://alysivji.github.io/php-mysql-docker-containers.html - Mysql in containers

https://stackoverflow.com/questions/1443210/updating-a-local-repository-with-changes-from-a-github-repository - Stack Overflow

https://stackoverflow.com/questions/37523338/how-to-restart-apache2-without-terminating-docker-container - restart Apache without killing the container

https://stackoverflow.com/questions/22720763/how-to-use-perl-to-change-a-mysql-password - changing a mysql password with perl

https://stackoverflow.com/questions/25920029/setting-up-mysql-and-importing-dump-within-dockerfile - setting up mysql in Docker

https://stackoverflow.com/questions/13154552/javascript-set-cookie-with-expire-time - cookies and Javascript

https://docs.docker.com/get-started/ - setting up a container, part 1

https://docs.docker.com/get-started/part2/ - setting up a container, part 2

https://docs.docker.com/get-started/part3/ - - setting up a container, part 3

https://gist.github.com/gcrawshaw/1071698/fe4a2ac69d845a65a093a23c4899fd9d80d5c466 - Using bcrypt to secure passwords in a Perl application 

https://gist.github.com/gcrawshaw/1071698/53f042e5e3bf399bdf2e5e023ffa057d3a15467a - Using bcrypt to secure passwords in a Perl application 

https://rosettacode.org/wiki/SHA-256#Perl - SHA 256 in Perl

https://www.digitalcitizen.life/how-view-remove-cookies-mozilla-firefox - working with and testing cookies

https://metacpan.org/pod/release/SHERZODR/CGI-Session-3.95/Session.pm - perl Sessions module

https://metacpan.org/pod/release/SHERZODR/CGI-Session-3.95/Session/CookBook.pm - Perl sessions

https://blog.ouseful.info/2020/06/09/first-forays-into-the-reclaim-cloud-beta-running-a-personal-jupyter-notebook-server/

https://www.effectiveperlprogramming.com/2020/06/turn-off-indirect-object-notation/ - Perl - Turn off indirect object notation

https://stackoverflow.com/questions/37458287/how-to-run-a-cron-job-inside-a-docker-container - How to run a cron job in Docker

https://www.howtogeek.com/howto/42980/the-beginners-guide-to-nano-the-linux-command-line-text-editor/ - Help using Nano

https://forums.docker.com/t/cannot-use-vim-vi-nano-yum-inside-docker-container/14905 - Help using Nano

https://www.digitalocean.com/community/tutorials/how-to-use-cron-to-automate-tasks-ubuntu-1804 - Setting up cron