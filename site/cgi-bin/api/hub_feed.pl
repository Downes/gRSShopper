# Feed-sourced post creation: api_hub_feed

# API HUB FEED ----------------------------------------------------------

# Given post metadata already known from an RSS/Atom feed (link, title, author,
# feed name, selected quote), populates a new post record directly.
# Unlike api_hub_bookmarklet, this does NOT fetch the source page - feed readers
# already have this data, and fetching the page risks getting nothing back if
# the site refuses bots.

# ----------------------------------------------------------------------------

sub api_hub_feed {

	my ($id) = @_;
	my $report = "";

	my $url = $vars->{url};
	&status_error("Failed Hub URL Update") unless (&api_textfield_update({table=>'post',field=>'post_link',value=>$url,id=>$id}));

	my $title = $vars->{title};
	if ($title) {
		&api_textfield_update({table=>'post',field=>'post_title',value=>$title,id=>$id});
	}

	my $quote = $vars->{quote};
	if ($quote) {
		&api_textfield_update({table=>'post',field=>'post_description',value=>"QUOTE: $quote",id=>$id});
	}

	my $feed = $vars->{feed};
	if ($feed) {
		&api_keylist_update({table=>'post',id=>$id,key=>'feed',value=>$feed});
	}

	my $author = $vars->{author};
	if ($author) {
		&api_keylist_update({table=>'post',id=>$id,key=>'author',value=>$author});
	}

	$report .= "Populated from feed data (no page fetch)<br>";
	return $report;
}

1;
