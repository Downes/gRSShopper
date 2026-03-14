
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
		print &hash_to_json({ status => "OK", message => "SNS subscription confirmed" });
		exit;
	}

	# Notification — parse the inner SES message
	exit unless $msg->{Type} eq 'Notification';
	my $ses = eval { decode_json($msg->{Message}) };
	exit unless $ses;

	my $notification_type = $ses->{notificationType};

	if ($notification_type eq 'Bounce') {

		# Only suppress permanent bounces; transient are temporary delivery failures
		if ($ses->{bounce}{bounceType} eq 'Permanent') {
			for my $recipient (@{$ses->{bounce}{bouncedRecipients}}) {
				my $email = lc($recipient->{emailAddress});
				$dbh->do(qq|
					UPDATE subscriber SET subscriber_status = 'bounced'
					WHERE LOWER(subscriber_email) = ?
				|, undef, $email);
			}
		}

	} elsif ($notification_type eq 'Complaint') {

		# Complaints (spam reports) must always be suppressed
		for my $recipient (@{$ses->{complaint}{complainedRecipients}}) {
			my $email = lc($recipient->{emailAddress});
			$dbh->do(qq|
				UPDATE subscriber SET subscriber_status = 'complained'
				WHERE LOWER(subscriber_email) = ?
			|, undef, $email);
		}

	}

	print &hash_to_json({ status => "OK", message => "Notification processed" });
	exit;

}

1;
