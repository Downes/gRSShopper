#    gRSShopper 0.7  Tags  -- gRSShopper harvester module
#    March 2, 2018 - Stephen Downes
#    cgi-bin/harvest/tags.pl

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


#----------  tags ---------------------


sub _app_edited {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_updated"} = $content;
}


sub _atom_id {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_blogID"} = $content;
}


sub _atom_updated {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_updated"} = $content;
}


sub _blogChannel_blogRoll {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_blogroll"} = $content;
}


sub _category {

	my ($element,$content,$attributes) = @_;
	my $type = $element->{type};



	if ($attributes) {
		my $att = process_attributes($attributes);
		$content .= $att->{term};
		if ($att->{scheme}) { $content = $att->{scheme} . ":" . $content; }
	}
	$element->{$type."_category"} = &append_to_list($element->{$type."_category"},$content);


}

sub _cloud {

	my ($element,$content,$attributes) = @_;
	my $att = process_attributes($attributes);      		# Cloud always has attributes
	my $type = $element->{type};


	$element->{$type."_cloudDomain"} = $att->{domain};
	$element->{$type."_cloudPort"} = $att->{port};
	$element->{$type."_cloudPath"} = $att->{path};
	$element->{$type."_cloudRegister"} = $att->{registerProcedure};
	$element->{$type."_cloudProtocol"} = $att->{protocol};

}


sub _comments {

	# Obviously a very partial represendation of the slash extension


	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_commentURL"} = $content;
}


sub _content {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_content"} = $content;
}


sub _content_encoded {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_content"} = $content;
}


sub _copyright {

	my ($element,$content,$attributes) = @_;
	my $type = $element->{type};

	my $att = process_attributes($attributes);
	if ($att->{url}) { $content .= ";".$att->{url}; }
	$element->{$type."_copyright"} = $content;

}


sub _creativeCommons_license {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_copyright"} = $content;

}



sub _dc_date {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_updated"} ||= $content;
	$element->{$type."_issued"} ||= $content;

}


sub _dc_publisher {	# I might make this an object later

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_publisher"} ||= $content;

}

sub _dc_subject {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$content =~ s/,\s*/;/g;			# gRSShopper uses ; to delimit list items
	$element->{$type."_subject"} = &append_to_list($element->{$type."_topic"},$content);
}


sub _dc_title {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_title"} = $content;

}


sub _description {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_description"} = $content;
}


sub _docs {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_docs"} = $content;

}

sub _email {		# Typically applies to  author object

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_email"} = $content;
}

sub _enclosure {

	my ($element,$content,$attributes) = @_;
	print "Processing _enclosure for $element->{type} ..." if ($DEBUG > 0);
	my $DEBUG = 2;
	my $att = &process_attributes($attributes);      		# Enclosure always has attributes (except for Feedburner, which is broken)
	my $type = $element->{type};

	if ($DEBUG > 1) {
		print "<br>Content: $content <br>Attributes: $attributes <br>Parsed attributed:<br>";
		while (my($ax,$ay) = each %$att) { print "$ax = $ay <br>"; }
	}

	my $media = gRSShopper::Record->new(tag => 'enclosure',type=>'media');     			# Set values
	print "New media record in _enclosure for $att->{url}<br>"  if ($DEBUG > 0);
	$media->{media_url} = $att->{url} || $content;			# $content will capture feedburner url
	$media->{media_size} = $att->{length};
	$media->{media_mimetype} = $att->{type};
	if ($content) { $media->{media_title} = $content; }
	else {
		my @mtitlearr = split "/",$att->{url};
		$media->{media_title} = pop @mtitlearr;
	}
	print "\nFinished.<br>Media title is $media->{media_title} <br>Media URL is: $media->{media_url} <br>" if ($DEBUG > 0);


	push @{$element->{media}},$media;

}


sub _feedburner_browserFriendly {

	my ($element,$content,$attributes) = @_;
	my $att = &process_attributes($attributes);
	my $type = $element->{type};

	if ($att->{uri}) { $element->{$type."_browserFriendly"} =  $att->{uri}; }

}


sub _feedburner_emailServiceId {

	my ($element,$content,$attributes) = @_;
	my $att = &process_attributes($attributes);
	my $type = $element->{type};

	if ($att->{uri}) { $element->{$type."_feed_feedburnerid"} =  $att->{uri}; }

}

sub _feedburner_feedburnerHostname {

	my ($element,$content,$attributes) = @_;
	my $att = &process_attributes($attributes);
	my $type = $element->{type};

	if ($att->{uri}) { $element->{$type."_feedburnerhost"} =  $att->{uri}; }

}

sub _feedburner_info {

	my ($element,$content,$attributes) = @_;
	my $att = &process_attributes($attributes);
	my $type = $element->{type};

	if ($att->{uri}) { $element->{$type."_feedburnerurl"} =  $att->{uri}; }

}


sub _feedburner_origLink {

	my ($element,$content) = @_;
	my $type = $element->{type};

	# Note tha 'link' tag is superseded by feedburner:origLink
	$content = &process_url($content);
	$element->{$type."_link"} = $content;

}


sub _gd_extendedProperty {

	my ($element,$content,$attributes) = @_;
	my $att = &process_attributes($attributes);
	my $type = $element->{type};

	if ($att->{name} eq "OpenSocialUserId") {
		$element->{$type."_opensocialuserid"} = $att->{value};
	}  else {
		&diag(1,qq|<div class="harvestererror">_gd_extendedProperty() : $att->{name} unknown in $element->{tag}</div>\n|);
	}

}

sub _gd_image {			# Author imnage thumbnail

	my ($element,$content,$attributes) = @_;
	my $att = &process_attributes($attributes);
	my $type = $element->{type};

	if ($att->{name} eq "rel") {		# Possible attributes, things you can do
		# schema
	}

	if ($att->{name} eq "width") {
		# width
	}

	if ($att->{name} eq "height") {
		# height
	}

	if ($att->{name} eq "src") {
		$element->{$type."_thumbnail"} = $att->{value};
		# schema
	}

}

sub _geo_lat {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_geo_lat"} = $content;

}


sub _geo_long {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_geo_long"} = $content;
}


sub _georss_point {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_geo"} = "point:".$content;
}


sub _generator {

	my ($element,$content,$attributes) = @_;
	my $att = &process_attributes($attributes);
	my $type = $element->{type};

	if ($att->{version}) { $element->{$type."_genver"} = $att->{version}; }
	if ($att->{url}) { $element->{$type."_genurl"} = $att->{url}; }
	if ($content) { $element->{$type."_genname"} = $content; }

}


sub _guid {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_guid"} = $content;
}


sub _height {				# Typically used with the 'image' media object

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_height"} = $content;
}


sub _icon {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_imgURL"} = $content;
}


sub _id {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_blogID"} = $content;		# For feeds
	$element->{$type."_guid"} = $content;		# The rest

}


sub _issued {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_issued"} = $content;
}


sub _itunes_author {

	my ($element,$content) = @_;

	my $type = $element->{type};

							# Initialize Author Object, as appropriate
	my $author = gRSShopper::Record->new(tag => 'author',type => 'author');     	# Set values
	$author->{type} = "author";
	$author->{author_name} = $content;
	push @{$element->{authors}},$author;

}


sub _itunes_block {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_itunesblock"} = $content;
}


sub _itunes_category {

	my ($element,$content,$attributes) = @_;
	my $type = $element->{type};

	if ($attributes) {
		my $att = process_attributes($attributes);
		$content .= $att->{term};
		if ($att->{scheme}) { $content = $att->{scheme} . ":" . $content; }
	}
	$element->{$type."_category"} = &append_to_list($element->{$type."_category"},$content);

}


sub _itunes_duration {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_duration"} = $content;
}


sub _itunes_email {		# Typically applies to itunes:owner author object

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_email"} = $content;
}


sub _itunes_explicit {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_explicit"} = $content;
}


sub _itunes_image {

	my ($element,$content,$attributes) = @_;
	my $att = &process_attributes($attributes);
	my $type = $element->{type};

	if ($att->{href}) { unless ($element->{$type."_imgURL"}) { $element->{$type."_imgURL"} =  $att->{href}; }  }
	if ($content) { unless ($element->{$type."_imgURL"}) { $element->{$type."_imgURL"} =  $content; }  }

}


sub _itunes_keywords {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$content =~ s/,\s*/;/g;			# gRSShopper uses ; to delimit list items
	$element->{$type."_topic"} = &append_to_list($element->{$type."_topic"},$content);
}




sub _itunes_name {		# Typically applies to itunes:owner author object

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_name"} = $content;
}


sub _itunes_subtitle {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_subtitle"} = $content;
}


sub _itunes_summary {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_description"} ||= $content;
}


sub _language {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_language"} = $content;

}


sub _lastBuildDate {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_updated"} = $content;

}

sub _link {

	my ($element,$content,$attributes) = @_;

	&diag(5,"LINK: $element->{type},$content,$attributes <br>\n");

	my $type = $element->{type};
	$content = &process_url($content);

	if ($attributes) {
		my $att = process_attributes($attributes);


		if ($att->{rel} =~ /^self$/i) {
			$element->{$type."_link"} ||= $att->{href};
		}

		elsif ($att->{rel} =~ /^alternate$/i) {
			$element->{$type."_link"} = $att->{href};      # Will supersede rel=self

		}

		elsif  ($att->{rel} =~ /^replies$/i) {
			$element->{$type."_comments"} = $att->{href};

		}

		elsif ($att->{rel} =~ /^hub$/i) {

			$element->{$type."_hub"} = $att->{href};


		}

		elsif ($att->{rel} =~ /^enclosure$/i) {		# enclosure in Atom

									# Initialize Media Object, as appropriate
			my $media = gRSShopper::Record->new(tag => 'enclosure',type => 'media');     	# Set values
			print "New media record in _link for $att->{href}<br>"  if ($DEBUG > 0);
			$media->{type} = "media";
			$media->{media_url} = $att->{href};
			$media->{media_size} = $att->{length};
			$media->{media_mimetype} = $att->{type};
			my @mtitlearr = split "/",$att->{href};
			$media->{media_title} = pop @mtitlearr;


			push @{$element->{media}},$media;



		} elsif ($att->{type} =~ "image") {					# Twitter Images
			$element->{$type."_thumbnail"} = $att->{href};

		} elsif ($att->{href}) {						# PHPBB style links

			$element->{$type."_link"} ||= $att->{href};
		} else {

			&diag(0,qq|<p class="red">Exception, not sure what to do with atom10:link rel = $att->{rel} <br>\n </p>|);

		}


	} else {  # Note tha 'link' tag is superseded by feedburner:origLink
		  # Also, we don't want to replace original link in feed->{feed_link}
		unless ($type eq "feed") { $element->{$type."_link"} ||= $content; }

	}


}


sub _logo {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_imgURL"} = $content;

}


sub _managingEditor {					# Should eventually become a type of author

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_managingEditor"} = $content;

}




sub _media_category {

	my ($element,$content,$attributes) = @_;
	my $type = $element->{type};

	if ($attributes) {
		my $att = process_attributes($attributes);
		$content .= $att->{term};
		if ($att->{scheme}) { $content = $att->{scheme} . ":" . $content; }
	}
	$element->{$type."_category"} = &append_to_list($element->{$type."_category"},$content);

	# gRSShopper does not support the optional 'lable' attributed defined
	# in the spec at http://www.rssboard.org/media-rss#media-category

}


sub _media_copyright {

	my ($element,$content,$attributes) = @_;
	my $type = $element->{type};

	my $att = process_attributes($attributes);
	if ($att->{url}) { $content .= ";".$att->{url}; }
	$element->{$type."_copyright"} = $content;

}


sub _media_credit {

	my ($element,$content,$attributes) = @_;
	my $type = $element->{type};			# Probably 'media' but we're stick to the format

	if ($attributes) {
		my $att = process_attributes($attributes);
		if ($att->{role}) { $content = $att->{role} . ":" . $content; }
	}
	$element->{$type."_credits"} = &append_to_list($element->{$type."_credits"},$content);

}


sub _media_description {

	my ($element,$content,$attributes) = @_;
	my $type = $element->{type};

	if ($attributes) {
		my $att = process_attributes($attributes);
		if ($att->{type} eq "html") { $content = decode_entities($content); }  	# uses HTML::Entities
	}

	$element->{$type."_description"} ||= $content;

}


sub _media_hash {

	my ($element,$content,$attributes) = @_;
	my $type = $element->{type};			# Probably 'media' but we're stick to the format

	if ($attributes) {
		my $att = process_attributes($attributes);
		if ($att->{algo}) { $content = $att->{algo} . ":" . $content; }
	}
	$element->{$type."_hash"} = $content;

}


sub _media_keywords {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$content =~ s/,\s*/;/g;			# gRSShopper uses ; to delimit list items
	$element->{$type."_topic"} = &append_to_list($element->{$type."_topic"},$content);
}


sub _media_player {

	my ($element,$content,$attributes) = @_;
	my $type = $element->{type};			# Probably 'media' but we're stick to the format


	if ($attributes) {
		my $att = process_attributes($attributes);

		$element->{$type."_plurl"} = $att->{url};
		$element->{$type."_plheight"} = $att->{height};
		$element->{$type."_plwidth"} = $att->{width};
		$element->{$type."_player"} = $att->{url} .";".$att->{width}.";".$att->{height};
	}
}


sub _media_rating {

	my ($element,$content,$attributes) = @_;
	my $type = $element->{type};

	if ($attributes) {
		my $att = process_attributes($attributes);
		$content .= $att->{term};
		if ($att->{scheme}) { $content = $att->{scheme} . ":" . $content; }
	}
	$element->{$type."_rating"} = &append_to_list($element->{$type."_rating"},$content);

}


sub _media_text {

	my ($element,$content,$attributes) = @_;
	my $type = $element->{type};

	if ($attributes) {
		my $att = process_attributes($attributes);
		if ($att->{type} eq "html") { $content = decode_entities($content); }  	# uses HTML::Entities
		my $start = "start:".$att->{start};
		my $end = "end:".$att->{end};
		$content = "<p>($start;$end) $content</p>";
	}

	$element->{$type."_content"} ||= $content;

	# gRSShopper does not support separate text entries, as per the specification at
	# http://www.rssboard.org/media-rss#media-text
	# but it does collect all relevant data and places it into the 'content' element
	# in an easy-to-parse format

}

sub _media_thumbnail {

	my ($element,$content,$attributes) = @_;
	my $type = $element->{type};			# Probably 'media' but we're stick to the format

	# gRSShopper supports only one thumbnail, not a whole series as defined in the
	# specification at http://www.rssboard.org/media-rss#media-thumbnails
	# As per that spec, the first thumbnail is taken to be the most important

	if ($attributes) {
		my $att = process_attributes($attributes);

		$element->{$type."_thurl"} ||= $att->{url};
		$element->{$type."_thheight"} ||= $att->{height};
		$element->{$type."_thwidth"} ||= $att->{width};
	}
}


sub _media_title {

	my ($element,$content,$attributes) = @_;
	my $type = $element->{type};

	if ($attributes) {
		my $att = process_attributes($attributes);
		if ($att->{type} eq "html") { $content = decode_entities($content); }  	# uses HTML::Entities
	}

	if ($content) { $element->{$type."_title"} = $content; }

}


sub _modified {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_updated"} = $content;
}


sub _name {		# Typically applies to  author object

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_name"} = $content;
}


sub _openSearch_totalResults {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_OStotalResults"} = $content;
}

sub _openSearch_startIndex {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_OSstartIndex"} = $content;
}

sub _openSearch_itemsPerPage {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_OSitemsPerPag"} = $content;
}


sub _pingback_server {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_pingserver"} = $content;
}


sub _pingback_target {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_pingtarget"} = $content;
}

sub _ppg {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_ppg"} = $content;

}

sub _pubDate {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_issued"} = $content;
}


sub _published {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_issued"} = $content;
}


sub _rights {

	my ($element,$content,$attributes) = @_;
	my $type = $element->{type};

	my $att = process_attributes($attributes);
	if ($att->{url}) { $content .= ";".$att->{url}; }
	$element->{$type."_copyright"} = $content;

}


sub _subtitle {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_subtitle"} = $content;
}


sub _summary {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_description"} ||= $content;
}


sub _sy_updatePeriod {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_updatePeriod"} ||= $content;
}


sub _sy_updateFrequency {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_updateFrequency"} ||= $content;
}


sub _sy_updateBase {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_updateBase"} ||= $content;
}


sub _tagline {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_subtitle"} = $content;
}


sub _slash_comments {

	# Obviously a very partial represendation of the slash extension


	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_comments"} = $content;
}


sub _slash_department {

	# Obviously a very partial represendation of the slash extension


	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_department"} = $content;
}


sub _slash_hit_parade {

	# Obviously a very partial represendation of the slash extension


	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_hit_parade"} = $content;
}


sub _slash_section {

	# Obviously a very partial represendation of the slash extension


	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_section"} = $content;
}

sub _thr_commments {

	# Obviously a very partial represendation of the thr extension
	# TODO fix threading per http://www.niallkennedy.com/blog/2006/09/feed-threads-comments.html
	# and http://purl.org/syndication/thread/1.0

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_commentURL"} = $content;
}


sub _thr_totals {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_comments"} = $content;
}


sub _title {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_title"} = $content;
}


sub _trackback_ping {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_pingtrackback"} = $content;
}


sub _ttl {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_ttl"} = $content;
}


sub _updated {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_updated"} = $content;
}


sub _uri {		# Typically applies to  author object

	my ($element,$content) = @_;
	my $type = $element->{type};

	if ($type eq "author" || $type eq "link") {
		$element->{$type."_link"} = $content;
	} else {
		$element->{$type."_url"} = $content;
	}
}


sub _url {				# Typically used with the 'image' media object

	my ($element,$content) = @_;
	my $type = $element->{type};

	$content = &process_url($content);
	$element->{$type."_url"} = $content;
}


sub _wfw_comment {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_commentURL"} = $content;
}


sub _wfw_comments {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_comments"} = $content;
}


sub _wfw_commentRSS {

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_commentRSS"} = $content;
}


sub _webMaster {					# Should eventually become a type of author

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_webMaster"} = $content;
}


sub _width {				# Typically used with the 'image' media object

	my ($element,$content) = @_;
	my $type = $element->{type};

	$element->{$type."_width"} = $content;
}

1;
