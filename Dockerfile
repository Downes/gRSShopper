FROM ubuntu:latest
USER root
LABEL Description="gRSShopper - personal content aggregation, management and publishing platform." \
	License="Apache License 2.0" \
	Usage="docker run -d -p [HOST WWW PORT NUMBER]:443 -v [HOST WWW DOCUMENT ROOT]:/var/www/html downes/grsshopper" \
	Version="1.0" \
	Maintainer="Stephen Downes <stephen@downes.ca>"

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install rsync -y
RUN apt-get install systemd -y
RUN apt-get install build-essential -y
RUN apt-get install cron -y
RUN systemctl enable cron



COPY debconf.selections /tmp/
RUN debconf-set-selections /tmp/debconf.selections

RUN apt-get install -y zip unzip

	
RUN apt-get install -y cpanminus 
RUN apt-get install -y	  liblocal-lib-perl 
RUN apt-get install -y      libcgi-session-perl 
RUN apt-get install -y 	    libdbd-mysql-perl
RUN apt-get install -y      libwww-perl 
RUN apt-get install -y      libmime-types-perl 
RUN apt-get install -y      libjson-perl 
RUN apt-get install -y      libjson-xs-perl
RUN apt-get install -y      libjson-parse-perl 
RUN apt-get install -y      libtypes-datetime-perl 
RUN apt-get install -y     libcrypt-eksblowfish-perl 
RUN apt-get install -y      libtext-vcard-perl 
RUN apt-get install -y      libfile-slurp-perl 
RUN apt-get install -y      liblingua-en-inflect-number-perl 
RUN apt-get install -y	  libemail-stuffer-perl 
RUN apt-get install -y	  libimage-magick-perl 
RUN apt-get install -y	  librest-application-perl 
RUN apt-get install -y 	  libplack-perl
RUN apt-get install -y	  libauthen-simple-perl  
RUN apt-get install -y	  libauthen-simple-net-perl 
RUN apt-get install -y	  libcgi-xml-perl 
RUN apt-get install -y	  libxml-opml-perl
RUN apt-get install -y    libtemplate-plugin-gd-perl 
RUN apt-get install -y    libwww-curl-perl
RUN apt-get install -y    libwww-mechanize-perl
RUN apt-get install -y    liburi-encode-perl

RUN cpanm Image::Resize
RUN cpanm Mastodon::Client
RUN cpanm Net::Twitter::Lite::WithAPIv1_1
RUN cpanm REST::Client
RUN cpanm MIME::Lite::TT::HTML
RUN cpanm WebService::Mailgun

      
RUN apt-get install apache2 -y
# RUN apt-get install mariadb-common mariadb-server mariadb-client -y
# Postfix is currently generating errors
# RUN apt-get install postfix -y
RUN apt-get install git -y
RUN apt-get install nano -y
RUN apt-get install curl -y
RUN apt-get install ftp -y


ENV LOG_STDOUT **Boolean**
ENV LOG_STDERR **Boolean**
ENV LOG_LEVEL warn
ENV ALLOW_OVERRIDE All
ENV DATE_TIMEZONE UTC
ENV TERM dumb


COPY cgi-enabled.conf /etc/apache2/conf-available/
COPY ssl-params.conf /etc/apache2/conf-available/
COPY default-ssl.conf /etc/apache2/conf-available/

RUN a2enmod rewrite
RUN a2enmod ssl
RUN a2enmod headers 
RUN a2enmod cgid 
RUN rm -f /etc/apache2/conf-available/serve-cgi-bin.conf 
RUN a2ensite default-ssl
RUN mkdir /var/www/html/cgi-bin
RUN a2enconf cgi-enabled 

VOLUME ./html:/var/www/html
VOLUME /var/log/httpd
VOLUME /etc/apache2

COPY html/index.html /var/www/html/index.html
COPY html/index.html /var/www/html/index.htm
COPY html/PLE.html /var/www/html/PLE.html
COPY html/PLE.html /var/www/html/PLE.htm
COPY html/.htaccess /var/www/html/.htaccess
ADD html/assets /var/www/html/assets/
ADD html/cgi-bin /var/www/html/cgi-bin/

COPY html/cgi-bin/server_test.cgi /var/www/html/cgi-bin
RUN chmod 755 /var/www/html/cgi-bin/server_test.cgi
RUN chown www-data /var/www
RUN chgrp www-data /var/www

COPY run-lamp.sh /usr/sbin/
COPY cronfile /etc/cron.d/cronfile
RUN chmod 705 /var/www/html/cgi-bin/*.cgi
RUN chmod 705 /var/www/html/cgi-bin/update/*.sh

COPY version /var/www/html/cgi-bin/version.txt
RUN chown www-data /var/www/html/cgi-bin/version.txt
RUN chgrp www-data /var/www/html/cgi-bin/version.txt

# Addressing the chmod problem
RUN mkdir /var/www/html/cgi-bin/test
RUN cp /var/www/html/cgi-bin/server_test.cgi /var/www/html/cgi-bin/test/server_test.cgi
RUN chmod 775 /var/www/html/cgi-bin/test/server_test.cgi
RUN chown www-data /var/www/html/cgi-bin/test/server_test.cgi

# Set up cron

RUN chmod 0644 /etc/cron.d/cronfile
RUN crontab /etc/cron.d/cronfile
RUN touch /var/log/cron.log

# Run startup script
RUN chmod +x /usr/sbin/run-lamp.sh
RUN chown -R www-data:www-data /var/www/html

EXPOSE 80
EXPOSE 443
EXPOSE 3306

# Run everything in parallel
CMD cron & /usr/sbin/run-lamp.sh
