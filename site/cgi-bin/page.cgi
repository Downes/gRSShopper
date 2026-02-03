#!/usr/bin/perl

use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Cwd 'realpath';
use URI::Escape;
use Sys::Syslog qw(:standard :macros);

# -----------------------------
# Config: whitelist permitted hostnames and their docroots
# -----------------------------
my %ALLOWED_VHOSTS = (
    'www.downes.ca' => '/var/www/www.downes.ca/html',
    'downes.ca'     => '/var/www/www.downes.ca/html',
);

# Initialize logging
openlog('perl_cgi_static', 'ndelay,pid', LOG_USER);

# Create CGI object
my $q = CGI->new;

# Get and normalize domain name and request URI
my $raw_host = $ENV{'HTTP_HOST'} || 'default.domain';
$raw_host =~ s/^\s+|\s+$//g;
$raw_host = lc $raw_host;
$raw_host =~ s/:\d+$//;                 # strip :port
$raw_host =~ s/[^a-z0-9\.\-]//g;        # sanitize

# Enforce whitelist
my $docroot = $ALLOWED_VHOSTS{$raw_host};
if (!defined $docroot) {
    syslog(LOG_WARNING, "Denied request for unapproved host '%s' from %s", $raw_host, ($ENV{REMOTE_ADDR}||'-'));
    return send_error($q, "Host not allowed.");
}

# Ensure docroot looks sane
my $real_base = realpath($docroot);
if (!defined $real_base) {
    syslog(LOG_ERR, "Configured docroot '%s' for host '%s' is not resolvable.", $docroot, $raw_host);
    return send_error($q, "Server misconfiguration.");
}

# Obtain and sanitize request URI
my $request_uri = $ENV{'REQUEST_URI'} || '/';
$request_uri = uri_unescape($request_uri);   # Decode URL encoding
$request_uri =~ s/\?.*$//;                   # strip query string (static serving)
$request_uri =~ s/\.\.//g;                   # normalize traversal attempts
$request_uri =~ s{//+}{/}g;                  # collapse duplicate slashes

# -----------------------------
# Query-style RD: /cgi-bin/page.cgi?post=<id>&action=rd
# (.htaccess maps /post/<id>/rd to this form)
# -----------------------------
if ((lc($q->param('action')||'')) eq 'rd') {
    my $id = $q->param('post');
    if (defined $id && $id =~ /^\d+$/ && $id > 0) {
        my ($parent, $leaf) = shard_segments($id);
        my $rd_base = "$docroot/_rd";
        my $rd_file = "$rd_base/$parent/$leaf";

        my $real_base_rd = realpath($rd_base);
        my $real_rd      = realpath($rd_file);

        if (defined $real_base_rd && defined $real_rd && index($real_rd, $real_base_rd) == 0 && -r $real_rd) {
            open my $fh, '<', $rd_file or return send_error($q, "File not accessible");
            binmode $fh; my $url = <$fh>; close $fh;
            $url //= ''; $url =~ s/^\s+|\s+$//g; $url =~ s/[\r\n]+$//;
            if ($url =~ m{^https?://}i) {
                print $q->redirect(-uri => $url, -status => '302 Found');  # or 301
                closelog(); exit 0;
            }
        }
        return send_error($q, "$rd_file Not found");
    }
    # If no valid id, continue to normal handling (will 404 later)
}

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
        open my $fh, '<', $rd_file or return send_error($q, "File not accessible");
        binmode $fh; my $url = <$fh>; close $fh;
        $url //= ''; $url =~ s/^\s+|\s+$//g; $url =~ s/[\r\n]+$//;
        if ($url =~ m{^https?://}i) {
            syslog(LOG_INFO, "Redirect: host=%s id=%s -> %s", $raw_host, $id, $url);
            print $q->redirect(-uri => $url, -status => '302 Found');  # or 301
            closelog(); exit 0;
        }
    }
    return send_error($q, "$rd_file Not found");
}

# Legacy query params -> INTERNAL rewrite to unsharded canonical
#   ?post=78157         -> treat as /post/78157 (no HTTP redirect)
#   ?presentation=587   -> treat as /presentation/587
for my $type (qw(post presentation)) {
    my $id = $q->param($type);
    next unless defined $id && $id =~ /^\d+$/ && $id > 0;
    $request_uri = "/$type/$id";   # internal rewrite only
    last;
}


# Canonical paths and internal rewrite
for my $type (qw(post presentation)) {
    # 1) Public unsharded -> INTERNAL rewrite to sharded (no redirect)
    if ($request_uri =~ m{^/$type/(\d+)(?:/(?:index\.html)?)?$}) {
        my $id = $1;
        my ($parent, $leaf) = shard_segments($id);   # 781/57 for 78157
        $request_uri = "/$type/$parent/$leaf/";      # internal only
        last;
    }

    # 2) Sharded path requested -> 301 back to canonical unsharded
    if ($request_uri =~ m{^/$type/(\d+)/(\d+)(?:/(?:index\.html)?)?$}) {
        my ($parent, $leaf) = ($1, $2);
        my $id = $parent * 100 + $leaf;              # adjust if you switch schemes
        print $q->redirect(-uri => "/$type/$id", -status => '301 Moved Permanently');
        closelog(); exit 0;
    }
}

# -----------------------------
# Static file serving
# -----------------------------
# Build candidate filename
my $filename = "$docroot$request_uri";

# If it ends with '/', append 'index.html'
if (-d $filename) {
    $filename .= '/index.html';
}

# Resolve real path of target
my $real_path = realpath($filename);

# Log access attempt
syslog(LOG_INFO, "Access: host=%s uri=%s candidate=%s resolved=%s from=%s",
    $raw_host, $request_uri, $filename, (defined $real_path ? $real_path : '(undef)'), ($ENV{REMOTE_ADDR}||'-')
);

# Security check: ensure target is within allowed docroot
if (!defined $real_path || index($real_path, $real_base) != 0) {
    syslog(LOG_WARNING, "Path escape prevented. host=%s uri=%s resolved=%s base=%s",
        $raw_host, $request_uri, (defined $real_path ? $real_path : '(undef)'), $real_base);
    return send_error($q, "Access denied.");
}

# Check existence and readability
if (!(-e $real_path && -r $real_path)) {
    syslog(LOG_INFO, "Not found or unreadable: %s (host=%s uri=%s)", $real_path, $raw_host, $request_uri);
    return send_error($q, "File not found.");
}

# Minimal content-type detection (expand as needed)
my $content_type = 'text/html';
if    ($real_path =~ /\.html?$/i) { $content_type = 'text/html' }
elsif ($real_path =~ /\.css$/i)   { $content_type = 'text/css' }
elsif ($real_path =~ /\.js$/i)    { $content_type = 'application/javascript' }
# else                            { $content_type = 'application/octet-stream' }

# Stream file contents in binary-safe chunks
my $fh;
if (!open($fh, '<', $real_path)) {
    syslog(LOG_ERR, "Open failed: %s : %s", $real_path, $!);
    return send_error($q, "File not accessible.");
}

binmode $fh;
binmode STDOUT;

# Output HTTP headers and content
print $q->header(-type => $content_type);

my $buffer;
while (read($fh, $buffer, 8192)) {
    print $buffer;
}
close $fh;

# Done
closelog();
exit 0;

# -----------------------------
# Helpers
# -----------------------------
sub shard_segments {
    my ($id) = @_;
    # Scheme: 78157 -> 781/57  (parent=int(id/100), leaf=id%100)
    my $leaf   = $id % 100;
    my $parent = int($id / 100);
    return ($parent, $leaf);
}

sub send_error {
    my ($q, $public_message) = @_;
    print $q->header(-type => 'text/plain', -status => '404 Not Found');
    print "Error: $public_message File not found or access denied.\n";
    closelog();
    exit 0;
}
