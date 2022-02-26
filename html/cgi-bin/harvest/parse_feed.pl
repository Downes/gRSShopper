#    gRSShopper 0.7  Parse Feed  -- gRSShopper harvester module
#    March 2, 2018 - Stephen Downes
#    cgi-bin/harvest/parse_feed.pl

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

my $dirname = dirname(__FILE__);
require $dirname."/tags.pl";

sub parse_feed {

	my ($feedrecord) = @_;
	&diag(2,qq|<div class="function">Parse Feed<div class="info">|);
	&diag(2,"Parsing Feed $feedrecord->{feed_id}: ".$feedrecord->{feed_title}."<p>\n\n");
	&diag(8,qq|<div class="data"><form><textarea cols=140 rows=80>|.$feedrecord->{feedstring}."</textarea><form></div>\n\n");

  # Clean the XML (Special for UdeM feed - convert ascii codes to html escape codes)
	$feedrecord->{feedstring} =~ s/\x92/'/g;                                            # '
	my @ascii_codes = (153,154,169,171,187..214,224..254);
	my @funny_chars = split("", pack("C*", @ascii_codes));
	my $x; for ($x=0; $x<=$#ascii_codes; $x++) { $feedrecord->{feedstring}  =~ s/$funny_chars[$x]/&#$ascii_codes[$x]/g; }

  # Remove CDATA, Initialize line counter and content flag
	&process_cdata($feedrecord);
	my $linecount = 0;						#
	$vars->{content} = "off";

  # Split into lines
	my @lines = split "<",$feedrecord->{feedstring};

  # For each line...
	foreach my $l (@lines) {
		last if ($linecount > 5000);

    # Check for Feed error
 		if ($linecount == 1) {					# First line, make sure we don't have a feed error
			unless ($l =~ /\?xml/i || $l =~ /rss/i) {   # which would be indicated if the first line isn't xml
				&diag(2,qq|<div class="harvestererror">Feed error: line 1 did not begin with &lt;xml or &lt;rss</div>>|);
			  return "feed error" ;	#     (note Google alert starts with <rss...> )
		  }
		}

		# Analyze the tag
		$linecount++; $vars->{linecount}="$linecount";		# Special for link = http://www.cbc.ca/podcasting
		my ($tag,$attributes,$content) = &process_line($l);	# Process line to get tag, attributes, content
		$feedrecord->{content_buffer} .= $content;
		$feedrecord->{attributes_buffer} .= $attributes;
		&diag(5,"<br>Analysis: Tag: $tag | Attributes: $attributes<br>");

    # Or process content (by adding it to the content buffer)
		if ($vars->{content} eq "on") {				# If we're processing content
			unless ($tag =~ /^\// && &detect_content($tag)) {	#   then unless we're closing the content tag
				$feedrecord->{content_buffer} .= "<".$l;	#      Restore < and add line to the content string

				next;					#      and move on
			}
		}

		# Close the element
		if ($tag =~ s/^\///) {					# If it's a close element tag

			&diag(7,"Content: ".$feedrecord->{content_buffer}."<br>");
			&element_close($feedrecord,$tag,$feedrecord);			#     Close Element

    # Or Open the element
		} else {

			&element_open($feedrecord,$tag);

			if ($attributes =~ /(.*?)(\/|\?)$/) {		# Single-line element, close here
				&diag(7,"Content: ".$feedrecord->{content_buffer}."<br>");
				&element_close($feedrecord,$tag,$feedrecord);		#     Close Element
			}
		}


	}

	&diag(2,qq|Parse Feed Completed\n\n|);
	&diag(2,qq|</div></div>\n\n|);

}












#------------------------  Process line  --------------------

sub process_line {

	my ($l) = @_;
	&diag(5,qq|<div class="function">Process Line<div class="info">|);
	&diag(5,qq|Line: <form><textarea cols=80 rows=1>$l</textarea></form><br>|);

	$l =~ s/\n|\r//g;
	my ($element,$content) = split ">",$l;		# Split line at end of element
	$content =~ s/(^\s*|\s*$)//g;

	my @elementitems = split " ",$element;		# Carve off attributes to find tag in element
	my $tag = shift @elementitems;
	my $attributes = join " ",@elementitems;	# Rebuild attribute string

	&diag(5,qq|</div></div>\n\n|);
	return ($tag,$attributes,$content);

}







#------------------------  Detect Content --------------------
#
#	Defines which tags are content types, and might contain html
#

sub detect_content {

	my ($tag) = @_;
	&diag(9,qq|<div class="function">Detect Content<div class="info">|);
		$tag =~ s/^\///;    # strip leading slash, to detect closes as well
	my $type = "";
	if ($tag =~ /(summary$|^media:text$|^content$|^content:encoded$|^description$)/i) {
		$type = "content";
	}
	&diag(9,qq|Content type: $type|);
	&diag(9,qq|</div></div>|);
	return $type;
}


#------------------------  Process attributes  --------------------

#
#   Receive attribute string
#   Return hash with attribute name as key and value as value

sub process_attributes {

	my ($attributes) = @_;

	$attributes =~ s/\/$//;	my $del; my $att;					# Carve closing /
	if ($attributes =~ /=("|')/) { $del = $1; }					# Find delimeter ' or "
	my @attitems = split /$del /,$attributes;					# Split at the delimeter

	foreach my $ai (@attitems) {							# For each attribute
		my ($attkey,$attval) = split/=$del/,$ai;				# Split at the delimiter
		$attval =~ s/$del$//;							# Carve trailing delimeter
		if ($attkey =~ /url|uri|href|src/) { &process_url($attval);}		# process URLs
		$att->{$attkey} = $attval;						# Store values
	}
	$att->{href} =~ s/utm=(.*?)$//;							# Wipe out utm parameters
	$att->{src} =~ s/utm=(.*?)$//;							# Wipe out utm parameters
	return $att;
}

#------------------------  Element Open  --------------------

sub element_open {

	my ($feed,$tag) = @_;
	&diag(6,qq|<div class="function">Element Open<div class="info">|);
	&diag(6,qq|Tag: $tag <br>|);


	# If the element is a feed, link, author, publisher or media, create an object and add to object stack
	# If it's a content element (and might contain HTML) turn content flag on
	# Add the element to the tag stack

	if (my $type = &detect_object($tag)) {

		&diag(9,qq|Object Detected: $type<br>|);
		my $record = gRSShopper::Record->new(tag => $tag,parent=>$feed,type=>$type,diag_level => $Site->{diag_level});
		&diag(4,"New record created, type = $type, from element_open($tag) <br>");

		$record->{attributes} = $feed->{attributes_buffer};
		unshift @{$feed->{objectstack}},$record;
	}

	if (&detect_content($tag)) {
		$vars->{content} = "on";
	}


	unshift @{$feed->{stack}},$tag;			# Add tag to stack
	&diag(6,qq|</div></div>|);
}

#------------------------  Element Close --------------------

sub element_close {

	# shouldn't I be getting the feedrecord here?
	my ($feed,$tag,$feedrecord) = @_;
	&diag(6,qq|<div class="function">Element Close<div class="info">|);

	my $child = ${$feed->{objectstack}}[0];
	my $parent = ${$feed->{objectstack}}[1];

	my $type = &detect_object($tag);

	my $parenttype = $parent->{type};
	&diag(7,qq|Tag: $tag, Parent Type: $parenttype.<br>|);

#print $feed->{objectstack};my $ccc=0;
#foreach my $f (@{$feed->{objectstack}}) { print $f,"<p>"; $ccc++;}
#print "Found $ccc array items<p>";
  if (@{$feed->{objectstack}}[0] && @{$feed->{objectstack}}[1]) {
		my $type = @{$feed->{objectstack}}[0]->{type};
		my $parenttype = @{$feed->{objectstack}}[1]->{type};
		&diag(7," Tag: $tag  Type: $type Content Buffer: $feed->{content_buffer} <br>\n");
  }

	if ($type eq "link") {

	  &diag(9,qq|Type = Link<br>|);
		push @{$parent->{items}},$child;
		my $att = process_attributes($child->{attributes});      		# Sometimes 'entry' has attributes
		if ($att->{'gd:etag'}) { $child->{link_gdetag} = $att->{'gd:etag'}; }	# gd:etag

		&diag(9,"Child: $child->{type} Parent: $parent->{type}\n\n");
											# OK, now close the link :)
	}

	elsif ($type eq "author") {							# ^itunes:owner$|^author$|^dc:creator$

		&diag(9,qq|Type = Author<br>|);
		push @{$parent->{authors}},$child;

		$child->{author_name} = $feed->{content_buffer};
		&diag(9,"Child: $child->{type} Parent: $parent->{type}<p>\n\n");


	}

	elsif ($type eq "media") {							# ^image$|^media$|^media:content$

		&diag(9,qq|Type = Media<br>|);
		push @{$parent->{media}},$child;

		my $att = process_attributes($child->{attributes});      		# 'Media:content' tag attributes
		if ($att->{url}) { $child->{media_url} = $att->{url}; }
		if ($att->{medium}) { $child->{media_type} = $att->{medium}; }

		&diag(9,"Child: $child->{type} Parent: $parent->{type}\n\n");
		# Capture Podcast from YouTube Videos
		# We only run the conversion once, when we capture the link for the first time

		if (($parent->{link_link} =~ m|youtube\.com|) && ($feedrecord->{feed_section} eq "podcast")) {
			&diag(6,"This is a podcast! Creating audio out of the video: $child->{link_link}");
	    my $dirname = dirname(__FILE__);
      require $dirname."/harvest_youtube.pl";
			my ($purl,$plength) = &youtube_to_podcast($parent->{link_link});
			if ($purl) {
				if ($purl =~ /^Error/) {
					&diag(1,qq|<div class="harvestererror">Error in $purl<br>|); }
				else {
					$child->{media_medialink} = $att->{url};
					$child->{media_url} = $purl;
					$child->{media_length} = $plength;
					$child->{media_mimetype} = "audio/mpeg";
					$child->{media_feed} = $feedrecord->{feed_id};
				}
			}

		}

	}

	elsif (&detect_content($tag)) {  						# Content Tags

		&diag(9,qq|Tag detected: $tag<br>|);
		$vars->{content} = "off";

		#	summary$|^media:text$|^content$|^content:encoded$|^description$
		for ($tag) {

			# content
			/^content$/i && do { _content($child,$feed->{content_buffer}); last; };

			# content:encoded
			/^content:encoded$/i && do { _content_encoded($child,$feed->{content_buffer}); last; };

			# description
			/^itunes:summary$/i && do { _description($child,$feed->{content_buffer}); last; };

			# itunes
			/^itunes:summary$/i && do { _itunes_summary($child,$feed->{content_buffer}); last; };

			# media: text
			/^media:text$/i && do { _media_text($child,$feed->{content_buffer}); last; };

			# summary
			/^summary$/i && do { _summary($child,$feed->{content_buffer}); last; };

		}



		$child->{$child->{type}."_".$tag} = $feed->{content_buffer};

		&diag(9,$tag.": ".$feed->{content_buffer}."<br>\n");


	}

	else {										# Other Tags

		&diag(9,$tag." ".$feed->{attributes_buffer}.": ".$feed->{content_buffer}."<br>\n");

		for ($tag) {

			# app
			/^app:edited$/i && do  { _app_edited($child,$feed->{content_buffer}); last; };

			# atom
			/^atom:updated$/i && do  { _atom_updated($child,$feed->{content_buffer}); last; };
			/^atom:id$/i && do  { _atom_id($child,$feed->{content_buffer}); last; };

			# blogChannel
			/blogChannel:blogRoll$/i && do { _blogChannel_blogRoll($child,$feed->{content_buffer}); last; };

			# category, itunes:category, media:category
			/category$/i && do { _category($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };

			# cloud
			/^cloud$/i && do { _cloud($child,$feed->{content_buffer}); last; };

			# comments
			/^comments$/i && do  { _comments($child,$feed->{content_buffer}); last; };

			# copyright
			/^copyrights$/i && do  { _copyright($child,$feed->{content_buffer}); last; };

			# creativeCommons
			/^creativeCommons:license$/i && do  { _creativeCommons_license($child,$feed->{content_buffer}); last; };

			# dc
			/^dc:date$/i && do  { _dc_date($child,$feed->{content_buffer}); last; };
			/^dc:subject$/i && do  { _dc_subject($child,$feed->{content_buffer}); last; };
			/^dc:publisher$/i && do  { _dc_publisher($child,$feed->{content_buffer}); last; };
			/^dc:title$/i && do  { _dc_title($child,$feed->{content_buffer}); last; };

			# docs
			/^docs$/i && do  { _copyright($child,$feed->{content_buffer}); last; };

			# email
			/^email$/i && do  { _email($child,$feed->{content_buffer}); last; };

			# enclosure
			/^enclosure$/i && do { _enclosure($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };

			# feedburner
			/^feedburner:browserFriendly$/i && do { _feedburner_browserFriendly($child,$feed->{content_buffer}); last; };
			/^feedburner:emailServiceId$/i && do { _feedburner_emailServiceId($child,$feed->{content_buffer}); last; };
			/^feedburner:feedburnerHostname$/i && do { _feedburner_feedburnerHostname($child,$feed->{content_buffer}); last; };
			/^feedburner:info$/i && do { _feedburner_info($child,$feed->{content_buffer}); last; };
			/^feedburner:origLink$/i && do { _feedburner_origLink($child,$feed->{content_buffer}); last; };

			# gd
			/^gd:extendedProperty$/ && do { _gd_extendedProperty($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };
			/^gd:image$/ && do { _gd_image($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };

			# geo
			/^geo:lat$/i && do { _geo_lat($child,$feed->{content_buffer}); last; };
			/^geo:long$/i && do { _geo_long($child,$feed->{content_buffer}); last; };
			/^georss:point$/i && do { _georss_point($child,$feed->{content_buffer}); last; };

			# generator
			/^generator$/i && do { _generator($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };

			# guid
			/^guid$/i && do  { _guid($child,$feed->{content_buffer}); last; };

			# height
			/^height$/i && do  { _height($child,$feed->{content_buffer}); last; };

			# icon
			/^icon$/i && do  { _icon($child,$feed->{content_buffer}); last; };

			# id
			/^id$/i && do  { _id($child,$feed->{content_buffer}); last; };

			# issued
			/^issued$/i && do  { _issued($child,$feed->{content_buffer}); last; };

			# itunes
			/^itunes:author$/i && do { _itunes_image($child,$feed->{content_buffer}); last; };
			/^itunes:block$/i && do { _itunes_block($child,$feed->{content_buffer}); last; };
			/^itunes:category$/i && do { _itunes_category($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };
			/^itunes:copyright$/i && do { _itunes_copyright($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };
			/^itunes:duration$/i && do { _itunes_duration($child,$feed->{content_buffer}); last; };
			/^itunes:email$/i && do { _itunes_email($child,$feed->{content_buffer}); last; };
			/^itunes:explicit$/i && do { _itunes_explicit($child,$feed->{content_buffer}); last; };
			/^itunes:keywords$/i && do { _itunes_keywords($child,$feed->{content_buffer}); last; };
			/^itunes:image$/i && do { _itunes_image($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };
			/^itunes:name$/i && do { _itunes_name($child,$feed->{content_buffer}); last; };
			/^itunes:subtitle$/i && do { _itunes_subtitle($child,$feed->{content_buffer}); last; };

			# language
			/^language$/i && do  { _language($child,$feed->{content_buffer}); last; };

			# lastBuildDate
			/^lastBuildDate$/i && do  { _lastBuildDate($child,$feed->{content_buffer}); last; };

			# link, atom:link
			/link$/i && do { _link($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };

			# logo
			/^logo$/i && do  { _logo($child,$feed->{content_buffer}); last; };

			# managingEditor
			/^managingEditor$/i && do  { _managingEditor($child,$feed->{content_buffer}); last; };

			# media - used for media objects, but will work for any object in this parser
			# TODO still need to add: media 5.13 ff http://www.rssboard.org/media-rss#media-restriction
			/^media:category$/i && do { _media_category($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };
			/^media:credit$/i && do { _media_credit($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };
			/^media:description$/i && do { _media_description($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };
			/^media:hash$/i && do { _media_hash($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };
			/^media:keywords$/i && do { _media_keywords($child,$feed->{content_buffer}); last; };
			/^media:player$/i && do { _media_player($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };
			/^media:rating$/i && do { _media_rating($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };
			/^media:thumbnail$/i && do { _media_thumbnail($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };
			/^media:title$/i && do { _media_title($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };

			# modified
			/^moified$/i && do  { _modified($child,$feed->{content_buffer}); last; };

			# name
			/^name$/i && do  { _name($child,$feed->{content_buffer}); last; };

			# openSearch
			/^openSearch:totalResults$/i && do { _openSearch_totalResults($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };
			/^openSearch:startIndex$/i && do { _openSearch_startIndex($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };
			/^openSearch:itemsPerPage$/i && do { _openSearch_itemsPerPage($child,$feed->{content_buffer},$feed->{attributes_buffer}); last; };

			# pingback
			/^pingback:server$/i && do  { _pingback_erver($child,$feed->{content_buffer}); last; };
			/^pingback:target$/i && do  { _pingback_target($child,$feed->{content_buffer}); last; };

			# ppg
			/^ppg:canonical$/i && do  { _ppg($child,$feed->{content_buffer}); last; };

			# pubDate
			/^pubDate$/i && do  { _pubDate($child,$feed->{content_buffer}); last; };

			# published
			/^published$/i && do  { _published($child,$feed->{content_buffer}); last; };

			# rights
			/^rights$/i && do  { _rights($child,$feed->{content_buffer}); last; };

			# slash
			/^slash:comments$/i && do  { _slash_comments($child,$feed->{content_buffer}); last; };
			/^slash:department$/i && do  { _slash_department($child,$feed->{content_buffer}); last; };
			/^slash:hit_parade$/i && do  { _slash_hit_parade($child,$feed->{content_buffer}); last; };
			/^slash:section$/i && do  { _slash_section($child,$feed->{content_buffer}); last; };

			# subtitle
			/^subtitle$/i && do  { _subtitle($child,$feed->{content_buffer}); last; };

			# syndication
			/^sy:updatePeriod$/i && do  { _sy_updatePeriod($child,$feed->{content_buffer}); last; };
			/^sy:updateFrequency$/i && do  { _sy_updateFrequency($child,$feed->{content_buffer}); last; };
			/^sy:updateBase$/i && do  { _sy_updateBase($child,$feed->{content_buffer}); last; };

			# tagline
			/^tagline$/i && do  { _tagline($child,$feed->{content_buffer}); last; };

			# thr
			/^thr:comments$/i && do  { _tagline($child,$feed->{content_buffer}); last; };
			/^thr:total$/i && do  { _tagline($child,$feed->{content_buffer}); last; };

			# title
			/^title$/i && do  { _title($child,$feed->{content_buffer}); last; };

			# ttl
			/^trackback:ping$/i && do  { _trackback_ping($child,$feed->{content_buffer}); last; };

			# ttl
			/^ttl$/i && do  { _ttl($child,$feed->{content_buffer}); last; };

			# updated
			/^updated$/i && do  { _updated($child,$feed->{content_buffer}); last; };

			# uri
			/^uri$/i && do  { _uri($child,$feed->{content_buffer}); last; };

			# url
			/^url$/i && do  { _url($child,$feed->{content_buffer}); last; };

			# webMaster
			/^webMaster$/i && do  { _webMaster($child,$feed->{content_buffer}); last; };

			# wfw
			/^wfw:comment$/i && do  { _wfw_comment($child,$feed->{content_buffer}); last; };
			/^wfw:comments$/i && do  { _wfw_comments($child,$feed->{content_buffer}); last; };
			/^wfw:commentRss$/i && do  { _wfw_commentRSS($child,$feed->{content_buffer}); last; };

			# width
			/^width$/i && do  { _width($child,$feed->{content_buffer}); last; };

			# xml - don't do anything
			/^channel$/i && do { last; };
			/^rss$/i && do { last; };
			/^\?xml$/i && do { last; };
			/^\?xml-stylesheet$/  && do { last; };

			&diag(1,qq|<div class="harvestererror">Unknown element $tag</div>\n\n|);


		}


	}



	${$feed->{objectstack}}[0] = $child;
	${$feed->{objectstack}}[1] = $parent;


	if ($child->{type} eq "feed") { $feed->{processed} = $child; }


	if (&detect_content($tag)) {  $vars->{content} = "off";  }




	#$feed->{processed} = ${$feed->{objectstack}}[0];	# Save object



	shift @{$feed->{stack}};					# Remove tag from stack
	if ($type) {
		shift @{$feed->{objectstack}};


		}	# If object, remove object
	$feed->{content_buffer} = "";					# Clear content buffer
	$feed->{attributes_buffer} = "";

	&diag(6,qq|</div></div>|);
}



#------------------------  Detect Object --------------------
#
#	Defines which tags are objects, returns the object type
#

sub detect_object {

	my ($tag) = @_;

	my $type = "";
	if ($tag =~ /(^feed$|^channel$)/i) { $type = "feed"; }
	elsif ($tag =~ /(^item$|^entry$)/i) {  $type = "link"; }
	elsif ($tag =~ /(^itunes:owner$|^author$|^dc:creator$)/i) {  $type = "author"; }
	elsif ($tag =~ /(^dc:publisher$)/i) {  $type = "publisher"; }
	elsif ($tag =~ /(^itunes:image$|^image$|^media$|^media:content$)/i) {  $type = "media"; }

	return $type;
}




1;
