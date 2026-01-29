#    gRSShopper 0.7  Harvest URL  0.83  --  March 2, 2018
#    /cgi-bin/harvest/harvest_url.pl

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


# -------   Harvest URL ------------------------------------------------------



# -------   Harvest URL ------------------------------------------------------
#
#
sub harvest_url {

	my ($url) = @_;

	&diag(2,qq|<div class="function">Harvest URL<div class="info">|);
	&diag(2,qq|Feed ID: $feedid; \n\n|);

	my $feedrecord = gRSShopper::Feed->new({dbh=>$dbh});
	$feedrecord->{feed_link} = $url;
	&get_url($feedrecord);
	&harvest_process_data($feedrecord);
	&diag(2,qq|</div></div>\n\n|);
}
