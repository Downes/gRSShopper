FROM httpd:2.4

# Use our Apache config (enables CGI)
COPY apache/httpd.conf /usr/local/apache2/conf/httpd.conf

# Site content will be bind-mounted at runtime
