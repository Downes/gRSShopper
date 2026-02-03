


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

	$output .= qq|
	<input type="button" id="show_graph" value="Show Graph"
		onClick="window.location.href = '|.
		$Site->{st_cgi}.qq|admin.cgi?action=show_graph&table=$table&id=$id_number'" />
	<input type="button" id="build_graph" value="Build Graph"
		onClick="window.location.href = '|.
		$Site->{st_cgi}.qq|admin.cgi?action=analyze_text&analysis=new&table=$table&id=$id_number'"><p>|;

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
    print "Content-type: text/html\n\n";
		my ($dbh,$query,$table,$id) = @_;

		print "Show Graph: ".ucfirst($table)." $id <br>";

		die "Table not provided to show_graph()" unless ($table);
		die "ID not provided to show_graph()" unless ($id);
		print "Content-type: text/html\n\n";
		print &analysis_buttons($table,$id);

		my @gtables = db_tables($dbh,$query);
		my $graph = ();
		foreach my $gtable (@gtables) {
			next if ($table eq $gtable);
			push @{$graph->{$gtable}},&find_graph_of($table,$id,$gtable);
		}

		# Find last table (for drawing graph)
		my $lasttable;
		while (my($gtable,$gy) = each $graph) {	if (@{$graph->{$gtable}}) { $lasttable = $gtable; } }

		# Show it
		print "$table $id <br>";
		while (my($gtable,$gy) = each $graph) {
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

		my ($dbh,$query,$table,$id) = @_;
		my $vars = $query->Vars;


		# If this is the first associate in a new post, we will be creating a file listing all the associates
		if ($vars->{analysis} eq "new") { &clear_associates_file(); }

		my $text = &get_analysis_text($dbh,$query,$table,$id);

		# If a category has been selected for a word: present options for saving data, then exit
		if ($vars->{word} && $vars->{category}) {
				&assoc_present_save_options($dbh,$query,$table,$id,$text); exit;
		} elsif ($vars->{insert_table}) {
				&assoc_save_data($dbh,$query,$table,$id,$text);
		}

		print "Content-type: text/html\n\n";
		print &analysis_buttons($table,$id);
		print "Analyzing ".ucfirst($table)." $id...<br>";

		my @nouns = &extract_nouns($dbh,$query,$table,$id,$text);

		&evaluate_nouns($dbh,$query,$table,$id,$text,@nouns);

		exit;

}



sub get_analysis_text {

	my ($dbh,$query,$table,$id) = @_;
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
											$update_id = &update_record($dbh,$query,"link","new");
											print "$update_id <hr>";
									}
					# Otherwise, save what we got into the description and move on
					} else {
									$description = $carryover . " - " . $description;
					}

			}
			print qq|Title: "|.$title.qq|" <br>URL: $url <br>Descr: <br>$descr<hr>|;
			exit;

	} elsif ($table eq "link") {

		 $str = "title: ". $record->{$table."_title"} ." - description: ". $record->{$table."_description"};
		 $str =~ s/http/ http/g;

	} else {

			$str = $record->{$table."_description"};
	}

	 return $str;

}

sub extract_nouns {

	my ($dbh,$query,$table,$id,$str) = @_;
	# print $record->{$table."_description"},"<p>";
	#use Data::Dumper qw(Dumper);
  print "Extracting nouns<br>";


	# Define and extract the list of words @matches matching the test string
	$str =~ s/\.,!\?//g;
	my $regex = qr{\b([ie]*-?[A-Z]+[A-Za-z0-9]+.*?)\b} ;  # Test pattern
	my $teststr = $str;                                   # Test string
	$teststr =~ s/<(.*?)>//g;

	my @matches;                                       # Output
	#print qq| $regex <br> $teststr <p>|;
	if ( @matches = $teststr =~ /$regex/g ) {
			#  Add a dummy match 'EOF' to the list of matches
			my $number_of_matches = 0+@matches;
			#print qq|Found $number_of_matches matches: <br> |;
	if (@matches) { push @matches,"EOF"; }
	}

	# Define and extract the list of @associates from combinations in the test string
	my $quickprev;
	foreach my $match (@matches) {

			if ($quickprev) {

		# Create test concatinations between the previous match $quickprev and the current one
					my $quicktesta = $quickprev." ".$match;
					my $quicktestb = $quickprev." of ".$match;
					my $quicktestc = $quickprev."-".$match;

					#print qq|Looking for "$quicktesta" in string<br>|;
					if ($teststr =~ m/$quicktesta/) {

							# If we find the $quicktest in the string, we'll make it $quickprev, so we can test for even more matches
							$quickprev = $quicktesta;
							#print "Found $quicktest in string. <br>";
							next;
					 #print qq|Looking for "$quicktestb" in string<br>|;

					} elsif ($teststr =~ m/$quicktestb/) {

							# If we find the $quicktest in the string, we'll make it $quickprev, so we can test for even more matches
							$quickprev = $quicktestb;
							#print "Found $quicktest in string. <br>";
							next;

					} elsif ($teststr =~ m/$quicktestc/) {

							# If we find the $quicktest in the string, we'll make it $quickprev, so we can test for even more matches
							$quickprev = $quicktestc;
							#print "Found $quicktest in string. <br>";
							next;

					} else {

							# $quicktest wasn't there, so now we'll see is $quickprev is a common noun<br>|;
							# print "Did not find $quicktest in string. <br>";
							if (&test_word_in_file($quickprev,"common_noun")) {
									#print "'$quickprev' is a common noun. <br>";

									#Reinitialize $quickprev and move on to the next test candidate
									$quickprev = $match;
									next;
							}

							# $quickprev might have been something we skipped<br>|;
							if (&test_word_in_file($quickprev,"skipped")) {
									#print "'$quickprev' is a common noun. <br>";

									#Reinitialize $quickprev and move on to the next test candidate
									$quickprev = $match;
									next;
							}

							# If it's not a common noun and not a duplicate, add $quickprev to the associates list

					#		unless (grep( /$quickprev/, @associates )) {

								push @associates,$quickprev;
						#  }


							# And reinitialize $quickprev with the next test candidate
							$quickprev = $match;
					}
			} else {
					#print "No previous match to concatinate with. <p>";
					$quickprev = $match;
			}
	}

	return @associates;


	}

	sub evaluate_nouns {

		my ($dbh,$query,$table,$id,$str,@associates) = @_;
    print "Evaluating nouns<br>";

		# Define the list of tables we're including in our graph
		my @categories = qw(common_noun author place institution organization company product project work feed journal concept);

		# Loop through the @associates
		# print "Content-type: text/html\n\n";
		foreach my $associate (@associates) {

				# Test to see whether we've already saved the $associate as a record in the database
				# The database table will match the categories we're considering
				my $found = 0;
				foreach my $category (@categories) {

						next if ($category eq "common_noun");
						next if ($category eq "feed");

						# print qq|Looking for a "$associate" in category "$category"  <br>|;
						if (my $rid = &test_word_in_db($associate,$category)) {

							#my $rec = db_get_record($dbh,$table,{$vars->{category}."_id"=>$record_id});
							$found=1;

							# Save found associates to associates file
							# print "Add $associate : $category to associates file<br>";
							&add_to_associates_file($associate,$category);
							last;   # Last category
						}

				}


				unless ($found) {

					# If we did not find the $associate in the db...
					# Our associate is not recorded. It's new!
					# Present categorization options, which when selected will give us our 'save data' screen



					print $vars->{msg},"<p>";
					$str =~ s/$associate/<span style="color:red;">$associate<\/span>/g;
					print $str;

					# This is for handling really long files, where I don't want to show everything
					# my $prstr = &select_incontext_display($associate,$str);
					# print $prstr;print "<p>";

					print qq|
						<form method="post" action="admin.cgi">
						<input type="hidden" name="action" value="analyze_text">
						We found a new term: <input type="text" name="word" value="$associate">
						<input type="submit" name="category" value="Skip this term"><br>|;

					print qq|Suggest a different term? <input type="text" name="new_associates" size="40"><br><br>
						Pick a category for this term:|;
					foreach my $category (@categories) {+
							print qq|<input type="submit" name="category" value="$category">|;
						}
					print qq|
						<input type="hidden" name="table" value="$table">
						<input type="hidden" name="id" value="$id">
						</form>
						|;
					print &previous_next_analysis($table,$id);
					exit;
				}
		}

		# Oh? We're here?
		# This means that we're done this post
		# Every associate has been found



		print "<br>$str<br>Analysis complete. We have associated the following terms with this post:<br>";
		my @known_associates = &get_associates_file();
		my @sorted_associates = sort @known_associates;
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
			print " - $a <br>";

		};

		print qq|
			<br><form method="post" action="admin.cgi">
			<input type="hidden" name="action" value="analyze_text">|;

		print qq|<br>Suggest another term? <input type="text" name="word" size="40"><br><br>
			Pick a category for this term: |;
		foreach my $category (@categories) {+
				print qq|<input type="submit" name="category" value="$category">|;
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
	#    Saves new data submitted about an associated term (or 'associate')
	#

sub assoc_save_data {

	my ($dbh,$query,$table,$id,$str) = @_;

		print "Content-type: text/html\n\n";
		print "Saving data - assoc_save_data<p>";

		# First, save any new_genres, new_categories or new_types that may have been created
		my @sorters = qw(genre category type);
		foreach my $sorter (@sorters) {
			if($vars->{"new_".$sorter}) {

				# Get existing optlist data
				my $optlist_record = &db_get_record($dbh,"optlist",{optlist_title => $vars->{insert_table}."_".$sorter});
				my $optlist_id = $optlist_record->{optlist_id};
				my $optlist_data = $optlist_record->{optlist_data};
				my @optlist_data_array = split ";",$optlist_data;

				# Generate new optlist data
				$optlist_id ||= "new";
				my $sorter_val = lc($vars->{"new_".$sorter});			# Standardizing
				my $sorter_tit = ucfirst($sorter_val);						# capitalization
				unless ($optlist_data =~ /$sorter_tit.",".$sorter_val/) { # prevent duplicates
					push @optlist_data_array, $sorter_tit.",".$sorter_val; }

				# Save optlist record
				$vars->{optlist_data} = join ";",@optlist_data_array;
				$vars->{optlist_table} = $vars->{insert_table};
				$vars->{optlist_field} = $sorter;
				my $rid = &update_record($dbh,$query,"optlist",$optlist_id);
				unless ($rid) { die "Failed to update optlists properly."; }

			}

		}



		# Second, save the word data itself as a new record
		my $name_or_title = &get_key_namefield($vars->{insert_table});
		$vars->{$vars->{insert_table}."_id"} = "new";

		if ($vars->{$name_or_title}) {

					 unless ($update_id = &update_record($dbh,$query,$vars->{insert_table},$vars->{$vars->{insert_table}."_id"})) {
								die "Update record failed for some reason, $vars->{insert_table} : $vars->{$name_or_title}"; }

					 # print "Updated in table ".$vars->{insert_table}." as id $update_id<br>";
					 if ($update_id eq "duplicate") {
						   #$update_id = &db_locate();
							 unless ($update_id) { die "Failed to locate record even though it was flagged as a duplicate";}
					 }

					 &add_to_associates_file($vars->{$name_or_title},$vars->{insert_table});


		}

	# Third, create associations in the graph
	my @associates = split ",",$vars->{associates};
	foreach my $associate (@associates) {

		# Do not associate duplicates; the record was never created
		#last if ($update_id eq "duplicate");

		# For each associate listed in the imput form

		# get the category and title
		my ($category,$title) = split ":",$associate;

		# If the associate can be found (as it always should be)
		if (my $associate_id = &test_word_in_db($title,$category)) {
			# Create the graph record
			my $graph_id = &db_insert($dbh,$query,"graph",{
				graph_tableone=>$vars->{insert_table}, graph_idone=>$update_id,
				graph_tabletwo=>$category, graph_idtwo=>$associate_id,
				graph_creator=>$Person->{person_id}, graph_crdate=>time, graph_type=>'assoc', graph_typeval=>''});
			#print "Associated $vars->{insert_table}:$update_id and $category:$associate_id as graph entry $graph_id<br>";
		}
	}
	}


	#
	#    Either adds the new word to the 'common terms' list and discards
	#    or sets up a content submission for the new term
	#

	sub assoc_present_save_options {

		my ($dbh,$query,$table,$id,$str) = @_;
		my $vars = $query->Vars;
		my $table = $vars->{table}; my $id = $vars->{id};
    # print "Assoc present save options <br>";
		# Override the selected word with the new suggested word input by the user, if any
		if ($vars->{new_associates}) { $vars->{word} = $vars->{new_associates}; }

		# Define the list of tables we're including in our graph
		my @categories = qw(author place institution organization company product project work feed journal concept);

		# If it's a common noun or a word we've chosen to skip
		if ($vars->{category} eq "Skip this term") { $vars->{category} = "skipped"; }
		if ($vars->{category} eq "common_noun" || $vars->{category} eq "skipped") {
			# print qq|The common noun was "$word"|;

			# Save it if necessary
			unless (&test_word_in_file($vars->{word},$vars->{category})) {
				&add_word_to_file($vars->{word},$vars->{category});
			}

		# Then bail
		print "Content-type: text/html\n";
		print "Location: $Site->{st_cgi}admin.cgi?table=$table&id=$id&action=analyze_text\n\n";
		exit;

	}



	# set up a content submission for the new term
	# Set up form variables
	my $new_record_form = "";
	my $associates_form = "";
	my $insert_table = $vars->{category};
	my $name_or_title = &get_key_namefield($insert_table);
	my $record_id = "new";

	# We're going to create a new record as part of our input

	# Define variables
	my $url; my $logo;
	my $search = $vars->{word}; my $wikipedia = $vars->{word};
	$search =~ s/ /%20/g;
	$wikipedia =~ s/ /_/g;


	# Search Clearbit for url and logo
	if ($vars->{category} eq "company" || $vars->{category} eq "institution"
			|| $vars->{category} eq "organization" || $vars->{category} eq "product") {

			($url,$logo,$json_text) = &get_url_from_clearbit($search);
			if ($url) { $new_record_form .=  $json_text."<p>"; }


	# Search Wikipedia for information about concepts
	} elsif ($vars->{category} eq "concept") {
		$url = "https://en.wikipedia.org/wiki/".$wikipedia;
	}

	# get the list of catgeories, genres and format selection
	my $category_text =  &form_optlist("",$insert_table,"new",$insert_table."_category","none","none","none",0);
	my $genre_text =  &form_optlist("",$insert_table,"new",$insert_table."_genre","none","none","none",0);
	my $type_text =  &form_optlist("",$insert_table,"new",$insert_table."_type","none","none","none",0);

	# Set up the 'new record' part of the form
	$new_record_form .= qq|
			<input type="text" size=40 name="$name_or_title" value="$vars->{word}">
			(<input type="text" size=10 name="|.$insert_table.qq|_acronym">)
			<input type="text" name="insert_table" value="$vars->{category}"><br>

			URL: <input type="text" name="|.$insert_table.qq|_url" value="$url" size=60>
			[<a href="$url" target="new">Test</a>]
			[<a href="http://www.google.com?q=$search" target="new">Search</a>]<br>

			Logo: <input type="text" name="|.$insert_table.qq|_logo" value="$logo" size=60>
			[<a href="$logo" target="new">Test</a>]
			[<a href="http://www.google.com?q=$search" target="new">Search</a>]
						<br>
						Description:<br>
						<textarea cols=60 rows=5 name="|.$insert_table.qq|_description"></textarea><br>
						<table border=1 cellpadding=3 cellspacing=0><tr>
						<td valign="top">Category:</td><td>$category_text
						 Or new: <input type="text" size=20 name="new_category"></tr>
						<tr><td valign="top">Genre:</td><td>$genre_text
						 Or new: <input type="text" size=20 name="new_genre"><br><br>

						<tr><td valign="top">Type:</td><td>$type_text
						 Or new: <input type="text" size=20 name="new_type"></td></tr>
						</table>
		|;

	#Set up form for associations
	# Note that new associations could be defined for existing records, based on the current data

	# Get all of the associates for this post, which we saved earlier
	# print "Getting associates file...<br>";
	my @associates = get_associates_file();

	# Suggested Associates  in $vars->{new_associates}
	my @new_associates = split ",",$vars->{new_associates};
	foreach my $new_associate (@new_associates) {
				foreach my $acat (@categories) {
					 my $arecord_id = &test_word_in_db($new_associate,$acat);
							 if ($arecord_id ne "new" && $arecord_id) {
									 $associates_form .= qq|<input type="checkbox" value="$acat:$new_associate" name="associates" checked> $acat: $new_associate <br>|;
							 }
				}
	}

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
		$associates_form .= qq|<input type="checkbox" value="$acategory:$aword" name="associates" checked> $acategory: $aword <br>|;
	}




	# Print the form
	print "Content-type: text/html\n\n";
	print &analysis_buttons($table,$id);
	print &checkbox_style();
	print qq|
		<form method="post" action="admin.cgi">
		<input type="hidden" name="action" value="analyze_text">
		<input type="hidden" name="table" value="$table">
		<input type="hidden" name="id" value="$id">
		$new_record_form
		<br><br>Associate with:<br>
		$associates_form
		<br><br><input type="submit" value="Submit data"><p>
		</form>
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
sub test_word_in_file {

	my ($word,$category) = @_;

	#print "Content-type: text/html\n\n";
	#print qq|Testing $word in $category <p>|;

  # Open the file
	my $filename = $Site->{st_urlf}."files/".$category.".txt";
	open(FILE,$filename);

	# Looking for an exact match in a line
	if (grep{/^$word\n/} <FILE>){
		#print qq|<b>The word "$word" was found $filename.</b><br>|;
		close FILE; return 1;
	}

	#print qq|The word "$word" was not found in $filename.<br>|;
	close FILE; return 0;

}

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

sub clear_associates_file {

	
	my $filename = $Site->{st_urlf}."files/associates.txt";
	open OUT,">$filename" or die "Could not open $filename $!";
	print OUT "" or die "Could not append to $filename $!";
	close OUT;

	# We'll also clear the 'words skipped' file
	my $filename = $Site->{st_urlf}."files/skipped.txt";
	open OUT,">$filename" or die "Could not open $filename $!";
	print OUT "" or die "Could not append to $filename $!";
	close OUT;

	#print qq|Content in associates.txt erased <br>|;

}

	sub get_url_from_clearbit {

	my ($search) = @_;

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


	 return ($url,$description);
	}


	sub checkbox_style {


		return qq|


						 <style>

	/* Form Styles */


	.form {
	max-width: 610px;
	margin: 60px auto;
	}

	.form__answer {
	display: inline-block;
	box-sizing: border-box;
	width: 150;
	margin: 2px;
	height: 20px;
	vertical-align: top;
	font-size: 14px;
	text-align: center;
	}

	label {
	border: 1px solid black;
	box-sizing: border-box;
	display: block;
	height: 20px;
	width: 100%;
	padding: 3px;
	cursor: pointer;
	opacity: .5;
	transition: all .5s ease-in-out;
	&:hover, &:focus, &:active {
		border: 1px solid red;
	}
	}

	/* Radio Input style */

	input[type="radio"] {
	opacity: 0;
	width: 0;
	height: 0;
	}

	input[type="radio"]:active ~ label {
	opacity: 1;
	}

	input[type="radio"]:checked ~ label {
	opacity: 1;
	border: 1px solid green;
	background-color:#e0e0e0;
	}


	/* Checkbox Input style */

	input[type="chackbox"] {
	opacity: 0;
	width: 0;
	height: 0;
	}

	input[type="checkbox"]:active ~ label {
	opacity: 1;
	}

	input[type="checkbox"]:checked ~ label {
	opacity: 1;
	border: 1px solid green;
	background-color:#e0e0e0;
	}

		</style>

	|;
	}


1;
