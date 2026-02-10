#!/usr/bin/perl

#  proxyp.cgi  -  A simple proxy script for making cross-domain requests
#  Part of CList, the next generation of learning and connecting with your community
#
#  Version version 0.1 created by Stephen Downes on January 27, 2025
#
#  Copyright National Research Council of Canada 2025
#  Licensed under Creative Commons Attribution 4.0 International https://creativecommons.org/licenses/by/4.0/
#
#  This software carries NO WARRANTY OF ANY KIND.
#  This software is provided "AS IS," and you, its user, assume all risks when using it.
 


use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use LWP::UserAgent;
use URI;



# Create a new CGI object
my $cgi = CGI->new;

# Set headers for CORS
print $cgi->header(
    -type => 'application/json',
    -access_control_allow_origin => '*',
    -access_control_allow_methods => 'GET, POST, OPTIONS',
    -access_control_allow_headers => 'Content-Type',
);

# Create a user agent
my $ua = LWP::UserAgent->new;

# Determine HTTP method (GET or POST)
my $method = $ENV{'REQUEST_METHOD'};

if ($method eq 'GET') {
    # Handle GET request
    my $url = $cgi->param('url');
    unless ($url) {
        print '{"error": "Missing \'url\' parameter in GET request"}';
        exit;
    }

    # Validate the URL
    if ($url !~ /^https?:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(\/\S*)?$/) {
        print '{"error": "Invalid \'url\' parameter"}';
        exit;
    }

    # Construct the URI with query parameters
    my %params = $cgi->Vars;  # Get query parameters (includes apikey)
    my $uri = URI->new($url);
    $uri->query_form(%params);  # Use the updated params including apikey

    # Debug logging
    logit("GET data: $uri\n");

    # Send GET request
    my $response = $ua->get($uri);

    if ($response->is_success) {
        print $response->decoded_content;
    } else {
        print '{"error": "Request failed: ' . $response->status_line . '"}';
    }
} elsif ($method eq 'POST') {
    # Handle POST request

    # Extract all form parameters
    my %params = $cgi->Vars;
    # Add the API key to the parameters



    my $url = $params{'url'};
    unless ($url) {
        print '{"error": "Missing \'url\' parameter in POST"}';
        exit;
    }

    # Validate the URL
    if ($url !~ /^https?:\/\/[a-zA-Z0-9\-\.]+\.[a-zA-Z]{2,}(\/\S*)?$/) {
        print '{"error": "Invalid \'url\' parameter"}';
        exit;
    }

    # Remove the URL from the parameters
    delete $params{'url'};

    # Prepare POST data
    my $post_data = join('&', map { "$_=" . $cgi->escape($params{$_}) } keys %params);
logit("POST data: $post_data\n");
    # Send POST request
    my $response = $ua->post($url, Content => $post_data);

    if ($response->is_success) {
        print $response->decoded_content;
    } else {
        print '{"error": "Request failed: ' . $response->status_line . '"}';
    }

} else {
    print '{"error": "Unsupported HTTP method"}';
}

# Debug logging
open my $log, '>>', 'proxy_debug.log';
print $log "Method: $method\n";
if ($method eq 'GET') {
    print $log "GET URL: " . $cgi->param('url') . "\n";
    print $log "Query Parameters: " . $cgi->query_string . "\n";
} elsif ($method eq 'POST') {
    print $log "POST URL: " . $cgi->param('url') . "\n";
    print $log "Form Parameters: " . join('&', map { "$_=" . $cgi->param($_) } $cgi->param) . "\n";
}
close $log;

sub logit {
    open my $log, '>>', 'proxy_logit.log';
    print $log @_;
    close $log;
}
