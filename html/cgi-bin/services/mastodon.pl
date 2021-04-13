
# -------   Mastodon --------------------------------------------------
#
# Autopost to Mastodon
# Requires: $dbh,$table,$id
# Optional: $toot (will print record title if tweet is not given)
# Requires $Site->{mas_post} set to 'yes' and $record->{post_social_media} to not contain "mastodon" (for the post specified)
# Will include site hastag $Site->{st_tag} if $Site->{mas_use_tag} is set to "yes"
# Will update the record to set the value 'posted' the value in 'post_twitter'   (or 'event_twitter', etc)
# to ensure each item is posted only once
# Returns status update in $vars->{twitter}


sub mastodon_post {

    my ($dbh,$table,$id,$tweet) = @_;


		&admin_only(); # We only want the site owner to be able to use icchat to post to mastodon

# Check and make sure it can be and hasn't been posted

    return "Content information not defined" unless ($table && $id);
    return "Mastodon turned off."  unless ($Site->{mas_post} eq "yes");
    return "Already posted this $table to Mastodon." if ($record->{$table."_social_media"} =~ "mastodon");
    return "Mastodon requires a client ID, client secret and access token" unless
       ($Site->{mas_instance} && $Site->{mas_cli_id} && $Site->{mas_cli_secret} && $Site->{mas_acc_token});


    $tweet = &compose_microcontent($dbh,$table,$id,$tweet,500);


	return "Content information not defined" unless (&new_module_load($query,"Mastodon::Client"));
	
    my $client = Mastodon::Client->new(
      instance        => $Site->{mas_instance},
      name            => 'gRSShopper',
      client_id       => $Site->{mas_cli_id},
      client_secret   => $Site->{mas_cli_secret},
      access_token    => $Site->{mas_acc_token},
      coerce_entities => 1,
    );

    my $result = $client->post_status($tweet);
    if ($result) { return $result; } else { return "OK"; }


}

sub mastodon_harvest {

	my ($channel) = @_;

	  # Turn on Mastodon Listener
	  # Streaming interface might change!
	#  use Mastodon::Client or print "Whga??";

  unless ($channel->{channel_tag}) {
     return qq|<span color="red">No mastodon tag detected</span>|;
  }      # Harvest ONLY if there is a tag
  my $tag = "#".$channel->{channel_tag}; $tag =~ s/##/#/;

	return "Content information not defined" unless (&new_module_load($query,"Mastodon::Client"));
	
	my $client = Mastodon::Client->new(
	  instance        => $Site->{mas_instance},
	  name            => 'gRSShopper',
	  client_id       => $Site->{mas_cli_id},
	  client_secret   => $Site->{mas_cli_secret},
	  access_token    => $Site->{mas_acc_token},
	  coerce_entities => 1,
	);

#my $timeline = $client->timeline($tag) or return "Mastodon harvest error.";

#return "tt<p>";

  my $timeline = $client->timeline("public") or return "Mastodon harvest error.";;
#return "Mastodon $tag $timeline <p>";
  foreach my $t (@$timeline) {
#return "Found one: $t <br>";
  #  print $t,"<br>";

				my $content = get($t->{uri});
				#print qq|<div style="width:100px;">$content</div>|;

        $content =~ /<meta content="(.*?)" property="og:description/;
        my $description = $1;
				next unless ($description =~ /$tag/);
				$content =~ /<meta content="(.*?)" property="og:title/;
        my $mastotitle = $1;

				my $chat; my $userstr = "";

				my ($created,$garbage) = split / \+/,$status->{created_at};
				$description =~ s/\x{201c}/ /g;	# "
				$description =~ s/\x{201d}/ /g;	# "
				$chat->{chat_link} = $t->{uri};
				$chat->{chat_title} = "Chat title";

        $chat->{chat_description} = qq|
					<img src="" align="left" hspace="10">
					<a href="$chat->{chat_link}">\@|.$mastotitle.qq|</a>: |.
					$description . "";
				$chat->{chat_signature} = "Mastodon";
				$chat->{chat_crdate} = time;
				$chat->{chat_channel} = $channel->{channel_id};
				$chat->{chat_creator} = $Person->{person_id};
				$chat->{chat_crip} = $ENV{'REMOTE_ADDR'};

				if (my $cid = &db_locate($dbh,"chat",{chat_link => $chat->{chat_link}})) {
					# Nothing
				} else {
					my $id_number = &db_insert($dbh,$query,"chat",$chat);
          unless ($id_number) { return qq|<span color="red">Error saving Mastodon chat comment</span>|;}
return qq|$chat->{chat_description}|;
				}

   }



}

1;
