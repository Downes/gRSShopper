
#               THIRD PARTY INTEGRATION
#
#    Longer term I'd like to standardize these functions



# -------   Facebook --------------------------------------------------
#
# Autopost to Facebook
# Requires: $dbh,$table,$id
# Optional: $tweet (will print record title if tweet is not given)
# Requires $Site->{fb_post} set to 'yes' and $record->{post_social_media} not containing 'facebook' (for the post specified)
# Will include site hastag $Site->{st_tag} if $Site->{fb_use_tag} is set to "yes"
# Will update the record to set the value 'posted' the value in 'post_twitter'   (or 'event_twitter', etc)
# to ensure each item is posted only once
# Returns status update in $vars->{twitter}

sub facebook_post {

	my ($dbh,$table,$id,$message) = @_;

	return "Facebook turned off." unless ($Site->{fb_post} eq "yes");				# Make sure Facebook is active
	my $record = &db_get_record($dbh,$table,{$table."_id"=>$id});					# get record
	my $fbp = &facebook_session();

	my $fbp = Net::Facebook::Oauth2->new(
		application_secret     => $Site->{fb_app_secret} ,
		application_id          => $Site->{fb_app_id},
		callback           => $Site->{fb_postback_url}
	);

	my $text = &format_record($dbh,"","post","facebook",$record);				# Format content
	my $link = $Site->{st_url}."post/".$id."/rd";

	$text =~ s/<br>|<br\/>|<br \/>|<\/p>/\n\n/ig;							# No HTML
	$text =~ s/\n\n\n/\n\n/g;
	$text =~ s/<(.*?)>//g;
	$text =~ s/<(.*?)>//g;


	my $posturl = "https://graph.facebook.com/v2.2/OLDaily/feed";
        my $args = {
            message => $text,
            link => $link,
        };
        $fbp->{access_token} = $Site->{fb_token};
        my $info = $fbp->post( $posturl,$args );							# Post to Facebook
        my $inforcheck = $info->as_json;

	if ($inforcheck =~ /error/) {													# catch error, or

			print "Content-type: text/html\n\n";
			$vars->{facebook} .= "Facebook: Error <br />";
			$vars->{facebook} .=  $inforcheck;
			print $vars->{facebook};
			facebook_access_code_url($vars->{facebook});
			exit;

	} else {
		my $smfield = $table."_social_media";								# Update Record
		my $smstring = $record->{$smfield}."facebook ";
		&db_update($dbh,$table,{$smfield => $smstring},$id);
		$vars->{facebook} .= "$inforcheck <br>Facebook: OK";
	 }



	return $vars->{facebook};

}
sub facebook_session {

	my ($dbh) = @_;
return;
	#use Facebook::Graph;
	# use Net::Facebook::Oauth2;


									# Make sure we have an access token
	unless ($Site->{fb_token}) { $Site->{fb_token} = &facebook_access_token(); }

									# Authenticate and Encode token
	unless (my $fb = &facebook_authenticate()) { return $vars->{facebook}; }
	$fb->{access_token} = $Site->{fb_token};
	return $fb;
}
sub facebook_authenticate {


	my $fbz = Net::Facebook::Oauth2->new(
		application_secret     => $Site->{fb_app_secret} ,
		application_id          => $Site->{fb_app_id},
		callback           => $Site->{fb_postback_url}
	);

	unless ($fbz) { $vars->{facebook} .= "Facebook authentication error: $?"; return; }

	return $fbz;

}
sub facebook_access_token {

	return $Site->{fb_token} if ($Site->{fb_token});

	my $access_code = &facebook_access_code_url();

	my $fb = Net::Facebook::Oauth2->new(
            application_secret     => $Site->{fb_app_secret},
            application_id          => $Site->{fb_app_id},
            callback           => $Site->{fb_postback_url}
        );

        my $access_token = $fb->get_access_token(code => $access_code);
        if ($access_token) { $Site->update_config($dbh,{fb_token => $access_token}); }
        else { $vars->{facebook} .= "Facebook: Error getting access token."; }

	return $access_token;
}
sub facebook_access_code_url {

	my ($info) = @_;
	return $Site->{fb_code} if ($Site->{fb_code});
	if ($vars->{code}) {						# This picks up the code from the redirect
		$Site->{fb_code} = $vars->{code};			# We'll store it for later use
		if ($Site->{fb_code}) { $Site->update_config($dbh,{fb_code => $Site->{fb_code}}); }
		print "Content-type: text/html\n\n";			# Print a response
		print "Facebook OK $Site->{fb_code}";
		exit;							# And quit
	}

									# This assumes we did not get a code from a redirect
									# So we have to make the request
	my $fbb = Net::Facebook::Oauth2->new(
            application_secret     => $Site->{fb_app_secret},
            application_id          => $Site->{fb_app_id},
            callback           => $Site->{fb_postback_url}
        );


								        # Get the authorization URL
        my $url = $fbb->get_authorization_url(
            scope   => [ 'public_profile', 'email'  ],
            display => 'page'
        );

        print "Content-type: text/html\n\n";
        print "$info <p>";
        print "Facebook needs to generate an access token. Click on the link or enter the URL:  $url<p>";					# And provide the link to click on

        print qq|Redirect URL: <a href="$url">Click here</a><p>|;

	exit;
}
sub facebook_access_code_submit {

	my $code = $vars->{code};					# save the code. Note it's valif only for a couple minutes
	if ($access_token) { $Site->update_config($dbh,{fb_code => $code}); }

									# Regenerate the access token, which will persist
	$Site->{fb_token} = "";
	my $result = &facebook_access_token();
	print "Content-type: text/html\n\n";
	print "Facebook Access Result: $result<br>";
	unless ($result =~ /error/i) { print "You can now use Facebook services<p>"; }
	exit;
}

1;
