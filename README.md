# gRSShopper
Personal Learning Environment and MOOC Hosting Platform

downes/grsshopper
==========

[![grsshopper_logo](https://raw.githubusercontent.com/downes/grsshopper/master/grsshopper_header.jpg)](https://grsshopper.downes.ca)

[![Docker Pulls](https://img.shields.io/docker/pulls/downes/grsshopper.svg?style=plastic)](https://hub.docker.com/r/downes/grsshopper/)
[![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/downes/grsshopper?style=plastic)](https://hub.docker.com/r/downes/grsshopper/builds/)


gRSShopper is a tool that aggregates, organizes and distributes resources to support online learning. Read more here: https://grsshopper.downes.ca/ 

Although it will run as a stand-alone application in an Apache2 envronment, it is designed to run in a Docker container. It can be installed either bundled with a built-in database, or on it's own, using an external database. As a Docker container it works equally well on a desktop or in the cloud.

This repository contains a Dockerfile and some docker-compose files. The docker image is here: https://hub.docker.com/r/downes/grsshopper and automatically updates following changes to this repository.

To run with embedded database from Docker Image:
===============================================

gRSShopper uses two containers, a server container and a database container. Before running docker-compose you need to download the SQL startup file and place it in the init directory; docker-compose will then load it into the generic database container. To do this, follow the instructions below:
 
```
curl https://raw.githubusercontent.com/Downes/gRSShopper/master/docker-compose-no-build.yml --output  docker-compose.yml
mkdir init
curl https://raw.githubusercontent.com/Downes/gRSShopper/master/init/gRSShopper-ple.sql --output init/gRSShopper-ple.sql
docker-compose up
```

OR, run with embedded database from the GitHub repository:
=========================================================

Process: run docker-compose to create two Docker containers, one for the application and one for the database. Running it from GitHub will clone the files. Then  and build the image and execute the build with the docker-compose command.

```
git clone  https://github.com/Downes/gRSShopper
```
        (or git pull origin master if reloading the changed repo)

```
cd gRSShopper

docker-compose up
```

OR, run as a stand-alone container and an external Maria or MySQL database
==========================================================================

Follow the instructions documented and illustrated here: https://docs.google.com/document/d/1jMFvEy8ikcVeweWzgzXWzh3JF7RDyllVaDwaSsxh5po/edit?ouid=109526159908242471749&usp=docs_home&ths=true

These instructions are specifically for Reclaim Cloud, though a similar approach in other cloud
environments (currently untested) should work as wekk.

Running in stand-alone mode will give you the option of selection from a number of pre-configured
databases, ranging from a simple basic install to a fully functional MOOC.


Testing the server 
==================

Note that gRSShopper runs in SSL (on post 443) and requires that you access it using https.

https://[your domain]  (should show gRSShopper start page)

https://[your domain]/cgi-bin/server_test.cgi  (should show Perl test page)     


Restart the Apache server
=========================

If Perl CGI isn't running properly, try:
```
docker exec -it gr1 /etc/init.d/apache2 reload
```

   (you can't docker exec -it bb3 apache2ctl restart because it crashes the entire container - see https://stackoverflow.com/questions/37523338/how-to-restart-apache2-without-terminating-docker-container )

   ( if you crash it, docker start bb3 )


Open a terminal in the container
================================
```
docker exec -e TERM=xterm -i -t grsshopper_grsshopper_1 bash
```

(A lot of sites say ```docker exec -it gr1 bash``` but I find it generates an error. Also if you want to be able to use nano when entering a container, you will need to set -e TERM=xterm). Alternatively  you can use the browser-based SSH terminal that comes with Docker Desktop or is available on cloud hosting sites.


Start cron
==========

Cron: cron starts automatically and runs in the gRSShopper container. if it ever stops (it shouldn't) you can enter the container and start it manually:

```
docker exec -e TERM=xterm -i -t grsshopper_grsshopper_1 bash
cron
crontab /etc/cron.d/cronfile
exit
```

The first command opens a terminal in the container. Then 'cron' starts cron, and the crontab loads instructions into the cron table. Exit closes the terminal in the container. Sorry if this doesn't work automatically.

Problems and Issues?
====================

Send me an email: stephen@downes.ca

