#!/usr/bin/perl

#    gRSShopper 0.7  Login  0.6  -- gRSShopper login module
#    26 April 2017 - Stephen Downes

#    Copyright (C) <2012>  <Stephen Downes, National Research Council Canada>
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


# Forbid bots

	die "HTTP/1.1 403 Forbidden\n\n403 Forbidden\n" if ($ENV{'HTTP_USER_AGENT'} =~ /bot|slurp|spider/);

# Load gRSShopper

	use File::Basename;
	use CGI::Carp qw(fatalsToBrowser);
	my $dirname = dirname(__FILE__);
	require $dirname . "/grsshopper.pl";

# Load modules

	our ($query,$vars) = &load_modules("login");

# Load Site

	our ($Site,$dbh) = &get_site("login");
	if ($vars->{context} eq "cron") { $Site->{context} = "cron"; }

# Get Person  (still need to make this an object)

	our $Person = {}; bless $Person;
	&get_person($dbh,$query,$Person);
	my $person_id = $Person->{person_id};

# Initialize system variables

	my $options = {}; bless $options;
	our $cache = {}; bless $cache;





if ($vars->{refer}) { $vars->{refer} = encode_entities($vars->{refer} );} 			# Encode refer to prevent XSS
our $target; if ($vars->{target}) { $target = $vars->{target}; }


# Initialize OpenID

if (&new_module_load($query,"Net::OpenID::Consumer")) { $vars->{openid_enabled} = 1; }





# TEMPORARY
#
# Logging requests for diagnostics
#
my $sq = "";
#while (my ($lx,$ly) = each %$vars) { $sq .= "\t$lx = $ly\n"; }
#open POUT,">>/var/www/cgi-bin/logs/login_access_log.txt" || print "Error opening log: $! <p>";
#print POUT "\n$ENV{'REMOTE_ADDR'}\t$vars->{action}\n$sq"
#	 || print "Error printing to log: $! <p>";
#close POUT;



	my $record->{page_content} = &db_get_template($dbh,"page_header","Login");
	&format_content($dbh,$query,$options,$record);
	$Site->{header} = $record->{page_content};

	my $record->{page_content} = &db_get_template($dbh,"page_footer","Login");
	&format_content($dbh,$query,$options,$record);
	$Site->{footer} = $record->{page_content};



$vars->{openid_enabled} = 0;

unless ($vars->{action}) {  	# Redirect ordinary users to subscribe.htm
 print "Content-type: text.html\n";
 print "Location: ".$Site->{st_url}."subscribe.htm\n\n";
                     exit;
 }


for ($vars->{action}) {

	/login_form/ && do { &login_form_text($dbh,$vars); last; };
	/Login/ && do { &login_form_input($dbh,$query); last; 					};
	/Logout/ && do { &user_logout($dbh,$query); last;						};
	/openidloginform/ && do { &openid_login_form($dbh,$query); last; 			};
	/OpenID/ && do { &openidq($dbh,$query); exit;						};

	/Register/ && do { &registration_form_text($dbh,$query); last;	 				};
	/New/ && do { &new_user($dbh,$query); last;	 					};
	/newAnonGoogle/ && do { &new_anon_google($dbh,$query); last;	 					};
	/RegGoogleUser/ && do { &reg_google_user($dbh,$query); last;	 					};
	/Remove/ && do { &remove_user($dbh,$query); last; 			};
	/Email/ && do { &email_password($dbh,$query); last;	 					};
	/Send/ && do { &send_password($dbh,$query); last;	 					};
	/reset/ && do { &reset_password($dbh,$query); last;	 					};
	/changepwdscr/ && do { &change_password_screen($dbh,$query); last;	 					};
	/changepwdinp/ && do { &change_password_input($dbh,$query); last;	 					};
	/Subscribe/ && do { &subscribe($dbh,$query); last;						};
	/Unsub/ && do { &unsubscribe($dbh,$query); last; 					};
	/Options/ && do { &options($dbh,$query); last;						};
	/form_socialnet/ && do { &form_socialnet($dbh,$query); last;						};
	/update_socialnet/ && do { &update_socialnet($dbh,$query); last;						};
	/EditInfo/ && do { &edit_info($dbh,$query); last;						};
	/edit_info_in/ && do { &edit_info_in($dbh,$query);
		&edit_info($dbh,$query); last;		};
	/add/ && do { &add_subscription($dbh,$query);
		&subscribe($dbh,$query); last;	};

	&choose_page($dbh,$vars,$query); last;
}



if ($dbh) { $dbh->disconnect; }			# Close Database and Exit
exit;

#-------------------------------------------------------------------------------
#
#           Functions
#
#-------------------------------------------------------------------------------

sub choose_page {
	my ($dbh,$vars,$query) = @_;
	&login_form_text($dbh,$vars);
	exit;

	if ($Person->{person_status} ne "anonymous") {
		print "Content-Type: text/html; charset=utf-8\n\n";
		&show_connected_page($dbh, $query);
	} else {
		&login_form_text($dbh,$vars);
	}
}

# -------   Header ------------------------------------------------------------

sub header {

	my ($dbh,$query,$table,$format,$title) = @_;
	my $template = "page_header";

	return &template($dbh,$query,$template,$title);


}

# -------   Footer -----------------------------------------------------------

sub footer {

	my ($dbh,$query,$table,$format,$title) = @_;
	my $template = "page_footer";
	return &template($dbh,$query,$template,$title);

}


# -------  Make Admin Links -------------------------------------------------------
#


sub make_admin_links {

	my ($input) = @_;



}




# --------  Login Form Text ----------------------------------------------------

sub login_form_text {

	my ($dbh,$vars) = @_;

							# Define redirects
	my $target; my $targa;
	if ($vars->{target}) {
		$target = qq|<input type="hidden" name="target" value="$vars->{target}">|;
		$targa = qq|&target=$vars->{target}|;
	}

	my $refer; my $refa;
	if ($vars->{refer}) {
		$refer = qq|<input type="hidden" name="refer" value="$vars->{refer}">|;
		$refa = qq|&refer=$vars->{refer}|;
	}

	#my $returntourl = $Site->{st_url} . "cgi-bin/login.cgi?action=newAnonGoogle&refer=$vars->{refer}";
	my $googleloginurl = $Site->{st_url} . "cgi-bin/googleLogin.cgi";

							# Page header

	my $pagetitle = &printlang("Login",$newsletter);
	$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;
	print "Content-type: text/html; charset=utf-8\n\n";

							# Page body

#	print $Site->{header};
	print qq|<div id="grey-box-wrapper" class="rounded-whitebox"><h2>$pagetitle</h2><p>$vars->{msg}</p>|;


	############################
	# Temporary, until I organize this better
	#if ($Site->{st_openid_on} eq "yes") {	print qq|
	#		<p><a href='$Site->{script}?refer=$vars->{refer}&action=openidloginform'>
	#		@{[&printlang("Login OpenID")]}</a>
	#		(<i><a href="$Site->{st_url}openid.htm">About OpenID on $Site->{st_name}</a></i>)
	#		</p>|;
	#}

	#if ($Site->{st_google_on} eq "yes") {	print qq|
	#		<p><a href='$Site->{script}?refer=$vars->{refer}&action=openidloginform'>
	#		@{[&printlang("Login Google")]}</a>
	#		(<i><a href="$Site->{st_url}openid.htm">About OpenID on $Site->{st_name}</a></i>)
	#		</p>|;
	#}
	#############################




	print qq|

		<form method='post' action='$Site->{script}' class="grss-skin">
                <h3>$Site->{st_name}</h3>
	      	<p><label>@{[&printlang("Enter your name")]}</label>
		<input name='person_title' type='text' size=40></p>
		<p><label>@{[&printlang("Enter your password")]}</label>
		<input name='person_password' type='password' size=40></p>
		<p id="remember-me"><input type='checkbox' name='remember' value='yes' checked>
		@{[&printlang("Remember me")]}</p>
      		<p>
		<input type='hidden' name='action' value='Login'>
		$refer
		$target
      		<input type='submit' value='@{[&printlang("Login")]}'> |;

        if ($Site->{st_google_on} eq "yes") {
         	print qq|
      		<span class="google-login">@{[&printlang("Or login with")]}
     		<a href="$googleloginurl"> <img src="|.$Site->{st_url}.qq|/images/googleId.png"></a></span>|;
	}

        print qq|
      		</p><div class="dashed-divider"><p class="link-box">
		<a href='$Site->{script}?action=Register$refa$targa'>
     		@{[&printlang("Create account")]}</a><br/>
		<a href='$Site->{script}?action=Email$refa$targa'>
      		@{[&printlang("Forgot password")]}</a></p></div><p id="login-note">@{[&printlang("You Agree")]}</p></form></div>|;


#	print $Site->{footer};
	return;
}

# --------  OpenID Login Form ----------------------------------------------------

sub openid_login_form {

	my ($dbh,$query) = @_;
	my $vars = $query->Vars;

	$Site->{header} =~ s/\Q[*page_title*]\E/Login Using OpenID/g;

	print "Content-type: text/html; charset=utf-8\n\n";
	print $Site->{header};

	if ($vars->{openid_enabled}) {
		print qq|<h4>Login Using OpenID</h4>

		<form method="post" action="$Site->{script}" class="grss-skin">
		<input type="hidden" name="action" value="OpenID">
		<input type="hidden" name="refer" value="$vars->{refer}">
		<nobr><b>Your OpenID URL:</b> <input class="sexy" id="openid_url" name="openid_url" size="30" />
<input type="submit" value="@{[&printlang("Connexion")]}" /></nobr><br />For example: <tt>melody.someblog.com</tt> (if your host supports OpenID)</form>

	      	<p><a href="$Site->{st_url}openid.htm">About OpenID on $Site->{st_name}</a></p>
		|;
	} else {
		print qq|<h4>Login Using OpenID</h4>
		<p>OpenID is not enabled on this website.
		Ask the site administrator to load
		Net::OpenID::Consumer if you would like to use it.</p>|;
	}


	print $Site->{footer};
	return;
}

# --------  Registration Form Text -------------------------------------------------

sub registration_form_text {
	my ($dbh,$query) = @_;




							# Define redirects

								my $target; my $targa;
	if ($vars->{target}) {
		$target = qq|<input type="hidden" name="target" value="$vars->{target}">|;
		$targa = qq|&target=$vars->{target}|;
	}

	my $refer; my $refa;
	if ($vars->{refer}) {
		$refer = qq|<input type="hidden" name="refer" value="$vars->{refer}">|;
		$refa = qq|&refer=$vars->{refer}|;
	}


							# Page header

	my $pagetitle = &printlang("Create account",$newsletter);
	$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;
	print "Content-type: text/html; charset=utf-8\n\n";

	$Site->{header} =~ s/\Q[*page_title*]\E/pagetitle/g;
	print $Site->{header};
	my $script = $Site->{script};

	print	qq|	<div id="grey-box-wrapper" class="rounded-whitebox">
			<form method='post' action='$script' class="grss-skin">
                        <h2>$pagetitle</h2>
                        <h3>@{[&printlang("Register and subscribe")]}</h3>
			<input type='hidden' name='action' value='New'>
			$refer
			$target|;



      	if ($Site->{st_reg_on} eq "yes") {			# Accepting Registrations? (st_reg_on = yes)



		$Person->{person_id} = 0;				# Set up statements
		my $login_text = qq|<box Privacy Statement>
				    <box Cookies Statement>
				    <box Research Statement>|;

									# Set up captcha
		my $captchas = ""; my $capt_text = "";
	   	if ($Site->{st_capcha_on} eq "yes") {			# Using capchas? (st_capcha_on = yes)

			if ($captchas = &get_captcha_table()) {
				my @capkeys = keys %$captchas;
				my $caplen = scalar @capkeys;
				my $cap_sel = rand($caplen);

				$capt_text =  qq|<div id="captcha">
					<p><label>@{[&printlang("Enter capcha text")]}</label>
					<img src="$Site->{st_url}images/captchas/|.
					@capkeys[$cap_sel].qq|.jpg" alt="|.@capkeys[$cap_sel].
					qq|"><input type='hidden' name='captcha_index' value='|.
					@capkeys[$cap_sel].qq|'>
					<span id="captcha-wrapper">
					<label>@{[&printlang("Enter capcha text")]}</label>
					<input type='text' size="10" name='captcha_submit'>
					</span></p></div>|;
			} else {
				$vars->{msg} .= @{[&printlang("Captcha table not found")]}.": ". $Site->{data_dir}."captcha_table.txt";
			}
		}

		if ($vars->{msg}) { $login_text .= qq|<p class="notice">$vars->{msg}</p>|; }
		$login_text .= qq|
			<p><label>@{[&printlang("Enter your name")]} </label> <input name='person_title' type='text' size=20></p>
			<p><label>@{[&printlang("Enter your password")]}</label> <input name='person_password' type='password' size=20></p>
			<p><label>@{[&printlang("Enter your email")]}</label><input name='person_email' type='text' size='40'></p>|;

		$login_text .=  &subscription_form_text($dbh,$query);

		$login_text .= qq|
			<p><label class="how-found">@{[&printlang("How found")]}</label>
			<textarea name="source" cols=60 rows=7></textarea></p>


			$capt_text
			<p><input type='submit' value='@{[&printlang("Click here")]}'></p>|;


      	 	&make_boxes($dbh,\$login_text,"silent");
      	 	&make_site_info(\$login_text);

      	 	print $login_text;

      	} else {						# Not Accepting Registrations (st_reg_on = no)

      		print qq|<p>@{[&printlang("Site not open")]}</p>|;

	}

	print "</form></div>";
	print $Site->{footer};
	return;
}

sub reg_google_user {
	my ($dbh,$query) = @_; my $table = 'person';
	my $vars = $query->Vars;



	unless ( ($vars->{person_title}) &&	# Verify Input
		  ($vars->{person_email})) {
		&login_error("nil",$query,"", "You must provide your name, and email address."); }

							# Captcha Test
	my $captchas;
	if ($captchas = &get_captcha_table()) {
		unless ( $vars->{captcha_submit} eq $captchas->{$vars->{captcha_index}}) {
			&login_error("nil",$query,"", "Incorrect Captcha.");
		}
	} else {
		$vars->{msg} .= "The Captcha table not found.";
	}


	my ($to) = $vars->{person_email};	# Check email address
	if ($to =~ m/[^0-9a-zA-Z.\-_@]/) {
		&login_error("nil",$query,"","Bad Email");
	}

						# Unique Email

	if (&db_locate($dbh,"person",{person_email => $vars->{person_email}}) ) {
		&login_error($dbh,$query,"","Someone or something else is using this email address.");
		};

						# Unique Name
	if (&db_locate($dbh,"person",{person_title => $vars->{person_title}}) ) {
		&login_error($dbh,$query,"","Someone else named '$vars->{person_title}' has already registered."); };

	# Unique openid
	if (&db_locate($dbh,"person",{person_openid => $vars->{person_openid}}) ) {
		&login_error($dbh,$query,"","It appears you already registered your Google OpenID - it already exists");
	};

						# Spam Checking
	if ($vars->{person_email} =~ /\.ru$/i) {
		&login_error($dbh,$query,"","Due to spam, Russian registrations must contact me personally by email."); };
	if ($vars->{source} =~ /test,|just a|for all|for every/i) {
		&login_error($dbh,$query,"","Leave my website alone and go away."); };
	if ($vars->{person_title} =~ /youtube|blog /i) {
		&login_error($dbh,$query,"","Obviously a spam. Go away."); };


						# Create the User Record
	my $idname = $table."_id";
	my $idval = 'new';
	$vars->{person_crdate} = time;
	$vars->{person_status} = "reg";
	$vars->{person_source}=	$vars->{source};
	$vars->{key} = &db_insert($dbh,$query,$table,$vars,$idval);
	unless ($vars->{key}) {
		&login_error($dbh,$query,"","Error, no new account was created.");
	}
	$Person->{person_id} = $vars->{key};
	$vars->{person_password} = $saved_password;

						# Newsletter Subscriptions
	&add_subscription($dbh,$query,$vars->{key});

	# Send email to user
	my $subj = "Welcome to ".$Site->{st_name};
	my $pagetext = qq|<html><head></head><body><p>

Welcome to $Site->{st_name}. It is nice to have you aboard.</p><p>

This email confirms your new user registration. Please save it in a safe place. In order to post comments on the website, you will need to login with your userid and password.
</p><p>
   Site address: $Site->{st_url}<br />
   Your userid is: $vars->{person_title}</p><p>

Should you forget your userid and password, you can always have them sent to you at this email address.
To recover missing login infromation, go here: $Site->{st_cgi}login.cgi?refer=&action=Email</p><p>

   -- $Site->{st_crea}</p></body></html>
	|;



	# Log Data
#	my $new_user_file = $Site->{st_cgif}."logs/".$Site->{st_tag}."_new_users.txt";
#	if (-e $new_user_file) {
#		open NUOUT,">>$new_user_file" or &login_error($dbh,"","","Can't Create Log $new_user_file : $!");
#	} else {
#		open NUOUT,">$new_user_file" or &login_error($dbh,"","","Can't Open Log $new_user_file : $!");
#	}
#	print NUOUT "$vars->{person_title}\t$vars->{person_email}\t$vars->{source}\n" or &login_error($dbh,"","","Can't Print to Log $new_user_file : $!");;
#	close NUOUT;


        my $subj = "Bienvenue &agrave; votre Cours en Ligne Ouvert et Massif portant sur les REL";
        $subj =~ s/&#39;/'/g;
        my $pagetext = &db_get_content($dbh,"box", "bienvenuemisemarcher");
        $page_text =~ s/<vars_person_title>/$vars->{person_title}/g;


	&send_email($vars->{person_email},$Site->{st_pub},$subj,$pagetext);



	#&send_email($vars->{person_email},$Site->{em_from},$subj,$pagetext);


	# Send Email to Admin
	$subj = "New User Registration";
	$pagetext = qq|
<html><head></head><body>
	New User Registration:</p><p>

	Userid: $vars->{person_title}</p><p>
	Email: $vars->{person_email}</p><p>

	$vars->{msg}</p><p>
	Remove this user?
	<a href="$Site->{st_cgi}login.cgi?action=Remove&person_id=$vars->{key}">Click here</a></p><p>

	Source:
	$vars->{source}</p><p></body></html>

	|;


	&send_email($Site->{em_copy},$Site->{em_from},$subj,$pagetext);


	&login_form_input($dbh,$query);

}

sub new_anon_google {

	my ($dbh,$query) = @_;

	my ($cgi);
	my ($session);
	my ($googleId);
	my ($cookie);

	$cgi = CGI->new();

	# Get the session ID from the user's cookie
	$session = CGI::Session->new() or die $cgi->header . $cgi->start_html .
		"<br/><h4>ERROR: Failed to create session ID: " . CGI::Session->errstr . "</h4><br/>" .
		$cgi->end_html;

	# Get the Google OpenID identity
	$googleId = $session->param('openid.identity');

	# Check if this user actually came from Google
	if ($googleId eq '' || $googleId eq undef)
	{
		# Print the web page headers
		print $cgi->header;
		print $cgi->start_html;

		print "<br/><h4>ERROR: Invalid google ID</h4><br/>";

		# Print the web page footers
		print $cgi->end_html;

		# Exit the script
		exit(0);
	}

	# We have a login
	$Person->{person_openid} = $googleId;

	# Delete the session so no one can impersonate this user
	$session->delete();


								    # Not Already Logged In with regular ID?
	if (($Person->{person_id} eq 2) || ($Person->{person_id} eq "")) {

	    							# Try to find an account for this OpenID

		my $stmt = qq|SELECT * FROM person WHERE person_openid = ? LIMIT 1|;
		my $sth = $dbh -> prepare($stmt);
		$sth -> execute($Person->{person_openid});
		my $ref = $sth -> fetchrow_hashref();
		if ($ref) {

									# Write Login Account Cookies

				$Person->{person_id} = $vars->{person_id} = $ref->{person_id};
				$Person->{person_title} = $vars->{person_title} = $ref->{person_title};
				&user_are_go($dbh,$query);
				exit;

		} else {

									# Brand New User, Yippee
			print "Content-type: text/html; charset=utf-8\n\n";

			my $target; my $targa;
			if ($vars->{target}) {
				$target = qq|<input type="hidden" name="target" value="$vars->{target}">|;
				$targa = qq|&target=$vars->{target}|;
			}

			my $refer; my $refa;
			if ($vars->{refer}) {
				$refer = qq|<input type="hidden" name="refer" value="$vars->{refer}">|;
				$refa = qq|&refer=$vars->{refer}|;
			}

			$Site->{header} =~ s/\Q[*page_title*]\E/Register New Google User/g;
			print $Site->{header};
			my $script = $Site->{script};
			print	qq|<br/><h3>Register a New Account With Google OpenID</h3><br/>
					<form method='post' action='$script' class="grss-skin">
					<input type='hidden' name='action' value='RegGoogleUser'>
					$refer
					$target|;


		      	if ($Site->{st_reg_on} eq "yes") {			# Accepting Registrations? (st_reg_on = yes)


					$Person->{person_id} = 0;				# Set up statements
					my $login_text = qq|<box Privacy Statement>
						    <box Cookies Statement>
						    <box Research Statement>|;

											# Set up captcha
					my $captchas;
					my $capt_text = "";
					if ($captchas = &get_captcha_table()) {
						my @capkeys = keys %$captchas;
						my $caplen = scalar @capkeys;
						my $cap_sel = rand($caplen);

						$capt_text = qq|<p><img src="http://www.downes.ca/images/captchas/|.
							@capkeys[$cap_sel].qq|.jpg" alt="|.@capkeys[$cap_sel].
							qq|"><input type='hidden' name='captcha_index' value='|.
							@capkeys[$cap_sel].qq|'><br/>
							<input type='text' size="10" name='captcha_submit'><br/>
				Please type the image text into the form.<br/></p>|;
					} else {
						$vars->{msg} .= "Captcha table not found.". $Site->{st_cgif}.
								"/data/captcha_table.txt";
					}


				if ($vars->{msg}) { $login_text .= qq|<p class="notice">$vars->{msg}</p>|; }
				$login_text .= qq|
					<p>Select a  username: <input name='person_title' type='text' size=20>|;
				$login_text .= "<input type='hidden' name='person_openid' value='$Person->{person_openid}'>";
				$login_text .= "<p>Enter your email address:<br>\n<input name='person_email' type='text' size='40'></p>";

				$login_text .=  &subscription_form_text($dbh,$query);

				$login_text .= qq|
					<p>(Optional) Where did you hear about this website?<br/>
					<textarea name="source" cols=60 rows=7></textarea></p>
					$capt_text
					<p><input type='submit' value='@{[&printlang("Cliquez ici pour vous inscrire")]}'></p><p>&nbsp;</p>|;


		      	 	&make_boxes($dbh,\$login_text,"silent");
		      	 	&make_site_info(\$login_text);

		      	 	print $login_text;

		      	} else {						# Not Accepting Registrations (st_reg_on = no)

		      		print qq|<p>This site is not open to new registrations at this time.
					Visit <a href="http://mooc.ca">MOOC.ca</a> for a list of
					open sites.</p>|;

			}

			print "</form>";
			print $Site->{footer};

		}
	} else {

		# Already Logged In
		&user_are_go($dbh,$query);
		exit;
	}

	return;
}


#


# --------  Login --------------------------------------------------------------


sub login_form_input {
	my ($dbh,$query) = @_;
	my $vars = $query->Vars;

						# Check Input Variables

	unless (($vars->{person_title}) && ($vars->{person_password}) ||
		($vars->{person_title}) && ($vars->{person_openid})) {			# Unless fields filled
			print "Content-type: text/html\n\n";
			my $returntourl = $Site->{st_url} . "cgi-bin/login.cgi?action=newAnonGoogle&refer=$vars->{refer}";
			my $mesg = &printlang("Missing credentials");
			$mesg .= "<a href='https://www.google.com/accounts/o8/ud?openid.ns=http://specs.openid.net/auth/2.0&openid.claimed_id=";
			$mesg .= "http://specs.openid.net/auth/2.0/identifier_select&openid.identity=";
			$mesg .= "http://specs.openid.net/auth/2.0/identifier_select&openid.return_to=$returntourl&openid.mode=checkid_setup'>";
			$mesg .= &printlang("Login Google").'</a>';
			&login_error($dbh,$query,"",$mesg); exit; }			# User Login Error



	my $stmt;
	if ($vars->{person_title} =~ /@/) { 						# Select by email or title
		$vars->{person_email} = $vars->{person_title};
		$stmt = qq|SELECT * FROM person WHERE person_email = ? ORDER BY person_id LIMIT 1|;
	} else {
		$vars->{person_title} = $vars->{person_title};
		$stmt = qq|SELECT * FROM person WHERE person_title = ? ORDER BY person_id LIMIT 1|;
	}

											# Get Person Data
#print "Content-type: text/html\n\n";
#print $stmt," ",$vars->{person_title}," <P>";



	my $sth = $dbh -> prepare($stmt);
	$sth -> execute($vars->{person_title});
	my $ref = $sth -> fetchrow_hashref();

											# Eerror if Data not found
	unless ($ref) {
		&anonymous($Person);
		my $errmsg = "".&printlang("Login error")."<br/>".&printlang("User name not found").
			"<br/>".&printlang("Recover registration",$Site->{st_cgi}."login.cgi?refer=$vars->{refer}&action=Email");
		&login_error($dbh,$query,"",$errmsg);
		exit;
	}

											# Password Check
	exit unless (&password_check($vars->{person_password},$ref->{person_password}));



	while (my($x,$y) = each %$ref) { $Person->{$x} = $y; }
	$sth->finish(  );
	unless ($Person->{person_id}) {
		&anonymous($Person);
		my $errmsg = "".&printlang("Login error")."<br/>".&printlang("Unknown error").
			"<br/>".&printlang("Recover registration",$Site->{st_cgi}."login.cgi?refer=$vars->{refer}&action=Email");
		&login_error($dbh,$query,"",$errmsg);
		exit;# No Person Data - Send Error
	}

	&user_are_go($dbh,$query);

}


# --------  Logout -------------------------------------------------------------

sub user_logout {
	my ($dbh,$options) = @_;

						# Define Cookie Names
	my $site_base = &get_cookie_base();
	my $id_cookie_name = $site_base."_person_id";
	my $title_cookie_name = $site_base."_person_title";
	my $session_cookie_name = $site_base."_session";

	my $salt = "logout";
	my $sessionid = crypt("anymouse",$salt);

	my $cookie1 = $query->cookie(-name=>$id_cookie_name,
		-value=>'2',
		-expires=>'-1y',
		-path=>'/',
		-domain=>$Site->{co_host},
		-secure=>0);
        my $cookie2 = $query->cookie(-name=>$title_cookie_name,
		-value=>'Anymouse',
		-expires=>'-1y',
		-path=>'/',
		-domain=>$Site->{co_host},
		-secure=>0);
	  my $cookie3 = $query->cookie(-name=>$session_cookie_name,
		-value=>$sessionid,
		-expires=>'-1y',
		-path=>'/',
	-domain=>$Site->{co_host},
		-secure=>0);

	# Added -charset for UTF-8 encoding issue -Luc
        print $query->header(-cookie=>[$cookie1,$cookie2,$cookie3], -charset => 'utf-8');
	print "\n\n";

	&anonymous($Person);			# Make anonymous

						# Print Jumpoff Page
	$Site->{header} =~ s/\Q[*page_title*]\E/Logout/g;
	print $Site->{header};
	print qq|<div id="grey-box-wrapper" class="rounded-whitebox"><h2>@{[&printlang("Logout successful")]}</h2><h3>$Site->{st_name}</h3>|;
	&print_nav_options($dbh,$options);
        print "</div>";
	print $Site->{footer};
	if ($dbh) { $dbh->disconnect; }			# Close Database and Exit
	exit;
}

# --------  Open ID ----------------------------------------------------------

sub openidq {

	my ($dbh,$query) = @_;

	my $vars;

#	unless ($vars->{openid_enabled}) {
#		$Site->{header} =~ s/\Q[*page_title*]\E/Login Using OpenID/g;
#
#		print "Content-type: text/html; charset=utf-8\n\n";
#		print $Site->{header};
#
#		print qq|<h4>OpenIDLogin</h4><p>$vars->{msg}</p>
#		<p>This site does not support OpenID. Ask the site administrator to load
#		Net::OpenID::Consumer if you would like to use it.</p>|;
#
#		exit;
#	}

									# Set up OpenID object
#	  use Net::OpenID::Consumer;


#    my $ua = LWP::UserAgent->new(timeout => 7);
 #   my $csr = Net::OpenID::Consumer->new(
#					 ua   => $ua,
#					 args  => $vars,
#					 consumer_secret => "hello",
#					 );

	# my $trust_root = $Site->{st_url};

	# 							    # Part 1: user enters their URL.

 #   	if (my $url = $vars->{openid_url}) {

	# 	my $claimed_id = $csr->claimed_identity($url)
	#     		or 	&login_error($dbh,$query,"","Can't determine claimed ID");

	# 	my $returntourl = $Site->{st_url}.
	# 		"cgi-bin/login.cgi?action=OpenID&refer=$vars->{refer}";
	# 	my $check_url = $claimed_id->check_url(
	# 					   return_to => $returntourl,
	# 					   trust_root => $trust_root,
	# 					   delayed_return => 1,
	# 					   );

	# 	# print "Content-type: text/html; charset=utf-8\n";    # I don't need this? Why?
	# 	 print "Location: $check_url\n\n";
	# 	 exit;
	# }

	# 								# Login Cancelled

	# if ($vars->{'openid.mode'} eq "cancel") {
	# 	&login_error($dbh,$query,"","You cancelled");
	# }


 #    								# Part 2: we get the assertion or setup url

	# 								# Setup URL

 #    if (my $setup = $csr->user_setup_url) {

	# 	# I don't know...
	# 	print "Content-type: text/html; charset=utf-8\n\n";
	# 	print "Setup URL $setup <br>";
	# 	exit;
 #    }

	# 							    # Assertion - get verified identity object

 #    my $vident = eval { $csr->verified_identity; };
 #    if (! $vident) {
	# 	if ($@) { $csr->_fail("runtime_error", $@); }
	# 	&login_error($dbh,$query,"","OpenID runtime error");
 #    }

	###############################

	#   Big security hole here
	#   MUST VERIFY OPENID LOGIN

	###############################

	exit;


	$Person->{person_openid} = $query->param('openid.identity');

								    # Not Already Logged In with regular ID?
	if (($Person->{person_id} eq 2) ||
	    ($Person->{person_id} eq "")) {



	    							# Try to find an account for this OpenID

		my $stmt = qq|SELECT * FROM person WHERE person_openid = ? LIMIT 1|;
		my $sth = $dbh -> prepare($stmt);
		$sth -> execute($Person->{person_openid});
		my $ref = $sth -> fetchrow_hashref();
		if ($ref) {

									# Write Login Account Cookies

				$Person->{person_id} = $vars->{person_id} = $ref->{person_id};
				$Person->{person_title} = $vars->{person_title} = $ref->{person_title};
				&user_are_go($dbh,$query);
				exit;

		} else {

									# Brand New User, Yippee

###### Insert page to prompt for a userid and assign to person_title
				$Person->{person_title} = $vars->{person_title} = $Person->{person_openid};
				$vars->{person_openid} = $Person->{person_openid};

									# Require Unique Name
									# Prevents stacking OpenID accounts
###### Check both the userid and the openid
				if (&db_locate($dbh,"person",{person_title => $vars->{person_title}}) ) {
					&login_error($dbh,$query,"","Someone else named '$vars->{person_title}' has already registered.");
				};

									# Create the User Record

				my $idval = 'new';
				$vars->{person_crdate} = time;
				$vars->{key} = &db_insert($dbh,$query,"person",$vars,$idval);
				unless ($vars->{key}) {
					&login_error($dbh,$query,"","Error, no new account was created.");
				}
				$Person->{person_id} = $vars->{person_id} = $vars->{key};

									# Send Email to Admin

				my $subj = "New OpenID User Registration";
				my $pagetext = qq|

					New OpenID User Registration:

					Userid: $vars->{person_title}
					Email: $vars->{person_email}

					Remove this user?
					$Site->{script}?action=Remove&person_id=$vars->{key}
				|;
				&send_email($Site->{em_copy},$Site->{em_from},$subj,$pagetext);

									# Create Login Message

				$vars->{msg} .= qq|

					OpenID login successful.<br/><br/>
					To personalize your account, click on [Options]<br/><br/>
					To associate your OpenID account with a previously existing
					$Site->{st_name} account, login to that account using
					your userid and password, then login using OpenID again.|;

									# Write Login Account Cookies

				&user_are_go($dbh,$query);
				exit;

		}



									# Already Logged In
	} else {

									# Remove old stand-alone OpenID

		my $stmt = "DELETE FROM person WHERE person_openid=? AND person_title=''";
		my $sth = $dbh->prepare($stmt);
		$sth->execute($Person->{person_openid});
		$sth->finish(  );

									# Associate ID with OpenID

		&db_update($dbh,"person",{person_openid => $Person->{person_openid}}, $Person->{person_id});

									# Print Jumpoff Page
		print "Content-type: text/html; charset=utf-8\n\n";
	#	$Site->{header} =~ s/\Q[*page_title*]\E/OpenID Login Successful/g;
	#	print $Site->{header};
		print qq|<h4>{[&printlang("Login Successful")]}</h4>|;
		print qq|<p>Identity verified. You are $Person->{person_openid}</p>
			You are currently logged in as $Person->{person_title}.
			Associating $Person->{person_openid} with this account.</p>
			When you return to this site in the future,
			you may now log in with <i>either</i> your OpenID
			account or your old $Site->{st_name} account. Either
			way, it will be the same account.</p>|;

	}

	&print_nav_options($dbh,$query);
	#print $Site->{footer};
	exit;
}


# --------  Register ----------------------------------------------------------

sub new_user {


	my ($dbh,$query) = @_; my $table = 'person';
	my $vars = $query->Vars;
	my $errmsg = "".printlang("Registration Error")."<br/>";

	unless ( ($vars->{person_title}) &&	# Verify Input
		  ($vars->{person_email}) &&
		  ($vars->{person_password})) {
		&login_error("nil",$query,"", $errmsg.&printlang("You must provide")); }

						# Captcha Test
	my $captchas;
	if ($captchas = &get_captcha_table()) {
		unless ( $vars->{captcha_submit} eq $captchas->{$vars->{captcha_index}}) {
			&login_error("nil",$query,"", $errmsg.&printlang("Incorrect Captcha"));
		}
	} else {
		$vars->{msg} .= printlang("Captcha table not found");
	}




	my ($to) = $vars->{person_email};	# Check email address
	if ($to =~ m/[^0-9a-zA-Z.\-_@]/) {
		&login_error("nil",$query,"", $errmsg.&printlang("Bad email"));
	}
						# Unique Email

	if (&db_locate($dbh,"person",{person_email => $vars->{person_email}}) ) {
		#$errmsg .= &printlang("Someone using").&printlang("Recover registration",$Site->{st_cgi}."login.cgi?refer=$vars->{refer}&action=Email");
		#&login_error($dbh,$query,"",$errmsg);
	};


						# Unique Name

	if (&db_locate($dbh,"person",{person_title => $vars->{person_title}}) ) {
		$errmsg .= &printlang("Someone named",$vars->{person_title}).
			&printlang("Recover registration",$Site->{st_cgi}."login.cgi?refer=$vars->{refer}&action=Email");
		&login_error($dbh,$query,"",$errmsg); };

						# Spam Checking

	if ($vars->{source} =~ /test,|just a|for all|for every/i) {
		&login_error("nil",$query,"", $errmsg.&printlang("Spam registration"));  };
	if ($vars->{person_title} =~ /youtube|blog /i) {
		&login_error("nil",$query,"", $errmsg.&printlang("Spam registration"));  };


						# Create a Salted Password

	my $saved_password = $vars->{person_password};
       	my $encryptedPsw = &encryptingPsw($vars->{person_password}, 4);
	my $sendpwd = $vars->{person_password};
	$vars->{person_password} = $encryptedPsw;



						# Create the User Record
	my $idname = $table."_id";
	my $idval = 'new';
	$vars->{person_crdate} = time;
	$vars->{person_status} = "reg";
	$vars->{person_status} = "reg";
	$vars->{person_source}=	$vars->{source};
	$vars->{key} = &db_insert($dbh,$query,$table,$vars,$idval);
	unless ($vars->{key}) {
		&login_error("nil",$query,"", $errmsg.&printlang("No new account"));
	}
	$Person->{person_id} = $vars->{key};
	$vars->{person_password} = $saved_password;



						# Newsletter Subscriptions
	&add_subscription($dbh,$query,$vars->{key});


						# Send email to user

	my $subj = &printlang("Welcome to",$Site->{st_name});
	$subj =~ s/&#39;/'/g;
	my $pagetext = &db_get_description($dbh,"box",&printlang("welcome message"));
	$page_text =~ s/<vars_person_title>/$vars->{person_title}/g;



	&send_email($vars->{person_email},$Site->{st_pub},$subj,$pagetext,"htm");


						# Send Email to Admin

	$subj = &printlang("New User Registration");
	$pagetext = qq|<p>
		@{[&printlang("New User Registration")]}<br/><br/>
		@{[&printlang("Userid")]}: $vars->{person_title} <br/>
		@{[&printlang("Email")]}: $vars->{person_email} <br/><br/>
		$vars->{msg} <br/>
		<br/>
		@{[&printlang("Remove user")]} : $Site->{script}?action=Remove&person_id=$vars->{key}  <br/><br/>
		Source:	$vars->{source} </p>

	|;

        # Sends to all admins
        &send_notifications($dbh,$vars,"person",$subj,$pagetext);

        # old
	# &send_email($Site->{em_copy},$Site->{em_from},$subj,$pagetext,"htm");


	&login_form_input($dbh,$query);

}


# -------   Captchas ------------------------------------------------------------


sub get_captcha_table {

	my $captchas;
	my $found = 0;
	my $cfilename = $Site->{data_dir}."captcha_table.txt";

	open IN,"$cfilename";
	while (<IN>) {
		chomp;
		my ($x,$y) = split "\t",$_;
		$y =~ s/[^a-zA-Z0-9]//g;			# Picking up some formatting junk from captcha table?


		$captchas->{$x} = $y;
	}
	close IN;

	return  $captchas;

}



# -------   Options ------------------------------------------------------------


sub options {
	my ($dbh,$query) = @_;
	my $vars = $query->Vars;

							# Page header
	my $pagetitle = &printlang("Options");
	$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;
	print "Content-type: text/html; charset=utf-8\n\n";


	print $Site->{header};

						# Find User Data
	my $pid = &find_person($dbh,$query);
	my $pdata = &db_get_record($dbh,"person",{person_id =>$pid});


						# Anonymous User Options
	if (($Person->{person_id} eq 2) ||
	    ($Person->{person_id} eq "")) { &anon_options($dbh,$query); return; }

	my $refer=""; 				# Define Refer Link
	my $referq; my $refera;
	if ($vars->{refer}) { $referq = "?refer=".$vars->{refer}; $refera = "&refer=".$vars->{refer}; }
	if ($vars->{target}) { $targetq = "?refer=".$vars->{target}; $targeta = "&refer=".$vars->{target}; }


						# Define Name
	my $name = $pdata->{person_name} || $Person->{person_title};

	unless ($pdata->{person_photo}) {
		$pdata->{person_photo} = qq|avatar_generique_25x25.jpg|;
	}


						# Print Page
	print qq|<div id="grey-box-wrapper" class="rounded-whitebox">
		<h2>@{[&printlang("Welcome")]}, $name</h2>
		$vars->{msg}
		<p>@{[&printlang("Your Private Page")]}
		<a href="$Site->{st_cgi}page.cgi?person=$pid">@{[&printlang("click here")]}</a>.
                        <h3 class="nospacebellow">@{[&printlang("Personal Information")]}</h3>
			<div id="options-personal-information">
			<div id="options-photo"><p class="clearfix"><span class="profile-label">@{[&printlang("Photo")]}:</span>
			<span class="profile-info"><a href="$Site->{st_cgi}login.cgi?action=EditInfo"><img src='$Site->{site_url}files/icons/$pdata->{person_photo}'></a>
                        <a href="$Site->{st_cgi}login.cgi?action=EditInfo">@{[&printlang("Change photo")]}</a></span>
                        </p></div>

			<div id="options-data"><p class="clearfix">  <!-- Remove this styling when CSS is updated -->
			<span class="profile-label">@{[&printlang("Userid")]}:</span><span class="profile-info">$pdata->{person_title}<br/></span>
			<span class="profile-label">@{[&printlang("Name")]}:</span><span class="profile-info">$pdata->{person_name}<br/></span>
			<span class="profile-label">@{[&printlang("Home Page")]}:</span><span class="profile-info">$pdata->{person_url}<br/></span>
			<span class="profile-label">@{[&printlang("Email")]}:</span><span class="profile-info">$pdata->{person_email}<br/></span>
			<span class="profile-label">@{[&printlang("Organization")]}:</span><span class="profile-info">$pdata->{person_organization}<br/></span>
			<span class="profile-label">@{[&printlang("City")]}:</span><span class="profile-info">$pdata->{person_city}|;
			if ($pdata->{person_city}) { print ", "; }
			print qq|$pdata->{person_country}<br/></span>
                        </p><p class="link-box">
			<a href="$Site->{script}?action=EditInfo$refera">@{[&printlang("Edit Info")]}</a><br/>
			<a href="$Site->{cgi}login.cgi?action=changepwdscr">@{[&printlang("Change password")]}</a>
			</p></div></div>|;


								# Social Networks
								# Note that social network data is stored in person:person_socialnet
								# If data is not saving, check to be sure this field exists in the DB

	print qq|<h3 class="nospacebellow">@{[&printlang("Social networks")]}</h3><div id="options-personal-information" class="clearfix"><p>|;


	my $sni = $pdata->{person_socialnet};	# Existing social networks
	my @snil = split ";",$sni;
	my $count = 0;
	foreach my $sn (@snil) {
		$count++;
		my ($netname,$netid,$netok) = split ",",$sn;
		$netok =~ s/checked/public/;
		print qq|<span>$netname:</span>
			<span>$netid</span>
			<span> - $netok</span><br/>
		|;
	}
	print qq|</p><p class="link-box">
	<a href="$Site->{script}?action=form_socialnet$refera">@{[&printlang("Edit social networks")]}</a></p>
        </div>|;

								# RSS Feeds

	print qq|<h3 class="nospacebellow">@{[&printlang("Blogs and RSS")]}</h3>\n
		<div id="options-feeds">\n|;


	my $stmt = qq|SELECT * FROM feed WHERE feed_author=?|;	# Get Feeds
	my $sth = $dbh->prepare($stmt) or &login_error($dbh,$query,"",&printlang("Cannot prepare SQL","options-feeds",$sth->errstr(),$stmt));
	$sth->execute($pid) or &login_error($dbh,$query,"",&printlang("Cannot execute SQL","options-feeds",$sth->errstr(),$stmt));

	while (my $ref = $sth -> fetchrow_hashref()) {  # Display Feeds

		print qq|<div class="option_feed">
			<img src="$Site->{st_url}images/$ref->{feed_status}tiny.jpg">
			$ref->{feed_title}
			[<a href="$Site->{st_cgi}page.cgi?feed=$ref->{feed_id}">@{[&printlang("View")]}</a>]
			</div>|;
	}

	$sth->finish();
	print qq|<br/><img src="$Site->{st_url}images/Otiny.jpg"> @{[&printlang("Pending Approval")]}
			<img src="$Site->{st_url}images/Atiny.jpg"> @{[&printlang("Approved")]}
			<img src="$Site->{st_url}images/Rtiny.jpg"> @{[&printlang("Retired")]}<br/>
                        </p><p class="link-box">
			<a href="$Site->{st_url}new_feed.htm">@{[&printlang("Add a new feed")]}</a>
			</p></div>|;


								# Newsletter Subscriptions

	print qq|<h3 class="nospacebellow">@{[&printlang("Newsletter Subscriptions")]}</h3><div id="options-newsletters"><p>|;
	my $stmt = "SELECT subscription_box FROM subscription WHERE subscription_person = '$pid'";
	my $sub_ary_ref = $dbh->selectcol_arrayref($stmt);

	my $sql = qq|SELECT page_id,page_title,page_autosub,page_location FROM page WHERE page_sub = 'yes' ORDER BY page_title|;
	my $sth = $dbh->prepare($sql) or &login_error($dbh,$query,"",&printlang("Cannot prepare SQL","options-newsletters",$sth->errstr(),$sql));
	$sth->execute() or &login_error($dbh,$query,"",&printlang("Cannot execute SQL","options-newsletters",$sth->errstr(),$sql));

	while (my $p = $sth -> fetchrow_hashref()) {
		if (&index_of($p->{page_id},$sub_ary_ref) > -1) {
			print qq|<span>$p->{page_title}:
			<a target="_blank" href="$Site->{st_url}$p->{page_location}">@{[&printlang("Read")]}</a></span><br/>|;
		}
	}

	print qq|</p><p class="link-box">
		<a href="$Site->{script}?action=Subscribe$refera">@{[&printlang("Modify Subscriptions")]}</a>
		</p></div>|;

								# OpenID
								# We may want to merge this with social networks


	print qq|<!--<h3 class="nospacebellow">OpenID</h3>--><div id="options-newsletters"><p>
	<span>|;

	#my $idfed = "no";
	#if ($Person->{person_openid}) {
	#	print qq|OpenID: $Person->{person_openid}|;
	#} else {

											# Associate with Google ID
		#if (($Site->{st_google_on} eq "yes") && ($Person->{person_id} ne 2)) {
		#	$idfed="yes";
		#	my $returntourl = $Site->{st_url}."cgi-bin/login.cgi?action=OpenID&refer=$vars->{refer}";
		#	print qq|
		#	[<a href='https://www.google.com/accounts/o8/ud?openid.ns=http://specs.openid.net/auth/2.0&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select&openid.identity=http://specs.openid.net/auth/2.0/identifier_select&openid.return_to=$returntourl&openid.mode=checkid_setup'>@{[&printlang("Associate with Google ID")]}</a>]<br/>|;
		#}



											# Associate with Open ID
		#if (($Site->{st_openid_on} eq "yes") && ($Person->{person_id} ne 2)) {
		#	$idfed="yes";
                #        print qq|[<a href="$script?$referq$targetq&action=openidloginform">@{[&printlang("Associate with OpenID")]}</a>]<br/>|;
		#}
		#if ($idfed eq "no") { print &printlang("OpenID not supported"); }

	#}

	print qq|</span></p></div><br/><br/>|;



	#&print_nav_options($dbh,$query);

	print $Site->{footer};

}

# -------   Anon Options ------------------------------------------------------------

sub anon_options {

		my ($dbh,$query) = @_;
	my $vars = $query->Vars;

		print qq|<p>@{[&printlang("Anon Message")]}</p>
			<p><ul>
			<li>@{[&printlang("Anon Login")]}</li>
			<li>@{[&printlang("Anon Register")]}</li>|; #'

		if ($vars->{refer}) {
			my $rf = $vars->{refer};
			$rf =~ s/AND/&/g;
			$rf =~ s/COMM/#/g;
			$rf =~ s/(<|>|"|&lt;|&gt;|&quot;)//g;		# Prevent XSS
			print qq|<li><a href="$rf">@{[&printlang("Go Back")]}</a></li>|;
		}
		print qq|</ul></p>|;
		print "<p>&nbsp;</p>".$Site->{footer};
		return;


}

# --------  User Are Go --------------------------------------------------------

# Writes login cookies after succcessful login or registration
# As in: Thunderbirds Are Go
#
# Used by: login_form_input()



sub user_are_go {
	my ($dbh,$query) = @_;
	my $vars = $query->Vars;
	#print "Content-type: text/html; charset=utf-8\n\n";
	$vars->{remember} = 1; 						# Because people keep forgetting to check the little box




									# Define Cookie Names
	my $site_base = &get_cookie_base();
	my $id_cookie_name = $site_base."_person_id";
	my $title_cookie_name = $site_base."_person_title";
	my $session_cookie_name = $site_base."_session";
	my $admin_cookie_name = $site_base."_admin";


#	print "Content-type: text/html; charset=utf-8\n\n";	# Print HTTP header
#	print "User are go<p>";



	my $exp; 							# Expiry Date
	if ($vars->{remember}) { $exp = '+1y'; }
	else { $exp = '+1h'; }

									# Session ID
	my $salt = $site_base . time;
	my $sessionid = crypt("anymouse",$salt); 			# Store session ID in DB
	&db_update($dbh,"person",{person_mode => $sessionid}, $Person->{person_id},&printlang("Setting session",$Person->{person_id}));



									# Cookies
	my $cookie1 = $query->cookie(-name=>$id_cookie_name,
		-value=>$Person->{person_id},
		-expires=>$exp,
		-domain=>$Site->{co_host},
		-secure=>0);
	my $cookie2 = $query->cookie(-name=>$title_cookie_name,
		-value=>$Person->{person_title},
		-expires=>$exp,
		-domain=>$Site->{co_host},
		-secure=>0);
	my $cookie3 = $query->cookie(-name=>$session_cookie_name,
		-value=>$sessionid,
		-expires=>$exp,
		-domain=>$Site->{co_host},
		-secure=>0);

									# Admin Cookie
									# Not secure; can be spoofed, use only to create links
	my $admin_cookie_value = "";
	if ($Person->{person_status}  eq "admin") { $admin_cookie_value="admin"; }
	else { my $admin_cookie_value="registered"; }

	my $cookie4 = $query->cookie(-name=>$admin_cookie_name,
			-value=>$admin_cookie_value,
			-expires=>$exp,
			-domain=>$Site->{co_host},
			-secure=>0);

	print $query->header(-cookie=>[$cookie1,$cookie2,$cookie3,$cookie4], -charset => 'utf-8');

	&d2l_remote_login($dbh,$query);


	&show_connected_page($dbh, $query);
							# Page header
	exit;
}

sub show_connected_page {
	my ($dbh,$query) = @_;

	my $pagetitle = &printlang("Login successful");
	$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;
#	print "Content-type: text/html; charset=utf-8\n\n";


	# Page Body - Jumpoff Page

#	print $Site->{header};
	print qq|<div id="grey-box-wrapper" class="rounded-whitebox"><h2>$pagetitle</h2>|;
	if ($vars->{msg}) {
		print qq|<div id="notice">$vars->{msg}</div>|;
	}
	&print_nav_options($dbh,$query);
#	print $Site->{footer};
        print qq|</div>|;

}


# -------   D2L Remote Login ---------------------------------------------
#
#  This supported gRSShopper integration with D2L
#  It's legacy code but kept around in case we ever do it again
#

sub d2l_remote_login {

	my ($dbh,$query) = @_;
	my $redirect;
	my $vars = $query->Vars;
	if ($Person->{person_id} && $Person->{person_id} ne "2") {

		if ($vars->{target}) {		# Site-specific Need a better thing here
			if ($target =~ /edfuture/) {			# URL-specific - Need a better thing here
			my $sitekey = qq|A48506F1-7AE3-4C90-9891-C4E6F662F0BC|;
			my $apiurl = "https://edfuture.desire2learn.com";
			my $apipath = "/d2l/api/custom/1.1/ssowithcreateandenroll/authUser/".$sitekey;

			my ($first,$last) = &first_last_name();
			&login_error($dbh,"","","fatal error, first and last name not found on D2L redirect: $first, $last") 	unless ($first && $last);
			&login_error($dbh,"","","fatal error, email address not found on D2L redirect") unless ($Person->{person_email});
			my $data = {
				UserName => $Person->{person_title},
				FirstName => $first,
				LastName => $last,
				Email => $Person->{person_email}
			};


			$redirect = &api_send_rest($dbh,$query,$apiurl,$apipath,$data,$target);
			print qq|<li>@{[&printlang("Return to D2L",$redirect)]}</li>|;
			exit;

			# For some reason autoreturn wasn't woprking
			print "Location: $redirect\n\n";



			}
		}

	}


}


#   -------------------------------------------------------------------------------------
#
#
#		NAVIGATION
#
#
#   -------------------------------------------------------------------------------------



# --------  Print Nav Options ---------------------------------------------------
#
# Used by: login_form_input()  (via user_are_go() )
#          user_logout()


sub print_nav_options {
	my ($dbh,$query) = @_;
	my $vars = $query->Vars;
	my $script = $Site->{script};




	my $refer=""; 				# Define Refer Link
	my $referq; my $refera;
	if ($vars->{refer}) {
		$referq = "?refer=".$vars->{refer};
		$refera = "&refer=".$vars->{refer};
	}
	if ($vars->{target}) {
		$targetq = "?refer=".$vars->{target};
		$targeta = "&refer=".$vars->{target};
	}
	print "<p><ul>";

	# Check if user is logged in
	if (!(($Person->{person_id} eq 2) || ($Person->{person_id} eq "")))
	{
		# &d2l_nav($dbh,$query)

		my $rf = $Site->{st_cgi}."page.cgi?page=PLE";
		print qq|<li><a href="$rf">
			@{[&printlang("gRSShopper PLE")]}</a></li>|;

		if ($Person->{person_status} eq "admin") {				# Site Administration
			print qq|<li><a href="$Site->{st_cgi}admin.cgi">@{[&printlang("Site Administration")]}</a></li>|;
		}

											# Options and Personal Info
		print qq|<li><a href="$script?action=Options$refera$targeta">
			@{[&printlang("Options and Personal Info")]}</a></li>|;



		if ($vars->{refer}) {							# Go back to where you were
			my $rf = $vars->{refer};
			$rf =~ s/AND/&/g;
			$rf =~ s/COMM/#/g;
			$rf =~ s/(<|>|"|&lt;|&gt;|&quot;)//g;		# Prevent XSS
			$rf .= "hi";
			print qq|<li><a href="$rf">
				@{[&printlang("Go Back")]}</a></li>|;
		} elsif ($vars->{target}) {
			unless (&new_module_load($query,"URI::Escape")) {
				print $vars->{error};
				exit;
			}
			my $tf = $vars->{target};
			$tf = uri_unescape($tf);
			print qq|<li><a href="$rf">
				@{[&printlang("Go Back")]}</a></li>|;

		} else {
			my $rf = $Site->{st_cgi}."page.cgi?page=PLE";
			print qq|<li><a href="$rf">
				@{[&printlang("Go Back")]}</a></li>|;

		}
	}
											# Home Page
	print qq|
		<li><a href="$Site->{st_url}">
		@{[&printlang("Site Home Page",$Site->{st_name})]}</a></li>|;





											# Change password
	unless ($Person->{person_id} eq 2) {
		print qq|<li><a href="$script?action=Subscribe$referq">@{[&printlang("Newsletter subscriptions")]}</a></li>|;
		print qq|<li><a href="$script?action=changepwdscr">@{[&printlang("Change password")]}</a></li>|;
	}

											# Login as another user
	unless ($Person->{person_id} eq 2) {
		print qq|<li><a href="$script?action=login_text$refera$targeta">@{[&printlang("Login as another user")]}</a></li>|;
	}

	# Login from anon
  if ($Person->{person_id} eq 2) {
    print qq|<li><a href="$script?action=login_text$refera$targeta">@{[&printlang("Login")]}</a></li>|;
  }
											# Logout
	unless ($Person->{person_id} eq 2) {
		print qq|<li><a class="disconnect" href="$script?action=Logout$refera$targeta">@{[&printlang("Logout")]}</a></li>|;
	}
	print "</ul></p>";

}

# -------   D2L Navigation ---------------------------------------------
#
#  This supported gRSShopper integration with D2L
#  It's legacy code but kept around in case we ever do it again
#

sub d2l_nav {

	my ($dbh,$query) = @_;
	my $vars = $query->Vars;
	my $script = $Site->{script};

	# Sepecial for Ed Future
	if ($Site->{st_url} =~ /edfuture/) {
		$vars->{target} ||= "http%3a%2f%2fedfuture.desire2learn.com%3a80%2fd2l%2fhome%2f6609";


		my $sitekey = qq|A48506F1-7AE3-4C90-9891-C4E6F662F0BC|;
		my $apiurl = "https://edfuture.desire2learn.com";
		my $apipath = "/d2l/api/custom/1.1/ssowithcreateandenroll/authUser/".$sitekey;


		my ($first,$last) = &first_last_name();
		&login_error($dbh,"","","fatal error, first and last name not found on D2L redirect: $first, $last")
			unless ($first && $last);
		&login_error($dbh,"","","fatal error, email address not found on D2L redirect")
			unless ($Person->{person_email});
		my $data = {
			UserName => $Person->{person_title},
			FirstName => $first,
			LastName => $last,
			Email => $Person->{person_email}
		};


		$redirect = &api_send_rest($dbh,$query,$apiurl,$apipath,$data,$target);
		print qq|<li>@{[&printlang("Return to D2L",$redirect)]}</li>|;

	}

}


# --------  Go to D2L ---------------------------------------------------

sub go_to_d2l {


	exit;
}


# --------  First-Last Name ---------------------------------------------------
#
#
# Generates first and last name
# Used by D2L functions

sub first_last_name {


	if ($Person->{person_name} && !$Person->{person_lastname}) {
		($Person->{person_firstname},$Person->{person_lastname}) = split " ",$Person->{person_name};
	}

	if ($Person->{person_firstname} && $Person->{person_lastname}) {
		return ($Person->{person_firstname},$Person->{person_lastname});
	}

	if ($Person->{person_firstname} || $Person->{person_lastname} ||  $Person->{person_title}) {
		$Person->{person_firstname} = $Person->{person_firstname} || $Person->{person_lastname} ||  $Person->{person_title};
		$Person->{person_lastname} = $Person->{person_lastname} || $Person->{person_firstname} ||  $Person->{person_title};
		return ($Person->{person_firstname},$Person->{person_lastname});
	}


}

#   -------------------------------------------------------------------------------------
#
#
#		USER INFO MANAGEMENT
#
#
#   -------------------------------------------------------------------------------------



# -------   Edit Info Form ---------------------------------------------

sub edit_info {

	my ($dbh,$query) = @_;
	my $vars = $query->Vars;
	my $script = $Site->{script};


						# Determine Person
	my $pid = &find_person($dbh,$query);
	&login_error($dbh,$query,"",&printlang("Cannot edit anon")) if ($pid eq "2");

						# Get Person Info

	my $record = &db_get_record($dbh,'person',{person_id => $pid});

	unless ($record->{person_photo}) {
		$record->{person_photo} = qq|avatar_generique_100x100.jpg|;
	}


							# Page header
	my $pagetitle = &printlang("Change Email and Personal Info");
	$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;
	print "Content-type: text/html; charset=utf-8\n\n";


							# Page Body
	print $Site->{header};
	print	qq|<div id="grey-box-wrapper" class="rounded-whitebox"><h2>$pagetitle</h2>|;
	print $vars->{msg};
	print qq|
		<form method='post' action='$script' ENCTYPE='multipart/form-data' class="grss-skin">
		<input type='hidden' name='action' value='edit_info_in'>
		<input type='hidden' name='refer' value='$vars->{refer}'>
		<input type='hidden' name='pid' value='$pid'>

		<p><img src='$Site->{site_url}files/icons/$record->{person_photo}'></p>
		<p class="input file"><label>@{[&printlang("Change photo")]}:</label><input size="30" type="file" id="file_name" name="file_name"/></p>

		<!--<tr>
		<td align="right">@{[&printlang("User name")]}</td>
		<td colspan="3">$record->{person_title} </td>
		</tr>-->

		<p><label>@{[&printlang("Name")]}:</label> <input size="30" type="text" name="person_name" value="$record->{person_name}"></p>

		<p><label>@{[&printlang("Email")]}: </label><input size="30" type="text" name="person_email" value="$record->{person_email}"></p>


		<p><label>@{[&printlang("City")]}:</label><input size="30" type="text" name="person_city" value="$record->{person_city}"></p>
		<p><label>@{[&printlang("Person OpenID")]}:</label><input size="30" type="text" name="person_openid" value="$record->{person_openid}"></p>
		<p><label>@{[&printlang("Country")]}:</label><input size="30" type="text" name="person_country" value="$record->{person_country}"></p>
		<p><label>@{[&printlang("Organization")]}:</label><input size="30" type="text" name="person_organization" value="$record->{person_organization}"></p>
		<p><label>@{[&printlang("Home Page")]}:</label><input size="30" type="text" name="person_html" value="$record->{person_html}"></p>
		<p><label>@{[&printlang("RSS Feed")]}:</label><input size="30" type="text" name="person_xml" value="$record->{person_xml}"></p>


      		<input class="leave-space-above leave-space-below" type='submit' value='@{[&printlang("Update Information")]}'></p>
      		</form>|;



	unless ($Person->{person_openid}) {
		unless ($Person->{person_id} eq 2) {
			if ($vars->{openid_enabled}) {
				print qq|<ul><li><a href="$script?referq&action=openidloginform">
				Associate a new OpenID account with your $Site->{st_name} account</a></li></ul>|;
			}
		}
	}


	&print_nav_options($dbh,$query);
	print $Site->{footer};
        print "</div>";
	return;
}

# -------   Edit Info Input ---------------------------------------------


sub edit_info_in {

	my ($dbh,$query) = @_; my $table = 'person';
	my $vars = $query->Vars;

						# Validate input user
	my $pid = $vars->{pid};
	&login_error($dbh,$query,"",&printlang("Cannot edit anon")) if ($pid eq "2");
	unless ($Person->{person_status} eq "admin" || $Person->{person_id} eq $pid) {
		&login_error($dbh,$query,"",&printlang("Not authorized"));
	}

	my ($to) = $vars->{person_email};	# Check email address
	if ($to) {
		if ($to =~ m/[^0-9a-zA-Z.\-_@]/) {
			&login_error("nil",$query,"", $errmsg.&printlang("Bad email"));
		}
						# Pre-delete email addr

		&db_update($dbh,"person",{person_email => "none"}, $pid);

	}



						# Manage Photo
	if ($vars->{file_name}) {&db_update($dbh,"person",{person_photo => &manage_photo($dbh,$query)}, $pid);}

						# Update the User Record
	&db_update($dbh,"person",$vars, $pid);
	$vars->{msg} .= qq|<p class="notice">@{[&printlang("Personal data updated")]}</p>|;


}


#   -------------------------------------------------------------------------------------
#
#   find_person
#
#   This function allows a person to identify themselves to edit their data,
#   or an administrator to find a person given name, email, etc.
#   Returns a single value, $pid   person->person_id
#
#   -------------------------------------------------------------------------------------



sub find_person {

	my ($dbh,$query) = @_;
	my $vars = $query->Vars;

							# Admin Only

	return $Person->{person_id} unless ($Person->{person_status} eq "admin");



	return $Person->{person_id} unless (		# On request only
		$vars->{pid} ||
		$vars->{ptitle} ||
		$vars->{pname} ||
		$vars->{pemail} );

	if ($vars->{pid} and
		&db_locate($dbh,"person",{		# Check ID
		person_id => $vars->{pid}})) {
		return $vars->{pid};
	}

	my $pid;					# Check Title
	if ($vars->{ptitle} and
		$pid = &db_locate($dbh,"person",{
		person_title => $vars->{ptitle}})) {
		return $pid;
	}

							# Check Name
	if ($vars->{pname} and
		$pid = &db_locate($dbh,"person",{
		person_name => $vars->{pname}})) {
		return $pid;
	}
							# Check Email
	if ($vars->{pemail} and
		$pid = &db_locate($dbh,"person",{
		person_email => $vars->{pemail}})) {
		return $pid;
	}

	&login_error($dbh,$query,"",&printlang("Could not find person"));	# Not found
	exit;
}


# -------   Manage Photo ---------------------------------------------

sub manage_photo{

	my ($dbh,$query) = @_;

                     # Identify, Save and Associate File

	my $file;
        my $pid = $vars->{pid};
        my $new_record=&db_get_record($dbh,"person",{person_id=>$pid});

	if ($query->param("file_name")) {
        	$file = &upload_file($query); 		# Uploaded File

			# Make Icon

		my $filename = $file->{file_title};
		my $filedir = $Site->{st_urlf}."files/images/";
		unless (-d $filedir) { mkdir $icondir, 0755 or &login_error($dbh,$query,"",&printlang("Error creating directory",$!,"manage_photo()",$filedir)); }
		my $icondir = $Site->{st_urlf}."files/icons/";
		unless (-d $icondir) { mkdir $icondir, 0755 or &login_error($dbh,$query,"",&printlang("Error creating directory",$!,"manage_photo()",$icondir)); }
		my $iconname = "person"."_".$new_record->{person_id}.".jpg";

		return &make_thumbnail($filedir,$filename,$icondir,$iconname);
	}
	return "";

}


# --------  Remove User ----------------------------------------------------------

sub remove_user {

	my ($dbh,$query) = @_;
	my $vars = $query->Vars;

						# Check Input
	&login_error($dbh,$query,"","Not allowed") 	# Admin only
		unless ($Person->{person_status} eq "admin");

	&login_error($dbh,$query,"","User not specified")
		unless ($vars->{person_id} > 2);


	my $pid = $vars->{person_id};


	&drop_subscription($dbh,$pid);		# Remove Subscriptions

							# Remove Person

	my $stmta = "DELETE FROM person WHERE person_id=?";
	my $stha = $dbh->prepare($stmta);
	$stha->execute($pid);
	$stha->finish(  );

								# Page header
	my $pagetitle = &printlang("User Deleted");
	$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;
	print "Content-type: text/html; charset=utf-8\n\n";

								# Page body

	print $Site->{header}.
		qq|<h3>$pagetitle</h2><p>User number $pid has been deleted.</p>|.
		$Site->{footer};

}

#   -------------------------------------------------------------------------------------
#
#
#		SUBSCRIPTION MANAGEMENT
#
#
#   -------------------------------------------------------------------------------------


# -------   Manage Subscriptions ---------------------------------------------

sub subscribe {
	my ($dbh,$query) = @_;

							# Page header
	my $pagetitle = &printlang("Manage Subscriptions");
	$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;
	print "Content-type: text/html; charset=utf-8\n\n";

	$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;  # print form
	print $Site->{header}.
	      qq|<div id="grey-box-wrapper" class="rounded-whitebox"><h2>$pagetitle</h2>
		 <form method="post" action="$Site->{script}" class="grss-skin">
		 <input type="hidden" name="action" value="add">|;
	print &subscription_form_text($dbh,$query,"manage");
	print qq|<p>&nbsp;</p><input type="submit" value="|;
	print &printlang("Update Subscriptions").qq|"></form><p>&nbsp;</p>|;
        print qq|<p><a class="return-link" href="$Site->{st_cgi}login.cgi?action=Options">Retour</a></p>|;
	#&print_nav_options($dbh,$query);
        print "</div>";
	print $Site->{footer};
}




# -------   Subscription Form Text --------------------------------------------

# Dynamic generation of subscription options

# Used by: subscribe()
#          registration_form_text()

	# Get Array of Subscriptions


sub subscription_form_text {

	my ($dbh,$query,$man) = @_;
	my $vars = $query->Vars;


						# Get Person Data
	my $pid = &find_person($dbh,$query);
	my $pdata = &db_get_record($dbh,"person",{person_id =>$pid});
	my $pname = $pdata->{person_name} || $pdata->{person_email} || $pdata->{person_id};

						# Get Person's Existing Subscriptions
	my $sub_ary_ref;
	unless ($vars->{action} eq "Register") {
		if ($man eq "manage" && ($pid eq "0" || $pid eq "2" || $pid eq "")) {
			return &printlang("No subscriptions"); }
		my $stmt = "SELECT subscription_box FROM subscription WHERE subscription_person = '$pid'";
		$sub_ary_ref = $dbh->selectcol_arrayref($stmt);
	}


						# Initialize Form Text
	my $form_text = "";
	if ($pname) { $form_text .= qq|<p>@{[&printlang("Displaying subscriptions",$pname)]}|; }
	$form_text .= qq|
		<div class="newsletter-subscribe"><p>@{[&printlang("Subscribe to newsletter...")]}</p>
		<input type="hidden" name="pid" value="$pid">
	|;


						# Get List of Subscribable Pages
	my $pages = {};
	my $sql = qq|SELECT * FROM page WHERE page_sub = 'yes' ORDER BY page_title|;
	my $sth = $dbh->prepare($sql) or &login_error($dbh,$query,"",&printlang("Cannot prepare SQL","subscription_form_text",$sth->errstr(),$sql));
	$sth->execute() or &login_error($dbh,$query,"",&printlang("Cannot execute SQL","subscription_form_text",$sth->errstr(),$sql));

						# For Each Subscribable Page...
	$form_text .= qq|<p>\n|;
	$form_text .= qq|<table>|;
	while (my $p = $sth -> fetchrow_hashref()) {

						# Does the user already subscribe?
		my $selected = "";
		if (&index_of($p->{page_id},$sub_ary_ref) > -1) {
			$selected = " checked";
		}

						# Is it a default subscribe on registration?
		if ($p->{page_autosub} eq "yes") {
			$selected = " checked";
		}

						# Create the form text for that page
		$form_text .= qq|
			<tr><td><input type="checkbox" name="newsletter" value="$p->{page_id}"|.
			qq| $selected ></input></td><td>&nbsp;</td><td>$p->{page_title}</td><tr>|;


	}
		$form_text .= qq|</table>|;
	$form_text .= qq|</p></div>\n|;
	return $form_text;


}

# -------   Add Subscription -------------------------------------------------

sub add_subscription {

	my ($dbh,$query,$pid) = @_;
	my $vars = $query->Vars;
						# Determine Person ID
	$pid ||= $vars->{pid};
	&login_error($dbh,$query,"",&printlang("No ID number")) unless ($pid);
	&login_error($dbh,$query,"",&printlang("Cannot edit anon")) if ($pid eq "2");

						# Validate User
	unless ($Person->{person_status} eq "admin" || $Person->{person_id} eq $pid) {
		&login_error($dbh,$query,"",&printlang("Not authorized"));
	}

	unless ($vars->{action} eq "New") {	# Remove Previous Subscriptions
		&drop_subscription($dbh,$pid);
	}

	unless ($vars->{newsletter}) {
		$vars->{msg} .= qq|<p class="notice">@{[&printlang("No longer subscribed")]}</p>|;
		return;
	}

					# Insert Subscriptions
	my @nls = split /\0/,$vars->{newsletter};


	foreach my $newsl (@nls) {
		my $nl={};
		$nl->{subscription_box} = $newsl;
		$nl->{subscription_person} = $pid;
		$nl->{subscription_crdate} = time;
		my $sub = &db_insert($dbh,$query,"subscription",$nl);
		unless ($sub) {
			&login_error($dbh,$query,"",&printlang("Subscription failed"));
		}
	}

						# Notify
	$vars->{msg} .= qq|<p class="notice">@{[&printlang("Subscriptions have been updated")]}.</p>|;
	#&notify_subscribe($person_id,"Subscribe",$sb);
	return;
}



# -------   Unsubscribe ------------------------------------------------------

sub unsubscribe {

	my ($dbh,$query,$newsletter) = @_;
	$newsletter = "Newsletter";
	my $vars = $query->Vars;
	$vars->{sid} =~ s/\s//g;			# Clean email address

							# Find person
	unless (&db_locate($dbh,"person",{person_id => $vars->{pid},person_email => $vars->{sid}})) {
		&login_error($dbh,$query,"",&printlang("Unsubscribe user not found",$vars->{pid},$vars->{sid}));
	}

							# Find associated subscription
	unless (&db_locate($dbh,"subscription",{subscription_person => $vars->{pid}})) {
		&login_error($dbh,$query,"",&printlang("Subscription not found",$newsletter));
	}

	&drop_subscription($dbh,$vars->{pid});		# Drop subscription


							# Page header
	my $pagetitle = &printlang("Unsubscribe",$newsletter);
	$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;
	print "Content-type: text/html; charset=utf-8\n\n";

							# Page Body
	my $msg = qq|<h2>$pagetitle</h2><p>@{[&printlang("Subscription cancelled",$vars->{sid},"$Site->{st_url}options.htm")]}</p>|;
	my $subj = qq|@{[printlang("Unsubscribe",$Site->{st_name})]}|;
	print $Site->{header}.$msg.$Site->{footer};

							# Send Emails
	&send_email($vars->{sid},$Site->{em_from},$subj,$msg,"htm");
	&send_email($Site->{em_copy},$Site->{em_from},$subj,$msg,"htm");

	exit;
}



# -------   Drop Subscription ------------------------------------------------

# Called by add_subscription()


sub drop_subscription {

	my ($dbh,$person_id) = @_;
	return unless ($person_id);
						# Remove Subscriptions

	my $stmt = "DELETE FROM subscription WHERE subscription_person=?";
	my $sth = $dbh->prepare($stmt);
	$sth->execute($person_id);
	$sth->finish(  );

}

#   -------------------------------------------------------------------------------------
#
#
#		PASSWORD MANAGEMENT
#
#
#   -------------------------------------------------------------------------------------


# --------  Password Check ------------------------------------------------------

sub password_check {

	my ($inputpwn,$dbpwd,$msg) = @_;
	$msg ||= "Login Error";



	return 1 if ($dbpwd eq crypt($inputpwn, $dbpwd));	# Salted crypt match
	&anonymous($Person);
	my $errmsg = qq|@{[&printlang("Login error")]}<br/>
			@{[&printlang("Incorrect password")]}<br/>
			@{[&printlang("Recover registration",$Site->{st_cgi}."login.cgi?refer=$vars->{refer}&action=Email")]}|;
	&login_error($dbh,$query,"",$errmsg);
	exit;



}

#   -------------------------------------------------------------------------------------
#
#   email_password
#
#   Form to request password sent to the user's email address
#
#   -------------------------------------------------------------------------------------

sub email_password {
	my ($dbh,$query) = @_;


				# Page header
	my $pagetitle = &printlang("Password reset",$Site->{st_name});

	$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;
	print "Content-type: text/html; charset=utf-8\n\n";

				# Page Body
	print $Site->{header} .
		qq|<div id="grey-box-wrapper" class="rounded-whitebox"><h2>$pagetitle</h2>
		<p><form method="post" action="$Site->{script}" class="grss-skin">\n
		<p><label>@{[&printlang("Reset instructions")]}</label>
		<input type="hidden" name="refer" value="$vars->{refer}">
		<input type="text" size="40" name="person_email">\n
		<input type="hidden" name="action" value="Send"></p>\n
		<p><input class="leave-space-above leave-space-below" type="submit" value="@{[&printlang("Click here")]}"></p>
		</form>\n</p>|;							# End form


	&print_nav_options($dbh,$query);
	print "</div>";
	print $Site->{footer};
}



#   -------------------------------------------------------------------------------------
#
#   send_password
#
#   Sends password to the user's email address
#
#   -------------------------------------------------------------------------------------

sub send_password {
	my ($dbh,$query) = @_;
	my $vars = $query->Vars;

	# Find the person by name, title or email

	unless ($vars->{person_email}) { &login_error($dbh,$query,"",&printlang("Enter something")); }
	my $person = &db_get_record($dbh,'person',{person_email => $vars->{person_email}});
	unless ($person) { $person = &db_get_record($dbh,'person',{person_title => $vars->{person_email}}); }
	unless ($person) { $person = &db_get_record($dbh,'person',{person_name => $vars->{person_email}}); }
	unless ($person) { &login_error($dbh,$query,"",&printlang("Person not found",$vars->{person_email})); }

	# Make sure they have an email address
	unless ($person->{person_email}) { &login_error($dbh,$query,"",&printlang("Could not find email")); }

	# We generate a random string, store it in $person->{person_midm}, then send it as a key
	# to reset the password

	my $reset_key = &generate_random_string(64);
	&db_update($dbh,"person",{person_midm=>$reset_key},$person->{person_id});


	# Send reset link

	$Site->{st_name} =~ s/&#39;/'/g;
	&send_email($person->{person_email},$person->{person_email},&printlang("To reset your password",$Site->{st_name}),
		&printlang("Reset message",$Site->{st_name},"$Site->{st_cgi}login.cgi?action=reset&key=$person->{person_id},$reset_key"),"htm");

	# Page header
	my $pagetitle = &printlang("Password reset",$Site->{st_name});
	$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;
	print "Content-type: text/html; charset=utf-8\n\n";

	# Page Body
	print $Site->{header} . qq|
		<h2>$pagetitle</h2><p>&nbsp;</p>
		<p>@{[&printlang("Sent reset URL")]}.</p><p>&nbsp;</p>|;
	print $Site->{footer};





}

#   -------------------------------------------------------------------------------------
#
#   reset_password
#
#   Resets password and sends to the user's email address
#   Requires key cerated by send_password
#
#   -------------------------------------------------------------------------------------

sub reset_password {

	my ($dbh,$query) = @_;
	my $vars = $query->Vars;


	my ($id,$key) = split ",",$vars->{key};

	my $person = &db_get_record($dbh,'person',{person_id => $id});
	&login_error($dbh,"","",&printlang("Blank midm")) unless ($person->{person_midm});
	&login_error($dbh,"","",&printlang("Reset key expired")) if ($person->{person_midm} eq "expired");")"
	&login_error($dbh,"","",&printlang("Key mismatch")) unless ($person->{person_midm} eq $key);

	my $new_password = generate_random_string(10);
	my $encryptedPsw = &encryptingPsw($new_password, 4);
	&db_update($dbh,"person",{person_password=>$encryptedPsw},$id);

	my $expired = "expired";
	&db_update($dbh,"person",{person_midm=>$expired},$id);

	if ($person->{person_email}) {

				# Send the password
		$Site->{st_name} =~ s/&#39;/'/g;
		&send_email($person->{person_email},$person->{person_email},
			&printlang("Password reset",$Site->{st_name}),&printlang("Has been reset",$person->{person_title},$new_password),"htm");

				# Page header
		my $pagetitle = &printlang("Password reset",$Site->{st_name});
		$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;
		print "Content-type: text/html; charset=utf-8\n\n";

		print $Site->{header} . qq|
			<h2>$pagetitle</h2><p>&nbsp;</p>
			<p>@{[&printlang("Password emailed","$Site->{st_cgi}login.cgi")]}</p>|;
	#	&print_nav_options($dbh,$query);
		print $Site->{footer};


	} else {

		&login_error($dbh,$query,"",&printlang("Could not find email"));

	}
	exit;

}


#   -------------------------------------------------------------------------------------
#
#   change_password_screen
#
#   Input screen to change password
#
#   -------------------------------------------------------------------------------------

sub change_password_screen {

	my ($dbh,$query) = @_;
	my $vars = $query->Vars;

			# Page Header
	my $pagetitle = &printlang("Change password");
	print "Content-type: text/html; charset=utf-8\n\n";
	$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;

			# Page Body
	print $Site->{header} . qq|
                        <div id="grey-box-wrapper" class="rounded-whitebox">
			<form method="post" action="$Site->{st_cgi}login.cgi" class="grss-skin">
			<input type="hidden" name="action" value="changepwdinp">
			<h2>$pagetitle</h2>
                        <p><label>@{[&printlang("Old Password")]}:</label> <input type="password" name="op" size="20"></p>
			<p><label>@{[&printlang("New Password")]}:</label> <input type="password" name="npa" size="20"></p>
			<p><label>@{[&printlang("New Password (Again)")]}:</label> <input type="password" name="npb" size="20"></p>

			<p><input class="leave-space-above" type="submit" value="@{[&printlang("Change Password")]}"></p>
			</form>
                        </div>
			 |;
	#	&print_nav_options($dbh,$query);
		print $Site->{footer};


	exit;

}


#   -------------------------------------------------------------------------------------
#
#   change_password_input
#
#   Input screen to change password
#
#   -------------------------------------------------------------------------------------

sub change_password_input {

	my ($dbh,$query) = @_;
	my $vars = $query->Vars;
	my $error = "";



	$error = &printlang("Password Change Error")."<br><br>".&printlang("Attempting to change password: incorrect old password");
	&login_error($dbh,"","",$error) unless &password_check($vars->{op},$Person->{person_password},&printlang("Password Change Error"));

	$error = &printlang("Password Change Error")."<br><br>".&printlang("New password blank");
	&login_error($dbh,"","",$error) unless ($vars->{npa});

	$error = &printlang("Password Change Error")."<br/>".&printlang("New password match");
	&login_error($dbh,"","",$error) unless ($vars->{npa} eq $vars->{npb});

	my $encryptedPsw = &encryptingPsw($vars->{npa}, 4);
	&db_update($dbh,"person",{person_password=>$encryptedPsw},$Person->{person_id});

				# Page Header
	my $pagetitle = &printlang("Change password");
	$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;
	print "Content-type: text/html; charset=utf-8\n\n";

				# Page Body
	print $Site->{header} . qq|
			<h2>$pagetitle</h2><p>&nbsp;</p>
			<p>@{[&printlang("Password changed")]}<br/><br/>
			<a href="$Site->{st_cgi}login.cgi">@{[&printlang("New password login")]}</a>.
			 </p>|;
	&print_nav_options($dbh,$query);
	print $Site->{footer};

	exit;

}


#   -------------------------------------------------------------------------------------
#
#   form_socialnet
#
#   Input social network information
#
#   -------------------------------------------------------------------------------------


sub form_socialnet {


	my ($dbh,$query,$man) = @_;
	my $vars = $query->Vars;

#	my $alterstmt = "ALTER TABLE person MODIFY person_socialnet text";
#	my $asth = $dbh -> prepare($alterstmt);
#	$asth -> execute();

						# Get Person Data
	my $pid = &find_person($dbh,$query);
	my $pdata = &db_get_record($dbh,"person",{person_id =>$pid});
	my $pname = $pdata->{person_name} || $pdata->{person_email} || $pdata->{person_id};
	my $record = &db_get_record($dbh,'person',{person_id => $pid});

				# Page Header
	my $pagetitle = &printlang("Edit social networks");
	$Site->{header} =~ s/\Q[*page_title*]\E/$pagetitle/g;
	print "Content-type: text/html; charset=utf-8\n\n";

				# Page Body
	print $Site->{header} .
		qq|<h4>$pagetitle</h4>
		$vars->{msg}.
		<p>@{[&printlang("Social network instructions",$Site->{st_name},$Site->{st_name})]}</p>
		<p><form method="post" action="$Site->{st_cgi}login.cgi" class="grss-skin">
		<input type="hidden" name="action" value="update_socialnet">
		<input type='hidden' name='refer' value='$vars->{refer}'>
		<input type='hidden' name='pid' value='$pid'>
		<table cellpadding="2" cellspacing="0" border="1">
		<tr><td><i>@{[&printlang("Network")]}</i></td>
		<td><i>@{[&printlang("Your ID")]}</i></td><td><i>@{[&printlang("Public?")]}</i></td></tr>|;

	my $sni = $record->{person_socialnet};	# Existing social networks
	my @snil = split ";",$sni;
	my $count = 0;
	foreach my $sn (@snil) {
		$count++;
		my ($netname,$netid,$netok) = split ",",$sn;
		print qq|
			<tr>
			<td><input type="text" size="20" name="netname$count" value="$netname"></td>
			<td><input type="text" size="20" name="netid$count" value="$netid"></td>
			<td><input type="checkbox" name="netok$count" value=" checked"$netok></td>
			</tr>
		|;


	}
	$count++;				# Add a new social network
	my @titleslist = qw(Facebook Twitter);
	print qq|
		<tr>
		<td><select name="netname$count">
		|;
	foreach my $snt (@titleslist) { print qq|
		<option value="$snt">$snt</option>|;
	}
	print qq|
		</select>
		</td>
		<td><input type="text" size="20" name="netid$count" value="$netid"></td>
		<td><input type="checkbox" name="netok$count" value=" checked"$netok></td></tr>
		<td colspan=3><input type="submit" value="@{[&printlang("Update Social Network Information")]}"></td></tr>
		</table>
		</form></p>
	|;

	print $Site->{footer};
}



#   -------------------------------------------------------------------------------------
#
#   submit_socialnet
#
#   Submit social network information
#
#   -------------------------------------------------------------------------------------

sub update_socialnet {


	my ($dbh,$query,$man) = @_;
	my $vars = $query->Vars;
#print "Content-type: text/html\n\n";
#while (my ($vx,$vy) = each %$vars) { print "$vx = $vy <br>"; }

						# Get Person Data
	my $pid = &find_person($dbh,$query);
	my $pdata = &db_get_record($dbh,"person",{person_id =>$pid});
	my $pname = $pdata->{person_name} || $pdata->{person_email} || $pdata->{person_id};
	my $record = &db_get_record($dbh,'person',{person_id => $pid});

	my $count = 0; my $snstring = "";
	while ($count < 1000) { 	# Huge upper limit on these
		$count++;
		my $netnamefield = "netname".$count;
		my $netidfield = "netid".$count;
		my $netokfield = "netok".$count;
		my $addstr = "";
		if ($vars->{$netnamefield} && $vars->{$netidfield}) {
			$addstr = $vars->{$netnamefield}.",".$vars->{$netidfield}.",".$vars->{$netokfield};
		}


		# Stop when we're done, but make sure we're definitely done
		unless ($vars->{$netnamefield}) { unless ($vars->{$netnameid}) { last }};
		if ($snstring) { $snstring .= ";"; }
		$snstring .= $addstr;

	}
#	print "Updating person $pid with $snstring <br>";
	if ($snstring) { &db_update($dbh,"person",{person_socialnet=>$snstring},$pid); }
	&form_socialnet($dbh,$query,$man);

}

sub login_error {

	my ($dbh,$query,$person,$msg,$supl) = @_;
	my $vars = ();
	if (ref $query eq "CGI") { $vars = $query->Vars; }
	if ($vars->{mode} eq "silent") { exit; }
	if ($person eq "api") {
		print qq|<p class="notice">$msg</p>|;
		exit;
	}

						# Page header

  print "Content-type: text/html\n\n";
  print qq|<div class="error"><b>Error</b>: $msg</div>|;


	if ($dbh) { $dbh->disconnect; }
	exit;
}
 #

1;
