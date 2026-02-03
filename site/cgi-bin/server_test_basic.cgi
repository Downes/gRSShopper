#!/usr/bin/perl
 

#    gRSShopper 0.7  Server Test  0.2  -- gRSShopper server test module
#    26 April 2017 - Stephen Downes


#    Copyright (C) <2008>  <Stephen Downes, National Research Council Canada>

#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

##########################################################################
# Servertest.pl
##########################################################################
	use CGI;
	use CGI::Carp qw(fatalsToBrowser);
	use lib 'modules/lib/perl5';



   
   print "Content-type: text/html\n\n";   
print "<pre>Hello from Server Test\n\n";
print "DEBUG HTTP_HOST=$ENV{HTTP_HOST}\n";
print "DEBUG SCRIPT=$0\n";
use Cwd qw(abs_path); use File::Basename qw(dirname);
my $cgidir = dirname(abs_path($0))."/";
print "DEBUG CGIDIR=$cgidir\n";
my $ms = $cgidir."data/multisite.txt";
print "DEBUG MULTISITE=$ms\n";
print "DEBUG MULTISITE_EXISTS=".( -e $ms ? 1 : 0 )."\n";
if (open my $fh, "<", $ms) {
  my $found=0;
  while (<$fh>) { s/(\s|\r|\n)$//g; my @f=split(/\t/);
    if ($f[0] eq $ENV{HTTP_HOST}) { $f[3]="[REDACTED]"; $f[4]="[REDACTED]";
      print "DEBUG MATCH=".join("\t",@f)."\n"; $found=1; last; }
  }
  close $fh;
  print "DEBUG MATCH_FOUND=$found\n";
} else {
  print "DEBUG MULTISITE_OPEN_FAIL=$!\n";
}
print "</pre>\n";



	
	
# ---------------------------------
# Let's see what our environment is
if (!$ENV{'SERVER_SOFTWARE'}) {
  $newline = "\n";$h1 = ""; $h1f="";
}
else {
  print "Content-type: text/html\n\n";
print "<pre>";
print "DEBUG HTTP_HOST=$ENV{HTTP_HOST}\n";
print "DEBUG SCRIPT=$0\n";
use Cwd qw(abs_path); use File::Basename qw(dirname);
my $cgidir = dirname(abs_path($0))."/";
print "DEBUG CGIDIR=$cgidir\n";
my $ms = $cgidir."data/multisite.txt";
print "DEBUG MULTISITE=$ms\n";
print "DEBUG MULTISITE_EXISTS=".( -e $ms ? 1 : 0 )."\n";
if (open my $fh, "<", $ms) {
  my $found=0;
  while (<$fh>) { s/(\s|\r|\n)$//g; my @f=split(/\t/);
    if ($f[0] eq $ENV{HTTP_HOST}) { $f[3]="[REDACTED]"; $f[4]="[REDACTED]";
      print "DEBUG MATCH=".join("\t",@f)."\n"; $found=1; last; }
  }
  close $fh;
  print "DEBUG MATCH_FOUND=$found\n";
} else {
  print "DEBUG MULTISITE_OPEN_FAIL=$!\n";
}
print "</pre>\n";
  $newline = "<br>"; $h1 = "<h1>"; $h1f = "</h1>";
 }
print $h1."gRSShopper web server environment test.".$h1f.$newline.$newline;

# --------------------------------------
# Check for the required version of PERL
eval "require 5.004";
print "Checking PERL version...";
if ($@) {
  print "$newline"."This program requires at least PERL version 5.004 or greater.$newline";
  exit;
} else {
print " <span style='color:green;'> OK</span>$newline";
}

# use local::lib; # sets up a local lib at ~/perl5

# -----------------------------------------------------
# Check that all of the required modules can be located



$|++;
my $missing = 0;
my @lissing_list;
my @modules = qw(CGI CGI::Carp CGI::Session Crypt::Eksblowfish::Bcrypt Cwd DateTime DateTime::TimeZone 
DBI DBD::mysql Digest::MD5 Digest::SHA Email::Stuffer Email::Sender::Transport::SMTP Fcntl 
File::Basename File::Slurp File::stat File::Find HTML::Entities HTTP::Request::Common
Image::Resize JSON JSON::Parse JSON::XS Lingua::EN::Inflect LWP LWP::UserAgent LWP::Simple MIME::Types 
Mastodon::Client MIME::Lite::TT::HTML REST::Client Scalar::Util 
Text::ParseWords Time::Local URI::Encode URI::Escape vCard WWW::Mechanize XML::OPML);


print "Checking: ";
foreach my $module (@modules) {
  print "$module ";
  eval "use $module";
  if ($@) {
    print "<span style='color:red;'> X</span> ";
    $missing=1;
    push @missing_list,$module;
  } else {
    print "<span style='color:green;'> OK</span> ";
  }
}



# -------------
# Provide CPAN help

if ($missing eq "1") {



	print qq|$newline$newline You are missing the following required Perl modules.<ul>|;
  foreach my $module (@missing_list) { print qq|<li>$module</li>|; }

  print qq|</ul>		$newline$newline
		<b>Getting Perl Modules</b>$newlineFor more information, please see:$newline
		<a href="https://www.cpan.org/modules/INSTALL.html">https://www.cpan.org/modules/INSTALL.html</a> $newline
		<a href="https://www.rcbowen.com/imho/perl/modules.html">https://www.rcbowen.com/imho/perl/modules.html</a> 
    $newline$newline|;
}

# 
# Test local libraries 
#

#my $dirname = dirname(__FILE__);
eval "use lib modules";
if ($@) {
    print "<span style='color:red;'>Error loading library directory modules : $! </span>$newline";
} else {
    print "Local libraries: <span style='color:green;'>OK</span>; ";
}

#
# Require gRSShopper.pl
#

my $dirname = dirname(__FILE__);
require $dirname . "/grsshopper.pl";
if ($gRSShopper_version) { print "gRSShopper: <span style='color:green;'>version $gRSShopper_version</span>; ";}
else { print "<span style='color:red;'>Error loading gRSShopper : $! </span><br>"; }

#
# Create a new Site object 
#

our $Site = gRSShopper::Site->new({
		context		=>	'server test',
		data_dir	=>	'./data/',				# Location of site configuration files
		secure => 1,							# Turns on SSH
});
die "Unable to create gRSShopper object" unless ($Site);
print "gRSShopper object created.$newline$newline";

# 
# Test database access (from from values in multisite.txt)
#

my $dbh = $Site->{dbh};
die "<span style='color:red;'>Database access failed<br></span>\n" unless ($Site);
print "Database access successful.<br>";
print "Database name: ".$Site->{database}->{name}."<br>";
&get_config($dbh);
$Site->{database}="";		# Clearing values for security purposes
$_ = "";



# 
# Test sessions
#

print "<p><b>Testing user authentication</b></p>";
print "<p>Note that this may create a new Admin user is one is needed; please be sure to take note of the admin user name and password for later logins.</p>";

print qq|<iframe src="login_widget.cgi" height="100" width="500" title="Login Widget"></iframe>|;

print qq|<p>Once you have logged in, try out <a href="../PLE.html">your new PLE</a></p>|;


exit;
