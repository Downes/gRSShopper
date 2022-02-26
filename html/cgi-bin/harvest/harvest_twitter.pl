#    gRSShopper 0.7  Harvest Twitter  0.83  --  March 2, 2018
#    /cgi-bin/harvest/harvest_twitter.pl

#    Copyright (C) <2013>  <Stephen Downes, National Research Council Canada>
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


# -------   Harvest Twitter ------------------------------------------------------

sub harvest_twitter {

	my ($feedrecord) = @_;			# data is stored in $feedrecord->{processed};
						# and processed in &save_records()

	print "Content-type: text/html\n\n";

 # print "Harvesting Twitter<p>"; 										# Access Account

	&error($dbh,"","","Twitter posting requires values for consumer key, consumer secret, token and token secret")
		unless ($Site->{tw_cckey} && $Site->{tw_csecret} && $Site->{tw_token} && $Site->{tw_tsecret});

	my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
		consumer_key        => $Site->{tw_cckey},
		consumer_secret     => $Site->{tw_csecret},
		access_token        => $Site->{tw_token},
		access_token_secret => $Site->{tw_tsecret},
		ssl                 => 1,  ## enable SSL! ##
	);


	my $r = $nt->search($feedrecord->{feed_link});

	while (my($rx,$ry) = each %$r) {
		if ($rx eq "search_metadata") {
#			while (my($mrx,$mry) = each %$ry) { print "$mrx = $mry <br>"; }
		}

		elsif ($rx eq "statuses") {
			foreach my $status (@$ry) {
				next if ($status->{text} =~ /^RT/);			# Skip retweets (the bane of twitter)
				next if ($status->{user}->{screen_name} =~ /wxMONCTON/);	#  @wxMONCTON:
				my $item;my $userstr = "";
	#			print "<hr>";
				while (my($srx,$sry) = each %$status) {                    # %$

#					print "$srx = $sry <br>";
					if ($srx eq "user") {


#						print "User info:-------------<br>";
						while (my($ssrx,$ssry) = each %$sry) {                 #  %$
#							print "$ssrx = $ssry <br>";
						}
#						print "-----------------<br>";
#						print "Name: $sry->{name} <br>";
#						print "Screen Name: $sry->{screen_name} <br>";
						$item->{screen_name} = $sry->{screen_name};
						$item->{name} = $sry->{name};
						$item->{profile_image_url_https} = $sry->{profile_image_url_https};
#						print qq|<br>|;
					}

				}
				my ($created,$garbage) = split / \+/,$status->{created_at};
				$status->{text} =~ s/\x{201c}/ /g;	# "
				$status->{text} =~ s/\x{201d}/ /g;	# "
				$item->{link_link} = "https://twitter.com/".$item->{screen_name}."/status/".$status->{id};
				$item->{link_title} = $status->{text};
				$status->{text} =~ s/#(.*?)( |:)/<a href="https:\/\/twitter.com\/search?q=%23$1&src=hash">#$1<\/a> /g;
				$status->{text} =~ s/http:(.*?)("|”|$| )/<a href="http:$1">http:$1<\/a> /g;                   # "
				$status->{text} =~ s/\@(.*?)( |:)/<a href="https:\/\/twitter.com\/$1">\@$1<\/a> /g;
				$item->{link_description} = qq|<div class="tweet" style="clear:both;">
					<img src="$item->{profile_image_url_https}" align="left" hspace="10">
					<a href="$item->{link_link}">\@|.$item->{screen_name}.qq|</a>: |.
					$status->{text} . " ($created)</div>";

#				print $item->{link_description} . "<p>";
				push @{$feedrecord->{processed}->{items}},$item;


			}
	#		&save_item($feed,$item);
		}
	}
	foreach my $its (@{$feedrecord->{processed}->{items}}) {

		print $its->{link_description} . "<p>";
	}
	unless ($analyze eq "on") { &save_records($feedrecord); }
  print "Allz done<p>";
	exit;
}


1;
