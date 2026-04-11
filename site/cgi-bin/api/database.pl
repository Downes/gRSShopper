# Database functions: create_sql, api_column_create/alter/remove, api_commit, __map_field_types, api_data_update

sub create_sql {

	my ($table,$language,$sort,$page) = @_;

  #  Language
  my $lang_where = "";
	$language =~ s/[^a-zA-Z]*//g;
  if ($language && $vars->{language} ne "All") {
		  $lang_where = "course_language LIKE '%".$language."%' AND ";
	}

	# Orderby
	my $orderby = "";
	$sort =~ s/[^a-zA-Z_]*//g;
	if ($sort eq "Title") {
		$orderby = " ORDER BY course_title";
	} else  {
		$sort = "Recent";
		$orderby = " ORDER BY course_crdate DESC";
	}


	# Start and Limit
	my $count = "Need to create counter";
	$page =~ s/[^0-9]*//g;
  my $limit; my $results_per_page = 10; my $start=0;
  unless ($page) { $page=0;}
	if ($page > 0) 	{ $start = $page*10; $limit = "LIMIT $start,$results_per_page"}
	else { $limit = "LIMIT $results_per_page"; }
	my $end = $start+$results_per_page; my $s = $start+1;
	my $results_range = "$s to $end of $count";


  my $sql = "SELECT * FROM  course	WHERE $lang_where (course_title LIKE ? OR course_description LIKE ?) $orderby $limit ";


	return $sql;
}


# API UPDATE ----------------------------------------------------------
# ------- Create Column -----------------------------------------------------
#
# Update a column in a database
# Expects semi-colon-delimited comtent as follows: "field;type;size;null;default;extra"
#
# -------------------------------------------------------------------------

sub api_column_create {

	my $table = $vars->{table_name};
	my $id = $vars->{table_id};
	my $value = $vars->{value};
	my $column = $vars->{col_name};
  my ($field,$type,$size,$null,$default,$extra) = split ';',$value;

  # Validate column name
  unless ($field) {
		print "No column created because no column name was provided."; exit;
	}

	# Validate field sizes
	($type,$size) = validate_column_sizes($type,$size);

  if ($id eq "new") {
     print &db_add_column($table,$field,$type,$size,$default); exit;
	} else {

     print "Error creating new column. 'id' should equal 'new'."; exit;

	}
	exit;

	die "Field does not exist" unless (&__check_field($vars->{table_name},$vars->{col_name}));
	my $id_number = &db_update($dbh,$vars->{table_name}, {$vars->{col_name} => $vars->{value}}, $vars->{table_id});
	if ($id_number) { &api_ok();   } else { &api_error(); }
	die "api failed to update $vars->{table_name}  $vars->{table_id}" unless ($id_number);


}

# API UPDATE ----------------------------------------------------------
# ------- Alter Column -----------------------------------------------
#
# Alter a column in a database
# Expects semi-colon-delimited comtent as follows: "field;type;size;null;default;extra"
#
# -------------------------------------------------------------------------

sub api_column_alter {

	my $table = $vars->{table_name};
	my $value = $vars->{value};
	my $column = $vars->{col_name};
  my ($field,$type,$size,$null,$default,$extra) = split ';',$value;
	my $result = "";

  print &db_alter_column($table,$field,$type,$size,$default);

	exit;


}

# API UPDATE ----------------------------------------------------------
# ------- Remove Column Warn ------------------------------------------
#
# Alter a column in a database
# Expects semi-colon-delimited comtent as follows: "field;type;size;null;default;extra"
#
# -------------------------------------------------------------------------

sub api_column_remove {

	my $table = $vars->{table_name};
	my $value = $vars->{value};
	my $col = $vars->{col_name};
	my $second_look = $vars->{second_look};
  my ($field,$type,$size,$null,$default,$extra) = split ';',$value;
	my $result = "";
  my $api_url = $Site->{st_cgi}."api.cgi";


  if ($value eq "confirm") {

    if (($col =~ /_id/) || ($col =~ /_name/) || ($col =~ /_title/) ||
			($col =~ /_description/) || ($col =~ /_crdate/) || ($col =~ /_creator/)) {
					print "The column <i>$col</i> is a required column and cannot be removed"; exit;
		} else {
					$dbh->do("ALTER TABLE $table DROP COLUMN $col");
					print "The column <i>$col</i> has been removed. I hope that's what you wanted."; exit;
		}


	} else {
  	print qq|
	  	<h1>WARNING</h1>
			<p>Are you <i>sure</i> you want to drop $col from $table ?????</p>
			<p><b>All data</b> in $col will be lost. Never to be recovered again.</p>
			<p>You <b>cannot</b> fix this. Backspace to get out of this.</p>
			<p>If you're <i>sure</i>, press the button:</p>
     	<input type="button" name="remove_column_warn" id="remove_column_warn" value=" Remove Column ">
		 	<script>
 				\$('#remove_column_warn').on('click',function(){
 					remove_column("$api_url","$table","$col","confirm");
 					openColumns("$Site->{st_cgi}api.cgi?cmd=show_columns&db=$table","$table");
 				});
 			</script>
		|;
	}
	exit;


}


#
#             API Commit
#
#             Commits changes saved in the 'Form' table to the database
#             - creates table if necessary
#             - creates columns if necessary
#             - alters column to new type if necessary
#


sub api_commit {

  print "Commit";
  return "Commit";
  exit;

	# Get the Form record from database
	my $record = &db_get_record($dbh,$vars->{table_name},{$vars->{table_name}."_id" => $vars->{table_id}});
	unless ($record) { print "<span style='color:red;'>Error: API failed to update $vars->{table_name}  $vars->{table_id}</span>"; exit; }

	# Standardize form names to lower case (because some operations are case insensitive)
	$record->{form_title} = lc($record->{form_title});


	# Create table if table doesn't exist
	&db_create_table($dbh,$record->{form_title});

	# Get the existing columns from the table
	my $columns;
	#my $showstmt = qq|SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = ? AND table_schema = ? ORDER BY column_name|;
	my $showstmt = "SHOW COLUMNS FROM ".$record->{form_title};
	my $sth = $dbh -> prepare($showstmt)  or die "Cannot prepare: $showstmt FOR $record->{form_title} in $Site->{db_name} " . $dbh->errstr();
	$sth -> execute()  or die "Cannot execute: $showstmt " . $dbh->errstr();
  #	$sth -> execute($record->{form_title},$Site->{db_name})  or die "Cannot execute: $showstmt " . $dbh->errstr();
	while (my $showref = $sth -> fetchrow_hashref()) {
  #print $showref->{Field},"<p>";
		# Stash Column Data for future reference
		$columns->{$showref->{Field}}->{type} = $showref->{Type};
		$columns->{$showref->{Field}}->{size} = $showref->{CHARACTER_MAXIMUM_LENGTH};

	}

	# Go though the table structure defined in $record->{form_data}
	my @fcols = split /;/,$record->{form_data};
	my $titles = 0;

	# For each of the columns defined in the form data
	foreach my $fcol (@fcols) {
		my ($fname,$ftype,$fsize) = split /,/,$fcol; 	# This assumes an order which could be a problem
		if ($titles == 0) {
								# Fix that problem here
			$titles = 1; next; 			# Skip past titles
		}

		# Does the column exist?
		my $columntitle = $record->{form_title}."_".$fname;

		# No
		unless ($columns->{$columntitle}) {

			next if (&__map_field_types($ftype) eq "none");

			# Create New Column as per the Form Data
			my $sql;
			if (&__map_field_types($ftype) eq "text") {
				$sql = qq|alter table |.$record->{form_title}.qq| add column $columntitle text;|;
			} elsif (&__map_field_types($ftype) eq "int") {
				unless ($fsize) { $fsize=15; }
				$sql = qq|alter table |.$record->{form_title}.qq| add column $columntitle int ($fsize);|;
			} elsif (&__map_field_types($ftype) eq "varchar") {
				unless ($fsize) { $fsize = 256; }
				$sql = qq|alter table |.$record->{form_title}.qq| add column $columntitle varchar ($fsize);|;
			} else {
				$sql = qq|alter table |.$record->{form_title}.qq| add column $columntitle varchar ($fsize);|;
			}
			#print "Doing: $sql <br>";
			$dbh->do($sql) or die "error creating $fname using $sql";


		# Yes
		} else {

			# Check for increased varchar size
			if (&__map_field_types($ftype) eq "varchar") {
				if ($columns->{$columntitle}->{size} < $fsize) {

					# And alter column size if necessary

					my $sql = qq|alter table |.$record->{form_title}.qq| modify $columntitle VARCHAR($fsize);|;
					$dbh->do($sql) or die "error embiggening $fname";

				}

			}

		}


	}


	my $id_number = &db_update($dbh,$vars->{table_name}, {$vars->{col_name} => 1}, $vars->{table_id});
	if ($id_number) { &api_ok();   } else { &api_error(); }
	die "api failed to update $vars->{table_name}  $vars->{table_id}" unless ($id_number);

}

sub __map_field_types {

	my ($field) = @_;
	if ($field eq "select" || $field eq "date" || $field eq "varchar") { return "varchar"; }
	elsif ($field eq "text" || $field eq "textarea" || $field eq "wysihtml5" || $field eq "data") { return "text"; }
	elsif ($field eq "commit" || $field eq "publish" || $field eq "int") { return "int"; }
	else { return "none"; }

}



sub api_data_update {



    my $data = "";
    for (my $i=-1; $i < 100; $i++) {
    	my $row = "";
    	for (my $j=-1; $j < 100; $j++) {
    	   my $slot = $i."-".$j;
	   if ($vars->{$slot}) {
	   	if ($row) { $row .= ","; }
	   	$row .= $vars->{$slot};
	   }
        }
        if ($data && $row) { $data .= ";"; }
	$data .= $row;
    }

  #$data = qq|name,type,size;name,textarea,256;nickname,textarea,256|;
    my $id_number = &db_update($dbh,$vars->{table_name}, {$vars->{col_name} => $data}, $vars->{table_id});


  #my $str; while (my ($x,$y) = each %$vars) 	{ $str .= "$x = $y <br>\n"; }
  #&send_email('stephen@downes.ca','stephen@downes.ca', 'data  update',$str.$data);

	# Reset commit flag in case the table is 'form'
	if ($vars->{table_name} eq "form") {
  #		&db_update($dbh,$vars->{table_name}, {form_commit => 0}, $vars->{table_id});
	}

	# Rebuild search forms in case the table is 'optlist'
	# We'll just call the function with a request to admin.cgi
	if ($vars->{table_name} eq "optlist") {
		my $findurl = $Site->{st_cgi}."admin.cgi?action=make_search_forms";
		my $content = get $findurl;
		&status_error("Couldn't get $findurl") unless defined $content;
		$vars->{message} .= $content;
	}

    if ($id_number) { &api_ok();   } else { &api_error(); }



  #	my $id_number = &db_update($dbh,$vars->{table_name}, {$vars->{name} => $vars->{value}}, $vars->{table_id});
  #	if ($id_number) { &api_ok();   } else { &api_error(); }
	#die "api failed to update $vars->{table_name}  $vars->{table_id}";
    #enless ($id_number);


}

1;
