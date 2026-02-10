
	# -------  Format Content -----------------------------------------------------------
	#
	# Should be called page_format()  (and eventually, $page->format() when we're fully OO)
	#
	# Formats the content area of a page or record
	# $wp is a page object
	# $wp->{page_content} is the output content that is being processed here
sub format_content {

	my ($dbh,$query,$options,$wp) = @_;


	if ($diag>9) { print "Format Content <br>"; }
						# Default Content
	unless (defined $wp->{page_content}) { $wp->{page_content} = &printlang("No content"); }
	unless (defined $wp->{page_description}) { $wp->{page_description} = &printlang("No description");; }
	unless (defined $wp->{page_title}) { $wp->{page_title} = &printlang("Untitled");; }
	unless (defined $wp->{page_format}) { $wp->{page_format} = "html"; }
	unless (defined $wp->{page_crdate}) { $wp->{page_crdate} = time; }
	unless (defined $wp->{page_creator}) { $wp->{page_creator} = $Person->{person_id}; }
	unless (defined $wp->{page_update}) { $wp->{page_update} = time; }
	unless (defined $wp->{page_feed}) { $wp->{page_feed} = $Site->{st_feed}; }
	unless (defined $Site->{st_title}) { $Site->{st_title} = &printlang("Site Title");; }
	$wp->{page_linkcount} = 0;

	&make_data_elements(\$wp->{page_content},$wp,$wp->{page_format});		# Fill page content elements

	&make_boxes($dbh,\$wp->{page_content});						# Make Boxes
	&make_counter($dbh,\$wp->{page_content});						# Make Boxes
	my $results_count = &make_keywords($dbh,$query,\$wp->{page_content},$wp);	# Make Keywords
	$wp->{page_linkcount} .= $results_count;

	$wp->{page_content} =~ s/<count>/$vars->{results_count}/mig;			# Update results count from keywords


	# These are for breadcrumbs
	$wp->{page_content} =~ s/\Q[*table*]\E/$wp->{type}/g;					# Insert record table
	&esc_for_javascript(\$wp->{title});  									# JS/JSON escape for title
	$wp->{page_content} =~ s/\Q[*title*]\E/$wp->{title}/g;					# Insert record title	
	my $today = &nice_date(time);
	$wp->{page_content} =~ s/#TODAY#/$today/;
	&autodates(\$wp->{page_content});
	&make_grid(\$wp->{page_content});						# make grid for graphing
	&make_tz($dbh,\$wp->{page_content});								# Time zones


	

        &get_loggedin_image(\$wp->{page_content});

						# Comment Form

	if ($vars->{comment} eq "no") {
		$wp->{page_content} =~ s/<CFORM>(.*?)<END_CFORM>//g;
	} else {

		&make_comment_form($dbh,\$wp->{page_content});
	}

						# Wikipedia

	&wikipedia_entry($dbh,\$wp->{page_content});


	$wp->{page_content} =~ s/\Q[*page_title*]\E/$wp->{page_title}/g;					# Page Title
	$wp->{page_content} =~ s/\Q<page_title>\E/$wp->{page_title}/g;
	&autotimezones($query,\$wp->{page_content});								# Fill timezone dates

						# Template and Site Info
	&make_site_info(\$wp->{page_content});

	&make_site_hits_info(\$wp->{page_content});


  # Insert person ID of person using the pages
	my $pid = $Person->{person_id};
	$wp->{page_content} =~ s/<person_id>/$pid/;


						# Stylistic
						# Customize Internal Links
	my $style = qq||;
	$wp->{page_content} =~ s/<a h/<a $style h/sig;






	&clean_up(\$wp->{page_content},$format);

						# RSSify

	if ($wp->{page_type} =~ /rss|xml|atom/i) {
		&format_rssify(\$wp->{page_content});
	}

						# ICSify
	if ($wp->{page_type} =~ /ics/i) {
		my @lines = split /\n/,$wp->{page_content};	
		my $newlines = "";
		foreach my $l (@lines) {
			$l =~ s/<(.*?)>//g;						# remove html
			next unless ($l =~ /:/);				# skip blank, comments or malformed lines
			my $shortened = substr( $l, 0, 53 );	# Limit each line to 53 characters
			$newlines .= $shortened . "\r\n";     	# ICS requires CRLF
		}	
		$wp->{page_content} = $newlines;
	}

	if ($diag>9) { print "/Format Content <br>"; }

}
sub get_loggedin_image{
  my ($text_ptr) = @_;

    #my $person = &get_person();
  #$mystring =~ s/<get_loggedin_image>/mom/;
}
sub published_on_web {

	# Do not publish if record is not 'published' (ie., if $Site->{pubstatus} has a value,
  # then fill only if the value of $table_social_media !~ /web/
	# Triggered by creating a 'social_media' column in the table (which we test for here)

	my ($dbh,$table,$record_data,@pubcolumns) = @_;

		# Yes, it's published
		if ($record_data->{$table."_web"}) { return 1; }

	  if ($Site->{pubstatus}) {

		# Old style
		# Get the list of columns for the table
		unless (@pubcolumns) { @pubcolumns = &db_columns($dbh,$table); }
		my $smcolumn = $table."_social_media";

			if ( grep( /^$smcolumn$/, @pubcolumns ) ) {

			return 0 unless ($record_data->{$table."_social_media"} =~ /web/i);
		}
	}

	return 1;

}

	# -------  Format Record ----------------------------------------------------
	#
	# Puts a single data record into its template
	# where there are different templates for different formats
	# keyflag is set by make_keywords() and is set to prevent
	# keyword commands from creating full page records with templates
	#
	# Should be called record_format()  (and eventually, $record->format() when we're fully OO)
sub format_record {

	my ($dbh,$query,$table,$record_format,$filldata,$keyflag,@pubcolumns) = @_;
	my $vars = (); if (ref $query eq "CGI") { $vars = $query->Vars; }
	my $id_number = $filldata->{$table."_id"};


	# Check input variables
	
	unless ($table) { $vars->{message} .= "Attempting to format record but no table provided."; return; }
	unless ($id_number) { $vars->{message} .= "Attempting to format $table but no record ID provided.";	return; }

	$diag = 0;
	if ($diag>9) { print "Format Record $table "..",$record_format <br>"; }

	return "Record $table $id_number is unpublished."
		unless (&published_on_web($dbh,$table,$filldata,@pubcolumns));


									# Permissions

	return &printlang("Permission denied to view",$table) unless (&is_viewable("view",$table,$filldata));


									# Get and Return Cached Version

	$vars->{force} = "yes";			# Cache is broken (again), still haven't figured out how to make this work

	unless ($vars->{force} eq "yes") {
		if (my $cached = &db_cache_check($dbh,$table,$id_number,$record_format)) {
			if ($cached) {
				return $cached;
			}
		}
	}

#print "Content-type: text/html\n\n";


											# No cached version, format record



	my $view_text = "";								# Get the code and add header and footer for Page
	if (!$keyflag && $table eq "page" && ($record_format ne "page_list" && $record_format ne "summary")) {
		
			$view_text .= &db_get_template($dbh,$filldata->{responsive_header}) .
			$filldata->{page_code}.
			&db_get_template($dbh,$filldata->{responsive_footer});
	} else {

									# Or Get the Template (aka View)

		my $view_title = $record_format;
		
		if ($table eq "post") { $view_title = $filldata->{post_type}."_".$view_title; }	# Special for post
		unless ($view_title =~ /$table/) { $view_title = $table."_".$view_title; }	# ensure full view format name
		$view_text .= &db_get_text($dbh,"view",$view_title);

		# Bail here unless a view template actually exists
		unless ($view_text) {
			$view_text .= "View $view_title not found.";
			return;
		} 

	}

 



	&make_boxes($dbh,\$view_text);							# Make Boxes - insert box text into element
	&make_counter($dbh,\$view_text);							# Make Counter

	&make_data_elements(\$view_text,$filldata,$record_format);			# Fill page content elements

	my $results_count = &make_keywords($dbh,$query,\$view_text);						# Keywords
	my $kresults_count = &make_keylist($dbh,$query,\$view_text);						# Keylist

	&make_next($dbh,\$view_text,$table,$id_number,$filldata);							# Prev / Next Link

	&make_grid(\$view_text,$table,$id_number,$filldata);						# make grid for graphing

	&autodates(\$view_text);
	
	&autotimezones($query,\$view_text); 		# Fill timezone dates
  
											# Dates
	&make_tz($dbh,\$view_text);								# Time zones

	#&make_langstring(\$view_text);							# Language Strings

	&make_images(\$view_text,$table,$id_number,$filldata);							# Images

	&make_enclosures(\$view_text,$table,$id_number,$filldata);					# Enclosures

	&make_author(\$view_text,$table,$id_number,$filldata);							# Author

	&make_associations(\$view_text,$table,$id_number,$filldata);							# 2nd Order Associations (from graph)

	&make_hits(\$view_text,$table,$id_number,$filldata);								# Hits

	&make_status_buttons(\$view_text,$table,$id_number,$filldata);			# Buttons

	&make_badges(\$view_text,$table,$id_number,$filldata);												# Badges

	&make_conditionals(\$view_text,$table,$id_number,$filldata);		# Resolve conditional statements


	if ($record_format =~ /opml/) { $view_text =~ s/&/&amp;/g; }
	if ($record_format =~ /text|txt/) { &strip_html($text_ptr); }




	&make_escape($dbh,\$view_text);										# Escaped HTML

	&clean_up(\$view_text,$record_format);

  #	&db_cache_save($dbh,$table,$id_number,$record_format,$view_text);					# Save To Cache




	$view_text =~ s/CDATA\((.*?)\)//g;		# Kludge to eliminate hanging CDATA tags

	# Clean up presentations
	if ($table eq "presentation") {

			unless ($filldata->{presentation_slideshare}) {
				$view_text =~ s|<iframe(.*?)slideshare.net/(.*?)/iframe>||g;
			}


			unless ($filldata->{presentation_youtube}) {
				$view_text =~ s|<iframe(.*?)youtube(.*?)/iframe>||g;
			}

			# Remove empty containers
			$view_text =~ s|<div class="video-container">\s*</div>||sig;

			# Remove empty audio
                                    $view_text =~ s|<audio(.*?)src=""(.*?)/audio>||sig;


	}

	# Clean up double commas (caused by missing data)
	$view_text =~ s|div>\s*,|div>|mig;
	$view_text =~ s|,\s*,|,|mig;
	$view_text =~ s|,\s*\.|\.|mig;


#print "<hr>$record_format <br>$view_text <hr>";


	if ($diag>9) { print "/Format Record <br>"; }
	return $view_text;											# Return the Completed Record

}


sub make_formatting {




}

	# -------   Set Formats ------------------------------------------------------
sub esc_for_javascript {

	my ($text_ptr) = @_;
	my $vars = (); if (ref $query eq "CGI") { $vars = $query->Vars; }

	$$text_ptr =~ s/&quot;/\"/mig;
	$$text_ptr =~ s/&#147;/"/mig;
	$$text_ptr =~ s/&#148;/"/mig;
 	$$text_ptr =~ s/\xe2\x80\x9c/\"/gs;
 	$$text_ptr =~ s/\xe2\x80\x9d/\"/gs;
  #	$$text_ptr =~ s/"Education/GORP/gs;
	$$text_ptr =~ s/\n//sig;
	$$text_ptr =~ s/\r//sig;
	$$text_ptr =~ s/\\\s/\\\\ /sig;
	$$text_ptr =~ s/\"/\\\"/sig;
}

	# -------   Set Formats ------------------------------------------------------
	#
	# Determine page format, record format and mime type given
	# page data and var input
	# returns array: page_format,record_format,mime_type
sub set_formats {

	my ($dbh,$query,$wp,$table) = @_;
	my $vars = (); if (ref $query eq "CGI") { $vars = $query->Vars; }




						# Page Format
	my $page_format = "html";				# default page format
	if ($table eq "page") { 				# Assign predefined page format
		if ($wp->{page_format}) { 			# for pages
			$page_format = $wp->{page_format};
		}
	} else {										# Assign requested format
		if ($vars->{format}) {				# for everything else
			$page_format = uc($vars->{format});
		}
	}

						# Record Format
	my $record_format = $table. "_" . lc($page_format);	# default record format
	# Special formats for 'types' of content
	# Eg., for types of post: comment, link, article, gallery, announcement
	if ($table eq "post") {
		if ($vars->{format}) {
			$record_format = "post_".$wp->{post_type}."_".lc($vars->{format});
		} elsif ($wp->{post_type}) {
			$record_format = "post_".$wp->{post_type}."_".lc($page_format);
		} else {
			$record_format = "post_link_".lc($page_format);
		}
	}


	my $mime_type = &set_mime_type($page_format);					# Mime Types


	return ($page_format,$record_format,$mime_type);
}

	# -------  Mime Types ------------------------------------------------------
sub set_mime_type {

	my ($page_format) = @_;
	if ($page_format =~ /RSS|OPML|XML|DC|ATOM/i) {
		$mime_type = "text/xml";
	} elsif ($page_format =~ /TEXT|TXT/i) {
		$mime_type = "text/plain";
	} elsif ($page_format =~ /JSON/i) {
		$mime_type = "application/json;charset=utf-8";
	} elsif ($page_format =~ /JS/i) {
		$mime_type = "text/Javascript";
	} else {
		$mime_type = "text/html";
	}
	return $mime_type;
	#	my $mime_type = "text/html; charset=utf-8";					# default mime
}

	# -------  Clean Up ------------------------------------------------------
sub clean_up {		# Misc. clean-up for print
	my ($text_ptr,$format) = @_;
	$format ||= "";
	$$text_ptr =~ s/BEGDE(.*?)ENDDE//mig;				# Kill unfilled data elements
	$$text_ptr =~ s/\[<a(.*?)href=""(.*?)>(.*?)<\/a>\]//mig;			# Kill blank Nav
	$$text_ptr =~ s/<a(.*?)href=""(.*?)>(.*?)<\/a>/$1 $2 $3/mig;			# Kill blank URLs
	$$text_ptr =~ s/<img(.*?)src=""(.*?)>//mig;			# Kill blank img

	unless ($format eq "edit" || $format =~ /rss|json/i) {
	  $$text_ptr =~ s/&quot;/"/mig;					# Replace quotes
	  $$text_ptr =~ s/&amp;/&/mig;					# Replace amps
	  $$text_ptr =~ s/&lt;|&#60;/</mig;					# Replace amps
	  $$text_ptr =~ s/&gt;|&#62;/>/mig;					# Replace amps
  }

  	$$text_ptr =~ s/&amp;#(.*?);/&#$1;/mig;				# Fix broken special chars
	$$text_ptr =~ s/&#147;/"/mig;
	$$text_ptr =~ s/&#148;/"/mig;
	$$text_ptr =~ s/&#233 /&#233; /g;		# For U de M, which drops a ;
	$$text_ptr =~ s/&amp;#233 /&#233; /g;		# For U de M, which drops a ;



	$$text_ptr =~ s/\x18\x20/'/g;
	$$text_ptr =~ s/\x19\x20/'/g;
	$$text_ptr =~ s/\x1a\x20/'/g;
	$$text_ptr =~ s/\x1c\x20/"/g;
	$$text_ptr =~ s/\x1d\x20/"/g;
	$$text_ptr =~ s/\x1e\x20/"/g;

	$$text_ptr =~ s/&rsquo;|&lsquo;/'/mig;
	$$text_ptr =~ s/&rdquo;|&ldquo;/"/mig;

	$$text_ptr =~ s/&apos;/'/mig;					# '
	$$text_ptr =~ s/&#39;/'/mig;					# '


    if ($format =~ /latex/) {
# \href{http://www.overleaf.com}{Something Linky}
		my $ltext = $$text_ptr;

		my @links = grep(/<a.*href=.*>/,@content);

		foreach my $c (@links){
			$c =~ /<a.*href="([\s\S]+?)".*>/;
			$link = $1;
			$c =~ /<a.*href.*>([\s\S]+?)<\/a>/;
			$title = $1;
			$$text_ptr = s/<a.*href="$link".*>$title<\/a>/\\href{$$link}{$title}/ig;
		}
		$$text_ptr =~ s/&amp;/&/g; 
		$$text_ptr =~ s/&nbsp;/ /g; 		
		$$text_ptr =~ s/<(.*?)>//ig;
		foreach my $q ('#','$','%','^','&','_','{','}','~') { 
		#	$$text_ptr =~ s/$q/\\$q/g; 
		}
		$$text_ptr =~ s/#/\\#/g;
		$$text_ptr =~ s/\$/\\\$/g;
		$$text_ptr =~ s/%/\\%/g;
		$$text_ptr =~ s/\^/\\\^/g;
		$$text_ptr =~ s/&/\\&/g;
		$$text_ptr =~ s/_/\\_/g;
		#$$text_ptr =~ s/\{/\\\{/g;
		#$$text_ptr =~ s/}/\\}/g;
		$$text_ptr =~ s/~/\\~/g;

		# .^$*+?()[{\|

		#$$text_ptr =~ s|//|////|g; 
		$$text_ptr =~ s/\s"/`` /g;
		$$text_ptr =~ s/'/\\textsc{\\char13}s/g;  #'

	}





						# Site Info
	$$text_ptr =~ s/<st_url>/$Site->{st_url}/g;
	$$text_ptr =~ s/<st_cgi>/$Site->{st_cgi}/g;
	$$text_ptr =~ s/<st_host>/$Site->{st_host}/g;

	$$text_ptr =~ s/ & / &amp; /mig;					# Catch hanging ampersands

	$$text_ptr =~ s/,\s+}/}/g;
	$$text_ptr =~ s/&amp;nbsp;/ /g;




	return;
}

	#------------------------  Strip HTML --------------------
sub strip_html {

	# Source
	#########################################################
	# striphtml ("striff tummel")
	# tchrist@perl.com
	#########################################################

	my ($text_ptr) = @_;

	$$text_ptr =~ s/&gt;/>/ig;
	$$text_ptr =~ s/&lt;/</ig;

	$$text_ptr =~ s/(<br>|<br\/>|<br \/>|<p>)/\n/ig;
	$$text_ptr =~ s{ <!(.*?)(--.*?--\s*)+(.*?)>}{if ($1 || $3) {"<!$1 $3>";}}gesx;
	$$text_ptr =~ s{ <(?:[^>'"] *|".*?"|'.*?') +>}{}gsx;
	$$text_ptr =~ s/\n\n\n/\n\n/g;
	$$text_ptr =~ s/\n/<br>/;

}
sub de_cp1252 {
  my( $s ) = @_;

  #   Map incompatible CP-1252 characters
  $s =~ s/\x82/,/g;
  $s =~ s-\x83-<em>f</em>-g;
  $s =~ s/\x84/,,/g;
  $s =~ s/\x85/.../g;

  $s =~ s/\x88/^/g;
  $s =~ s-\x89- \B0/\B0\B0-g;

  $s =~ s/\x8B/</g;
  $s =~ s/\x8C/Oe/g;

  $s =~ s/\x98/'/g;
  $s =~ s/\x99/'/g;
  $s =~ s/\x93/"/g;
  $s =~ s/\x94/"/g;
  $s =~ s/\x95/*/g;
  $s =~ s/\x96/-/g;
  $s =~ s/\x97/--/g;
 	# $s =~ s-\x98-<sup>~</sup>-g;
 	# $s =~ s-\x99-<sup>TM</sup>-g;

  $s =~ s/\x9B/>/g;
  $s =~ s/\x9C/oe/g;

  #   Now check for any remaining untranslated characters.
  if ($s =~ m/[\x00-\x08\x10-\x1F\x80-\x9F]/) {
      for( my $i = 0; $i < length($s); $i++) {
          my $c = substr($s, $i, 1);
          if ($c =~ m/[\x00-\x09\x10-\x1F\x80-\x9F]/) {
              printf(STDERR  "warning--untranslated character 0x%02X in input line %s\n",
                  unpack('C', $c), $s );
          }
      }
  }

  $s;
}

	# -------   RSSify -----------------------------------------------------------
#
#     Make XML parser safe
#
sub format_rssify {		# Misc. clean-up for print

	my ($text_ptr) = @_;

	$$text_ptr =~ s/&(\w+?);/AMPERSAND$1;/g;
	$$text_ptr =~ s/&/&amp;/mig;
	$$text_ptr =~ s/AMPERSAND(\w+?);/&$1;/g;
	$$text_ptr =~ s/AMPERSAND/&/mig;


}


1;