

#           UPLOAD
#-------------------------------------------------------------------------------
	# -------   Upload File --------------------------------------------------------------
	#
	#
	#	      Edited: 21 January 2013, 30 May 2017
	#
	#----------------------------------------------------------------------

sub upload_file {

	# Assumes global input variable $query from CGI
	# Name of input field:  myfile
	my ($upload_file_name) = @_;
	my $filen = $vars->{file};
	$upload_file_name ||= "myfile";
	my $file = gRSShopper::File->new();
	#my $file;
	$file->{file_title} = $query->param($upload_file_name);

	$file->{file_dir} = $Site->{st_urlf} . "uploads";
	unless (-d $file->{file_dir}) { mkdir $file->{file_dir}, 0755 or die "Error 3857 creating upload directory $file->{file_dir} $!"; }
	unless ($file->{file_title}) { $vars->{msg} .= " No file was uploaded."; }

	# Prepare Filename
	my ( $ffname, $ffpath, $ffextension ) = fileparse ( $file->{file_title}, '\..*' );
	$file->{file_title} = $ffname . $ffextension;
	$file->{file_title} = &sanitize_filename($dbh,$file->{file_title});

	# Set File Upload Directory
	($file->{filetype},$file->{file_dir}) = &file_upload_dir($ffextension);
	my $fulluploaddir = $Site->{st_urlf} . $file->{file_dir};
	unless (-d $fulluploaddir) { 
		system "mkdir -p $fulluploaddir"; 
		system "chmod 0755 $fulluploaddir";
		&error($dbh,"","","Error 4053 Failed to create upload directory") unless (-d $fulluploaddir);
	}

	# Store the File
	my $upload_filehandle = $query->upload($upload_file_name) 
		or &error($dbh,"","","Failed to upload $upload_fullfilename $!");
	$upload_filedirname = $file->{file_dir}.$file->{file_title};
	$upload_fullfilename = $Site->{st_urlf}.$upload_filedirname;

	# Prevent Duplicate File Names  (creates filename.n.ext where n is the increment number)

	my ($upload_fulldirname,$upload_fullfilename,$upload_filedirname) = &unique_filename($file,$upload_fullfilename);

	open ( UPLOADFILE, ">$upload_fullfilename" ) or &error($dbh,"","","Failed to upload $upload_fullfilename $!");
	binmode UPLOADFILE;
	while ( <$upload_filehandle> ) { print UPLOADFILE; }
	close UPLOADFILE;

	$file->{fullfilename} = $upload_fullfilename;


	return $file;


}

	# -------   Upload URL ---------------------------------------------------------------
	#
	#
	#	      Edited: 21 January 2013, 30 May 2017
	#
	#----------------------------------------------------------------------
sub upload_url {

	my ($url) = @_;

	$vars->{msg} .= "<br>Downloading $url...  ";
	return unless ($url);

	# Chop seo and such (if there are exceptions to these I'll fix them in the future)
	$ url =~ s/\?(.*?)$//;
	$ url =~ s/#(.*?)$//;

	my $file = gRSShopper::File->new();



	# Prepare Filename
	my @parts = split "/",$url;
	$file->{file_title} = pop @parts;
	$file->{file_title} = &sanitize_filename($dbh,$file->{file_title});

	# Set File Upload Directory
	my @pparts = split /\./,$file->{file_title};
	my $ffextension = "." . pop @pparts;
	($file->{filetype},$file->{file_dir}) = &file_upload_dir($ffextension);
	my $fulluploaddir = $Site->{st_urlf} . $file->{file_dir};
	unless (-d $fulluploaddir) { mkdir $fulluploaddir, 0755 or die "Error 1892 creating upload directory $upload_dir $!"; }
	$file->{filedirname} = $file->{file_dir}.$file->{file_title};
	$file->{fullfilename} = $Site->{st_urlf}.$file->{filedirname};


	# Prevent Duplicate File Names  (creates filename.n.ext where n is the increment number)
	my ($upload_fulldirname,$upload_fullfilename,$upload_filedirname) = &unique_filename($file,$file->{fullfilename});

	$file->{filedirname} = $upload_fulldirname;
	$file->{fullfilename} = $upload_fullfilename;


	# Get and Store the File

	my $result = getstore($url,$file->{fullfilename});
	unless ($result eq "200") {
		&status_error(qq|\n
			<br>Error $result while trying to download<br><a href="$url">$url</a> <br>
			Try saving manually and uploading from your computer|);
		$file->{fullfilename} = ""; $file->{file_title} = "";
		return 0;
	}

	return $file;

}

	# ---- Unique Filename ---------------------
	#
	# Used by upload_url and upload_file
sub unique_filename {

	my ($file,$upload_fullfilename,$upload_filedirname) = @_;

	my $ccnt = 0;
	while (-e $upload_fullfilename) {

		# Get extension and remove from file title
		my ($ext) = $file->{file_title} =~ /(\.[^.]+)$/;
		$file->{file_title} =~ s/(\.[^.]+)$//;

		# Get and increment an existing file name counter, or
		if ($file->{file_title} =~ m/\./) {
			my ($incr) = $file->{file_title} =~ /(\.[^.]+)$/;
			$incr =~ s/\.//;
			$file->{file_title} =~ s/(\.[^.]+)$//;
			$incr = $incr +1;
			$file->{file_title} = $file->{file_title}.".".$incr.$ext;

		# or create a new file name counter
		} else {
			$file->{file_title} = $file->{file_title} .".1".$ext;
		}

		# Set the new file name variables
		$upload_filedirname = $file->{file_dir}.$file->{file_title};
		$upload_fullfilename = $Site->{st_urlf}.$upload_filedirname;
		$ccnt++; last if ($ccnt > 100000);

	}

	return ($upload_fulldirname,$upload_fullfilename);

}

	# -------   Sanitize Filename --------------------------------------------------------
sub sanitize_filename {

	my ($dbh,$filename) = @_;
	my $safe_filename_characters = "a-zA-Z0-9_.-";

	$filename =~ tr/ /_/;
	$filename =~ s/[^$safe_filename_characters]//g;
	if ( $filename =~ /^([$safe_filename_characters]+)$/ )  { $filename = $1;  }
	else { &error($dbh,"","","Filename $filename contains invalid characters"); }

	return $filename;

}

	# -------   Set File Upload Directory --------------------------------------------------------
sub file_upload_dir {

	my ($ff) = @_;
	my $filetype = "";
	my $dir = "";

	if ($ff =~ /\.jpg|\.jpeg|\.gif|\.png|\.bmp|\.tif|\.tiff|\.webp/i) {
		$filetype = "image"; $dir = $Site->{up_image} || "files/images/";
	} elsif ($ff =~ /\.doc|\.txt|\.pdf/i) {
		$filetype = "doc"; $dir = $Site->{up_docs} || "files/documents/";
	} elsif ($ff =~ /\.ppt|\.pps/i) {
		$filetype = "slides"; $dir = $Site->{up_slides} || "files/slides/";
	} elsif ($ff =~ /\.mp3|\.wav/i) {
		$filetype = "audio"; $dir = $Site->{up_audio} || "files/audio/";
	} elsif ($ff =~ /\.flv|\.mp4|\.avi|\.mov|\.webm/i) {
		$filetype = "video"; $dir = $Site->{up_video} || "files/video/";
	} else {
		$filetype = "other"; $dir = $Site->{up_files} || "files/files/";
	}

	unless ($dir =~ /\/$/) { $dir .= "/"; }


	return ($filetype,$dir);
}

	# -------  Auto Make Icon  --------------------------------------------------------
	#
	#
	#	      Edited: 21 January 2013
	#
	#----------------------------------------------------------------------
	#
	#  Used with auto_post()
	#  Find an associated media image, download it as a file,
	#  and set it up as an icon
	#
sub auto_make_icon {

	my ($table,$id) = @_;



	my $file = &auto_upload_image($table,$id);					# Upload image found in RSS feed
	if ($file =~ /Error:/) { return "Error uploading image"; }
	$file->{file_id} =  &db_insert($dbh,$query,"file",$file);			# Save file record (for later graphing)

	my $icondir = $Site->{st_icon} || $Site->{st_urlf}."files/icons/";		# Define (or make) icon directory
	unless (-d $icondir) { mkdir $icondir, 0755 or die "Error creating icon directory $icondir $!"; }


	my $filename = $file->{file_title};						# Set image and icon filenames and directories
	my $filedir = $Site->{st_urlf}."files/images/";
	my $icondir = $Site->{st_urlf}."files/icons/";
	my $iconname = $table."_".$id.".jpg";
	my $icon = &make_thumbnail($filedir,$filename,$icondir,$iconname);		# make the icon


	if ($icon) {									# Update icon value in post record
		&db_update($dbh,$table,{post_icon=>$icon},$id,"Update icon in $table"); # (not strictly necessary but loads image a bit faster)
	}

	return $file;

}

	# -------  Auto Upload Image  --------------------------------------------------------
	#
	#
	#	      Edited: 25 January 2013
	#
	#----------------------------------------------------------------------
sub auto_upload_image {

	my ($table,$id) = @_;

	my @graph = &find_graph_of($table,$id,"media");
	my $media; foreach my $media_id (@graph) {					# Find media associated with record
		$media = &db_get_record($dbh,"media",{media_id=>$media_id});		#    keep searching till you find an image
		next unless (($media->{media_mimetype} =~ /image/ || $media->{media_type} =~ /image/));
		my $uploadedfile = &upload_url($media->{media_url});			#    then upload that image to the server
		if ($uploadedfile->{fullfilename}) {					#    if the upload was successful
			return $uploadedfile ;						#    return the newly created file record as an object
		}

	}
	return "Error: could not find a record to upload.";

}

	# -------  Make Thumbnail  --------------------------------------------------------
	#
	#
	#	      Edited: 21 January 2013
	#
	#----------------------------------------------------------------------
sub make_thumbnail {

	my ($dir,$img,$icondir,$iconname) = @_;


	return "Error: need both directory and file" unless ($img && $dir);
	my $tmb = $img;
	if ($iconname) { $tmb = $iconname; }
	else { $tmb =~ s/\.(.*?)$/_tmb\.$1/; }

	my $dimf = $dir . $img;			# Full filename of original
	my $domf = $icondir . $tmb;		# Full filename of new icon

	unless (-d $icondir) { 
		system "mkdir -p $icondir"; 
		system "chmod 0755 $icondir";
		&error($dbh,"","","Error 4053 Failed to create upload directory") unless (-d $icondir);
	}

  my $image = Image::Resize->new($dimf);
	my $gd = $image->resize(100, 100);
	open(FH, '>'.$domf);
	print FH $gd->jpeg() or return "Error: writing $domf image file: $error";
	close(FH);


  return $tmb;   # Return full filename of icon
}

 # slurp
 # Quick and easy file read

sub slurp {
    my $file = shift;
    open my $fh, '<', $file or die;
    local $/ = undef;
    my $cont = <$fh>;
    close $fh;
    return $cont;
}
  #-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	#
	#           Getting and Storing Data
	#
	#-------------------------------------------------------------------------------
	# -------   Harvest: Process Data ------------------------------------------------------
	# URL is stored in gRSShopper feed record, $feed->{feed_link}
	# If URL is known and in feed record
	# my $feedrecord = gRSShopper::Feed->new({dbh=>$dbh,id=>$feedid});
	# Otherwise
	#	$feedrecord->{feed_link} = $url;
	#	&get_url($feedrecord);
	#       my $feedrecord = gRSShopper::Feed->new({dbh=>$dbh});
sub get_url {

	my ($feedrecord,$feedid) = @_;

	$feedrecord->{feedstring} = "";
	my $cache = &feed_cache_filename($feedrecord->{feed_link},$Site->{feed_cache_dir});
	my $editfeed = qq|<a href="$Site->{st_cgi}admin.cgi?action=edit&feed=$feedid">Edit Feed</a>|;


  #	if ((time - (stat($cache))[9]) < (60*60)) {			# If the file is less than 1 hour old

  #		&diag(1,"Getting file from common cache<br>");
  #		$feedrecord->{feedstring} = &get_file($cache);

  #	} else {

		&diag(1,"Harvesting $feedrecord->{feed_link}<br>\n");





	my $ua = LWP::UserAgent->new;
	$ua->agent("Mozilla/8.0");
	$ua->ssl_opts( verify_hostname => 0 ,SSL_verify_mode => 0x00);

	my $server_endpoint = $feedrecord->{feed_link};

	# set custom HTTP request header fields
	my $req = HTTP::Request->new(GET => $server_endpoint);

	# set up user agent
	my $response = $ua->request($req);




	if ($response->is_success) {
		# my $message = $response->decoded_content;
		# my $message .=  "$Site->{st_name}<br>Request Successful\n<br>\nResults returned from $server_endpoint <br> $editfeed <br>";
		#&send_email('stephen@downes.ca','stephen@downes.ca',"gRSShopper Harvest Succeeded",$message,"htm");

	} else {

		my $message = "$Site->{st_name}<br>gRSShopper Harvest Failed \n<br>\n".
			$response->code. "<br>\n".
			$response->message. "<br>\n".
			$server_endpoint. "<br>\n";

		&log_cron(0,$message);
		#&send_email('stephen@downes.ca','stephen@downes.ca',"gRSShopper Harvest Failed",$message,"htm");
		return;
	}



		$feedrecord->{feedstring} = $response->decoded_content();
		$feedrecord->{feedstring} =~ s/^\s+//;

		unless ($feedrecord->{feedstring}) {
			&diag(1,"ERROR: Couldn't get $feedrecord->{feed_link} <br>\n\n");
			return;
		}

									# Save common cache
  #		open FOUT,">$cache" or die qq|Error opening to write to $cache: $! \nCheck your Feed Cache Location at this location: \n$Site->{st_cgi}admin.cgi?action=harvester\n\n|;
  #		print FOUT $feedrecord->{feedstring}  or die "Error writing to $cache: $!";
  #		close FOUT;
  #		chmod 0666, $cache or &diag(1,"Couldn't chmod $cache: $! <br>\n");
  #	}



	return $feedrecord->{feedstring};

}
sub feed_cache_filename  {


	my ($feedurl,$feed_cache_dir) = @_;

	my $feed_file = $feedurl;
	unless ($feed_cache_dir =~ /\/$/) {  $feed_cache_dir .= "/"; }
	$feed_file =~ s/http:\/\///g;
	$feed_file =~ s/https:\/\///g;
	$feed_file =~ s/\%|\$|\@//g;
	$feed_file =~ s/(\/|=|\?)/_/g;

	return $feed_cache_dir.$feed_file;

}

	# -------  Mime Types ----------------------------------------------------------

	# Returns a mime type based on extension of filename
sub mime_type {

	my ($url) = @_;

	my $mime_table = {
	      ai => "application/postscript",
	      aiff => "audio/x-aiff",
	      au => "audio/basic",
	      avi => "video/x-msvideo",
	      bck => "application/VMSBACKUP",
	      bin => "application/x-octetstream",
	      bleep => "application/bleeper",
	      class => "application/octet-stream",
	      com => "text/plain",
	      crt => "application/x-x509-ca-cert",
	      csh => "application/x-csh",
	      dat => "text/plain",
	      doc => "application/msword",
	      docx => "application/msword",
	      dot => "application/msword",
	      dvi => "application/x-dvi",
	      eps => "application/postscript",
	      exe => "application/octet-stream",
	      gif => "image/gif",
	      gtar => "application/x-gtar",
	      gz => "application/x-gzip",
	      hlp => "text/plain",
	      hqx => "application/mac-binhex40",
	      htm => "text/html",
	      html => "text/html",
	      htmlx => "text/html",
	      htx => "text/html",
	      imagemap => "application/imagemap",
	      jpe => "image/jpeg",
	      jpeg => "image/jpeg",
	      jpg => "image/jpeg",
	      mcd => "application/mathcad",
	      mid => "audio/midi",
	      midi => "audio/midi",
	      mov => "video/quicktime",
	      movie => "video/x-sgi-movie",
		mp3 => "audio/mpeg",
	      mpeg => "video/mpeg",
	      mpe => "video/mpeg",
	      mpg => "video/mpeg",
	      pdf => "application/pdf",
	      png => "image/png",
	      ppt => "application/vnd.ms-powerpoint",
	      pptx => "application/vnd.ms-powerpoint",
	      ps => "application/postscript",
	      'ps-z' => "application/postscript",
	      qt => "video/quicktime",
	      rtf => "application/rtf",
	      rtx => "text/richtext",
	      sh => "application/x-sh",
	      sit => "application/x-stuffit",
	      tar => "application/x-tar",
	      tif => "image/tiff",
	      tiff => "image/tiff",
	      txt => "text/plain",
	      ua => "audio/basic",
	      wav => "audio/x-wav",
	      xls => "application/vnd.ms-excel",
	      xbm => "image/x-xbitmap'",
	      zip => "application/zip"
	     };


	my ($dirname,$atts) = split /\?/,$url;
	my @slices = split /\//,$dirname;
	my $filename = pop @slices;
	my @harray = split /\./,$filename;
	my $ext = pop @harray;
	$ext = lc($ext);
	my $mimetype = $mime_table->{$ext};
	unless ($mimetype) { $mimetype = "unknown"; }

	return $mimetype;

}

# Jusdt a quick and dirty read file

sub read_text_file {

   my ($file) = @_;
	 open(FILE, $file) or return "Can't read file $file [$!]\n";
	 $document = <FILE>;
	 close (FILE);
	 return $document;

}

# Just a quick and dirty save file

sub write_text_file {

   my ($file,$contents) = @_;
	 open(FILE, ">$file") or return "Can't open file $file [$!]\n";
	 print FILE $contents;
	 close (FILE);
	 return 1;

}



sub arrayAdd {

	my ($term_input,$list) = @_;
	my ($term,$filename,@lines) = &arrayManage($term_input,$list,"arrayAdd");

	push @lines,$term unless (grep(/^$term$/i, @lines));
	open FILE,">$filename";
	foreach $line (@lines) { 
		print FILE $line."\n" or &status_error("Unable to save $term_input to $list");
	}
	close FILE; return 1;

}

sub arrayRemove {

	my ($term_input,$list) = @_;
	my ($term,$filename,@lines) = &arrayManage($term_input,$list,"arrayRemove");

	my $matchstring = $term."\n"; my@nlines;
	foreach my $l (@lines) { push @nlines,$l unless ($l eq $matchstring); }
	write_file($filename, @nlines);

}

sub arrayCheck {

	my ($term_input,$list) = @_;
	my ($term,$filename,@lines) = &arrayManage($term_input,$list,"arrayCheck");

	open(FILE,$filename);

	# Looking for an exact match in a line
	if (grep{/^$term\n/} <FILE>){
		#print qq|<b>The word "$word" was found $filename.</b><br>|;
		close FILE; return 1;
	}

	#print qq|The word "$word" was not found in $filename.<br>|;
	close FILE; return 0;

}

sub arrayReturn {
	my ($list) = @_; my $term_input = "return";
	my ($term,$filename,@lines) = &arrayManage($term_input,$list,"arrayReturn");
	return @lines;
}


sub arrayClear {
	my ($list) = @_; my $term_input = "clear";
	my ($term,$filename,@lines) = &arrayManage($term_input,$list,"arrayClear");
	if (-e $filename) { unlink($filename) or &status_error("Can't unlink $file: $!"); }
	return;
}

# used by all the array functions, restricts content for security
sub arrayManage {

	my ($term,$list,$source) = @_;
	&status_error("Module File::Slurp not loaded") unless (&new_module_load($query,"File::Slurp"));
	&status_error("Must specify both 'list' and 'term' to add to array")
		unless($term && $list);
	&status_error("List name '$list' can only be alphanumeric characters") 
		unless ($list =~ /^[\p{Alnum}\s-_]{0,30}\z/ig);
	&status_error("Term name '$term' can only be alphanumeric characters ($source)") 
		unless ($term =~ /^[\p{Alnum}\s-_:]{0,60}\z/ig) ;	# Restrict to Alpha-Numerics
													# To keep things secure

													# Get the file contents
	my $filedir = $Site->{st_cgif}."data/lists/";
	mkdir ($filedir) unless (-e $filedir) || &status_error("Could not make $filedir in arrayAdd(): $!)");
	my $filename = $filedir.$list;
	my @lines;
	@lines = read_file($filename) if (-e $filename);
	foreach $line (@lines) { $line =~ s/\n//g;$line =~ s/\r//g; }		# Remove line feeds


	return ($term,$filename,@lines);
}


1;