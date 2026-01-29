#    gRSShopper 0.7  Parse JSON  -- gRSShopper harvester module
#    March 2, 2018 - Stephen Downes
#    cgi-bin/harvest/parse_jspn.pl

#    Copyright (C) <2011>  <Stephen Downes, National Research Council Canada>
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






sub parse_json {

	my ($feedrecord) = @_;

	# print "FEED RECORD ".$feedrecord->{crdate}."<p>";
print "Content-type: text/html\n\n";
print "Title: $feedrecord->{feed_title}<p>";

	use JSON qw( decode_json );

	my $decoded = decode_json($feedrecord->{feedstring});		# Decode JSON
	$feedrecord->{processed}->{type} = "feed";

#print "DECODED JSCON<p>";

#while (my($fx,$fy) = each %$decoded) { print "$fx = $fy <br>"; }
#print "<hr>";

	my $parent; my $start;							# Define Starting Point
	$parent = $feedrecord->{processed};
	$parent->{feed_type} = $feedrecord->{feed_type};
	if ($feedrecord->{feed_type} =~ /facebook/i) {
		$start = $decoded->{data};
		$feedrecord->{processed}->{type} = "feed";
	}  else {
		$start = $decoded;
		$feedrecord->{processed}->{type} = "feed";

	}






# "parent $parent  ---  ".ref($parent)."<p>";

	my $printout; my $counter;					# Process Data
	if (ref($start) eq "ARRAY") {
		($printout,$counter) = &json_array($parent,$start,0,"item");
	} elsif (ref($start) eq "HASH") {
		($printout,$counter) = &json_hash($parent,$start,0);
	}



#	 print $printout;





	print "ITEMS: <br>";
	foreach my $item (@{$feedrecord->{processed}->{items}}) {
# print "IteM: $item->{name} <hr>";
# while (my($ix,$iy) = each %$item) { 	print "$ix=$iy<br>"; }
# print "<hr>";

	}


#print "Parsong JSON<p>";
#print "<form><textarea cols=80 rows=20>$feedrecord->{feedstring}</textarea></form> <br>\n";

#exit;
}


sub json_array {
	my ($parent,$arr,$counter,$ji) = @_;

	$counter++;
	my $record = ""; my $newparent = $parent;
	my $tab = "&nbsp;&nbsp;&nbsp;"x$counter;

	my $arraystring = "";my $separator=";";
	foreach my $a (@$arr) {


		if ($ji) {

			$record = gRSShopper::Record->new(tag => $ji,parent => $parent);
			$record->{tag} = $ji;
			$record->{type} = $ji;
			$record->{feed_type} = $parent->{feed_type};
			$newparent = $record;
# print "<br>Found a $record->{type} in $parent->{type} and created a new record ";
			&json_associate($parent,$record);

		}

		my $jo;
		if ($jo = &json_objects($a)) {
			 print "Found a $jo <br>"
		}




		if (ref($a) eq "HASH") { $separator="<br>";($a,$counter) = &json_hash($newparent,$a,$counter,$jo); }
		elsif (ref($a) eq "ARRAY") { $separator="<br>";($a,$counter) = &json_array($newparent,$a,$counter,$jo); }
		else {
			print "Hmmm.... $a <p>";
		}
	}
	$arraystring = join($separator,@$arr);

	$counter--;
	return ("<br>".$tab.$arraystring."<br>",$counter);
}



sub json_hash {

	my ($parent,$hashin,$counter,$ji) = @_;
	$counter++;
	my $record = ""; my $newparent = $parent;
	my $tab = "&nbsp;&nbsp;&nbsp;"x$counter;
	my $hashstr = "";my $separator="=";

	if ($ji) {

		$record = gRSShopper::Record->new(tag => $ji,parent => $parent);
		$record->{feed_type} = $parent->{feed_type};
		$record->{tag} = $ji;
		$record->{type} = $ji;
		$newparent = $record;
# print "<br>Found a $record->{type} in $parent->{type}  and created a new record<br>";
		&json_associate($parent,$record);

	}

	while (my($j,$k) = each %$hashin) {


		$separator="=";
		my $jo = &json_objects($j);
		if (ref($hashin->{$j}) eq "HASH") { $separator="=<br>";($k,$counter) = &json_hash($newparent,$hashin->{$j},$counter,$jo); }
		elsif (ref($hashin->{$j}) eq "ARRAY") { $separator="=<br>";($k,$counter) = &json_array($newparent,$hashin->{$j},$counter,$jo); }
		else {
			my $prefix; if ($newparent->{type} eq "item") { $prefix = "link"; } else { $prefix = $newparent->{type}; }
			$newparent->{$prefix."_".$j} = $k;
#print ">> $j = $k <br>";
		}



		$hashstr .= "<br>$tab $newparent->{type} _ $j $separator $k <br>";


	}

	if ($newparent->{type} eq "item") {										# Facebook
		if ($newparent->{feed_type} =~ /facebook/i) {

			$parent->{link_title} = $newparent->{link_message};				# Title
			my @titarr = split /[,?\.]/,$newparent->{link_title};
			$newparent->{link_title} = $titarr[0];


			$newparent->{link_description} = $newparent->{link_message};		# Descrioption
			$newparent->{link_description} = substr( $newparent->{link_description}, 0, 255);

			$newparent->{link_content} = $newparent->{link_message};			# Content

			my ($usr,$postn) = split /_/,$newparent->{link_id};					# Link
#print "Linkdata $usr $postn <br>";
			$newparent->{link_link} = "https://www.facebook.com/$usr/posts/$postn";
#print "Link: $newparent->{link_link}  <p>";

		} else {
			$newparent->{link_link} = $newparent->{link_url};				# DOAJ
			$newparent->{link_description} = $newparent->{link_abstract};		# DOAJ
		}
	}


	$newparent->{link_id} = "";												# Don't pass on ID

	while (my ($a,$b) = each %$newparent) {              # %$
		# print "$a = $b <br>";
	}


	$counter--;

	return ($hashstr,$counter);

}





sub json_objects {

	my ($check,$parent) = @_;

#print "Checking objcets, $check  <br>";
	my $translate;
	if ($parent eq "doaj" ) {
		$translate = {
			'item' => 'bibjson',
			'author' => 'author',
			'feed' => 'journal',

		};

	} else {

		$translate = {
			'author' => 'from',
			'action' => 'actions',
			'application' => 'application',
			'privacy' => 'privacy',
			'likes' => 'likes',
			'shared' => 'shares',
			'comments' => 'comments',
		};
	}

	while ( my ($i,$j) = each %$translate) {

		if ($check eq $j) { return $i; }
	}

	return 0;

}


sub json_associate {

	my ($jparent,$jchild) = @_;
	if ($jchild->{type} eq "author") {
		push @{$jparent->{authors}},$jchild;
		# print "Adding $jchild->{type} to $jparent->{type} <p>";
	}
	elsif ($jchild->{type} eq "feed") {
		 push @{$jparent->{feeds}},$jchild;
		# print "Adding $jchild->{type} to $jparent->{type} <p>";
	 }
	elsif ($jchild->{type} eq "media") {
		push @{$jparent->{media}},$jchild;
		# print "Adding $jchild->{type} to $jparent->{type} <p>";
	}
	elsif ($jchild->{type} eq "item") {
		push @{$jparent->{items}},$jchild;
		# print "Adding $jchild->{type} to $jparent->{type} <p>";
	 }


}












1;
