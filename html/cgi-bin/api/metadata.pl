


	#
	#
	#                                   Metadata
	#
	#

	# ---------------------------------------------------------------------
	#
	# Obtains metadata for remote resources and returns it
    # thus allowing use of data without CORS issues
	#
	#
	# -------------------------------------------------------------------------

sub analyze_link {

    my ($link) = @_;
    use LWP::Simple;
    use LWP::UserAgent ();
    use HTML::HeadParser;
    unless (&new_module_load($query,"URI::Encode",qw(uri_encode uri_decode))) { $vars->{warnings} .= "URI::Encode;"; }
   # use URI::Encode qw(uri_encode uri_decode); # Failing, even though it's installed?
    use HTTP::Headers;

   # print "Content-type: text/html\n\n";
   #my $decoded = uri_encode("https://abcnews.go.com/International/debate-daylight-saving-time-drags-europe/story?id=80925773");
   #$encoded =~ s/\?/QMark/g;
#print $encoded,"\n\n<br>";;

    my $decoded = uri_decode($vars->{link}); 
    $decoded =~ s/QMark/\?/g;


    
    #    my $ua = LWP::UserAgent->new;


 
    my $ua = LWP::UserAgent->new(timeout => 10);
    $ua->agent("Mozilla/8.0");
	$ua->ssl_opts( verify_hostname => 0 ,SSL_verify_mode => 0x00);
    $ua->env_proxy;
    
    my $response = $ua->get($decoded);
    
    if ($response->is_success) {

        my $text = $response->decoded_content;






        my $h = HTTP::Headers->new;
        my $p = HTML::HeadParser->new($h);
        $p->parse($text);
        my $output;

        my @twitterlabels; my @twitterdata; my @twittercount;
        for ($h->header_field_names) {
            my $linkfield = $_;

            # parse all the link rel values
            if (($linkfield =~ m/^Link$/i)) {
                #print $h->header($linkfield),"\n";
                my @linkdata = split /,/,$h->header($linkfield);
                foreach my $l (@linkdata) {
                    my $href; my $rel; my $type;
                    my @linkitems = split /;/,$l;

                    foreach my $li (@linkitems) {
                        #print $li,"\n";
                        if ($li =~ m/rel="(.*?)"/i) { $rel = $1;}
                        elsif ($li =~ m/<(.*?)>/) { $href = $1; }
                        elsif ($li =~ m/type="(.*?)"/i) { $type = $1;}
                    }
                # print "$rel - $href \n\n";
                    if (($rel =~ /alternate/) && $type) { $output->{$type} = $href; }
                    else { $output->{$rel} = $href; }
                }

            # extract Twitter Labels and store in arrays for further processing
            } elsif ($linkfield =~ m/^X-Meta-Twitter-Label(.*?)$/i) {
                my $c = $1;
                $twitterlabels[$c] = $h->header($linkfield);
                push @twittercount,$c;  # Keeps a list of label numbers, because it might not be sequential
            } elsif ($linkfield =~ m/^X-Meta-Twitter-Data(.*?)$/i) {
                $twitterdata[$1] = $h->header($linkfield);    

            # parse the rest of the metadata
            } else {
                $output->{$_} = $h->header($_) ;
            }
        # printf("%s: %s\n", $_, $h->header($_));
        }

        # Process saved Twitter data, cycling through the saved list of label numbers
        foreach my $tw (@twittercount) {
            my $twlabel = $twitterlabels[$tw];
            if ($twlabel eq "Written by") { $twlabel = "author"; }  # cf. eg. Nieman Lab page
            $output->{$twlabel} = $twitterdata[$tw];
        }

   		my $json = encode_json $output;
   		print $json;exit;


    } else {


		my $message = "failed to get link \n<br>\n".
			$response->code. "<br>\n".
			$response->message. "<br>\n".
			$server_endpoint. "<br>\n";

        &status_error("$message :$! $?");
		#&log_cron(0,$message);
		#&send_email('stephen@downes.ca','stephen@downes.ca',"gRSShopper Harvest Failed",$message,"htm");
		return;
	}





    exit;
}

1;