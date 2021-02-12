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



   
   print "Content-type: text/html\n\n";   



	
	
# ---------------------------------
# Let's see what our environment is
if (!$ENV{'SERVER_SOFTWARE'}) {
  $newline = "\n";$h1 = ""; $h1f="";
}
else {
  print "Content-type: text/html\n\n";
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
Mastodon::Client MIME::Lite::TT::HTML Net::Twitter::Lite::WithAPIv1_1 REST::Client Scalar::Util 
Text::ParseWords Time::Local URI::Escape vCard WWW::Curl::Easy WWW::Mechanize XML::OPML);


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
		<a href="https://www.rcbowen.com/imho/perl/modules.html">https://www.rcbowen.com/imho/perl/modules.html</a> $newline|;

}

# 
# Test local libraries and require gRSShopper.pl
#

my $dirname = dirname(__FILE__);
eval "use lib $dirname";
if ($@) {
    print "Error loading library directory $dirname : $! <br>";
    $missing=1;
    push @missing_list,$module;
} else {
    print "Local libraries: OK; ";
}


eval "require $dirname/grsshopper.pl";
my $dirname = dirname(__FILE__);
eval "use lib $dirname";
if ($@) {
    print "Error loading grsshopper.pl : $! <br>";
    $missing=1;
    push @missing_list,$module;
} else {
    print "gRSShopper: OK; ";
}


# -------------
# Test database access (from default config in Dockerfile)

print "<p><b>Testing database access (from default config in Dockerfile)</b></p>";
use DBI;

    	# Make variables easy to read :)
    	my $dbname = "grsshopper";
    	my $dbhost = "localhost";
    	my $usr = "grsshopper_user";
    	my $pwd = "user_password";

	# Connect to the Database
  	my $dbh = DBI->connect("DBI:mysql:database=$dbname;host=$dbhost;port=3306",$usr,$pwd);

	# Catch connection error
	if( ! $dbh ) {

              print "Content-type: text/html\n\n";
	      print "Database connection error for db '$dbname'. Please contact the site administrator.<br>";   

		# Print error report and exit
		print "Error String Reported: $DBI::errstr <br>";
		exit;

	# I'll put more error-checking here
	} else {
	
	        print "<p>Database successfully connected.</p>";
		eval {
		#$dbh->do( whatever );
		#$dbh->{dbh}->do( something else );
		};

		if( $@ ) {
			print "Ugg, problem: $@\n";
		}
	}

# -------------
# Test sessions
print "<p><b>Testing user authentication</b></p>";
print "<p>Note that this may create a new Admin user is one is needed; please be sure to take note of the admin user name and password for later logins.</p>";

print qq|<iframe src="login_widget.cgi" height="100" width="500" title="Iframe Example"></iframe>|;

print qq|<p>Once you have logged in, try out <a href="../PLE.html">your new PLE</a></p>|;


exit;
