	sub admin_database {

		my ($dbh,$query,$sst,$columns) = @_;


		# Permissions
		return unless (&is_viewable("admin","database"));
		$Site->{admin_pane}	= "database";
		my $adminlink = $Site->{st_cgi}."admin.cgi";

		if ($vars->{dbmsg}) { $vars->{dbmsg} = qq|<p class="notice"><br>$vars->{dbmsg}</p>|; }
		my $content = qq|$vars->{dbmsg}<h2>Database</h2>
		<p>Get database information and manage database tables.</p>|;

exit;
		# Manage Database

		# Create generic tables dropdown
		my @tables = $dbh->tables();
		my $table_dropdown;
		foreach my $table (@tables) {

			# Remove database name from specification of table name
			if ($table =~ /\./) {
				my ($db,$dt) = split /\./,$table;
				$table = $dt;
			}

			# User cannot view or manipulate person or config tables
			next if ($table eq "person" || $table eq "config");
			$table=~s/`//g;  #`

			my $sel; if ($table eq $sst) { $sel = " selected"; } else {$sel = ""; }
			$table_dropdown  .= qq|		<option value="$table"$sel>$table</option>\n|;
		}




		$content .= qq|
			<h3>Manage Database</h3>
			pp
			<div class="adminpanel">eeee
			<form method="post" action="admin.cgi">Select table:
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">
			<select name="stable">$table_dropdown</select><br>\n
			<select name="action">\n
			<option value="showcolumns">Show Columns</option>\n
			<option value="db_add_column">Add Column</option>\n
			<option value="removecolumnwarn">Remove Column</option>\n
			</select>\n
			<input type="text" name="col" value="" size="12"  style="height:1.8em;"/>\n
			<input type="submit" value="Submit" class="button">\n
			</select></form></ul>\n|;

		# Display results from previous processing
		if ($columns) { $content .= $columns; }
		$content .= "<br/>";
		$content .= "</div>";


		# Back Up Database


		$content .= qq|
			<br/><h3>Back Up Database</h3>
			<div class="adminpanel">
			<form method="post" action="admin.cgi">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<input type="hidden" value="backup_db" name="action">
			<select name="backup_table">
			<option value="all">All Tables</option>
			$table_dropdown
			</select>

			<input type="submit" value="Back Up Database">
			</form>
			</div>|;


		# Add and Drop Tables

		$content .= qq|
			<br/><h3>Add Table</h3>
			<div class="adminpanel">
			<form method="post" action="admin.cgi">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<input type="hidden" value="add_table" name="action">
			<input type="text" name="add_table">
			<input type="submit" value="Add Table">
			</form>
			</div>|;

		$content .= qq|
			<br/><h3>Drop Table</h3>
			<div class="adminpanel">
			<form method="post" action="admin.cgi">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<input type="hidden" value="drop_table" name="action">
			<select name="drop_table">
			$table_dropdown
			</select>
			<input type="submit" value="Drop Table"><br>
			<span style="color:red;">Warning</span>: dropping a table will eliminate all data in the table. Table data will be saved in a backup file.
			</form>
			</div>|;


		# Import from File


		my $tout = qq|<select name="table">$table_dropdown</select><br/>\n|;


		$content  .= qq|
			<br/><h3>Import Data From File</h3>
			<div class="adminpanel">
			The file needs to be preloaded on the server. The system expects a tab delimited file with
			field names in the first row. Importer will ignore field names it does not recognize.<br/><br/>
			<form method="post" action="$adminlink" enctype="multipart/form-data">
			<input type="hidden" name="action" value="import">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<table cellpadding=2>
			<tr><td>Import into table:</td><td>$tout</td></tr>
			<tr><td>File URL:</td><td><input type="text" name="file_url" size="40"></td></tr>
			<tr><td>Or Select:</td><td><input type="file" name="myfile" /></td></tr>
			<tr><td>Data Format:</td><td><select name="file_format"><option value="">Select a format...</option>
			<option value="tsv">Tab delimited (TSV)</option>
			<option value="csv">Comma delimited (CSV)</option>
			<option value="json">JSON</option></select></td>
			<tr><td colspan=2><input type="submit" value="Import" class="button"></tr></tr></table>
			</form></div>|;

		# Export data

		$content  .= qq|
			<br/><h3>Export Data</h3>
			<div class="adminpanel">
			<form method="post" action="$adminlink">
			<input type="hidden" name="action" value="export_table">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<table cellpadding=2>
			<tr><td>Export from table:</td><td>$tout</td></tr>
			<tr><td>Data Format:</td><td><select name="export_format"><option value="">Select a format...</option>
			<option value="tsv">Tab delimited (TSV)</option>
			<option value="csv">Comma delimited (CSV)</option>
			<option value="json">JSON</option></select></td>
			<tr><td colspan=2><input type="submit" value="Export" class="button"></tr></tr></table>
			</form></div>|;


		$content .=  qq|</table></ul>|;


		$content .= qq|
			<h3>Create Data Pack</h3><ul>
			Data Packs contain the <i>data</i> from several tables in addition to the basic table structure
			for all tables (which may be modified above). These are intended to create new blank sites out
			of the site you already have, with predefined pages, templates, or whatever.
			Data Pack scripts use <b>mysqldump</b> and assume
			you are using MySQL and Linux. If you are not set up this way you will need to replace
			the export scripts with scripts that will work for your system. Saving a Data Pack
			writes over an existing Data Pack with that name.<br/><br/>
			<form method="post" action="admin.cgi"><table cellpadding="3" cellspacing="0" border="1">
			<input type="hidden" name="action" value="db_pack">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<tr><td>Create Data Pack named</td><td><input type="text" name="pack" size="20"></td></tr>
			<tr><td valign="top">Use fields:</td><td><select name="fields" multiple="multiple" size="8">|;

		foreach my $tt (@tables) {
			$tt=~s/`//g;              #`
			next if ($tt =~ /config/);
			next if ($tt =~ /person/);
			next if ($tt =~ /cache/);
			$content  .= qq|	<option value="$tt">$tt</option>\n|;

		}
		$content .= qq|</select></td></tr><tr><td>&nbsp;</td>
			<td><input type="submit" value="Create Data Pack"></td></tr></table></form>
			</ul>|;



		$Site->{ServerInfo}  =  $dbh->{'mysql_serverinfo'};
		$Site->{ServerStat}  =  $dbh->{'mysql_stat'};

		$content .= qq|
			<h3>Database Information</h3><br/><ul>
			&nbsp;&nbsp;Server Info: $Site->{ServerInfo} <br/>
			&nbsp;&nbsp;Server Stat: $Site->{ServerStat}<br/><br/></ul>|;



		&admin_frame($dbh,$query,"Admin General",$content);					# Print Output
		exit;



	}

	sub admin_db_export {

		my ($dbh,$query) = @_;
		my $vars = $query->Vars;



		if ($vars->{export_format} eq "json") {
			print "Content-type: application/json\n\n";
	    my $keyfield = $vars->{table}."_id";
			#my $hash_ref = $dbh->selectall_hashref(qq|select * from $vars->{table}|,$keyfield);
	    my $export->{$vars->{table}} = $dbh->selectall_hashref(qq|select * from $vars->{table}|,$keyfield);
			use JSON;
			print to_json($export, {pretty => 1});
			exit;
		} else {


			print "Content-type: text/plain\n\n";
			my $sth= $dbh->prepare(qq|select * from $vars->{table}|);
			$sth->execute();

			my $fields = join "\t" , @{$sth->{NAME}};
			print $fields,"\n";

			my $count = 0;
			while (my $row = $sth->fetchrow_arrayref()) {
				foreach my $r (@$row) { $row[$count] =~ s/\t/    /g; $count++;}
				print join( "\t", map( {$dbh->quote($_)} @$row)),"\n";
			}
		}
		$dbh->disconnect;

	}

	sub admin_db_pack {

		my ($dbh,$query) = @_;
		my $vars = $query->Vars;
		&error($dbh,"","","No Pack Name specified") unless ($vars->{pack});
													# Make Pack Directory
		my $packsdir = $Site->{st_cgif}."packs/".$vars->{pack};
		unless (-d $packsdir) { mkdir $packsdir, 0755 or die "Error 1062 creating upload directory $packsdir $!"; }

													# Clearn out existing files
		opendir (DIR,$packsdir);
		my @files = grep(/grsshopper/, readdir (DIR));
		closedir (DIR);
		foreach my $file (@files) { unlink "$packsdir/$file"; }

													# Execute shell script
		my $pwd = $Site->{database_pwd}; $pwd =~ s/\&/\\\&/g; 					# cgi-bin/data_pack.sh
		my @fields = split /\0/,$vars->{fields};
		my $fields = join " ",@fields;

		my $symsg = qq|./data_pack.sh $vars->{pack} $pwd $Site->{db_name} $fields|;
		print "Content-type: text/html\n\n";
		print $symsg,"<p>";
		my $systring = `./data_packa.sh $vars->{pack} $pwd $Site->{db_name} $fields`;
		$vars->{dbmsg} .= "$systring<br>Data Pack a <b>$vars->{pack}</b> Created";
		&admin_database($dbh,$query);
	}

	sub admin_db_backup {

		my ($table,$p) = @_;

		my $output = "Backing up $table";
		if ($table eq "all") {$output .= " tables"; }
		$output .= "<br>";
		my $savefile = &db_backup($table);
		my $saveurl = $savefile;
		$saveurl =~ s/$Site->{st_urlf}/$Site->{st_url}/;

		my $output .= qq|Table '$table' backed up to <a href="$saveurl">$savefile</a>|;
		$output .= $vars->{backup_message};

		if ($p) { $vars->{dbmsg} .= $output; &admin_database($dbh,$query,$table,""); }
		else { return $output; }

	}

	sub admin_db_add_table {

		my ($table) = @_;


		# Normalize table names
		$table =~ s/[^a-zA-Z0-9_]//g;
		$table = lc($table);

		# Create the table
		my $content = "<h3>Create Table</h3>";
		$vars->{dbmsg} .= &db_create_table($dbh,$table) || $vars->{msg};

		# Print Output
		&admin_database($dbh,$query,$table,"");

		# Done


	}

	sub admin_db_drop_table {

		my ($table) = @_;


		# Back up table
		my $savemsg = &admin_db_backup($table);

		# Drop table
		my $dropmsg = &db_drop_table($dbh,$table);

		# Print Output
		$vars->{dbmsg} .= "$savemsg <br>$dropmsg";
		&admin_database($dbh,$query,$table,"");

	}


	# --------------------------------------   Update Config -----------------------------------------------
	#
	#    Accept user input from admin and update the config table (using reset flag)
	#
	# ------------------------------------------------------------------------------------------------------

1;
