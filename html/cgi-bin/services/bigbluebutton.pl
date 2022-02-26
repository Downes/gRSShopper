
# -------   Big Blue Button ---------------------------------------------------------

sub bbb {

  # "BBB Name:bbb_name","BBB URL:bbb_url","BBB Salt:bbb_salt"

	my ($url,$salt,$cmd,$qs) = @_;

	my $suburl = $cmd . $qs . $salt;
	my $checksum = sha1_hex($suburl);
	my $gourl = $Site->{bbb_url}.$cmd."?".$qs."&checksum=".$checksum;
	return $gourl;
}
sub bbb_create {

	my ($name,$id,$mp,$ap) = @_;

	$name =~ s/ /+/g; $id =~ s/ /+/g;
	unless ($name) { $name = $id; }
	my $qs = "name=$name&meetingID=$id&moderatorPW=$mp&attendeePW=$ap";
	my $cmd = "create";
	my $suburl = $cmd . $qs . $Site->{bbb_salt};
	my $checksum = sha1_hex($suburl);
	my $gourl = $Site->{bbb_url}.$cmd."?".$qs."&checksum=".$checksum;
	return $gourl;
}
sub bbb_joinmod {

	my ($meetingid,$username,$userid,$mp) = @_;

	&error($dbh,"","","Need a name to join a meeting") unless ($username || $userid);
	unless ($username) { $username = $userid; }
	unless ($userid) { $userid = $username; }
	$username =~ s/ /+/g;
	$userid =~ s/ /+/g;

	my $qs = "meetingID=$meetingid&password=$mp&fullName=$username&userID=$userid";
	my $cmd = "join";
	my $suburl = $cmd . $qs . $Site->{bbb_salt};
	my $checksum = sha1_hex($suburl);
	my $gourl = $Site->{bbb_url}.$cmd."?".$qs."&checksum=".$checksum;
	return $gourl;


}
sub bbb_create_meeting {

	my ($name,$id



	) = @_;
  #print "Content-type: text/html\n\n";
  #print "Smod password $Site->{bbb_mp} <p>";
	$name =~ s/ /+/g; $id =~ s/ /+/g;
	$name =~ s/&#39;//ig; $id =~ s/&#39;//ig;
	unless ($name) { $name = $id; }

	my $qs = "name=$name&meetingID=$id&maxParticipants=-1&moderatorPW=$Site->{bbb_mp}&attendeePW=$Site->{bbb_ap}";
	if ($vars->{record_meeting} eq "on") { $qs .= "record=true"; }
	my $cmd = "create";
	my $suburl = $cmd . $qs . $Site->{bbb_salt};
	my $checksum = sha1_hex($suburl);
	my $gourl = $Site->{bbb_url}.$cmd."?".$qs."&checksum=".$checksum;

	my $content = get($gourl);
	&error($dbh,"","","Couldn't Create Meeting with $gourl") unless defined $content;
  #print qq|<form><textarea cols=50 rows=10>$content</textarea></form><p>|;
  #exit;
	my $status;
	if ($content =~ /<returncode>FAILED<\/returncode>/) { $status = "failed"; }
	elsif ($content =~ /<returncode>SUCCESS<\/returncode>/) { $status = "success"; }
	else { $status = "unknown"; }
}
sub bbb_getMeetingInfo {

	my ($meetingid) = @_;
  #print "Content-type: text/html\n\n";
	$meetingid =~ s/ /+/g;
	my $qs = "meetingID=$meetingid&password=$Site->{bbb_mp}";
	my $cmd = "getMeetingInfo";
	my $suburl = $cmd . $qs . $Site->{bbb_salt};
	my $checksum = sha1_hex($suburl);
	my $gourl = $Site->{bbb_url}.$cmd."?".$qs."&checksum=".$checksum;
  #print "$gourl <p>";
	my $content = get($gourl);

  #print qq|<form><teaxarea cols="50" rows="10">$content</textarea></form>|;
  #print "Done";
  #exit;
	&error($dbh,"","","Couldn't get Meeting info from $gourl") unless defined $content;

	return $content;



}
sub bbb_getMeetingStatus {

	my ($meetingid,$req) = @_;

	my $content = bbb_getMeetingInfo($meetingid);
	my $status;
	if ($content =~ /<returncode>FAILED<\/returncode>/) { $status = "failed"; }
	elsif ($content =~ /<returncode>SUCCESS<\/returncode>/) { $status = "success"; }
	else { $status = "unknown"; }
	return $status;
}
sub bbb_get_meetings {

	my $random = "1234567890";
	my $qs = "random=$random";
	my $cmd = "getMeetings";
	my $suburl = $cmd . $qs . $Site->{bbb_salt};
	my $checksum = sha1_hex($suburl);
	my $gourl = $Site->{bbb_url}.$cmd."?".$qs."&checksum=".$checksum;

	my $content = get($gourl);
	return "Couldn't get Meetings info from $gourl" unless defined $content;
	return $content;


}
sub bbb_join_as_moderator {

  # print "Content-type: text/html\n\n";
	my ($meetingid,$username,$userid) = @_;
	&error($dbh,"","","Must specify meeting ID to join as moderator<p>") unless ($meetingid);
	&error($dbh,"","","Need a name to join a meeting") unless ($username || $userid);

	unless ($username) { $username = $userid; }
	unless ($userid) { $userid = $username; }
	$username =~ s/ /+/g; $userid =~ s/ /+/g; $meetingid =~ s/ /+/g;


	# Get Meeting Information
	my $status = &bbb_getMeetingStatus($meetingid);
	if ($status eq "failed") {
		$vars->{meeting_name} = "Generic Meeting" unless ($vars->{meeting_name});
		$vars->{meeting_name} =~ s/&#39;//ig; $meetingid =~ s/&#39;//ig;
		$status = &bbb_create_meeting($vars->{meeting_name},$meetingid);
		if ($status eq "failed") {
			&error($dbh,"","","Tried to create meeting but it failed.<p>$content");
		}
	}

		# Join the Meeting

	$qs = "meetingID=$meetingid&password=$Site->{bbb_mp}&fullName=$username&userID=$userid";
	$cmd = "join";
	$suburl = $cmd . $qs . $Site->{bbb_salt};
	$checksum = sha1_hex($suburl);
	$gourl = $Site->{bbb_url}.$cmd."?".$qs."&checksum=".$checksum;
	print "Content-type:text/html\n";
	print "Location:".$gourl."\n\n";
  #	print "<br> $suburl <p>";


}
sub bbb_join_meeting {

  # print "Content-type: text/html\n\n";
	my ($meetingid,$username,$userid) = @_;
	&error($dbh,"","","Must specify meeting ID to join meeting<p>") unless ($meetingid);
	&error($dbh,"","","Need a name to join a meeting") unless ($username || $userid);

	unless ($username) { $username = $userid; }
	unless ($userid) { $userid = $username; }
	$username =~ s/ /+/g; $userid =~ s/ /+/g; $meetingid =~ s/ /+/g;


		# Join the Meeting

	$qs = "meetingID=$meetingid&password=$Site->{bbb_ap}&fullName=$username&userID=$userid";
	$cmd = "join";
	$suburl = $cmd . $qs . $Site->{bbb_salt};
	$checksum = sha1_hex($suburl);
	$gourl = $Site->{bbb_url}.$cmd."?".$qs."&checksum=".$checksum;
	print "Content-type:text/html\n";
	print "Location:".$gourl."\n\n";
  #	print "<br> $suburl <p>";


}


1;
