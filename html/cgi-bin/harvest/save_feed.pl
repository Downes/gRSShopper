#    gRSShopper 0.7  Save Feed  -- gRSShopper harvester module
#    March 4, 2018 - Stephen Downes
#    cgi-bin/harvest/save_feed.pl

#    Copyright (C) <2018>  <Stephen Downes, National Research Council Canada>
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.

#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

#   Two major sets of functions:
#     - find various data types, eg. find_feed(), to avoid duplicate saves
#     - functions to save various data types, eg. save_feed()
#   Holy grail would be just one of each for all data types, of course :)

#------------------------  Save Records  --------------------

# Fill out missing data by flowing values down from higher level elements,
# eg. feed->{feed-author} flows into $item->{link_author} if link_author is empty
# We also find author information and flow it up
# Save all recordes in feed harvest


sub save_records {


	&diag(2,qq|<div class="function">Save Records<div class="info">|);

	my ($feedrecord) = @_;

	&diag(2,qq|Feed Record |.$feedrecord->{feed_id}.qq|<p>|);


	my $feed = $feedrecord->{processed};


	unless ($feed->{items}) {
		&diag(0,"Feed has no items<br>\n");
		return;
	}
	my @items = @{$feed->{items}};

	$feed->{feed_creator} = $Person->{person_id};			# Change to Person later
	$feed->{feed_crdate} = time;


	# Fill out feed elements from feed record in DB
	while (my ($fx,$fy) = each %$feedrecord) {
		next if ($fx =~ /_issued|_updated|lastBuildDate|pubDate/);	# Don't preserve previous update dates
		$feed->{$fx} ||= $fy;
	}

	# Flow feed values to feed media
	foreach my $media (@{$feed->{media}}) {
		$media->{media_feedname} = $feed->{feed_title};
		$media->{media_feedurl} = $feed->{feed_html};
		$media->{media_feedid} = $feed->{feed_id};
	}


	foreach my $item (@{$feed->{items}}) {
		&diag(2,qq|<a href="$item->{link_link}" target="_new">Item $item->{link_title}</a>:\n\n|);

		if (my $pl = &is_existing_link($item)) { &diag(2," Already Exists<br>\n"); next; }
		&diag(2," New item <br>\n");



		$item->{link_feedname} = $feed->{feed_title};
		$item->{link_feedurl} = $feed->{feed_html};
		$item->{link_feedid} = $feed->{feed_id};

		# Classification Information
		$item->{link_category} ||= $feed->{feed_category};
		$item->{link_section} ||= $feed->{feed_section};
		$item->{link_genre} ||= $feed->{feed_genre};

		&find_feed_information($item);				# Find feed info that might be in the item record
		&find_author_information($feedrecord,$feed,$item);				# Find authors and save as appropriate

		&find_media_information($feedrecord,$feed,$item,"","save_records");				# Find media and save as appropriate

		&find_link_information($feedrecord,$feed,$item);				# Find link and save as appropriate

		&save_item($feedrecord,$feed,$item);						# Save Item

		# Save Graphs

		if ($item->{type} = "item") {$item->{type}="link";}
	  unless ($analyze eq "on") {
			&diag(5,"Saving graph for item $item->{link_id} <p>\n\n");
			foreach my $aut (@{$item->{authors}}) { &save_graph("by",$item,$aut); }		# Save graphs
			foreach my $med (@{$item->{media}}) { &save_graph("contains",$item,$med); }
			foreach my $lin (@{$item->{links}}) { &save_graph("links",$item,$lin); }
			foreach my $fin (@{$item->{feeds}}) { &save_graph("contains",$fin,$item); }
		}

		unless ($analyze eq "on") { &save_graph("contains",$feed,$item); }

		&rules($feed,$item);						# Rules


	}

	# Feed was updated on....

	$feed->{feed_updated} ||= $feed->{feed_issued};
	$feed->{feed_updated} ||= $feed->{feed_pubDate};
	$feed->{feed_updated} ||= $feed->{feed_lastBuildDate};

  # Save feed
  my $rep = "<b>Feed Data</b>";
  while (my($fx,$fy) = each %$feed) { next if ($fx eq "feedstring"); next unless ($fy); $rep .= "$fx = $fy <br>"; }
	&diag(6,qq|<div class="data">$rep</div>|);

	&save_feed($feedrecord,$feed);
	&diag(2,qq|Save Records complete.|);
	&diag(2,qq|</div></div>|);

}





#----------------------------- Save Author ------------------------------


sub save_author {

	my ($feedrecord,$author,$feed) = @_;
	&diag(2,qq|<div class="function">Save Author<div class="info">|);
	&replace_cdata($feedrecord,$author);						# Replace CDATA

	if ($author->{author_name}) {
		$author->{author_creator} ||= $Person->{person_id};
		$author->{author_crdate} ||= time;
		$author->{author_link} ||= $feed->{feed_html};
		if ($analyze eq "on") { $author->{author_id} = "[Not Inserted]"; }
		else { $author->{author_id} = &db_insert($dbh,$query,"author",$author); }
			&diag(2,qq|&nbsp;&nbsp;&nbsp;Creating new author record for
			<a href="$Site->{st_url}author/$author->{author_id}">$author->{author_name}</a><br/>\n|);
	} else {
			&diag(2,qq|Nameless author not saved.|);
	}

	&diag(2,qq|</div></div>|);
}

#----------------------------- Save Item ------------------------------
#
#  Saves main feed item or entry
#  Can replace 'link' created earlier via scraping with original data
#  created through a feed harvest
#


sub save_item {

	my ($feedrecord,$feed,$item) = @_;
	&diag(2,qq|<div class="function">Save Item<div class="info">|);
	&replace_cdata($feedrecord,$item);						# Replace CDATA
	$item->{link_creator} ||= $Person->{person_id};
	$item->{link_crdate} ||= time;
	$item->{link_orig} = "yes";
	$item->{link_content} ||= $item->{link_description} || $item->{link_summary};
	$item->{link_status} = "Fresh"; 		# freshly minted content :)
	$item->{link_title} =~ s{ \b(\w+) }{\u\L$1}gx;		# Standardize titles

	return 0 if &save_item_discard($item);				# Toss unwanted items

	unless ($item->{link_link} =~ /http(s|):/) {			# Catch relative links eg. Global maritivmes
		$item->{link_link} = $feed->{feed_html} . $item->{link_link};
		$item->{link_link} =~ s/\/\//\//g;			# Fix // in RL
	}

									# Clean messy messy Google links
	if ($item->{link_link} =~ /google/) {
		if ($item->{link_link} =~ /(.*?)url=(.*?)$/) {

			my $url = $2;					# Replace Google news redirect with URL
			$item->{link_link} = $url;

		}
		#http://news.google.com/news/url?sa=t&fd=R&ct2=us&usg=AFQjCNEznSLOIQmGVT3BtTxSV_Isac6s6Q&clid=c3a7d30bb8a4878e06b80cf16b898331&cid=43982378835558&ei=oQ9QU4i-IqaV8QHn6AE&url=http://www.washingtonpost.com/blogs/style-blog/wp/2014/


	}



	if ($item->{link_id}) {
		my $ti = &db_get_record($dbh,"link",{link_id=>$item->{link_id}});
		unless ($ti->{link_orig} eq "yes") {

			if ($item->{link_link}) {
				unless ($analyze eq "on") { &db_update($dbh,"link",$item,$item->{link_id}); }
				&diag(1,qq|Converting existing item
					<a href="$Site->{st_url}link/$item->{link_id}">$item->{link_title}</a><br/>\n|);
			}
		}
	} else {
		if ($item->{link_link}) {
			if ($analyze eq "on") {  $item->{link_id} = "[Not Inserted]"; }
			else { $item->{link_id} = &db_insert($dbh,$query,"link",$item); }
			if ($item->{link_id}) {
				my $newurl = $Site->{st_url}."link/".$item->{link_id};
				&diag(1,qq|Save Item <a href="$newurl">$item->{link_title}</a><br/>\n|);
				&log_cron(1,sprintf("New link inserted: %s : %s",$newurl,$item->{link_title}));
			} 
		}



	}
	&diag(2,qq|</div></div>|);
}

sub save_item_discard {

	my ($item) = @_;

	if ($item->{link_link} =~ m|http://news.google.com/news/more|) { return 1; }

	return 0;

}
#----------------------------- Save Feed ------------------------------

sub save_feed {

	my ($feedrecord,$feed) = @_;
	&diag(2,qq|<div class="function">Save Feed<div class="info">|);
	&replace_cdata($feedrecord,$feed);						# Replace CDATA

							# Roll up author information
	foreach my $author (@{$feed->{authors}}) {
		unless ($author->{author_id}) {	&find_author_record($feedrecord,$feed,$author); }
		&append_to_list($feed->{feed_author},$author->{author_id});
		&append_to_list($feed->{feed_authorname},$author->{author_name});
		&append_to_list($feed->{feed_authorlink},$author->{author_link});
	}


	# Special for Plusfeed
	if ($feed->{feed_link} =~ /plusfeeds/) { $feed->{feed_link} =~ s/plusfeeds/plusfeed/i; }

	if ($feed->{feed_id}) {
		my $fl = $feed->{feed_link};
		delete($feed->{feed_link});  # Don't change feed link

		unless ($analyze eq "on") { &db_update($dbh,"feed",$feed,$feed->{feed_id}); }
		$feed->{feed_link} = $fl;
		&diag(2,"Updating feed $feed->{feed_id} - $feed->{feed_title} <br>\n");
	} else {
		$feed->{feed_crdate} = time;
		$feed->{feed_creator} = $Person->{person_id};
		$feed->{feed_title} ||= $feed->{feed_link};
		if ($analyze eq "on") {  $feed->{feed_id} = "[Not Inserted]"; }
		else { $feed->{feed_id} = &db_insert($dbh,$query,"feed",$feed); }
		&diag(2,"Created new feed $feed->{feed_id} - $feed->{feed_title} <br>\n");
	}


								# Verify and save feed media
	foreach my $media (@{$feed->{media}}) {
		&find_media_information($feedrecord,$feed,"",$media,"save_feed");
	}

	unless ($analyze eq "on") {
	  foreach my $author (@{$feed->{authors}}) {		# Author graph
      &save_graph("by",$feed,$author);
	  }
  }
	&diag(2,qq|Done.|);
	&diag(2,qq|</div></div>|);
}

#----------------------------- Save Feeditem ------------------------------
#
# Save feed that was included in an item record, eg. from a journal search

sub save_feeditem {

	my ($feeditem) = @_;
	&diag(2,qq|<div class="function">Save Feeditem<div class="info">|);
	my $feed;

	$feeditem->{feed_crdate} = time;
	$feeditem->{feed_creator} = $Person->{person_id};
	$feeditem->{feed_title} ||= $feeditem->{feed_link};
	if ($analyze eq "on") { $feeditem->{feed_id} = "[Not Inserted]"; }
	else { $feeditem->{feed_id} = &db_insert($dbh,$query,"feed",$feeditem); }
	&diag(1,"Created new feed $feed->{feed_id} - $feeditem->{feed_title} <br>\n");

	&diag(2,qq|</div></div>|);
	return $feeditem->{feed_id};

}



#----------------------------- Save Link ------------------------------
#
#  Saves links contained inside items or entries, usually found by scraper
#

sub save_link {


	my ($feedrecord,$link) = @_;
	&diag(2,qq|<div class="function">Save Link<div class="info">|);
	&replace_cdata($feedrecord,$link);						# Replace CDATA
	if ($link->{link_link}) {
		$link->{link_creator} ||= $Person->{person_id};
		$link->{link_status} |= "Link";
		$link->{link_crdate} ||= time;
		if ($analyze eq "on") { $link->{link_id} = "[Not Inserted]"; }
		else { $link->{link_id} = &db_insert($dbh,$query,"link",$link); }
		&diag(3,qq|---- Save link
			<a href="$Site->{st_url}link/$link->{link_id}">$link->{link_title}</a><br/>\n|);
	}
	&diag(2,qq|</div></div>|);
}



#----------------------------- Save Media ------------------------------

sub save_media {

	my ($feedrecord,$media,$from) = @_;
	&diag(1,qq|<div class="function">Save Media<div class="info">|);

	&replace_cdata($feedrecord,$media);						# Replace CDATA
	if($media->{media_url}) {

    # Set mime type from URL and setup links
    $media->{media_mimetype} = &mime_type($media->{media_url});
		$media->{media_htmllink} = $media->{media_link};
		$media->{media_url} =~ s/ /%20/g;

  	# Save audio files
  	if ( $media->{media_mimetype} =~ "audio" && $Site->{st_audio_dl} eq "yes") {

      &diag(2,qq|Downloading audio files<br>|);
  		my $default_audio_dir = "files/podaudio/";					# Establish audio download directory
  		my $audio_dir = $Site->{audio_download_dir} || $default_audio_dir;
  		unless ($audio_dir =~ /\/$/) { $audio_dir .= "/"; }

  		my @filearr = split "/",$media->{media_url};					# Establish name of download file
  		my $filename = pop @filearr;
  		my $flink = $Site->{st_url}.$Site->{audio_download_dir} . $filename;
      $filename = $Site->{st_urlf}.$audio_dir. $filename;

  		use LWP::Simple; my $lwperr;
  		getstore($media->{media_url}, $filename) or $lwperr = "Error downloading file. $!";
      if ($lwperr) { &diag(2,qq|<div class="warning">$lwperr</div><br>|);}
      else { &diag(1,qq|Saving URL: $media->{media_url} <br>To File: <a href="$flink" target="_new">$filename</a><br><br>|); }

  	}
  }




  my $rep = "<b>Media Record</b>";
  while (my($mx,$my) = each %$media) { $rep .=  "$mx = $my<br>"; } # "
  &diag(9,qq|<div class="data">$rep</div>|);

  &diag(2,qq|Saving |.$media->{media_mimetype}.qq| media record<br>
      URL: <a href="$media->{media_url}">$media->{media_url}</a> from $from<br>|);

  # Save the Media Record
  $media->{media_creator} = $Person->{person_id};
  $media->{media_crdate} = time;
  if ($analyze eq "on") { $media->{media_id} = "[Not Inserted - In Analyze Mode]"; }
  else { $media->{media_id} = &db_insert($dbh,$query,"media",$media); }
  &diag(1,qq|New Media Record: $media->{media_title} ($media->{media_id}) <br>|);

  &diag(2,qq|<br>Done saving media <br><br>|);
	&diag(1,qq|</div></div>|);


}


#
#                      FIND
#



#----------------------------- Find Feed --------------------------------

# This is for cases where the feed info is contained inside the item information
# as for example in a search from a journal indexing service

sub find_feed_information {

	my ($item) = @_;
	&diag(4,qq|<div class="function">Find Feed Information<div class="info">|);



	foreach my $feeditem (@{$item->{feeds}}) {			# Find feed information from database
									# Should just be one

		$feeditem->{feed_id} = &db_locate($dbh,"feed",{feed_title=>$feeditem->{feed_title}});
		unless ($feeditem->{feed_id}) {
			$feeditem->{feed_id} = &save_feeditem($feeditem);
		};
		if ($feeditem->{feed_id}) {					# And flow it back up
			$item->{link_feed} = $feeditem->{feed_id};
			$item->{link_feedtitle},$feeditem->{feed_title};
			$item->{link_feedlink},$feeditem->{feed_link};
		}
	}

  	&diag(4,qq|</div></div>|);
}





#----------------------------- Find Author ------------------------------

sub find_author_information {

	my ($feedrecord,$feed,$item) = @_;
	&diag(4,qq|<div class="function">Find Author Information<div class="info">|);

	# Find author information
	if (not (@{$item->{authors}}) || @{$item->{authors}} == 0) {						# If no author inormation in item
		if (@{$feed->{authors}} > 0) {					# then use feed author information
			foreach my $aut (@{$feed->{authors}}) { push @{$item->{authors}}, $aut; }
		} else {							# or use values from the feed record
			my $aut = {author_name=>$feed->{feed_authorname},author_email=>$feed->{feed_authoremail},
				author_id=>$feed->{feed_author},author_link=>$feed->{feed_authorlink}};
			if ($aut) { push @{$item->{authors}}, $aut; }
		}

	}

										# Find author information from database
	foreach my $author (@{$item->{authors}}) {

    # Replace CDATA
    &replace_cdata($feedrecord,$author);

    # Search for Author
		&find_author_record($feedrecord,$feed,$author);
		if ($author->{author_id}) {					# And flow it back up
			&append_to_list($item->{link_author},$author->{author_id});
			&append_to_list($item->{link_authorname},$author->{author_name});
			&append_to_list($item->{link_authorlink},$author->{author_link});
		}
	}
	&diag(4,qq|</div></div>|);
}

sub find_author_record {

	my ($feedrecord,$feed,$author) = @_;
	&diag(4,qq|<div class="function">Find Author Record<div class="info">|);


	return unless (&is_author($author));
	&diag(4,"---- Author: $author->{author_name}... \n");

	my $author_record = find_buffered_author($feed,$author);
	if ($author_record) { 		# nice if it's already there
		while (my($ax,$ay) = each %$author_record) { $author->{$ax} ||= $ay; }
		&diag(4," in buffer...<br/>\n ");
		return;
	}

								# Life is easier if we have an author ID
	if (!$author_record && $author->{author_id}) {
		&diag(4," using author id...<br/>\n ");
		$author_record = &db_get_record($dbh,"author",{author_id => $author->{author_id}});
	}

								# If there's an author URL, it's easy
								# Unless it's a blog that uses multiple authors

	if (!$author_record && $author->{author_link}) {
		&diag(4," using author link...<br/>\n ");
		$author_record = &db_get_record($dbh,"author",{author_link => $author->{author_link}});
	}

							# Bail here if it's a Twitter author
							# (& any multi-author feed)

	if ($feed->{feed_link} =~ /twitter/) {
		&diag(4," It's Twitter, I give up<br/>\n ");
		&diag(4,qq|</div></div>|);
		return;
	}


								# Next, try by author email address

	if (!$author_record && $author->{author_email}) {
		&diag(4," using author email...<br/>\n ");
		unless ($author->{author_email} =~ /noreply/) {		# Skip place-holder emails
			$author_record = &db_get_record($dbh,"author",{author_email => $author->{author_email}});
		}
	}



	if (!$author_record && $author->{author_name}) {	# Next, search by Name
		&diag(4," searching by name...<br/>\n ");
		if ($author->{author_name} =~ /@/) {			# Name is an email address?
			$author_record = &db_get_record($dbh,"author",{author_email => $author->{author_name}});
		}
		if (!$author_record) {
			$author_record = &db_get_record($dbh,"author",{author_name => $author->{author_name}});
		}
	}

								# Try using the author's nickname as a desperate last measure
	if (!$author_record) {
		&diag(4,"searching by nickname...<br/>\n ");
		$author_record = &db_get_record($dbh,"author",{author_nickname => $author->{author_name}});
	}


	if ($author_record) {
		push @{$feed->{author_buffer}},$author_record;	# save to skip future db lookups
		while (my($ax,$ay) = each %$author_record) { $author->{$ax} ||= $ay; }
		&diag(4,"Found author $author->{author_id}<br/> \n");

	} else {
		&diag(4,"Couldn't find this author.<br/>\n ");
		&save_author($feedrecord,$author,$feed);				# Save Author
		push @{$feed->{author_buffer}},$author;

	}

	&diag(4,qq|</div></div>|);
}

sub find_buffered_author {

	my ($feed,$author) = @_;
	&diag(5,qq|<div class="function">Find Buffered Author<div class="info">|);
	foreach my $buffered (@{$feed->{author_buffer}}) {

	if (
			($author->{author_name} && ($buffered->{author_name} eq $author->{author_name})) ||
			($author->{author_email} && ($buffered->{author_email} eq $author->{author_email})) ||
			($author->{author_link} && ($buffered->{author_link} eq $author->{author_link}))
			) {
				&diag(5,qq|</div></div>|);
				return $buffered
			};
	}
	&diag(5,qq|</div></div>|);
	return 0;

}

#------------------------  Find Link --------------------

sub find_link {

	my ($feed,$item) = @_;
	&diag(5,qq|<div class="function">Find Link<div class="info">|);
	if ($item->{item_id}) {
	  &diag(5,qq|</div></div>|);
		return;
	};								# Find by url

	$item->{item_id} = &db_get_record($dbh,"link",{link_link => $item->{link_link}});
	&diag(5,qq|</div></div>|);

}



#------------------------  Find Link Information --------------------
#
# Checks for previously saved links, and saves new ones (generally from scrapers)

sub find_link_information {

	my ($feedrecord,$feed,$item) = @_;
	&diag(5,qq|<div class="function">Find Link Information<div class="info">|);

	foreach my $link (@{$item->{links}}) {				# Check for existing links

    # Find Link ID if it exists
    # Two serach URLs used because Wordpress is inconsistent with https
    my $search_url = $link->{link_link}; my $second_search_url = $search_url;
    if ($search_url =~ /https:/) { $second_search_url =~ s/https:/http:/i; }
    else  { $second_search_url =~ s/http:/https:/i; }
    $link->{link_id} = &db_locate($dbh,"link",{link_link=>$search_url});
    unless ($link->{link_id}) { $link->{link_id} = &db_locate($dbh,"link",{link_link=>$second_search_url});}

		next if ($link->{link_id});				# Skip existing links
		&save_link($feedrecord,$link);					# Save new link
	}
	&diag(5,qq|</div></div>|);
}

#------------------------  Find Media --------------------

sub find_media_information {

	my ($feedrecord,$feed,$item,$media,$from) = @_;

	&diag(5,qq|<div class="function">Find Media Information<div class="info">|);

  # Set values for the media
  if ($media) {
      &__medi_info($feedrecord,$media,$from);

  } elsif ($item) {

    # Or flow item values to item media
  	foreach my $imedia (@{$item->{media}}) {
      &__medi_info($feedrecord,$imedia,$from);
  	}

  } elsif ($feed) {

    # Of flow item values to feed media
  	foreach my $fmedia (@{$feed->{media}}) {
      &__medi_info($feedrecord,$fmedia,$from);
  	}

  } else {
    &error($dbh,"","","Neither Media nor Item info sent to &fine_media_information()");
  }
	&diag(5,qq|</div></div>|);
}


sub __medi_info {
  my ($feedrecord,$imedia,$from) = @_;
  &diag(5,qq|<a href="$imedia->{media_link}">$imedia->{media_title}</a>: |);

  # Give the media a title
  unless ($imedia->{media_title}) {
    my @media_name_array = split '/',$imedia->{media_url};
    $imedia->{media_title} = pop @media_name_array;
  }

  my $rep = "<b>Media</b>";
  while (my ($mx,$my) = each %$imedia) { $rep .= "$mx = $my <br>"}
  &diag(5,qq|<div class="data">$rep</div>|);

  # Find Media ID if it exists
  # Two serach URLs used because Wordpress is inconsistent with https
  my $search_url = $imedia->{media_url}; my $second_search_url = $search_url;
  if ($search_url =~ /https:/) { $second_search_url =~ s/https:/http:/i; }
  else  { $second_search_url =~ s/http:/https:/i; }
  $imedia->{media_id} = &db_locate($dbh,"media",{media_url=>$search_url});
  unless ($imedia->{media_id}) { $imedia->{media_id} = &db_locate($dbh,"media",{media_url=>$second_search_url});}

  # Skip existing media
  if ($imedia->{media_id}) {
    &diag(5,qq|already exists <br>\n|);
    return;
  }

  # Save New Media
  &diag(5,qq|new<br>\n|);

  &save_media($feedrecord,$imedia,$from);					# Save new media

}





1;
