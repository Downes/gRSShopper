# File functions: api_file_upload, api_url_upload, api_save_file

# API UPDATE ----------------------------------------------------------
# ------- File -----------------------------------------------------
#
# Retrieves the file uploaded, saves it, stores
# metadata as a 'file' entry, then creates a graph entry linking the new
# file with $table $id
#
# -------------------------------------------------------------------------

sub api_file_upload {

	my ($file) = @_;

	# File was actually uploaded before calling check_user() 
	# If you need to find it, search for multipart/form-data
	&api_save_file($file);
	# Return new graph output for the form
	my $newlist = &form_graph_list($vars->{table},$vars->{id},"file");
	&status_ok("file_graph_list",$newlist);
	exit;	
}

# API UPDATE ----------------------------------------------------------
# ------- URL -----------------------------------------------------
#
# Retrieves the file found at the URL supplied, saves it, stores
# metadata as a 'file' entry, then create a graph entry linking the new
# file with $table $id
#
# -------------------------------------------------------------------------

sub api_url_upload {

	# Upload the file
	my $file = &upload_url($vars->{value});
	&api_save_file($file);

	# Return new graph output for the form
	my $newlist = &form_graph_list($vars->{table},$vars->{id},"file");
	&status_ok("file_graph_list",$newlist);
	exit;
}

# API UPDATE ----------------------------------------------------------
# ------- API Save File -----------------------------------------------
#
# Save a file, then create a graph entry
# linking the new file with $table $id
#
# -------------------------------------------------------------------------

sub api_save_file {

	my ($file) = @_;

	# Reject unless there's a full file name
	&status_error("Can't find ".$file->{fullfilename}." file to save")
		unless ($file && $file->{fullfilename});

	$vars->{graph_table} ||= $vars->{table};
	$vars->{graph_id} ||= $vars->{id};
	&status_error("Graph table name not provided") unless ($vars->{graph_table});
	&status_error("Graph table ID not provided") unless ($vars->{graph_id});

	# Save the file
	my $file_record = &save_file($file);


	unless ($file_record) { &status_error("Error saving file $!"); }


	# Set up Graph Data
	return unless ($vars->{graph_id} && $vars->{graph_table});
	my $urltwo = $Site->{st_url}.$vars->{graph_table}."/".$vars->{graph_id};
	my $graph_typeval = "";
	if ($file_record->{file_type} eq "Illustration") { 
		$graph_typeval = $vars->{file_align} . "/" . $vars->{file_width}; }
	else { $graph_typeval = $file_record->{file_mime}; }


	# Save Graph Data
	my $graphid = &db_insert($dbh,$query,"graph",{
		graph_tableone=>'file', graph_idone=>$file_record->{file_id}, graph_urlone=>$file_record->{file_url},
		graph_tabletwo=>$vars->{graph_table}, graph_idtwo=>$vars->{graph_id}, graph_urltwo=>$urltwo,
		graph_creator=>$Person->{person_id}, graph_crdate=>time, graph_type=>$file_record->{file_type}, graph_typeval=>$graph_typeval});
	&status_error("Failed to save graph data : ".
	"file ". $file_record->{file_id}.
" ; ".$vars->{graph_table}." ". $vars->{graph_id}
) unless $graphid;



	# Make Icon (from smallest uploaded image thus far)

	#if ($file_record->{file_type} eq "Illustration") {


		my $filename = $file->{file_title};
		my $filedir = $Site->{st_urlf}.$Site->{up_image};

		my $icondir = $Site->{st_urlf}."files/icons/";
		my $iconname = $vars->{graph_table}."_".$vars->{graph_id}.".jpg";
		my $tmb = &make_thumbnail($filedir,$filename,$icondir,$iconname);
		
	#	print "Content-type: text/html\n\n";
	# 	print "Thumbnail: $tmb <p>";
	#}



}

1;
