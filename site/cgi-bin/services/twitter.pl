
# -------   Twitter --------------------------------------------------
#
# Autopost to Twitter
# Requires: $dbh,$table,$id
# Optional: $tweet (will print record title if tweet is not given)
# Requires $Site->{tw_post} set to 'yes' and $record->{post_social_media} to not contain "twitter" (for the post specified)
# Will include site hastag $Site->{st_tag} if $Site->{tw_use_tag} is set to "yes"
# Will update the record to set the value 'posted' the value in 'post_twitter'   (or 'event_twitter', etc)
# to ensure each item is posted only once
# Returns status update in $vars->{twitter}

sub twitter_post {

	my ($dbh,$table,$id,$tweet) = @_;

  &admin_only(); # We only want the site owner to be able to use icchat to post to Twitter

	unless ($Site->{tw_post} eq "yes") { &status_error(qq|
		Twitter turned off. 
		<span class="btn-inline" onClick="
		  openDiv('cgi-bin/api.cgi','Profile','social','Accounts','','','Accounts');
          openTab(event, 'Profile', 'mainlinks');
		  ">Turn on?</span>|); }



	if ($record->{$table."_social_media"} =~ "twitter") { 
		&status_error("Already posted this $table to Twitter.");
	}

	#use Net::Twitter::Lite::WithAPIv1_1;
	#use Scalar::Util 'blessed';

	#my $Site->{tw_cckey} = '';
	#my $Site->{tw_csecret}  = '';
	#my $Site->{tw_token} = '';
	#my $Site->{tw_tsecret}  = '';


										# Access Account

	&status_error("Twitter posting requires values for consumer key, consumer secret, token and token secret")
		unless ($Site->{tw_cckey} && $Site->{tw_csecret} && $Site->{tw_token} && $Site->{tw_tsecret});


	$tweet = &compose_microcontent($dbh,$table,$id,$tweet,280);

	my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
		consumer_key        => $Site->{tw_cckey},
		consumer_secret     => $Site->{tw_csecret},
		access_token        => $Site->{tw_token},
		access_token_secret => $Site->{tw_tsecret},
		ssl                 => 1,  ## enable SSL! ##
	);

    my $result = eval {$nt->update({ status => $tweet})};
	#use Data::Dumper;
 	#print Dumper $result;

	if ( my $err = $@ ) {
		&status_error($@) unless blessed $err && $err->isa('Net::Twitter::Lite::Error');
		my $error_message=sprintf("Twitter posting error<br>Attempted to tweet: %s<br>HTTP Response Code: %s<br>HTTP Message: %s<br>Twitter error: %s", $tweet,$err->code,$err->message,$err->error);
		&status_error($error_message);
	}

	my $tweet_url = "https://twitter.com/".$Site->{tw_account}."/status/".$result->{id};
	if ($result) { return $tweet_url; } 
	else { &status_error("No result returned from Twitter"); }

	return 1;

}

sub compose_microcontent {

   my ($dbh,$table,$id,$tweet,$length) = @_;

	my $record = &db_get_record($dbh,$table,{$table."_id"=>$id});

	use HTML::Entities;
	use utf8;							# Turns out if you don't also use this, encode_entities doesn't work

										# Create Array of Post Sentences
	my $post_description; my @sentences;
	$post_description = $record->{$table."_description"};
	$post_description =~ s/&amp;/&/g;	# Decode Ampersands
	$post_description = decode_entities($post_description); 	# Decode previously encoded entities
	$post_description =~ s/<(.*?)>//ig; # Remove HTML tags
	@sentences = split /\. /,$post_description;



										# URL
	my $tw_url; 
  	if ($table eq "chat") { $tw_url = ""; } # Special URL for chat
	else { $tw_url = $Site->{st_url}.$table."/".$id; }

										# Tag
  	unless ($vars->{chat_tag}  =~ /#/) { $vars->{chat_tag} = "#".$vars->{chat_tag};}
  	if ($table eq "chat") { $tw_url = $vars->{chat_tag}." ".$tw_url; }
	elsif ($Site->{tw_use_tag}) { $tw_url = $Site->{st_tag}." ".$tw_url; }

										# Title
	$tweet ||= $record->{$table."_title"};	# Allows for message to be sent to this function
	$post_description =~ s/&amp;/&/g;	# Decode Ampersands	
	$title = decode_entities($tweet); 	# Decode previously encoded entities	
	$tweet =~ s/<(.*?)>//ig;  # Remove HTML tags

										# Calculate Lengths
	my $url_length = length($tw_url)+1;
	my $tweet_length = length($tweet);

										# Create Initial Tweet (Abbreviating title if necessaey)
	if (($url_length + $tweet_length) > ($length-3)) {
		my $etc = "...";
		my $trunc_length = 277 - $url_length;
		$tweet = substr($tweet,0,$trunc_length);
		$tweet =~ s/(\w+)[.!?]?\s*$//;
		$tweet.=$etc;
	}

	$tweet = $tweet . " " . $tw_url;

	foreach my $sentence (@sentences) {					# Add sentences to tweet if they fit
		last if (length($tweet)+length($sentence)+2 > $length);
		$tweet = $tweet ." ". $sentence .".";
	}

	return $tweet;

}

1;
