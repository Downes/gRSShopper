
# SES Bounce/Complaint webhook handler
# Called by Amazon SNS when SES reports a bounce or complaint
# Endpoint: api.cgi?cmd=ses_bounce
#
# Setup: In SES console → Verified identities → your domain → Notifications,
# set Bounce and Complaint topics to an SNS topic subscribed to this endpoint.

sub api_ses_bounce {

	my ($query) = @_;

	# Read raw POST body — SNS sends application/json, stored by CGI.pm as POSTDATA
	my $body = $query->param('POSTDATA');
	&status_error("No body received") unless $body;

	# Parse outer SNS envelope
	use JSON;
	my $msg = eval { decode_json($body) };
	&status_error("Invalid JSON: $@") if $@;

	# Verify SNS signature before trusting any content
	&status_error("SNS signature verification failed") unless &verify_sns_signature($msg);

	# SNS subscription confirmation — fetch the SubscribeURL to activate the subscription
	if ($msg->{Type} eq 'SubscriptionConfirmation') {
		use LWP::UserAgent;
		my $ua = LWP::UserAgent->new(timeout => 10);
		$ua->get($msg->{SubscribeURL});
		use JSON;
		print to_json({ status => "OK", message => "SNS subscription confirmed" }, {pretty => 1});
		exit;
	}

	# Notification — parse the inner SES message
	exit unless $msg->{Type} eq 'Notification';
	my $ses = eval { decode_json($msg->{Message}) };
	exit unless $ses;

	my $notification_type = $ses->{notificationType};

	if ($notification_type eq 'Bounce') {

		# Increment fail counter for all bounce types (permanent and transient).
		# Spam-based rejections are often content-dependent and may resolve, so
		# we treat them the same as transient failures rather than insta-banning.
		# Mark as bounced once the counter reaches 6.
		for my $recipient (@{$ses->{bounce}{bouncedRecipients}}) {
			my $email = lc($recipient->{emailAddress});
			$dbh->do(qq|
				UPDATE subscriber
				SET subscriber_failcount = subscriber_failcount + 1,
				    subscriber_status = IF(subscriber_failcount + 1 >= 6, 'bounced', subscriber_status)
				WHERE LOWER(subscriber_email) = ?
				AND subscriber_status = 'active'
			|, undef, $email);
		}

	} elsif ($notification_type eq 'Complaint') {

		# Complaints (spam reports) — increment counter and suppress at 6,
		# same policy as bounces since rejections are often content-dependent.
		for my $recipient (@{$ses->{complaint}{complainedRecipients}}) {
			my $email = lc($recipient->{emailAddress});
			$dbh->do(qq|
				UPDATE subscriber
				SET subscriber_failcount = subscriber_failcount + 1,
				    subscriber_status = IF(subscriber_failcount + 1 >= 6, 'complained', subscriber_status)
				WHERE LOWER(subscriber_email) = ?
				AND subscriber_status = 'active'
			|, undef, $email);
		}

	}

	use JSON;
	print to_json({ status => "OK", message => "Notification processed" }, {pretty => 1});
	exit;

}

1;
