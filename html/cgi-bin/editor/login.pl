	#   -------------------------------------------------------------------------------------
	#
	#   LOGIN FUNCTIONS
	#   Added 13 September 2020 while putting gRSShopper into containers
	#
	#   -------------------------------------------------------------------------------------

	# Checks for logout, initializes session, writes cookie
sub check_user {

#print "Content-type: text/html\n\n";
#print "<h2>Check User</h2><p>";
	my ($output_format) = @_;
    my $session = new CGI::Session(undef, $query, {Directory=>'/tmp'});
    $session->expires("+1y");
#print "Vars in check_user<p>";
#while (my($vx,$vy) = each %$vars) { print "$vx = $vy <br>";}


	# Logout
    if ($query->param("action") eq "logout") {

		$session->delete();
        print $query->header();
        print qq|Logged Out. <a href="//|.$ENV{'SERVER_NAME'}.$ENV{'SCRIPT_NAME'}.qq|">Login</a>
		<script>window.scrollTo(0,document.body.scrollHeight);
		</script>|;
        exit;
    } 

	# Create user
	if ($query->param("action") eq "new") {
		print $query->header();
		print &show_login($session);
		exit;
	}

	if ($query->param("action") eq "Create a New Profile") { 
			&_make_profile();     # Make a new profile if asked
	}

	#   $session->clear(["~logged-in"]);
#print "Into init_login()<p>";	
    &init_login($session);


#print "Back from init_login()";
#print " Going to print my cookie for the session ".$session->id."<p>";
    my $cookie = CGI::Cookie->new(CGISESSID => $session->id);


  #  my $cookie = $query->cookie(-name=>fCGISESSID,
#	    -value=>$session->id,
#	    -expires=>"Wed, 22 Oct 2025 07:28:00 GMT",
#	    -secure=>1);

	$output_format ||= "text/html";	# default mime type
    unless ($Site->{context} eq "cron" || $Site->{context} eq "rcomment") {
		print $query->header(-type => $output_format,-cookie=>$cookie,-charset => 'utf-8');
	}

   
#print "Content-type: text/html\n\n OK";
    my $profile = $session->param("~profile");
    my $username = $profile->{username};
 #print "Just printed the cookie<p>";  
 # print "Returning session $session and username $username <p>";
 
    return($session,$username);


}


	# Returns user name if logged in, login form otherwise
	# Use in iframe on web pages 
sub show_login {

    my $session = shift;
	my $reload_script = qq|	document.addEventListener('readystatechange', event => { 
    if (event.target.readyState === "interactive") {   
     //   alert("Success");
	 //	alert(window.parent.location.href);
		parent.location.reload();
	}});|;  # Reloads parent page in event of login or logout

    # Logged In
    if (($session->param("~logged-in")) && ($query->param("new") eq "")) { 
		my $reload = "";
		if ($session->param("~reload")) {
			$reload = $reload_script;
			$session->param("~reload",0);
		}
        return "".$session->param("~profile")->{username}.
			qq| [<a href="//|.$ENV{'SERVER_NAME'}.$ENV{'SCRIPT_NAME'}.qq|?action=logout">Logout</a>]
			[<a href="//|.$ENV{'SERVER_NAME'}.$ENV{'SCRIPT_NAME'}.qq|?action=new&new=user">Create New User</a>]
			<p>
		<script>window.scrollTo(0,document.body.scrollHeight);
		$reload
		</script>|;
    } 

    # Not Logged In
    else {
    
  #  &list_all_rows();
  #  &delete_all_rows();
  
  
    
    	my $count = &db_count($dbh,"person"); my $extra;
	if ($count == 0) { $count = "Create an Admin Profile"; } 
	elsif ($query->param("new")) { 
		#$query->param("new") = "";	# Clear param
		$count = "Create a New Profile"; 
		$extra = qq|<input type=text placeholder="Email" name="lg_email">|;
	}
	else { $count = "Login"; } 
	
        return qq|
        <form method="post" action="//$ENV{'SERVER_NAME'}$ENV{'SCRIPT_NAME'}">
        <input type=text placeholder="Username" name="lg_name">
	$extra
        <input type=password placeholder="Password" name="lg_password">
        <input type="submit" name="action" value ="$count"  >
        </form>
		<script>window.scrollTo(0,document.body.scrollHeight);</script>
        |;
    }
}



	# Initializes session and loads profile if new login
sub init_login {
    my $session = shift;
#print "Content-type: text/html\n\n";	
#print "In init_login() <br>";
#print $session->dump();

    if ( $session->param("~logged-in") ) {
#print "yes, logged in <br>";  
#print "Login name (from form): ".$query->param("lg_name")."<p>";   
        return 1;  # if logged in, don't bother going further
    }

	
#print "Not logged in <brp>"; 
#print "Login name (from form): ".$query->param("lg_name")."<p>";

    my $lg_name =  $query->param("lg_name") or return;
    my $lg_psswd = $query->param("lg_password") or return;




    # if we came this far, user did submit the login form
    # so let's try to load his/her profile if name/psswds match
  
#print "About to load profile for $lg_name with password $lg_passwd<p>";
       
    if ( my $profile = _load_profile($lg_name, $lg_psswd,$output_format) ) {     
        $session->param("~profile", $profile);
        $session->param("~logged-in", 1);
		$session->param("~reload", 1);
        $session->clear(["~login-trials"]);
#print "Got the profile, $profile and loaded it into the session $session <p>";
        return 1;
    }
    

 
    # if we came this far, the login/psswds do not match
    # the entries in the database
#print "The login/passwds do not match<p>";	
    my $trials = $session->param("~login-trials") || 0;
    return $session->param("~login-trials", ++$trials);
}


	# Check password, Load profile from profiles file on new login
sub _load_profile {
    my ($lg_name, $lg_psswd,$output_format) = @_;
    my $cgi = $query;
#print "Loading profile <p>";

    my $persondata = &db_get_record($dbh,"person",{person_title=>$lg_name});		# Load a profile
    
    unless ($persondata) {		                   # User does not exist
    	my $count = &db_count($dbh,"person");
    	if ($query->param("action") eq "Create an Admin Profile" && $count == 0) { &_make_profile("admin"); }    # Make a new one if asked
        print "Content-type: text/html\n\n";               # Or exit
        print "User does not exist. $count users exist";
        exit;
    }
							# User Exists, Check Password
#print "Checking password<p>";							
    if (&_check_password($lg_psswd,$persondata->{person_password})) {
       my $p_mask = "x" . length($p);
#print "Password OK, returning ".$persondata->{person_title}."<p>";       
       return {username=>$persondata->{person_title}, password=>$p_mask, email=>$persondata->{person_email}};
    }

    exit;   # Failed password, script exits in check_password()
}


	# Create a new profile and store it in the profiles file
sub _make_profile {


	my $cgi = $query;
	my $status = shift;
	print $cgi->header();
	print "Working <p>";
	$query->param(action => ''); # Clear action param
 
	
	# Security Functions
	# Captcha, Email verification, etc. will go here
	
	# Check for username and password
	unless ($cgi->param("lg_name") && $cgi->param("lg_password")) { 
		print "New account must have both a user name and a password."; 
		print qq|<script>window.scrollTo(0,document.body.scrollHeight);</script>|;
		exit;
	}
	
	# Check for unique username
	my $persondata = &db_get_record($dbh,"person",{person_title=>$cgi->param("lg_name")});
	if ($persondata) { 
		print "This user name is already in use."; 
		print qq|<script>window.scrollTo(0,document.body.scrollHeight);</script>|;
		exit;
	}
	    
	# Check in case this is the first user, which must be Admin
	my $count = &db_count($dbh,"person");
	if ($count == 0) { $count = "Admin"; } else { $count = "Registered"; }
	print "<p>Making $count Profile</p>"; 
	
	# Encrypt password
	my $encr_pass = &_encrypt_password($cgi->param("lg_password"));

	# Create record in database
	my $userid = &db_insert($dbh,$query,"person",{
		person_title => $cgi->param("lg_name") ,
		person_password => $encr_pass,
		person_status => $status,
		person_email => $cgi->param("email")
		});
	
#print "<p>Name".$cgi->param("lg_name")."<p>";
#print "<p>Pass".$cgi->param("lg_password")."<p>";
#print "<p>Encr".$encr_pass."<p>";

	if ($userid) { print qq|<p>Profile made. Now you can <a href="//$ENV{'SERVER_NAME'}$ENV{'SCRIPT_NAME'}">login</a></p>
	<script>window.scrollTo(0,document.body.scrollHeight);</script>|; }
	else { print qq|Failed to create profile; I have no idea why.|; }
	
	exit;

exit;

}

	# Encrypt a password 
sub _encrypt_password {

	my $encryption_scheme;

#       use local::lib; # sets up a local lib at ~/perl5
	
    #sudo apt-get install libcrypt-eksblowfish-perl
    # use Crypt::Eksblowfish::Bcrypt qw(bcrypt_hash);
	if (&new_module_load($query,"Crypt::Eksblowfish::Bcrypt")) { $encryption_scheme="blowfish";}
	else { die "Can't find an encryption scheme: $?"; }
    my $password = shift;

    # Generate a salt if one is not passed
    my $salt = shift || &_salt(); 

    # Encrypt the password 
    my $hash = Crypt::Eksblowfish::Bcrypt::bcrypt_hash({ key_nul => 1, cost => 8, salt => $salt, }, $password);

    # Return the salt and the encrypted password
    return join('-', $salt, Crypt::Eksblowfish::Bcrypt::en_base64($hash));
}

	# Check if the passwords match
sub _check_password {
    my ($plain_password, $hashed_password) = @_;
    my ($salt) = split('-', $hashed_password, 2);
    my $test = &_encrypt_password($plain_password, $salt);
    
        unless ($test eq $hashed_password) {
        print "Content-type: text/html\n\n";
        print "Invalid Login";
        exit;
    }
    return length $salt == 16 && &_encrypt_password($plain_password, $salt) eq $hashed_password;
}

	# generate a 16 octet more-or-less random salt for blowfish
sub _salt {
    my $itoa64 = "./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    my $salt = '';
    $salt .= substr($itoa64,int(rand(64)),1) while length($salt) < 16;
    return $salt;
}



	# Login stuff below this line is legacy and will be removed

	#   -------------------------------------------------------------------------------------
	#
	#   encryptions and salts
	#
	#   -------------------------------------------------------------------------------------
sub encryptingPsw {
	my $psw = shift;
	my $count = shift;
	my @salt = ('.', '/', 'a'..'z', 'A'..'Z', '0'..'9');
	my $salt = "";
	$salt.= $salt[rand(63)] foreach(1..$count);
	my $encrypted = crypt($psw, $salt);
	return $encrypted;
}
sub generate_random_string {
  my $count = shift;
  my @salt = ('-','/', 'a'..'z', 'A'..'Z', '0'..'9');
  my $salt = "";
  $salt.= $salt[rand(63)] foreach(1..$count);
  return $salt;
}
 #
#

sub random_password {

	my $password;
	my $_rand;

	my $password_length = $_[0];
	if (!$password_length) {
		$password_length = 10;
	}

	my @chars = split(" ",
		"a b c d e f g h i j k l m n o
		p q r s t u v w x y z - _ % # |
		0 1 2 3 4 5 6 7 8 9");

	srand;

	for (my $i=0; $i <= $password_length ;$i++) {
		$_rand = int(rand 41);
		$password .= $chars[$_rand];
	}
	return $password;
}


#-------------------------------------------------------------------------------
#
#     PERMISSION SYSTEM
#
#-------------------------------------------------------------------------------

	# -------   Admin Only ---------------------------------------------------------
	#
	# Restrict to admin only

sub admin_only {

  # if ($Person->{person_title} eq "Downes") { $Person->{person_status} = "admin" }
  #
#print "Status: ". $Person->{person_status}."<p>";
	unless ($Person->{person_status} =~ /^admin$/i) {	 &login_needed("Admin"); 	}
}

	# -------   Registered Only ---------------------------------------------------------
	# Restrict to registered users only
sub registered_only {

	unless (($Person->{person_status} eq "registered")
			 || ($Person->{person_status} eq "Admin")) {&login_needed(""); 
	}
}

	# -------   is Viewable - Permissions System------------------------------------------
	# Will return 0 if triggered, 1 if allowed
sub is_viewable {

	my ($action,$table,$object) = @_;
	return 1 if (&check_status($action,$table,$object));
	return 0;

}

	# -------   is Allowed - Permissions System-------------------------------------------
	# Will punt you with an error if triggered, returns 1 if allowed
sub is_allowed {

	my ($action,$table,$object,$place,$api) = @_;
	return 1 if (&check_status($action,$table,$object));
	return 0;

}

	#-------------------------------------------------------------------------------
	#
	# -------   Check Status -------------------------------------------------------
	#
	#           Check the status of the requested user and action
	#		Restrict to proper status only
	#		May use $object address to examine ownership info
	#
	#	      Edited: 3 July 2012
	#-------------------------------------------------------------------------------
sub check_status {

	my ($action,$table,$object) = @_;

							# Verify Site information and
							# Always allow views of templates, boxes, views

	unless ($Site) { &error($dbh,"","",&printlang("Site info not found in check_status","check_status")); }
	return 1 if ($action eq "view" && ( $table =~ /view|box|template/i ));
	return 1 if (lc($Person->{person_status}) eq "admin");	# Admin always has permission
	return 1 if ($Site->{cron} );				# Always allow cron
	return 1 if ($Site->{permission} eq "initialize");		# Lets us do things to initialize



							# Read permision data from site information

	my $req = &permission_current($action,$table,$object);


  #	Diagnostic
  #	print "$action _ $table :  $req <br>";

							# Return 0 if nobody can do this (hides features) and
							# Return 1 if everybody can do this

	return 0 if ($req eq "none");
	return 1 if ($req eq "anyone");

							# Get User Status
	my $status = lc($Person->{person_status});
	my $project = lc($Person->{project});
	my $pid = $Person->{person_id};



  #	Diagnostic
  #	print "Person: $pid <br>Status: $status <br>Project: $project <br>";



							# If requirement is 'registered'
							# Return 1 if $pid > 2

	if ($req eq "registered") { return 1 if ($pid > 2); }

							# The next set requires that we look at the object.

	if ($object) {

							# If requirement is 'owner' or 'project'
							# Return 1 if person is the object creator

		my $ownf = $table."_creator";
 		if (($req eq "owner") || ($req eq "project")) {
			return 1 if ($object->{$ownf} eq $pid);
		}

							# If requirement is 'project'
							# Return 1 if person is in the project
		my $prof = $table."_project";
		if ($req eq "project") {
  # Needs to be created
		}

	} else {
		#&error($dbh,"","","Object information not found in check_status()");
	}

	return 0;
}

	#-------------------------------------------------------------------------------
	#
	# -------   Current Pernmission -------------------------------------------------------
	#
	#           Permission for action on table
	#
	#	    Edited: 3 July 2012
	#-------------------------------------------------------------------------------
sub permission_current {

	my ($action,$table,$object) = @_;

	my $req = lc($Site->{$action."_".$table});
	unless ($req) { $req = &permission_default($action,$table,$object); }

	return $req;


}

	#-------------------------------------------------------------------------------
	#
	# -------   Default Pernmission -------------------------------------------------------
	#
	#           Hard-coded Deafult Permission in Case db version not available
	#
	#	    Edited: 3 July 2012
	#-------------------------------------------------------------------------------
sub permission_default {

	my ($action,$table,$object) = @_;

	if ($action eq "view")  {
		if ($table =~ /config|mapping|optlist/) { return "admin"; }
		if ($table =~ /person/) { return "owner"; }
		else { return "anyone"; }
	}
	elsif ($action eq "admin") { return "admin"; }
	elsif ($action eq "delete")  { return "admin"; }
	elsif ($action eq "create")  {
		if ($table =~ /post|feed/) { return "registered"; }
		else { return "admin"; }
	}
	elsif ($action eq "edit")  {
		if ($table =~ /post|feed|person/) { return "owner"; }
		else { return "admin"; }
	}
	elsif ($action eq "publish")  {
		return "admin";
	} else {
		return "anyone";
		#die "Nonstandard permission request: $action,$table,$object ";
	}

}

#
sub login_needed {

	my ($status) = @_;

	print "Content-type: text/html\n";
	if ($status =~ /^admin$/i) { print "You must be an admin to continue.";  } else {
	print "A login is needed to continue."; }
	if ($dbh) { $dbh->disconnect; }
	exit;
}
 #
 #
sub show_environment {

	my $env_values;
	while (my($x,$y) = each %ENV) {
		$env_values.= "$x = $y \n";
	}
	return $env_values;


}

1;
