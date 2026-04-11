# Keylist functions: keylist, api_keylist_update, api_keylist_remove

sub keylist {

  my ($sutocontent) = @_;
	my $script = {}; my $replace;

	&parse_keystring($script,$sutocontent);


	$script->{separator} = $script->{separator} || ", ";

	for (qw(prefix postfix separator)) {
		if ($script->{$_} =~ /(BR|HR|P)/i) {
			$script->{$_} = "<".$script->{$_}.">";
		}
	}



	our $ddbbhh = $dbh;
	#print " Finbding graph $script->{db},$script->{id},$script->{keytable} <br>";
	my @connections = &find_graph_of($script->{db},$script->{id},$script->{keytable});

	foreach my $connection (@connections) {

								# Get item data

								# Prepare SQL Query for each item
								# (We could probably combine into one
								# by making a large 'OR' out of all the ID
								# numbers...
		my $titfield = get_key_namefield($script->{keytable});
		my $klid = $script->{keytable}."_id";
		$script->{search} =~ s/'//; $connection =~ s/'//;

		my $keylistsql = qq|SELECT * FROM $script->{keytable} WHERE $klid = '$connection'|;


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
			my $kname = $c->{$titfield};
			if ($replace) { $replace .= $script->{separator}; }
			if ($script->{format} eq "text") { $replace .= qq|$kname|; }
			elsif ($script->{format}) {
				my $ftext = &format_record($dbh,$query,$script->{keytable},"$script->{format}",$c);
				$replace .= $ftext; }
			else { $replace .= qq|<a href="$Site->{st_url}$script->{keytable}/$connection" style="text-decoration:none;">$kname</a>|; $replace =~ s/\n/<br\/>/ig; }



		}
		$sth->finish();
	}


    return $replace;

}




# API UPDATE ----------------------------------------------------------
# ------- Keylist Update-----------------------------------------------
#
# Find or, if not found, create a new $key record named $value
# Then create a graph entry linking the new $key with $table $id
#
# -------------------------------------------------------------------------



sub api_keylist_update {

	my ($vars) = @_;
	my ($table,$key) = split /_/,$vars->{col_name};
 # 	die "Field does not exist" unless &__check_field($table,$vars->{col_name});
	my $table = $vars->{table};
	my $id = $vars->{id};
	my $value = $vars->{value};
	my $key = $vars->{key};
	my $noedit = $vars->{noedit};

	# Encode entities, then split list of input $value by ;
	use HTML::Entities;
	use utf8;							# Turns out if you don't also use this, encode_entities doesn't work
	$value =~ s/&amp;/&/ig;				# To avoid &amp;apos;
	$value = decode_entities($value);	# Decode entitiles so we can separate by semi-colons
	my @keynamelist = split /;/,$value;

	# For each member of the list...
	foreach my $keyname (@keynamelist) {
		$keyname = encode_entities($keyname); # Encode previously decoded entities

		# Trim leading, trailing white space
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
		my $graphid = &db_insert($dbh,$query,"graph",{
			graph_tableone=>$key, graph_idone=>$keyrecord->{$key."_id"}, graph_urlone=>$keyrecord->{$key."_url"},
			graph_tabletwo=>$table, graph_idtwo=>$id, graph_urltwo=>"",
			graph_creator=>$Person->{person_id}, graph_crdate=>time, graph_type=>"", graph_typeval=>""});

		# Save to current graph cache
		my $tod = $keyrecord->{$key."_id"};
		push @{$Site->{$key}->{$tod}->{$table}},$id;
	#	push @{$Site->{$table}->{$id}->{$key}},$tod;

	}

	# Return new graph output for the form
	
	my $newlist = &form_graph_list($table,$id,$key,'',$noedit);

	return ($key."_graph_list",$newlist);

}

# API UPDATE ----------------------------------------------------------
# ------- KeylistRemove -----------------------------------------------
#
# Remove any graph entry linking the new $key $value with $table $id
#
# -------------------------------------------------------------------------

sub api_keylist_remove {

	my $table = $vars->{table};
	my $id = $vars->{id};
	my $key = $vars->{key};
	my $keyid = $vars->{keyid};
	my $noedit = $vars->{noedit};
	unless ($table && $id && $key && $keyid) {
		&status_error("Missing input value (either table, id, key or keyid) from api_keylist_remove()");
	}

   # Remove Graph Database

	my $sql = "DELETE FROM graph WHERE graph_tableone=? AND graph_idone = ? AND graph_tabletwo =? AND graph_idtwo = ?";
	my $sth = $dbh->prepare($sql);
	$sth->execute($table,$id,$key,$keyid);
	$sth->execute($key,$keyid,$table,$id);

	# Return new graph output for the form
	my $newlist = &form_graph_list($table,$id,$key,'',$noedit);
	&status_ok($key."_graph_list",$newlist);

	exit;
}



1;
