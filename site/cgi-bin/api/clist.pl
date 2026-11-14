# -------------------------------------------------------------------------------------
#          CList Integration
#
#          Token-authenticated endpoints used by CList to publish and update
#          annotations as 'post' records (post_type = 'link'), and to fetch an
#          existing post's content back so CList can reopen it for editing.
#          Session-independent: authenticates via $Site->{clist_api_token} rather
#          than a login cookie, then impersonates $Site->{clist_person_id} so
#          record_defaults/record_save behave exactly as for a logged-in editor.
# -------------------------------------------------------------------------------------

# Like status_error(), but also sends a non-200 HTTP status, so CList's fetch()
# can detect failure via response.ok rather than having to inspect the JSON body.
# Scoped to this file only - status_error() itself is shared by ~175 call sites
# across the app and is left alone.
sub api_clist_error {
	print "Status: 400 Bad Request\r\n";
	&status_error(@_);
}

sub api_clist_authenticate {

	&api_clist_error("CList integration not configured (no token set)") unless ($Site->{clist_api_token});
	&api_clist_error("Invalid or missing token") unless ($vars->{token} && $vars->{token} eq $Site->{clist_api_token});

	&api_clist_error("CList integration not configured (no person set)") unless ($Site->{clist_person_id});
	my $p = &db_get_record($dbh,"person",{person_id=>$Site->{clist_person_id}});
	&api_clist_error("CList integration person not found") unless ($p);
	%$Person = %$p;
}

sub api_clist_publish {

	&api_clist_authenticate();

	&api_clist_error("Title required") unless ($vars->{title});
	&api_clist_error("Description required") unless ($vars->{description});
	&api_clist_error("Link required") unless ($vars->{link});

	my $record = {
		post_type        => "link",
		post_title       => $vars->{title},
		post_description => $vars->{description},
		post_link        => $vars->{link},
	};

	my $id = $vars->{id};
	unless ($id) {
		my $dup = &find_duplicate_post($dbh,$vars->{link});
		$id = $dup->{post_id} if ($dup);
	}
	$record->{post_id} = $id if ($id);

	&record_sanitize_input($record);
	&record_defaults("post",$record);
	if ($id) { &record_update_info("post",$record); } else { &record_creation_info("post",$record); }

	$id = &record_save($dbh,$record,"post",$record);
	&api_clist_error("Could not save post") unless ($id);

	use JSON;
	print to_json({ status => "OK", post_id => $id+0, url => $Site->{st_url}."post/".$id });
	exit;
}

sub api_clist_fetch {

	&api_clist_authenticate();

	&api_clist_error("Post id required") unless ($vars->{id});

	my $post = &db_get_record($dbh,"post",{post_id=>$vars->{id}});
	&api_clist_error("Post not found") unless ($post);

	use JSON;
	print to_json({
		status      => "OK",
		post_id     => $post->{post_id}+0,
		title       => $post->{post_title},
		description => $post->{post_description},
		link        => $post->{post_link},
		post_type   => $post->{post_type},
		url         => $Site->{st_url}."post/".$post->{post_id},
	});
	exit;
}

1;
