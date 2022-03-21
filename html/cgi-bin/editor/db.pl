
# DB ----------------------------------------------------------------
	# ------- Add Column ------------------------------------------------
	#
	# Add a column in a database
	#
	# -------------------------------------------------------------------------

sub db_add_column {
	my ($table,$column,$datatype,$size,$default) = @_;

	&status_error("Column name error - cannot call a column $column") if (
		(($col+0) > 0) ||
		($col =~ /['"`#!$%&@]/)
		);

	# Validate field types and sizes
	($datatype,$size) = &validate_column_sizes($datatype,$size);

  # Set default data type and size
	$datatype ||= "text";
	if ($datatype eq "text") { $datatype_string = "text"; }
	elsif ($datatype eq "date") { $size ||= 10; $datatype_string = "date"; }
	elsif ($datatype eq "varchar") { $size ||= 256; $datatype_string = "varchar($size)"; }
	elsif ($datatype eq "int") { $size ||= 10; $datatype_string = "int($size)"; }
	elsif ($datatype eq "bit") { $datatype_string = "tinyint(1)"; }
	else {$datatype_string = "text";}

	# Sanitize $default
	$default =~ s/['"`#!$%&@]//g;

	# Normalize column name - column names *must* be prefixed with the table name 'table_colmname'
	my $tabstring = $table."_";
	unless ($column =~ /^$tabstring/) {
		$column = $tabstring.$column;
	}

  # Create the column
	$dbh->do("ALTER TABLE $table ADD $column $datatype_string NULL");
	$default =~ s/'|`/&apos;/g;
	if ($default) { $dbh->do("ALTER TABLE $table MODIFY $column SET DEFAULT '$default';"); }


	return "Column $column ($datatype_string) added to $table";

}

	# DB ----------------------------------------------------------------
	# ------- Alter Column ----------------------------------------------
	#
	# Alter a column in a database
	#
	# ---------------------------------------------------------------------
sub db_alter_column {

    my ($table,$column,$type,$size,$default) = @_;

    # Set the default if there's a default
		$default =~ s/'|`/&apos;/g;
		if ($default) { $dbh->do("ALTER TABLE $table MODIFY $column SET DEFAULT '$default';") or return "Error setting the default value: $!"; }

		# Validate field types and sizes
		($type,$size) = &validate_column_sizes($type,$size);

		if ($type eq "text") {
			my $sth = $dbh->prepare("ALTER TABLE $table MODIFY $column $type");
			$sth->execute() or return $sth->errstr();
		} else {
			my $sth = $dbh->prepare("ALTER TABLE $table MODIFY $column $type($size)");
			$sth->execute() or return $sth->errstr();
		}

		return "Table $column changed to $type($size) <br>";

    # Allow  a way to change size only - leave field tyoe information blank
		# Because this is higher risk it can only be used to increase size

		# Get Existing Column Info
		print "Table: $table Column $column <p>";
		my $sth = $dbh->column_info(undef, undef, 'box', $column);
		my $col_info = $sth->fetchrow_hashref();

    # Check the size
		if ($col_info->{COLUMN_SIZE} > $size) {
				  $size = $col_info->{COLUMN_SIZE};
					return "You cannot reduce the size of your varchar or int field. This is to prevent accidental content loss.<br>";
					exit;
		}

    # Make the change
		$dbh->do("ALTER TABLE $table MODIFY $column $type($size)") or return $sth->errstr();
		return "Table $column size changed to $type($size) <br>";

}

	# DB ----------------------------------------------------------------
	# ------- Validate Column Sizes ----------------------------------------------
	#
	# Validate field types and sizes for database column definitions
	#
	# ---------------------------------------------------------------------
sub validate_column_sizes {

   my ($type,$size) = @_;

   # Limit allowed column types - this could probably be expanded but will do for now
	 $type ||= "text";
	 die "invalid column type $type" unless ($type =~ /text|longtext|varchar|int|bit|tinyint|date|datetime|blob/i);

	 if ($type eq "int") {
			$size ||= 10;
			if ($size > 11) { $size = 11;}
			}
	 if ($type eq "varchar") {
			$size ||= 256;
			if ($size > 65535) { $size = 65535;}
	 }
	 if ($type eq "bit") { $type="tinyint"; $size = 1; }

   return ($type,$size);
}

	# DB ----------------------------------------------------------------
	# ------- Remove Column - Warn ---------------------------------------
	#
	# Validate field types and sizes for database column definitions
	#
	# ---------------------------------------------------------------------
sub removecolumnwarn {

	my ($dbh,$query) = @_;
	my $vars = $query->Vars;
	my $col = $vars->{col};
	my $tab = $vars->{stable};
	print "Content-type: text/html\n\n";
	print qq|<html><head></head><h1>WARNING</h1>
		<p>Are you <i>sure</i> you want to drop $col from $tab ?????</p>
		<p><b>All data</b> in $col will be lost. Never to be recovered again.</p>
		<p>You <b>cannot</b> fix this. Backcspace to get out of this.</p>
		<p>If you're <i>sure</i>, press the button:</p>
		<form method="post" action="$Site->{st_cgi}admin.cgi">
		<input type="hidden" name="col" value="$col">
		<input type="hidden" name="stable" value="$tab">
		<input type="hidden" name="action" value="removecolumndo">
		<input type="submit" value="Remove Column">
		</form></body><html>|;

}
sub removecolumndo {
	my ($dbh,$query) = @_;
	my $vars = $query->Vars;
	my $col = $vars->{col};

	&status_error("Column name error - cannot remove $col") if (
		($col =~ /_id/) || ($col =~ /_name/) || ($col =~ /_title/) || ($col =~ /_description/)
		);
	my $tab = $vars->{stable};

	$dbh->do("ALTER TABLE $tab DROP COLUMN $col");
	my $msg = "Column $col dropped from $tab";


	&show_columns($dbh,$query,$msg);

}
sub import_json {

	my ($file,$table) = @_;

	use JSON::XS;
	my $json_text = &get_file($file->{file_location});

# print $json_text;
	my $perl_scalar = decode_json $json_text;

	my $normalize = &import_json_schema($perl_scalar,$table);

 #	print $perl_scalar;

	while (my ($x,$y) = each %$perl_scalar) {
		#print "Importing chat record with foreign ID of $x. ";

		# Normalize column names (note - in a table, all columns begin with 'tablename_' )
		if ($normalize) {
			while (my ($xx,$xy) = each %$y) {

				my $tabstring = $table."_";
				unless ($xx =~ /^$tabstring/) {
					$y->{$tabstring.$xx} = delete $y->{$xx}
				}
			}

		}
		my $new_record = &db_insert($dbh,$query,$table,$y);
		#print "Saved as chat record $new_record.<br>";
	}


	#$perl_scalar = decode_json $json_text

}

	# This function allows you to import data from JSON, creating new
	# database columns as needed, in case the current schema doesn't
	# support the column
sub import_json_schema {

	my ($perl_scalar,$table) = @_;

	# get the current list of columns for the table
	my @columns = &db_columns($dbh,$table);
	my $normalize = 0;

	# Get the list of columns (cycle through the whole list so we don't miss any)
	my %hash;
	while (my ($x,$y) = each %$perl_scalar) {
		while (my ($xx,$xy) = each %$y) {
			$hash{$xx} = 1;
		}
	}

	# Compare the new columns with the existing columns and add the column to the table if needed
	foreach my $column (keys %hash) {


		# Normalize column name
		my $tabstring = $table."_";
		unless ($column =~ /^$tabstring/) {
			$column = $tabstring.$column;
			$normalize=1;
		}

		# skip if we already have this column
		next if ( grep( /^$key$/, @columns ));

		push @column,$column;
		$msg = &db_add_column($table,$column);
		#print "Added $column to list<br>";
		# do something with $key
	}


	return $normalize;


}

#           Database Functions
	# -------   Open Database ------------------------------------------------------

sub db_open {

	my ($dsn,$user,$password) = @_;

	die "Database dsn note specified in db_open" unless ($dsn);
	die "Database user note specified in db_open" unless ($user);

	my $dbh = DBI->connect($dsn, $user, $password)
		or die "Database connect error: $! \n";
	# Uncomment next line to trace DB errors
 #	  if ($dbh) { $dbh->trace(1,"/var/www/connect/dberror.txt"); }
	return $dbh;
}

	# -------   Get Record -------------------------------------------------------------
sub db_get_record {

	my ($dbh,$table,$value_arr) = @_;
	&status_error("Database not ready") unless ($dbh);

	my @value_list; my @value_vals;
	while (my($kx,$ky) = each %$value_arr) { push @value_list,"$kx=?"; push @value_vals,$ky; }
	my $value_str = join " AND ",@value_list;
	unless ($value_vals[0]) { warn "No value input to db_get_record from $table"; return; }
	my $stmt = "SELECT * FROM $table WHERE $value_str LIMIT 1";
	my $sth = $dbh -> prepare($stmt);
	$sth -> execute(@value_vals);
	my $ref = $sth -> fetchrow_hashref();
	$sth->finish(  );
	return $ref;
}

	# -------   Get Record List ---------------------------------------------------------
	#
	# Returns a list of values from specified table
	# Default value is id number, but can optionally define an alternative field
	# (this is useful for getting a list of records from the graph)
	# updated 12 May 2013
sub db_get_record_list {

	my ($dbh,$table,$value_arr,$field) = @_;
	&status_error("Database not ready") unless ($dbh);
	if ($diag eq "on") { print "Get Record List ($table $value_arr)<br/>\n"; }

	my @value_list; my @value_vals;
	while (my($kx,$ky) = each %$value_arr) { push @value_list,"$kx=?"; push @value_vals,$ky; }
	my $value_str = join " AND ",@value_list;
	&status_error("Error forming request in db_get_record_list()") unless ($value_str);

	my $idfield = $table ."_id";
	$field ||= $idfield;
	my $stmt = "SELECT $field FROM $table WHERE $value_str";

	my $sth = $dbh -> prepare($stmt);
	$sth -> execute(@value_vals);


	my @record_list;
	while (my $hash_ref = $sth->fetchrow_hashref) {
		push @record_list,$hash_ref->{$field};
	}
	$sth->finish(  );

	return @record_list;
}



	# -------   Get Text --------------------------------------------------------
	#
	#  Specialized function to get the content only, used for making views
	#  Eventually I'mm combine all these three into one function
sub db_get_text {

	my ($dbh,$table,$title) = @_;


	my $fname = "db_get_text";								# Error Check
	unless ($title) { &error($dbh,$query,"",&printlang("Required in","title",$fname)); }
	unless ($table) { &error($dbh,$query,"",&printlang("Required in","table",$fname)); }

	my $viewcache = $table.$title;									# Never get the same thing from the db twice
	if (defined $cache->{$viewcache}) { return $cache->{$viewcache}; }

	my $stmt = "SELECT ".$table."_text FROM $table WHERE ".$table."_title = '$title'";	# Get Data from DB
	my $ary_ref = $dbh->selectcol_arrayref($stmt) or &error($dbh,$query,"",&printlang("Cannot execute SQL",$fname,$sth->errstr(),$stmt));
	my $templ = $ary_ref->[0];									# Fail silently

	$cache->{$viewcache} = $templ;									# Save in cache and return


	return $templ;

}


	# -------   Get Content --------------------------------------------------------
	#
	#  Specialized function to get the content only, used for making boxes on the fly
sub db_get_content {

	my ($dbh,$table,$title) = @_;

	my $fname = "db_get_content";								# Error Check
	unless ($title) { &error($dbh,$query,"",&printlang("Required in","title",$fname)); }
	unless ($table) { &error($dbh,$query,"",&printlang("Required in","table",$fname)); }

	my $viewcache = $table.$title;									# Never get the same thing from the db twice
	if (defined $cache->{$viewcache}) { return $cache->{$viewcache}; }

	my $stmt = "SELECT ".$table."_content FROM $table WHERE ".$table."_title = '$title'";	# Get Data from DB

	my $ary_ref = $dbh->selectcol_arrayref($stmt) or &error($dbh,$query,"",&printlang("Cannot execute SQL",$fname,$sth->errstr(),$stmt));

	my $templ = $ary_ref->[0];									# Fail silently

	$cache->{$viewcache} = $templ;									# Save in cache and return
	return $templ;

}

	# -------   Get Template --------------------------------------------------------
sub db_get_template {

	my ($dbh,$title,$page_title) = @_;

	if ($title =~ /'/) { &status_error("Cannot put apostraphe in template title"); }  # '
	&status_error("Database not initialized in get_single_value") unless ($dbh);
	return unless ($title);							# Just pass by blank template requests


	my $stmt = qq|SELECT template_description FROM template WHERE template_title='$title' LIMIT 1|;

	my $ary_ref = $dbh->selectcol_arrayref($stmt);
	my $ret = $ary_ref->[0];


	return $ret;

}

	# -------  Get Template ---------------------------------------------------------
	#
	#	Get a template from the database, format it, and return the formatted text
	#
sub get_template {

	my ($template_title,$wp) = @_;
 	if ($diag>9) { print "Get Template <br>"; }

													# Get Template From DB

	return unless ($template_title);
	return if ($template_title eq "none");		                   		#     - Can print 'blank' remplate (ie., nothing)
	my $template_record = &printlang($template_title) || $template_title;		#     - Try to find a translated title of template
	my $template = &db_get_description($dbh,"template",$template_record) ||		#     - Get the template text from the database
		&printlang("Template file $template_record not found",$ermsg);		# 		- or report error


														# Format the template
	&make_boxes($dbh,\$template);									# 	- Make boxes
	&make_data_elements(\$template,$wp,$record_format);
	&make_admin_nav($dbh,\$template);							# Admin Table Navigation Box
	&make_counter($dbh,\$template);								# 	- Make counter

	&make_keywords($dbh,$query,\$template);							# 	- Make Keywords

	&autodates(\$template);										# 	- Autodates
	&make_tz($dbh,\$template);								# Time zones

	&make_langstring(\$template);							# Language Strings

														# More Formatting

	$template =~ s/&#39;/'/g;									# 	- Makes scripts work
	&make_site_info(\$template);									#	- Template and Site Info

														# Write Page Title
	$template =~ s/\Q[*page_title*]\E/$title/g;
	$template =~ s/\Q<page_title>\E/$title/g;

	if ($diag>9) { print "/ Get Template <br>"; }
	return $template;


}

	#
	# -------   Get Description --------------------------------------------------------
	#
	#  Specialized function to get the description only, used for get_template()
sub db_get_description {

	my ($dbh,$table,$title) = @_;

	my $fname = "db_get_description";								# Error Check
	unless ($title) { &error($dbh,$query,"",&printlang("Required in","title",$fname)); }
	unless ($table) { &error($dbh,$query,"",&printlang("Required in","table",$fname)); }

	my $viewcache = $table.$title;									# Never get the same thing from the db twice
	if (defined $cache->{$viewcache}) { return $cache->{$viewcache}; }

	my $stmt = "SELECT ".$table."_description FROM $table WHERE ".$table."_title = '$title'";	# Get Data from DB
	my $ary_ref = $dbh->selectcol_arrayref($stmt) or &error($dbh,$query,"",&printlang("Cannot execute SQL",$fname,$sth->errstr(),$stmt));
	my $templ = $ary_ref->[0];									# Fail silently

	$cache->{$viewcache} = $templ;									# Save in cache and return
	return $templ;

}


	# -------   Get Column --------------------------------------------------------
sub db_get_column {

	my ($dbh,$table,$field) = @_;
	&status_error("Database not ready") unless ($dbh);
	if ($diag eq "on") { print "Get Column ($table $value_arr)<br/>\n"; }
	my $stmt = qq|SELECT $field FROM $table|;
	my $names_ref = $dbh->selectcol_arrayref($stmt);
	return $names_ref;
}


	# -------   Get Record Cache --------------------------------------------------------
	# Cache is a pre-assembled version of complex records all ready for display
	#
	# Cache is either
	#       *expired*   if time-$Site->{st_cache} > cache_update
	#       or *active*
	#
	# Chack check returns either the record cache, if active, or '0' if expired
sub db_cache_check {

	my ($dbh,$table,$record,$format) = @_;

	return 0 if ($format =~ /_edit/i);			# never cache edit screen

	return 0 if ($vars->{force} eq "yes");			# command line force

	$format ||= "html";					# format defaults to html
	return unless ($table && $record);			# must specify table and record

	my $cache = &db_cache_get($dbh,$table,$record,$format);


	my $expired = time+$Site->{pg_update};
	if ($cache->{cache_text} && ( $expired > $cache->{cache_update} )) {
		return $cache->{cache_text};
	}
	return 0;


}

	# --------- Back Up Database -------------------------------------------------------
	# Note - uses mysqldump - won't work for different db
sub db_backup {

	my ($table) = @_;
	my $output =  qq|"$table"|;
	if ($table eq "all") { $table = ""; }

  	my $data_file = $self->{st_cgif}."data/multisite.txt";

	open IN,"$data_file" or die "Couldn't open $data_file $!";
	my $dbinfo;


	# Find the line beginning with site URL
	# and read site database information from it

	my $url_located = 0;
  	while (<IN>) {
		my $line = $_; $line =~ s/(\s|\r|\n)$//g;
		( $dbinfo->{st_home},
		  $dbinfo->{database}->{name},
		  $dbinfo->{database}->{loc},
		  $dbinfo->{database}->{usr},
		  $dbinfo->{database}->{pwd},
		  $dbinfo->{site_language},
		  $dbinfo->{urlf},
		  $dbinfo->{cgif} ) = split "\t",$line;   # Assign defualts with first line
		if ($line =~ /^$Site->{st_host}/) {
			( $dbinfo->{st_home},
			  $dbinfo->{database}->{name},
			  $dbinfo->{database}->{loc},
			  $dbinfo->{database}->{usr},
			  $dbinfo->{database}->{pwd},
			  $dbinfo->{site_language},
			  $dbinfo->{urlf},
		  	  $dbinfo->{cgif} ) = split "\t",$line;
			$url_located = 1;
			last;
		}
	}
	close IN;

	$table =~ s/$dbinfo->{database}->{name}\.//;
	unless (-d $Site->{st_urlf}."files/backup/") { mkdir $Site->{st_urlf}."files/backup/"; }
	my $backup_filename = $Site->{st_urlf}."files/backup/".$dbinfo->{database}->{name}."-".$table."-".time.".sql";
	$backup_filename =~ s/--/-/;
	`mysqldump --host=db --user=$dbinfo->{database}->{usr} --password=$dbinfo->{database}->{pwd} $dbinfo->{database}->{name} $table > $backup_filename`;

	# `mysqldump -h db -uroot –p test_db > backup.sql`;

	$Site->{database}="";							# Clear site database info so it's not available later
	$_ = "";								# Prevent accidental (or otherwise) print of config file.

	return $backup_filename; 
	# qq|mysqldump --user=$dbinfo->{database}->{usr} --password=$dbinfo->{database}->{pwd} $dbinfo->{database}->{name} $table > $backup_filename|;


}

	# -------   Get Record Cache --------------------------------------------------------
	# Cache is a pre-assembled version of complex records all ready for display
sub db_cache_get {

	my ($dbh,$table,$record,$format) = @_;

	return if ($format =~ /_edit/i);			# never cache edit screen
	$format ||= "html";					# format defaults to html
	return unless ($table && $record);			# must specify table and record


	my $stmt = "SELECT * FROM cache WHERE cache_table=? AND cache_record=? AND cache_format=? LIMIT 1";
	my $sth = $dbh -> prepare($stmt);
	$sth -> execute($table,$record,$format);

	my $ref = $sth -> fetchrow_hashref();
	$sth->finish(  );
	if ($ref->{cache_text}) { return $ref; } else { return 0; }
}

	# -------   Save Record Cache --------------------------------------------------------
sub db_cache_save {

	my ($dbh,$table,$record,$format,$text) = @_;
	push @{$Site->{cache}},"$table:$record:$format:$text";

}

	# -------   Save Record Cache --------------------------------------------------------
	# Cache is a pre-assembled version of complex records all ready for display
	# Cache items gathered during processing and stored in $Site->{cache}
	# Cache is written at the end of page processing, after all page output is complete
sub db_cache_write {

	my ($dbh) = @_;

	foreach my $cache (@{$Site->{cache}}) {

		my @cachearr = split /:/,$cache;
		my $table = shift @cachearr;
		my $record = shift @cachearr;
		my $format = shift @cachearr;
		my $text = join ":",@cachearr;

		next if ($format =~ /_edit/i);			# never cache edit screen
		$format ||= "html";					# format defaults to html
		die "table and record not specified for cache save" unless ($table && $record);			# must specify table and record

		my $cache_update = time;				# record time of current update
								# used in db_cache_check()

		&db_cache_remove($dbh,$table,$record,$format);		# remove previous entry


								# insert new entry
		&db_insert($dbh,$query,"cache",
			{	cache_table => $table,
				cache_record => $record,
				cache_format => $format,
				cache_text => $text,
				cache_update => $cache_update	});
	}

}

	# -------   Remove Record Cache --------------------------------------------------------

	# Short and simple, remove cached records, nothing permanent is touched
sub db_cache_remove {


	my ($dbh,$table,$record,$format) = @_;
	return unless ($table);

	my $where = "cache_table = '$table'";
	if ($record) { $where .= " AND cache_record = '$record'"; }
	if ($format) { $where .= " AND cache_format = '$format'"; }

	my $sql = "DELETE from cache WHERE $where";

	my $sth = $dbh->prepare($sql);
    	$sth->execute();

}


	# -------   Get Single Value--------------------------------------------------------
sub db_get_single_value {

  my ($dbh,$table,$field,$id,$sort,$cmp) = @_;

  &status_error("Database not initialized in get_single_value") unless ($dbh);
  &status_error("Table not initialized in get_single_value") unless ($table);
  unless ($sort) { &status_error("Field not initialized in get_single_value") unless ($field); }
  #&status_error("ID number not initialized in get_single_value") unless ($id);
  return unless ($id || $sort);

  my $idfield = $table."_id";								# define id field name
  my $t = $table."_";unless ($field =~ /$t/) { $field = $t.$field; }	# Normalize field field name
	if ($sort) { $sort = "ORDER BY $sort"; }
	my $where; if ($idfield && $id) {
		if ($cmp eq "lt" && $id>0) { $where = qq|WHERE $idfield<$id|; }
		elsif ($cmp eq "gt" && $id>0) { $where = qq|WHERE $idfield>$id|; }
		else { $where = qq|WHERE $idfield='$id'|; }
	}

  my $stmt = qq|SELECT $field FROM $table $where $sort LIMIT 1|; 	# Perform SQL
 
  my $ary_ref = $dbh->selectcol_arrayref($stmt);
  my $ret = $ary_ref->[0];

  return $ret;

}

	# -------   Drop Table -------------------------------------------------------------
	#
	#  db_drop_table($dbh,$table)
	#
	#  Disabled by default, because bthe consequences of accidental call are too extreme
	#
sub db_drop_table {

	my $dbh = shift || die "Database handler not initiated";
	my $table = shift || die "Table not specified on drop table";

	&db_backup($table);

	my $sql = qq|DROP TABLE IF EXISTS `$table`|;

	my $sth = $dbh->prepare($sql);
    	$sth->execute();
    	return "Table '$table' dropped.";
}


	# -------   Create Table -------------------------------------------------------------
	#
	#  db_create_table($dbh,$table,$data)
	#
	#  Create a new table, if the table does not yet exist (die otherwise)
	#  $data defines the table elements
	#
	#  Table fields are defined with the table name and the field name
	#
sub db_create_table {

	my $dbh = shift || die "Database handler not initiated";
	my $table = shift || die "Table not specified on create table";
	my $data = shift;
	my $return = "";

  #  Do not create if the table already exists

	if (&db_table_exist($dbh,$table)) {
		$vars->{msg} = "Table '$table' already exists.";
		return 0;
	}

  #  All tables *must* have the following fields:
  #      $table_id  int(11) NOT NULL auto_increment
  #      $table_creator int(15) which is set to the current $Person->{person_id} when a record is created
  #      $table_crdate int(15) which is set to time when a record is created
  #

	my @fieldlist = ($table."_id", $table."_crdate", $table."_creator");
	my $sql = qq|CREATE TABLE `|.$table.qq|` (
  `|.$table.qq|_id` int(11) NOT NULL auto_increment,
  `|.$table.qq|_crdate` int(15) default NULL,
  `|.$table.qq|_creator` int(15) default NULL,|;


  #  Data provides table elements, in order
  #  Each element as an array or comma-delimited string:  name,type,length,default,extra
  #  List of table elements as array, or semi-colon delimited string:
  #  name,type,length,default,extra;name,type,length,default,extra;name,type,length,default,extra...

	my @fields;
	if (ref($data) eq "ARRAY") { @fields = @$data; }
	else { @fields = split /;/,$data; }

	foreach my $field (@fields) {

		my @values;
		if (ref($field) eq "ARRAY") { @values = @$field; }
		else { @values = split /,/,$field; }
		foreach my $v (@values) { $v =~ s/[^a-zA-Z0-9,_]+//g;} # No unusual characters or sql injection
		unless ($values[0] =~ /^$table/) { $values[0] = $table."_".$values[0]; } # Normalize field names
		next unless (&index_of($values[0],\@fieldlist) < 0);  # No duplicate field names
		push @fieldlist,$values[0];

		$sql .= qq|`$values[0]` |.$values[1].qq||;
		if ($values[2]) { $sql .= qq|(|.$values[2].qq|)|; }
		if ($values[3]) { $sql .= qq| |.$values[2].qq||; }
		if ($values[4]) { $sql .= qq| |.$values[2].qq||; }
		$sql .= ",\n";

	}



	$sql .= qq|  PRIMARY KEY  (`|.$table.qq|_id`)) ENGINE=MyISAM AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;|;

	$return .=qq|<pre>$sql</pre>|;
	my $sth = $dbh->prepare($sql) or  $return .= "Can't prepare SQL statement in db_create_table : ", $sth->errstr(), "\n";

    	if ($sth->execute()) { $return .= "Table $table created<p>"; }
	else { $return .= "Can't execute SQL statement in db_create_table : ", $sth->errstr(), "\n"; }

    	$return;
}

	# -------   Table exist -------------------------------------------------------------
	#
	#  Does a table exist?
	#
	#  Uses table_info()
	#  Returns 1 if it does, 0 otherwise
	#
sub db_table_exist {
    my ($dbh,$table_name) = @_;

    my @tables = &db_tables($dbh);
    if (&index_of($table_name,\@tables) < 0) { return 0; }
    else { return 1; }

}

	# -------   Delete -------------------------------------------------------------
sub db_delete {

	my $dbh = shift || die "Database handler not initiated";
	my $table = shift || die "Table not specified on delete";
	my $field = shift || die "Field not specified on delete";
	my $id = shift || die "No data provided on delete $table, $field)";
	die "Invalid input record $id on delete" unless (($id+0) > 0);	# Prevents accidental mass deletes
	my $sql = "DELETE FROM $table WHERE $field = '".$id."'";

	my $sth = $dbh->prepare($sql);
    	$sth->execute();
}

	# -------   Locate -------------------------------------------------------------

	# Find the ID number given input values

	# Used by new_user()
sub db_locate {

	my ($dbh,$table,$vals) = @_;
						# Verify Input Data

	&status_error("db_locate(): Cannot locate with no values") unless ($vals);

						# Prepare SQL Statement
	my $stmt = "SELECT ".$table.
		"_id from $table WHERE ";
	my $wherestr = ""; my @whvals;
	while (my($vx,$vy) = each %$vals) {
		if ($wherestr) { $wherestr .= " AND "; }
		$wherestr .= "$vx = ?";
		push @whvals,$vy;
	}
	$stmt .= $wherestr . " LIMIT 1";

	my $sth = $dbh->prepare($stmt);		# Execute SQL Statement

	$sth->execute(@whvals) or return 0;

  	my $hash_ref = $sth->fetchrow_hashref;
	$sth->finish(  );

	return $hash_ref->{$table."_id"};

}

	# -------   Locate Multiple -------------------------------------------------------------
	# Find an array of ID numbers given input values
	# Used by new_user()
sub db_locate_multiple {

	my ($dbh,$table,$vals) = @_;
						# Verify Input Data

	&status_error("db_locate(): Cannot locate with no values") unless ($vals);

						# Prepare SQL Statement
	my $stmt = "SELECT ".$table.
		"_id from $table WHERE ";
	my $wherestr = ""; my @whvals;
	while (my($vx,$vy) = each %$vals) {
		if ($wherestr) { $wherestr .= "AND "; }
		$wherestr .= "$vx = ?";
		push @whvals,$vy;
	}
	$stmt .= $wherestr;

	my $ary_ref = $dbh->selectcol_arrayref($stmt,{},@whvals);
	return $ary_ref;

}

	# -------   Insert --------------------------------------------------------

	# Adapted from SQL::Abstract by Nathan Wiger
sub db_insert {		# Inserts record into table from hash
print "Inserting<p>";

						# Verify Input Data

	my $dbh = shift || &status_error("Database handler not initiated");
	my $query = shift;
	my $table = shift || &status_error("Table not specified on insert");
	my $input = shift || &status_error("No data provided on insert");


    	my $vars = ();
    	if (ref $query eq "CGI") { $vars = $query->Vars; }


	my $dtype = ref $input;
	&status_error("Unsupported data type specified to insert (data was $dtype)")
		unless (ref $input eq 'HASH' || ref $input eq 'gRSShopper::Record' || ref $input eq 'gRSShopper::Person' || ref $input eq 'gRSShopper::File');
	my $data= &db_prepare_input($dbh,$table,$input);

	# Default link URL for link
	if ($table eq "link") {
		unless ($data->{link_link}) { $data->{link_link} = time; } # So we can create links manually
	}

	my $sql   = "INSERT INTO $table ";	# Prepare SQL Statement

	my(@sqlf, @sqlv, @sqlq) = ();

	for my $k (sort keys %$data) {
		push @sqlf, $k;
		push @sqlq, '?';
		push @sqlv, $data->{$k};
	}
	$sql .= '(' . join(', ', @sqlf) .') VALUES ('. join(', ', @sqlq) .')';

print "$sql<p>";
	my $sth = $dbh->prepare($sql) or print "Content-type: text/html\n\n".$sth->errstr;;		# Execute SQL Statement

   	$sth->execute(@sqlv) or print "Content-type: text/html\n\n".$sth->errstr;

	if ($sth->errstr) { $vars->{err} = "DB INSERT ERROR: ".$sth->errstr." <p>"; }

	my $insertid = $dbh->{'mysql_insertid'};
print "Inserted $table $insertid <br>";	
	$sth->finish(  );
	return $insertid;


}

	# -------   Insert --------------------------------------------------------

	# Adapted from SQL::Abstract by Nathan Wiger
sub db_insert_ignore {		# Inserts record into table from hash
						# Verify Input Data
	my $dbh = shift || &status_error("Database handler not initiated");
	my $query = shift;
	my $table = shift || &status_error("Table not specified on insert");
	my $input = shift || &status_error("No data provided on insert");


    	my $vars = ();
    	if (ref $query eq "CGI") { $vars = $query->Vars; }


	my $dtype = ref $input;
	&status_error("Unsupported data type specified to insert (data was $dtype)")
		unless (ref $input eq 'HASH' || ref $input eq 'gRSShopper::Record' || ref $input eq 'gRSShopper::Person');
	my $data= &db_prepare_input($dbh,$table,$input);


	my $sql   = "INSERT IGNORE INTO $table ";	# Prepare SQL Statement

	my(@sqlf, @sqlv, @sqlq) = ();

	for my $k (sort keys %$data) {
		push @sqlf, $k;
		push @sqlq, '?';
		push @sqlv, $data->{$k};
	}
	$sql .= '(' . join(', ', @sqlf) .') VALUES ('. join(', ', @sqlq) .')';


	my $sth = $dbh->prepare($sql);		# Execute SQL Statement
	if ($diag eq "on") {
		print "Content-type: text/html\n\n";
		print "$sql <br/>\n @sqlv <br/>\n";
	}

    	$sth->execute(@sqlv);

	if ($sth->errstr) { $vars->{msg} .= "DB INSERT ERROR: ".$sth->errstr." <p>"; }
	my $insertid = $dbh->{'mysql_insertid'};
	$sth->finish(  );
	return $insertid;


}
	# -------  Update---------------------------------------------------------
	# Updates record $where (must be ID) in table from hash
	# Adapted from SQL::Abstract by Nathan Wiger
	# -------  Update---------------------------------------------------------
	# Updates record $where (must be ID) in table from hash
	# Adapted from SQL::Abstract by Nathan Wiger
sub db_update {

	my ($dbh,$table,$input,$where,$msg) = @_;
 #print " A Content-type: text/html\n\n";
	unless ($dbh) { die "Error $msg Database handler not initiated"; }
	unless ($table) { die "Error $msg Table not specified on update"; }
	unless ($input) { die "Error $msg No data provided on update"; }
	unless ($where) { die "Error $msg Record ID not specified on update"; }

	if ($diag eq "on") { print "DB Update ($table $input $where)<br/>\n"; }
	die "Unsupported data type specified to update" unless (ref $input eq 'HASH' || ref $input eq 'Link' || ref $input eq 'Feed' || ref $input eq 'gRSShopper::Record' || ref $input eq 'gRSShopper::Feed');
 #print " BUpdating $table $input $where <br>";
	my $data = &db_prepare_input($dbh,$table,$input);
	#print "Data: $data <br>";
	#return "No data" unless ($data);

	my $sql = "UPDATE $table SET ";
	my(@sqlf, @sqlv) = ();

	for my $k (sort keys %$data) {
		push @sqlf, "$k = ?";
		push @sqlv, $data->{$k};

        }

	$sql .= join ', ', @sqlf;
  	$sql .= " WHERE ".$table."_id = '".$where."'";

  #print "\n D $sql <br>\n";
  #foreach $l (@sqlv) { print "\n$l ; \n"; }
	my $sth = $dbh->prepare($sql);

	if ($diag eq "on") { print "$sql <br/>\n @sqlv <br/>\n"; }
    	$sth->execute(@sqlv) or &status_error("Update failed: ".$sth->errstr);

	return $where;


}

	# -------  Increment---------------------------------------------------------
	#
	# For table type $gtable, record id $id, increment the value of $field by one
	# and return the new value of $field
sub db_increment {

	my ($dbh,$table,$id,$field,$from) = @_;

	&status_error("Database not initialized in db_increment") unless ($dbh);				# Check Input
	&status_error("Table not initialized in db_increment") unless ($table);
	&status_error("Field not initialized in db_increment") unless ($field);
	&status_error("ID number not initialized in db_increment - $from") unless ($id);

	my $idfield = $table."_id";
	my $prefix = $table."_";

	unless ($field =~ /$prefix/) { $field = $table."_".$field; }

	my $hits = db_get_single_value($dbh,$table,$field,$id);

	my $sql;
	if ($hits) { $sql = "update $table set $field = $field + 1 where $idfield = $id"; }
	else { $sql = "update $table set $field = 1 where $idfield = $id"; }
 	my $sth = $dbh->prepare($sql) or &status_error("Can't prepare the SQL in db_increment $table");
	$sth->execute or &status_error("Can't execute the query: ".$sth->errstr);
	$hits++;
	return $hits;

}

	# -------   Prepare Input ----------------------------------------------------
sub db_prepare_input {	# Filters input hash to contain only columns in given table

	my ($dbh,$table,$input) = @_;
	#print "DB Prepare Input ($table $input)<br/>\n";
	my $data = ();


						# Get a list of columns

	my @columns = &db_columns($dbh,$table);

						# Clean input for save
	foreach my $ikeys (keys %$input) {


		next unless (defined $input->{$ikeys});

		next if ($ikeys =~ /_id$/i);
		if (&index_of($ikeys,\@columns) < 0) {
			# print "Warning: input for aa".$ikeys."aa does not have a corresponding column in aa".$table."aa<p>";
			next;
		}
		# print "$ikeys = $input->{$ikeys} <br>";
		$data->{$ikeys} = $input->{$ikeys};
	}

	return $data;

}

	# -------   Count -------------------------------------------------------------

	# Count Number of Items in a Search
sub db_count {

	my ($dbh,$table,$where) = @_;

	my $stmtc = "SELECT COUNT(*) AS items FROM $table $where";

	my $sthc = $dbh -> prepare($stmtc);
	$sthc -> execute()  || die "Error: " . $dbh->errstr . " -- ".$stmtc;
	my $refc = $sthc -> fetchrow_hashref();
	my $count = $refc->{items};
	$sthc->finish( );
	unless ($count) { $count = 0; }
	return $count;

}

	# -------   Columns -----------------------------------------------------------
sub db_columns {


	my ($dbh,$table) = @_;			# Get a list of columns

	my @columns = ();
	my $showstmt = "SHOW COLUMNS FROM $table";

	my $sth = $dbh -> prepare($showstmt);
	$sth -> execute();
	while (my $showref = $sth -> fetchrow_hashref()) {
		push @columns,$showref->{Field};
	}
	return @columns;
}

	#-------------------------------------------------------------------------------
	#
	# -------   Database Tables ---------------------------------------------------------
	#
	# 		Returns the list of tables in the database
	#	      Edited: 28 March 2010
	#-----------------------------------------------------------------------------
sub db_tables {

	my ($dbh) = @_; my @tables;
	my $sql = "show tables";
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	while (my $hash_ref = $sth->fetchrow_hashref) {
		while (my($hx,$hy) = each %$hash_ref) { push @tables,$hy; }
	}
	return @tables;
}

	# -------   Update Vote ------------------------------------------------------                                                   UPDATE
sub update_vote {

	my ($dbh,$query) = @_;
	my $vars = $query->Vars;
	$vars->{vote_table} ||= "post";


	# Remove Previous Vote
	if ($Person->{person_id} && $vars->{vote_table} && $vars->{vote_post} ) {
		my $dsql = qq|DELETE FROM vote WHERE vote_person='$Person->{person_id}' AND vote_table='$vars->{vote_table}' AND vote_post='$vars->{vote_post}'|;
		$dbh->do($dsql);
	}


	# Create Current Vote
	my $crdate = time;
	$vote_id = &db_insert($dbh,$query,"vote",{vote_person=>$Person->{person_id},
		vote_post=>$vars->{vote_post},vote_table=>$vars->{vote_table}, vote_value=>$vars->{vote_value},
		vote_creator=>$Person->{person_id},vote_crdate=>$crdate});

	# Recalculate vote count for the post
	my $sth1 = $dbh->prepare(qq|SELECT SUM(vote_value) FROM vote WHERE vote_post=? AND vote_table=?|) or return $dbh->errstr;
	$sth1->execute($vars->{vote_post},$vars->{vote_table}) or return $dbh->errstr;
	my ($sum) = $sth1->fetchrow_array or $dbh->errstr;
	&db_update($dbh,"post",{post_votescore=>$sum},$vars->{vote_post},"Update vote in post");



	# Return the vote value
	if (sum) { return $sum; } else { return "0"; }

}

1;