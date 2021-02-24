#    gRSShopper 0.7  Scraper  -- gRSShopper harvester module
#    March 4, 2018 - Stephen Downes
#    cgi-bin/harvest/scraper.pl

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

#------------------------  Scrape Items --------------------

sub scrape_items {

	my ($feedrecord) = @_;
	&diag(5,qq|<div class="function">Scrape Items<div class="info">|);
	my $feed = $feedrecord->{processed};
	unless ($feed->{items}) {
		&diag(0,"Feed has no items<br>\n");
		return;
	}
	my @items = @{$feed->{items}};
	&diag(6,"<hr> SCRAPE ITEMS <hr>\n\n");


	# Feed Items

	while (my ($fx,$fy) = each %$feed) {
		if ($fx eq "items") {

			foreach my $item (@$fy) {
				&diag(6,"<hr>Scraping Item: $item->{link_title}: <br>\n");
				my $scrapetext = &scrape_prepare($feedrecord,$feed,$item);
				&scrape_links($feed,$item,$scrapetext);
				&scrape_images($feed,$item,$scrapetext);
				&scrape_iframes($feed,$item,$scrapetext);
				&scrape_embeds($feed,$item,$scrapetext);
				#&diag("<form><textarea cols=80 rows=10>$scrapedata</textarea></form>") ;
				#&diag($scrapedata);

				&merge_media($feed,$item);

			}
		}
	}
	&diag(5,qq|</div></div>|);
}


#------------------------  Scrape Prepare --------------------

sub scrape_prepare {

	my ($feedrecord,$feed,$item) = @_;
	&diag(6,qq|<div class="function">Scrape Prepare<div class="info">|);
	my $type = $item->{type};
	&diag(6,"Scrape Prepapre: $type<br>\n");

  &replace_cdata($feedrecord,$item);
#	my $description = &replace_cdata($item->{$type."_description"});
#	my $content = &replace_cdata($item->{$type."_content"});
#	my $summary = &replace_cdata($item->{$type."_summary"});

	my $scrapedata = $item->{$type."_description"};
	if ($item->{$type."_description"} ne $item->{$type."_content"}) { $scrapedata .= $item->{$type."_content"}; }
	if ($item->{$type."_description"} ne $item->{$type."_summary"}) { $scrapedata .= $item->{$type."_summary"}; }

	$scrapedata = decode_entities($scrapedata);   	# uses HTML::Entities
	&diag(6,qq|</div></div>|);
	return $scrapedata;
}



#-------------------------- Scrape Links --------------------------------

sub scrape_links {

	my ($feed,$item,$scrapetext) = @_;
	&diag(5,qq|<div class="function">Scrape Links<div class="info">|);

	&diag(5,"Scraping Links for $item->{link_title}<br>\n");

	while($scrapetext =~ m/<a(.*?)>(.*?)</ig) {

		my $attributes = $1;
		my $att = &process_attributes($attributes);
		my $title = $2;

		next unless &is_url($feed,$att->{href});			# URL

		unless ($title) { $title = &is_title($att); }			# title

		my $mimetype = &mime_type($att->{href});			# mimetype
		if (!$mimetype || $mimetype eq "unknown") { $mimetype = "text/html"; }

		my $type = &is_type($att->{href},$mimetype);			# type



		if ($type =~ /link|archive|document/) {
									# save as link
			my $link = gRSShopper::Record->new(tag=>'scraped',type=>'link',
				link_link=>$att->{href},link_title=>$title);
			push @{$item->{links}},$link;

			&diag(5,qq|-- Found link: <a href="$att->{href}">$link->{link_title}</a> ) <br>\n|);

		} else {						# save as media

      # Give the media a title
        my @media_name_array = split '/',$att->{href};
        my $media_title = pop @media_name_array;
        $media_title ||= $title;

			my $media = gRSShopper::Record->new(tag=>'scraped',type=>'media',
				media_url=>$att->{href},media_title=>$media_title,media_mimetype=>$mimetype,
				media_height=>$att->{height},media_width=>$att->{width});
			push @{$item->{media}},$media;
			&diag(5,"New media record in scrape_links for $att->{href}<br>");

			&diag(5,qq|-- Found media: <a href="$att->{href}">$media->{media_title}</a> ) <br>\n|);

		}
	}
	&diag(5,qq|</div></div>|);
}

#-------------------------- Scrape Images --------------------------------

sub scrape_images {

	my ($feed,$item,$scrapetext) = @_;
	&diag(5,qq|<div class="function">Scrape Images<div class="info">|);
	&diag(5,qq|Scraping Images for |.$item->{link_title}.qq|<br>|);


	my $type;

	while ($scrapetext =~ m/<img(.*?)>/ig) {

		my $attributes = $1;
		my $att = &process_attributes($attributes);


		next unless &is_url($feed,$att->{src});			# URL
		$att->{src} =~ s/\?(.*?)$//i;				# Strip parameters from image URLs

		my $title = &is_title($att);				# Title

		my $description = $att->{alt}; 				# description
		unless ($description) { $description = $title; }

		my $mimetype = &mime_type($att->{src});			# mimetype
		if (!$mimetype || $mimetype eq "unknown") { $mimetype = "image"; }


									# save as media
		my $media = gRSShopper::Record->new(tag=>'scraped',type=>'media',media_type=>"image",
			media_url=>$att->{src},media_title=>$title,media_description=>$description,
			media_mimetype=>$mimetype,media_height=>$att->{height},media_width=>$att->{width});
		&diag(5,"New media record in scrape_images for $att->{src}<br>");

		push @{$item->{media}},$media;

		&diag(5,qq|-- Found image: <a href="$att->{src}">$media->{media_title}</a> ) <br>\n|);

	}
	&diag(5,qq|</div></div>|);
}




#-------------------------- Scrape Embeds --------------------------------

sub scrape_embeds {


	my ($feed,$item,$scrapetext) = @_;
	&diag(5,qq|<div class="function">Scrape Embeds<div class="info">|);
	&diag(5,qq|Scraping embeds for |.$item->{link_title}.qq|<br>\n|);

	while($scrapetext =~ m/<embed(.*?)>/ig) {

		my $attributes = $1;
		my $att = &process_attributes($attributes);

		next unless &is_url($feed,$att->{src});			# URL

		my $title = &is_title($att);				# Title

		my $description = $att->{alt}; 				# description
		unless ($description) { $description = $title; }

		my $mimetype = $att->{type};				# mimetype
		$mimetype ||= &mime_type($att->{src});
		if (!$mimetype || $mimetype eq "unknown") { $mimetype = "embed"; }

		my $type = &is_type($att->{src},$mimetype);		# type


		if ($type =~ /link|archive|document/) {
									# save as link
			my $link = gRSShopper::Record->new(tag=>'scraped',type=>'link',
				link_link=>$att->{src},link_title=>$title,link_description=>$description);
			push @{$item->{links}},$link;

	    &diag(5,qq|Found link: <a href="$att->{src}">$link->{link_title}</a> ) <br>\n|);


		} else {						# save as media

			my $media = gRSShopper::Record->new(tag=>'scraped',type=>'media',
				media_url=>$att->{src},media_title=>$title,media_mimetype=>$mimetype,
				media_height=>$att->{height},media_width=>$att->{width});
			push @{$item->{media}},$media;
			&diag(5,qq|New media record in scrape_embeds for $att->{src}<br>|);
			&diag(5,qq|Found media: <a href="$att->{src}">|.$media->{media_title}.qq|</a> ) <br>\n|);

		}


	}
	&diag(5,qq|</div></div>|);
}



#-------------------------- Scrape Iframes --------------------------------

sub scrape_iframes {

	my ($feed,$item,$scrapetext) = @_;
	&diag(5,qq|<div class="function">Scrape iFrames<div class="info">|);
	&diag(5,qq|Scraping iframes for |.$item->{link_title}.qq|<br>\n|);

	while($scrapetext =~ m/<iframe(.*?)>/ig) {


		my $attributes = $1;
		my $att = &process_attributes($attributes);

		next unless &is_url($feed,$att->{src});			# URL

		my $title = &is_title($att);				# Title

		my $mimetype = &mime_type($att->{src});			# mimetype

		my $type = &is_type($att->{src},$mimetype);		# type

		if ($type =~ /link|archive|document/) {

			my $link = gRSShopper::Record->new({tag=>'scraped',type=>'link',
				link_link=>$att->{src},link_title=>$title});
			push @{$item->{links}},$link;

			print qq|-- Found link: <a href="$att->{src}">$link->{link_title}</a> ) <br>\n| if $DEBUG > 1;

		} else {						# save as media


			my $media = gRSShopper::Record->new(tag=>'scraped',type=>'media',
				media_url=>$att->{src},media_title=>$title,media_mimetype=>$mimetype,
				media_height=>$att->{height},media_width=>$att->{width});
			push @{$item->{media}},$media;
	    &diag(5,qq|New media record in scrape_iframes for $att->{src}<br>|);
			&diag(5,qq|Found media: <a href="$att->{src}">$media->{media_title}</a> ) <br>\n|);
		}
	}

	&diag(5,qq|</div></div>|);
}





#------------------------  Is Audio --------------------

# Return 1 if URL is on the 'rejected' list

sub is_audio { 		# Would like to make this a loadable list at some point

	my ($url) = @_;
	&diag(6,qq|<div class="function">Is Audio?<div class="info">|);

	my @audio = ('soundcloud.com','www.freesound.org');
	foreach my $a (@audio) { if ($url =~ /$a/i) { 	&diag(6,qq|</div></div>|);return 1; } }
	&diag(6,qq|</div></div>|);
	return 0;
}



#----------------------------- Is Author ------------------------------

sub is_author {

	# Weed out authors with no names, authors named 'admin', etc

	my ($author) = @_;
	&diag(6,qq|<div class="function">Is Author?<div class="info">|);
	unless ($author->{author_name} || $author->{author_email} || $author->{author_link} || $author->{author_id}) {
		&diag(9,"<p>Author from $author->{source} rejected; it has no name, email, url or id</p>\n\n"); 	&diag(6,qq|</div></div>|);return 0; }
	if ($author->{author_name} =~ /^admin$/i) {
		&diag(9,"<p>Author from $author->{source} rejected; 'admin' is not an author name</p>\n\n"); 	&diag(6,qq|</div></div>|);return 0; }
	if ($author->{author_name} =~ /^guest$/i) {
		&diag(9,"<p>Author from $author->{source} rejected; 'guest' is not an author name</p>\n\n"); 	&diag(6,qq|</div></div>|);return 0; }
	&diag(6,qq|</div></div>|);
	return 1;

}

#------------------------  Is Existing Link --------------------
#
# Makes sure not only whether or not the link exists, but also whether it's one harvested
# here (link_orig = "yes") or just something linked incidentally and recorded here
#

sub is_existing_link {

	my ($item) = @_;
	&diag(6,qq|<div class="function">Is Existing Link?<div class="info">|);
	$item->{link_link} =~ s/\#(.*?)$//;				# Remove gunk
	$item->{link_link} =~ s/utm=(.*?)$//;
	&diag(6,qq|Searching for: $item->{link_link} |);
									# Search by link

  # Find Link ID if it exists
  # Two serach URLs used because Wordpress is inconsistent with https
  my $search_url = $item->{link_link}; my $second_search_url = $search_url;
  if ($search_url =~ /https:/) { $second_search_url =~ s/https:/http:/i; }
  else  { $second_search_url =~ s/http:/https:/i; }
  $item->{link_id} = &db_locate($dbh,"link",{link_link=>$search_url});
  unless ($item->{link_id}) { $item->{link_id} = &db_locate($dbh,"link",{link_link=>$second_search_url});}

	if ($item->{link_id}) {
		my $tl = &db_get_record($dbh,"link",{link_id=>$item->{link_id}});
		if ($tl->{link_orig} eq "yes") {
			&diag(6,qq|Found.<br>|);
			&diag(6,qq|</div></div>|);
			return  1;
		}
	}


									# Search by title
	&diag(6,qq|Not found.<br>Searching for: $item->{link_title} -- |);
	$item->{link_id} = &db_locate($dbh,"link",{link_title=>$item->{link_title}});
	if ($item->{link_id}) {
		my $tl = &db_get_record($dbh,"link",{link_id=>$item->{link_id}});
		if ($tl->{link_orig} eq "yes") { return  2; }
	}
	&diag(6,qq|Not found.<br>|);
	&diag(6,qq|</div></div>|);
	return 0;
}

#------------------------  Is Slideshow --------------------

# Return 1 if URL is on the 'slideshow' list

sub is_slides { 		# Would like to make this a loadable list at some point

	my ($url) = @_;
	&diag(6,qq|<div class="function">Is Slides?<div class="info">|);

	my @slide = ('slideshare.net','slideshare.com');
	foreach my $a (@slide) { if ($url =~ /$a/i) { 	&diag(6,qq|</div></div>|);return 1; } }
	&diag(6,qq|</div></div>|);
	return 0;
}

#------------------------  Is Title --------------------

# Return title based on attributes

sub is_title {

	my ($att) = @_;
	&diag(6,qq|<div class="function">Is Title?<div class="info">|);
	my $title = $att->{title};						# try 'title'
	unless ($title) { $title = $att->{"data-image-title"}; } # Fancy fancy title
	unless ($title) { $title = $att->{name}; }				# try 'name'
	unless ($title) { $title = $att->{alt}; }				# try 'alt'
	unless ($title) {							# try url
		my $url = $att->{src} || $att->{url} || $att->{href};
		my @mtitlearr = split "/",$url; $title = pop @mtitlearr;
	}
	&diag(6,qq|</div></div>|);
	return $title;
}

#------------------------  Is Type --------------------

# Return type based on URL and mimetype

sub is_type { 		# Would like to make this a loadable list at some point

	my ($url,$mimetype) = @_;
	&diag(6,qq|<div class="function">Is Type?<div class="info">|);
	my $type;
	if (&is_video($url) || $mimetype =~ /video/i) {	 $type = "video"; }		# video
	elsif (&is_audio($url) || $mimetype =~ /audio/i) {  $type = "audio"; }		# audio
	elsif (&is_slides($url)) { $type = "slides"; }					# slideshare
	elsif ($mimetype =~ /image/i) {	$type = "image"; }				# image
	elsif ($mimetype =~ /pdf|msword|powerpoint/i) {	$type = "document"; }		# document
	elsif ($mimetype =~ /zip|tar|binhex/i) { $type = "archive"; }			# archive
	else {	$type = "link";	 }							# link
	&diag(6,qq|is_type() determines type to be $type<br>|);
	&diag(6,qq|</div></div>|);
	return $type;
}


#------------------------  Is URL --------------------

# Return 0 if URL is on the 'rejected' list

sub is_url { 		# Would like to make this a loadable list at some point

	my ($feed,$url) = @_;
	&diag(6,qq|<div class="function">Is Type?<div class="info">|);
	my $href;

	unless ($url =~ /(http|https):\/\//) { &diag(6,qq|</div></div>|); return 0; }					 	# No relative URLs
	if ($feed->{feed_html}) { if ($url =~ /$feed->{feed_html}/) { &diag(6,qq|</div></div>|); return 0; } }				# - don't scrape internal links
	if ($url =~ /#!/) {	&diag(6,qq|</div></div>|); return 0;	};									# - Don't scrape hashbang links
	my @rejected = ('api.tweetmeme.com/','feeds.wordpress.com','api.postrank.com','feeds.feedburner.com',
		'www.diigo.com/user/', 'http://academicacareers.ca/','stats.wordpress.com','gravatar.com');
	foreach my $a (@rejected) { if ($url =~ /$a/i) { return 0; } }
  &diag(6,qq|</div></div>|);
	return 1;
}

#------------------------  Is Video --------------------

# Return 1 if URL is on the 'video' list

sub is_video { 		# Would like to make this a loadable list at some point

	my ($url) = @_;
	&diag(6,qq|<div class="function">Is Video?<div class="info">|);
	my @video = ('youtu.be','video.umwblogs.org','www.openshotvideo.com','blip.tv','www.youtube.com','www.theonion.com/video');
	# foreach my $a (@video) { if ($url =~ /$a/i) {   &diag(6,qq|</div></div>|);return 1; } }
	&diag(6,qq|</div></div>|);
	return 0;
}



#------------------------  Merge Media  --------------------

# Loop through scraped media items and merge duplicates


sub merge_media {

	my ($feed,$item) = @_;


	&diag(9,"MERGING<br>\n");
	&diag(9,"Item: ".$item->{link_title}." merge <br>\n");

	my @new_list = ();
	foreach my $xmedia (@{$item->{media}}) {
		my $duplicate = 0;
		foreach my $ymedia (@new_list) {
			if ($xmedia->{media_url} eq $ymedia->{media_url}) {
				while (my ($mx,$my) = each %$xmedia) {
					if ($my) {
						$ymedia->{$mx} ||= $my;
						&diag(" -- -- $mx = $my <br>\n");
					}
				}
				&diag(9,"Rejecting duplicate $ymedia->{media_url} <br>\n");
				$duplicate = 1;
			}
		}
		unless ($duplicate) { &diag(9,"Pushing $xmedia->{media_url} <br>\n"); }
		unless ($duplicate) { push @new_list,$xmedia; }
	}
	@{$item->{media}} = @new_list;


}


1;
