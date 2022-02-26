
	#-------------------------------------------------------------------------------
	#
	#   Search Functions
	#
	#-------------------------------------------------------------------------------
sub find_by_title {

	my ($dbh,$table,$title) = @_;
	return unless (defined $table);
	$title =~ s/%20/ /g;
	$title =~ s/  / /g;
   	my $vars = (); if (ref $query eq "CGI") { $vars = $query->Vars; }

				# Find and return ID number for title
	my $tfield;
	if ($table =~ /author|person/) { $tfield = $table."_name"; }
	else {$tfield = $table."_title"; }

	if ($title =~ /(.*?) - (.*?)/) {
		$vars->{table} = "feed";
		return $1;
	}

	my $newid = &db_locate($dbh,$table,{$tfield => $title});
	if ($newid) { return $newid; }

				# For select tables, autocreate the record if it doesn't exist
				# Works only for links from the site

	return unless ($ENV{'HTTP_REFERER'} =~ $Site->{st_url});
	if ($table =~ /journal/) {
			$newid = &db_insert($dbh,$query,$table,{journal_title => $title});
	} elsif ($table =~ /author/) {
			$newid = &db_insert($dbh,$query,$table,{author_name => $title});
	}
	return $newid;
}

	#-------------------------------------------------------------------------------
	#
	# -------   Find Records ------------------------------------------------------
	#
	#		$terms is a hash of vield values eg. $terms->{post_id} = 12
	#		$terms must include   table=>$table
	#		to use > or < do this:   field=>">$value" or field=>"<$value"
	#		this finction treats search terms as a conjunction
	#		use com=>"OR" to treat as disjunction
	#		use number=>$num to specify a limit
	#		use sort=>$field to specify a sort (or sort=>"$field DESC")
	#	      Edited: 31 July 2010
	#
	#-------------------------------------------------------------------------------
sub find_records {

	my ($dbh,$terms) = @_;						# Default Parameters
	return unless (defined $dbh && $dbh);
	return unless (defined $terms && $terms);
	return unless (defined $terms->{table} && $terms->{table});
	unless (defined $terms->{com} && $terms->{com}) {$terms->{com} = " AND "; }

	my @fields_array; my @values_array;						# Create SQL Statement
	while (my($sx,$sy) = each %$terms) {
		next if ($sx =~ /^(sort|number|table|com)$/);
		my $rel = "=";
		if ($sy =~ /^</) { $rel="<"; $sy=~s/<//; }
		if ($sy =~ /^>/) { $rel=">"; $sy=~s/>//; }
		push @fields_array,$sx.$rel."?";
		push @values_array,$sy;
	}
	my $fieldstring = join $terms->{com},@fields_array;
	my $sql = "SELECT " . $terms->{table} . "_id" . " FROM " . $terms->{table};
	if ($fieldstring) { $sql .= " WHERE " . $fieldstring; }
	if (defined $terms->{sort} && $terms->{sort}) {
		$sql .= " ORDER BY ".$terms->{sort};
	}
	if (defined $terms->{number} && $terms->{number}) {
		$sql .= " Limit ".$terms->{number};
	}

	my $sth = $dbh->prepare($sql);						# Execute Search
	return $dbh->selectcol_arrayref($sth, {}, @values_array);

}
sub search {

	my ($dbh,$query) = @_;
 print "Content-type: text/html; charset=utf-8\n\n";
 	my $vars = (); if (ref $query eq "CGI") { $vars = $query->Vars; }


						# Initialize Page
	my $page = gRSShopper::Page->new;
	$page->{table} = $vars->{table} || "post";
	$page->{format} = $vars->{format} || "html";
	$page->{title} = "Search ".ucfirst($page->{table})."s";

						# Permissions

	return unless (&is_allowed("view",$page->{table}));

						# Header
	$page->{page_format} = $format;
	$page->{page-title} = "Search ".ucfirst($table)."s";
	$page->{page_content} = &get_template("page_header",$page,$page->{format});
	$page->{page_content} .= "<h3>$page->{title}</h3>";


						# Compile SQL 'Where' Statement
	my @conjuncts = ();
	my @columns = &db_columns($dbh,$page->{table});
	while (my($cx,$cy) = each %$vars) {

		next if ($cx eq "format");
		my @disjuncts = ();
		$vars->{$cx} =~ s/\0//g;
		$cy =~ s/\0//g;

		my @flds = split /,/,$cx;
		foreach my $fld (@flds) {


			next unless ($cy);
			my $field = $page->{table}."_".$fld;
			next unless (&index_of($field,\@columns)>-1);
			$cy =~ s/'/&apos/g;		#'
			if ($cy =~ /\|/) {
				push @disjuncts,"($field REGEXP '$cy')";
			} else {
				push @disjuncts,"($field LIKE '%$cy%')";
			}


		}
		my $searchvar = join " OR ",@disjuncts;
		next unless ($searchvar);
		$searchvar = "(".$searchvar.")";
		push @conjuncts,$searchvar;

	}
	my $where = join " AND ",@conjuncts;
	if ($where) { $where = "WHERE ".$where; }


						# Count Results

	my $count = &db_count($dbh,$page->{table},$where);
 $output .= "Where: $where print Count $count <p>";

						# Set Sort, Start, Number values

	my ($sort,$start,$number,$limit) = &sort_start_number($vars,$page->{table});
	$page->{page_content} .= qq|<p id="listing">Listing $start to |.($start+$number)." of $count ".$page->{table}."s found</p>";



						# Execute SQL search

	my $stmt = qq|SELECT * FROM $page->{table} $where $sort $limit|;
	unless ($vars->{start}) { $vars->{start} = 0; }
	my $sthl = $dbh->prepare($stmt);
	$sthl->execute();



	while (my $list_record = $sthl -> fetchrow_hashref()) {


		$vars->{comment} = "no";		# Suppresss comment form in results

		my $record = gRSShopper::Record->new;
		$record->{data} = $list_record;
		my $type = $list_record->{post_type};


						# Set Record Format
		my $record_format = lc($page->{format});							# default record format
		if ($record_format =~ /html/i) { $record_format = "summary"; }			# special case for HTML pages


						# Format Record

		my $record_text = &format_record($dbh,
			$query,
			$page->{table},
			$record_format,
			$list_record);

		$page->{page_content} .=  $record_text;

	}


						# Next Button
  #	if ($page->{format} eq "html") {
		$page->{page_content} .= &next_button($query,$table,$page->{format},$start,$number,$count);
  #	}

						# Footer
	$page->{page_content} .= 
		&get_template("page_footer",$page,$page->{format});
	



						# Format Content

	&format_content($dbh,$query,$options,$page);
	$page->print;
	$sthl->finish();
	exit;


}

	#
	# -------  Sort, Start and Number --------------------------------------------------------
	#
	#          Determine values for sort, start and number
	#          Called from list()
	#	     Edited: 27 March 2010
	#
sub sort_start_number {

	my ($vars,$table) = @_;


						# Number

	my $number = $vars->{number} || $Site->{st_list} || 40;
 #	print "Number: $number <br>";

						# Sort
	my $sort = "ORDER BY ";
	if ($vars->{sort}) {
		$sort .= $vars->{sort};
	} else {
		if ($table =~ /box|view|feed|field|page|topic|template|optlist|form/) {
			$sort .= $table."_title" ;
		} elsif ($table =~ /person/) {
			$sort .= $table."_name";
		} elsif ($table =~ /event/) {
			$sort .= $table."_start DESC";
		} elsif ($table =~ /link/) {
			$sort .= $table."_id DESC";
		} else {
			$sort .=  $table."_crdate DESC";
		}
	}
 #	print "Sort: $sort <br>";

						# Start
	my $limit = "";
	if ($vars->{start}) {
		$limit = " LIMIT $vars->{start},$number";
	} else {
		$limit = " LIMIT $number";
	}
	my $start = $vars->{start};
	unless ($start) { $start = 0; }

	return ($sort,$start,$number,$limit);
}



sub list_tables {

  # Try to display from cache in cgi-bin/data/tables
	my $tab = lc($vars->{tab});
	&quick_show_page("","data","tables-".$tab);

	my @tables = $dbh->tables();
	my $output;

	# Restrict to Admin
#	&admin_only();

	# If needed, get form data (tells us what to list, based on tab) - eg. If tab is Read, then to view, form_read="yes" for the given table
	my @filter;
	if ($tab) {
		@filter = &db_get_record_list($dbh,"form",{"form_".$tab => "yes"},"form_title");
	}



	# For each table in tables()
	foreach my $table (@tables) {

		$table =~ s/`//ig;   #`

		# Normalize the table name (it comes out of tables() as `dbname.tablename` )
		my ($tdb,$tname) = split /\./,$table; unless ($tname) { $tname = $tdb; }

		# Make sure the user is allowed to view the table, and that it's in the list for this tab
	#	next unless (&is_viewable("nav",$tname));
	#	if (@filter) { next unless (my ($matched) = grep $_ eq $tname, @filter); }

		# Format the output
		# Open Main: url,cmd,db,id,title,starting_tab
		my $onclickurl = $Site->{st_cgi}."api.cgi";
		$output .= qq|<li class="table-list-element">|;
		if ($tab eq "make") { 
			$output .= qq| [<a href="#" onClick="
			openTab(event, 'editor', 'mainlinks');
			openDiv('$onclickurl','editor','edit','$tname','new','','Edit');
			">New</a>]|; }

		if ($tab eq "find") { 
			$output .= qq| [<a href="#" onClick="
			openDiv('$onclickurl','main','import','$tname','','','Import');
			">Import</a>]|; }

# loadList({div:'Read',cmd:'list',table:'link'});

		my $fspecial = "";			# Special for feed, limit default to Approved
		if ($tname eq "feed") {	$fspecial = ",status:'A'" }
		$output .= qq|[<a href="#" 
			onClick="
			openTab(event,'List','tablinks','list-button');
			loadList({div:'List',cmd:'list',table:'$tname'$fspecial});
			">List</a>] |.
    	ucfirst($tname).qq| </li>\n		|;

# read_into({div:'List',url:'$onclickurl',cmd:'list',table:'$tname'});
	}

	# Return nicely formatted output

  $output = qq|<ul class="table-list">|.$output.qq|</ul>|;

	# Print Cache version to file
	my $page_file = $Site->{st_cgif}."data/tables-".$tab;
	open FILE, ">$page_file" or die "Could not open $page_file $!";
	print FILE $output;
	close FILE;

	print $output;
		print "NOT Printed from cache";
	return ;

}

# -------------------------------------------------------
#           List Records
#
#           Requires a table and set of key-value parameters
#           Returns a list header with metadata
#           and a list array with results
#
# -------------------------------------------------------


sub list_records {

	my ($table,$parms) = @_;
	my $vars = $query->Vars;
	my $output = "";
	my $onclickurl = $Site->{st_cgi}."api.cgi";
#print "Content-type: text/html\n\n";	
#while (my ($px,$py) = each %$parms) { print "$px = $py \n";}
	$vars->{where} =~ s/[^\w\s]//ig;	# chars only, no SQL injection for you
	my $format = $vars->{format};		# Output Format

	if ($parms->{id} eq "latest") { 	# Special filter for id=latest
		$parms->{id} = db_get_single_value($dbh,$table,$table."_id","",$table."_crdate DESC");
	}


	# Set Sort, Start, Number values`
	my ($sort,$start,$number,$limit) = &sort_start_number($parms,$table);
	$parms->{sort} = $sort;
	$parms->{start} = $start+1;
	$parms->{number} = $number;


	# Set Conditions Related to Permissions
	my $permtype = "list_".$table; 


#	if ($Site->{$permtype} eq "owner" && $Person->{person_status} ne "admin") {
#			$where = "WHERE ".$table."_creator = '".$Person->{person_id}."'";

#	} else { $where = ""; }


	# Set Search Conditions

	if ($vars->{titname}) { $titname = $vars->{titname}; }
	elsif ($table =~ /^author$|^person$|^badge$/) { $titname = "name"; }
	else { $titname = "title"; }
	my $p = $table."_"; unless ($titname =~ m/$p/) { $titname = $p. $titname; }

	my $where = "";

	if ($vars->{where}) {
		my $w = "where ".$titname." LIKE '%".$vars->{where}."%'";
		if ($where) {
	#		$where .= "($where) AND ($w)";
		} else {
	#		$where .= $w;
		}
	}


	if ($parms) {

		my @columns = &db_columns($dbh,$table);
		my @wherelist;
	
	
		while (my ($px,$py) = each %$parms) { 

			next if ($py eq "" || $py eq "all");		# Don't filter by nothing or everything

		
			# Don't search for search conditions
			# If you want to search for the value, use the full field name, eg. 'event_start' 
			# and not 'start'
			next if ($px =~ /table|number|limit|sort|start|finish/);	 

			my $tablelead = $table."_";					# Normalize field name
			unless ($px =~ /$tablelead/) { $px = $tablelead.$px; }
			next unless (grep( /^$px$/, @columns));		# Don't search in non-existent columns

		


			if ($px =~ /_category|_genre|_status|_section|_class|_type|_id/) {  	# Parameters for filter
				push @wherelist,qq|($px = '$py')|; 
			} else {													# Text search, uses 'LIKE'
				push @wherelist,qq|($px LIKE '\%$py\%')|;
			}

		}
		$where .= join ' AND ',@wherelist;

	} 

	if ($where) { $where = "WHERE ".$where; }


	# Count Total Number of Items
	my $count;
#print "My table is $table <p>";
  	if ($where) { $count = &db_count($dbh,$table,$where); } else { $count = &db_count($dbh,$table); }
	$parms->{count} = $count;
	if ($start+$number > $start+$count) { $parms->{end} = $start+$count;} 
	else {$parms->{end} = $start+$number;}

	# Execute SQL search
	my $stmt = qq|SELECT * FROM $table $where $sort $limit|;

	my $sthl = $dbh->prepare($stmt);
	$sthl->execute();
	if ($sthl->errstr) { print "Content-type: text/html\n\n";print "DB LIST ERROR: ".$sthl->errstr." <p>"; exit; }

#print "Results:  from $stmt\n";

	#if ($table eq "media" || $table eq "link" || $table eq "feed") {
	#if ($table eq "media" || $table eq "link" || $table eq "feed") {
		my $listarray;
		my $feeds_data;	# Cache, so we don't reload feed info for each item
		while (my $list_record = $sthl -> fetchrow_hashref()) {

			my $id = $list_record->{$table."_id"};  # So the record is $table $id
			# Unescape data that was escaped for storage
			while (my($lx,$ly) = each %$list_record) {
				if ($list_record->{$lx}) {
					$list_record->{$lx} =~ s/&amp;/&/g;
				}
			}

#print "List record $id \n";

			# Provide default titles
			unless ($list_record->{$table."_title"} || $list_record->{$table."_name"}) {
				$list_record->{$table."_title"} = "Untitled";
				$list_record->{$table."_name"} = "Nameless";
			}
			my $itemdata;

			# Basic list data, always sent
			foreach my $field (qw(title name mimetype url link id section genre category status)) {
				 $itemdata->{$field} = $list_record->{$table."_".$field}; 
			}

						
			# Large list data, sent if 'cmd' == 'show'
			if ($parms->{cmd} eq "show") {

				# Content
				foreach my $field (qw(description content)) {
					$itemdata->{$field} = $list_record->{$table."_".$field};

					# Some formatting, to make it easier to read
					$itemdata->{$field} =~ s/\n\n/\n/g;				# Eliminate double line feeds
					$itemdata->{$field} =~ s/\n/<\/p>\n<p>/ig;		# Add some paragraphs
					$itemdata->{$field} = "<p>".$itemdata->{$field}."</p>";  # wrap it

				}

				# Get the previous and next records
				$sort ||= "crdate";
 				my $nextdata = &get_next($dbh,$table,$id,$sort,$where,$list_record);
				foreach my $field (qw(first last prev next)) {
					$itemdata->{$field} = $nextdata->{$field};
					#$itemdata->{$table."_".$field} = $nextdata->{$field};
				}

				# Get the linked data from feed

				my @connections = &find_graph_of($table,$id,"feed");
				foreach my $feed (@connections) {
					my $feeditem;
					unless ($feeds_data->{$feed}) {  # If it's not in cache get it from db and save into cache
						$feeditem = &db_get_record($dbh,"feed",{feed_id=>$feed});
						$feeds_data->{$feed} = $feeditem;
					}
					$feeditem = $feeds_data->{$feed}; # get from cache
					foreach my $field (qw(title name url link id category genre status section)) {
						$itemdata->{"feed_".$field} = $feeditem->{"feed_".$field};
					}
				}
			}
			push @$listarray,$itemdata;
		}

		$parms->{newtest} = "New Test";
		return ($parms,$listarray);
	#}





	# print Search form
	$output .=  qq|<div class="table-list-heading">
	   <span title="Search" onClick="toggle_visibility('$tab-search-box');"  ><i class="fa fa-search"></i></span>|;
	$output .= qq|<div id="$tab-search-box" style="display:none;">|.&list_search_form($table).qq|</div>|;

	# Print Page Header
	$start ||= 1;
	my $end; if ($count > ($start+$number)) { $end = $number; } else { $end = $count; }
	my $plural = PL($table,$count);
	$output .=  qq| Listing $start to $end of $count $plural|;
	if ($vars->{where}) { my $f = $vars->{titname}; my ($a,$b) = split "_",$titname; $output .= qq|<br>Searching for '|.$vars->{where}.qq|'' in |.ucfirst($b); }
	$output .=  qq|</div>\n|;


	# Print the output for each item
    $output .= qq|<ul class="table-list">|;
	while (my $list_record = $sthl -> fetchrow_hashref()) {

		my $rid = $list_record->{$table."_id"};
    	my $record_text = "";

		# Special for Author
		if ($table eq "author_list") {
			$output .= qq|$list_record->{author_list_id}
			 Author <a href="http://www.downes.ca/author/$list_record->{author_list_author}">$list_record->{author_list_author}</a> $list_record->{author_list_table}
			 <a href="http://www.downes.ca/$list_record->{author_list_table}/$list_record->{author_list_item}">$list_record->{author_list_item}</a>
			 <br>|; next;
		}
	$format = "";
		# Format Record 
		if ($format) {
			$record_text = &format_record($dbh,$query,$table,$format,$list_record,1);
		}


    	# If format_record() returns no result, print raw list 
		unless ($record_text) {

			# Generate a listing from basic data
			my $record_title = $list_record->{$table."_title"}
				|| $list_record->{$table."_name"}
				|| $list_record->{$table."_noun"}
				|| $list_record->{$table."_id"};


      		my $recordstatus = "";

			# Special handling for APIs
			if ($vars->{cmd}) {

				if ($table eq "feed") {
					unless ($list_record->{$table."_link"}) { $list_record->{$table."_status"} = "B"; }
					$recordstatus = qq|<img src="$Site->{st_url}assets/img/|.$list_record->{$table."_status"}.qq|tiny.jpg">|;
				}

         		# Open Main: url,cmd,db,id,title,starting_tab
          		my $starting_tab = "Edit";
				if ($table eq "person") { $starting_tab = "Identity-tab"; }

				# Define the full record text
		      	$record_text = qq|
			       <li class="table-list-element list-result" id="$table-$rid">
			         <span title="Edit" 
			  		   onClick="openDiv('$onclickurl','main','edit',
			  		   '$table','$rid','$starting_tab');">$recordstatus $record_title</span>
				   </li>|;
			}

			# Default Handling, old admin.cgi style
			else {

			  $record_text = qq|
			    <li class="table-list-element">[<a href="$Site->{st_cgi}admin.cgi?action=edit&$table=$rid">Edit</a>]
		  	  [<a href="javascript:confirmDelete('$Site->{st_cgi}admin.cgi?action=Delete&$table=$rid')">Delete</a>]
		    	<a href="$Site->{st_url}$table/$rid">$record_title</a></li>
		  	|;

		  }
		}


		# Print record to output string

		$output .=  $record_text;

	}
  	$output .= "</ul>";

	# print 'Next' information to output string
	$output .=  &next_button($query,$table,"list",$start,$number,$count,1);

	$sthl->finish( );

	return $output;
}
sub list_search_form {

  my ($table) = @_;

  # Set up list of serach field options
	my $titoptions = "";
	my @columns = &db_columns($dbh,$table);
	my @selections = qw(name title description content code email link type id);
	foreach my $sc (@selections) {
      my $field = $table."_".$sc;
		  if (grep { /$field/ } @columns) { $titoptions  .= qq|<option value="|.$table.qq|_$sc">$sc</option>\n|; }
	}

	my $hidden_input = qq|
	   <input type="hidden" name="db" value="$table">
     <input type="hidden" name="table" value="$table">
	   <input type="hidden" name="action" value="list">
	   <input type="hidden" name="cmd" value="list">
	   <input type="hidden" name="obj" value="record">
	|;

	# Print Search Form
  $vars->{start} = 0;
	$output .= qq|
		<form method="post" id="$table-search-form"
		   action="javascript:list_form_submit('|.$Site->{st_cgi}.qq|api.cgi','$table-search-form');"> &nbsp;
		$hidden_input
    <table style="width:100%;">
    <tr><td style="width: 3em;">In:</td>
		<td style=""><select name="titname">$titoptions</select></td></tr>

		<tr><td style="width: 3em;">Sort:</td>
		<td style=""><select name="sort">
		$titoptions
		<option value="|.$table.qq|_crdate">Oldest First</option>
		<option value="|.$table.qq|_crdate DESC">Newest First</option>
		</select></td></tr>
		<tr><td style="width: 3em;">Find:</td>
		<td style=""><input name="where" width="40"></td></tr>|;


		if ($table eq "feed") {  	# Make some special buttons for feeds
         my $imgdir = $Site->{st_url}."assets/img";
		     $output .= qq|<tr><td  style="width: 3em;" colspan=2>
						 <input type="checkbox" name="feed_status" value="On Hold"> <img src="$imgdir/Otiny.jpg"> On Hold <br />
						 <input type="checkbox" name="feed_status" value="Active"> <img src="$imgdir/Atiny.jpg">Active <br />
						 <input type="checkbox" name="feed_status" value="Retired"> <img src="$imgdir/Rtiny.jpg"> Retired <br />
						 <input type="checkbox" name="feed_status" value="Unlinked"> <img src="$imgdir/Btiny.jpg"> Unlinked  <br />
        </td></tr>
			  |;
		}

			$output .= qq|
		<tr><td style="width: 3em;" colspan=2><input type="submit" value="List Again"></td></tr></table>

		</form></p>|;
	if ($vars->{where}) { $output .= "<p>Searching for  $vars->{where} </p>"; }

  return $output;


}



1;

