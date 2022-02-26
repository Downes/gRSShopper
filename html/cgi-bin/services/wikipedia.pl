
# -------   Wikipedia  ----------------------------------------------

sub wikipedia {

	my ($dbh,$term) = @_;

	use constant WIKIPEDIA_URL =>'http://%s.wikipedia.org/w/index.php?title=%s';
	use CGI qw( escape );

	return unless ($term);

 	my $browser = LWP::UserAgent->new();
	my $language = "en";
	my $string = escape($term);

	$browser->agent( 'Edu_RES' );
	my $src = sprintf( WIKIPEDIA_URL, $language, $string );
	my $response = $browser->get($src);

	if ( $response->is_success() ) {
		my $article = $response->content();
		$article =~ s/(.*?)<body(.*?)>(.*?)<\/body>(.*?)/$3/si;
		$article =~ s|/wiki/|http://en.wikipedia.org/wiki/|sig;
		$article =~ s|<script(.*?)>(.*?)</script>||sig;
		$article =~ s/<div(.*?)>//sig;
		$article =~ s|</div>||sig;
		$article = qq|<div id="wikipedia">\n$article\n</div>|;

		return $article;
	} else {
		return "Unable to connect to Wikipedia";
	}

        # look for a wikipedia style redirect and process if necessary
        # return $self->search($1) if $entry->text() =~ /^#REDIRECT (.*)/i;

}
sub process_wikipedia {

	my ($content) = @_;

	my $output = "";
	my @graphs = split /\n/,$content;
	foreach my $graph (@graphs) {
		next unless ($graph);
		$output .= "<p>".$graph."</p>";
	}

	return $output;
}
sub wikipedia_entry {

	my ($dbh,$text_ptr) = @_;

	while ($$text_ptr =~ /<WIKIPEDIA (.*?)>/sg) {

		my $autotext = $1;
		my $term = $autotext;
		my $entry = &wikipedia($dbh,$term);
		$$text_ptr =~ s/<WIKIPEDIA \Q$autotext\>/$entry/sig;
	}

}

1;
