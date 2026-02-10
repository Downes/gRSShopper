
sub log_event {
	return;
}
sub log_status {

	my ($dbh,$query,$logfile,$message) = @_;

	my $ltime = time;
	my $lcreator = $Person->{person_id} || 1;

						# Configure log entry
	my $lvals = {
		log_crdate =>$ltime,
		log_creator => $lcreator,
		log_title => $logfile,
		log_entry => $message
	};

	if ($message =~ /headers:/) {		# Add headers if they aren't already there, or
		return if (&db_locate($dbh,"log",{log_title=>$logfile,log_entry=>$message}));
	}

						# Add log entry
	&db_insert($dbh,$query,"log",$lvals);

}

# -------  Cron Log -------------------------------------------------------
#
# Cron log is a simple text file, with newest entries at the top. It is written to by the cron process, and can be viewed by admins. It is not intended to be a general log of all events, but rather a log of cron activity and errors. It is intended to be simple and lightweight, and to be easily viewable by admins without needing to access the server directly.
#

sub log_cron {

    my ($level,$log) = @_;

    return unless ($level <= $Site->{st_log_level});

    my $MAX_LINES     = 20000;  # trigger point
    my $REWRITE_LINES = 15000;  # keep this many (most recent)

    return unless ($Site->{context} eq "cron");
    my $entry = sprintf("%s ", $Site->{context});

    # Get the time
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my @wdays = qw|Sunday Monday Tuesday Wednesday Thursday Friday Saturday|;
    my $weekday = @wdays[$wday];
    $mon++;
    if ($min < 10)  { $min  = "0".$min; }
    if ($mday < 10) { $mday = "0".$mday; }
    my $logtime="$mon/$mday $hour:$min ";
    $entry .= "$logtime $log\n";

    # Define Cron Log Location
    my $cronfile = &get_cookie_base("b");
    $cronfile =~ s/\./_/g;
    my $cronlog = $Site->{data_dir} . $cronfile. "_cron.log";

    # Read existing log (if any), then write newest at top
    my @lines;
    if (-e $cronlog) {
        open my $fh, '<', $cronlog or die "Error opening Cron Logfile\n $cronlog: $!";
        @lines = <$fh>;
        close $fh;
    }

    unshift @lines, $entry;  # newest first

    # If too big, keep only the most recent REWRITE_LINES (top of file)
    if (@lines >= $MAX_LINES) {
        $#lines = $REWRITE_LINES - 1 if @lines > $REWRITE_LINES;
    }

    # Rewrite file
    open my $out, '>', $cronlog or die "Error opening Cron Logfile\n $cronlog: $!";
    print $out @lines or die "Error printing Cron Log $cronlog : $! \nLog: $log";
    close $out;

    return 1;
}


sub log_view {
	my ($dbh,$query,$logfile,$format) = @_;
print "Logview<br>";

						# Table View Defaults
	my $vars = $query->Vars;
	$logfile ||= $vars->{logfile};
	$format ||= $vars->{format};
	my $border = $vars->{border} || 1;
	my $padding = $vars->{padding} || 3;
	my $spacing = $vars->{spacing} || 0;

	# print "Retrieving $logfile <br>";
	if ($logfile eq "cronlog") {
		my $cronfile = &get_cookie_base("d");
		$cronfile =~ s/\./_/g;
		my $cronlog = $Site->{data_dir} . $cronfile. "_cron.log";
		unless (-e $cronlog) { $cronlog = $Site->{data_dir} . "localhost_cron.log"; }
		if ($vars->{format} eq "tail") {
			open my $pipe, "-|", "/usr/bin/tail", "-f", $cronlog
				or die "could not start tail on SampleLog.log: $!";
			print while <$pipe>;
		}
		print "Opening $cronlog <br><br>";
		open CRONLOG,"$cronlog" or &error($dbh,"","","Error opening cron log: $!");
		while (<CRONLOG>) { print $_ . "<br>"; }
		close CRONLOG;
		exit;
	}




						# Retrieve Log
	my $lsql = qq|SELECT * FROM log WHERE log_title=?|;
	my $lsth = $dbh -> prepare($lsql);
	$lsth -> execute($logfile);

						# Process Data
	my $lcount; my $headers; my $body;
	while (my $logrow = $lsth -> fetchrow_hashref()) {
		my $line = $logrow->{log_entry};
		if ($line =~ /headers:/) { $line =~ s/headers:/headers:date,/; }
		else {
			my $d = $logrow->{log_crdate};
			$d = &nice_date($d,"min");
			$d =~ s/,//g;
			$line = $d.",".$line; }
		if ($format eq "table") {
			$line =~ s|,|</td><td>|mig;
			$line = "<tr><td>".$line."</td></tr>";
		} elsif ($format eq "tsv") {
			$line =~ s|,|\t|g;
		}
		$line .= "\n";
		if ($line =~ /headers:/) {
			$line =~ s|headers:||;
			$headers = $line;
		} else {
			$body .= $line;
		}
	}
	$lsth->finish();
						# Print Output

	if ($format eq "table") { print qq|<table border="$border" cellspacing="$spacing" cellpadding="$padding">|; }
	#print $headers;
	print $body;
	if ($format eq "table") { print "</table>"; }
	exit;
}
sub log_reset {

	my ($dbh,$query,$logfile) = @_;
	$logfile ||= $vars->{logfile};
	return unless ($logfile);
	my $sth = $dbh->prepare("DELETE FROM log WHERE log_title = ?");
	$sth->execute($logfile);
	print "Content-type:text/html\n\n";
	print "Log $logfile wiped clean<br>";
	exit;

}
sub show_status_message {

	my ($dbh,$query,$person,$msg,$supl) = @_;

    my $vars = ();
    if (ref $query eq "CGI") { $vars = $query->Vars; } else { return; }

	return if ($vars->{mode} eq "silent");

	print "Content-type: text/html; charset=utf-8\n\n";
	$Site->{header} =~ s/\Q[*Login Required\E*]/Login Required/g;
	print $Site->{header};
	print "<h2>Login Required</h2>";
	print "<p>$msg</p>";
	print $Site->{footer};
  #	my $adr = 'stephen@downes.ca';

  #	&send_email($adr,$adr,
  #		"Error on Website",
  #		"Error message: $msg\nSupplementary:$supl\n\n");




	exit if ($dbh eq "nil");

	if ($dbh) { $dbh->disconnect; }
	exit;
}

	# -------  Conditional print -------------------------------------------------------
sub diag {

	# $diag_level set at top

	my ($score,$output) = @_;

	if ($score <= $Site->{diag_level}) {
#		print $output;
	}

	return;
}


1;
