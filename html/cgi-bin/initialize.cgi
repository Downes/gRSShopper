#!/usr/bin/env perl
print "Content-type:text/html\n\n";
print "Initializing...<p>";

#-------------------------------------------------------------------------------
#
#	    gRSShopper
#           Initialization Functions - super simple version
#           08 August 2018 - Stephen Downes
#
#-------------------------------------------------------------------------------

# Forbid bots
die "HTTP/1.1 403 Forbidden\n\n403 Forbidden\n" if ($ENV{'HTTP_USER_AGENT'} =~ /bot|slurp|spider/);

# Load gRSShopper
use File::Basename;
use CGI::Carp qw(fatalsToBrowser);
my $dirname = dirname(__FILE__);
require $dirname . "/grsshopper.pl";

# Load modules
our ($query,$vars) = &load_modules("initialize");

# Load Site
our $Site = gRSShopper::Site->new({									# Create new Site object
	no_db		=>	'1',									#   no database
	context		=>	'initialize',
	data_dir	=>	'./data/',
});

if ($vars->{action} eq "multisite") {  &process_initialization_form($vars); }
else { &display_initialization_form($vars);  }

exit;

# -----------------------------------------------------------------------
#  Multisite Form
  #
  #  Form to input values for database access
  #
# -----------------------------------------------------------------------

sub display_initialization_form {

	# Create or update database information
	# to be stored in multisite.txt file

	$Site->{database}->{loc} ||= "localhost";
	my $heading = qq|<tr><td colspan=2><br>|;
	my $row = qq|<tr><td align="right">|;
	my $tab = qq|</td><td>|;
	my $endrow = qq|</td></tr>|;

	print qq|

		<form action="initialize.cgi" method="post">
		<input type="hidden" name="st_host" value="$Site->{st_host}">

		<!-- DB Administrator Info -->
		Please enter database information for $Site->{st_host} <br><br>
		<table cellspacing=1 cellpadding=2 border=0>




		<!-- Database Info -->

		$heading Database Information:<br><br> $endrow

		$row Database Name $tab <input type="text" name="db_name" value="$Site->{database}->{name}"> $endrow
		$row Database Location $tab <input type="text" name="db_loc" value="$Site->{database}->{loc}"> $endrow
		$row Database Username $tab <input type="text" name="db_usr" value="$Site->{database}->{usr}"> $endrow
		$row Database Password $tab <input type="password" name="db_pwd" value="$Site->{database}->{pwd}"> $endrow
		$row Language $tab <input type="text" name="site_language" value="$Site->{site_language}"> $endrow
		$row Site Document Directory $tab <input type="text" name="st_urlf" value="$Site->{st_urlf}"> $endrow
		$row Site CGI Directory $tab <input type="text" name="st_cgif" value="$Site->{st_cgif}"> $endrow

		<!-- Site Info -->

		$heading Site Information:<br><br> $endrow
		$row Site Name $tab <input type="text" name="st_name" value="$Site->{st_name}"> $endrow
		$row Site Tag $tab <input type="text" name="st_tag" value="$Site->{st_tag}"> $endrow
		$row Site Email Address $tab <input type="text" name="st_email" value="$Site->{st_email}"> $endrow
		$row Site Time Zone $tab <input type="text" name="st_timezone" value="$Site->{st_timezone}"> $endrow
		$row License $tab <input type="text" name="st_license" value="$Site->{st_license}"> $endrow
		$row Site Key $tab <input type="text" name="st_key" value="$Site->{st_key}"> $endrow

		<!--  Site Administrator -->

		$heading Site Administrator:<br><br> $endrow
		$row Administrator Username $tab <input type="text" name="site_admin_name"> $endrow
		$row Administrator Password $tab <input type="password" name="site_admin_pwd"> $endrow

		$heading $tab <br><input type="submit" name="action" value="multisite"><br>$endrow

	 	</table><br/><br/><p>
 	 	</form>

  |;  # End of the form printout
}





sub process_initialization_form {

	# All data in is from $vars


	# Restrict input characters if necessary
	if ($vars->{strict}){
		while (my ($vx,$vy) = each %$vars) {
			next if ($vx eq "error");
			next if ($vx eq "warnings");
			if ($vars->{$vx} =~ /[^\/\\\-0-9a-zA-Z_,\0#@&;\.]/) {
				print "Content-type: text/html\n\n";
				print qq|<h1>Input Error in vx: $vars->{$vx} </h1>
					<p>Allowed characters for input: a-zA-Z0-9 # @ & . ; / \</p>
					<p>Please back up and try again.</p>|;
				exit;
			}
		}
	}

	# Convert language input to comma-delimited list
	$vars->{site_language} =~ s/\0/,/i;

	# Standardize dirtectory name input by adding trailing slash
	unless ($vars->{st_urlf} =~ /\/$/) { $vars->{st_urlf} .= "/"; }
	unless ($vars->{st_cgif} =~ /\/$/) { $vars->{st_cgif} .= "/"; }

	# Open the multisite configuration file,
	# Initialize if file can't be found or opened
	# my $data_directory = 	$vars->{st_cgif}."data/";   # Not ideal because I prefer to allow people to choose alternative locations
  my $data_directory = "./data";
	my $data_file =  $data_directory . "/multisite.txt";			# I want to make this changeable
	my $new_data_file = "";

  # Check for the data firectory
  if (-d $data_directory) {
		# If the multisite configuration file exists, open it, and recreate it
		if (-e $data_file) {
	  	open IN,"$data_file" or die "Can't open $data_file to read";
			my $url_located = 0;
			while (<IN>) {
				my $line = $_;
				unless ($line =~ /^$Site->{st_host}/) { $new_data_file .= $line; }
			}
			close IN;
		}
	} else {   #data directory doesn't exist, create it
		mkdir $data_directory;
	}

 	# Make Document Directories
	unless (-d $vars->{st_urlf}) { mkdir $vars->{st_urlf} or die "Could not make the document directory $vars->{st_urlf}  $!"; }
	unless (-d $vars->{st_urlf}) { die "Error making the document directory $vars->{st_urlf}  $!"; }
	foreach my $subdir (qw(archive assets files images logs stats)) {
		mkdir($vars->{st_urlf}.$subdir."/");
		unless (-d $vars->{st_urlf}.$subdir."/") {
			die "Error making subdirectory ".$vars->{st_urlf}.$subdir."/ $!";
		}
	}


	# Write new site data to multisite configuration file
	my $new_data_file .= qq|$Site->{st_host}\t$vars->{db_name}\t$vars->{db_loc}\t$vars->{db_usr}\t$vars->{db_pwd}\t$vars->{site_language}\t$vars->{st_urlf}\t$vars->{st_cgif}\n| or die "Cannot write to $data_file";
	open OUT,">$data_file" or die "Cannot open $data_file: $!";
	print OUT $new_data_file or die "Cannot save to $data_file: $!";
	close OUT;

  # At this point, if the database has already been created, the site should be ready to load.

	# Try connecting to the database
	$Site->__dbinfo();
	$Site->__db_connect({initialize => "new"});
	our $dbh = $Site->{dbh};

	# Write Config (Stores general site information, can be edited later by admin)
	$vars->{st_pub} = $vars->{st_email};
	$vars->{st_crea} = $vars->{st_email};
	$vars->{reset_key} = $vars->{st_key};
	$vars->{cronkey} = $vars->{st_key};
	my @configs = qw(st_name st_tag st_pub st_crea st_license st_timezone reset_key cronkey);
	foreach $config (@configs) {
	   &db_insert($dbh,"","config",{config_noun=>$config,config_value=>$vars->{$config}})
		 		or print "Error inserting $config -- $vars->{err}";
	}

	# Create Admin and anon Accounts
	# Note: windows users must perform this step manually
	my $site_admin_name = $vars->{site_admin_name};
	my $encryptedPsw = &encryptingPsw($vars->{site_admin_pwd}, 4);
	# Delete previous user with this username, if they exist
	my $admin_user_id = &db_locate($dbh,"person",{person_title => $site_admin_name});
	if ($admin_user_id) { &db_delete($dbh,"person","person_id",$admin_user_id); }
	my $id_number = &db_insert($dbh,"","person",{person_title=>$site_admin_name,person_password=>$encryptedPsw,person_status=>"admin"});
#	if ($id_number) { print qq|Created Site Administrator - <a href="admin.cgi">click here to login</a><p>|; }
#	else { print qq|error creating admin user.|; }

	print "<p>Done.</p><p>";
	print qq|[<a href="$Site->{st_cgi}login.cgi?action=login_text">Log in to your new gRSShopper PLE</a>]<br>|;
	print qq|[<a href="$Site->{st_cgi}initialize.cgi?action=file">Run this initialization script again</a>]</p>|;
	exit;

}
