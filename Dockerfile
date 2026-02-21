FROM httpd:2.4

# Use our Apache config (enables CGI)
COPY apache/httpd.conf /usr/local/apache2/conf/httpd.conf

RUN apt-get update && apt-get install -y --no-install-recommends \
    cpanminus build-essential perl-base perl-modules-5.40 perl-doc \
    libperl-dev \
    libmariadb-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libgd-dev \
    zlib1g-dev \
    libcgi-session-perl \
    libdatetime-perl \
    libdatetime-timezone-perl \
    libdbi-perl \
    libdbd-mysql-perl \
    libemail-stuffer-perl \
    libfile-slurp-perl \
    libjson-perl \
    libjson-parse-perl \
    libjson-xs-perl \
    liblingua-en-inflect-perl \
    libmime-types-perl \
    libmastodon-client-perl \
    librest-client-perl \
    liburi-encode-perl \
    libwww-mechanize-perl \
    libxml-opml-perl \
    libamazon-s3-perl \
    cron \
    nano \
 && cpanm --notest WebService::Mailgun MIME::Lite::TT::HTML \
 && mkdir -p /var/log/grsshopper \
 && rm -rf /var/lib/apt/lists/*

# Site content will be bind-mounted at runtime

# Start cron + Apache
CMD cron && httpd-foreground

COPY cron/grsshopper-cron /tmp/grsshopper-cron
RUN crontab /tmp/grsshopper-cron && rm /tmp/grsshopper-cron


