
#               RECORDS
# ------------------------------------------------------------------------------
	# ---------------------------------------------------------------------------------------------------
	#
	#                        RECORD SUBMIT
	#
	#    One Submit to Rule them All
	#
	#    Record data: $vars
	#    Person data: $Person
	#
	# ---------------------------------------------------------------------------------------------------

sub record_submit {

	my ($dbh,$vars,$return) = @_;

	$vars->{force} = "yes";


	&error($dbh,$query,"api","Database not initialized") unless ($dbh);		# Set database
	my $table = $vars->{db} || &error($dbh,$query,"api","Table not specified");	# Set table

	&record_sanitize_input($vars);							# Sanitize input
	&record_anti_spam($dbh,$table,$vars);						# No Spam!

	&record_autoformat($table,$vars);						# Autoformat text-based input
	&record_convert_dates($table,$vars);						# Convert input dates to epoch

	my $record = &record_load($dbh,$table,$vars);					# Load or create new record
	my $id = &record_save($dbh,$record,$table,$vars) ||
		&error($dbh,$query,"api","Error saving record");			# Save record

	my $new_record = &record_verify($dbh,$table,$id);				# Verify and return saved record

	&record_graph($dbh,$vars,$table,$new_record);					# Create graph of associated entities

											# Remove Cache
  #	&db_cache_remove($dbh,$table,$id);						# (So people can see their updates)
  #	&db_cache_remove($dbh,$table,$vars->{$table."_thread"});

	if ($return) { return $record->{$table."_".$return}; }				# Quick return without preview

	$preview .= &record_preview($dbh,$table,$id,$vars);				# Generate Preview version

	$vars->{msg} .= &record_notifications($dbh,$vars,$table,$record,$preview);			# Send email notifications to admin

	return ($id,$preview);								# Full return with preview
}

	# -------  Graph Record ---------------------------------------------
	#
	#   This function associates a just-saved record with records in other tables
	#   Values for these other records are submitted in $vars and always have the prefix 'keyname_'
	#   For example, a field named 'keyname_author' will refer to the name of an author in the 'author' table
	#   The function produces a record in the graph table
	#   It will also create a new record in the other table, if necessary
	#   Be sure to set $new_record->{type} before sending $new_record to this function (where 'type' = new_record's table)
	#
sub record_graph {

	my ($dbh,$vars,$table,$new_record) = @_;

	# return unless ($vars->{$table."_status"} eq "Final");				# Can be commented out, but really
											# graphs entries shouldn't be created
											# until the user commits
	$new_record->{type} ||= $table;	# Just in case

	while (my ($vkey,$vval) = each %$vars) {

		if ($vkey =~ /^keyname_(.*?)$/) {				# Eg. 'keyname_author'
			my $keytable = $1; 					# This is a record in another table associated with this one Eg. 'author'
			my @keynamelist = parse_csandv($vval);  		# Find eg. authors, split: first, second and third  (but leave values in quotes intact)
			foreach my $keyname (@keynamelist) {			# For each., eg. author...

				$keyname =~ s/^ | $//g;	 			# Trim leading, trailing white space

				my $keyfield = &get_key_namefield($keytable);	# Are we looking for _name, _title ...?
				my $keyrecord = &db_get_record($dbh,$keytable,{$keyfield=>$keyname});	# can we find a record with that name or title?

				unless ($keyrecord) {				# Record wasn't found, create a new record, eg., a new 'author'
					$keyrecord = {
						$keytable."_creator"=>$Person->{person_id},
						$keytable."_crdate"=>time,
						$keyfield=>$keyname
					};
					$keyrecord->{$keytable."_id"} = &db_insert($dbh,$query,$keytable,$keyrecord);
					&error($dbh,"","api","New $keytable crash and burn") unless ($keyrecord->{$keytable."_id"});
				}


				$keyrecord->{type}=$keytable;
								# Create Graph Record
				if ($keytable eq "author") { $keytype = "by"; }
				else { $keytype = "in"; }
				&save_graph($keytype,$new_record,$keyrecord);
			}
		}
	}
}

	# -------  Sanitize ------------------------------------------------------
	#
	# Clean hashes of programs, injection code, etc
	#
sub record_sanitize_input {


	my ($vars) = @_;

	while (my ($vkey,$vval) = each %$vars) {

		$vars->{$vkey} =~ s/#!//g;				# No programs!
		$vars->{$vkey} =~ s/\x{201c}/"/g;	# "
		$vars->{$vkey} =~ s/\x{201d}/"/g;	# "
		$vars->{$vkey} =~ s/\x{2014}/-/g;	# '
		$vars->{$vkey} =~ s/\x{2018}/'/g;	# '
		$vars->{$vkey} =~ s/\x{2019}/'/g;	# '
		$vars->{$vkey} =~ s/\x{2026}/.../g;	# ...
		$vars->{$vkey} =~ s/'/&apos;/g;	#     No SQL injections

		# If it's not from a JS editor, auto-insert spaces
		unless ($vars->{$vkey} =~ /^<p>/i) {
			$vars->{$vkey} =~ s/\r//g;
	#		$vars->{$vkey} =~ s/\n/\n\n/g;   # Adds an extra LF for single returns - converts MS Doc paras to extra LFs
	#		$vars->{$vkey} =~ s/\n\n\n/\n\n/g; $vars->{$vkey} =~ s/\n/<br\/>/g;
		}
	}


	unless ($Site->{context} eq "rcomment") { return if ($Person->{person_status} eq "Admin"); }

	$vars->{$vkey} =~ s/<(\/|)(scr|if|ob|e|t)(.*?)>//sig;	# No scripts, iframes, embeds, tables

	unless ($Site->{context} eq "rcomment") { return if ($Person->{person_status} eq "Registered"); }

	$vars->{$vkey} =~ s/<(\/|)(a|img)(.*?)>//sig;	# No links, images

}

	# -------  Anti-Spam ------------------------------------------------------
	#
	# Like the title says
	#
sub record_anti_spam {		# Checks input for spam content and kills on contact

	my ($dbh,$table,$vars) = @_;

	# die "Commenting disabled due to persistent and annoying spammers." unless $Person->{person_status} eq "admin";


								# Define test text

	my $d = $table."_description";
	my $t = $table."_title";
	my $c = $table."_content";
	my $test_text = $vars->{$d}.$vars->{$t}.$vars->{$c};
	my $sem_text = $vars->{$d}.$vars->{$c};

								# Require Users to Have Remote Addr
								# if they fail access permissions
	unless (&is_viewable("spam","remote_addr")) {
		unless ($ENV{'REMOTE_ADDR'}) {
			&error($dbh,$query,"api","Who are you?");
		}
	}

								# Require Comment Code Match
  #	unless (&is_viewable("spam","code_match")) {
  #
  #		unless (&check_code($vars->{post_thread},$vars->{code}) || $table ne "post" || $vars->{code} eq "override") {
  #			&error($dbh,$query,"api",qq|Spam code mismatch - $vars->{post_thread},$vars->{code}  - (used to prevent robots from
  #			submitting comments). Try this: copy your comment (highlight and ctl/c),
  #			reload the web page ( do a shift-reload #for force a full reload),
  #			paste the comment into the form, and submit again.|,"CONTENT: $test_text");
  #		}
  #	}

								# Ban multiple links
	unless (&is_viewable("spam","many_links")) {
		my $c; while ($test_text =~ /http/ig) { $c++ }
		my $d; while ($test_text =~ /url/ig) { $d++ }
		if (($c > 5)||($d > 15)) {
			&error($dbh,$query,"api","This post is link spam. Go away. (Too many links)","CONTENT: $test_text");
		}
	}

								# Ban scripts
	unless (&is_viewable("spam","scripts")) {
		if ($test_text =~ /<(.*?)(script|embed|object)(.*?)>/i) {
			&error($dbh,$query,"api","No scripts in the comments please.","CONTENT: $test_text");
		}
	}

								# Ban links
	unless (&is_viewable("spam","links")) {
		if ($test_text =~ /<a(.*?)>/i) {
			&error($dbh,$query,"api","No links in the comments please.","CONTENT: $test_text");
		}
	}


								# Ban words
	unless (&is_viewable("spam","links")) {
		if ($test_text =~ /(You are invited|viagra|areaseo|carisoprodol|betting|pharmacy|poker|holdem|casino|roulette|phentermine|ringtone|insurance|diet|ultram| pills| loans|tramadol|cialis|penis|handbag| shit | cock | fuck | fucker | cunt | motherfucker | ass )/i) {
			&error($dbh,$query,"api","Spam in the text.","CONTENT: $test_text");
		}
	}


								# Ban short comments
	unless (&is_viewable("spam","length")) {
		my $test_text_length = length ($test_text);
		if ($test_text_length < 150) {
			&error($dbh,$query,"api","Comments must be long enough to mean something.","CONTENT: $test_text");
		}
	}


								# Semantic Test
								# applied to post only

	unless (&is_viewable("spam","semantic")) {

		unless ($sem_text =~ / and | or | but | the | is | If | you | my | me | he | she | was | will | all | some | I /i) {
			if ($table eq "post") {
				&error($dbh,$query,"api","This content makes no sense and has thus been classified as spam","CONTENT: $test_text");
			}
		}
	}



	# Filter by IP
	unless (&is_viewable("spam","ip")) {
		if (&db_locate($dbh,"banned_sites",{banned_sites_ip => $ENV{'REMOTE_ADDR'}})) {
			&error($dbh,$query,"api","Your IP address has been classified as a spammer.");
		}
	}

	return 1;
}


	# -------  Delete a Record -----------------------------------------------------
	#
	# gets rid of a record forever, and doubles as a spamcatcher
	# should only be used by admin
	#
	#
	# RECORD
	#---------------------Delete ------------------------------------
sub record_delete {
	my ($dbh,$query,$table,$id,$mode) = @_;

	my $vars = $query->Vars;

						# Get Record from DB

	my $wp = &db_get_record($dbh,$table,{$table."_id"=>$id});
	$wp->{post_title} ||= &printlang("Record no longer exists");


						# Permissions
	die "You are not allowed to delete this record" unless (&is_allowed("delete",$table,$wp));
	my $readername = $Person->{person_name} || $Person->{person_title};

						# Ban spam sender IP
	my $banned;
	if ($vars->{action} =~ /spam/i) {
		my $bs=();
		$bs->{banned_sites_ip} = &db_record_crip($dbh,$table,$id);
		&db_insert($dbh,$query,"banned_sites",$bs);
		$banned = &printlang("Sender banned",$bs->{banned_sites_ip});

	}

						# Delete the record

	&db_delete($dbh,$table,$table."_id",$id);

						# Delete related graph entries

	my $sql = "DELETE FROM graph WHERE graph_tableone=? AND graph_idone = ?";
	my $sth = $dbh->prepare($sql);
    	$sth->execute($table,$id);
	my $sql = "DELETE FROM graph WHERE graph_tabletwo=? AND graph_idtwo = ?";
	my $sth = $dbh->prepare($sql);
    	$sth->execute($table,$id);

						# Remove Cache
  #	&db_cache_remove($dbh,$table,$id);
  #	&db_cache_remove($dbh,$table,$wp->{$table."_thread"});




								# Return message
	$vars->{msg} .= qq|<p><br /> @{[&printlang("Record id deleted",$id,$banned)]} </p>|;
	$vars->{api} = 	&printlang("Deleted record",$wp->{post_title});		# Needs to be fixed
	$vars->{title} = &printlang("Table id deleted",&printlang($table),$id,$readername);

	return if ($mode eq "silent");
	#&send_notifications($dbh,$vars,$table,$vars->{title},$vars->{msg});

}

	# -------  Convert Dates ------------------------------------------------------
	#
	#   All dates input are turned to epoch
	#   That's just how I roll
	#
	#
sub record_convert_dates {

	my ($table,$vars) = @_;

											#Set default timezones, durations
	$vars->{$table."_timezone"} ||= $Site->{st_timezone} || "America/Toronto";	# Allows input to specify timezone
	unless ($vars->{$table."_duration"}) {$vars->{$table."_duration"} = "1:00";}
	unless ($vars->{$table."_duration"} =~ /:/) {$vars->{$table."_duration"} .= ":00";}

										# Convert datepicker input to epoch
	$vars->{$table."_start"} = &datepicker_to_epoch($vars->{$table."_start"},$vars->{$table."_timezone"});
	$vars->{$table."_finish"} = &datepicker_to_epoch($vars->{$table."_finish"},$vars->{$table."_timezone"});

}

	# -------  Autoformat ------------------------------------------------------
	#
	#   Autoformatting for comment-form based input
	#
	#
sub record_autoformat {

	my ($table,$vars) = @_;

	return if ($vars->{autoformat} eq "off");				# May be turned off from form
	foreach (qw(description content)) {
		my $element = $table."_".$_;



		unless ($vars->{$element} =~ /^<p|^<div/i) { 				# Unless from text-fromatter (eg TinyMCE)...

			$vars->{$element} =~ s/\n/<br\/><br\/>/g; 			# Auto line feed
			$vars->{$element} =~ s/<br\/><br\/><br\/>/<br\/><br\/>/g;	# (Double to enable seamless MS-Word paste)

			$vars->{$element} =~ s/\s\*(.*?)\*(\s|\.|,|;|:)/ <b>$1<\/b> /g;	# Auto bold

			$vars->{$element} =~ s/\s_(.*?)_(\s|\.|,|;|:)/ <i>$1<\/i> /g;	# Auto italics
		}

	}

}

	# -------  Load Record ------------------------------------------------------
	#
	#   Loads the new record into memory, combining existing record information with new form submission info
	#
	#
sub record_load {

	my ($dbh,$table,$vars) = @_;
	my $record;
  #identifier
	my $id = &db_locate($dbh,$table,{$table."_identifier"=>$vars->{identifier}}) || $vars->{id} || "new";
	&record_defaults($table,$vars);

	if ($id =~ /new/i) { 					# Create New Record


		&error($dbh,$query,"api","Permission denied to create $table") unless (&is_allowed("create",$table));

		&error($dbh,$query,"api","This $table already exists, you can't recreate it")
			unless (&record_unique($dbh,$table,$vars));
		$vars->{$table."_id"} = "new";
		$record = gRSShopper::Record->new({tag=>$table});
		&record_creation_info($table,$vars);							# Set creation info

	} else { 						# Load Existing Record

		$record = &db_get_record($dbh,$table,{$table."_id"=>$id});
		&error($dbh,$query,"api","Record ID $id not found") unless ($record->{$table."_id"});
		$vars->{$table."_id"} = $record->{$table."_id"};
		$vars->{id} = $record->{$table."_id"};
		&error($dbh,$query,"api","Permission denied to edit $table record $id") unless (&is_allowed("edit",$table,$record));
		&record_update_info($table,$vars);							# Set update info
	}

								# Load vars into Record and return record
								# Note: record is NOT saved at this point, only loaded

	while (my($vx,$vy) = each %$vars) { $record->{$vx} = $vy;  }

	return $record;
}

	# -------  Unique Record ------------------------------------------------------
	#
	# Is this a unique record? Returns 1 if yes, 0 if no
	#
sub record_unique {

	my ($dbh,$table,$vars) = @_;

	if ($table eq "event") {
		return 0 if (&db_locate($dbh,$table,{event_title=>$vars->{event_title},event_start=>$vars->{event_start}}));
	} elsif ($table eq "post" && $vars->{post_type} eq "link") {
		return 0 if (&db_locate($dbh,$table,{post_link=>$vars->{post_link}}));
	}

	return 1;


}

	# -------  Save Record ------------------------------------------------------
	#
	# Save record (*update or create) and return record id
	#
sub record_save {

	my ($dbh,$record,$table,$vars) = @_;
	my $record_id;						# ID of saved record

	if ($record->{$table."_id"} && $record->{$table."_id"} ne "new") {
		$record_id = &db_update($dbh,$table,$vars,$record->{$table."_id"});
		$vars->{msg} .= "Updated $table ($record_id)";
	} else {
		$record_id = &db_insert($dbh,$query,$table,$vars);
		$vars->{id} = $record_id;
		$record->{$table."_id"} = $record_id;
		#$vars->{msg} .= "Created new $table ($record_id)";
	}
	return $record_id;
}

	# -------  Verify ------------------------------------------------------
	#
	# Returns newly saved record with type info for further processing
	#
sub record_verify {

	my ($dbh,$table,$id) = @_;
	my $new_record=&db_get_record($dbh,$table,{$table.+"_id"=>$id});
	&error($dbh,"","api","New $table record not created properly.") unless ($new_record);
	$new_record->{type} = $table;
}

	# -------  Creation Info ------------------------------------------------------
	#
	# Set record creator crdate, creation IP and identifier
	#
sub record_creation_info {

	my ($table,$vars) = @_;

	$vars->{$table."_creator"} = $Person->{person_id};

	$vars->{$table."_crdate"} = time;
	$vars->{$table."_crip"} = $ENV{'REMOTE_ADDR'};
	$vars->{$table."_identifier"} = $vars->{identifier};


}

	# -------  Update Info ------------------------------------------------------
	#
	# Set record creator crdate, creation IP and identifier
	#
sub record_update_info {

	my ($table,$vars) = @_;

	$vars->{$table."_updater"} = $Person->{person_id};
	$vars->{$table."_updated"} = time;
	$vars->{$table."_upip"} = $ENV{'REMOTE_ADDR'};

}

	# -------  Defaults ------------------------------------------------------
	#
	# Set record defaults
	#
sub record_defaults {

	my ($table,$vars) = @_;

								# Status  (Need some work to standardize on this)
	$vars->{$table."_status"} ||= "None";
	if ($vars->{pushbutton} eq "preview") { $vars->{$table."_status"} = "Draft"; }
	elsif ($vars->{pushbutton} eq "done") { $vars->{$table."_status"} = "Final"; }
	if ($Person->{person_status} eq "Admin") {
		if ($vars->{pushbutton} eq "rejected") { $vars->{$table."_status"} = "Rejected"; }
		else { $vars->{$table."_status"} = "Approved"; }
	}

								# Type

	if ($vars->{newautoblog}) { $vars->{post_type} = "link"; }				# Autoblog, first input, default to Link
	unless ($Person->{person_status} eq "admin") { $vars->{post_type} ||= "comment"; }	# Default to comment

								# Source
	if ($vars->{newautoblog}) { $vars->{$table."_source"} = "autoblog"; }
	else  { $vars->{$table."_source"} = "page"; }

								# Title, Description, Dates

	&error($dbh,$query,"api",ucfirst($table)." requires a title") unless ($vars->{$table."_title"});
	&error($dbh,$query,"api",ucfirst($table)." requires a description") unless ($table eq "feed" || $vars->{$table."_description"});
	if ($table eq "feed") { &error($dbh,$query,"api",ucfirst($table)." requires a link") unless ($vars->{$table."_link"}); }
	if ($table eq "event") {
		&error($dbh,$query,"api",ucfirst($table)." requires a start time") unless ($vars->{$table."_start"});
	}

								# Link

	if ($vars->{post_type} eq "link") { unless ($vars->{post_link}) { &error($dbh,$query,"api","Link post requires a link"); } }
	unless ($vars->{$table."_link"}	=~ /http/) { $vars->{$table."_link"} = "http://".$vars->{$table."_link"}; }
	unless ($vars->{$table."_html"}	=~ /http/) { $vars->{$table."_html"} = "http://".$vars->{$table."_html"}; }

								# Author
	$vars->{$table."_author"} ||= $Person->{person_name} || $Person->{person_title} || $Site->{st_anon} || "Any Mouse";

}

	# -------  Record Preview ------------------------------------------------------
	#
	# 	Return a preview of our newly minted record
	#
sub record_preview {

	my ($dbh,$table,$id,$vars) = @_;

	my $preview = &db_get_record($dbh,$table,{$table."_id" => $id});			# Get record




	my $wp = {}; 									# Format Record
	$vars->{comments} = "no";
	$wp->{table} = $table;
	$wp->{page_content} = &format_record($dbh,$query,$table,"preview",$preview);
	&format_content($dbh,$query,$options,$wp);

	my $hh;
	if ($table eq "event") { $hh = qq|<section>@{[&printlang("Start")]} <h3>|.&nice_date($preview->{$table."_start"}) ."</h3>"; }
	elsif ($table eq "post") { $hh = qq|<h3>@{[&printlang("Preview")]}</h3><p>@{[&printlang("Continue editing")]}</p>|; }




											# Return text
	return $hh.
		qq|$wp->{page_content}|.
		qq|</section>|;




}
sub record_notifications {

	my ($dbh,$vars,$table,$record,$preview) = @_;

  #	$Site->{st_crea} = "stephen\@downes.ca";

	# If User is done editing - status = "Final" (or feed)

	if ($record->{$table."_status"} eq "Final" || $table eq "feed") {


		if ($Person->{person_status} eq "admin") {
			$vars->{msg} = qq|<p class="notice">@{[&printlang("Automatic approval",&printlang($table))]} </p>|;
			return;
		}



		# Compose notification message

		my $readername = $Person->{person_name} || $Person->{person_title};
		my $mailtext = qq|
			@{[&printlang("Dear")]} <name> <email>,<br><br>
			@{[&printlang("New submitted approval needed",&printlang($table),$Site->{st_name},$readername)]}<br/><br/>
			$preview<br/><br/>
			[<a href="$Site->{st_cgi}admin.cgi?$table=$record->{$table."_id"}&action=approve&from=email">Approve</a>]
			[<a href="$Site->{st_cgi}admin.cgi?$table=$record->{$table."_id"}&action=edit&from=email">Edit</a>]
			[<a href="$Site->{st_cgi}admin.cgi?$table=$record->{$table."_id"}&action=reject&from=email">Reject</a>]
			[<a href="$Site->{st_cgi}admin.cgi?$table=$record->{$table."_id"}&action=delete&from=email">Delete</a>]
			[<a href="$Site->{st_cgi}admin.cgi?$table=$record->{$table."_id"}&action=spam&from=email">Spam</a>]</p>|;


	        my $subject = &printlang("New submitted",&printlang($table),$record->{$table."_id"},$Site->{st_name});
	        &send_notifications($dbh,$vars,$table,$subject,$mailtext);

	        my $return_message .= qq|<p class="notice">@{[&printlang("Has been submitted",&printlang($table),$Site->{st_name})]}|;
	        if ($table eq "feed") { $return_message .=  &printlang("Check feed status",$Site->{st_cgi}."login.cgi?action=Options"); }
	        $return_message .= "</p>";

		return $return_message;
	} else {

		return;
	}


	# Not working yet, temporary storage of legacy code
	if ($record->{$table."_status"} eq "Approved") {


					# Update email notification list
	if ($vars->{anon_email}) {						# Detect anonymous email
		$vars->{post_email_checked} = "checked";
		$Person->{person_email} = $vars->{anon_email};
	}

	if ($vars->{post_email_checked} eq "checked") {
		&add_to_notify_list($dbh,$Person->{person_email},$vars->{$table."_thread"});
	} else {
		&del_from_notify_list($dbh,$Person->{person_email},$vars->{$table."_thread"});
	}


					# Get Email Addresses
		my $elist = &db_get_single_value($dbh,"post","post_emails",$vars->{$table."_thread"});

		my @earray = split ",",$elist;


					# Send Emails
					# To Email List
		my $adr = $Site->{em_discussion};
		my $eml = "";
		foreach my $e (@earray) {
			my $emailcontent = $wp->{page_content};
			$emailcontent =~ s/<SUBSCRIBEE>/$e/g;
			$eml .= $e." <br/>\n";
			last if ($e eq "none");
			#&send_email($e,$adr,$ttitle,$emailcontent,"htm");
		}
	}
}

sub make_new_record {

	my ($table,$data) = @_;
	my $id;

print "Content-type: text/html\n\n";

	# Record might be a database table where we know the title but not the id
	# so we'll try to look up the ID
	my $input_data_type = ref($data) || "string";
	if ($data && $input_data_type eq "string" && $id ne "new") {	 
		$id = &db_locate($dbh,"form",{$table."_title"=>$data}); 
		print "Found existing record<p>";
		}

	# Otherwise, yes, we're creating a new record
	else {
		my $record; # I will eventually replace this with gRSShopper::record->new()
print "Making new record";
		# If $data is a string, it's our new title
		if ($input_data_type eq "string") { 
			$record->{$table."_name"} = $data; 
			$record->{$table."_title"} = $data;
		}
		
		# Otherwise, the data is the seed data for our new record
		else {
			while (my($dx,$dy) = each (%$data)) {
				next if ($dx =~ /_id$/i);
				$record->{$dx} = $dy;
			}
		}

		&record_sanitize_input($record);
		
		# Initialize values for NEW record, overwriting seed data as needed
			
			# Undefined forms are throwing an error here - may be a db error for event
			unless ($table eq "event") {
			$record->{$table."_creator"} = $Person->{person_id};
			}

			$record->{$table."_crdate"} = time;
			$record->{$table."_pub_date"} = &tz_date(time,"day","");
print "Inserting data";
		# Save the values and obtain new record id
		$id = &db_insert($dbh,$query,$table,$record);
	}
	
 	return $id;
}



1;