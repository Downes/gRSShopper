#!/usr/bin/perl

#    gRSShopper 0.7  Page  0.7  -- gRSShopper submit form
#    11 October 2018 - Stephen Downes

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
#
#-------------------------------------------------------------------------------
#
#	    gRSShopper
#           Submit Script
#
#-------------------------------------------------------------------------------



# Load CGI

	use CGI;
	use CGI::Carp qw(fatalsToBrowser);
	my $query = new CGI;
	my $vars = $query->Vars;
	my $page_dir = "../";


# Load gRSShopper

	use File::Basename;
      use local::lib; # sets up a local lib at ~/perl5
	my $dirname = dirname(__FILE__);
	require $dirname . "/grsshopper.pl";

# Load modules

	our ($query,$vars) = &load_modules("page");


# Load Site

	our ($Site,$dbh) = &get_site("page");
	if ($vars->{context} eq "cron") { $Site->{context} = "cron"; }

# Get Person  (still need to make this an object)

	our $Person = {}; bless $Person;
	&get_person($dbh,$query,$Person);
	my $person_id = $Person->{person_id};

# Initialize system variables

	my $options = {}; bless $options;
	our $cache = {}; bless $cache;


  my $action = $vars->{action};
  my $table = "feed";    # For now
  my $id = "new";  # This script creates records, but doesn't edit records




# Determine Output Format  ( assumes admin.cgi?format=$format )

if ($vars->{format}) { 	$format = $vars->{format};  }
if ($action eq "list") { $format = "list"; }
$format ||= "html";		# Default to HTML


unless ($table && $action) {				# Print Form

	print "Content-type: text/html; charset=utf-8\n\n";
  print qq|
     <form action="submit.cgi" method="post">
     <input type="hidden" name="table" value="feed">
     <input type="hidden" name="feed_id" value="new">
     Please enter your blog or feed information below:<br>
     <input type=text size=80 name="feed_title" placeholder="Feed or blog Title"><br>
     <input type=text size=80 name="feed_html" placeholder="Feed or blog Web Page"><br>
     <input type=text size=80 name="feed_link" placeholder="Feed or blog RSS/Atom/JSON feed link"><br>
     <input type=text size=80 name="feed_author" placeholder="Your Name"><br>
     <input type="submit" name="action" value="Submit">
     </form>|;
	exit;
}





# Actions ------------------------------------------------------------------------------


if ($action) {						# Perform Action, or


	for ($action) {

		/Submit/ && do {
	   	print "Content-type: text/html; charset=utf-8\n\n";
      unless ($vars->{feed_title}) { &missing_message("title"); }
      unless ($vars->{feed_html}) { &missing_message("html"); }
      unless ($vars->{feed_link}) { &missing_message("link"); }
      if (&db_locate($dbh,"feed",{feed_title => $vars->{feed_title}})) { &exists_message("title"); }
			if (&db_locate($dbh,"feed",{feed_html => $vars->{feed_html}})) { &exists_message("url"); }
			if (&db_locate($dbh,"feed",{feed_link => $vars->{feed_link}})) { &exists_message("link"); }
      if ($vars->{feed_link} =~ /twitter\.com/i) { &noneed_message("twitter"); }

			# Test the feed link
      unless (($vars->{feed_link} =~ /^http:\/\//i) or ($vars->{feed_link} =~ /^https:\/\//i)) {
					$vars->{feed_link} = "http://".$vars->{feed_link};
			}
      print "Testing ".$vars->{feed_link}." ... ";
			my $ua = LWP::UserAgent->new( );
			  $ua->agent("gRSShopper"); # give it time, it'll get there
        my $response = $ua->get($vars->{feed_link});
			  if ($response->is_error( )) {
			    printf "I'm so sorry, but it failed: %s <br>\n", $response->status_line;
					print &back_button();
					exit;
			  } else {
			    my $content = $response->content( );
			    my $bytes = length $content;
			    my $count = ($content =~ tr/\n/\n/);
			    printf "Found: %d lines, %d bytes <br>\n", $count, $bytes;
			  }


      $vars->{feed_status} = "O";
			my $id = &form_update_submit_data($dbh,$query,$table,$id);
      if ($id) { print "Thank you, your $table has been submitted.<br>"}
      else { print "Sorry, I tried to save your feed but I failed.<br>"}
      exit;

    	};


							# Go to Home Page
		if ($dbh) { $dbh->disconnect; }			# Close Database and Exit
		print "Content-type: text/html; charset=utf-8\n";
		print "Location:".$Site->{st_url}."\n\n";
		exit;

	}
}



if ($dbh) { $dbh->disconnect; }			# Close Database and Exit
print "Content-type: text/html; charset=utf-8\n";
print "Location:".$Site->{st_url}."\n\n";

exit;

sub missing_message {

  my ($item) = @_;
  my $feeds_url = $Site->{st_cgi}.qq|page.cgi?page=Course Feeds&force=yes|;
	print "You need to provide a $item for your feed.<br>";
  print &back_button();
	exit;

}

sub exists_message {

  my ($item) = @_;
  my $feeds_url = $Site->{st_cgi}.qq|page.cgi?page=Course Feeds&force=yes|;
	print "This feed $item already exists.<br>";
  print qq|Please check the <a href="$feeds_url">Course Feeds</a>. If you do not see your feed,
		please contact the <a href="mailto:|.$Site->{st_pub}.qq|">site administrator</a>.<br>|;

	exit;

}

sub noneed_message {

  my ($item) = @_;
  my $feeds_url = $Site->{st_cgi}.qq|page.cgi?page=Course Feeds&force=yes|;
	print "You do not need to privide a Twitter feed; this site already searches through Twitter for the ".
		$Site->{st_tag}." hashtag.<br>";

	exit;

}

sub back_button {

  return qq|
		 <button onclick="goBack()">Go Back</button>
		 <script>
		 function goBack() {
				 window.history.back();
		 }
		 </script>
  |;

}

1;
