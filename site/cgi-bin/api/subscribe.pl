
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
	my @page_list = &db_get_record_list($dbh,"page",{page_sub => "yes"});
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
		.hp { position: absolute; left: -5000px; }
	</style>
	<p><form class="listform" method="post" action="|.$Site->{st_cgi}.qq|api.cgi">
	<input type="hidden" name="cmd" value="subscribe">
	$page_selection
	Email: <input type="email" name="email" style="width:15em;">
	<div class="hp"><label for="website">Leave this field empty</label><input type="text" name="website" id="website" value="" autocomplete="off" tabindex="-1"></div>|.
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

	# Honeypot: bots fill in the website field; real users never see it
	if ($vars->{website}) {
		my $logfile = $Site->{data_dir} . "honeypot.log";
		if (open my $log, '>>', $logfile) {
			printf $log "%s\t%s\t%s\t%s\n",
				scalar localtime, $ENV{REMOTE_ADDR}, $vars->{email}, $vars->{page_id};
			close $log;
		}
		print "<p>Thank you for subscribing.</p>";
		exit;
	}

  	# Verify Input
	my $email = $vars->{email};
	my $page_id = $vars->{page_id};
  	unless ($email) { &status_error("No email address provided to subscribe"); };
	unless ($vars->{page_id}) {
		# No newsletter selected — show a picker with the email pre-filled
		my $sth = $dbh->prepare(qq|SELECT page_id, page_title FROM page WHERE page_sub='yes' ORDER BY page_title|);
		$sth->execute();
		my $buttons = '';
		while (my ($pid, $ptitle) = $sth->fetchrow_array()) {
			$buttons .= qq|<p><button type="submit" name="page_id" value="$pid" class="button">$ptitle</button></p>\n|;
		}
		print qq|<p>Please select a newsletter to subscribe <b>$email</b> to:</p>
<form method="post" action="$Site->{st_cgi}api.cgi">
<input type="hidden" name="cmd" value="subscribe">
<input type="hidden" name="email" value="$email">
<div style="position:absolute;left:-5000px"><input type="text" name="website" value="" autocomplete="off" tabindex="-1"></div>
$buttons
</form>
<p><a href="$Site->{st_url}">Cancel</a></p>|;
		exit;
	}
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


  	# Check email address: reject multiple addresses and header injection attempts
	if ($email =~ /[,;\r\n]/) {
		&status_error("Please enter a single valid email address.");
	}
	unless ($email =~ /^[^\@\s,;]+\@[^\@\s,;]+\.[^\@\s,;]{2,}$/) {
		&status_error("Please enter a valid email address.");
	}
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
		elsif ($page->{page_type} eq "ses")	{
			$res = &send_ses_email($pgcontent,$pgtitle,$email);		# send using Amazon SES
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

    my @page_list = &db_get_record_list($dbh, "page", {page_sub => "yes"});
    my $page_selection = '';
    foreach my $pid (@page_list) {
        my $page = &db_get_record($dbh, "page", {page_id => $pid});
        $page_selection .= qq|<input type="radio" name="page_id" value="$pid"> $page->{page_title}<br>\n|;
    }
    my $email = $vars->{email} || '';

    print qq|
<p><form method="post" action="$Site->{st_cgi}api.cgi">
<input type="hidden" name="cmd" value="unsubscribe">
$page_selection
<input type="text" name="email" value="$email" size=60 placeholder="Your email address">
<input type="submit" value="Unsubscribe">
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

    # Verify input
    unless ($vars->{email})   { print "No email address provided to unsubscribe"; exit; }
    unless ($vars->{page_id}) { print "No page id provided to unsubscribe"; exit; }

    my $email   = lc($vars->{email});
    my $page_id = $vars->{page_id};

    my $page = &db_get_record($dbh, "page", {page_id => $page_id});
    unless ($page) { print "Mailing list page does not exist."; exit; }

    # Update subscriber table — handles both one-click POST and browser GET
    $dbh->do(qq|
        UPDATE subscriber SET subscriber_status = 'unsubscribed'
        WHERE LOWER(subscriber_email) = ? AND subscriber_list = ?
    |, undef, $email, $page_id);

    # One-click POST (RFC 8058) — return 200 with no body
    if ($ENV{REQUEST_METHOD} eq 'POST') {
        exit;
    }

    # Browser GET — show confirmation page
    my $listname = $page->{page_title} || "the mailing list";
    print "<p>You have been unsubscribed from $listname. Sorry to see you go.</p>";
    exit;

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
	elsif ($page->{page_type} eq "ses")	{ $res = &ses_subscribe_confirm($email,$page_id); }
	else { 	&status_error("You can't subscribe to this page");	}

	# Print landing page
	return "<p>Your subscription to ".$page->{page_title}." has been confirmed.</p>";

	exit;

}


1;