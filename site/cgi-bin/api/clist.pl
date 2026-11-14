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

sub api_clist_authenticate {

	&status_error("CList integration not configured (no token set)") unless ($Site->{clist_api_token});
	&status_error("Invalid or missing token") unless ($vars->{token} && $vars->{token} eq $Site->{clist_api_token});

	&status_error("CList integration not configured (no person set)") unless ($Site->{clist_person_id});
	my $p = &db_get_record($dbh,"person",{person_id=>$Site->{clist_person_id}});
	&status_error("CList integration person not found") unless ($p);
	%$Person = %$p;
}

sub api_clist_publish {

	&api_clist_authenticate();

	&status_error("Title required") unless ($vars->{title});
	&status_error("Description required") unless ($vars->{description});
	&status_error("Link required") unless ($vars->{link});

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
	&status_error("Could not save post") unless ($id);

	use JSON;
	print to_json({ status => "OK", post_id => $id+0, url => $Site->{st_url}."post/".$id });
	exit;
}

sub api_clist_fetch {

	&api_clist_authenticate();

	&status_error("Post id required") unless ($vars->{id});

	my $post = &db_get_record($dbh,"post",{post_id=>$vars->{id}});
	&status_error("Post not found") unless ($post);

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
