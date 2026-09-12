# Bookmarklet function: api_hub_bookmarklet

# API UPDATE ----------------------------------------------------------

# API HUB BOOKMARKLET -------------------------------------------------------

# Given an input URL, retrieves the web page and returns a hash of page data
# Triggered when a person uses the bookmarklet to create a post

# ----------------------------------------------------------------------------

sub api_hub_bookmarklet {

	use HTML::Entities;
	use utf8;

	my ($id,$geturl,$images) = @_;
	$images ||= [];
	my $report = "";
#print "Content-type:/text/html\n\n";
#print qq|<!DOCTYPE html><html lang="en"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8">|;

#print "OK go";
	# Check for duplicates
	my $lid = &db_locate($dbh,"post",{post_link => $geturl});
# if ($lid) { &status_error("Link already exists in db"); }

	use HTML::TreeBuilder 5 -weak; # Ensure weak references in use
        use LWP::UserAgent ();
#	my $output_format = 'text/plain';
#	print $query->header(-Accept => "*/*",-type => $output_format,-charset => 'utf-8','-Access-Control-Allow-Origin' =>  => "*");

        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        $ua->env_proxy;
	$ua->agent('Mozilla/5.0');
        $ua->ssl_opts({ verify_hostname => 0,SSL_verify_mode => 'SSL_VERIFY_NONE',SSL_version => 'SSLv3' });
	my $tree = HTML::TreeBuilder->new();

	my $response_text; my $curl_result;
    my $response = $ua->get($geturl);
	if ($response->is_success) { 
		$tree->parse($response->decoded_content);
	$report .= "LWP: success<br>";

	} else {
		$report .= "Failed to get resource. ".$response->status_line."<br>"; 
		$report .= "Trying curl... ";
		$curl_result = `curl $geturl`;
		if ($curl_result) {
			utf8::decode($curl_result);
			#$report .= $curl_result;
			$tree->parse($curl_result);
		} else {
			$report .= "Curl also failed.<br>";
		}
	$report .= "LWP: curl<br>";	
	}
	$response_text = $curl_result || $response->decoded_content;

	# Analyze h-card
	# my $namebadge = $tree->look_down('class' => qr/namebadge/);

	# URL

   	&status_error("Failed Hub URL Update") unless (&api_textfield_update({table=>'post',field=>'post_link',value=>$geturl,id=>$id}));

	# Initialize tags that may be filled by various values found
	my $metadata;

	# Analyze meta
	my @meta = $tree->find_by_tag_name('meta');
	foreach my $m (@meta) {
#while (my ($mx,$my) = each %$m) { print "$mx = $my <br>"; }

		# Meta Tags
		my @metatags = qw(description author);
		foreach my $metatag (@metatags) {
			if ((($m->attr_get_i("name") // '') eq $metatag) ||
				(($m->attr_get_i("property") // '') eq $metatag)
			) {
				$metadata->{$metatag} ||= $m->attr_get_i("content"); 
			}

		}

		# Meta Open Graph Tags
		my @ogtags = qw(type site_name title description title url description 
			published_time modified_time image image:width image:height image:alt locale);
		foreach my $ogtag (@ogtags) {
			my $ogproperty = "og:".$ogtag;
			if (($m->attr_get_i("property") // '') eq $ogproperty) {
				$metadata->{$ogtag} ||= $m->attr_get_i("content"); 			
			}			
		}

		# Meta Twitter Tags
		my @twtags = qw(card site title description image:src);
		foreach my $twtag (@twtags) {
			my $twname = "twitter:".$twtag;
			if (($m->attr_get_i("name") // '') eq $twtag) {
				$metadata->{$twtag} ||= $m->attr_get_i("content");
			}

		}


		# Meta DC Tags
		if (($m->attr_get_i("name") // '') eq "DC.creator") { $metadata->{author} ||= $m->attr_get_i("content"); }

	}


	# Analyze h-card
	my $hcard = $tree->look_down('class' => qr/h-card/);
        if ($hcard) {

		# Author
    		my $pname = $hcard->look_down('class' => qr/p-name/);
    		if ($pname) { print "Name: ".$pname->as_text." \n\n"; }

		# Author URL
		my $urlhref;
    		my $uurl = $hcard->look_down('class' => qr/u-url/);
		if ($uurl && $uurl->attr_get_i('href')) {
			$urlhref = $uurl->attr_get_i('href'); 
			print "URL: $urlhref \n\n"; 
		}
		# Author Photo
    		my $uphoto = $hcard->look_down('class' => qr/u-photo/);
		if ($uphoto) { 
			my $photosrc = $uphoto->attr_get_i('src');
			print "Photo: $photosrc \n\n";
		}
	}

	# Search for the author in the page content if necessary
	# print $response_text;
	if ($response_text =~ /"author":"(.*?)"/) {
		$metadata->{author} = $1;
	}

	# Update page data (because not all systems use the same terms for things, natch)

	# Title
	my $title; my $titletag =  $tree->find_by_tag_name('title');
	if ($titletag) { $metadata->{title} ||= $titletag->as_text; }
	unless ($title) { $title = "Untitled"; }

	#	$report .= "Title: ".$metadata->{title}."<br>";

	if ($metadata->{title}) {
   		&api_textfield_update({table=>'post',field=>'post_title',value=>$metadata->{title},id=>$id});
	}

	# Description
	# Quoted text from Hub and completion of description
	my $quote = $vars->{quote};
	if ($quote) { $metadata->{description} .= "QUOTE: $quote"; }
	# $report .= "Description: ".$metadata->{description}."<br>";	

	if ($metadata->{description}) {
   		&api_textfield_update({table=>'post',field=>'post_description',value=>$metadata->{description},id=>$id});
	}

	# Feed — use og:site_name from scraped page, falling back to feed name passed via URL param
	my $feed = $metadata->{site_name} || $vars->{feed};
	if ($feed) {
		&api_keylist_update({table=>'post',id=>$id,key=>'feed',value=>$feed});
	}

	# Author — use scraped metadata, falling back to author name passed via URL param
	my $author = $metadata->{author} || $vars->{author};
	if ($author) {
		&api_keylist_update({table=>'post',id=>$id,key=>'author',value=>$author});
	}

	# Image - fold the page's own og:image/twitter:image into the candidate
	# list gathered client-side, so the picker shows both
	my $image = $metadata->{image} || $metadata->{"twitter:image:src"} || $metadata->{source};
	if ($image) {
		unshift @$images, $image;
		$report .= "Image: ".$image."<br>";
	}

    $tree->delete;

	return $report;
}



1;
