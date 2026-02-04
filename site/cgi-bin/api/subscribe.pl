
# API SUBSCRIPTION FORM ---------------------------------------------------------- "
# ------- Page -----------------------------------------------------
#
# Subscribe to a page - form
#
# Generic request for a subscription form
# Autogenerates capcha that must be filled
#
# -------------------------------------------------------------------------

sub api_subscription_form {

	# Get the list of pages to which you can subscribe by email
	my @page_list = &db_get_record_list($dbh,"page",{page_type => "mailgun"});
	my $page_selection;
	foreach my $page_id (@page_list) {
		my $page = &db_get_record($dbh,"page",{page_id=>$page_id});
		$page_selection .= qq|
		<input class="listinput" type="radio" name="page_id" id="$page_id" value="$page_id">
			<label for="$page_id">$page->{page_title}</label>|;
	}
print qq|
	<style>
		.listinput {
			display: none;
		}

		.listform label{
			position: relative;
			max-width: 20em; width: 20em; margin: 0;
			color: #000;
			background-color: #fff;
			font-size: 1em;
			text-align: center;
			height: 2.5em;
			line-height: 2em;
			display: block;
			cursor: pointer;
			border: 1px solid blue;
			-webkit-box-sizing: border-box;
			-moz-box-sizing: border-box;
			box-sizing: border-box;
		}

		.listform input:checked + label{
			border: 3px solid #333;
			background-color: #2fcc71;
		}
	</style>
	<p><form class="listform" method="post" action="|.$Site->{st_cgi}.qq|api.cgi">
	<input type="hidden" name="cmd" value="subscribe">
	$page_selection
	Email: <input type="email" name="email" style="width:15em;">|.
	qq|<input type="submit" class="button" value="Subscribe">
	</form></p>
|;
exit;



}



sub set_capcha {

	# Set up captcha
	my $captchas = ""; my $capt_text = "";
	if ($Site->{st_capcha_on} eq "yes") {			# Using capchas? (st_capcha_on = yes)

		if ($captchas = &get_captcha_table()) {
			my @capkeys = keys %$captchas;
			my $caplen = scalar @capkeys;
			my $cap_sel = rand($caplen);

			$capt_text =  qq|<div id="captcha">
			<p><label>@{[&printlang("Enter capcha text")]}</label><br>
			<img src="$Site->{st_url}images/captchas/|.
			@capkeys[$cap_sel].qq|.jpg" alt="|.@capkeys[$cap_sel].
			qq|"><input type='hidden' name='captcha_index' value='|.
			@capkeys[$cap_sel].qq|'>
			<span id="captcha-wrapper">
			<input type='text' size="10" name='captcha_submit'>
			</span></p></div>|;
		} else {
			return @{[&printlang("Captcha table not found")]}.": ". $Site->{data_dir}."captcha_table.txt";
		}
	}
   return $capt_text;

}


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

# API SUBSCRIBE ---------------------------------------------------------- "
# ------- Page -----------------------------------------------------
#
# Subscribe to a page
#
# expects vars->{page_id} and vars->{email}
# if capcha is enabled expects two capcha values as well
#
# -------------------------------------------------------------------------

sub api_subscribe {

  	# Verify Input
	my $email = $vars->{email};
	my $page_id = $vars->{page_id};
  	unless ($email) { &status_error("No email address provided to subscribe"); };
	unless ($vars->{page_id}) { &status_error("No page id provided to subscribe"); }
  	my $page = &db_get_record($dbh,"page",{page_id=>$page_id});
	unless ($page) { &status_error("Mailing list page does not exist."); }

	# Captcha Test
	my $captchas;
	if ($captchas = &get_captcha_table()) {
		  unless ( $vars->{captcha_submit} eq $captchas->{$vars->{captcha_index}}) {
	   	print "Incorrect Captcha.";
			exit;
		}
	} else {
		#print "Captcha table not found.";
	}


  	# Check email address
	# use Mail::CheckUser qw(check_email);
	#  my $is_valid = &check_email($vars->{email});
	my $is_valid = 1;

  	# If email is valid
	if( $is_valid ) {

	   # Create a code
		my $code = $vars->{page_id} + time;
		$code = $code*55;

    	# Generate email text
		my $listid = $page->{page_listid} || $page->{page_title};
		my $url = $Site->{st_cgi}."api.cgi?cmd=confirm&page_id=$page_id&email=$email&code=$code";
	    my $pgtitle = "Subsciption request for $listid";
		my $sitename = $Site->{st_name} || $Site->{st_url};
    	my $pgcontent = qq|<p style="margin:10%;">
			Someone, probably you, has requested to subscribe to $listid on $sitename.
		    Please click on or load the following URL into your web browser in order to confirm:<br><br>
			<a href="$url">$url</a>
			<br><br>Thank you.</p>|;

		# Send email
		my $res;
		if ($page->{page_type} eq "mailchimp")	{&status_error("Mailchimp not currently supported");exit;}
		elsif ($page->{page_type} eq "mailgun")	{
			$res = &send_mailgun_email($pgcontent,$pgtitle,$email);	# send using mailgun
		}
		else { 	&status_error("You can't subscribe to this page");	}

		# Print landing page
		return "<p>Thank you. An email has been sent to ".$vars->{email}.
			" Please check your email inbox to confirm your subscription.</p>".
			"<p>Note that if the email does not appear in your inbox this means that ".
			$Site->{st_pub}." may be blocked by your email administrator. If so, you will need to ensure that ".
			$Site->{st_pub}." is whitelisted in order to receive this newsletter.";

		&status_ok($vars->{div},$res->{message});
		exit;

	}
	else {
	  # Email is *not* valid:
	  &status_error("We cannot confirm that $email is a valid email address. Please contact us directly to subscribe to this mailing list");
		exit;
	}

}



# API UNSUBSCRIBE ---------------------------------------------------------- "
# ------- Page -----------------------------------------------------
#
# Unsubscribe from a page
#
# expects vars->{page_id} and vars->{email}
# if capcha is enabled expects two capcha values as well
#
# -------------------------------------------------------------------------

sub api_unsubscribe_form {

print qq|

	<p><form method="post" action="https://www.downes.ca/cgi-bin/api.cgi">
	<input type="hidden" name="cmd" value="unsubscribe">
	<input type="radio" name="page_id" value="2"> OLDaily<br>
	<input type="radio" name="page_id" value="3"> OLWeekly<br>
	<input type="text" name="email" size=60>
	<input type="submit" value="Unubscribe">
	</form>
|;
exit;



}

# API UNSUBSCRIBE ---------------------------------------------------------- "
# ------- Page -----------------------------------------------------
#
# Unsubscribe from a page
#
# expects vars->{page_id} and vars->{email}
# if capcha is enabled expects two capcha values as well
#
# -------------------------------------------------------------------------

sub api_unsubscribe {

  # Verify Input
  unless ($vars->{email}) { print "No email address provided to unsubscribe"; exit; };
	unless ($vars->{page_id}) { print "No page id provided to unsubscribe" ; exit; }

  my $page = &db_get_record($dbh,"page",{page_id=>$vars->{page_id}});
	unless ($page) { print "Mailing list page does not exist." ; exit; }

  my $subscriber = &db_get_record($dbh,"person",{person_email=>$vars->{email}});
	unless ($subscriber) { print "This email doesn't exist in our records."; exit; }

	my $result = &graph_delete("person",$subscriber->{person_id},"page",$vars->{page_id},"subscribe");

  # Print landing page
	print "<p>Thank you. You have been unsubscribed. Sorry to see you go.";

  # Generate email text
	my $page = &db_get_record($dbh,"page",{page_id=>$vars->{page_id}});
	my $admintext = "<p>Someone, probably you, has requested to unsubscribe to ".$page->{page_title}." on ".$Site->{st_name}.
		   ". If this was in error you can subscribe again at ".$Site->{st_url}."subscribe.htm";
	my $subject = $Site->{st_name}." Unsubscription verification";
	$subject =~ s/&#39;/'/g;

	# Send confirmation email
	&send_email($vars->{email},$Site->{st_pub},$subject,$admintext,"htm");
	&send_email('stephen@downes.ca',$Site->{st_pub},"Unsubscription",$vars->{email}.
		" has unsubscribed from ".$page->{page_title},"htm");

}

sub api_confirm {

	my $email = $vars->{email}; unless ($email) { &status_error("No email address provided to confirm"); };
	my $page_id = $vars->{page_id}; unless ($page_id) { &status_error("No page id provided to confirm"); }
	unless ($vars->{code}) { &status_error("No code provided to confirm"); }

	# Check Confirmation Code
  	my $code = $vars->{code}/55;
	my $subtime = $code - $vars->{page_id};    # Time subscription was submitted
	my $day = (60*60*24);
	if ($subtime < (time-$day) || $subtime > (time+$day)) {
		&status_error(qq|<p>Sorry, this subscription request has expired.
		Please <a href="$Site->{st_url}subscribe.htm">visit the subscribe page</a> and try again.</p>|);
	}

	# Get list (ie., page) information
	my $page = &db_get_record($dbh,"page",{page_id=>$page_id});
	unless ($page) { &status_error("Mailing list page does not exist."); }
	my $listid = $page->{page_listid} || $page->{page_title};
	unless ($listid) { &status_error("Mailing list page has no title or listid."); }

	# Add email to mailing list
	my $res;
	if ($page->{page_type} eq "mailchimp")	{&status_error("Mailchimp not currently supported");exit;}
	elsif ($page->{page_type} eq "mailgun")	{ $res = &mailgun_subscribe_confirm($email,$listid); }
	else { 	&status_error("You can't subscribe to this page");	}

	# Print landing page
	return "<p>Your subscription to ".$page->{page_title}." has been confirmed.</p>";

	exit;

}


1;