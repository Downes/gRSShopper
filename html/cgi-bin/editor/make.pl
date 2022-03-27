
#           MAKE FUNCTIONS
#-------------------------------------------------------------------------------
	# -------  Make Page Data -------------------------------------------------------
	#
	#
	#   Given an input text reference $text_ptr and table data hash $reference,
	#   will replace instances of [*table_field*] with $table->{field}
	#   in $$text_ptr

sub make_data_elements {

	my ($text_ptr,$table,$format) = @_;

	my @data_elements = ();
	while ($$text_ptr =~ /\[\*(.*?)\*\]/) {

		my $de = $1; push @data_elements,$de;
		$$text_ptr =~ s/\[\*(.*?)\*\]/BEGDE $de ENDDE/si;
	}

	foreach my $data_element (@data_elements) {

		unless (defined $table->{$data_element}) { $table->{$data_element} = ""; }
		if ($format =~ /JS|JSON/i) { &esc_for_javascript(\$table->{$data_element}); } 	# JS/JSON escape
		$$text_ptr =~ s/BEGDE $data_element ENDDE/$table->{$data_element}/mig;
	
	}

}

	# -------  Make Page Data -------------------------------------------------------
	#
	# Lets you send some link data to a page using page variables
	# eg. ... &pagedata=post,12,rdf
	# Separate values with commas. make_pagedata() will insert them into
	# appropriately numbered fields. Eg. <pagedata 1> for the first,
	# <pagedata 2> for the second, etc.
	# Typically, usage is: pagedata=table,id_number,format
	# Receives text pointer and query as input; acts directly on text
	# Note that this will not work on static versions of pages
sub make_pagedata {

	my ($query,$input,$title) = @_;

	return unless (defined $input);
	my $vars = (); if (ref $query eq "CGI") { $vars = $query->Vars; }
	return unless (defined $vars->{pagedata});
	my @insertdata = split ",",$vars->{pagedata};

	my $count;
	while ($$input =~ /<pagedata (.*?)>/mig) {

		my $autotext = $1;
		$count++; last if ($count > 100);			# Prevent infinite loop
		my $replace = "";

		my $replacenumber = $autotext-1;
		next unless ($replacenumber >= 0);
		$replace = $insertdata[$replacenumber];

		$$input =~ s/<pagedata $autotext>/$replace/;
	}

									# Write Page Title
	$$input =~ s/\Q[*page_title*]\E/$$title/g;
	$$input =~ s/\Q<page_title>\E/$$title/g;


}

	# -------  Make Login Info --------------------------------------------------------
	#
	# Looks at the Person object and creates a personalized set of
	# login options for that user
	# Receives text pointer as input; acts directly on text
sub make_login_info {

	my ($dbh,$query,$text_ptr,$table,$id) = @_;
	return unless (defined $text_ptr);

  #	if ($diag eq "on") { print "Make Login Info ($table $text_ptr)\n"; }
    	my $vars = ();
    	if (ref $query eq "CGI") { $vars = $query->Vars; }

  #	my $refer = $Site->{script} . "?" . $table . "=" . $id . "#comment";
  #	my $logout_link = $Site->{st_cgi} . "login.cgi?action=Logout&refer=".$refer;
  #	my $login_link = $Site->{st_cgi} . "login.cgi?refer=".$refer;
  #	my $options_link = $Site->{st_cgi} . "login.cgi?action=Options&refer=".$refer;

  #	my $name = $Person->{person_name} || $Person->{person_id};

  #	my $replace = "";
  #	if (($Person->{person_id} eq 2) ||
  #	    ($Person->{person_id} eq "")) {

  #		$replace = qq|
  #			You are not logged in.
  #			[<a href="$login_link">Login</a>]
  #		|;

  #	} else {
  #		$replace = qq|
  #			You are logged on as $name.
  #			[<a href="$logout_link">Logout</a>]
  #			[<a href="$options_link">Options</a>]
  #		|;
  #	}
  #

	my $replace = qq|<script language="Javascript">comment_login_box();</script>|;
	$$text_ptr =~ s/<LOGIN_INFO>/$replace/sig;

}

	# -------  Make Site Info --------------------------------------------------------
	#
	# Puts site variables into pages
	# Site variables are found in the site data file in cgi-bin/data
	# For security reasons, only st_ (site) and em_ (email) variables are filled
sub make_site_info {

	my ($text_ptr) = @_;
	return unless (defined $text_ptr);

	while (my($sx,$sy) = each %$Site) {
		next unless ($sx =~ /^(em|st)/);
		$$text_ptr =~ s/<$sx>/$sy/mig;
		$$text_ptr =~ s/&lt;$sx&gt;/$sy/mig;
	}

}
sub make_site_hits_info {

	my ($text_ptr) = @_;
	return unless (defined $text_ptr);

	while ($$text_ptr =~ /<site_hits>/sig) {

						# Site Page Hit Totals
		my $post_today; my $page_today; my $event_today;
		my $post_total; my $page_total; my $event_total;
		print "Content-type: text/html\n\n";

		# Posts - today
		my $sth = $dbh->prepare("SELECT SUM(post_hits) FROM post");
		$sth->execute();
		my ($post_today) = $sth->fetchrow_array();


		# Posts - total
		my $sth = $dbh->prepare("SELECT SUM(post_total) FROM post");
		$sth->execute();
		my ($post_total) = $sth->fetchrow_array();

		my $site_hits = "Posts viewed: $post_today today, $post_total all time.<br>";

		$$text_ptr =~ s/<site_hits>/$site_hits/;
	}

}

	# -------  Make Langstring -------------------------------------------------------------
	#
	#  takes <langstring text> and produces text in the appropriate language, as 
	#  defined by the current $Site language. see sub printlang()
	#
sub make_langstring {

	my ($text_ptr,$table,$id,$filldata) = @_;

	my $count=0;
	while ($$text_ptr =~ /<langstring(.*?)>/sig) {
		my $parse = $1;	my $autotext = "<langstring".$parse.">";
		$parse =~ s/^\s*//;  # Remove leading spaces
		$count++; last if ($count > 100);			# Prevent infinite loop

		# Generate the replace text
		my $replace  = &printlang($parse);
		$$text_ptr =~ s/$autotext/$replace/;
	}




}



	# -------  Make Hits -------------------------------------------------------------
	#
	#  Fill values for today and total number of hits recorded by the hit counter
	#  Replaces <hits> command
sub make_hits {

	my ($text_ptr,$table,$id,$filldata) = @_;

	return unless (defined $table eq "post");			# Hits only for posts
	return unless (defined $text_ptr);

	my $count=0;

	while ($$text_ptr =~ /<hits>/sig) {

		my $autotext = $1;
		$count++; last if ($count > 100);			# Prevent infinite loop

		my $replace = "";
		my $parse = $autotext;

		my $hits = $filldata->{$table."_hits"};
		my $total = $filldata->{$table."_total"};

		$$text_ptr =~ s/<hits>/$hits\/$total/;
	}


}

# -------  Make Grid -------------------------------------------------------------
#
#  Get values for two tables and make a grid to create a graph of the tables
#  
sub make_grid {
	my ($input) = @_;

	
	my $count=0;
	while ($$input =~ /<grid(.*?)>/sig) {
	
		my $autotext = "<grid".$1.">";
		$count++; last if ($count > 100);			# Prevent infinite loop

		my $autocontent = $1;my $nexttext = "";

		my $script = {};
		&parse_keystring($script,$autocontent);
#print "$autocontent -- ".$script->{t1}." -- ". $script->{t2};
#		my $replace = "Grid";
		my $replace = &graph_grid($script->{t1},$script->{t2});


		$$input =~ s/$autotext/$replace/;
	}

}



# -------  Make Buttons -------------------------------------------------------------
#
#  Fill values for today and total number of hits recorded by the hit counter
#  Replaces <hits> command
sub make_status_buttons {

	my ($text_ptr,$table,$id,$filldata) = @_;


	return unless (defined $text_ptr);

	my $count=0;
	# Values correspond to names from font-awesome
	# At some future point this could be input from a db
	my $icons = {
			read => [ 'far fa-eye-slash', 'fa fa-eye', ],
  		star => [ 'far fa-star', 'fas fa-star'],
	};

	while ($$text_ptr =~ /<statusbutton (.*?)>/sig) {
		my $autotext = $1;

		my $replace = "";
		$count++; last if ($count > 100);			# Prevent infinite loop
    unless ($filldata->{$table."_".$autotext}) { $filldata->{$table."_".$autotext} = 0; }

    my $i = $icons->{$autotext}->[$filldata->{$table."_".$autotext}];
    next unless $i;

    $replace = qq|
    <script>
       var url = "|.$Site->{st_cgi}.qq|api.cgi";
       jQuery("#$autotext$id").click(function() {
       		var stat = ["$icons->{$autotext}->[0]","$icons->{$autotext}->[1]"];
       		var cla = jQuery(this).find("i").attr("class");
			 		if (cla == stat[0]) { jQuery(this).find("i").removeClass(stat[0]).addClass(stat[1]); cla=1;}
			 		else if (cla == stat[1])  { jQuery(this).find("i").removeClass(stat[1]).addClass(stat[0]); cla=0; }
          else { jQuery(this).find("i").addClass(stat[0]); cla=0; }
          var col_name = "$table"+"_"+"$autotext";
          parent.submit_function(url,'$table','$id',col_name,cla,"text");
       });
    </script>
    <span id='|.$table.qq|_$autotext'><button id="$autotext$id" style="height:2em;"><i class="$i"></i></button>
          <span id='|.$table.qq|_|.$autotext.qq|_result'></span></span>|;
		$$text_ptr =~ s/<statusbutton $autotext>/$replace/;
	}


}

# -------  Make Badges -------------------------------------------------------------
#

sub make_badges {

	my ($text_ptr,$table,$id,$filldata) = @_;


	#&admin_only();
#print "Content-type: text/html\n\n";
	while ($$text_ptr =~ /<badges>/sig) {
		my $autotext = $1;

		my $replace = "";
		$count++; last if ($count > 100);			# Prevent infinite loop
    unless ($filldata->{$table."_".$autotext}) { $filldata->{$table."_".$autotext} = 0; }

    my $i = $icons->{$autotext}->[$filldata->{$table."_".$autotext}];
  #  next unless $i;

    if ($Person->{person_status} eq "admin") { 			# Admin Only
    $replace = qq|
      <script>
		    \$(document).ready(function(){

		    \$("#badgeButton").click(function(){
		        \$("#award-badge").toggle();
		    });

			 	\$("#award-badge-form").submit( function(e) {
					 e.preventDefault();
					 var url = "$Site->{st_cgi}api.cgi?cmd=award_badge&"
						 + "badge_table=" + \$("input[name=badge_table]").val()
						 + "&badge_table_id=" + \$("input[name=badge_table_id]").val()
						  + "&badge_id=" + \$("#badge_id").val();
					 alert(url);
					 \$("#badge-result").load(url, function(response, status, xhr) {
							if (status == "error") {
									var msg = "Sorry but there was an error: ";
									alert(msg + xhr.status + " " + xhr.statusText);
								}
							});
					 return 0;
					});
				});
			</script>
			<button id="badgeButton" style="height:2em;"><i class="fa fa-award"></i></button>
			<div id="award-badge" style="display:none;border:solid black 0.5px;padding:0.2em;">
				<p>Award a Badge</p>
				<p><form id="award-badge-form">
				Select a badge:
				<input type="hidden" name="badge_table" value="$table">
				<input type="hidden" name="badge_table_id" value="[*|.$table.qq|_id*]">|.
				&get_options($dbh,"badge",$vars->{feed},&printlang("All Badges")).qq|
				<input type="submit" value="Award">
				</form>
				<div id="badge-result"></div>
			</div>
			|;
		} else {
	     $replace = "";
	  }

		$$text_ptr =~ s/<badges>/$replace/;
	}

}

sub get_options {

	my ($dbh,$table,$opted,$blank,$size,$width) = @_;
	return "Table not specified in get_options" unless ($table);
	$opted ||= "none";
	my $titfield = $table."_title";
	my $title = &printlang(ucfirst($table));
	my $idfield = $table."_id";
	$size ||= 15;
	$width ||= 15;
	my $output = "";
	if ($table eq "feed") { $where = qq|WHERE feed_status = 'A'|; } else { $where = ""; }
	my $sql = qq|SELECT $titfield,$idfield from $table $where ORDER BY $titfield|;

	my $sth = $dbh -> prepare($sql);
	$sth -> execute() or die $dbh->errstr;
	while (my $ref = $sth -> fetchrow_hashref()) {
		next unless ($ref->{$titfield});
		my $selected="";
		if ($opted eq $ref->{$idfield}) { $selected = " selected"; }
		$output .= qq|    <option value="$ref->{$idfield}"$selected>$ref->{$titfield}</option>\n|;
	}

	if ($output) {
		$output = qq|<select name="$idfield" id="$idfield" style="width:|.$width.qq|em;" class="viewer-select">
    <option value="none" selected>$blank</option>
		$output</select>
		|;
	}
	return $output;
}

	# -------  Get Next -------------------------------------------------------------
	# Get previous, stext, start and end id numbers given a table, 
	# and 'where' as a hash of key=>value, search 
	# and sort information, returning the four values as a hash {prev=>$id,etc}
	# This is being use for API output, not formatting

sub get_next {

	my ($dbh,$table,$id,$sort,$where,$record_data) = @_;
	my @directions = qw(first last next prev);  # The order here matters, in case next > last
	my $idfield = $table."_id";
	my $results;

	my $sortreplace = "ORDER BY ".$table."_";
	$sort =~ s/$sortreplace//;	# fixes something from sort_start_number();
	$sort =~ s/ DESC//;			# where it returns the full 'ORDER BY' phrase
								# used elsewhere, but we don't want to use it here 


	foreach my $direction (@directions) {
return "$direction nn";
		# This is some arbitrary search stuff
		my $rwhere = "";
		if ($table eq "presentation"){
			$rwhere = qq|(presentation_catdetails NOT IN("Interview","Class","Internal Presentation")) AND |;
		} elsif ($record_data->{presentation_catdetails} eq "Interview") {
			$rwhere = qq|(presentation_catdetails = "Interview") AND |;
		} elsif ($record_data->{presentation_catdetails} eq "Class") {
			$rwhere = qq|(presentation_catdetails = "Class") AND |;
		}

		# How are we sorting the next, previous, etc (default to crdate)?
		# (Again, remember table data uses fields with table name, eg. presentation_title)
		my $sort_by; my $search_value;
		if ($sort) { 
			$sort_by = $table."_".$sort;	
			$search_value = $record_data->{$table."_".$sort}; }
		else { 
			$sort_by = $table."_crdate";	
			$search_value = $record_data->{$table."_".$sort}; }
		
		# Handle case of first or last record (to allow blank search result to produce an error)
		
		if (($direction eq "next") && ($id eq $results->{last})) {  
			$results->{next} = $results->{last}; next; }
		if (($direction eq "prev") && ($id eq $results->{first})) { 
			$results->{prev} = $results->{first}; next; }	

		# Define and execute search for first,last,next,prev record id	
		my $nextsql = sprintf("SELECT %s FROM %s WHERE %s%s ",$idfield,$table,$rwhere,$sort_by);
		unless ($search_value) { $search_value = '0'; }  # Make sure search value has a value for search
		if ($direction eq "first") { $nextsql .= sprintf("<= '%s' ORDER BY %s ",$search_value,$sort_by); }
		elsif ($direction eq "last") { $nextsql .= sprintf(">= '%s' ORDER BY %s DESC",$search_value,$sort_by);}
		elsif ($direction eq "next") { $nextsql .= sprintf("> '%s' ORDER BY %s ",$search_value,$sort_by); }
		elsif ($direction eq "prev") { $nextsql .= sprintf("< '%s' ORDER BY %s DESC",$search_value,$sort_by);}		
		$nextsql .= " LIMIT 1";
		# Will fail if $table or $id don't exist or if $sort isn't a valid field
		my ($newnextid) = $dbh->selectrow_array($nextsql) 
			or die "Can't execute SQL statement (will fail if table or id don't exist or if sort isn't a valid field) $nextsql: $dbh::errstr\n"; 
		#$results->{$direction} = $nextsql; 
		$results->{$direction} = $newnextid; 
		
	}
	
	return $results;
}

	# -------  Make Next -------------------------------------------------------------
	#
sub make_next {

	my ($dbh,$input,$table,$id_number,$filldata) = @_;
	if ($diag>9) { print "Make Next<br>"; }

	unless (defined $input) { if ($diag>9) { print "/Make Next - input not defined<br>"; } return;	}
	unless (defined $input) { if ($diag>9) { print "/Make Next - input not defined<br>"; } return;	}

	my @directions = qw(next previous first last);
	foreach my $direction (@directions) {

		my $count=0;
		while ($$input =~ /<$direction(.*?)>/sig) {

			$count++; last if ($count > 100);			# Prevent infinite loop

			my $autocontent = $1;my $nexttext = "";
			next if ($autocontent eq "BuildDate");			# Fixes RSS bug, need something more permanent

			my $script = {};
			&parse_keystring($script,$autocontent);
			my $format = $script->{format} || $vars->{format} || "html";


			if ($script->{type}) { 	$typesql = " ".$table."_type='".$script->{type}."' AND ";  }

			# Special sequences - I'll figure out how to create an interface for this later, for now
			# I'll define sequences here manually
			# Create clause for presentations (so we don't include class, interview or internal presentations )
			my $rwhere = "";
			if ($table eq "presentation"){
				$rwhere = qq|((presentation_catdetails IS NULL) OR (presentation_catdetails NOT IN("Interview","Class","Internal Presentation"))) AND |;
			} elsif ($filldata->{presentation_catdetails} eq "Interview") {
				$rwhere = qq|(presentation_catdetails = "Interview") AND |;
			} elsif ($filldata->{presentation_catdetails} eq "Class") {
				$rwhere = qq|(presentation_catdetails = "Class") AND |;
			}

			# How are we sorting the next, previous, etc
			my $sort_by; my $search_value;
			if ($script->{sortby}) { 
				$sort_by = "_".$script->{sortby}; 
				$search_value = $filldata->{$table."_".$script->{sortby}}; 
			} else {
				$sort_by = "_title"; 
				$search_value = $filldata->{$table."_title"}; 
			}

			my $nextsql ="SELECT ".$table."_id FROM $table WHERE $rwhere$typesql ".$table.$sort_by." ";
#$nexttext .= "Direction: $direction <br>Search value: $search_value <br>";			

			if ($direction eq "next") {  $nextsql .= ">'".$search_value."' ORDER BY ".$table.$sort_by;}
			elsif ($direction eq "previous") { $nextsql .= "<'".$search_value."' ORDER BY ".$table.$sort_by." DESC";}
			elsif ($direction eq "first") { $nextsql .= "<'".$search_value."' ORDER BY ".$table.$sort_by;}
			elsif ($direction eq "last") { $nextsql .= ">'".$search_value."' ORDER BY ".$table.$sort_by." DESC";}

			$nextsql .= " LIMIT 1";
#$nexttext .= $nextsql;
			my ($newnextid) = $dbh->selectrow_array($nextsql);
			if ($newnextid) {
				$nexttext .= qq|[<a class="next" href="|.
                                                          $Site->{st_url}.
                                                          "$table/".
                                                           $newnextid.qq|">@{[&printlang(ucfirst($direction))]}</a>]|;
			}

			$$input =~ s/$autotext/$nexttext/;
		}

	}
	if ($diag>9) { print "/Make Next<br>"; }

}

	# -------  Make Counter -------------------------------------------------------------
sub make_counter {
	my ($dbh,$input,$silent) = @_;

	my @boxlist;
	while ($$input =~ /<counter(.*?)>/sig) {

		my $autotext = "<counter".$1.">";

		my $script = {};
		&parse_keystring($script,$1);

		if ($script->{name}) { $countername = $sy."counter"; } else { $countername = "counter"; }
		if ($script->{start}) {  if ($Site->{$countername}==1) { $Site->{$countername} = $script->{start}; }  }
		if ($script->{increment}) { $Site->{$countername} += $script->{increment}; } else { $Site->{$countername}+=40; }
			
		my $replace = $Site->{$countername};
		$$input =~ s/$autotext/$replace/;
	}

}

	# -------  Make Boxes -------------------------------------------------------------
sub make_boxes {
	my ($dbh,$input,$silent) = @_;

	my @boxlist;
	while ($$input =~ /<box (.*?)>/sig) {
		my $autotext = $1;

		&error($dbh,"","",&printlang("No box recursion")) unless (&index_of($autotext,\@boxlist) == -1);
		push @boxlist,$autotext;

		my $box_content = &db_get_content($dbh,"box",$autotext);

		&make_site_info(\$box_content);
		$$input =~ s/<box $autotext>/$box_content/;
	}

}
sub make_escape {

	my ($dbh,$input,$silent) = @_;
	return unless $$input =~ /<escape>/;
	my $newinput = "";

	my @elist = split /<escape>/,$$input;
	foreach my $eitem (@elist) {
		unless ($newinput) { $newinput = $eitem; next; }
		my ($escarea,$nonescarea) = split "</escape>",$eitem;
		$escarea = HTML::Entities::encode($escarea);
		$newinput .= $escarea.$nonescarea;
	}
	$$input = $newinput;
}
sub make_tz {

	my ($dbh,$input,$silent) = @_;
	return unless $$input =~ /<timezone>/;
	my $newinput = $Site->{st_timezone};
	$$input =~ s/<timezone>/$newinput/ig;
}

	# -------   Make Conditionals ------------------------------------------------------
	#
	#           Analyzes <if> <then> <endif> 
	#
	#           In the text, if the contents between <if> and <then> are nonzero, then the content 
	#           between <then> and <endif> become part of the text, otherwise the whole <if> ... <endif>
	#           expression is removed. Note that this function should be run *after* content-filling
	#           functions such as make_data_elements() and make_keywords()        
	#
	#-------------------------------------------------------------------------------

sub make_conditionals {

   	my ($text_ptr,$table,$id,$filldata) = @_;

	my $count = 0; 									# Look for conditional statements
	while ($$text_ptr =~ /<if>(.*?)<then>(.*?)<endif>/sig) {
		$count++; last if ($count > 100);			# Prevent infinite loop
		my $replace = "";							# Create an original empty replace string
		my $autotexta = $1; my $autotextb = $2;		# Parse conditional statement
		my $antecedent = $autotexta;				# Extract antecedent from text, then
		$antecedent =~ s/\s+//g;					# clean spaces, line feeds from antecedent
		if ($antecedent) { 							# and look for content in antecedent
			$replace .= $autotextb;					# If content is found, put the consequent into the replace string,
			$replace =~ s/^\s+|\s+$//sg;			# removing leading and trailing spaces, which
													# allows us to insert strings into formatting, URLs, etc
		} 
													# Substitute the original content with the replace string
													# noting that if the antecedent is empty the entire conditional
													# will be replaced with the original empty replace string
		$$text_ptr =~ s/<if>\Q$autotexta\E<then>\Q$autotextb\E<endif>/$replace/sig;
													# Win code documentation of the year award
	}
}


	# -------   Make Keylist ------------------------------------------------------
	#
	#           Analyzes <keylist ...> command in text
	#           A keylist is a series of records linked via entries in the graph table
	#	    make_keylist parses a <keylist> command and replaces it with a
	#           list of names with links. format: <keylist db=link,id=234,keytable=author>
	#	      Edited: 14 January 2013, 8 Oct 2021
	#-------------------------------------------------------------------------------
sub make_keylist {

	my ($dbh,$query,$text_ptr) = @_;
	my $diag = 0;
	if ($diag>9) { print "<ul>Make Keylist <br>"; }

   	my $vars = ();
       	if (ref $query eq "CGI") { $vars = $query->Vars; }


	unless ($$text_ptr =~ /<keylist (.*?)>/i) {
		if ($diag>9) { print "/Make Keylist - No content found, returning<p> </ul>"; }
		return 1;
	}

	while ($$text_ptr =~ /<keylist (.*?)>/ig) {

		my $autocontent = $1; my $replace = "";




						# No endless loops, d'uh
		$vars->{escape_hatch}++; 
		if ($vars->{escape_hatch} > 10000) {
			die "Endless keyword loop"; 
		}

						# Pasre Keyword into Script
		my $script = {};
		&parse_keystring($script,$autocontent);

		$script->{separator} = $script->{separator} || ", ";

		for (qw(prefix postfix separator)) {
			if ($script->{$_} =~ /(BR|HR|P)/i) {
				$script->{$_} = "<".$script->{$_}.">";
			}
		}

		our $ddbbhh = $dbh;
		
 		my @connections = &find_graph_of($script->{db},$script->{id},$script->{keytable});

		my $results_count=0;
		foreach my $connection (@connections) {

			next unless ($connection);			# escape in case of zero results counts

									# Get item data

									# Prepare SQL Query for each item
									# (We could probably combine into one
									# by making a large 'OR' out of all the ID
									# numbers...
			my $titfield = get_key_namefield($script->{keytable});
			my $klid = $script->{keytable}."_id";
			$script->{search} =~ s/'//; $connection =~ s/'//;

			# my $keylistsql = qq|SELECT * FROM $script->{keytable} WHERE $klid = '$connection'|;
			my $keylistsql = qq|SELECT * FROM $script->{keytable}|;

			my $wwwvalues = $script;
			$wwwvalues->{db} = $script->{keytable};
			$wwwvalues->{id} = $connection;
			$keylistsql .= &make_where($dbh,$wwwvalues);

			if ($script->{type}) { $keylistsql .= " AND ".$script->{keytable}."_type = '$script->{type}'"; }
			if ($script->{search}) {
				my $descfield = $script->{keytable}."_description";
				my $catfield = $script->{keytable}."_category";
				my $contfield = $script->{keytable}."_content";
				my $keylistwhere = qq| AND ($descfield LIKE '%$script->{search}' OR
						$titfield LIKE '%$script->{search}%' OR
						$contfield LIKE '%$script->{search}%' OR
						$catfield LIKE '%$script->{search}%')|;
				$keylistsql .= $keylistwhere;
			}

									# Execute SQL Query for each item
			my $sth = $dbh->prepare($keylistsql);

			$sth -> execute();
			while (my $c = $sth -> fetchrow_hashref()) {

				next unless ($c);			# Items that don't match $script->{search}
									# if it's used will not return results

									# Display the result
				$results_count++;
				my $kname = $c->{$titfield};
				if ($replace) { $replace .= $script->{separator}; }
				if ($script->{format} eq "text") { $replace .= qq|$kname|; }
				elsif ($script->{format}) {
					my $ftext = &format_record($dbh,$query,$script->{keytable},$script->{format},$c,1);
					$replace .= $ftext; }
				else { $replace .= qq|<a href="$Site->{st_url}$script->{keytable}/$connection" style="text-decoration:none;">$kname</a>|; $replace =~ s/\n/<br\/>/ig; }



			}
			$sth->finish();




		}
  #print " -- $replace <br>";



	if ($results_count) {

		# Insert Heading
		if ($script->{heading}) {
			if ($script->{helptext}) {
				$replace = "<h2>".$script->{heading} ."</h2><p>".$script->{helptext}."</p>".  $replace;
			} else {
				$replace = "<h2>".$script->{heading} ."</h2>".  $replace;
			}
		}

		if ($script->{readmore}) {
			$replace .= qq|Read more: <a href="$script->{readmore}">$script->{heading}</a>|;
		}

	} else {
		# If no results are found, and a empty format is specified, display empty format. -Luc
		if ($script->{empty_format}) {
			$replace = $script->{empty_format};
			# Fixed Luc's code - SD
			#$replace = &format_record($dbh, "",$script->{db},$script->{empty_format}, "", 1);
		}
	}



		if ($replace && ($script->{prefix} || $script->{postfix})) { $replace = $script->{prefix} . $replace . $script->{postfix}; }

		$$text_ptr =~ s/\Q<keylist $autocontent>\E/$replace/;


	}

	if ($diag>9) { print "/Make Keylist <p>"; }
}

	#-------------------------------------------------------------------------------
	#
	# -------   Make Author Info ------------------------------------------------------
	#
	#
	#   For a record $r finds the appropriate author records and returns
	#   formated content
	#
	#   For example:  <author summary>  returns author records in author_summary format
	#
	#	      Edited: 19 April 2013
	#-------------------------------------------------------------------------------
sub make_author {

	my ($text_ptr,$table,$id,$filldata) = @_;

   	return 1 unless ($$text_ptr =~ /<author (.*?)>/i);
	while ($$text_ptr =~ /<author (.*?)>/ig) {

		my $autocontent = $1; my $replace = "";

		&escape_hatch();


		my @connections = &find_graph_of($table,$id,"author");
		foreach my $connection (@connections) {

			my $author = &db_get_record($dbh,"author",{author_id=>$connection});
			if ($author->{author_id}) {
				$replace .= &format_record($dbh,$query,"author",$autocontent,$author);
			}

		}



		$$text_ptr =~ s/\Q<author $autocontent>\E/$replace/;

	}

}

	# -------   Make Admin Nav ----------------------------------------------------------
	#
	#	Prints the navigation bar to create and list types of records
	#
sub make_admin_nav {

	my ($dbh,$text_ptr) = @_;

   	return 1 unless ($$text_ptr =~ /<admin_nav(.*?)>/i);

   	my @tables = $dbh->tables();
	while ($$text_ptr =~ /<admin_nav(.*?)>/ig) {
		my $autocontent = $1; my $replace = "";

		my $replace = qq|
			<div id="admin_table_nav">
			[<a href="$Site->{script}">Admin</a>]<br/><br/>
			|;

		foreach my $table (@tables) {
			$table =~ s/`//ig;
			if ($table =~ /\./) { my $tmp; ($tmp,$table) = split /\./,$table; }

  #			next unless (&is_viewable("nav",$table)); 		# Permissions

			my $numb;
			if ($table eq "feed") { $numb = "&number=1000"; }
			elsif ($table eq "page") { $numb = "&number=500"; }

			my $tname = ucfirst($table);
			my $title = "List ".$tname."s";
			$replace .= qq{
				[<a href="$Site->{st_cgi}admin.cgi?db=$table&action=edit">New</a>]
				[<a href="$Site->{st_cgi}admin.cgi?db=$table&action=list$numb">List</a>]
				$tname <br />\n
			};
		}
		$replace .= "</div>";
		$$text_ptr =~ s/\Q<admin_nav$autocontent>\E/$replace/;
	}


}

	#-------------------------------------------------------------------------------
	#
	# -------   Make Enclosures ------------------------------------------------------
	#
	#    Make a list of enclosures at the <enclosures> tag
	#
	#	      Edited: 21 Jan 2013
	#-------------------------------------------------------------------------------
sub make_comment_form {

		my ($dbh,$text_ptr) = @_;
		return unless (defined $text_ptr);

		while ($$text_ptr =~ /<CFORM>(.*?)<END_CFORM>/sg) {

			my $autotext = $1; my ($cid,$ctitle) = split /,/,$autotext;
			$ctitle =~ s/"//g;
			my $code = &make_code($cid);

			# Detect anonymous user
			my $anonuser = 0;
			if ($Person->{person_name} eq $Site->{st_anon}) { $anonuser=1; }

			# Set up email subscription element...
			my $email_subscription;

			# ... for anon user
			if ($anonuser) {
				$email_subscription = qq|
					<tr><td colspan=2>@{[&printlang("Enter Email for Replies")]}</td>
					<td colspan="2"><input type="text" name="anon_email" size="40"></tr>|;

			# ... for registered user
			} else {
				$email_subscription = qq|
				<tr><td><input type="checkbox" name="post_email_checked" checked></td>
				<td colspan="3">@{[&printlang("Check Box for Replies")]}<br>&nbsp;@{[&printlang("Your email")]}
				<input type="text" name="anon_email" value="$Person->{person_email}" size="57"></tr>|;
			}

			my $identifier = "id".$Person->{person_id}.time;
			my $comment_form = qq|
			<div class="comment_form_container" style="background-color:#eeeeee;"><div style="padding:10px;">
			<section id="Comment"><h3>@{[&printlang("Your Comment")]}</h3></section>

			<div id="preview" style="width:90%;">
			<p><LOGIN_INFO></p>
			<p>@{[&printlang("Preview until satisfied")]} @{[&printlang("Not posted until done")]}<p>
			</div></div>

			<div id="theform" style="width:90%;">

			 <a name="comment"></a>
	 		 <form id="apisubmit" method="post" action="$Site->{st_cgi}page.cgi" style="margin-left:15px;">
			 <input type="hidden" name="table" value="post">
			 <input type="hidden" name="post_type" value="comment">
			 <input type="hidden" name="id" value="new">
			 <input type="hidden" name="post_thread" value="$cid">
			 <input type="hidden" name="code" value="$code">
			 <input name="action" value="api submit" type="hidden">
			 <input name="identifier" value="$identifier" type="hidden">

			<input name="post_title" value="Re: $ctitle" size="60" style="width:300px;height:1.8em;" type="text">
			<br/>


			<textarea id="post_description" name="post_description" cols="70" rows="5"></textarea>
			<br/>

			$email_subscription

			<br/>
			<input name="pushbutton" id="pushbutton" type="hidden">
			<button id="preview">Preview</button>
			<button id="done">Done</button>


			</form>|;

			my $cbox = &printlang("comment_disclaimer");
			$comment_form .= &db_get_content($dbh,"box",$cbox);

			$comment_form .= "</div></div>";

			$$text_ptr =~ s/<CFORM>\Q$autotext\E<END_CFORM>/$comment_form/sig;
		}
	}

sub make_enclosures {

	my ($text_ptr,$table,$id,$filldata) = @_;

   	return 1 unless ($$text_ptr =~ /<enclosures (.*?)>/i);
	while ($$text_ptr =~ /<enclosures (.*?)>/ig) {

		my $autocontent = $1;my $replace = ""; my $style = "";

		&escape_hatch();

		my @enclosures = &find_graph_of($table,$id,"file","Enclosure");
		foreach my $enclosure (@enclosures) {
			my $file = &db_get_record($dbh,"file",{file_id=>$enclosure});
			if ($autocontent eq "format=html") {
				$replace .= qq|- <a href="$Site->{st_url}$file->{file_dirname}">$file->{file_title}</a><br/>|;
			} elsif  ($autocontent eq "format=html") {
				$replace .= qq|<enclosure url="$Site->{st_url}$file->{file_dirname}" length="$file->{file_size}" type="$file->{file_size}" />|;
			}
		}
		if ($replace) {
			if ($autocontent eq "format=html") { $replace = qq|<p>Enclosures:<br>$replace</p>|; }
		}

		$$text_ptr =~ s/\Q<enclosures $autocontent>\E/$replace/;

	}

}

	#-------------------------------------------------------------------------------
	#
	# -------   Make Media ------------------------------------------------------
	#
	#
	#   For a record $r finds the appropriate image file $f or alignment $a and
	#   width $w and returns the formated image (with captions, etc., as
	#   appropriate given width parameters).
	#
	#	      Edited: 21 Jan 2013
	#-------------------------------------------------------------------------------
sub make_media {

	my ($text_ptr,$table,$id,$filldata) = @_;
  #print "Making media<p>";
   	return 1 unless ($$text_ptr =~ /<media (.*?)>/i);
	while ($$text_ptr =~ /<media (.*?)>/ig) {

		my $autocontent = $1; my $replace = ""; my $style = "";

		&escape_hatch();

		my $typeval; my $width;
		if ($autocontent eq "display") {
			$width = "400";
			$style = qq|style="width:400px;margin:5px 15px 5px 0px;"|;
		}
		else { $typeval = autocontent; }


		if ($autocontent eq "icon") { $replace =  &make_icon($table,$id,$filldata)."<p>";


		} else { $replace =  &make_media_display($table,$id,$autocontent,$style,$filldata)."<p>";


		}


		$$text_ptr =~ s/\Q<media $autocontent>\E/$replace/;

	}

}

	#-------------------------------------------------------------------------------
	#
	# -------   Make Associations ------------------------------------------------------
	#
	#
	#   For a record $r find the second-order associations.
            #   For example, for an $author with a list of $posts, find the list of
            #   $feed for those posts
	#
	#	      Edited: 27 July 2020
	#-------------------------------------------------------------------------------
sub make_associations {

	my ($text_ptr,$table,$id,$filldata) = @_;

  	return 1 unless ($$text_ptr =~ /<associate (.*?)>/i);
	while ($$text_ptr =~ /<associate (.*?)>/ig) {
		my $autotext = $1;
		$count++; last if ($count > 100);			# Prevent infinite loop
		my $replace = "";
		my ($first_table,$second_table,$format) = split ",",$autotext;
		$format ||= "list";
		my @associations = &find_second_graph($table,$id,$first_table,$second_table);   
		foreach my $associate (@associations) {
			my $assoc_record = &db_get_record($dbh,$second_table,{$second_table."_id"=>$associate});					# get record
			my $assoc_text = &format_record($dbh,
				$query,
				$second_table,
				$format,
				$assoc_record);
			$replace .= "$assoc_text";
		}
		$$text_ptr =~ s/\Q<associate $autotext>\E/$replace/;
            }
}

	#-------------------------------------------------------------------------------
	#
	# -------   Make Image ------------------------------------------------------
	#
	#
	#   For a record $r finds the appropriate image file $f or alignment $a and
	#   width $w and returns the formated image (with captions, etc., as
	#   appropriate given width parameters).
	#
	#	      Edited: 21 Jan 2013
	#-------------------------------------------------------------------------------
sub make_images {

	my ($text_ptr,$table,$id,$filldata) = @_;

  return 1 unless ($$text_ptr =~ /<image (.*?)>/i);
	while ($$text_ptr =~ /<image (.*?)>/ig) {

		my $autocontent = $1; my $replace = ""; my $style = "";

		&escape_hatch();

		my $typeval; my $width;
		#if ($autocontent eq "display") {
		#	$width = "400";
		#	$style = qq|style="width:400px;margin:5px 15px 5px 0px;"|;
		#}
		#else { $typeval = $autocontent; }


		if ($autocontent eq "icon") { $replace =  &make_icon($table,$id,$filldata)."<p>";	}
		elsif ($autocontent eq "display") { $replace =  &make_display($table,$id,$autocontent,$style,$filldata)."<p>"; }
		else {
			my $imagefile = &item_images($table,$id,"largest");
			my $imlink = $imagefile->{file_link} || $filldata->{$table."_link"};
			if ($imagefile->{file_dirname}) {
				$replace =  qq|<div class="image_realsize">
				<a href="$imlink"><img src="<st_url>$imagefile->{file_dirname}"
				alt="$imagefile->{file_dirname}"></a></div>|;
			}
	  }

		$$text_ptr =~ s/\Q<image $autocontent>\E/$replace/;

	}

}

	#-------------------------------------------------------------------------------
	#
	# -------   Make Icon ------------------------------------------------------
	#
	# Makes icon text for a record in response to an <image icon> tag
	#
	#
sub make_icon {

	my ($table,$id,$filldata) = @_;
	$Site->{st_icon} ||= "files/icons/";		# Default icon directory location
	my $width = "100";
	my $style = qq|style="width: 100px; float:left; margin:5px 15px 5px 0px;"|;
	my $iconurl = "";


	my $iconlink = $Site->{st_url}.$table."/".$id."/rd";

	# Defined icon over-rides everything
	if ($filldata->{$table."_icon"} && -e $Site->{st_urlf}.$Site->{st_icon}.$filldata->{$table."_icon"}) {
		$iconurl = $Site->{st_url} . $Site->{st_icon} . $filldata->{$table."_icon"};

	# In certain cases, default to author icon
	} elsif ($table eq "author" || $filldata->{$table."_genre"} eq "Column") {
		$iconurl = &make_related_icon($table,$id,"author");
	}

	# Otherwise, look for autogenerated icon
	unless ($iconurl) {
		if (-e $Site->{st_urlf}.$Site->{st_icon}.$table."_".$id.".jpg") {
			$iconurl = $Site->{st_url} . $Site->{st_icon} . $table."_".$id.".jpg";
			$filldata->{$table."_icon"} = $table."_".$id.".jpg";

		# Otherwise, try the author icon
		} else {
			$iconurl = &make_related_icon($table,$id,"author");
		}

		unless ($iconurl) {
			$iconurl = &make_related_icon($table,$id,"feed");

		}
	}

	if ($iconurl) {
		return  qq|<div class="image_icon" $style>
		           <a href="$iconlink"><img src="$iconurl" alt="Icon" width=$width></a>
		           </div>|;
	}

	return "";
}
sub make_display {

	my ($table,$id,$autocontent,$style,$filldata) = @_;
	my $replace = "";
	my $imagefile = &item_images($table,$id,"largest");
	my $imlink = $imagefile->{file_link} || $filldata->{$table."_link"};
	my $width = 400;

	if ($imagefile->{file_dirname}) {
		$replace =  qq|<a href="$imlink"><img src="<st_url>$imagefile->{file_dirname}" $style alt="$imagefile->{file_dirname}"></a>|;
	}

	return $replace;

}

	#          Item Images
	#
	#          Get the largest or smallest image associated with an item
	#          This is used to make icons and display images
	#          Provide, table, id, and option = largest|smallest
	#          Full image record is returned
sub item_images {


	my ($table,$id,$option) = @_;

	my $replace; my $largest_size = 0; $smallest_size = 10000000; my $largest_image; my $smallest_image;

	# Get the list of all images
	my @image_list_a = &db_get_record_list($dbh,"graph",
		{graph_tableone=>$table,graph_idone=>$id,graph_tabletwo=>'file',graph_type=>'Illustration'},"graph_idtwo");
	my @image_list_b = &db_get_record_list($dbh,"graph",
		{graph_tabletwo=>$table,graph_idtwo=>$id,graph_tableone=>'file',graph_type=>'Illustration'},"graph_idone");
	my @image_list = &arrays("union",@image_list_a,@image_list_b);

	# Find the largest and smallest

	foreach my $image_id (@image_list) {


		my $imagefile = &db_get_record($dbh,"file",{file_id=>$image_id});


		if ($imagefile->{file_size} > $largest_size) {

			$largest_size = $imagefile->{file_size};
			$largest_image = $imagefile;
		}
		if ($imagefile->{file_size} < $smallest_size) {

			$smallest_size = $imagefile->{file_size};
			$smallest_image = $imagefile;
		}
	}

	if ($option eq "largest") { return $largest_image; }
	elsif ($option eq "smallest") { return $smallest_image; }
	else { print "ERROR"; }


}
sub make_media_display {

	my ($table,$id,$autocontent,$style,$filldata) = @_;
	my $replace = "";

	my $imagefile = &item_media($table,$id,"largest");
	my $width = 400;


	$imagefile->{media_dirname} = $imagefile->{media_url};

	print "displaying media id number ".$imagefile->{media_id}."<P>".$imagefile->{media_dirname}."<p>";


	if ($imagefile->{media_dirname}) {
		$replace =  qq|Display<div class="image_$autocontent">
		<a href="$imagefile->{media_link}"><img src="$imagefile->{media_dirname}" $style
		alt="$imagefile->{media_dirname}" width="$width"></a></div>|;
	}

	return $replace."Display ".$imagefile->{media_dirname}."<br>";

}
sub item_media {


	my ($table,$id,$option) = @_;


	my $replace; my $largest_size = 0; $smallest_size = 10000000; my $largest_image; my $smallest_image;

	# Get the list of all images
	my @image_list_a = &db_get_record_list($dbh,"graph",
		{graph_tableone=>$table,graph_idone=>$id,graph_tabletwo=>'media'},"graph_idtwo");
	my @image_list_b = &db_get_record_list($dbh,"graph",
		{graph_tabletwo=>$table,graph_idtwo=>$id,graph_tableone=>'media'},"graph_idone");
	my @image_list = &arrays("union",@image_list_a,@image_list_b);

	# Find the largest and smallest

	my $largest_size = 0;
	foreach my $image_id (@image_list) {



		my $imagefile = &db_get_record($dbh,"media",{media_id=>$image_id});


		if ($imagefile->{media_width} > $largest_size) {

			$largest_size = $imagefile->{media_width};
			$largest_image = $imagefile;
		}
		if ($imagefile->{media_width} < $smallest_size) {

			$smallest_size = $imagefile->{media_width};
			$smallest_image = $imagefile;
		}
	}

	if ($option eq "largest") { return $largest_image; }
	elsif ($option eq "smallest") { return $smallest_image; }
	else { print "ERROR"; }


}

	#-------------------------------------------------------------------------------
	#
	# -------   Make Author Icon ------------------------------------------------------
	#
	# Used my make_icon() to find an author icon
	#
	#
sub make_related_icon {

	my ($table,$id,$related) = @_;

	my @connections = &find_graph_of($table,$id,$related);
	foreach my $connection (@connections) {
		if (-e $Site->{st_urlf} . $Site->{st_icon} . $related."_".$connection.".jpg") {
			return $Site->{st_url} . $Site->{st_icon} . $related."_".$connection.".jpg";
		}
	}
	return "";
}

	#-------------------------------------------------------------------------------
	#
	# -------   Make Lunchbox ------------------------------------------------------
	#
	# Takes input content $content and lunchbox name $name and makes a slide-down lunchbox
	# using javascript lunchboxOpen() scripts
	#
	#	      Edited: 21 Jan 2013
	#-------------------------------------------------------------------------------
sub make_lunchbox {

	my ($food,$name,$title) = @_;

		$title ||= "Add more...";
		$lunchbox = qq|
	<div id="clasp_$name" class="clasp"><a href="javascript:lunchboxOpen('$name');">$title</a></div>
	<div id="lunch_$name" class="lunchbox">
		<div class="well">
		$food
		</div>

	</div>|;
	return $lunchbox;

}

	#-------------------------------------------------------------------------------
	#
	# -------   Make Keywords ------------------------------------------------------
	#
	#           Analyzes <keyword ...> command in text
	#           Inserts contents from databased based on keyword commands
	#	      Edited: 28 March 2010
	#-------------------------------------------------------------------------------
sub make_keywords {

	my ($dbh,$query,$text_ptr) = @_;


	if ($diag>9) { print "Make Keywords <br>"; }

   	my $vars = (); my $results_count=0;
   	my $running_results_count;



   	return 1 unless ($$text_ptr =~ /<keyword (.*?)>/i);				# Return 1 if no keywords
											# This allows static pages to be published
											# Otherwise, if keyword returns 0 results,
											# the page will not be published, email not sent


    	if (ref $query eq "CGI") { $vars = $query->Vars; }

						# Substitute site tag (used to create filters)
	$$text_ptr =~ s/<st_tag>/$Site->{st_tag}/g;




						# For Each keyword Command
	my $escape_hatch=0; my $page_format = "";
	while ($$text_ptr =~ /<keyword (.*?)>/ig) {
		my $autocontent = $1; my $replace = ""; my $grouptitle = "";



						# No endless loops, d'uh
		$escape_hatch++; die "Endless keyword loop" if ($escape_hatch > 10000);
		$vars->{escape_hatch}++; die "Endless recursion keyword loop" if ($escape_hatch > 10000);

						# Pase Keyword into Script
		my $script = {};
		&parse_keystring($script,$autocontent);

						# Check Keyword Contents and Defaults
		next unless ($script->{db});

		$script->{number} ||= 50;

						# Make SQL from Keyword Data

						# Where
		my $where = &make_where($dbh,$script);

						# Number / Limit
		my $limit = "";
		if ($script->{start}) {
			$script->{number} ||= 10;
			$script->{start}--; if ($script->{start} < 0) { $script->{start} = 0; }
			$limit = " LIMIT $script->{start},$script->{number}";
		} elsif ($script->{number}) { $limit = " LIMIT $script->{number}"; }

		my $order = "";			# Order / Sort
		if ($script->{sort}) {
			my @orderlist = split ",",$script->{sort};
			foreach my $olst (@orderlist) {
				if ($order) { $order .= ","; }
				$order .= "$script->{db}_$olst";
			}
			$order = " ORDER BY " . $order;
		}


		my $sql = "SELECT * FROM $script->{db} $where$order$limit";
#die $where;

						# Permissions

		my $perm = "view_".$table;
		if ((defined $Site->{perm}) && $Site->{$perm} eq "owner") {
			$where .= " AND ".$table."_creator = '".$Person->{person_id}."'";
		} else {
			return unless (&is_allowed("view",$script->{db},"","make keywords"));
		}

		# get the list of coluns in this table (used by published_on_web()
		my @pubcolumns = &db_columns($dbh,$script->{db});

  #print "Content-type: text/html\n\n";						# Get Records From DB

		my $sth = $dbh -> prepare($sql) or die "Error in $sql: $!";
		$sth -> execute() or die "Error executing $sql: $!";
		$results_count=0;
		my $results_in = "";



						# For Each Record
		$Site->{keyword_counter}=0;
		while (my $record = $sth -> fetchrow_hashref()) {
			my $rest = "Counting...";
if ($sql =~ /link/) {
#die $sql.":-".$rest." - ".$record->{post_title}." Pub datew: ".$record->{post_pub_date}."\n";
}
$rest = "Skipping..";
			# If we are publishing a page, skip items that have not been published
			next unless (&published_on_web($dbh,$script->{db},$record,@pubcolumns));
$rest = "Did not skip";
			$Site->{keyword_counter}++;
			$results_count++;


						# Apply nohtml and truncate commands
						# to description or content fields

			my $descelement = $script->{db}."_description";
			my $conelement = $script->{db}."_content";
			my $titelement = $script->{db}."_title";


			if ($script->{truncate} || $script->{nohtml}) {
				$record->{$descelement} =~ s/<br>|<br\/>|<br \/>|<\/p>/\n\n/ig;
				$record->{$descelement} =~ s/\n\n\n/\n\n/g;
				$record->{$descelement} =~ s/<(.*?)>//g;
				$record->{$conelement} =~ s/<(.*?)>//g;
			}

						# Clean if for Javascript
			if ($script->{format} =~ /js|player/) {
				$titelement =~ s/"/&quote;/g;
				$comelement =~ s/"/&quote;/g;
				$descelement =~ s/"/&quote;/g;
			}

			if ($script->{truncate}) {
				my $etc = "...";
				if (length($record->{$descelement}) > $script->{truncate}) {
					$record->{$descelement} = substr($record->{$descelement},0,$script->{truncate}-1);
					$record->{$descelement} =~ s/(\w+)[.!?]?\s*$//;
					$record->{$descelement}.=$etc;
				}
				if (length($record->{$conelement}) > $script->{truncate}) {
					$record->{$conelement} = substr($conelement,0,$script->{truncate}-1);
					$record->{$conelement} =~ s/(\w+)[.!?]?\s*$//;
					$record->{$conelement}.=$etc;
				}
			}


						# Format Record
			my $keyflag = 1;		# Tell format_record this is a keywords request

			my $record_text = &format_record($dbh,
				$query,
				$script->{db},
				$script->{format},
				$record,
				$keyflag,
				@pubcolumns);

						# Add counter information
			$record_text =~ s/<count>/$results_count/mig;
			if ($results_count) { $vars->{results_count} = $results_count; }

						# Add Grouping titles

			if ($script->{groupby} eq "start date") {
				my $element_date = &epoch_to_date($record->{$script->{db}."_start"});
				unless ($element_date eq $grouptitle) {
					$grouptitle = $element_date;
					$results_in .= qq|<div class="key_group">$grouptitle</div>|;

				}

			}

						# Add to Keyword Text
			$results_in .= $record_text;

		}

		$results_in =~ s/,$//;	# Remove trailing comma

		if ($results_count) {
			$running_results_count += $results_count;
			# Insert Heading
			if ($script->{heading}) {
				if ($script->{helptext}) {
					$results_in = "<h2>".$script->{heading} ."</h2><p>".$script->{helptext}."</p>".  $results_in;
				} else {
					$results_in = "<h2>".$script->{heading} ."</h2>".  $results_in;
				}
			}

			if ($script->{readmore}) {
				$results_in .= qq|Read more: <a href="$script->{readmore}">$script->{heading}</a>|;
			}

		} else {
			# If no results are found, and a empty format is specified, display empty format. -Luc
			if ($script->{empty_format}) {
				$results_in = &format_record($dbh, "", 	$script->{db}, 	$script->{empty_format}, "", 1);
			}
		}

		$replace .= $results_in;


						# Insert Keyword Text Into Page
#print "Content-type: text/html\n\n";
#print "<textarea>$replace</textarea>"
		$$text_ptr =~ s/\Q<keyword $autocontent>\E/$replace/;
		$sth->finish( );


	}
#

	if ($diag>9) { print "/Make Keywords <br>"; }
	return $running_results_count;
}

	# -------  Parse Keystring ----------------------------------------------------
	#
	# Parses keyword string and fills script command hash
sub parse_keystring {
	my ($script,$keystring) = @_;

	foreach (split /;/,$keystring) {
		my ($cx,$cy) = split /=/,$_;
		if ($cx eq "all") { $cy = "yes"; }
		$cy =~ s/'//g; $cx =~ s/'//g;
		$cy =~ s/^\s//g; $cx =~ s/^\s//g;		# Remove leading spaces
		$script->{$cx} = $cy;

	}
	$script->{all} ||= "off";

}

	#-------------------------------------------------------------------------------
	#
	# -------   Make Where ------------------------------------------------------
	#
	#		Called by make_keywords() and receives an individual script
	#           Creates a 'where' statement based on keyword commands
	#	      Edited: 28 March 2010
	#
	#-------------------------------------------------------------------------------
sub make_where {

	my ($dbh,$script) = @_; my @where_list;

	unless ($script->{id}) { undef $script->{id}; }

	if ($script->{lookup}) {
		my $ret = "(".&make_lookup($dbh,$script).")";
		push @where_list,$ret;
	}


	# Set Start and Finish date-times
	# Input may be in the form yyyy/mm/dd hh:mm
	# of +/- offset (in seconds)
	# or NOW (for now)


	my $startafter; if ($script->{startafter}) {

		my $dts;
		if ($script->{startafter} =~ /^(\+|\-)/) {				# Offset Value
			$dts = time + $script->{startafter};
		} elsif ($script->{startafter} eq "NOW") {
			$dts = time;
		} else {								# RFC3339 value
			$dts = &rfc3339_to_epoch($script->{startafter});
		}

		$startafter = $script->{db}."_start > ".$dts;
		push @where_list,$startafter;

	}


	# The same as startafter, in seconds.

	my $startbefore; if ($script->{startbefore}) {
		my $dtf;
		if ($script->{startbefore} =~ /^(\+|\-)/) {				# Offset Value
			$dtf = time + $script->{startbefore};
		} elsif ($script->{startafter} eq "NOW") {
			$dts = time;
		} else {								# RFC3339 value
			$dtf = &rfc3339_to_epoch($script->{startbefore});
		}
		$startbefore = $script->{db}."_starttime < ".$dtf;
		push @where_list,$startbefore;

	}

	my $expires; if ($script->{expires}) {

		# Auto Adjust for weekends
		my ($weekday) = (localtime time)[6];
		if (($weekday == 1) && ( $script->{expires} == 24)) { $script->{expires} = 72; }

		# Calculate Expires Time
		my $extime = time - ($script->{expires}*3600);
		$expires = $script->{db}."_crdate > ".$extime;
		push @where_list,$expires;

	}


	while (my($cx,$cy) = each %$script) {
		next if	($cx =~ /^(prefix|keytable|keyflag|postfix|separator|color|number|startbefore|startafter|expires|heading|format|db|dbs|sort|start|next|all|none|wrap|lookup|nohtml|truncate|helptext|groupby|readmore)$/);
		if ($cx eq "event_start") { $cx = "start"; }

		if ($cx =~ /person_id/ && $cy eq "me") {			# Show my own personal info to me
			$cy = $Person->{person_id}; 
		}

		my $flds; my $tval; my @fid_list;
		if ($cx =~ '!~') {								# does not contain
			($flds,$tval) = split "!~",$cx;
			my @matchlist = split ",",$flds;
			foreach my $ml (@matchlist) {
				push @fid_list,$script->{db}."_".$ml." NOT REGEXP '".$tval."'";
			}
		} elsif ($cx =~ '~') {								# contains
			($flds,$tval) = split "~",$cx;
			my @matchlist = split ",",$flds;
			foreach my $ml (@matchlist) {
				push @fid_list,$script->{db}."_".$ml." REGEXP '".$tval."'";
			}
		} elsif ($cx =~ 'GT') {								# greater than
			($flds,$tval) = split "GT",$cx;
			my @matchlist = split ",",$flds;
			foreach my $ml (@matchlist) {
				push @fid_list, $script->{db}."_".$ml." > '".$tval."'";
			}
		} elsif ($cx =~ 'LT') {								# less than
			($flds,$tval) = split "LT",$cx;
			my @matchlist = split ",",$flds;
			foreach my $ml (@matchlist) {
				push @fid_list, $script->{db}."_".$ml." < '".$tval."'";
			}
		} elsif ($cx =~ '!=') {								# not equal
			($flds,$tval) = split '!=',$cx;
			my @matchlist = split ",",$flds;
			foreach my $ml (@matchlist) {
				push @fid_list, $script->{db}."_".$ml." <> '".$tval."'";
			}
		} elsif (defined($cy)) {							# equals


			if ($cy eq "TODAY") { $cy = &cal_date(time); }
			push @where_list, $script->{db}."_".$cx." = '".$cy."'";
		}


		my $fwhere = join " OR ",@fid_list;
		if ($fwhere) { push @where_list,"(".$fwhere.")"; }
	}
	my $where = join " AND ",@where_list;
  #print "Where: $where <p>";
  #&log_event($dbh,$query,"where","$Site->{process}\t$where");
	if ($where) { $where = " WHERE $where"; }

	return $where;

}

	# -------  Make UnpackedData ---------------------------------------------------
	# 	Sometimes I store data in the form a1,b1,ca;a2,b2,c2; ... etc
	#	This function receives that string
	#	and returns it neatly formatted as a table
	#	Use titles = a,b,c  (ie, a string with values separated by commas) for titles
	#	Specify table properties with $tv, eg. {cellpadding=>14}
	#	If $reqd is specified as a title, then there must be a value for that title to print
	#	Note that this value is only for checking if printing is OK, it will never actually be printed
sub make_unpackeddata {

	my ($data,$titles,$tablevals,$reqd) = @_;

	my $ret = qq|<table cellpadding="$tv->{cellpadding}" cellspacing="$tv->{cellspacing}" border="$tb->{border}">\n|;

	my @titlelist; if ($titles) {
		$ret .= "<tr>\n";
		my @titlelist = split ",",$titles; my $tcount=0;
		foreach my $tit (@titlelist) {
			$ret .= qq|<td>$tit</td>|;
		}
	}


	my @dl = split ";",$data;


	foreach my $dline (@dl) {
		my $lineret = qq|<tr>|; my $ct = 0; my $skip=0;
		my @dvls = split ",",$dline;
		foreach my $dv (@dvls) {
			if ($titlelist[$ct] && ($titlelist[$ct] eq $reqd)) {
				unless ($dv) { $skip = 1; }
			} else {
				$lineret .= qq|<td>$tit</td>\n|;
			}
		}
		$lineret .= "</tr>\n";
		unless ($skip == 1) { $ret .= $lineret; }

	}
	$ret .= "<table>\n";
	return $ret;

}

	# -------  Make Lookup ---------------------------------------------------------
sub make_lookup {
	my ($dbh,$script) = @_; my $str="";
	my ($look,$as) = split / as /,$script->{lookup}; 		#/ fix for code highligher
	my ($lf,$ll) = split / in /,$look;				#/
	my $lv = $script->{$lf};
	my $asitem = $as || $script->{db};
	my $ret = $ll."_".$asitem;
	die "Lookup command badly formed: $ll && $lf && $lv && $script->{db}" unless ($ll && $lf && $lv && $script->{db});

  # print "Content-type: text/html; charset=utf-8\n\n$stmt -- $lv <br>";

						# Permissions

	my $where ="";
	my $perm = "view_".$ll;
	if ((defined $Site->{perm}) && $Site->{$perm} eq "owner") {
		$where .= " AND ".$ll."_id = '".$Person->{person_id}."'";
	} else {
		return unless (&is_allowed("view",$ll,"","make lookup"));
	}

	my $stmt = "SELECT $ret FROM $ll WHERE ".$ll."_".$lf." = ?".$where;
	my $sth = $dbh->prepare($stmt);
	$sth->execute($lv);
	while (my $ref = $sth -> fetchrow_hashref()) {
		if ($str) { $str .= " OR "; }
		$str .= $script->{db}."_id = '".$ref->{$ret}."'";
	}
	undef $script->{lookup};
	undef $script->{$lf};
	if ($str) { return $str; }
}

# Make search form templates 
# for use with api.cgi

sub make_search_forms() {


	my $doptions; my $templ="";
	$doptions->{a}="b";
	my @tables = &db_tables($dbh);
	foreach my $table (@tables) {
		next if ($table eq "class");  # Javascript chokes on this
		# Get options from optlist

		my $sql = qq|SELECT * from optlist where optlist_table = '$table' OR optlist_title LIKE '$table%';|;

		my $sth = $dbh -> prepare($sql);
		$sth -> execute() or die $dbh->errstr;
		while (my $options = $sth -> fetchrow_hashref()) {
			next unless ($options->{optlist_data});

			# get table and field from optlist data or optlist title
			my $optlisttable = $options->{optlist_table};
			my $optlistfield = $options->{optlist_field};
			unless ($optlisttable && $optlistfield) {
				# Get table and field from title
				($optlisttable,$optlistfield) = split /_/,$options->{optlist_title};
			}
			next unless ($optlisttable && $optlistfield);


			my $option_data = $options->{optlist_data};
			my @option_list = split /;/,$option_data;
			
			foreach my $option (@option_list) {
				($ofield,$oname) = split /,/,$option;
				
				$doptions->{$optlisttable}->{$optlistfield}->{$ofield} = $oname;
			}
		}

		# Get options from fields that might not be in optlist
		my @miscfieldlist = qw(category genre section type topic class status);

		# Get the list of columns from the database
		my @columns = ();
		my $showstmt = "SHOW COLUMNS FROM $table";
		my $sth = $dbh -> prepare($showstmt);
		$sth -> execute();

		# For each column...
		while (my $showref = $sth -> fetchrow_hashref()) {
			
			# Normalize the column name
			my $fullfieldname = $showref->{Field};
			my $prefix = $table."_"; $showref->{Field} =~ s/$prefix//;
			next if ($showref->{Field} eq "class");  # Javascript chokes on this

			# See if it's the sort of thing that might be a category
			foreach my $miscfield (@miscfieldlist) {
				
				if ($showref->{Field} =~ /$miscfield/) {  # It's a hit		
					unless ($doptions->{$table}->{$showref->{Field}}) {  # If it is not in optlist			
						$doptions->{$table}->{$showref->{Field}}->{something} = "something else";

					}

				}
			}

		}

		unless ($doptions->{$table}) {
			$doptions->{$table}->{default} = "No search";
		}


	}
			




	while (my($table,$ty) = each %$doptions){	# For each table

		# Write the template
		my $formname = $table."SearchForm";
		my $panelname = $table."Panel";
		$templ .= qq|
	function |.$table.qq|SearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter \${request.table}</button>
		<div class="panel" id="$panelname">

		<form method="post" action="#" id="$formname">
		<input type="hidden" name="div" value="\${request.div}">
		<input type="hidden" name="cmd" value="\${request.cmd}">
		<input type="hidden" name="table" value="\${request.table}">		
		|;

		foreach my $column (sort keys %$ty) {
			$cy = $ty->{$column};
		#while (my($column,$cy) = each %$ty) {		# For each column
			my $fieldname = $table."_".$column;
			$templ .= sprintf(qq|
				<div class="table-list-search-form">%s <select name="%s" id="%s%s">
				    <option value="all" selected>All</a>
			|,ucfirst($column),$fieldname,$column,$table);

			foreach my $fname (sort keys %$cy) {
				$fval = $cy->{$fname};
			# while (my($fname,$fval) = each %$cy) {   #For each option
				$templ .= sprintf(qq|<option value="%s">%s</a>|,$fval,ucfirst($fname));
			}

			$templ .= qq|
							</select></div>|;


		}

		# Text search by fields
		$templ .= qq|
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>|;

		# Submit Button
		$templ .= qq|
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				\$('.list-result').remove();
				loadDataFromForm({div:'\${request.div}',cmd:'\${request.cmd}',table:'\${request.table}',formid:'$formname'}); 
				document.getElementById('$panelname').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	|;



	}
#print qq|<textarea>$templ</textarea>|;
	my $js_assets_dir = $Site->{st_urlf}."assets/js/";
		my $filename = $js_assets_dir."gRSShopper_dataTemplates.js";
		open OUT,">$filename" or print "Error opening $filename: $! <br>";
		
		print OUT $templ or print "Error printing $filename: $! <br>";
		close OUT;

		return qq|Templates printed to 
			<a href="|.$Site->{st_url}.
		qq|assets/js/gRSShopper_dataTemplates.js">gRSShopper_dataTemplates.js</a>|;
		
	return "Forms updated";
}	 


1;