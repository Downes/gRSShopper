	sub parse_youtube {
		my ($dbh,$query) = @_;
		my $vars = $query->Vars;
		my $url = $vars->{url};
		if ($ENV{'HTTP_HOST'} =~ /monctonfreepress/) { # Use proxy for Moncton Free Press
	#print "Content-type: text/html\n\n";

			use URI::Escape;
			$safe = uri_escape($url);

			$url = "http://www.downes.ca/cgi-bin/page.cgi?action=proxy&url=$safe";

			#	print "$url.<br>$safe <br>ip";
			#	exit;

		}



		# Get YouTube page
		my $feedrecord = gRSShopper::Feed->new({dbh=>$dbh});
		$feedrecord->{feedstring} = "";
		$feedrecord->{feed_link} = $url;
		&get_url($feedrecord);
		my $tubetext = $feedrecord->{feedstring};
		my $item = ();
	#print "Content-type: text/html\n\n";
	#print $feedrecord->{feedstring};
	#exit;
		#print qq|<form><textarea cols=120 rows=40> $feedrecord->{feedstring}</textarea></form>|;
	#exit;

		if ($tubetext =~ m/<meta(.*?)name="description"(.*?)content="(.*?)"(.*?)>/i) { $vars->{post_description} = $3; }
		if ($tubetext =~ m/<meta(.*?)name="keywords"(.*?)content="(.*?)"(.*?)>/i) { $vars->{post_category} = $3; }
		if ($tubetext =~ m/<meta(.*?)property="og:url"(.*?)content="(.*?)"(.*?)>/i) { $vars->{post_link} = $3; }
		if ($tubetext =~ m/<meta(.*?)property="og:site_name"(.*?)content="(.*?)"(.*?)>/i) { $vars->{keyname_feed} = $3; }
		if ($tubetext =~ m/<meta(.*?)property="og:title"(.*?)content="(.*?)"(.*?)>/i) { $vars->{post_title} = $3; }
		if ($tubetext =~ m/<meta(.*?)name="twitter:image"(.*?)content="(.*?)"(.*?)>/i) { $vars->{file_url} = $3; }
		$vars->{keyname_feed} = "YouTube";

		$vars->{post_genre} = "video";
		$vars->{post_type} = "link";


		my $id = &update_record($dbh,$query,"post",$id);
		&edit_record($dbh,$query,"post",$id);
		exit;


	}


	# -------   Parse CSV -- used by input, requires that you use Text::ParseWords ------

	sub parse_csv {
	    return quotewords(",",0, $_[0]);
	}

	sub parse_csandv {
	    my ($firstbunch,$lastone) = quotewords(" and ",0, $_[0]);
	    my @csvlist = quotewords(",",0, $firstbunch);
	    if ($lastone) { push @csvlist,$lastone; }
	    return @csvlist;

	}


	#
	# -------   Refield ------------------------------------------------------------
	#
	# Rebuilds field_definition.pl from database
	#

	sub refield {

							# Permissions

		return unless (&is_allowed("edit","field"));

		my ($dbh,$query) = @_;
		my $vars = $query->Vars;

															# Create File Header

		my $ds = '$'."base_fields";
		my $output = qq|
			sub set_base_fields {
				\$base_fields = {|;

															# Get Fields Data, and...

		my $sql = qq|SELECT * FROM field|;
		my $sth = $dbh -> prepare($sql);
		$sth -> execute();

															# For each field listed...

		while (my $ref = $sth -> fetchrow_hashref()) {
			my $title = $ref->{field_title};
			my $type = $ref->{field_type};
			my $size = $ref->{field_size};
			next unless ($title && $type && $size);

															# Create field definition text

			$output .= qq|
					$title => {
						title => "$title",
						type => "$type",
						size => "$size"
					},|;
		}

															# Create file footer

		$output .= qq|			};
				return \$base_fields;
				};
				1;|;

															# Print the file

		my $filename = $Site->{st_cgif}."/data/" . $ENV{'SERVER_NAME'} . ".field_definitions.pl";

		open OTPUT,">$filename" or
			&error("$dbh","","","Cannot print fields definition file $filename: $!");
		print OTPUT $output or
			&error("$dbh","","","Cannot print fields definition file $filename: $!");;
		close OTPUT;

															# Return to admin menu

		$vars->{msg} = "New field types table created.";
		&admin_menu($dbh,$query);
	}

	#
	# -------   Refield ------------------------------------------------------------
	#
	# Rebuilds record cache
	#

	sub recache {


		my ($dbh,$query) = @_;
		my $vars = $query->Vars;

		return unless (&is_allowed("edit",$vars->{table})); 			# Get variables
		

		my $format = $vars->{format};							# Set Format
		if ($vars->{type}) { $format = $vars->{type}."_".$format; }
		$format = $vars->{table}."_".$format;
		$vars->{force} = uc($format);

		my $sql = qq|SELECT * FROM $vars->{table}|;				# Select Records
		if ($vars->{type}) { $sql .= " WHERE ".$vars->{table}."_type=?"; }
		my $sth = $dbh -> prepare($sql);
		$sth -> execute($vars->{type});
	# my $count=0;
		print "Record search: $sql <br /> Recaching $vars->{table} : $vars->{type} : $vars->{format} ";
		while (my $ref = $sth -> fetchrow_hashref()) {
			my $idfield = $vars->{table}."_id";

			my $record_text = &format_record($dbh,
				$query,
				$vars->{table},
				$format,
				$ref);

	#		print $record_text;
	# $count++; last if ($count > 20);
			print "$ref->{$idfield} - ";
		}

		exit;

	}



	# -------   Admin Menu: topics ---------------------------------------------

	sub admin_topics {

		return unless (&is_viewable("admin","topics")); 		# Permissions

		return qq|<div class="menubox">

			<h4>Build Content Types</h4>
			<p>
			<ul>
			<li><a href="?action=refield">Rebuild Fields List</a></li>
			</ul>

			<h4>Matches</h4>
			<p><b>Caution: Reindexing can take a long time</b><ul>
			<li> <a href="?action=reindex_topics">Reindex Topics</a> (Caution - this could take a long time)
			<li><a href="?action=reindex&db=author">Reindex Authors</a></li>
			<li><a href="?action=reindex&db=journal">Reindex Journals</a></li>
			</ul></p>

		</div>|;

	}




	# -------   News Rollup ----------------------------------------------------------
	#
	#	Gives a quick preview of posts slated for upcoming newsletters
	#

	sub admin_list_records {

		my ($table) = @_;

		my ($metadata,$output) = &list_records($table);

		# print output in Admin frame

		&admin_frame($dbh,$query,"List ".$table."s",$output);
	}



	# -------  Autopost------------------------------------------------------

	sub autopost {

		my ($dbh,$query) = @_;
		my $vars = $query->Vars;
		exit unless ($Person->{person_status} eq "admin");
		my $postid = &auto_post($dbh,$query,$vars->{id});

		print "Autopost $postid";
		exit;

	}

	# -------  Autopost------------------------------------------------------

	sub postedit {

		my ($dbh,$query) = @_;
		my $vars = $query->Vars;
		exit unless ($Person->{person_status} eq "admin");

		my $postid = &auto_post($dbh,$query,$vars->{id});
		my $posttext = &edit_record($dbh,$query,"post",$postid,1);

	 	print $posttext;
		exit;

	}

	# -------   Remote Comment ----------------------------------------------------

	sub rcomment {

		&record_sanitize_input($vars);
		my $refer = $ENV{HTTP_REFERER};	
		$vars->{link} = $refer;
		while (my ($vkey,$vval) = each %$vars) {
			$vars->{$vkey} =~ s/\0/;/g;	# Replace 'multi' delimiter with semi-colon
		}

		printf(qq|A <a href="%s">remote website</a> has sent a 
			comment for you to submit:<br><br><table>
			<form method="post" action="admin.cgi">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<input type="hidden" name="action" value="add_rcomment">|,
			$refer);
		
		foreach my $vkey (qw(title description link author feed)) {
			$vars->{$vkey} =~ s/\0/,/g;	# Replace 'multi' delimiter with semi-colon
			printf(qq|<tr><td>%s</td><td>%s
			<input type="hidden" name="%s" value="%s">
			</td></tr>|,$vkey,$vars->{$vkey},$vkey,$vars->{$vkey});
		}

		printf(qq|</table><br><br>Do you wish to submit this comment? 
			<input type="submit" value="Submit Comment"><br></form>|);

		exit;
	}

	sub add_rcomment {

		&record_sanitize_input($vars);
		my $refer = $ENV{HTTP_REFERER};	
		while (my ($vkey,$vval) = each %$vars) {
			$vars->{$vkey} =~ s/\0/;/g;	# Replace 'multi' delimiter with semi-colon
		}

		die "Not allowwed to comment" unless (&is_allowed("create",$table));
		# Do some stuff
		my $refer = $vars->{link};		
		my $table="post";
		my $post = {
			post_type => 'link',
			post_link => $refer,
			post_description => $vars->{description},
			post_title => $vars->{title},
			post_author => $vars->{author},
			post_feed => $vars->{feed}, 
			post_id => "new",
			post_pub_date => &cal_date(time),
			post_crdate => time,	
			post_creator => $Person->{person_id},		
		};

		# Uniqueness Constraints
		my $l;
		if (($l = &db_locate($dbh,"post",{post_link => $post->{post_link}})) ||
		    ($l = &db_locate($dbh,"post",{post_title => $post->{post_title}})) ) {

			my $url = $Site->{st_url} . "post/" . $l;	
			printf(qq|<p>Duplicate Entry: <a href="%s">Post %s</a></p>|,$url,$l);
			exit;
		}		

		# Clean up
		post->{post_description} =~ s/href=('|&#39;|&apos;)(.*?)"/href="$2"/ig; #'

		# Submit and print record
		my $id_number = &db_insert($dbh,$query,$table,$post) || die "Couldn't inset post";
		&rcomment_keylist_update($id_number,"author",$post->{post_author}) || die "Couldn't associate author";
		&rcomment_keylist_update($id_number,"feed",$post->{post_feed}) || die "Couldn't associate author";		
		print_record("post",$id_number,"html",$Site->{context});

		# Send WebMention

		my $content = get($post->{post_link});
		die "Source page is unreachable" unless ($content);
		my $endpoint = &find_webmention_endpoint($content);
		if ($endpoint) {
			&send_webmention($endpoint,$post->{post_link},$Site->{st_url}."post/".$id_number);
		}

		print "Content-type: text/html\n";
		print "Location: ".$refer."#$id_number!\n\n";
		exit;

	}






	

	# -------   Remote Comment Author and Feed -----------------------------------------

	sub rcomment_keylist_update {

		my ($id,$key,$value) = @_;
		return unless ($id & $key & $value);

		# Split list of input $value by ;
		$value =~ s/&apos;|&#39;/'/g;   # ' Remove apostraphe escaping, just for the split
		my @keynamelist = split /;/,$value;

		# For each member of the list...
		foreach my $keyname (@keynamelist) {

		$keyname =~ s/'/&#39;/g;   # Replace apostraphe escaping

			# Trim leading, trailing white spaces
			$keyname =~ s/^ | $//g;

			# Are we looking for _name, _title ...?
			my $keyfield = &get_key_namefield($key);

			# can we find a record with that name or title?
			my $keyrecord = &db_get_record($dbh,$key,{$keyfield=>$keyname});

			# Record wasn't found, create a new record, eg., a new 'author'
			unless ($keyrecord) {

				# Initialize values
				$keyrecord = {
					$key."_creator"=>$Person->{person_id},
					$key."_crdate"=>time,
					$keyfield=>$keyname
				};

				# Save the values and obtain new record id
				$keyrecord->{$key."_id"} = &db_insert($dbh,$query,$key,$keyrecord);
			}

			# Error unless we have a new record id
			print &error() unless $keyrecord->{$key."_id"};

			# Save Graph Data
			my $typeval;
			if ($key eq "author") { $tytpeval = "Author wrote link";}
			if ($key eq "feed") { $tytpeval = "Link on feed";}			
			my $graphid = &db_insert($dbh,$query,"graph",{
				graph_tableone=>$key, graph_idone=>$keyrecord->{$key."_id"}, graph_urlone=>$keyrecord->{$key."_url"},
				graph_tabletwo=>"post", graph_idtwo=>$id, graph_urltwo=>"",
				graph_creator=>$Person->{person_id}, graph_crdate=>time, graph_type=>"Comment", graph_typeval=>"$typeval"});
			die "Error creating graph entry for $key $value" unless ($graphid > 0);
		}

		return 1;

	}

	# -------   Update Record ------------------------------------------------------                                                   UPDATE

	sub update_record {

		my ($dbh,$query,$table,$id_number) = @_;
		my $vars = $query->Vars;

print "Content-type: text/html\n\n";
print "Fuck off";
exit;

		# print "Content-type: text/html; charset=utf-8\n\n";
		#print "Updating a $table id number $id_number <br>";
		#while (my($vx,$vy) = each %$vars) { print "$vx = $vy <br/>"; }

							# Validate Input

		&error("nil",$query,"","Database not ready") unless ($dbh);
		&error($dbh,$query,"","Table not specified") unless ($table);
		&error($dbh,$query,"","Fishy ID") unless ($id);

								# Permissions

		my $id_field = $table."_id";
		my $record = &db_get_record($dbh,$table,{$id_field=>$id});
		if ($id =~ /new/i) {	return unless (&is_allowed("create",$table)); }
		else { return unless (&is_allowed("edit",$table,$record)); }





							# Clean Input
							# Fix mismatched href quotes

		$vars->{$table."_description"} =~ s/href=('|&#39;|&apos;)(.*?)"/href="$2"/ig; #'





							# Fix relative links
							# (eg. created by TinyMCE)
		if ($vars->{$table."_description"} =~ /\.\.\//) {
			$vars->{$table."_description"} =~ s/\.\.\//$Site->{st_url}/;
		}
		if ($vars->{$table."_content"} =~ /\.\.\//) {
			$vars->{$table."_content"} =~ s/\.\.\//$Site->{st_url}/;
		}
							# Require URL in link
		if ($vars->{post_type} eq "link") {
			unless ($vars->{$table."_link"} =~ /http/i) {
		#		&error($dbh,$query,"","Link must contain 'http'");
			}
		}

		# Remove line feeds in _data
		$vars->{$table."_data"} =~ s/\n//g;
		$vars->{$table."_data"} =~ s/\r//g;
							# Table-specific functions
							# Capitalize titles in Post
		if ($table eq "post") {
			$vars->{$table."_title"} = &capitalize($vars->{$table."_title"});
			$vars->{$table."_name"} = &capitalize($vars->{$table."_name"});
			unless ($vars->{$table."_pub_date"}) {
				$vars->{$table."_pub_date"} = &cal_date(time); }

		} elsif ($table eq "person") {

			if ($vars->{$table."_password"}) {		# Create a Salted Password
				$vars->{$table."_password"} = &encryptingPsw($vars->{person_password}, 4);

			}

		} elsif ($table eq "optlist") {				# Autogenerate Optlist Titles
			$vars->{optlist_table} ||= "table";
			$vars->{optlist_field} ||= "field";
			$vars->{optlist_title} = $vars->{optlist_table} ."_".$vars->{optlist_field};
		} elsif ($table eq "feed") {
			$vars->{msg} .= "YouTube feed detected. ";
			if (($vars->{feed_link} =~ m|youtube\.com/channel/(.*?)$|i) ||
				(($vars->{feed_html} =~ m|youtube\.com/channel/(.*?)$|i) && ($vars->{feed_link} eq ""))) {

				$vars->{feed_link} = qq|http://www.youtube.com/feeds/videos.xml?channel_id=$1|;
				$vars->{msg} .= "Channel $1 converted to RSS URL<p>";
				# https://www.youtube.com/channel/UCvInFYiyeAJOGEjhqJnyaMA
			} elsif ($vars->{feed_link} =~ m|youtube\.com/user/(.*?)$|i) {
				$vars->{feed_link} = qq|http://www.youtube.com/feeds/videos.xml?user=$1|;
				$vars->{msg} .= "User $1 converted to RSS URL <p>";
			}
		}



		&record_convert_dates($table,$vars);



							# Kill spartquotes
		while (my ($vkey,$vval) = each %$vars) {
			$vars->{$vkey} =~ s/\0/,/g;	# Replace 'multi' delimiter with comma
			$vars->{$vkey} =~ s/#!//g;				# No programs!

		}


		if ($id_number eq "new") {			# Uniqueness Constraints
			my $l = "";
			my $name_or_title = &get_key_namefield($vars->{insert_table});
			if (($l = &db_locate($dbh,"post",{post_link => $vars->{post_link}}))        ||
			    ($l = &db_locate($dbh,"feed",{feed_link => $vars->{feed_link}})) 	 ||
			    ($l = &db_locate($dbh,$table,{$name_or_title => $vars->{$name_or_title}})) 	) {
				$vars->{msg} .= qq|<p>Duplicate Entry: <a href="$Site->{st_cgi}admin.cgi?$table=$l">$table $l</a></p>
				<p>If you would like to edit the existing $table then please <a href="$Site->{st_cgi}admin.cgi?$table=$l&action=edit">Click here</a></p>|;
				return "duplicate";
			}
		}

								# Submit and verify record
		$id_number = &form_update_submit_data($dbh,$query,$table,$id_number);

		my $new_record=&db_get_record($dbh,$table,{$table.+"_id"=>$id_number});
		&error($dbh,"","","New $table record not created properly.") unless ($new_record);
		$new_record->{type} = $table;

		#   Submissions will include info about authors, feeds, etc.
		#   Values for these other records are submitted in $vars and always have the prefix 'keyname_'
		#   For example, a field named 'keyname_author' will refer to the name of an author in the 'author' table
		#   The function produces a record in the graph table
		#   It will also create a new record in the other table, if necessary

		&record_graph($dbh,$vars,$table,$new_record);					# Save Graph Records







							# Identify, Save and Associate File

		my $file;
		if ($query->param("file_name")) { $file = &upload_file($query); }		# Uploaded File
		elsif ($vars->{file_url}) { $file = &upload_url($vars->{file_url}); }		# File from URL

		# Create File Record
		if ($file->{fullfilename}) {
			my $file_record = &save_file($file);
			$file_record->{type} = "file";
			my $graph_typeval = "";
			if ($file_record->{file_type} eq "Illustration") { $graph_typeval = $vars->{file_align} . "/" . $vars->{file_width}; }
			else { $graph_typeval = $mime; }
			&save_graph($file_record->{file_type},$new_record,$file_record,$graph_typeval);



		# Make Icon (from smallest uploaded image thus far)

			if ($file_record->{file_type} eq "Illustration") {

				my $icon_image = &item_images($table,$new_record->{$table."_id"},"smallest");

				my $filename = $icon_image->{file_title};
				my $filedir = $Site->{st_urlf}."files/images/";
				my $icondir = $Site->{st_urlf}."files/icons/";
				my $iconname = $table."_".$new_record->{$table."_id"}.".jpg";

				my $tmb = &make_thumbnail($filedir,$filename,$icondir,$iconname);
			}
		}





							# Insert Topic Matches
	#	if (($table eq "post") || ($table eq "link")) {
	#		my $matchstr = $vars->{$fields->{title}} . $vars->{$fields->{description}};
	#		&insert_topic_matches($dbh,$query,$matchstr,$table,$id_number);
	#		my $matchstr = $vars->{$author};

							# Topic Matches

	#		my ($matchmsgstr,$matchmsgids) =
	#			&insert_matches($dbh,$query,$vars->{$title}.$vars->{$description},
	#				$table,$id_number,"topic","");
	#		$vars->{$table."_authorstr"} = $matchmsgstr;
	#		$vars->{$table."_authorids"} = $matchmsgids;

							# Author Matches

	#		my ($matchmsgstr,$matchmsgids) =
	#			&insert_matches($dbh,$query,$vars->{$author},$table,$id_number,"author","");
	#		$vars->{$table."_authorstr"} = $matchmsgstr;
	#		$vars->{$table."_authorids"} = $matchmsgids;


							# Journal Matches

	#		my ($matchmsgstr,$matchmsgids) =
	#			&insert_matches($dbh,$query,$vars->{$journal},$table,$id_number,"journal","");
	#		$vars->{$table."_journalstr"} = $matchmsgstr;
	#		$vars->{$table."_journalids"} = $matchmsgids;


							# Update the input item with matches

	#		$id_number = &db_update($dbh,$table, $vars, $id_number);
	#	}




							# If Topic, Reindex Topic

		if (($table eq "topic") && ($vars->{topic_reindex} eq "yes")) {

			&reindex_topics($dbh,$query,$id_number);
			$vars->{msg} .= "Topic number $id_number successfully reindexed.<br/>";
		}

							# If publish selected, publish

		if ($vars->{post_facebook} || $vars->{post_twitter}) {
			$vars->{msg} .= &publish_post($dbh,$table,$id_number);
		}



	#	print "Content-type: text/html; charset=utf-8\n\n";

		$vars->{updated_table} = $table;
		$vars->{updated_title} = $vars->{$table."_title"};



	    return $id_number;


	}

	

	# -------   Edit Record --------------------------------------------------------
	#
	# Administrator's general record editing function
	#

	sub edit_record {

		# Get variables

		my ($dbh,$query,$table,$id_number,$viewer) = @_;
		$vars->{force} = "yes";	# Never use cache on edit

		# print "Content-type: text/html; charset=utf-8\n\n";


		# Define Form Contents

		# provide styling; this is temporary before I move this to a style sheet
		my $form_text = qq|<style>

		label {
  			padding: 12px 12px 0px 12px;
  			margin:0;
  			display: inline-block;
  			color:green;
		}

		p.info {
  			padding: 0px 12px 0px 12px;
  			margin:0;
  			display: block;
  			color:black;

		}

		.graph-list-element {
			font-family: Arial, Helvetica, sans-serif;
			font-size: 0.875em; /* 14px/16=0.875em */
			margin-left:1em;
		}

		.text-input {
			z-index: 1;
		}

		.text-input-form {
			font-family: Arial, Helvetica, sans-serif;
			font-size: 0.875em; /* 14px/16=0.875em */
			margin-left:12px;
			max-width: 60em;
		}

		.text-input-field {
			margin:0;
			padding:10;
			width: 40%;
			height: 1.6em;
			line-height: 1.8em;
		}

		.text-input-textarea {
			
		   max-width:90%; 
		   line-height:1.8em;"
		}

		.keylist-input {

		}
		.keylist-input-form {
			font-family: Arial, Helvetica, sans-serif;
			font-size: 0.875em; /* 14px/16=0.875em */
			margin-left:10px;
		}

		.keylist-input-field {
			margin:0;
			padding:10;
			width: 40%;
			height: 1.6em;
			line-height: 1.6em;
		}

		.keylist-input-button {
			margin:0;
			padding:0;
			padding-left:5px;padding-right:5px;
			height: 1.6em;
			line-height: 1.6em;
		}

		.optlist-input {

		}

		.action {
			padding-top;padding-bottom:0;
		}

		.optlist-input-form {
			font-family: Arial, Helvetica, sans-serif;
			font-size: 0.875em; /* 14px/16=0.875em */
			margin-left:10px;
		}

		.harvest-button {
			height: 1.6em;
			line-height: 1.6em;
			margin:0;
			margin-right:5px;
			padding:0;
			padding-left:5px;padding-right:5px;
		}

		.harvest-select {
			height: 1.9em;
			line-height: 1.9em;
			font-family: Arial, Helvetica, sans-serif;
			font-size: 0.875em; /* 14px/16=0.875em */
			margin:0;
			padding:0;
			margin-top:8px;
			margin-left:10px;
		}

		.harvest-option {
			height: 1.9em;
			line-height: 1.9em;
			font-family: Arial, Helvetica, sans-serif;
			font-size: 0.875em; /* 14px/16=0.875em */
			margin:0;
			margin-left:10px;
			padding:0;
		}

		.row button {
			margin:0;
			margin-right:3px;
			padding:0;
			padding-left:5px;padding-right:5px;
			height: 1.6em;
			line-height: 1.6em;
		}

		.editor-selected {
			height: 1.6em;
			line-height: 1.6em;
			margin:0;
			margin-right:5px;
			padding:0;
			padding-left:5px;padding-right:5px;
			color:red;
		}

		.editor-unselected {
			height: 1.6em;
			line-height: 1.6em;
			margin:0;
			margin-right:5px;
			padding:0;
			padding-left:5px;padding-right:5px;
			color:blue;
		}

	</style>|;

	$form_text .= &main_window($tabs,"Edit",$table,$id_number,$vars);
		#&form_editor($dbh,$query,$table,$id_number);

		$form_text =~ s/&#39;/'/mig;
	  $form_text = qq|<script src="https://www.downes.ca/assets/js/jquery.min.js"></script>
	       <script src="https://www.downes.ca/assets/js/grsshopper_admin.js">|.$form_text;
		if ($viewer) { return $form_text; }							# Send form text to viewer, or
		else { &admin_frame($dbh,$query,"Edit $table",$form_text); } 				# Print Output


	}






	# -------  Approve Feed --------------------------------------------------------
	#
	#   Removes a graph record

	sub remove_key {

		my ($dbh,$query,$table,$id) = @_;
		my $vars = $query->Vars;
		unless ($vars->{remove}) {
			$vars->{msg} .= "No remove instructions";
			return;
		}
		my ($rtab,$rid) = split /\//,$vars->{remove};
		my $sql = "DELETE FROM graph WHERE graph_tableone=? AND graph_idone = ? AND graph_tabletwo =? AND graph_idtwo = ?";
		my $sth = $dbh->prepare($sql);
	    	$sth->execute($table,$id,$rtab,$rid);
		my $sql = "DELETE FROM graph WHERE graph_tableone=? AND graph_idone = ? AND graph_tabletwo =? AND graph_idtwo = ?";
		my $sth = $dbh->prepare($sql);
	    	$sth->execute($rtab,$rid,$table,$id);
		return;

	}


	#--------------------------------------------------------
	#
	#	Editor Functions
	#
	#--------------------------------------------------------




	# -------  Approve a Record -----------------------------------------------------

	# Change record_status to "Published"
	# This is used to filter displays

	sub record_approve {

		my ($dbh,$query,$table,$id) = @_;
		my $vars = $query->Vars;

		return unless (&is_allowed("approve",$table));
		my $readername = $Person->{person_name} || $Person->{person_title};

		my $approval;
		if ($table eq "feed") {	$approval = "A"; } else { $approval = "Published"; }
		&db_update($dbh,$table,{$table."_status"=>$approval},$id);
		&db_cache_remove($dbh,$table,$id);



									# Return message
		$vars->{msg} .= qq|New $table ($id) approved by $readername |.
			qq| View at: <a href="$Site->{st_url}$table/$id">$Site->{st_url}$table/$id</a></p>|;
		$vars->{api} = 	"Approved $wp->{post_title}";		# Needs to be fixed
		$vars->{title} = qq|$table ($id) approved by $readername|;


		&send_notifications($dbh,$vars,$table,$vars->{title},$vars->{msg});
		&report_action($vars->{title});
		exit;

	}

	# -------  Reject or a Record -----------------------------------------------------

	# Change record_status to "Retired"
	# This is used to filter displays

	sub record_retire {

		my ($dbh,$query,$table,$id) = @_;
		my $vars = $query->Vars;

		return unless (&is_allowed("approve","feed"));
		my $readername = $Person->{person_name} || $Person->{person_title};

		my $approval;
		if ($table eq "feed") {	$retired = "R"; } else { $retired = "Retired"; }

		&db_update($dbh,$table,{$table."_status"=>$retured},$id);
		&db_cache_remove($dbh,$table,$id);



									# Return message
		$vars->{msg} .= qq|New $table ($id) rejected by $readername |.
			qq| View at: <a href="$Site->{st_url}$table/$id">$Site->{st_url}$table/$id</a></p>|;
		$vars->{api} = 	"Rejected $wp->{post_title}";		# Needs to be fixed
		$vars->{title} = qq|$table ($id) rejected by $readername|;


		&send_notifications($dbh,$vars,$table,$vars->{title},$vars->{msg});
		&report_action($vars->{title});
		exit;

	}

	# -------  Report Action -----------------------------------------------------

	# Routes the response to an action depending on where it came from
	# so we can use the same functions to manage commands from API, email and editor
	# Eventually I might just combine this with admin_frame()

	sub report_action {

		my ($action,$apiresponse) = @_;


		if ($vars->{from} eq "email") {
			&admin_frame($dbh,$query,$action,$vars->{msg});
			exit;
		} elsif ($vars->{from} eq "api") {
			print $vars->{api};
			exit;
		} else {
			&admin_list_records($table);
			exit;
		}


	}


	# -------  Count  --------------------------------------------------------

	# Counts the number of items in feeds, journals, whatever
	# If feed specified, returns the value, otherwise, simply updates DB
	# ie., counting X in Y

	sub count_feed {
	#print "Content-type: text/html; charset=utf-8\n\n";
		my ($dbh,$query) = @_;

		my $X = $vars->{count};
		my $Y = $vars->{in};

		my $idfield = $X."_id";
		my $id = $vars->{$idfield};
		my $tracefield = $Y."_".$X."id";
		my $countfield = $X."_".$Y."s";			# eg. feed_links

		if ($id) {
			my $count = &db_count($dbh,$Y,{$idfield => $id});
			return $count;
		} else {
			my $stmt = qq|SELECT $idfield from $X|;
			my $Xs = $dbh->selectcol_arrayref($stmt);
			foreach my $xitem (@$Xs) {
				my $count = &db_count($dbh,$Y,"WHERE $tracefield = '$xitem'");
				&db_update($dbh,$X,{$countfield => $count},$xitem);
			}
			$vars->{msg} .= "Number of $X counted for each $Y and database updated.";
		}

		&admin_menu($dbh,$query);
	}

	# --------------------------------------------------------------------------------------
	#
	#          API requests
	#
	# -------------------------------------------------------------------------------------

	# Access API

	sub access_api {

		my ($dbh,$query) = @_;
		my $vars = $query->Vars;

	print "Accessing API <p>";

	  my $server_endpoint = $vars->{url};
	  my $postdata = $vars->{postdata};
	  my $message;  # from remote server

	  if ($vars->{method} eq "get") {

			use LWP::Simple;
			$message = get($server_endpoint);
			unless (defined $message) {
				 print "HTTP GET Error!";
				 return;
			}


		} else {

	  	use LWP::UserAgent;

	  	my $ua = LWP::UserAgent->new;



	    # set custom HTTP request header fields
	    my $req = HTTP::Request->new(POST => $server_endpoint);
	    $req->header('content-type' => 'application/json');

	    # add POST data to HTTP request body
	    $req->content($postdata);

	    my $resp = $ua->request($req);
	    unless ($resp->is_success) {

	      print "HTTP POST error code: ", $resp->code, "\n";
	      print "HTTP POST error message: ", $resp->message, "\n";
				return;
	    }

			$message = $resp->decoded_content;

	  }

			#print "Received reply: $message\n";
			use JSON::Parse 'parse_json';
			my $response_data = parse_json($message);
			#print $response_data->{entries};
			foreach my $entry (@{$response_data->{entries}}) {
				print qq|
					<b><a href="$entry->{course_url}">$entry->{course_title}</a></b><br>$entry->{course_description}<br><br>
				|;

				#while (my ($x,$y) = each %$entry) {	print "$x = $y <br>";	}
			}

			print qq|<form><textarea cols=60 rows=20>$message</textarea></form>|;
			#print $response_data;

	}

1;
