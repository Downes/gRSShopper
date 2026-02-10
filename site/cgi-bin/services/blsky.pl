
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


sub bluesky_post {

    my ($dbh,$table,$id,$tweet) = @_;

		&admin_only(); # We only want the site owner to be able to use icchat to post to mastodon

# Check and make sure it can be and hasn't been posted

    my $mastoerror = "";
    $mastoerror = "Content information not defined" unless ($table && $id);
    $mastoerror = "Mastodon turned off."  unless ($Site->{blue_post} eq "yes");
    $mastoerror = "Already posted this $table to Bluesky." if ($record->{$table."_social_media"} =~ "mbluesky");
    $mastoerror = "Bluesky requires a user handle" unless ($Site->{blue_handle});
    $mastoerror = "Bluesky requires an app password" unless ($Site->{blue_app_pass});

    my $status = &compose_microcontent($dbh,$table,$id,$tweet,300);
    $mastoerror = "Post has no content" unless ($status);

    if ($mastoerror) { &status_error("$mastoerror"); }
    # Bluesky API endpoint for creating a session
    my $api_url = 'https://bsky.social/xrpc/com.atproto.server.createSession';

    # Create a user agent
    my $ua = LWP::UserAgent->new;

    # Set up the request
    my $request = HTTP::Request->new(POST => $api_url);
    $request->header('Content-Type' => 'application/json');

    # Create the JSON payload
    my $payload = {
        identifier => $Site->{blue_handle},
        password   => $Site->{blue_app_pass},
    };

    # Convert the payload to JSON
    my $json_payload = encode_json($payload);

    # Add the JSON payload to the request
    $request->content($json_payload);

    # Send the request
    my $response = $ua->request($request);

    # Check the response
    my $auth; my $did;
    if ($response->is_success) {
        my $session = decode_json($response->decoded_content);
       # print "Access Token: " . $session->{'accessJwt'} . "\n";
        $auth = $session->{'accessJwt'};
        $did = $session->{'did'};
       # print "DID: " . $session->{'did'} . "\n";
    } else {
        die "Failed to create session: " . $response->status_line . "\n";
    }


    # Fetch the current time in ISO 8601 format with "Z" for UTC
    #my $now = "'".strftime("%Y-%m-%dT%H:%M:%SZ", gmtime)."'";
    my $now = strftime("%Y-%m-%dT%H:%M:%SZ", gmtime);

        # Do Bluesky's really weird setip for links


    my $pattern = qr{https?://[^\s]+};
    my $start; my $end; my $embedded_url;
    if ($status =~ /($pattern)/) {
        $embedded_url = $1;
        $start = index($status, $embedded_url);
        $end = $start + length($embedded_url);
        #print "URL found from position $start to $end\n";
    
    }

    # Required fields that each post must include
    # Notice use of 0+$start to make sure to force encode_json to treat it as an integer
    my $post = {
        '$type'    => 'app.bsky.feed.post',
        'text' => $status,
        'createdAt' => $now,
        'langs' => [ 'en-US','en-CA' ],
        'facets' => [ 
            {
                index => {
                    'byteStart' => 0+$start,
                    'byteEnd' => 0+$end,
                },
                features => [
                    {
                    '$type' => 'app.bsky.richtext.facet#link',
                    'uri' => $embedded_url,
                    }
                ],
            }
         ],

    };



    # Set up the request
    my $arequest = HTTP::Request->new(POST => 'https://bsky.social/xrpc/com.atproto.repo.createRecord');
    $arequest->header('Content-Type' => 'application/json');
    $arequest->header('Authorization' => "Bearer $auth");

    # Create the JSON payload
    my $payload = {
        'repo'       => $did,
        'collection' => 'app.bsky.feed.post',
        'record'     => $post,
    };


    # Convert the payload to JSON
    my $json_payload = encode_json($payload);




    # Add the JSON payload to the request
    $arequest->content($json_payload);

# Debugging

# Convert the post data to JSON (pretty-printed)
#my $json_post = to_json($json_payload, { utf8 => 1, pretty => 1 });

# Print the full JSON request payload
#print "Full JSON Request Payload:\n$json_payload\n\n";
#exit;

    # Send the request
    my $response = $ua->request($arequest);

    my $response_data = decode_json($response->decoded_content);

    print $response_data->{url};
   


    # Check if the response contains 'response' and 'status' keys with value 'OK'
    if ( $response_data->{uri}) {
        status_ok();
       # print "Post created successfully!\n";
    } else {
        &status_error("Failed! $response->{status} $response->{reason}")
    }


}

sub bluesky_harvest {

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
