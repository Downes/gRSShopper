	sub admin_permissions {

		my ($dbh,$query) = @_;
		$Site->{admin_pane}	= "permissions";
		return unless (&is_viewable("admin","permissions")); 		# Permissions

		my $content = qq|<h2>Permissions</h2><p>|;

		# my @tables = $dbh->tables();
		my @tables = &db_tables($dbh);
		my @actions = qw{create approve edit delete view};
		my @reqs = qw{admin editor owner project registered anyone};


		$content .= qq|<style>

			select.admin {background-color: #cc0000;}
			select.owner {background-color: #ffcccc;}
			select.editor {background-color: #FF7F00;}
			select.project {background-color: #ffcc00;}
			select.registered {background-color: #ff00cc;}
			select.anyone {background-color: #008800;}
			option.admin {background-color: #cc0000;}
			option.editor {background-color: #FF7F00;}
			option.owner {background-color: #ffcccc;}
			option.project {background-color: #ffcc00;}
			option.registered {background-color: #ff00cc;}
			option.anyone {background-color: #008800;}
			select, option { width: 100px; }
			</style>
			|;

		# Table Headings
		$content .= qq|<form method="post" action="admin.cgi">
			<input type="hidden" name="title" value="Permissions">
			<input type="hidden" name="action" value="config">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">|;
		$content .= "<p><table cellpadding=3 cellspacing=0 border=1>";
		$content .= "<tr><td><i>Data Type</i></td>";
		foreach my $action (@actions) { $content .= "<td>".ucfirst($action)."</td>"; }
		$content .= "</tr>\n";

		foreach my $table (@tables) {
			$content .= "<tr><td>".ucfirst($table)."</td>";
			foreach my $action (@actions) {

				my $vname = $action."_".$table;
				my $creq = &permission_current($action,$table);
				$content .= qq|<td><select name="$vname" class="$creq" >\n|;
				foreach my $req (@reqs) {
					my $sel="";if ($creq eq $req) { $sel = " selected"; }
					$content .= qq|<option class="$req" value="$req"$sel> $req</option>\n|;
				}
				$content .= qq|</select></td>\n|;
			}
			$content .= "</tr>\n";
		}

		$content .= qq|</table></p>Color will not change until data has been saved.<br>
			<input type="submit" value="Update Permissions"></form>|;




		&admin_frame($dbh,$query,"Admin Permissions",$content);					# Print Output
		exit;

	}



	# -----------------------------------   Admin: Harvester   -----------------------------------------------
	#
	#   Harvester management utilities
	#
	# ------------------------------------------------------------------------------------------------------

	sub admin_users {

		my ($dbh,$query) = @_;


		return unless (&is_viewable("admin","users")); 		# Permissions
		$Site->{admin_pane}	= "users";
		my $adminlink = $Site->{st_cgi}."admin.cgi";

		my $intro = "";
		if ($vars->{msg}) { $intro = qq|<p class="notice">$vars->{msg}</p>|; }
		else { $intro = "<p>On this page you can manage your user accounts and newsletter subscriptions. Note that
			you can also access user accounts directly by searching and editing in the 'Persons' table, left.</p>";	}


		my $content = qq|<h2>Users</h2>$intro|;


		$content .= &admin_configtable($dbh,$query,"Enable Registration",
			("Enable Registration:st_reg_on:yesno","Turn Capchas On:st_capcha_on:yesno"));

		$content .= &admin_configtable($dbh,$query,"Enable External Accounts",
			("Enable OpenID:st_openid_on:yesno","Enable Google:st_google_on:yesno"));

		$content .= &admin_configtable($dbh,$query,"Anonymous User",
			("Anonymous User Name:st_anon","Anonymous IUser ID:st_anon_id"));

		$content .= &admin_configtable($dbh,$query,"Sharing",
			("Share Tables:sh_tables","Share Fields:sh_fields"));

		$content .= qq|
			<h3>Find User</h3>
			<div class="adminpanel">
			<form method="post" action="$Site->{st_cgi}admin.cgi">
			<input type="hidden" name="action" value="eduser">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<table>
			<tr><td>User ID number:</td><td><input type="text" name="pid" size="20"></td></tr>
			<tr><td><b>or</b> userid:</td><td><input type="text" name="ptitle" size="40"></td></tr>
			<tr><td><b>or</b> name:</td><td><input type="text" name="pname" size="40"></td></tr>
			<tr><td><b>or</b> email:</td><td><input type="text" name="pemail" size="40"></td></tr>
			</td></tr></table>
			<input type="submit" value="Find User" class="button">
			</form>
			</div>
		|;


		$content  .= qq|
			<br/><h3>Import User List From File</h3>
			<div class="adminpanel">
			The system expects a file with
			field names in the first row. Importer will ignore field names it does not recognize.<br/><br/>
			<form method="post" action="$adminlink" enctype="multipart/form-data">
			<input type="hidden" name="action" value="import">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<table cellpadding=2>
			<input type="hidden" name="table" value="person">
			<tr><td>File URL:</td><td><input type="text" name="file_url" size="40"></td></tr>
			<tr><td>Or Select:</td><td><input type="file" name="file_name" /></td></tr>
			<tr><td>Data Format:</td><td><select name="file_format"><option value="">Select a format...</option>
			<option value="tsv">Tab delimited (TSV)</option>
			<option value="csv">Comma delimited (CSV)</option></select></td>
			<tr><td colspan=2><input type="submit" value="Import" class="button"></tr></tr></table>
			</form></div>|;

		$content .= qq|	<h3>Export User List</h3>
			<div class="adminpanel">

			<p>
			<form method="post" action="$adminlink">
			<input type="hidden" name="action" value="export_users">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<select name="exportformat">
			<option value="CSV" selected>Select a Format...</option>
			<option value="CSV">Comma Separated Values</option>
			<option value="TSV">Tab Separated Values</option>
			</select>
			<input type="submit" value="Export User List" class="button">
			</form>
			</p>



			</p></div>|;


		# It's here, but I just don't think it's wise to enable it
		# To enable, remove the word DISABLED

		 	$content .= qq|	<h4>Delete All Users</h4>
			<div class="adminpanel"><p>
			<form method="post" action="$adminlink">
			<input type="hidden" name="saction" value="remove_all">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<select name="action">
			<option value="NONONO" selected>Really?</option>
			<option value="DISABLEDremove_all">Yes, Really</option>
			</select>
			<input type="submit" value="Delete All Users" class="button">
			</form></p>
			</div><p>&nbsp;</p>|;



		&admin_frame($dbh,$query,"Admin General",$content);					# Print Output
		exit;



	}

	sub admin_users_edit {

		my ($dbh,$query) = @_;

		&error ($dbh,"","","Permission denied") unless ($Person->{person_status} eq "admin"); 		# Permissions

										# Find User Information
		my $user;
		if ($vars->{ptitle}) { $user = &db_get_record($dbh,"person",{person_title=>$vars->{ptitle}}); }
		elsif ($vars->{pname}) {  $user = &db_get_record($dbh,"person",{person_name=>$vars->{name}}); }
		elsif ($vars->{pemail}) {  $user = &db_get_record($dbh,"person",{person_email=>$vars->{pemail}}); }
		elsif ($vars->{pid}) {  $user = &db_get_record($dbh,"person",{person_id=>$vars->{pid}}); }
		else { &error($dbh,"","","User information was not supplied"); }
		unless ($user) { &error($dbh,"","","I feel terrible. User information was not found."); }

		$user->{person_name} ||= $user->{person_title};
		my $content = qq|<h2>User Information Found</h2>
			<div class="adminpanel">
			Name: $user->{person_name} ($user->{person_title})<br/>
			UserID: $user->{person_id}<br/>
			Email: $user->{person_email}<br/>
			[<a href="$Site->{st_cgi}admin.cgi?person=$user->{person_id}&action=edit">Edit $user->{person_name}</a>]<br/>
			[<a href="javascript:confirmDelete('$Site->{st_cgi}admin.cgi?person=$user->{person_id}&amp;action=Delete')">Delete $user->{person_name}</a>] <br>
			[<a href="$Site->{st_cgi}login.cgi?action=Subscribe&pid=$user->{person_id}">Edit Subscriptions</a>]<br/>
			<br/>Send this person a message:<br/>
			<form method="post" action="$Site->{st_cgi}admin.cgi">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<input type="hidden" name="action" value="sendmsg">
			<input type="hidden" name="userid" value="$user->{person_id}">
			<input type="text" size="40" name="subject">
			<textarea cols="80" rows="10" name="body"></textarea>
			<input type="submit" value="send email"></form>
			</div>|;



		my $user = &db_get_record($dbh,"person",{$table."_id"=>$id_number});



		 print $Site->{header};
		 print $content;
		 print $Site->{footer};
		 exit;

	}

	# -----------------------------------   Admin: Users: Send Message  --------------------------------------------
	#
	#   Manage Users
	#
	# ------------------------------------------------------------------------------------------------------

	sub admin_users_send_message {

		 my $content =qq|<h2>Message Sent</h2>|;


		&error ($dbh,"","","Permission denied") unless ($Person->{person_status} eq "admin"); 		# Permissions
		&error($dbh,"","","No body in message") unless ($vars->{body});
		&error($dbh,"","","No person to send to") unless ($vars->{userid});
		$vars->{subject} ||= "Message from $Person->{person_name} on $Site->{st_name}";

		my  $user = &db_get_record($dbh,"person",{person_id=>$vars->{userid}});
		&error($dbh,"","","No email address to send to") unless ($user->{person_email});
		$vars->{body} .= "\n\nSent from gRSShopper administrator on $Site->{st_name}\n";


		$vars->{subject} =~ s/&#39;/'/g;
		$vars->{body} =~ s/&#39;/'/g;
		$Site->{st_name} =~ s/&#39;/'/g;

		&send_email($user->{"person_email"},$Site->{em_from}, $vars->{subject},$vars->{body});




		 print $Site->{header};
		 print $content;
		 print $Site->{footer};
		 exit;
	}

	# -----------------------------------   Admin: Newsletters   -----------------------------------------------
	#
	#   Manage and Send Newsletters
	#
	# ------------------------------------------------------------------------------------------------------

	sub export_user_list {

		my ($dbh,$query) = @_;

		if ($vars->{exportformat} =~ /^CSV$/i) {			# CSV
			print "Content-type: text/plain\n\n";
			print &make_user_list($dbh,$query,"csv");

		}elsif($vars->{exportformat} =~ /^TSV$/i) {		# TSV
			print "Content-type: text/plain\n\n";
			print &make_user_list($dbh,$query,"tsv");
		}


	}

	sub make_user_list {

		my ($dbh,$query,$delim) = @_;

		my $endlim;
		if ($delim =~ /^CSV$/i) { $endlim = "\n"; $delim = ","; }
		elsif ($delim =~ /^TSV$/i) { $endlim = "\n";$delim = "\t"; }
		my $row = 0; my $output = "";

		my $sql = qq|SELECT * from person|;
		my $sth = $dbh -> prepare($sql);
		$sth -> execute();

		while (my $user = $sth -> fetchrow_hashref()) {
			my @titles; my @data;
			while (my ($ux,$uy) = each %$user) {
				$user->{$ux} =~ s/$delim/ /ig; 		# clean data of delimiters
				$user->{$ux} =~ s/$endlim/ /ig; 		# clean data of delimiters
				if ($row == 0) { $ux =~ s/person_//; push @titles,$ux; }
				push @data,$uy;
			}
			if ($row == 0) { my $topline = join $delim,@titles; $output .= $topline . "\n"; }
			my $line = join $delim,@data; $output .= $line . "\n";
			$row++;
		}
		return $output;

	}

	sub delete_all_users {

		my ($dbh,$query) = @_;

		$Site->{header} =~ s/\Q[*page_title*]\E/Delete All Users/g;
		$Site->{header} =~ s/\Q<page_title>\E/Delete All Users/g;
		print $Site->{header};
		print "<h1>Deleting All Users</h1>";
		print "<p>Ummm.... no. Go edit the code to allow this - line 1270 in admin.cgi</p>";
	exit;

	# Note - backup of subscription file needs column headers
	#exit;

		# Save a backup file
		&error($dbh,"","","Can't get users") unless ( my $savetext = &make_user_list($dbh,$query,"TSV") );
		my $savefile = $Site->{st_cgif}."/data/".$Site->{db_name}."_person_".time;
		&error("$dbh","","","Save Users: Cannot open $savefile: $!") unless (open OUT,">$savefile");
		&error("$dbh","","","Save Users: Cannot print to $savefile: $!") unless (print OUT $savetext);
		close OUT;
		print "<p>Backup of users saved to $savefile </p>";


		# Erase all subscriptions
		my $sql = qq|SELECT page_id FROM page WHERE page_type='email'|;
		my $sth = $dbh -> prepare($sql);
		$sth -> execute();
		while (my $page = $sth -> fetchrow_hashref()) {
			&autounsubscribe_all($dbh,$query,$page->{page_id},"return");
		}

		# Erase all users
		# Erase all subscriptions
		my $sql = qq|SELECT person_id,person_status FROM person|;
		my $sth = $dbh -> prepare($sql);
		$sth -> execute();
		while (my $user = $sth -> fetchrow_hashref()) {
			unless ($user->{person_status} eq "admin") {
				unless ($user->{person_id} eq "2") {
					&db_delete($dbh,"person","person_id",$user->{person_id});
				}
			}
		}
		print "<p>All users (except admin) deleted.</p>";

		print $Site->{footer};
		exit;
	}




	# -------   User Find Form -----------------------------------------------------
	#
	#   Quick form to find a user

	sub userfindform {

		my ($title,$action) = @_;

							# Permissions

		return unless (&is_allowed("edit","person"));

							# Form

		$Site->{header} =~ s/\Q[*page_title*]\E/$title/g;
		$Site->{header} =~ s/\Q<page_title>\E/$title/g;
		return 
			$Site->{header}.
			qq|<h2>$title</h2>
			<p>Select a person to edit. Enter:
			<form method="post" action="$Site->{st_cgi}login.cgi">
			<input type="hidden" name="action" value="$action">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			User ID number: <input type="text" name="pid" size="20"><br/><br/>
			<b>or</b> userid: <input type="text" name="ptitle" size="40"><br/><br/>
			<b>or</b> name: <input type="text" name="pname" size="40"><br/><br/>
			<b>or</b> email: <input type="text" name="pemail" size="40"><br/><br/>
			<input type="submit" value="Find User data" class="button">
			</form>|.
			$Site->{footer};

	}



	# -------   Import List --------------------------------------------------------

	sub import {

		my ($dbh,$query,$table) = @_;


		my $vars = $query->Vars;

	  
	  #while (my($fx,$fy) = each %$vars) { print "$fx = $fy<br>";}
		print "<h1>Importing List</h1>";
		print "Table: $table File: ".$vars->{myfile}."<br>";                  #"

		my $file;
		if ($query->param("myfile")) { $file = &upload_file(); }		# Uploaded File
		elsif ($vars->{file_url}) { $file = &upload_url($vars->{file_url}); }		# File from URL
		$file->{file_format} = $vars->{file_format};

		$file->{file_location}  = $Site->{st_urlf}.$file->{file_dir}.$file->{file_title};
		print "Got a file - $file->{file_location}  -- $file->{file_title} <p>";
		print "Format is $file->{file_format} <br>";


		if ($file->{file_format} =~ /^json$/i) {

			my $result = &import_json($file,$table);
			&admin_list_records($table);
			exit;
		}

		unless (&new_module_load($query,"Text::ParseWords")) {
			&error($dbh,"","","Text::ParseWords is not available");
		}

		my $count = 0;
		open (DBIN, "<:encoding(UTF-8)", $file->{file_location}) or &error($dbh,"","","Can't open $file->{file_location} $!");  # auto UTF-8 decoding on read
		#open DBIN,"<:encoding(UTF-8)"$file->{file_location}" or &error($dbh,"","","Can't open $file->{file_location} $!");
		my $count = 0; my @fields;
		while (<DBIN>) {
			chomp;
	#		print "$_ <br>\n";
			my @values; my $data;

									# Set Up Field Titles from Import File
			if ($count eq 0) {
				if ($file->{file_format} eq "tsv") { @fields = split "\t",$_; }
				elsif ($file->{file_format} eq "csv") {	@fields = parse_csv($_); }
				else { &error($dbh,"","","File format must be csv or tsv"); }
				print "Fields <br>";
				foreach my $field (@fields) {
				print "- $field <br>";					
					$field = lc($field);
					$field =~ s/ /_/g;
					$field =~ s/first_name/firstname/g;
					$field =~ s/last_name/lastname/g;
					if ($field eq "e-mail_address") { $field = "email"; }
					$field = $table ."_". $field;
				}
				print "<br>";
				$count++;
				next;
			}
			

									# Assign datafrom file to imput values
			else {
				if ($file->{file_format} eq "tsv") { @values = split "\t",$_; }
				elsif ($file->{file_format} eq "csv") {	@values = parse_csv($_); }
				#print @values,"<br>";
				my $innercount=0;
				print "<pre>";
				foreach my $field (@fields) {
					#print $innercount," $field: ",$values[$innercount],"<br>";
					my $ff = substr( $values[$innercount], 0, 15 );# $values[$innercount]; #
					#printf("%s:$s",$field,$ff);
					$data->{$field} = $values[$innercount];
					print " ",$field,": ",$ff, "|";
					$innercount++;
				}
				print "<br>";
			}
			print "</pre>";
			if ($table eq "person") {			# Special functions for person insert

				my ($to) = $data->{person_email};				# Check email address
					if ($to =~ m/[^0-9a-zA-Z.\-_@]\./) {
					print "Rejected: $to is a Bad Email<br/>";
					next;
				}

				if (&db_locate($dbh,"person",
					{person_email => $data->{person_email}}) ) {		# Unique Email
					print "Duplicate email: $data->{person_email}<br/>";
					next;
				}

				unless ($data->{person_name}) {
					$data->{person_name} = $data->{person_firstname} . " " . $data->{person_lastname};
				}

				unless ($data->{person_name}) {
					$data->{person_name} = $data->{person_email};
				}

				unless ($data->{person_title}) {
					$data->{person_title} = $data->{person_name};
				}

				unless ($data->{person_password}) {
					$data->{person_password} = &random_password();
				}

				unless ($data->{person_status}) {
					$data->{person_status} = "reg";
				}

			}

									# Automatically generated data

			$data->{$table."_crdate"} = time;
			$data->{$table."_creator"} = $Person->{person_id};


									# Save data to database
			$count++;
			if ($table eq "person") { next unless ($data->{"person_email"}); }

			my $ok = 0;
			$ok = &db_insert($dbh,$query,$table,$data);
	#	while (my ($vx,$vy) = each %$data) { print "$vx = $vy <br>"; }
	#		print "Inserting $data->{person_name} ($data->{person_email}) ($data->{person_organization}) <br>";
			#if ($ok) { print "."; }


									# Send email
		}

		print " <br>";
		print "Data uploaded, $count records added.";
		exit;
	# connect_page_4_subscriptions_1284638307



	exit;


	}


	# --------  Parse YouTube ----------------------------------------
	#
	#  Takes a YouTube URL and creates a post

1;
