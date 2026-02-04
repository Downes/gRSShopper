#     OUTPUT and PUBLISH



#
#    Quick Show Page
#
# Looks for cached version of page at a file location, and prints it if it's found
# Otherwise returns in order to generate the page dynamically
# Override with &force=yes
#

sub quick_show_page {

	my ($page_dir,$table,$id,$format) = @_;

	my $page_file = $page_dir.$table."/".$id.".".$format;

	return unless (-e $page_file);
  print "Content-type: text/html\n\n";
	open FILE, $page_file or die $!;
	while (<FILE>) { print $_; }
	close FILE;
  &record_hit($table,$id);
  if ($format eq "viewer") {
    &record_was_read($table,$id);
	  &output_record($dbh,$query,$table,$id,$format);
  }  # Updates cache version after read in viewer
	exit;
}

sub quick_show_search {

	my ($search_dir,$table,$q,$start,$format) = @_;
	$q =~ s/[^a-zA-Z0-9 -]//g; 
	
	my $page_file = $search_dir.$table.".".$q.".".$start.".".$format;

  	return unless (-e $page_file);

	open FILE, $page_file or die $!;
	while (<FILE>) { print $_; }
	close FILE;

	exit;
}

#-------------------------------------------------------------------------------


	# -------   Print Record ------------------------------------------------------

            # Prints a record to its proper file location  ie. post=123 prints to /post/123

# -------   Print Record  ------------------------------------------------------
# Writes page HTML into a sharded path:
#   scheme 100 :  id=78157 -> /post/781/57/index.html
# Also writes the redirect shard (if this is a 'post' with a valid http/https link):
#   $Site->{st_urlf}/_rd/781/57  (file contains just the URL + newline)
#
# Returns the numeric id on success.

sub print_record {
    my ($table,$id_number,$format,$context) = @_;

    die "The Table not specified in request" unless ($table);
    die "ID not specified in request"        unless ($id_number);
    $format = "html";  # write HTML pages to disk

    # Fetch the record
    my $print_record = &db_get_record($dbh,$table,{$table."_id"=>$id_number})
        or die "Error getting record $table $id_number";

    # Page title
    $print_record->{page_title} =
           $print_record->{$table."_title"}
        || $print_record->{$table."_name"}
        || $print_record->{$table."_noun"}
        || ucfirst($table)." ".$print_record->{$table."_id"}
        || "Untitled";

    # Build page content
    $print_record->{page_content} = &format_record($dbh,$query,$table,$format,$print_record);

    # Header/footer templates
    my ($header_template, $footer_template) = ("static_header", "static_footer");
    #if ($table eq "presentation" && $format =~ /htm/i) {
    #    ($header_template, $footer_template) = ("presentation_header", "presentation_footer");
    #}

    # Wrap with header/footer
    $print_record->{page_content} =
        &db_get_template($dbh,$header_template,$print_record->{page_title}) .
        $print_record->{page_content} .
        &db_get_template($dbh,$footer_template,$print_record->{page_title});

    # Final formatting
    $print_record->{type}  = $table;
    $print_record->{title} = $print_record->{$table."_title"} || $print_record->{$table."_name"} || "Untitled";
    &format_content($dbh,$query,$options,$print_record);

    my $output = $print_record->{page_content};

    # -------- Sharded paths --------
    my $SHARD_SCHEME = 100;  # 100 => 781/57 ; set 1000 for 78/157 if you switch later

    my ($parent, $leaf);
    if ($SHARD_SCHEME == 100) {
        $leaf   = $id_number % 100;        # 57
        $parent = int($id_number / 100);   # 781
    } else { # 1000
        $leaf   = $id_number % 1000;       # 157
        $parent = int($id_number / 1000);  # 78
    }

    # Base dir for this content type (e.g., /var/www/www.downes.ca/html/post)
    my $base_dir  = File::Spec->catdir($Site->{st_urlf}, $table);
    my $page_dir  = File::Spec->catdir($base_dir, $parent, $leaf);
    my $page_file = File::Spec->catfile($page_dir, 'index.html');

    # Ensure page dir exists
    unless (-d $page_dir) {
        make_path($page_dir, { mode => 0775 }) or die "make_path($page_dir) failed: $!";
    }

    # Atomic write of the page (UTF-8)
    my $tmp = "$page_file.tmp.$$";
    open my $pfh, '>', $tmp or die "Failed to open $tmp for write: $!";
    binmode($pfh, ':encoding(UTF-8)');
    print {$pfh} $output or die "Print failure: $!";
    close $pfh or die "Close failure on $tmp: $!";
    chmod 0644, $tmp;
    rename $tmp, $page_file or die "rename($tmp => $page_file) failed: $!";

    # -------- Write redirect shard for THIS record (only when applicable) --------
    # Host-scoped RD base: /var/www/www.downes.ca/html/_rd
    if ($table eq 'post') {
        my $url = $print_record->{post_link} // $print_record->{$table."_link"} // '';
        $url =~ s/^\s+|\s+$//g;  # trim

        if ($url =~ m{^https?://}i) {  # only http/https targets
            my $rd_base = File::Spec->catdir($Site->{st_urlf}, '_rd');
            my $rd_dir  = File::Spec->catdir($rd_base, $parent);
            my $rd_file = File::Spec->catfile($rd_dir, $leaf);

            unless (-d $rd_dir) {
                make_path($rd_dir, { mode => 0755 }) or die "make_path($rd_dir) failed: $!";
            }

            # If file exists and identical, skip write
            my $current = '';
            if (-e $rd_file) {
                if (open my $rfh, '<', $rd_file) {
                    local $/ = undef;
                    $current = <$rfh>;
                    close $rfh;
                    $current //= '';
                    $current =~ s/^\s+|\s+$//g;
                }
                if ($current eq $url) {
                    return $id_number;  # nothing to update
                }
            }

            # Atomic write: tmp -> rename
            my $rtmp;
            $rtmp = "$rd_file.tmp.$$";
            open my $wfh, '>', $rtmp or die "open($rtmp) failed: $!";
            binmode $wfh;
            print {$wfh} $url, "\n";
            close $wfh or die "close($rtmp) failed: $!";
            chmod 0644, $rtmp;
            rename $rtmp, $rd_file or die "rename($rtmp => $rd_file) failed: $!";
        }
        # else: no valid external link; silently do nothing (no logging requested)
    }

    return qq|$id_number : $page_file|;
}

#-------------------------------------------------------------------------------

	# -------   Output Record ------------------------------------------------------

sub output_record {

  my ($dbh,$query,$table,$id_number,$format,$context) = @_;
  if ($diag>9) { print "Output Record<br>"; }

	my $vars = (); if (ref $query eq "CGI") { $vars = $query->Vars; }

	# Identify record to output																									# Check Request
	$table ||= $vars->{table}; die "Table not specified in output record" unless ($table);			#   - table
	$id_number ||= $vars->{id_number}; my $findable = $id_number;
	unless ($table) { my $err = ucfirst($table)." ID not specified in output record" ; die "$err"; } 	#   - ID number
	unless ($id_number =~ /^[+-]?\d+$/) { $id_number = &find_by_title($dbh,$table,$id_number); } 		#     (Try to find ID number by title)
	$format ||= $vars->{format} || "html";									#   - format

	# JSON
	if ($format =~ /json/i) {
		return &record_to_json($dbh,$table,$id_number);
	}

	# Get Record
	my $record = &db_get_record($dbh,$table,{$table."_id"=>$id_number});					# Get Record
	unless ($record) {
		print "Content-type: text/html\n\n";
		print "Looking for $table '$findable', but it was not found, sorry.";
		exit;
	}		#     - catch get record error
    #	my ($hits,$total) = &record_hit($table,$id_number);							#     - Increment record hits counter

	# Permissions
	return unless (&is_allowed("view",$table,$record));								# Permissions

	# Create Page Title
	$record->{page_title} = $record->{$table."_title"}
		|| $record->{$table."_name"}
		|| $record->{$table."_noun"}
		|| ucfirst($table)." ".$record->{$table."_id"}
		|| "Untitled";		# Page Title
	unless ($table eq "page") { $record->{page_title} = $Site->{st_name} . " ~ " .
		$record->{page_title}; }
	
	if ($format =~ /json/i) { 

		return hash_to_json($record);
	}

	# Create Page Content (from formatted record)
	$record->{page_content} = &format_record($dbh,$query,$table,$format,$record);				# Page Content = Formated Record content

	# Default Page Content (In case the appropriate format isn't found)
	unless ($record->{page_content}) {
		$record->{page_content} = qq|<h1>|.$record->{$table."_title"}.
				$record->{$table."_name"}.
				qq|</h1> |.$record->{$table."_description"}.
				qq|<admin $table,|.$record->{$table."_id"}.qq|>|;
	}

  # Temporary placement for now - Insert award data into badges for individuals, replacing  <award>
  # Format:  site_url/badge/badgeid/authorid  (rewrites to site_url/cgi-bin/page.cgi?badge=badgeid&data=authorid)
  my $replace;
  if ($table eq "badge") {
		if ($vars->{data}) {

			# Find the author
			my $author = &db_get_record($dbh,"author",{author_id=>$vars->{data}}) ||
											&db_get_record($dbh,"author",{author_url=>$vars->{data}}) ||
											&db_get_record($dbh,"author",{author_email=>$vars->{data}}) ||
											&db_get_record($dbh,"author",{author_name=>$vars->{data}}) ||
											&db_get_record($dbh,"author",{author_phone=>$vars->{data}});		# Tries a few things to find the author


			# Find the badge awarded to the author
			if ($author) {
				my $graph_item = &graph_item("badge",$id_number,"author",$author->{author_id});
				if ($graph_item) {
					$replace .= sprintf(qq|<h2>Awarded To:</h2><h1>%s</h1><h3>%s<br/>%s</h3>|,
						$author->{author_name},$author->{author_url},$author->{author_email},$graph_item,$graph_item);
					if ($graph_item->{graph_typeval}) {
						$replace .= sprintf(qq|<p><i>for</i></p><h3><a href="%s">%s</a></h3>|,$graph_item->{graph_typeval},$graph_item->{graph_typeval});
					}
				} else {
					$replace .= sprintf("This badge has <b>not</b> been awarded to %s (%s).",$author->{author_name},$author->{author_id});
				}
			} else {
				$replace .= sprintf("Looked for author number %s but could not find them.",$vars->{data});
			}
		}
		$record->{page_content} =~ s/<award>/$replace/mig;
  }

	# Define geader and footer templates
	$header_template = $record->{page_header} || lc($format) . "_header";					# Add headers and footers
	$footer_template = $record->{page_footer} || lc($format) . "_footer";					#     - pages can override default templates

	if ($table eq "presentation" && $format =~/htm/i) {
		$header_template = "presentation_header";
		$footer_template = "presentation_footer";
	}


	# Add headers and footers
	if ($table =~ /post|author|presentation|feed/ && $format =~ /^htm/) {
	$record->{page_content} =
		&db_get_template($dbh,"static_header",$record->{page_title}) . 
		$record->{page_content} .
		&db_get_template($dbh,"static_footer",$record->{page_title});
	}

	# Format Page Content
	$record->{type} = $table;
	$record->{title} = $record->{$table."_title"} || $record->{$table."_name"} || "Untitled";

	&format_content($dbh,$query,$options,$record);								# Format Page content

	&make_pagedata($query,\$record->{page_content});							# Fill special Admin links and post-cache content

	&make_login_info($dbh,$query,\$record->{page_content},$table,$id_number);

	$record->{page_content} =~ s/\Q]]]\E/] ]]/g;  								# Fixes a Firefox XML CDATA bug

	$output .= $record->{page_content};


	# Print Cache version to file
	#my $page_dir = $Site->{st_urlf}.$table;
	#unless (-d $page_dir) { mkdir($page_dir,0755); }
	#my $page_file = $Site->{st_urlf}.$table."/".$id_number.".".$format;
	#open FILE, ">$page_file" or die $!;
	#print FILE $output or die "Print failure: $!";
	#close FILE;


														# Fill special Admin links and post-cache data

	&make_pagedata($query,\$wp->{page_content},\$wp->{page_title});

	&make_login_info($dbh,$query,\$wp->{page_content},$table,$id_number);
	&autotimezones($query,\$record->{page_content});

	my $mime_type = set_mime_type($format);
	unless ($context eq "api") {	print "Content-type: ".$mime_type."\n\n";			}					# Print header
	if ($diag>9) { print "/Output Record<br>"; }

	return $output;

}


	# -------  Publish Page --------------------------------------------------------
	#
	#          $page_id can be the id of a specific page, 'all' for all pages
	#          or 'auto' to publish autopublied pages (used by cron)
	#          $opt can be set to 'silent' to suppress printing of results 
	#          $export can be used to convert HTML into different formats
	#
	# ------------------------------------------------------------------------------
sub publish_page {

	my ($dbh,$query,$page_id,$opt,$export) = @_;
	my $options = $query->{options};

	$Site->{pubstatus} = "publish";

							# Set up vars for send_newsletter
	my ($pgcontent,$pgtitle,$pgformat,$archive_url); 		

							# Set up formatting for text or html output of results
	my $LF = " "; if ($Site->{cron} ) { $LF = "\n"; } 
	if ($vars->{mode} eq "silent") { $opt = "silent"; }

							# Always rebuild when publishing; don't publish from cache
	$vars->{force} = "yes";				

							# Set Up Request
	my $stmt;my $sth;
	if ($page_id eq "all" || $page_id eq "auto") {
		$stmt = qq|SELECT * FROM page|;
		$sth = $dbh -> prepare($stmt);
 		$sth -> execute(); }
	else {  $stmt = qq|SELECT * FROM page WHERE page_id = ? LIMIT 1|;
		$sth = $dbh -> prepare($stmt);
		$sth -> execute($page_id);
	}

							# Get Page Data, and for Each Page...
	my $count=0;my $wp;
	while ($wp = $sth -> fetchrow_hashref()) {
		$count++;

		$wp->{page_code} =~ s/&#60;/</g;	# Convert data that was encoded back to HTML or keyword, etc
		$wp->{page_code} =~ s/&#62;/>/g;

						# Publish the page only if allowed
		unless (&is_allowed("publish","page",$wp)) {
		#	print "Publishing this page is not allowed";
		#	next;
		};
		$vars->{message} .= "Publishing Page: ".$wp->{page_title}.". ".$LF; 

								# Skip non-auto in autopublish mode
		if ($page_id eq "auto") {
			next unless ($wp->{page_autopub} eq "yes");
		}

		
								# Make Sure We Have Content
		$wp->{page_content} = $wp->{page_code};						
		unless ($wp->{page_content}) {
			$vars->{message} .= qq|Whoa, this page |.$wp->{page_title}.qq| ($page_id) has no content $LF $LF|;
			next;
		}

								# Add Headers and Footers

		my $header = &db_get_template($dbh,$wp->{page_header},$wp->{page_title});
		my $footer = &db_get_template($dbh,$wp->{page_footer},$wp->{page_title});
		$wp->{page_content} = $header . $wp->{page_content} . $footer;

								# Update 'update' value
		$wp->{page_update} = time;
		&db_update($dbh,"page",{page_update=>$wp->{page_update}},$wp->{page_id});


								# Format Page Content

		&format_content($dbh,$query,$options,$wp);

								# Publish only if new content was added, unless empty content allowed
		unless ($wp->{page_linkcount} || $wp->{page_allow_empty} eq "yes") {
			$vars->{message} .= "Zero linkcount in page ".$wp->{page_title}."($page_id), page not published.<p>";
			next;
		}

	
	
								# Save Formatted Content to DB
		#&db_update($dbh,
			#"page",
			#{page_content=>$wp->{page_content},page_latest=>time},
			#$page_id);


								# Make Sure We Have an output location
		unless ($wp->{page_location}) {
			$vars->{message} .= "Whoa, no file to print page ".$wp->{page_title}."($page_id) to $LF $LF"; 
			next;
		}

								# make sure there's a directory to print to
								# by extracting and testing for any subdirectory specified
								# in page location 
		my @dirarray = split /\//,$wp->{page_location};
		my $temp = pop @dirarray;
		my $pgdir = $Site->{st_urlf} . join /\//,@dirarray;
		unless (-d $pdgir) {
			use File::Path qw(make_path);
			make_path($pgdir);
		}



								# Remove CGI Headers

		my $hdr9 = 'Content-type:text/html';
		my $hdr0 = 'Content-type:text/html; charset=utf-8';
		my $hdr1 = 'Content-type: text/html; charset=utf-8';
		$wp->{page_content} =~ s/($hdr0|$hdr1|$hdr9)//sig;


								# Perform conversions
		if ($export) {
			$wp->{page_location} = &convert_page($export,$wp);
		}

								# Print Page

		my $pgfile = $Site->{st_urlf} . $wp->{page_location};
		my $pgurl = $Site->{st_url} . $wp->{page_location};

		# $vars->{message} .= "Publishing to ".$pgfile.$LF;
		&log_cron(1,sprintf("Page published to %s",$pgfile));

		unless (open PSITE, ">$pgfile") { 
			$vars->{message} .= "Cannot open ($page_id) $pgfile : $! $LF $LF"; 
			next; 
		}
		unless (print PSITE $wp->{page_content}) { 
			$vars->{message} .= "Cannot print to ($page_id) $pgfile : $!  $LF $LF"; 
			close PSITE; next; 
		}
		unless ($opt eq "silent" || $opt eq "initialize") {
			$vars->{message} .= qq|Saved page to <a href="$pgurl" target="new">$pgurl</a>  $LF|; }
		close PSITE;






								# Print Archive Version


		if ($wp->{page_archive} eq "yes") {

			my ($save_to,$save_url) = &archive_filename($wp->{page_location});
			unless ($save_to) { 
				$vars->{message} .= "No location to save ".$wp->{page_title}."($page_id) archive file.$LF $LF";
				next;
			}
			unless (open POUT,">$save_to") {
				$vars->{message} .= "Error opening to write ".$wp->{page_title}."($page_id) to $save_to : $! $LF $LF";
				next;
			}

			unless (print POUT $wp->{page_content}) {
				$vars->{message} .= "Error printing ".$wp->{page_title}."($page_id) to $save_to : $! $LF $LF";
				close POUT;
				next;
			}

			unless ($vars->{mode} eq "silent" || $opt eq "silent" || $opt eq "initialize") {
				$vars->{message} .= qq|Archived $wp->{page_title} to <a href="$save_url">$save_url</a> |;
			}
			$archive_url = $save_url;

		}
		if ($wp->{page_content}) { $pgcontent = $wp->{page_content}; }
		if ($wp->{page_title}) { $pgtitle = $wp->{page_title}; }
		if ($wp->{page_format}) { $pgformat = $wp->{page_format}; }

	}


	$sth->finish(  );
print $vars->{message};
	unless ($opt eq "silent" || $opt eq "initialize") { # print $vars->{message};
	 }
	return ($pgcontent,$pgtitle,$pgformat,$archive_url,$wp->{page_linkcount},$wp->{page_location},$wp->{page_type});


}

sub convert_page { 
	my ($export,$wp) = @_;
	return $wp->{page_location} if ($export =~ /htm/);		# Don't convert html to html
	if ($export eq "txt") {
		$wp->{page_content} =~ s/<br>|<br\/>|<br \/>/\n/ig;
		$wp->{page_content} =~ s/<p(.*?)>/\n\n/ig;
		$wp->{page_content} =~ s/<(.*?)>//ig;
		return $wp->{page_location}.".".$export;
	} elsif ($export eq "latex") {
		
		use File::Basename qw(dirname);
		use Cwd  qw(abs_path);
		use lib dirname(dirname abs_path $0) . '/cgi-bin/modules/Latex/lib';
		unless (&new_module_load($query,"Latex",@export)) { 
			&status_error("Error: Publish as Latex required HTML::Latex module, which is not loaded"); }
 		my $parser = new Latex();

		my $filehandle = $parser->set_log('report01.log');
		$parser->set_option({border => 0, debug => 0});
		$wp->{page_content} = $parser->parse_string($wp->{page_content},1);


			return $wp->{page_location}.".".$export;
		}
}



sub publish_error {

  my ($pg,$err) = @_;
  my $LF = "<br>";
  if ($Site->{cron} ) { $LF = "\n"; }

	if ($Site->{context} eq "cron") {
		&log_cron(0,sprintf("Publish Error: Page %s $LF    %s",$pg,$err));
		printf("Publish Error: Page %s $LF    %s",$pg,$err);
	} else {
		&status_error(sprintf("Publish Error: Page %s $LF    %s",$pg,$err));
	}


}
	# -------  Publish badge --------------------------------------------------------
sub publish_badge {

	my ($dbh,$query,$badge_id,$opt) = @_;
	my $options = $query->{options};

	$vars->{force} = "yes";				# Always rebuild when publishing
								# instead of using caches

     	if ($opt eq "verbose") {			# Print header for verbose
		print "Content-type: text/html; charset=utf-8\n\n";
		$Site->{header} =~ s/\Q[*badge_name*]\E/Publish!/g;
		print $Site->{header};
		print "<p>";
	}




							# Set Up Request
	my $stmt;my $sth;
	if ($badge_id eq "all" || $badge_id eq "auto") {
		$stmt = qq|SELECT * FROM badge|;
		$sth = $dbh -> prepare($stmt);
 		$sth -> execute(); }
	else {  $stmt = qq|SELECT * FROM badge WHERE badge_id = ?|;
		$sth = $dbh -> prepare($stmt);
		$sth -> execute($badge_id);
	}

							# Get Badge Data
	my $count=0;my $wp;
	while ($wp = $sth -> fetchrow_hashref()) {
		$count++;


		next unless (&is_allowed("publish","badge",$wp));
		unless ($opt eq "silent" || $opt eq "initialize") { print "Publishing Badge: ",$wp->{badge_name},$LF; }




								# Make Sure We Have Content
		unless ($wp->{badge_name}) {
			unless ($opt eq "silent") { print qq|Whoa, this badge has no name! $LF $LF|; }
			next;
		}

								# Make Sure We Have an Output File
		unless ($wp->{badge_location}) {
			unless ($opt eq "silent") { print qq|Whoa, no file to print this to $LF $LF|; }
			next;
		}


                				# Print Page

		my $pgfile = $Site->{st_urlf} . $wp->{badge_location};
		my $pgurl = $Site->{st_url} . $wp->{badge_location};
		my $json = qq|{"name": "$wp->{badge_name}","description": "$wp->{badge_description}","image": "$wp->{badge_image}", "criteria": "$wp->{badge_criteria}","issuer": "$wp->{badge_issuer}"}|;


		open PSITE, ">$pgfile"  or  print qq|Cannot open $pgfile : $! $LF $LF|;

		print PSITE $json or print qq| Cannot print to $pgfile : $!  $LF $LF|;

		unless ($opt eq "silent" || $opt eq "initialize") { $vars->{message} .= qq|Saved page to <a href="$pgurl"  target="new">$pgfile</a>  $LF|; }

		close PSITE;


	}


	$sth->finish(  );

	if ($opt eq "verbose") {
		print "</p>";
		print $Site->{footer};
	}

   #assign_badge($dbh,$query,$badge_id,1,$opt);
   #bake_badge("http://rel2014.mooc.ca/badge/badgeassert.json",$Site->{st_urlf}."monnouveaubadge.png");

}

	# -------  Assign badge --------------------------------------------------------
sub assign_badge {

	my ($dbh,$query,$badge_id, $person_id,$opt) = @_;
	my $options = $query->{options};

	 $stmt = qq|SELECT * FROM badge WHERE badge_id = ?|;
		$sth = $dbh -> prepare($stmt);
		$sth -> execute($badge_id);

         my $badge = $sth -> fetchrow_hashref();

	 $stmt = qq|SELECT * FROM person WHERE person_id = ?|;
		$sth = $dbh -> prepare($stmt);
		$sth -> execute($person_id);

          my $person = $sth -> fetchrow_hashref();




								# Make Sure We Have Badge Class
		unless ($badge->{badge_location}) {
			unless ($opt eq "silent") { print qq|Whoa, this badge has no class location! $LF $LF|; }
			next;
		}

                     						# Print Page


			my $pgfile = $Site->{st_urlf} . "assert_".$person->{person_id}."_".$badge->{badge_location};
			my $pgurl = $Site->{st_url} . "assert_".$person->{person_id}."_".$badge->{badge_location};

			my $json = qq|{"uid": "$person->{person_id}_$badge->{badge_id}","recipient": {"type":"email", "hashed": false, "identity": "$person->{person_email}"},"image": "$badge->{badge_image}", "evidence": "$badge->{badge_criteria}","issuedOn": "12345","badge":"$Site->{st_url}$badge->{badge_location}", "verify":{"type": "hosted","url": "$pgurl"} }|;


			open PSITE, ">$pgfile"  or  print qq|Cannot open $pgfile : $! $LF $LF|;

			print PSITE $json or print qq| Cannot print to $pgfile : $!  $LF $LF|;

			unless ($opt eq "silent" || $opt eq "initialize") { $vars->{message} .= qq|Saved page to <a href="$pgurl"  target="new">$pgfile</a>  $LF|; }


		close PSITE;





	$sth->finish(  );

	if ($opt eq "verbose") {
		print "</p>";
		print $Site->{footer};
	}


}

	# -------  Get Badge from Mozilla --------------------------------------------------------
sub bake_badge {

  my ($urlbadge,$pgfile) = @_;

  use LWP::Simple;

  $contents = get("http://backpack.openbadges.org/baker?assertion=".$urlbadge);

  open PSITE, ">$pgfile"  or  print qq|Cannot open $pgfile : $! $LF $LF|;

  print PSITE $contents or print qq| Cannot print to $pgfile : $!  $LF $LF|;

  close PSITE;

}

# -------  Publish Post  --------------------------------------------------------
#
#
#	      Edited: 10 July 2013
#
#----------------------------------------------------------------------
sub publish_post {

  my ($dbh,$table,$id,$msg) = @_;


  if ($vars->{post_twitter} eq "yes") { $vars->{twitter} = &twitter_post($dbh,"post",$id); }
  if ($vars->{post_facebook} eq "yes") { $vars->{facebook} = &facebook_post($dbh,"post",$id);	}

  return $vars->{twitter}.$vars->{facebook};
}


	# -------  Archive Filename -----------------------------------------------------------
sub archive_filename {

	# Obtain filename from inout
	my $archivefile = shift @_;

	# Replace any slashes with underscores
	$archivefile =~ s/\//_/g;

	# Get current time and fix digits
	my ($sec,$min,$hour,$mday,$mon,$year,
		$wday,$yday,$isdst) = localtime(time);
	$mday = "0$mday" if ($mday < 10);
	$mon++;
	$mon  = "0$mon"  if ($mon < 10);
	$year  = $year - 2000 if ($year > 1999);  					$year  = $year - 100 if ($year > 99);
	$year  = "0$year"  if ($year < 10);


	# Make these directories if necessary
	my $af = $Site->{st_urlf}."archive/";
	unless (-d $af) { mkdir $af, 0755 or &error($dbh,"","",&printlang("Cannot create directory",$af,"archive_filename",$!)); }
	$af .= $year."/";
	unless (-d $af) { mkdir $af, 0755 or &error($dbh,"","",&printlang("Cannot create directory",$af,"archive_filename",$!)); }

	# Compile filename and url
	$af = $Site->{st_urlf} .
		"archive/$year/$mon" . "_" . $mday . "_" .
		$archivefile;
	my $au = $Site->{st_url} .
		"archive/$year/$mon" . "_" . $mday . "_" .
		$archivefile;	# Compile URL



	# And return them
	return ($af,$au);
}

#
#          Publish Graph
#
#          Prints Site Data Graph
#          List of tables to show is defined in config table, item sh_tables
#          List of fields to show is defined in config table, iten sh_fields
#          After records from each table are listed, the graph is listed
#

sub publish_graph {

	my @wholegraph = &get_graph();
	my $graphed;
	my @outputgraph;
	my @outputdata;
	my $graphcount = 1;
	foreach my $gr (@wholegraph) {
		if ($Site->{sh_tables} =~ $gr->{graph_tableone} && $Site->{sh_tables} =~ $gr->{graph_tabletwo} ) {
			my $source = "qm0".sha256_base64($Site->{st_url}.$gr->{graph_tableone} ."/". $gr->{graph_idone});
			#$gr->{graph_tableone} ."/". $gr->{graph_idone};
			my $target = "qm0".sha256_base64($Site->{st_url}.$gr->{graph_tabletwo} ."/". $gr->{graph_idtwo});
			#$gr->{graph_tabletwo} ."/". $gr->{graph_idtwo};
			my $crgraph = {
				source => $source,
				target => $target,
				type => $gr->{graph_type},
				value => $gr->{graph_tabletwo},
				id => $graphcount
			};
			$graphcount++;
			push @outputgraph,$crgraph;
			$graphed->{$gr->{graph_tableone}}->{$gr->{graph_idone}} = 1;
			$graphed->{$gr->{graph_tabletwo}}->{$gr->{graph_idtwo}} = 1;
			# if ($graphed->{link}->{1}) { print "yes";}
	#	print "$gr->{graph_id}\t$gr->{graph_tableone}\t$gr->{graph_idone}\t$gr->{graph_tabletwo}\t$gr->{graph_idtwo}\t$gr->{graph_type}<br>";
		}
	}
use Data::Dumper;
	foreach my $og (@outputgraph) {
#print $og."\n";
#print Dumper $og;

	}
#print Dumper @outputgraph;

use Digest::SHA qw(sha256_hex sha256_base64);
use Encode;

my $x = 0;
my $y = 0;

	my @tables = split /,/,$Site->{sh_tables};
	foreach my $table (@tables) {
		$x=$x+10; $y=0;
		# Normalize field names for select
		my @fieldlist = split /,/,$Site->{sh_fields}; my @fieldselect;
		foreach my $field (@fieldlist) { push @fieldselect,$table."_".$field; }
		my $fields = join ',',@fieldselect;
#print "SELECT $fields from $table";
		# Retrieve data
		my $sth = $dbh->prepare("SELECT * from $table") or &status_error("Error preparing SQL $!");
   		$sth->execute();
		while (my $hash_ref = $sth->fetchrow_hashref) {
			$y++;
			my $record = {};
			my $id = $hash_ref->{$table."_id"};	
			if ($graphed->{$table}->{$id}) { 
				
				$record->{'@type'} = $table;
				$record->{url} = $Site->{st_url}.$table."/".$id;
				$record->{'id'} = "qm0".sha256_base64($Site->{st_url}.$table."/".$id);

				while (my($hx,$hy) = each %$hash_ref) {
					my ($t,$f) = split /_/,$hx;
next if ($f =~ /description/);					
					if ($Site->{sh_fields} =~ /$f/i) {
						$hy = decode('UTF-8', $hy);			# For UTF characters in JSON
						$record->{$f} = $hy;
					}				
				}

				$record->{x} = $x;		# Positioning for sigma.js
				$record->{y} = $y;
				$record->{size} = 1;
				$record->{label} = $record->{title} || $record->{name};

				$record->{'@type'} = $table;
				$record->{url} = $Site->{st_url}.$table."/".$id;
				$record->{'id'} = "qm0".sha256_base64($Site->{st_url}.$table."/".$id);

				push @outputdata,$record;
			} 
		}
	}

# 		tables => $outputtables,
	my $outputdata = {
		nodes => [@outputdata],
		edges => [@outputgraph]		
	};
use JSON::MaybeXS qw(encode_json decode_json);
my $updated = iso_date(time,"min",$Site->{st_timezone});
my $output_data = {
    name => "$Site->{st_name}",
	creator => "$Site->{st_crea}",
	updated => "$updated",
    email => "$Site->{st_email}",
	website => "$Site->{st_url}",
	base => "$Site->{st_url}",
	data => [@outputdata],
	graph => [@outputgraph],
    address => {
        city => 'Fooville',
        planet => 'Earth',
    },
};

$json = new JSON::XS;
$json = $json->pretty ([$enable]);
$json_text = $json->encode ($outputdata);
print $json_text;

#use utf8;                             # Source encoded using UTF-8.
#use open ':std', ':encoding(UTF-8)';  # Terminal expects UTF-8.
 
# my $output_json = encode_json $outputdata;
# print $output_json;

 #  my $json = encode_json $outputdata;
 #  print $json;
   exit;
	#use Data::Dumper;
	#print Dumper $output;
	#print "Publishing graph";

}


1;