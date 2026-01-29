


	#
	#
	#                                   Analyze
	#
	#

	# TABS ----------------------------------------------------------
	# ------- Analyze --------------------------------------------
	#
	# Generic Upload Functions
	#
	# Uses the _summary view but I'll fix this later
	#
	# -------------------------------------------------------------------------

# Format the Analyze Tab
sub Tab_Analyze {

	my ($window,$table,$id_number,$record,$data,$defined) = @_;
	my $output = qq|
		<!-- Need iframe, not div, as admin.cgi will be reloading inside it -->
		<iframe  id="analysis_window" style="width:95%;height:40em;border:0;"
		src="|.$Site->{st_cgi}.qq|admin.cgi?action=show_graph&table=$table&id=$id_number">
		</iframe>
	|;
	return  $output;
}


	#
	# Buttons -
	#             'Show Graph'   calls show_graph()
	#             'Build Graph'  calls analyze_text()
	#
sub analysis_buttons {

	my ($table,$id_number) = @_;

	$output .= qq|<div class="text-input">
	<input type="button" id="show_graph" value="Show Graph"
		onClick="window.location.href = '|.
		$Site->{st_cgi}.qq|admin.cgi?action=show_graph&table=$table&id=$id_number'" />
	<input type="button" id="build_graph" value="Build Graph"
		onClick="window.location.href = '|.
		$Site->{st_cgi}.qq|admin.cgi?action=analyze_text&analysis=new&table=$table&id=$id_number'"><p>
		</div>|;

	return $output;
}


# ------------------------------------------------------------------------------
#
#                        Show graph
#
# ------------------------------------------------------------------------------

	#		   onClick="\$('#analysis_window').attr('src','|.
	#		 $Site->{st_cgi}.qq|admin.cgi?action=show_graph&table=$table&id=$id_number');">
	# 		 onClick="\$('#analysis_window').attr('src','|.
	#			 $Site->{st_cgi}.qq|admin.cgi?action=analyze_text&analysis=new&table=$table&id=$id_number');"><p>|;

	sub show_graph {
    
		my ($table,$id) = @_;

		&status_error("Table not provided to show_graph()") unless ($table);
		&status_error("ID not provided to show_graph()") unless ($id);

		print &analysis_buttons($table,$id);

		my @gtables = db_tables($dbh,$query);
		my $graph = ();
		foreach my $gtable (@gtables) {
			next if ($table eq $gtable);
			push @{$graph->{$gtable}},&find_graph_of($table,$id,$gtable);
		}

		# Find last table (for drawing graph)
		my $lasttable;
		while (my($gtable,$gy) = each %$graph) {	if (@{$graph->{$gtable}}) { $lasttable = $gtable; } }

		# Show it
		print "$table $id <br>";
		while (my($gtable,$gy) = each %$graph) {
			if (@{$graph->{$gtable}}) {
				print qq|&nbsp;&nbsp;|;
				if ($gtable eq $lasttable) { print qq|&#9492;|; } else { print qq|&#9500;|; }
				print qq|$gtable <br>|;

			# Find last id (for drawing graph)
			my $lastid;
			foreach my $gt (@{$graph->{$gtable}}) { $lastid = $gt;  }

			foreach my $gt (@{$graph->{$gtable}}) {
				my $gtrecord = &db_get_record($dbh,$gtable,{$gtable."_id"=>$gt});
				my $title = $gtrecord->{$gtable."_title"} || $gtrecord->{$gtable."_name"};
				print qq|&nbsp;&nbsp;|;
				if ($gtable eq $lasttable) { print qq|&nbsp;&nbsp;&nbsp;|; } else { print qq|&#9474;|; }
				print qq|&nbsp;&nbsp;|;
				if ($gt eq $lastid) { print qq|&#9492;|; } else { print qq|&#9500;|; }
				print qq|$title
					<a href="$Site->{st_url}$gtable/$gt" target="_new">View</a><br>|;
			}
		}
	}
	print qq|<p>&nbsp;</p>|;
	print &previous_next_analysis($table,$id,"graph");
	exit;
	}
	# -------------------------------------------------------------------------------------------------------------
	#
	#                                   Extract Nouns (called by 'Build Graph')
	#
	# This is a set of functions to study the text of a post and extract words of significance. It works with an
	# author, presenting candidates for categorization as author, organization, company, etc., and identifying
	# associations between them
	#
	#
	# --------------------------------------------------------------------------------------------------------------

	sub analyze_text {

		my ($table,$id) = @_;

		# Get variables
		my $word = $vars->{word};
		my $category = $vars->{category};
		$word = $vars->{new_associates} if ($vars->{new_associates});

		# Reset if new
		&arrayClear("skip") if ($vars->{analysis} eq "new");
		&arrayClear("associates") if ($vars->{analysis} eq "new");

		# Perform actions
		&arrayAdd($vars->{term},"skip") if ($vars->{skip}); 
		&arrayAdd($vars->{term},"common") if ($vars->{common});
		&assoc_present_save_options($table,$id,$text,$word,$category) if ($word && $category);
		&assoc_save_data($table,$id) if ($vars->{associates});

		# Perform Analysis		
		my $text = &get_analysis_text($table,$id);
		print &analysis_buttons($table,$id);
		my @nouns = &extract_nouns($table,$id,$text);
		&evaluate_nouns($table,$id,$text,@nouns);

		exit;

}



sub get_analysis_text {

	my ($table,$id) = @_;
	my $vars = $query->Vars;

	my $record = &db_get_record($dbh,$table,{$table."_id"=>$id});
	my $str; #contents to be analyzed

	# Get the content we're studying

	# Study a file
	if ($table eq 'file') {
			my $filename = $Site->{st_urlf}.$record->{file_dirname};
			my $url;my $title;my $descr;
			open IN,"$filename";
			while(<IN>) {

					# Parse string
					chomp;
					my $carryover = $_;
					my @stuff = split ' - ',$carryover;
					my $title = shift @stuff;
					next unless ($tit);
					my $url = shift @stuff;

					# If we have something to save, save it
					if ($url =~ /http/) {

									$vars->{link_title} = $tit;
									$vars->{link_link} = $u;
									$vars->{link_description} = $description;
									$vars->{insert_table} = "link";
									if ($vars->{link_title}) {
											print "Content-type: text/html\n\n";
											print qq|Title: "|.$title.qq|" <br>URL: $url <br>Descr: <br>$descr<br>|;
											print "Updating...";
											$update_id = &update_record("link","new");
											print "$update_id <hr>";
									}
					# Otherwise, save what we got into the description and move on
					} else {
									$description = $carryover . " - " . $description;
					}

			}
			print qq|Title: "|.$title.qq|" <br>URL: $url <br>Descr: <br>$descr<hr>|;
			exit;

	} elsif ($table eq "link" || $table eq "post") {

		 $str = "title ". $record->{$table."_title"} ." - description ". $record->{$table."_description"};
		 $str =~ s/http/ http/g;

	} else {

			$str = $record->{$table."_description"};
	}

	 return $str;

}

sub extract_nouns {

	my ($table,$id,$str) = @_;
	my @associates = ();			# list of nouns extracted from $str


	# Define and extract the list of words @matches matching the test string
	$str =~ s/\.,!\?//g;
	my $regex = qr{\b([ie]*-?[A-Z]+[A-Za-z0-9]+.*?)\b} ;  # Test pattern
	my $teststr = $str;                                   # Test string
	$teststr =~ s/<(.*?)>//g;							  # Remove HTML from test string

	my @matches;                                       # Output
	if ( @matches = $teststr =~ /$regex/g ) {
		#  Add a dummy match 'EOF' to the list of matches
		my $number_of_matches = 0+@matches;
		#print qq|Found $number_of_matches matches: <br> |;
		if (@matches) { push @matches,"EOF"; }
	}

	# Define and extract the list of @associates from combinations in the test string
	my $quickprev;  # To preview the current match in combination with previous matches
	MATCH: foreach my $match (@matches) {
		$quickprev = $match unless ($quickprev);

		my @proper_conjuncts = (" "," of ","-"," for the "," of the ");
		foreach my $conjunct (@proper_conjuncts) {
			my $quicktest = $quickprev.$conjunct.$match;
			if ($teststr =~ m/$quicktest/) {
				$quickprev = $quicktest;
				next MATCH;
			} 
		}
			
		# Is $quickprev is a common noun?
		if (&arrayCheck($quickprev,"common")) { 
			$quickprev = $match;
			next;
		}

		# Is $quickprev something we're skipping?
		if (&arrayCheck($quickprev,"skip")) { 
			$quickprev = $match;
			next;
		}

		# $quickprev qualifies as a potential @associate 
		unless (grep{$_ eq $quickprev} @associates) { 
			push @associates, $quickprev; 
		};

		$quickprev = $match;
		next;
	}


	return @associates;
}

sub evaluate_nouns {

	my ($table,$id,$str,@associates) = @_;

	# Define the list of tables we're including in our graph
	my @categories = &assoc_categories();
	my @found_associates = ();
	my @new_associates = ();	
	# Loop through the @associates
	# print "Content-type: text/html\n\n";
	foreach my $test_associate (@associates) {

		# Test to see whether we've already saved the $associate 
		# as a $category in the database
		my $found = 0;
		foreach my $category (@categories) {
			if (my $rid = &test_word_in_db($test_associate,$category)) {
				$found = 1;
				push @found_associates,$category.":".$test_associate;
				&arrayAdd($category.":".$test_associate,"associates");  # Save for use next cycle by 
				last; 											   		# assoc_present_save_options()	
			} 
		}
		unless ($found) { push @new_associates,$test_associate; }
	}

	foreach my $associate (@new_associates) {

		# We did not find the $associate in the db...
		# Our associate is not recorded. It's new!
		# Present categorization options, which when selected will give us our 'save data' screen

		print $vars->{msg},"<p>";
		$str =~ s/$associate/<span style="color:red;">$associate<\/span>/g;
		print $str;

		# This is for handling really long files, where I don't want to show everything
		# my $prstr = &select_incontext_display($associate,$str);
		# print $prstr;print "<p>";

		print qq|
			We found a new term: $associate
			<form method="post" action="admin.cgi"> 
			<input type="hidden" name="action" value="analyze_text">
			<input type="hidden" name="term" value="$associate">
			<input type="hidden" name="table" value="$table">
			<input type="hidden" name="id" value="$id">
			<input type="submit" name="skip" value="Skip this term for now"><br>
			<input type="submit" name="common" value="Never show this term again"><br>
			</form>

			<form method="post" action="admin.cgi">
			<input type="hidden" name="action" value="analyze_text">
			<input type="hidden" name="table" value="$table">
			<input type="hidden" name="id" value="$id">
			<input type="hidden" name="word" value="$associate">
											
			Pick a category for this term. Or, optionally, suggest a different term
			and pick a category for it.<br>
			<input type="text" name="new_associates" placeholder="Optional: new term" size="40"><br><br>|;

		foreach my $category (@categories) {
			print qq|<input type="submit" name="category" value="$category"> |;
		}
		print qq|
			</form>
		|;
		print &previous_next_analysis($table,$id);
		exit;
	}

	# Oh? We're here?
	# This means that we're done this post
	# Every associate has been found and saved

	if (@found_associates) {
		print qq|Analysis complete. We have associated the following terms with this post:<br>|;
	} else {
		print qq|Analysis complete. No terms associated with this post. Maybe you want to add some?<br>
			<div style="margin:10px;">$str</div><br>|;
	}
	
	my @sorted_associates = sort @found_associates;
	foreach my $a (@sorted_associates) {

		


		# Create a graph entry for this association - EXCEPT for Author
		my ($gtable,$gtitle) = split /:/,$a;
		my $gid = &db_locate($dbh,$gtable,{$gtable."_title" => $gtitle});
		if ($gid) {
			 my $addid = &graph_add($table,$id,$gtable,$gid,"assoc");
			 #print "Graph entry: $addid<br>";
		} else {
			# This error happens for 'author', which uses 'name' instead of 'title'
			#print "Couldn't create graph entry for $table,$id,$gtable,$gtitle <br> ";
		}
		$a =~ s/:/: /;  # prettify
		print " - $a <br>";

	};

	print qq|
		<br><form method="post" action="admin.cgi">
		<input type="hidden" name="action" value="analyze_text">|;

	print qq|<br>Suggest another term? <input type="text" name="word" size="40"><br><br>
		Pick a category for this term: |;
		foreach my $category (@categories) {+
				print qq|<input type="submit" name="category" value="$category"> |;
			}
		print qq|
			<input type="hidden" name="table" value="$table">
			<input type="hidden" name="id" value="$id">
			</form>
			|;

   	print &previous_next_analysis($table,$id);
		exit;


	}


  # Prints previous-next links at the Bottom

sub previous_next_analysis {

	my ($table,$id,$action) = @_;
	my $output = "";
	if ($action eq "graph") { $action = qq|show_graph|; }
	else { $action = qq|analyze_text|; }
	$id--;
	$output .= qq|<a href="$Site->{st_cgi}admin.cgi?table=$table&id=$id&action=$action&analysis=new">Previous $table?</a>\n\n|;
	$id++;  $id++;
	$output .= qq|<a href="$Site->{st_cgi}admin.cgi?table=$table&id=$id&action=$action&analysis=new">Next $table?</a>\n\n|;
  return $output;
}

	#
	#    Saves graph data submitted about an associated term (or 'associate')
	#

sub assoc_save_data {

	#print "Content-type: text/html\n\n";
	# print "Saving data - assoc_save_data<p>";

	my @associates = split ",",$vars->{associates};
	foreach my $associate (@associates) {
		&status_error("Invalid associate table proposed in assoc_save_data()")
			unless ($list =~ /^[\p{Alnum}\s-_]{0,30}\z/ig);  # Just in case
		# get the category and title
		my ($category,$title) = split ":",$associate;
		&status_error("Invalid associate proposed in assoc_save_data()")
			unless ($title =~ /^[\p{Alnum}\s-_]{0,30}\z/ig);  # Just in case
		my $associate_id = &test_word_in_db($title,$category);
		if ($associate_id) {
			# Create the graph record
			my $graph_id = &db_insert($dbh,$query,"graph",{
				graph_tableone=>$vars->{associate_table}, graph_idone=>$vars->{associate_id},
				graph_tabletwo=>$category, graph_idtwo=>$associate_id,
				graph_creator=>$Person->{person_id}, graph_crdate=>time, graph_type=>'assoc', graph_typeval=>''});
		} else { &status_error("Could not find $category:$title in the database"); }
	}
}

# Define the list of tables we will use to create associations
sub assoc_categories {
	return qw(author place institution organization company product project work feed journal concept);
}

sub assoc_present_save_options {

	my ($table,$id,$str,$word,$category) = @_;

	my @categories = &assoc_categories();
	
	my $url,$logo,$json_text,$description;
	($url,$logo,$json_text) = &get_url_from_clearbit($word) 
		if ($category =~/company|institution|organization|product/);
	($url,$description) = &get_concept_from_wikipedia($word);

	my $record_id = &make_new_record($category,{
		$category."_name" => $word,
		$category."_title" => $word,
		$category."_url" => $url,
		$category."_logo" => $logo
	});

	# Save the new $category record
	my $record = &db_get_record($dbh,$category,{$category."_id" => $record_id});

	# Associate with the original $table
	&graph_add($table,$id,$category,$record_id,"mentions");

	print &analysis_buttons($table,$id);
	print &Tab_Analyzer($window,$category,$record_id,$record);


	#Set up form for associations
	# Note that new associations could be defined for existing records, based on the current data

	# Get all of the associates for this post, which we saved earlier
	# print "Getting associates file...<br>";
	my @associates = arrayReturn("associates");
	my $associates_form = qq|
		<input type="hidden" name="associate_id" value="$record_id">
		<input type="hidden" name="associate_table" value="$category">
	|;
	
	# For each associate...
	foreach my $associate (@associates) {

		# If it is already associated, we just want to skip it
		# Which would mean that, for both (a) it exists, and (b) there's an entry in the graph table
		# We've already tested one (if ($record_id eq "new")) now we'll test the other
		# print "Testing for association with $associate <br>";

		my ($acategory,$aword) = split /:/,$associate;
		my $arecord_id = &test_word_in_db($aword,$acategory);

		# If the both exist...
		if ($record_id ne "new" && $arecord_id) {

			# Then they might be associated. Let's see if there's a graph entry
			# and if there is, we'll just skip this item
			# print qq|Checking for graph entry between: $insert_table : $record_id and $acategory : $arecord_id <br>|;
			next if (&db_locate($dbh,"graph",{
				graph_tableone=>$insert_table, graph_idone=>$record_id,
				graph_tabletwo=>$acategory, graph_idtwo=>$arecord_id}));

		}

		# No association exists. So let's give the user the option to create one.
		# print "No association found<br>";
		$count++;
		$associates_form .= qq|
			<div><input style="display:inline" type="checkbox" id="associates$count" name="associates" value="$acategory:$aword" ><label class="label-inline" for="associates$count">$acategory: $aword</label></div>
			|;
		
		#qq|<input type="checkbox" value="$acategory:$aword" name="associates" checked> $acategory: $aword <br>|;
		
	}

	# Print the form
	

	print &checkbox_style();
	print qq|d<div style="margin:10px;">
		<form method="post" action="admin.cgi">
		<input type="hidden" name="action" value="analyze_text">
		<input type="hidden" name="table" value="$table">
		<input type="hidden" name="id" value="$id">
		<br><br>Associate $category: $word with:<br>
		$associates_form
		<br><br><input type="submit" value="Submit When Completed"><p>
		</form>
		</div>
	|;
 	print &previous_next_analysis($table,$id);
	exit;

	
}

	# Given a word and a string, show only stuff around the word in the string


	sub select_incontext_display {
		my ($word,$str) = @_;
		if ($str =~ /($|\n\n)(.*?)$word(.*?)(\n\n|^)/) {
				return $1.$word.$2;
		}
	}

	sub test_word_in_db {

		my ($word,$category) = @_;
		
	#print "Content-type: text/html\n\n";
	#print qq|Testing "$word" in database table "$category" <br>|;

		# Test for title or name
	my $name_or_title = get_key_namefield($category);
	my $id =  db_locate($dbh,$category,{$name_or_title=>$word});

	# Test for Acronym
	unless ($id) {
				$id =  db_locate($dbh,$category,{$category."_acronym"=>$word});
	}

	# Test for Nickname
	unless ($id) {
				$id =  db_locate($dbh,$category,{$category."_nickname"=>$word});
	}

	#if ($id) { print qq|Found |.$category.qq|_id "$id" in "$category" <p>|; }
	#else { print qq|Did not find |.$category.qq|_id in "$category" <p>|; }

	return $id;
	}

  # Tests to see if a word is in a file containing words relevant to a category

	sub add_word_to_file {
	#print "Content-type: text/html\n\n";
	my ($word,$category) = @_;
			my $filename = $Site->{st_urlf}."files/".$category.".txt";
	open OUT,">>$filename" or die "Could not open $filename $!";
	print OUT $vars->{word}."\n" or die "Could not append to $filename $!";
	close OUT;
	#print qq|The word "$word" appended to file $filename <br>|;


	}


	# Keeps track of things in the current post so we can decide whether to associate them with each other
	sub add_to_associates_file {

	my ($word,$category) = @_;
	my $line = $category.":".$word."\n";

	my @known_associates = &get_associates_file();
	return if (grep( /$line/, @known_associates ));   # No duplicates please

	#print "Content-type: text/html\n\n";

			my $filename = $Site->{st_urlf}."files/associates.txt";
	open OUT,">>$filename" or die "Could not open $filename $!";
	print OUT $line or die "Could not append to $filename $!";
	close OUT;
	#print qq|The "$category:$word" appended to file $filename <br>|;

	}

	# Returns the associates file as an array so we can ask whether we want something associated
	sub get_associates_file {
	my ($opt) = @_;
	#print "Content-type: text/html\n\n";
	my @associates;
	my ($word,$category) = @_;
	my $filename = $Site->{st_urlf}."files/associates.txt";
	open IN,"$filename" or die "Could not open $filename $!";
	while (<IN>) {
		chomp;
		my $match = $_;
		unless (grep /$match/, @associates) { push @associates,$match; }
	}
	close IN;
	return @associates;

	}



	sub get_url_from_clearbit {

	my ($search) = @_;

	$search =~ s/ /%20/g;
	use JSON::XS;
	my $json_text = get("https://autocomplete.clearbit.com/v1/companies/suggest?query=$search") || print "Could not access Clearbit: $! <p>";

	# Extract search results from JSON - #sk_106d8475acaa57a53f51faa04dbceb41
	my $perl_scalar = decode_json $json_text;
	#while (my ($x,$y) = each %$perl_scalar) { print "$x = $y <br>"; }
	foreach my $ps (@$perl_scalar) {
		if ($ps->{name} =~ /^$vars->{word}$/i) {
			$logo = $ps->{logo};
			$url = "http://".$ps->{domain};
			last;
			#print "Data: $ps->{name} , $ps->{domain} , $ps->{logo} <br>";
		}
	}

	return ($url,$logo,$json_text);

	}

	sub get_concept_from_wikipedia {

		my ($wikipedia) = @_;
		$wikipedia =~ s/ /_/g;
		# Will eventually fetch a description from Wikipedia
	 	return ($url,$description);
	}


	sub checkbox_style {


		return qq|

	|;
	}



	# -----------   Auto Categories --------------------------------------------------
sub autocats {

	my ($text_ptr,$table,$filldata) = @_;
	my $vars = (); if (ref $query eq "CGI") { $vars = $query->Vars; }



	# Define some fields
	my $idfield = $table."_id";
	my $tfield = $table."_title";
	my $dfield = $table."_description";
    	my $acfield = $table."_autocats";
    	my @tlist;


	if (($filldata->{$acfield} eq "") || ($vars->{autocats} eq "force")) {		# if autocats are not defined in table_authcats, then


		unless ($vars->{topicdefinitions}) {							# Get topic list (just once)
			my $tsql = "SELECT * from topic";
			my $tsth = $dbh->prepare($tsql);
			$tsth->execute();
			while (my $topic = $tsth -> fetchrow_hashref()) {
				$vars->{topicdefinitions}->{$topic->{topic_title}} = $topic->{topic_where};
				$vars->{topicids}->{$topic->{topic_title}} = $topic->{topic_id};
			}
		}

		my $tdata = $filldata->{$tfield}.$filldata->{$dfield};					# Find topics in data
		while ( my ($tx,$ty) = each %{$vars->{topicdefinitions}}) {
			if ($tdata =~ m/$ty/) { push @tlist,"$tx"; }
		}

		$filldata->{$acfield} = join ";",@tlist;						# Save the topic list in table_authcats
		# print "Autocats: $filldata->{$acfield} <br>";
		unless ($filldata->{$acfield}) { $filldata->{$acfield} = "none"; }
		&db_update($dbh,$table,{$acfield => $filldata->{$acfield}},$filldata->{$idfield});
	}

	# find List of Topics in Text  (@topiclist in $$text_ptr)
	# then store in table_authcats


	unless (@tlist) { @tlist = split ";",$filldata->{$acfield}; }

	# HTML Topics
	while ($$text_ptr =~ m/<TOPIC>(.*?)<END_TOPIC>/g) {
		my $id = $1; my $replace = "";
		foreach my $t (@tlist) {
			if ($replace) { $replace .= ", "; }
			$replace .= $t;
		}
		unless ($replace) { $replace = "None"; }
		$replace = "[Tags: $replace]";
		$$text_ptr =~ s/<TOPIC>\Q$id\E<END_TOPIC>/$replace/sig;
	}

	# XML Topics
	while ($$text_ptr =~ m/<XMLTOPIC>(.*?)<END_XMLTOPIC>/g) {
		my $id = $1; my $replace = "";

		foreach my $t (@tlist) {
			my $topicurl = $Site->{st_url} . "topic/" . $vars->{topicids}->{$t};
			$replace .= qq|      <category domain="$topicurl">$t</category>\n|;
		}
		$$text_ptr =~ s/<XMLTOPIC>\Q$id\E<END_XMLTOPIC>/$replace/sig;
	}

}


1;
