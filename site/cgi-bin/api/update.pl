# Field update functions: api_textfield_update, api_password_update, api_datetime_update

# API UPDATE ----------------------------------------------------------
# ------- Text -----------------------------------------------------
#
# Update a text field
#
# -------------------------------------------------------------------------

sub api_textfield_update {

	my ($vars) = @_;
	$vars->{format} = "json"; 
					
	unless ($vars->{table} && $vars->{field} && $vars->{value} && $vars->{id}) {
		&status_error("Update command requires a table name, ID number, and a value");
	}
	
	my $field = $vars->{field}; my $fieldprefix = $vars->{table}."_";
	unless ($field =~ /^$fieldprefix/) { $field = $fieldprefix.$field; }
		
	&status_error("Field $field does not exist") unless (&__check_field($vars->{table},$vars->{field}));
	
	# Check for duplicates - same external resource already posted, by normalized link
	if ($vars->{table} eq "post" && $field eq "post_link" && $vars->{value}) {
		if (my $dup = &find_duplicate_post($dbh,$vars->{value},$vars->{id})) {
			my $existing_title = &db_get_single_value($dbh,"post","post_title",$vars->{id});
			unless ($existing_title) {
				# Still a blank New-Post stub (no title yet) - safe to discard rather
				# than leave an empty duplicate row behind
				&db_delete($dbh,"post","post_id",$vars->{id});
			}
			&status_error(qq|<p>This looks like a duplicate of "$dup->{post_title}".<br/>
			<span onclick="openDiv('$Site->{st_cgi}api.cgi','editor','edit','post','$dup->{post_id}','Edit')"><i class="fa fa-edit"></i> Click here to edit it instead</span></p>|);
		}
	}

	# Submit the data
	my $id_number = &db_update($dbh,$vars->{table}, {$vars->{field} => $vars->{value}}, $vars->{id});

	# If successful
	if ($id_number) {

$vars->{message} .= "Successfully updated $id_number";

		# If the post's publication date changed, move any pending social-media
		# schedule rows for it to match (see services/social_schedule.pl)
		if ($vars->{table} eq "post" && $field eq "post_pub_date") {
			&reschedule_social_posts_for_post($dbh,$vars->{table},$vars->{id},$vars->{value});
		}

		# If table is optlist, update search forms
		if ($vars->{table} eq "optlist") {
$vars->{message} .= " Updating search form";			
			$vars->{message} .= &make_search_forms();    # Located in make.pl
		}

		# Update the cached version of the record
 		# &output_record($dbh,$query,$vars->{table},$vars->{id},"viewer");
		 
		my $published = &db_get_single_value($dbh,$vars->{table},$vars->{table}."_social_media",$vars->{id});

		# Update if already published to web
		# Autopublishing author, feed
		if (($published // '') =~ /web/ || $vars->{table} =~ /author|feed|post/) {
		
			&print_record($vars->{table},$vars->{id});
		
		}   
		
		return $id_number;

  } else { &api_error(); }
	die "api failed to update $vars->{table_name}  $vars->{table_id}" unless ($id_number);


}
# API UPDATE ----------------------------------------------------------
# ------- Password -----------------------------------------------------
#
# Encrypt and Update Password
#
# -------------------------------------------------------------------------

sub api_password_update {

	$vars->{format} = "json";

	# Encrypt password
	my $encr_pass = &_encrypt_password($vars->{value});
	
	# Submit the data
	my $id_number = &db_update($dbh,$vars->{table}, {$vars->{field} => $encr_pass}, $vars->{id});
	$vars->{message} .= "Updated $vars->{type} for $vars->{table} $vars->{id}";
	&status_ok();

}
# API UPDATE ----------------------------------------------------------
# ------- DateTime -----------------------------------------------------
#
# Update Date Time
#
# -------------------------------------------------------------------------

sub api_datetime_update {


	unless (&__check_field($vars->{table_name},$vars->{col_name})) {

		print "Field does not exist";
	  die "Field does not exist";
	}

  my $epoch = datepicker_to_epoch($vars->{value});
	# Convert value to epoch (which is what we'll actually save for a datetime)

	my $id_number = &db_update($dbh,$vars->{table_name}, {$vars->{col_name} => $epoch}, $vars->{table_id});

	# Update the cached version of the record
	if ($id_number) {
		
		&output_record($dbh,$query,$vars->{table_name},$vars->{table_id},"viewer");
		my $published = &db_get_single_value($dbh,$vars->{table_name},$vars->{table_name}."_social_media",$vars->{table_id});
		if ($published =~ /web/) { 
			
			&print_record($vars->{table_name},$vars->{table_id}); 
			
		}   # Update if alread published to web

		&api_ok();
	} else { &api_error(); }
	die "api failed to update $vars->{table_name}  $vars->{table_id}" unless ($id_number);


}

1;
