#    gRSShopper 0.7  Harvest Facebook  0.83  --  March 2, 2018
#    /cgi-bin/harvest/harvest_facebook.pl

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


# -------   Harvest Facebook ------------------------------------------------------


# -------   Harvest Facebook ------------------------------------------------------

sub harvest_facebook {

	my ($feedrecord) = @_;			# data is stored in $feedrecord->{processed};
						# and processed in &save_records()
	print "Content-type: text/html\n\n";

	unless ($Site->{fb_app_secret} && $Site->{fb_app_id} && $Site->{fb_postback_url}) {
		print "facebook harvest is not supported."; exit; }
	use Net::Facebook::Oauth2;

	my $fbp = &facebook_session();

	my $fbp = Net::Facebook::Oauth2->new(
		application_secret     	=> $Site->{fb_app_secret} ,
		application_id          => $Site->{fb_app_id},
		callback          	=> $Site->{fb_postback_url},
		access_token		=> $Site->{fb_token}
	);


        print "<p>Page: $feedrecord->{feed_link}</p>";

                my $info = $fbp->get($feedrecord->{feed_link} );

  #      print $info->as_json;
        $feedrecord->{feedstring} = $info->as_json;
       	&harvest_process_data($feedrecord);
        exit;
}
