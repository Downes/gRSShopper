
# SNS message signature verification
# Reusable for any SNS subscription on this server
# Called before trusting any SNS notification payload

sub verify_sns_signature {

	my ($msg) = @_;    # decoded JSON hashref

	# Validate cert URL is from AWS to prevent forgery
	my $cert_url = $msg->{SigningCertURL};
	unless ($cert_url =~ m|^https://sns\.[a-z0-9-]+\.amazonaws\.com/|) {
		return 0;
	}

	# Fetch the signing certificate
	use LWP::UserAgent;
	my $ua = LWP::UserAgent->new(timeout => 10);
	my $res = $ua->get($cert_url);
	return 0 unless $res->is_success;
	my $pem = $res->content;

	# Build the string to sign — field order is mandated by AWS, not alphabetical
	my $type = $msg->{Type};
	my @fields;
	if ($type eq 'Notification') {
		@fields = ('Message','MessageId','Subject','Timestamp','TopicArn','Type');
	} elsif ($type eq 'SubscriptionConfirmation' || $type eq 'UnsubscribeConfirmation') {
		@fields = ('Message','MessageId','SubscribeURL','Timestamp','Token','TopicArn','Type');
	} else {
		return 0;
	}

	my $string_to_sign = '';
	for my $field (@fields) {
		next unless defined $msg->{$field};
		$string_to_sign .= "$field\n$msg->{$field}\n";
	}

	# Verify RSA-SHA1 signature manually
	# OpenSSL 3.5 disables the PKCS#1 v1.5 API (Marvin attack mitigation),
	# so we use raw RSA (no_padding) and parse the PKCS#1 block ourselves
	use MIME::Base64;
	use Digest::SHA qw(sha1);
	use Crypt::OpenSSL::RSA;
	use Crypt::OpenSSL::X509;

	my $sig  = decode_base64($msg->{Signature});
	my $x509 = Crypt::OpenSSL::X509->new_from_string($pem);
	my $rsa  = Crypt::OpenSSL::RSA->new_public_key($x509->pubkey());
	$rsa->use_no_padding();

	# RSA public-key decrypt the signature to recover the PKCS#1 v1.5 block
	my $decrypted = eval { $rsa->public_decrypt($sig) };
	return 0 unless defined $decrypted;

	# Confirm PKCS#1 v1.5 type-1 padding structure
	return 0 unless $decrypted =~ /^\x00?\x01\xFF+\x00/;

	# SHA1 DigestInfo OID prefix (from RFC 3447)
	my $sha1_digestinfo = "\x30\x21\x30\x09\x06\x05\x2b\x0e\x03\x02\x1a\x05\x00\x04\x14";

	# Verify the DigestInfo prefix and SHA1 hash match
	my $digest_prefix = substr($decrypted, -35, 15);
	my $embedded_hash = substr($decrypted, -20);
	my $expected_hash = sha1($string_to_sign);

	return ($digest_prefix eq $sha1_digestinfo && $embedded_hash eq $expected_hash) ? 1 : 0;

}

1;
