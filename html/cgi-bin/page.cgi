#!/usr/bin/perl
#print "Content-type: text/html\n\n";

#    gRSShopper 0.7  Page  0.7  -- gRSShopper administration module
#    26 April 2017 - Stephen Downes

# WORK IN PROGRESS 07 September 2020


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
#
#-------------------------------------------------------------------------------
#
#	    gRSShopper
#           Public Page Script
#
#-------------------------------------------------------------------------------



# Load CGI

	use CGI;
	use CGI::Carp qw(fatalsToBrowser);
	my $page_dir = "../";


# Load gRSShopper

	use File::Basename;
    #  use local::lib; # sets up a local lib at ~/perl5
	my $dirname = dirname(__FILE__);
	require $dirname . "/grsshopper.pl";

# Load modules

	our ($query,$vars) = &load_modules("page");


# Load Site
	
	our ($Site,$dbh) = &get_site("page");		

# Convert old-style requests
# (Allows API style requests of the form domain/table/id/action for most things
# and requests of the form domain/table/seach_term/q  )
	my $table = $vars->{db} || $vars->{table};
	if ($table) { $vars->{table} = $vars->{id};	}

# Detect Search Requests (ensures maximum flexibility in how to form these)
	if ($table eq "search") { $vars->{q} = $vars->{id}; }	
	if ($vars->{q} || $vars->{action} eq "q") { 
		$vars->{action} = "search"; 
		$vars->{table} ||= "post"; 
		$vars->{$vars->{table}} = $vars->{q};
	}

# Analyze Request --------------------------------------------------------------------
# Determine Request Table, ID number 
# ( assumes page.cgi?$table=$id )
	my $action = $vars->{action};
	my $id = $vars->{id};
	my @tables = &db_tables($dbh);
	foreach $table (@tables) {				# Scan the list of tables	
		if ($vars->{$table}) {				#     and if we've specified one	
			$id = $vars->{$table};			#	      get its ID, and
			if ($action) {				    # 		  Perform Action, or
				for ($action) {
					/rd/ && do { &redirect($dbh,$query,$table,$id); exit; 		};
					/search/ && do { &show_search($dbh,$query,$table); exit; 		};
					/list/ && do { &list_records($table,{}); exit;		};
				}
			} else {						# Show $table number $id			
				&show_page($dbh,$query,$table,$id,$vars->{format});
				exit;
			} 

		} 
		
	}	# No table? Default to home

	print "Content-type: text/html; charset=utf-8\n";
	print "Location:".$Site->{st_url}."\n\n";
	exit;
	


# Nothing below this line is operational, will be fixed

		if ((!$action || $action =~ /^list$/i || $action =~ /^rd$/i) && $vars->{$t}) {
			$table = $t;
			$id = $vars->{$t};
			$vars->{id} = $id;
			last;
		}
	


# Initialize User

	my ($session,$username) = &check_user();
	
		our $Person = {}; bless $Person;
	&get_person($Person,$username);
	my $person_id = $Person->{person_id};
	
	#print "Person title is: ".$Person->{person_title}." and status is ".$Person->{person_status}."<p>";
	# print &show_login($session);
	
	#if ($username) { print $username.qq| [<a href="//|.$ENV{'SERVER_NAME'}.$ENV{'SCRIPT_NAME'}.qq|?action=logout">Logout</a>]<p>|; }
	#else { $login_window; }




# Actions ------------------------------------------------------------------------------


if ($action) {						# Perform Action, or


	for ($action) {

		/rd/ && do { &redirect($dbh,$query,$table,$id); last; 	};
		/search/ && do { &search($dbh,$query); last; 	};
		/list/ && do { &list_records($table,{}); last;		};

		/meetings/ && do { &meetings($dbh,$query); last; 	};
		/join_meeting/ && do { &join_meeting($dbh,$query); last; 	};
		/moderate_meeting/ && do { &moderate_meeting($dbh,$query); last;	};

		/proxy/ && do { &proxy($dbh,$query); last; };

							# Go to Home Page
		if ($dbh) { $dbh->disconnect; }			# Close Database and Exit
		print "Content-type: text/html; charset=utf-8\n";
		print "Location:".$Site->{st_url}."\n\n";
		exit;

	}
}



if ($dbh) { $dbh->disconnect; }			# Close Database and Exit
exit;




#-------------------------------------------------------------------------------
#
#           Functions
#
#-------------------------------------------------------------------------------

# Responds to page request, displaying record of type table ($vars->{table})
# and #id ($vars->{id}) in a given $format ($vars->{format}) defined in the view named table_format
# The output_page() fundction is from grsshopper.pl

sub show_page {

  	my ($dbh,$query,$table,$id,$format) = @_;
  	$vars = $query->Vars;

	# Find page by title, if applicable
	unless (&db_locate($dbh,$table,{$table."_id"=>$id})) { 
		$id = &db_locate($dbh,$table,{$table."_title"=>$id});
	}

	# Determine Output Format  ( assumes admin.cgi?format=$format )

	if ($vars->{action} eq "list") { $format = "list"; }
	$format ||= "html";		# Default to HTML


	# Try to show the cached version
	my @tables = qw(post presentation page author feed link publication);
	foreach my $t (@tables) {
		if (($table eq $t) && $vars->{force} ne "yes" ) {

			&quick_show_page($page_dir,$table,$id,$format);

		}
	}

  print &output_record($dbh,$query,$table,$id,$format);

	&record_hit($table,$id);
  &record_was_read($table,$id);
	# Otherwise, generate the page with output_record()

}



sub record_hit($table,$id) {

	my ($table,$id) = @_;
return unless ($table eq "post");
	my $hits = &db_increment($dbh,$table,$id,"hits");		# Old school
	my $total = &db_increment($dbh,$table,$id,"total");		# Increment Hit Counter
	return ($hits,$total);							# Return new values

}

sub record_was_read($table,$id) {

	my ($table,$id) = @_;
  return unless ($table eq "link");
  return unless ($Person->{person_status} eq "admin");
  my $read = &db_update($dbh,$table,{$table."_read"=>1},$id);
	return $read;							# Return new values

}

sub api_counter {

	# Increment Counter
	my ($dbh,$query,$table,$id) = @_;
	my ($hits,$total) = &record_hit($table,$id);

	# Return New Values
	print "Content-type:text/html\n\n";
	print qq|document.write("Page counter $table $id - $hits today, $total total");|;

	exit;
}


sub redirect {

	my ($dbh,$query,$table,$id) = @_;

	# Increment Counter
	my ($dbh,$query,$table,$id) = @_;
	my ($hits,$total) = &record_hit($table,$id);

	my $linkfield = $table."_link";

	my $target = db_get_single_value($dbh,$table,$linkfield,$id);
	$target =~ s/&amp;/&/g;
	unless ($target) { $target = $Site->{st_url}.$table."/".$id; }

	print "Content-type:text/html\n";
	print "Location: $target\n\n";
	exit;
}






#-------------------------------------------------------------------------------
#
#           Menu Functions
#
#-------------------------------------------------------------------------------



#-------------------------------------------------------------------------------
#
# -------   List Records -------------------------------------------------------
#
#           List records of a certain type
#	      Edited: 27 March 2010
#-------------------------------------------------------------------------------

sub list_records {

	my ($table,$parms) = @_;
	my $vars = ();
	if (ref $query eq "CGI") { $vars = $query->Vars; }
	$vars->{force} = "yes";




						# Troubleshoot Input, normally commented out
#	print "Content-type: text/html; charset=utf-8\n\n";
#	while (my($lx,$ly) = each %$vars) { print "$lx = $ly <br>"; }


						# Output Format
	my $format = $table ."_list";

						# Print Page Header
	if ($vars->{format} =~ /html/i) {

		print "Content-type: text/html; charset=utf-8\n\n";
		print $Site->{header};
		print "<h3>List ".$table."s</h3>";
		if ($vars->{msg}) {
			print qq|<p class="notice">$vars->{msg}</p>|;
		}
	} elsif ($vars->{format} =~ /json/i) {
		print "Content-type: application/json; charset=utf-8\n\n";
		my $jsontitle = $table."s";
		print qq|{"$jsontitle":[\n|;
	}
						# Init SQL Parameters

	my $count; my $sort; my $start; my $number; my $limit;
	my $where = "WHERE ";

						# Admin Display

	if ($Person->{person_status} eq "admin") {
		$count = &db_count($dbh,$table);
		($sort,$start,$number,$limit) = &sort_start_number($query,$table);

						# User Display
	} else {
		my $owner = $Person->{person_id};
		my $owh = $table.qq|_creator='$owner'|;
		if ($table eq "thread") { $owh .= " OR thread_status='active'"; }
		$count = &db_count($dbh,$table,$owh);
		($sort,$start,$number,$limit) = &sort_start_number($query,$table);
 		$where .= $owh;
	}



						# Execute SQL search

	if ($where eq "WHERE ") { $where = ""; }
	my $stmt = qq|SELECT * FROM $table $where $sort $limit|;
#	print "SQL: $stmt <p>";
	my $sthl = $dbh->prepare($stmt);
	$sthl->execute();

						# Print Search Summary
	my $stname = "";
	if ($Person->{person_status}) { $stname = "everyone"; }
	else { $stname .= $Person->{person_name}; }
	my $status = "<p>Listing $start to ".($start+$number)." of $count ".$table."s belonging to $stname<br/>";
	$status .= "You are person number: $Person->{person_id} <script language=\"Javascript\">login_box();</script></p>";

	if ($vars->{format} =~ /html/) {
		print &pr_status($status);
		print "<p>\n";
	}
						# Process Records

	my $recordlist = "";
	while (my $list_record = $sthl -> fetchrow_hashref()) {

						# Troubleshoot Search (Normally commented out)

		#print "<hr>";
		#while (my($lx,$ly) = each %$list_record) {
		#	print "$lx = $ly <br>";
		#}

						# Determine Record format
		my $recformat ="";
		if ($vars->{type}) { $recformat = $vars->{table}."_".$vars->{type}."_".$vars->{format}; }
		else { $recformat = $vars->{table}."_".$vars->{format}; }







						# Format Record

		my $record_text = &format_record($dbh,
			$query,
			$table,
			$recformat,
			$list_record,1);

		&autodates(\$record_text);

						# Print Record
		$recordlist .= $record_text . "\n";

	}
	$recordlist =~ s/ *$//g;
	$recordlist =~ s/,$//g;		# Remove trailing comma from list

	print $recordlist;


	if ($vars->{format} =~ /html/) {
		print "</p>";

						# Print Page Footer
		print "<p>";
		print &next_button($query,$table,"list",$start,$number,$count);
		$sthl->finish( );
		print $Site->{footer};

		return 1;
	} elsif ($vars->{format} =~ /json/) {
		print " ]}\n";
	}
}

#

sub autopost {

	my ($dbh,$query) = @_;
	my $vars = $query->Vars;
	my $postid = &auto_post($dbh,$query,$vars->{id});
	print "Content-type: text/html\n";
	print "Location:$Site->{st_url}post/$postid\n\n";
	exit;

}
# -------   Output Record ------------------------------------------------------

sub show_search {

	my ($dbh,$query,$table) = @_;

	my $output = "<h2>Searching</h2>";
	my $search_dir = $Site->{st_urlf}."search/";

	print "Content-type: text/html; charset=utf-8\n\n";



	my $newq = $vars->{q};
	$newq =~ s/[^a-zA-Z0-9 -]//g; 



	$vars->{number}=20;
	my ($sort,$start,$number,$limit) = &sort_start_number($query,$table);
	my $searchtable = $table || "post"; exit "No search permitted" if ($searchtable =~ /person/);

	# Try to show the cached version
#	if ($vars->{force} ne "yes" ) {

			&quick_show_search($search_dir,$table,$newq,$start,"html");
#	}
	




	if ($searchtable eq "post") {
		$output .=  qq|<p>This page: <a href="$Site->{st_url}search/$newq">$Site->{st_url}search/$newq</a></p>|;
	} else {
		$output .=  qq|<p>This page: <a href="$Site->{st_url}search/$newq">$Site->{st_url}search/$searchtable/$newq</a></p>|;
	}

	my $keyword = qq|<keyword start=$start;db=$searchtable;sort=crdate DESC;number=$number;title,description~$vars->{q};truncate=500;format=search>|;
	my $results_count = &make_keywords($dbh,$query,\$keyword);




	$output .= $keyword;

	my $newstart = $vars->{start} + $vars->{number};

	unless ($results_count < $vars->{number}) {
		$output .=  qq|<p>[<a href="$Site->{st_cgi}page.cgi?start=$newstart&q=$newq">Next $vars->{number} results</a>]|;
	}

	$page->{page_content} =
		&db_get_template($dbh,"static_header",$record->{page_title}) . 
		$output .
		&db_get_template($dbh,"static_footer",$record->{page_title});
	

	&format_content($dbh,"","",$page);

	# save a cached version


	my $page_file = $search_dir.$table.".".$newq.".".$start.".html";
	
	unless (-d $search_dir) { mkdir($search_dir,0755); }
    binmode(STDOUT, ":utf8");
    open FILE, ">$page_file" or die "Cannot open $page_file: $!";
	print FILE $page->{page_content} or die "Print failure: $!";
	close FILE;

	print $page->{page_content};
	exit;

}






#---------------------  Input Vote  ----------------------------------

sub input_vote {

	my ($dbh,$query) = @_;
	my $sum = &update_vote($dbh,$query);
	$vars->{vote_table} ||= "post";

	print &output_record($dbh,$query,$vars->{vote_table},$vars->{vote_post},"html");

}

#




#
#
# -------   Print Status -------------------------------------------------------
#
#           Print output in a 'status' span
#	      Edited: 27 March 2010
#

sub pr_status {

	my ($msg) = @_;
	return qq|<span class="status">$msg</span>|;
}










#-------------------------------------------------------------------------------
#
# -------   Meetings --------------------------------------------------------
#
#           List BBB Meetings
#	      Edited: 16 September 2011
#
#-------------------------------------------------------------------------------



sub meetings {


	my ($dbh,$query) = @_;
	$vars = $query->Vars;


	print "Content-type: text/html; charset=utf-8\n\n";
	print $Site->{header};

	print "<h2>Live Meetings</h2>";

	my $meeting_con = &bbb_get_meetings();
	my $meetingcount = 0;

	$Person->{person_name} ||= $Person->{person_title};
	$content .= qq|<h4>Current Live Meetings</h4>
		<form method="post" action="$Site->{st_cgi}page.cgi">
		<p>These are the live meetings currently running ion $Site->{st_name}. If you would
		like to enter the confreencing environment and join the meeting, please provide a
		name and then select the meeting you would like to join.<br/><br/>

		Enter your name: <input size="40" type="text" name="username" value="$Person->{person_name}"></p>

		<input type="hidden" name="action" value="join_meeting">

		<ul><table cellpadding="5" cellspacing="0" border="0">|;

	while ($meeting_con =~ /<meeting>(.*?)<\/meeting>/g) {
		$meetingcount++; my $meeting = (); my @moderators;
		my $meet_data = $1; my $meeting_id; my $meeting_name; my $meeting_started;

		while ($meet_data =~ /<meetingName>(.*?)<\/meetingName>/g) { $meeting->{name} = $1; }
		next if ($meeting->{name} eq "Administrator Meeting");

		while ($meet_data =~ /<meetingID>(.*?)<\/meetingID>/g) { $meeting->{id} = $1; }
		$meeting->{info} = &bbb_getMeetingInfo($meeting->{id});

		while ($meeting->{info} =~ /<participantCount>(.*?)<\/participantCount>/g) { $meeting->{count} = $1; }
		while ($meeting->{info} =~ /<attendee>(.*?)<\/attendee>/g) {
			my $attendee = $1; my $a = ();
			while ($attendee =~ /<role>(.*?)<\/role>/g) { $a->{role} = $1; }
			while ($attendee =~ /<fullName>(.*?)<\/fullName>/g) { $a->{fn} = $1; }
			if ($a->{role} =~ /moderator/i) {
				if ($meeting->{mods}) { $meeting->{mods} .= ", "; }
				$meeting->{mods} .= $a->{fn};
			}
		}

		while ($meet_data =~ /<createTime>(.*?)<\/createTime>/g) { $meeting_started = $1; }
		$content .= qq|<tr><td align="right"><b>$meeting->{name}</b> - $meeting->{count} participant(s)<br/>
				Moderator(s): $meeting->{mods} </td>
				<td valign="top">
				<input type="submit" name="meeting_id"
				value="Join Meeting $meeting->{id}"></td></tr>|;
 # $content .= qq|<form><textarea cols="50" rows="10">$meet_data\n\n$meet_info</textarea></form><p>|;
	}
	$content .= "</table></ul></p></form>";
	if ($meetingcount ==0) {
		$content .= "<p><ul>There are currently no live meetings taking place.</ul></p>";
	}

	if ( ( $Person->{person_id} > 2  ) ||
		( $Person->{person_status} eq "admin" ) ) {
		my $newid = time;
		$content .= qq|<h4>Create and Join a Meeting</h4>
			<form method="post" action="$Site->{st_cgi}page.cgi">
			<p><ul>
			<input type="hidden" name="action" value="moderate_meeting">
			<table cellpadding="2" cellspacing="0" border="0">
			<tr><td align="right">Meeting Name:</td><td><input type="text" name="meeting_name" size="40"></td></tr>
			<tr><td align="right">Meeting Ident:</td><td><input type="text" name="meeting_id" value="$newid" size="40"></td></tr>
			<tr><td align="right" colspan="2"><input type="submit" value="Create Meeting and Join It"></td></tr>
			</table></ul></p></form>|;
	} else {

		$content .= "<p>If you are registered and logged in, you may create your
			own live meetings right here any time you want.</p>";
	}


	$content .= qq|<h4>Meeting System Help</h4>
		<p><ul><a href="http://www.bigbluebutton.org/sites/all/videos/join/index.html">
		<img src="http://bigbluebutton.org/sites/default/files/images/student_vid_0.png"
		alt="Video Student" title="Video Student" class="image image-_original "
		style="padding: 3px; border: 1px solid rgb(175, 175, 175); margin-top: -5px;"
		height="108" width="163"></a><br>
		Viewer Overview</strong> [3:35] How to use BigBlueButton as a viewer.<br/>
		<a href="http://www.bigbluebutton.org/sites/all/videos/join/index.html">Play Video</a></ul></p>|;

	print $content;

	print $Site->{footer};
	exit;


}

#-------------------------------------------------------------------------------
#
# -------   Join Meeting --------------------------------------------------------
#
#           Join BBB Meetings
#	      Edited: 16 September 2011
#
#-------------------------------------------------------------------------------

sub join_meeting {

	my ($dbh,$query) = @_;
	my $vars = $query->Vars;

	$vars->{meeting_id} =~ s/Join Meeting //;
	my $uname = $vars->{username} || $Person->{person_name};

#	unless ($vars->{meeting_name}) { $vars->{meeting_name} = "Administrator Meeting"; }
#	unless ($vars->{meeting_id}) { $vars->{meeting_id} = "12345"; }

	&bbb_join_meeting($vars->{meeting_id},$uname,$Person->{person_title});

	exit;



}

#-------------------------------------------------------------------------------
#
# -------   Moderate Meeting --------------------------------------------------------
#
#           Create BBB Meetings
#	      Edited: 17 September 2011
#
#-------------------------------------------------------------------------------
sub moderate_meeting {

	my ($dbh,$query) = @_;
	my $vars = $query->Vars;

	unless ($vars->{meeting_name}) { $vars->{meeting_name} = "Generic Meeting"; }

	unless ($vars->{meeting_id}) { $vars->{meeting_id} = "12345"; }


	&bbb_join_as_moderator($vars->{meeting_id},$Person->{person_name},$Person->{person_title});

	exit;



}

















1;

	





exit;
