
	#----------------------------- Save Graph ------------------------------
sub save_graph {


	my ($type,$recordx,$recordy,$typeval) = @_;
  #$Site->{diag_level} = 1;


							# Set default values
	my $tabone = $recordx->{type}; unless ($tabone) { &diag(7,"Graph error 1"); return; }

	my $idone = $recordx->{$tabone."_id"}; unless ($idone) { &diag(7,"Graph error 3"); return; }
	my $urlone; if ($tabone eq "feed") { $urlone = $recordx->{$tabone."_html"}; }
	elsif ($tabone eq "media") { $urlone = $recordx->{$tabone."_url"}; }
	else { $urlone = $recordx->{$tabone."_link"}; }
	unless ($urlone) { $urlone = $Site->{st_url}.$tabone."/".$idone; }
	my $baseone = "one"; if ($urlone =~ m/http:\/\/(.*?)\//) { $baseone = $1; }

	my $tabtwo = $recordy->{type}; unless ($tabtwo) { &diag(7,"Graph error 2"); return; }
	my $idtwo = $recordy->{$tabtwo."_id"} || "-1";
	my $urltwo; if ($tabtwo eq "feed") { $urltwo = $recordy->{$tabtwo."_html"}; }
	elsif ($tabtwo eq "media") { $urltwo = $recordy->{$tabtwo."_url"}; }
	else { $urltwo = $recordy->{$tabtwo."_link"}; }
	my $basetwo = "two"; if ($urltwo =~ m/http:\/\/(.*?)\//) { $basetwo = $1; }
	unless ($urltwo) { $urltwo = $Site->{st_url}.$tabtwo."/".$idtwo; }

							# Graph distinct entities only

	if (($tabone eq $tabtwo) && (($idone eq $idtwo) || ($urlone eq $urltwo))) { &diag(7,"Graph error 4"); return; }
	if (($tabone eq $tabtwo) && ($baseone eq $basetwo)) { &diag(7,"Graph error 5"); return; }

							# Uniqueness constraint


	if (&db_locate($dbh,"graph",{
		graph_tableone=>$tabone, graph_idone=>$idone, graph_urlone=>$urlone,
		graph_tabletwo=>$tabtwo, graph_idtwo=>$idtwo}, graph_urltwo=>$urltwo))
		{ &diag(7,"Graph error 6 - uniqueness"); return; }

	my $crdate  = time;
	my $creator = $Person->{person_id};

							# Create Graph Record

  #	print qq|------ Save Graph: [<a href="$urlone">$tabone $idone</a>] $type [<a href="$urltwo">$tabtwo $idtwo</a>]<br>|;
	my $graphid = &db_insert($dbh,$query,"graph",{
		graph_tableone=>$tabone, graph_idone=>$idone, graph_urlone=>$urlone,
		graph_tabletwo=>$tabtwo, graph_idtwo=>$idtwo, graph_urltwo=>$urltwo,
		graph_creator=>$creator, graph_crdate=>$crdate, graph_type=>$type, graph_typeval=>$typeval});


	return $graphid ||  &diag(7,"Graph error 6");
	return;



}

# Add a new graph entry

sub graph_add {

	my ($tabone,$idone,$tabtwo,$idtwo,$type,$typeval) = @_;
  my $crdate = time;
  my $creator = $Person->{person_id} || $Site->{context};
	# Return if it already exists
	if ($eid = &db_locate($dbh,"graph",{
		graph_tableone=>$tabone, graph_idone=>$idone,
		graph_tabletwo=>$tabtwo, graph_idtwo=>$idtwo} ))
		{ return "Exists - $eid"; }

  # Otherwise, Create Entry
	my $graphid = &db_insert($dbh,$query,"graph",{
		graph_tableone=>$tabone, graph_idone=>$idone,
		graph_tabletwo=>$tabtwo, graph_idtwo=>$idtwo,
		graph_creator=>$creator, graph_crdate=>$crdate, graph_type=>$type, graph_typeval=>$typeval});

	return $graphid;
}

# remove a graph Entry

sub graph_delete {

		my ($tabone,$idone,$tabtwo,$idtwo,$type) = @_;
    my $return = 0;

		if ($type) {

			while (my $graphid = &db_locate($dbh,"graph",{
				graph_tableone=>$tabone, graph_idone=>$idone,
				graph_tabletwo=>$tabtwo, graph_idtwo=>$idtwo, graph_type=>$type} )){

				   &db_delete($dbh,"graph","graph_id",$graphid);
					 $return = 1;

			}


		} else {

			while (my $graphid = &db_locate($dbh,"graph",{
				graph_tableone=>$tabone, graph_idone=>$idone,
				graph_tabletwo=>$tabtwo, graph_idtwo=>$idtwo} )){

					&db_delete($dbh,"graph","graph_id",$graphid);
					$return = 1;

			}

	  }
	  $return;
}

# Get a list of graph items related to a graph items
sub graph_list {

	my ($tableone,$idone,$tabletwo,$type) = @_;

  $tableone =~ s/'//g;$type =~ s/'//g;	# Just in case
	$tableone =~ s/;//g;$type =~ s/;//g;

	my $stmt;

	# One way
	if ($type) { $stmt = qq|SELECT graph_idtwo FROM graph WHERE graph_tableone='$tableone' AND graph_idone='$idone' AND graph_type='$type'|; }
	else { $stmt = qq|SELECT graph_idtwo FROM graph WHERE graph_tableone='$tableone' AND graph_idone='$idone' |; }
	my $names_ref = $dbh->selectcol_arrayref($stmt);

	# Reverse way
	if ($type) { $stmt = qq|SELECT graph_idone FROM graph WHERE graph_tabletwo='$tableone' AND graph_idtwo='$idone' AND graph_type='$type'|; }
	else { $stmt = qq|SELECT graph_idone FROM graph WHERE graph_tableone='$tableone' AND graph_idtwo='$idone'|; }
	my $names_ref_two = $dbh->selectcol_arrayref($stmt);

  # Join them (ignoring duplicates)
	push(@$names_ref, @$names_ref_two);
	return @$names_ref;

}

  # ---------- graph_item -----------------------------------------------
  # Returns the graph record given both tables and both ids (used to find the typeval value)
sub graph_item {
	my ($t1,$v1,$t2,$v2) = @_;

  my $graph_item = &db_get_record($dbh,"graph",{graph_tableone=>$t1,graph_idone=>$v1,graph_tabletwo=>$t2,graph_idtwo=>$v2});
  unless ($graph_item) { $graph_item = &db_get_record($dbh,"graph",{graph_tableone=>$t2,graph_idone=>$v2,graph_tabletwo=>$t1,graph_idtwo=>$v1}); }
  return $graph_item;
}



	#--------------- Graph Grid
	# Returns an HTML grid of two tables, which can be used as input for grid-based graphing 
	# $type denotes the type of grid entry (radio [default], value)
	# $s1 and $s2 are optional starting positions, $l1 and $l2 is an optional number of entities to count out

sub graph_grid {

	my($t1,$t2,$type,$s1,$s2,$l1,$l2) = @_;
	die "Require two distinct tables for graph grid" unless ($t1 && $t2);
	my $output = "";

	# Get the two lists of items
	my $sql1 = "SELECT ".$t1."_title,".$t1."_id FROM $t1";
	my $sth1 = $dbh->prepare($sql1);
	$sth1 -> execute();

	my $sql2 = "SELECT ".$t2."_title,".$t2."_id FROM $t2";
	my $sth2 = $dbh->prepare($sql2);
	$sth2 -> execute();

	my $table1; my $table2;
	while (my $c1 = $sth1 -> fetchrow_hashref()) {
		$table1->{$c1->{$t1."_id"}} = $c1->{$t1."_title"}
	}
	while (my $c2 = $sth2 -> fetchrow_hashref()) {
		$table2->{$c2->{$t2."_id"}} = $c2->{$t2."_title"}
	}
	$output .= qq|<style>
			table {
			table-layout: fixed;
			width: 1000px;
		}
			td.grid {
				border-bottom:1px solid black;
			}
			.rotate {
		transform: rotate(-45deg);
		/* Legacy vendor prefixes that you probably don't need... */
		/* Safari */
		-webkit-transform: rotate(-45deg);
		/* Firefox */
		-moz-transform: rotate(-45deg);
		/* IE */
		-ms-transform: rotate(-45deg);
		/* Opera */
		-o-transform: rotate(-45deg);
		/* Internet Explorer */
		filter: progid:DXImageTransform.Microsoft.BasicImage(rotation=3);
		}</style>
	|;
	$output .= qq|<h1>Graph: $t1 vs $t2 </h2>|;
	$output .= qq|<form method="post" action="|.$Site->{st_cgi}.qq|api.cgi">
					<input type="hidden" name="t1" value="$t1">
					<input type="hidden" name="t2" value="$t2">
					<input type="hidden" name="cmd" value="graph_submit">|;
	$output .= qq|<table cellpadding=3 cellspacing=0 border=0><tr><td  style="height:30px;width:400px;margin-top:400px;"> - </td>|;
	foreach my $key1 (sort {$a <=> $b} keys %$table1) {
		$table1->{$key1} =~ s/ /&nbsp;/g;
		$output .= "<td style='height:20px;width=20px;' class='rotate'>$table1->{$key1} </td>";
	}
	$output .= "</tr>";

	foreach my $key2 (sort {$a <=> $b} keys %$table2) {
		$output .= qq|<tr><td class="grid" style="height:30px;width:400px;">$table2->{$key2} </td>|;
		foreach my $key1 (keys %$table1) {
			$output .= qq|<td class="grid" style='height:20px;width=20px;'> <input type=checkbox name="$t1$key1$t2$key2"></td>|;
		}
		$output .= "</tr>";
	}
	$output .= "</table>";
	$output .= qq|<input type="submit" value="Submit Graph values"></form>|;

	return $output;

}

	# -------   Create Graph Table ---------------------------------------------------------
	#
sub create_table_graph {


	# Create the graph table
	my @tables = $dbh->tables();
	my $tableName = "graph";
	if ((grep/$tableName/, @tables) <= 0) {
		$vars->{msg} .=  "<b>Creating Graph Table</b>";
		my $sql = qq|CREATE TABLE graph (
			  graph_id int(15) NOT NULL auto_increment,
			  graph_type varchar(64) default NULL,
  			  graph_typeval varchar(40) default NULL,
  			  graph_tableone varchar(40) default NULL,
  			  graph_urlone varchar(256) default NULL,
  			  graph_idone varchar(40) default NULL,
  			  graph_tabletwo varchar(40) default NULL,
  			  graph_urltwo varchar(256) default NULL,
  			  graph_idtwo varchar(40) default NULL,
  			  graph_crdate varchar(15) default NULL,
  			  graph_creator varchar(15) default NULL,
			  KEY graph_id (graph_id)
		)|;
		$dbh->do($sql);
	}
}

	# -------   Find Graph Records of ---------------------------------------------------------
	#
	#  Find a list of $tabletwo id numbers graphed to $tableone id number $idone

sub find_graph_records_of {

	my ($tableone,$idone,$tabletwo,$type) = @_;

	return unless ($tableone && $idone);
	return unless ($tabletwo || $type);
  #	if ($Site->{counter}) {$Site->{counter}++; } else { $Site->{counter} = 1; }
  #	return if ($Site->{counter} > 8000);


	unless ($dbh) { $dbh = $ddbbhh; }
	return unless ($dbh);						# For some reason mooc.ca doesn't pass $dbh

	if ($Site->{$tableone}->{$idone}) {							# Return cached graph entry
		if ($type) {											# by type, or
			return @{$Site->{$tableone}->{$idone}->{$type}};
		} else {												# by table
   # print "Finding graph $tableone,$idone for $tabletwo (in cache)
	# ",@{$Site->{$tableone}->{$idone}->{$tabletwo}},"<br>";
			return @{$Site->{$tableone}->{$idone}->{$tabletwo}};
		}


	} else {		# Create a cache and call the function again
					# so we have one DB call per record, not 12, or 16 times
   #print "Finding graph $tableone,$idone for $tabletwo <br>";
		my $sql = qq|SELECT * FROM graph WHERE (graph_tableone = ? AND graph_idone = ?) OR (graph_tabletwo = ? AND graph_idtwo = ?)|;
		my $sth = $dbh->prepare($sql);
		$sth -> execute($tableone,$idone,$tableone,$idone); my $grfound=0;
		
		while (my $c = $sth -> fetchrow_hashref()) {

			next unless ($c->{graph_idtwo});		# Don't pass zero graph references
			$grfound = 1;
			if ($c->{graph_tableone} eq $tableone && $c->{graph_idone} eq $idone) {
				push @{$Site->{$tableone}->{$idone}->{$c->{graph_tabletwo}}},$c;
				if ($c->{graph_type}) { push @{$Site->{$tableone}->{idone}->{$c->{graph_type}}},$c; }
			} elsif ($c->{graph_tabletwo} eq $tableone && $c->{graph_idtwo} eq $idone) {
				push @{$Site->{$tableone}->{$idone}->{$c->{graph_tableone}}},$c;
				if ($c->{graph_type}) { push @{$Site->{$tableone}->{idone}->{$c->{graph_type}}},$c; }
			}
		}
		if ($grfound) {
			my @connections = &find_graph_of($tableone,$idone,$tabletwo,$type);  # Once we've stored the data, call the result from cache
			return @connections;
		} else { return qw(0 0); }

	}

}

	# -------   Find Graph of ---------------------------------------------------------
	#
	#  Find a list of $tabletwo id numbers graphed to $tableone id number $idone
sub find_graph_of {

	my ($tableone,$idone,$tabletwo,$type) = @_;

	return unless ($tableone && $idone);
	return unless ($tabletwo || $type);
  #	if ($Site->{counter}) {$Site->{counter}++; } else { $Site->{counter} = 1; }
  #	return if ($Site->{counter} > 8000);


	unless ($dbh) { $dbh = $ddbbhh; }
	return unless ($dbh);						# For some reason mooc.ca doesn't pass $dbh

	if ($Site->{$tableone}->{$idone}) {	# Return cached graph entry

		if ($type) {							# by type, or

			return @{$Site->{$tableone}->{$idone}->{$type}};

		} else {							# by table

			if ($Site->{$tableone}->{$idone}->{$tabletwo}) {
				return @{$Site->{$tableone}->{$idone}->{$tabletwo}};
			} 
		}



	} 

	# Create a cache and call the function again
	# so we have one DB call per record, not 12, or 16 times
		
	my $sql = qq|SELECT * FROM graph WHERE (graph_tableone = ? AND graph_idone = ?) OR (graph_tabletwo = ? AND graph_idtwo = ?)|;

	my $sth = $dbh->prepare($sql);
	$sth -> execute($tableone,$idone,$tableone,$idone); my $grfound=0;
	$grfound=0;
	while (my $c = $sth -> fetchrow_hashref()) {
		
		
		next unless ($c->{graph_idtwo});		# Don't pass zero graph references

		$grfound = 1;
		if ($c->{graph_tableone} eq $tableone && $c->{graph_idone} eq $idone) {
			push @{$Site->{$tableone}->{$idone}->{$c->{graph_tabletwo}}},$c->{graph_idtwo}
				unless grep{$_ == $c->{graph_idtwo}} @{$Site->{$tableone}->{$idone}->{$c->{graph_tabletwo}}}; # Unique values only

			push @{$Site->{$c->{graph_tabletwo}}->{$c->{graph_idtwo}}->{$tableone}},$idone
				unless grep{$_ == $idone} @{$Site->{$c->{graph_tabletwo}}->{$c->{graph_idtwo}}->{$tableone}}; # Both ways, because it's an acyclic graph		

			if ($c->{graph_type}) { push @{$Site->{$tableone}->{idone}->{$c->{graph_type}}},$c->{graph_idtwo}; }
			
		} elsif ($c->{graph_tabletwo} eq $tableone && $c->{graph_idtwo} eq $idone) {
			push @{$Site->{$tableone}->{$idone}->{$c->{graph_tableone}}},$c->{graph_idone}
				unless grep{$_ == $c->{graph_idone}} @{$Site->{$tableone}->{$idone}->{$c->{graph_tableone}}}; 

			push @{$Site->{$c->{graph_tableone}}->{$c->{graph_idone}}->{$tabletwo}},$idtwo
				unless grep{$_ == $idtwo} @{$Site->{$c->{graph_tableone}}->{$c->{graph_idone}}->{$tabletwo}};

			if ($c->{graph_type}) { push @{$Site->{$tabletwo}->{idtwo}->{$c->{graph_type}}},$c->{graph_idone}; }
		} else {
			print "Graph save error.<p>";
		}
	}


	if ($Site->{$tableone}->{$idone}->{$tabletwo}) {


			my @connections = &find_graph_of($tableone,$idone,$tabletwo,$type);  # Once we've stored the data, call the result from cache
			return @connections;
		} else { return qw(0 0); }

	

}

#	#-------------------------------------------------------------------------------
	#
	# -------   Find Second Graph ------------------------------------------------------
	#
	#
	#   For a record $r find the second-order associations.
            #   For example, for an $author with a list of $posts, find the list of
            #   $feed for those posts
	#
	#	      Edited: 27 July 2020
	#-------------------------------------------------------------------------------
sub find_second_graph {

	my ($table,$id,$first_table,$second_table) = @_;
	my @first_array = &find_graph_of($table,$id,$first_table);
	my @final_array;
	foreach my $first_item (@first_array) {
		my @second_array = &find_graph_of($first_table,$first_item,$second_table);
		foreach my $second_item (@second_array) {
			push(@final_array, $second_item) unless grep{$_ == $second_item} @final_array;
		}
	}
	return @final_array;
}

	#	Arrays
	#
	#	Common array functions - 12 May 2013
	#
	#	Accepts pointer to @array1, @array2
	#	Returns full array of @union, @intersection or @difference
	#
	# 	Example:
	#	my @array1 = (10, 20, 30, 40, 50, 60);
	#	my @array2 = (50, 60, 70, 80, 90, 100);
	#	my @intersection = &arrays("intersection",@array1,@array2);
sub arrays {

	my ($func,@array1,@array2) = @_;

	@union = @intersection = @difference = ();
	%count = ();

	foreach $element (@array1, @array2) { $count{$element}++;  }
	foreach $element (keys %count) {
		if ($func eq "union") { push @union, $element; }
		else { push @{ $count{$element} > 1 ? \@intersection : \@difference }, $element; }
	}
	if ($func eq "union") { return @union; }
	elsif ($func eq "intersection") { return @intersection; }
	elsif ($func eq "difference") { return @difference; }
}



  # -------  Clone Graph  --------------------------------------------------------
#
#
#	      Edited: 21 January 2013
#
#----------------------------------------------------------------------
sub clone_graph {

  my ($link,$post) = @_;

  &diag(7,"Cloning graph for link $link->{link_id} autopost<br>");
  my $now = time;
  my $cr = $Person->{person_id};

  my $sql = qq|SELECT * FROM graph WHERE graph_tableone=? AND graph_idone = ?|;
  my $sth = $dbh->prepare($sql);
  $sth->execute("link",$link->{link_id});
  while (my $ref = $sth -> fetchrow_hashref()) {

	  $ref->{graph_tableone} = "post";
	  $ref->{graph_idone} = $post->{post_id};
	  $ref->{graph_urlone} = $post->{post_link};
	  $ref->{graph_crdate} = $now;
	  $ref->{graph_creator} = $cr;
	  &diag(7,qq|------ Save Graph: [<a href="$ref->{graph_urlone}">$ref->{graph_tableone} $ref->{graph_idone}</a>]
		$ref->{graph_type} [<a href="$ref->{graph_urltwo}">$ref->{graph_tabletwo} $ref->{graph_idtwo}</a>]<br>|);
	  &db_insert($dbh,$query,"graph",$ref);
  }

  my $sql = qq|SELECT * FROM graph WHERE graph_tabletwo=? AND graph_idtwo = ?|;
  my $file_list = "";
  my $sth = $dbh->prepare($sql);
  $sth->execute("link",$link->{link_id});
  while (my $ref = $sth -> fetchrow_hashref()) {

	  $ref->{graph_tabletwo} = "post";
	  $ref->{graph_idtwo} = $post->{post_id};
	  $ref->{graph_urltwo} = $post->{post_link};
	  $ref->{graph_crdate} = $now;
	  $ref->{graph_creator} = $cr;
	  &diag(7,qq|------ Save Graph: [<a href="$ref->{graph_urlone}">$ref->{graph_tableone} $ref->{graph_idone}</a>]
		$ref->{graph_type} [<a href="$ref->{graph_urltwo}">$ref->{graph_tabletwo} $ref->{graph_idtwo}</a>]<br>|);
	  &db_insert($dbh,$query,"graph",$ref);
  }
}

# Load the entire graph into memory
# Don't do this unless you're publishing the entire graph

sub get_graph {

	my @graph;
	my $sth = $dbh->prepare("SELECT * from graph");
   	$sth->execute();
	while (my $hash_ref = $sth->fetchrow_hashref) {
		push @graph,$hash_ref;
	}
	$sth->finish();   
	return @graph;
}

sub share_graph {

print "<h2>Sharing graph</h2>";
print qq|<div style="width:400px;"><h3>Select Tables</h3>
    <p>Share your graph. Selecting tables from the list below will include them in the 
	list of records shared. Individual records will be shared only if they are in the graph 
	(ie., no singletons). Other people will be able to view your list of records plus the
	graph showing how they are associated with each other.</p><div style="margin-left:3em;">
	 |;

print qq|<form method="post" action="admin.cgi">|;
my @tables = &db_tables($dbh);
my $sharecount=1;
foreach my $table (@tables) {
	next if ($table =~ /^(box|config|optlist|person|graph|view)$/i);   # Not part of the graph
	my $checked = "";
	if ($Site->{sh_tables} =~ /$table/i) { $checked = "checked"; }
	print qq|
	<div>
    <input style="display:inline" type="checkbox" id="share$sharecount" name="interest" value="table" $checked><label class="label-inline" for="share$sharecount">|.ucfirst($table).qq|</label>
    </div>|;
	$sharecount++;
#	print qq|<input type="checkbox" name="share" value="$table"> |.ucfirst($table).qq| <br>|;
}
print qq|</form></div></div>|;
exit;

}
1;
