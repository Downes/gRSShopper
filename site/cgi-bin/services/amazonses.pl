
# Amazon SES email service functions
# Equivalent to mailgun.pl but sends via Amazon SES SMTP
# Credentials stored in site config: ses_smtp_user, ses_smtp_password
# SMTP server: email-smtp.us-east-1.amazonaws.com port 587 (STARTTLS)

sub send_ses_email {

	# Send a single email via SES
	# Recipient must be an email address (unlike Mailgun, SES does not support list aliases here)
	my ($pgcontent, $pgtitle, $recipient) = @_;

	my $smtp = &set_up_ses();
	my $res = &ses_message($smtp, $recipient, $pgtitle, $pgcontent);
	$smtp->quit();
	return $res;

}


# Subscribes user to a list and sends confirmation email
sub ses_subscribe_confirm {

	my ($email, $page_id) = @_;

	# Insert into subscriber table (confirmed now)
	my $sth = $dbh->prepare(qq|
		INSERT IGNORE INTO subscriber
			(subscriber_email, subscriber_list, subscriber_status, subscriber_crdate, subscriber_confirmed)
		VALUES (?, ?, 'active', ?, ?)
	|);
	$sth->execute($email, $page_id, time, time);

	# Get list title for confirmation message
	my $page = &db_get_record($dbh, "page", {page_id => $page_id});
	my $listname = $page->{page_title} || "the mailing list";

	# Send confirmation email
	my $smtp = &set_up_ses();
	&ses_message($smtp, $email, "Subscription confirmed", "You've been added to the $listname mailing list.");
	$smtp->quit();

	return 1;

}


sub set_up_ses {

	eval "use Net::SMTP";
	if ($@) { &status_error("Net::SMTP module is required to send Amazon SES email."); }

	unless ($Site->{ses_smtp_user} && $Site->{ses_smtp_password}) {
		&status_error("Please define ses_smtp_user and ses_smtp_password in site config.");
	}

	my $server = $Site->{ses_smtp_server} || "email-smtp.us-east-1.amazonaws.com";

	my $smtp = Net::SMTP->new(
		$server,
		Port    => 587,
		Timeout => 30,
		Debug   => 0,
	) or &status_error("Cannot connect to SES SMTP server: $server");

	$smtp->starttls() or &status_error("SES SMTP STARTTLS failed");
	$smtp->auth($Site->{ses_smtp_user}, $Site->{ses_smtp_password})
		or &status_error("SES SMTP authentication failed");

	return $smtp;

}


sub ses_message {

	my ($smtp, $recipient, $pgtitle, $pgcontent, $page_id) = @_;

	# From
	my $from = $Site->{st_email};
	unless ($from) { &status_error("Please define a site email address in Admin:General first"); }

	# Subject
	$pgtitle ||= "No subject";

	# Body
	unless ($pgcontent) { &status_error("Email doesn't contain any content"); }

	# Encode to avoid wide character issues
	use Encode qw(encode);
	$pgtitle   = encode('UTF-8', $pgtitle);
	$pgcontent = encode('UTF-8', $pgcontent);

	# Send via SMTP
	$smtp->mail($from);
	$smtp->to($recipient);
	$smtp->data();
	$smtp->datasend("From: $from\n");
	$smtp->datasend("To: $recipient\n");
	$smtp->datasend("Subject: $pgtitle\n");
	$smtp->datasend("MIME-Version: 1.0\n");
	$smtp->datasend("Content-Type: text/html; charset=UTF-8\n");
	if ($page_id) {
		(my $encoded_email = $recipient) =~ s/\+/%2B/g;
		my $unsub_url = $Site->{st_cgi} . "api.cgi?cmd=unsubscribe&email=$encoded_email&page_id=$page_id";
		$smtp->datasend("List-Unsubscribe: <$unsub_url>\n");
		$smtp->datasend("List-Unsubscribe-Post: List-Unsubscribe=One-Click\n");
	}
	$smtp->datasend("\n");
	$smtp->datasend($pgcontent);
	$smtp->dataend();

	return 1;

}


sub ses_send_newsletter {

	my ($pgcontent, $pgtitle, $page_id, $send_list, $since) = @_;

	my $smtp = &set_up_ses();

	# Test mode: send to admin email only
	if ($send_list =~ /admin/i) {
		my $admin_email = $Site->{st_email};
		unless ($admin_email) { &status_error("No site email defined in Admin:General"); }
		&ses_message($smtp, $admin_email, $pgtitle, $pgcontent);
		$smtp->quit();
		return 1;
	}

	# Real send: query active subscribers, optionally skipping those already sent
	# $since is a Unix timestamp — skip anyone whose subscriber_lastsent >= $since
	my $since_clause = $since ? "AND (subscriber_lastsent IS NULL OR subscriber_lastsent < ?)" : "";
	my $sth = $dbh->prepare(qq|
		SELECT subscriber_id, subscriber_email FROM subscriber
		WHERE subscriber_list = ? AND subscriber_status = 'active'
		$since_clause
		ORDER BY subscriber_email
	|);
	$since ? $sth->execute($page_id, $since) : $sth->execute($page_id);

	my $count = 0;
	while (my ($id, $email) = $sth->fetchrow_array()) {
		# Reconnect every 200 messages to avoid SMTP session timeout
		if ($count > 0 && $count % 200 == 0) {
			$smtp->quit();
			$smtp = &set_up_ses();
		}
		&ses_message($smtp, $email, $pgtitle, $pgcontent, $page_id);
		# Record send time so a partial send can be resumed without duplicates
		$dbh->do("UPDATE subscriber SET subscriber_lastsent = ? WHERE subscriber_id = ?",
			undef, time(), $id);
		print ". ";
		$count++;
	}

	$smtp->quit();
	return $count;

}

1;
