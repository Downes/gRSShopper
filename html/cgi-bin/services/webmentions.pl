	# -------  Webmentions
	#

	
# Finds a WebMention wndpoint given the $lcontent of a web page
sub find_webmention_endpoint {
   my ($lcontent) = @_;
	 my $endpoint = "";

	 my @bodylinks = $lcontent =~ /<a (.*?)>/gis;
	 foreach my $bl (@bodylinks) {	if ($bl =~ m/rel="webmention"/is) { $bl =~ m/href="(.*?)"/is; $endpoint=$1; last; }	}

	 my @headlinks = $lcontent =~ /<link (.*?)>/gis;
	 foreach my $hl (@headlinks) {	if ($hl =~ m/rel="webmention"/is) { $hl =~ m/href="(.*?)"/is; $endpoint=$1; last; }	}

	 return $endpoint;
	}

sub send_webmention {

	my ($endpoint,$target,$source) = @_;
		my $ua = new LWP::UserAgent;

	#print "Sending webmention update to $endpoint <br>";
	my $req = new HTTP::Request 'POST',$endpoint;
	$req->content_type('application/x-www-form-urlencoded');
	$req->content("source=$source&target=$target");
	my $res = $ua->request($req);
	#print $res->as_string; print "<br>";


	}

1;