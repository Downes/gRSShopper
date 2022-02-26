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
use CGI::Session;
our $query = new CGI;
our $vars = $query->Vars;

# Change Database?
if ($vars->{action} eq "change_database") { &change_database(); }      

# Check Environment
my $newline = &check_environment();    

# Check Perl modules
&check_perl();

# Update database info if requested
if ($vars->{action} eq "Create Database") { &create_database($vars); }  # creates brand new db
if ($vars->{action} eq "Access Database") { &access_database($vars); }  # rewrites multisite.txt


# Test Database Access
&test_db_access();
our $Site = &open_site();                                               # opens db using multisite.txt



print "Got $Site->{st_url} <p>";


# Test Authentication
&test_sessions($Site->{st_url});

exit;
   
    



	
sub check_environment {
  # ---------------------------------
  # Let's see what our environment is
  if (!$ENV{'SERVER_SOFTWARE'}) {
    $newline = "\n";$h1 = ""; $h1f="";
  } else {
    print "Content-type: text/html\n\n";
    $newline = "<br>"; $h1 = "<h1>"; $h1f = "</h1>";
  }
  print $h1."gRSShopper web server environment test.".$h1f.$newline.$newline;
  return $newline;
}

sub check_perl {
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
  Text::ParseWords Time::Local URI::Encode URI::Escape vCard WebService::Mailgun WWW::Curl::Easy 
  WWW::Mechanize XML::OPML);


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
}



sub test_db_access {

  #
  # Test DB Access
  #
  my ($home,$name,$loc,$usr,$pwd,$lan,$urlf,$cgif) = &read_multisite_file($vars->{site});
  unless ($vars->{site}) { $vars->{site} = $home; }

  print "<p>Testing database connection with the following values.<ul>";
  print "Site home URL:",$home,"<br>",
      "Database name: ",$name,"<br>",
      "Database host location: ",$loc,"<br>",
      "Database user: ",$usr,"<br>",
      "Database password: ********* <br>",
      "Default language: ",$lan,"<br>",
      "HTML files: ",$urlf,"<br>",
      "CGI files: ",$cgif,"</ul>";
  my $testdbh = DBI->connect("DBI:mysql:database=$name;host=$loc;port=3306",$usr,$pwd);
  if ($testdbh) { print "Database connection successful. ";
    print qq|<a href="server_test.cgi?action=change_database&site=|.$vars->{site}.qq|">Change Database</a></p>|;
  }
  else { 
    if ($vars->{action}) { 
        print "<b>Database connection was unsuccessful. Please update values and try again.</b></p>".$DBI::errstr;
    }
    &print_form($home,$name,$loc,$usr,$pwd,$lan,$urlf,$cgif,$vars->{site}); exit; }
}

sub open_site {

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

  my $Site = gRSShopper::Site->new({
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
  &get_config($dbh);
  $Site->{database}="";		# Clearing values for security purposes
  $_ = "";

  return $Site;
}

sub test_sessions {
  # 
  # Test sessions

  my ($url) = @_;
  my $login_widget = $url . "cgi-bin/login_widget.cgi";
  
  #
  # Doesn't work for two sites in the cloud
  #
  # $url = "https://www.downes.ca/PLE.html";
  # print "Looking for $url <p>";
  # use LWP::UserAgent;
  #  my $login_widget = $url . "cgi-bin/login_widget.cgi";
  # my $ua = LWP::UserAgent->new;
  # my $req = HTTP::Request->new(GET => $url);
  # my $res = $ua->request($req);
  # if ($res->is_success) {
  #     print $res->as_string;
  # }
  # else {
  #     print "Failed: ", $res->status_line, "\n";
  # }

  # my $test_url = $url . "PLE.html";
  # my $content = &get_url($feedrecord);
  # Does this site exist yet?
  #  use LWP::Simple;
  # my $content = get($test_url);

  # print "Running 34567 got $content @@";
  # exit;
  # my $widget_test = get $login_widget;

  # print "Running 890";
  # exit;

  # unless ($widget_test) { print "This site doesn't exist yet"; }

  print "<p><b>Testing user authentication</b></p>";
  print "<p>Note that this may create a new Admin user if one is needed; please be sure to take note of the admin user name and password for later logins.</p>";
  print qq|<iframe src="$login_widget" height="100" width="500" title="Login Widget"></iframe>|;
  print qq|<p>Once you have logged in, try out <a href="|.$url.qq|PLE.html">your new PLE</a></p>|;

}



sub read_multisite_file {

  my ($inputhome) = @_;
  if ($inputhome) { print "<p>Loading $inputhome<br>"; }
  else { print "<p>Loading default site information.<br>"; }
 #exit; 
  # Open database info file
  my $data_file = "./data/multisite.txt";
	unless (-e $data_file) {
    print "Website information file $data_file does not exist."; 
    die "Website information file $data_file does not exist.";
  };
	unless (open IN,"$data_file") {
    print "Cannot open website information file $data_file : $!"; 
    die "Cannot open website information file $data_file : $!";     
  }
  
  # and read site database information from it
  my $line; my $row = 0;
  while (<IN>) {
    $line = $_;
    $line =~ s/(\s|\r|\n)$//g;
    my ($h) = split "\t",$line;
    if ($row == 0) {  # Default values are in the first line
      ($home,$name,$loc,$usr,$pwd,$lan,$urlf,$cgif) = split "\t",$line;
      if ($inputhome) {   # Specifying a specific site; we'll set up defaults based on that
        $home = $inputhome;
        my @inputhomelist = split /\//,$inputhome; my $base = pop @inputhomelist;
        $name = $base;
        $urlf = "/vars/www/".$name."/html/";
        $cgif = "/vars/www/".$name."/html/cgi-bin/";
      }
    }
    if (($h) && ($h eq $inputhome)) {  # Location specific values
                             # If the location is repeated, will be the last instance
      ($home,$name,$loc,$usr,$pwd,$lan,$urlf,$cgif) = split "\t",$line;
    }
    $row++;
  }
  close IN;
  return ($home,$name,$loc,$usr,$pwd,$lan,$urlf,$cgif);
}

sub change_database {

    my $session = new CGI::Session(undef, $query, {Directory=>'/tmp'});
    $session->delete();
    print $query->header();
    print "Content-type: text/html\n\n";
    unless ($vars->{site}) { print "Cannot determine your current site in change_database().<br>"; exit; }
    print "Please log out before creating a new database. <br>";

    my ($home,$name,$loc,$usr,$pwd,$lan,$urlf,$cgif) = &read_multisite_file($vars->{site});
    &print_form($home,$name,$loc,$usr,$pwd,$lan,$urlf,$cgif,$vars->{site}); 
    exit;

}

sub print_form { 
  my ($home,$name,$loc,$usr,$pwd,$lan,$urlf,$cgif,$site) = @_;
  my $sql_options = &get_sql_options();

  print qq|
  <script>
  function myFunction(a,b) {
    var mainFrameOne = document.getElementById(a); 
    var mainFrameTwo = document.getElementById(b);
    mainFrameOne.style.display = "block"; 
    mainFrameTwo.style.display = "none"; 
  }
  </script>
  <style>
  .area {
    border: solid 1px black;
    height:26em;
    width:40em;
    overflow: auto;
    padding:2em;
  }
  </style>
  <p>
  <button class="button_large" onclick="myFunction('a','b')">Use existing gRSShopper database</button>
  <button class="button_large" onclick="myFunction('b','a')"> Create a new gRSShopper database</button>
  </p>
  <div id="a" class="area" style="display:none;">
    <p><b>Use existing gRSShopper database</b></p>
    <p>Enter your gRSShopper database information<br>
    <form method="post" action="server_test.cgi">
    <input type="hidden" name="site" value="$site">
    <input type="hidden" name="lan" value="$lan">
    <input type="hidden" name="urlf" value="$urlf">
    <input type="hidden" name="cgif" value="$cgif">
    <input type="text" name="home" value="$home"> Your website home URL<br>
    <input type="text" name="name" value="$name"> Database name<br>
    <input type="text" name="loc" value="$loc">  Database host location (url or IP)<br>
    <input type="text" name="usr" value="$usr">  Database user name<br>
    <input type="text" name="pwd" value="$pwd">  Database user password<br>
    <input type="submit" name="action" value="Access Database"><br>
    </form>
    </p>

  </div>
  <div id="b" class="area">
    <form method="post" action="server_test.cgi">
    <input type="hidden" name="lan" value="$lan">
    <input type="hidden" name="urlf" value="$urlf">
    <input type="hidden" name="cgif" value="$cgif">
    <p><b>Create a new gRSShopper database</b></p>
    <p>Enter the <i>root</i> database information, to create the database<br><br>
    <input type="text" name="rootname" value=""> Database root user name<br>
    <input type="password" name="rootpwd" value=""> Database root user password<br>
    <input type="text" name="loc" value="$loc">  Database host location (url or IP)<br>
    <br>Enter your new gRSShopper database information<br><br>
    <input type="text" name="home" value="$home"> Your website home URL<br>
    <input type="text" name="name" value="$name"> Database name<br>
    <input type="text" name="usr" value="$usr">  Database user name<br>
    <input type="password" name="pwd" value="$pwd">  Database user password<br>
    <br>Select a version of gRSShopper from the repository at MOOC.ca<br><br>
    $sql_options
    <input type="submit" name="action" value="Create Database"><br>
    </form>
    </p>
  </div>



  |;
}

sub get_sql_options {
  # gets the list of SQL database files from MOOC.ca
  # [{"file_title":"moocca_header.png","file_url":"https://mooc.ca/files/images/moocca_header.png"}, {"file_title":"mooccaicon.png","file_url":"https://mooc.ca/files/images/mooccaicon.png"}, {"file_title":"grsshopper-base.sql","file_url":"https://mooc.ca/files/files/grsshopper-base.sql"}, {"file_title":"grsshopper-base.1.sql","file_url":"https://mooc.ca/files/files/grsshopper-base.1.sql"} ] 

  my $sql_list_url = 'https://grsshopper.downes.ca/sql_file_source.json';
  use LWP::Simple;
  my $sql_list_json = get $sql_list_url;
  use JSON::Parse 'parse_json';
  my $sql_list = parse_json ($sql_list_json);
  my $output = qq|<select name="sql_url">\n|;
  foreach my $sl (@$sql_list) { 
    if ($sl->{file_url} =~ /\.sql$/i) { 
      $output .= qq|<option value="$sl->{file_url}">$sl->{file_title}</option>\n|;
    }
  }
  $output .= "</select>";
  return $output;
}

sub access_database {
  # This replaces the multisite text file with a new default database
  my ($vars) = @_;
  $vars = &clean_vars($vars);

  # Open database info file for writing
  unless ($vars->{cgif}) { print "No cgi directory defined; I won't be able to read the database.<br>"; exit;}
  my $data_file = $vars->{cgif}."data/multisite.txt";
	unless (-e $data_file) { &error("Website information file $data_file does not exist."); }
	unless (open IN,">$data_file") { &error("Cannot open website information file $data_file : $!"); }

  # Write new database information to website information file
  print $vars->{home},"\t",
           $vars->{name},"\t",
           $vars->{loc},"\t",
           $vars->{usr},"\t",
           $vars->{pwd},"\t",
           $vars->{lan},"\t",
           $vars->{urlf},"\t",
           $vars->{cgif},"\n";
  unless(print IN $vars->{home},"\t",
           $vars->{name},"\t",
           $vars->{loc},"\t",
           $vars->{usr},"\t",
           $vars->{pwd},"\t",
           $vars->{lan},"\t",
           $vars->{urlf},"\t",
           $vars->{cgif},"\n") {
    &error("Cannot write to website information file $data_file : $!"); 
  }

  close IN;

}

sub create_database {

  my ($vars) = @_;
  $vars = &clean_vars($vars);
  my $loc = $vars->{loc};
  my $usr = $vars->{usr};
  my $pwd = $vars->{pwd};
  my $name = $vars->{name};
  my $home = $vars->{home};
  my $sql_url = $vars->{sql_url};

  # Create Database
  print "<p>Creating Database</p>";
  my $crdbh = DBI->connect("DBI:mysql:host=$loc;port=3306",$vars->{rootname},$vars->{rootpwd});
  if ($crdbh) {
    print "Successfully connected as root<br>";
  } else {
    &error("Cannot connect to database as root: ".$DBI::errstr,
      "<br>Trying: <br>Location: $loc<br>User:".$vars->{rootname}."<br>Password: ".
      $vars->{rootpwd}.qq|<br>Connection unsuccessful.Check your host location 
      and user information.
      <button onclick="history.back()">Go Back</button>|);
  }

  if ($crdbh->do("create database $name")) {
    print "Successfully created database $name<br>";
  } else {
    &error("Unable to create database $name: ".$DBI::errstr);
  }

  # Add user to database
  if ($crdbh->do("CREATE USER '$usr'\@'%' IDENTIFIED BY '$pwd'")) {
    print "Created user $usr <br>";
  } else { &error("Cannot create db user \n ".$DBI::errstr); }
  
  if ($crdbh->do(qq|GRANT ALL ON $name.* TO '$usr'\@'%'|)) { 
    print "Added user $usr to database $name \n<br>"; 
  } else {
    &error("Cannot grant access to database \n ".$DBI::errstr); 
  }

  $crdbh->do("FLUSH PRIVILEGES");

  # Load the gRSShopper SQL file into the database
  $crdbh->do("use $name") or &error("Cannot use $name database:\n ".$DBI::errstr);
  print "Retrieving SQL from $sql_url <br>";
  $sql_url ||= $sqlfilelocation;
  my $sqlfilelocation = qq|https://mooc.ca/files/grsshopper-base.1.sql|;
  my $sqlfile = get($sql_url);
  unless ($sqlfile) { &error("Could not get SQL file: $!","Filename: $sqlfilelocation"); }
  my @sqlcommands = split ';\n',$sqlfile;
  foreach my $l (@sqlcommands) {
 
    $l =~ s/^\-\-(.*?)\n//g;  # Remove comment
    $l =~ s/^\s*//g;        # remove leading spaces
    #print "$l <br>";
    $crdbh->do($l) or print "Can't execute statement in sql, line $l: ".$DBI::errstr."<p>";
  }
  print "Database $name built<p>";
  

  my @domainarr = split /\./,$home;
  my $cname = shift @domainarr;
  my $server_name = join '.',@domainarr;
  my $base_directory = "/var/www/".$cname."/";

  # If necessary, create file structure
  unless (-e $base_directory) {
    print "$base_directory doesn't exist <br>";
    mkdir($base_directory) or die("Can't create directory \"$base_directory\": $!\n");
    my $rr = `/var/www/html/cgi-bin/update/create.sh $cname`;

  }

  

  &access_database($vars);

  my $url = "https://".$home."/cgi-bin/server_test.cgi";
  # Does this site exist yet?
  use LWP::Simple;
  my $url_test = get $url;


  unless ($widget_test) { 
    print "This site doesn't exist yet"; 
    print "In order to enable it on your server, you need to create a <i>virtual host</i><br>";
    print "Log on to the server as root, go to /var/www/html/cgi-bin/ and enter the command: ./vhost.sh <br>";
    print "(If you get 'permission denied', first enter the command: chmod 755 vhost.sh  )<br>";
    print "Provide the following information when prompted:<p>";
    print "Enter the server name your want (without www) : <b> $server_name </b><br>";
    print "Enter a CNAME (e.g. :www or dev for dev.website.com) :<b> $cname </b><br>";
    print "Enter the path of directory you wanna use:<b> /var/www/ </b><br>";
    print "Enter the user you wanna use :<b> www-data </b><br>";
    print "Enter the listened IP for the server (e.g. : *):<b> * </b><p>";
    print "When this has been done, return here and click on the link below. <p>";
  }


  print qq|New database created. <a href="$url">Click here to access it</a>|;
  exit;
}

sub clean_vars {

  my $vars = shift;
  while (my($vx,$vy)=each %$vars) {
    next if ($vx eq "pwd"); # Don't alter password
    $vars->{$vx} =~ s/\n|\t|&#65533//g;
    $vars->{$vx} =~ s/'//g;
    $vars->{$vx} =~ s/;//g;
  }

  $vars->{loc} =~ s/(http|https):\/\///i; # Strip leading http from loc
  $vars->{loc} =~ s/^\s//;
  $vars->{loc} =~ s/\s$//;  # Remove leading and trailing spaces

  unless ($vars->{urlf} =~ /\/$/) { $vars->{urlf} .= "/"; }
  unless ($vars->{cgif} =~ /\/$/) { $vars->{cgif} .= "/"; }
  return $vars;
}

sub error {
  my ($errorstring,$supplemental) = @_;
    print "<p>$errorstring</p>"; 
    print "<p>$supplemental</p>";
    die "$errorstring"; 
}
1;