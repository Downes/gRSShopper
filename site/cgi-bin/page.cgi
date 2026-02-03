#!/usr/bin/perl

use strict;
use warnings;
use Cwd 'realpath';

# use CGI::Carp qw(fatalsToBrowser);

# -----------------------------
# Config: whitelist permitted hostnames and their docroots
# -----------------------------
my %ALLOWED_VHOSTS = (
    'www.downes.ca' => '/srv/www/www.downes.ca',
    'downes.ca'     => '/srv/www/www.downes.ca',
);


# Minimal query param parsing (replaces CGI->param)
my %PARAM;
{
    my $qs = $ENV{'QUERY_STRING'} // '';
    for my $pair (split /[&;]/, $qs) {
        next unless length $pair;
        my ($k, $v) = split /=/, $pair, 2;
        $k =~ tr/+/ /;
        $v =~ tr/+/ /;
        next unless length $k;
        $PARAM{$k} = $v;   # last one wins
    }
}
sub param { my ($name) = @_; return $PARAM{$name}; }




# Get and normalize domain name and request URI
my $raw_host = $ENV{'HTTP_HOST'} || 'default.domain';
$raw_host =~ s/^\s+|\s+$//g;
$raw_host = lc $raw_host;
$raw_host =~ s/:\d+$//;                 # strip :port
$raw_host =~ s/[^a-z0-9\.\-]//g;        # sanitize

# Enforce whitelist
my $docroot = $ALLOWED_VHOSTS{$raw_host};
if (!defined $docroot) {
    return send_error("Host not allowed.");
}

# Ensure docroot looks sane
my $real_base = realpath($docroot);
if (!defined $real_base) {
    return send_error("Server misconfiguration.");
}

# Obtain and sanitize request URI
my $request_uri = $ENV{'REQUEST_URI'} || '/';
$request_uri =~ s/\?.*$//;                   # strip query string (static serving)
$request_uri =~ s/\.\.//g;                   # normalize traversal attempts
$request_uri =~ s{//+}{/}g;                  # collapse duplicate slashes

# -----------------------------
# Path-style RD: /post/<id>/rd
# -----------------------------
if ($request_uri =~ m{^/post/(\d+)/rd$}) {
    my $id = $1;
    my ($parent, $leaf) = shard_segments($id);
    my $rd_base = "$docroot/_rd";
    my $rd_file = "$rd_base/$parent/$leaf";

    my $real_base_rd = realpath($rd_base);
    my $real_rd      = realpath($rd_file);

    if (defined $real_base_rd && defined $real_rd && index($real_rd, $real_base_rd) == 0 && -r $real_rd) {
        open my $fh, '<', $rd_file or return send_error("File not accessible");
        binmode $fh; my $url = <$fh>; close $fh;
        $url //= ''; $url =~ s/^\s+|\s+$//g; $url =~ s/[\r\n]+$//;
        if ($url =~ m{^https?://}i) {
            print redirect($url, '302 Found');  # or 301
            closelog(); exit 0;
        }
    }
    return send_error("$rd_file Not found");
}

# -----------------------------
# Query-style RD: /cgi-bin/page.cgi?post=<id>&action=rd
# -----------------------------
if ((lc(param('action')||'')) eq 'rd') {
    my $id = param('post');
    if (defined $id && $id =~ /^\d+$/ && $id > 0) {
        my ($parent, $leaf) = shard_segments($id);
        my $rd_base = "$docroot/_rd";
        my $rd_file = "$rd_base/$parent/$leaf";

        my $real_base_rd = realpath($rd_base);
        my $real_rd      = realpath($rd_file);

        if (defined $real_base_rd && defined $real_rd && index($real_rd, $real_base_rd) == 0 && -r $real_rd) {
            open my $fh, '<', $rd_file or return send_error("File not accessible");
            binmode $fh; my $url = <$fh>; close $fh;
            $url //= ''; $url =~ s/^\s+|\s+$//g; $url =~ s/[\r\n]+$//;
            if ($url =~ m{^https?://}i) {
                print redirect($url, '302 Found'); # or 301
                closelog(); exit 0;
            }
        }
        return send_error("$rd_file Not found");
    }
    # If no valid id, continue to normal handling (will 404 later)
}


exit 0;

# -----------------------------
# Helpers
# -----------------------------

sub redirect {
    my ($uri, $status) = @_;
    $uri    = defined $uri    ? $uri    : '/';
    $status = defined $status ? $status : '302 Found';
    return "Status: $status\r\nLocation: $uri\r\n\r\n";
}

sub header {
    my ($type, $status) = @_;
    $type   = defined $type   ? $type   : 'text/plain';
    $status = defined $status ? $status : '200 OK';
    return "Status: $status\r\nContent-Type: $type\r\n\r\n";
}

sub shard_segments {
    my ($id) = @_;
    # Scheme: 78157 -> 781/57  (parent=int(id/100), leaf=id%100)
    my $leaf   = $id % 100;
    my $parent = int($id / 100);
    return ($parent, $leaf);
}

sub send_error {
    my ($public_message) = @_;
    print header('text/plain', '404 Not Found');
	print "Redirect Error: $public_message File not found or access denied.\n";
    closelog();
    exit 0;
}
