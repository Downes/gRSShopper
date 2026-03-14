	sub admin_newsletters {

		my ($dbh,$query) = @_;

		return unless (&is_viewable("admin","newsletter")); 		# Permissions
		$Site->{admin_pane}	= "newsletters";
		my $adminlink = $Site->{st_cgi}."admin.cgi";


		my $content = qq|<h1>Newsletters</h1><div class="menubox">Each newsletter is composed of a page and a list of subscribers.
			Edit pages at left, and to turn any page into a newsletter, set 'Autopub' to 'yes' and seelcting
			the 'MailGun' or 'email' page type (note that 'email' requires /usr/bin/sendmail, which is not available
			in gRSShopper Docker containers). Newsletter contents are typically created automatically; the page is republished
			before being sent, ensuring that the most fresh possible version is sent. Provide users with a subscription 
			interface at <a href="|.$Site->{st_cgi}.qq|api.cgi?cmd=subform">|.$Site->{st_cgi}.qq|api.cgi?cmd=subform</a>
			(or embed in an iframe anywhere). Subscription lists may be
			managed locally or by the external email provider; unsubscribe links must be placed at the bottom
			of any mailing list page. Send the email either to yourself (to test) or to the full list.</div>|;

		$content .= qq|<div class="menubox">
			<h3>Verify Email Addresses</h3><p>
			This might take a while. Not working at the moment for MailGun
			[<a href="|.$Site->{st_cgi}.qq|admin.cgi?action=verify_email">Click here</a>]</p></div>
		|;

		# Get list of eligible newsletters with sent/unsent subscriber counts
		my $npageoptionlist = "<option>Select a newsletter</option>\n";
		my $stmt = qq|SELECT * FROM page WHERE page_sub='yes'|;
		my $sthl = $dbh->prepare($stmt);
		$sthl->execute();
		my @newsletters;
		while (my $s = $sthl->fetchrow_hashref()) {
			push @newsletters, $s;
			$npageoptionlist .= qq|<option value="$s->{page_id}">$s->{page_title}</option>\n|;
		}

		# Create options for recipients
		my $npagerecipientlist = qq|
			<select name="send_list">
			<option value="on">Select an action</option>
			<option value="admin">To Yourself Only</option>
			<option value="subscribers">To All Subscribers</option>
			<option value="resend">Resend (skip already sent)</option>
			</select>

		|;

		# Build per-newsletter subscriber stats table
		my $stats_rows = '';
		for my $nl (@newsletters) {
			my ($sent, $unsent) = $dbh->selectrow_array(qq|
				SELECT
					COUNT(CASE WHEN subscriber_lastsent IS NOT NULL THEN 1 END),
					COUNT(CASE WHEN subscriber_lastsent IS NULL THEN 1 END)
				FROM subscriber
				WHERE subscriber_list = ? AND subscriber_status = 'active'
			|, undef, $nl->{page_id});
			my $total = ($sent || 0) + ($unsent || 0);
			$stats_rows .= qq|<tr><td>$nl->{page_title}</td><td>$total</td>|
				. qq|<td>$sent</td><td>$unsent</td></tr>\n|;
		}
		my $stats_table = $stats_rows ? qq|
			<table border="1" cellpadding="4" style="margin-top:0.5em;border-collapse:collapse">
			<tr><th>Newsletter</th><th>Total</th><th>Sent</th><th>Not yet sent</th></tr>
			$stats_rows
			</table>| : '';


		$content .= qq|
			<div class="menubox"><h3>Send Newsletter</h3>
			<form method="post" action="$Site->{st_cgi}admin.cgi">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">
			<input type="hidden" name="action" value="send_nl">
			<input type="hidden" name="verbose" value="1">

			<div style="display:inline;margin:1em;">Page:
			<select name="page_id">$npageoptionlist</select>
			</div>

			<div style="display:inline;margin:1em;">Recipients:
			$npagerecipientlist
			</div>

			<div style="display:inline;margin:1em;">
			<input type="submit" value="Send Newsletter" class="button">
			</div>

			</form>
			$stats_table
			</div>
		|;

		$content .= qq|


			<div class="menubox"><h3>Manage Newsletter</h3>
			<b>Post Issue Rollup</b><br/>
			Posts in newsletters can be scheduled for publication ahead of time; see the
			'Edit Post' screen for more. This button will show you the list of posts scheduled
			for upcoiming newsletters.<br>
			<form method="post" action="$adminlink">
			<input type="hidden" name="action" value="rollup">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<input type="submit" value="Rollup" class="button">
			</form>
			</div><br/>



			<div class="menubox"><h3>Manage Subscriptions</h3>
			<b>Autosubscribe</b><br/>
			<form method="post" action="$adminlink">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<select name="action">
			<option>Select an action</option>
			<option value="autosub">Autosubscribe All</option>
			<option value="autounsub">Unsubscribe All</option>
			</select>
			to
			<select name="newsletter">
			$npageoptionlist
			</select>
			<input type="submit" value="Do It" class="button">
			</form>
			</div><br/>

		|;

		$content .= &admin_configtable($dbh,$query,"Email Program and Addresses",
			("Mail Program Location:em_smtp","System Email:em_from",
			"Discussion Email:em_discussion","Copyto Email:em_copy","Def:em_def"));

		&admin_frame($dbh,$query,"Admin General",$content);					# Print Output
		exit;



	}

	# -----------------------------------   Admin: Verify Emails   -----------------------------------------------
	#
	#   Cycles through all the email addresses in the person table
	#   Verifies each in turn (note: this can take a while)
	#   Sets a verified/not verified flad in the person
	#
	# ------------------------------------------------------------------------------------------------------

	sub admin_verify_emails {
	return 1;
	#	use Email::Verify::SMTP;
	  $|++;

		my $sth = $dbh -> prepare("SELECT * FROM person"); $sth -> execute();



		while (my $p = $sth -> fetchrow_hashref()) {
			print $p->{person_id}." (".$p->{person_title}."): ";
			if ($p->{person_email}) {
				  print $p->{person_email}."(".$p->{person_eformat}.")<br>";
					# Find out if, and why not (if not):
					my ($is_valid, $msg) = verify_email($p->{person_email});
					if( $is_valid ) {
									print "email is valid<br>";
									&db_update($dbh,"person",{person_eformat=>"valid"},$p->{person_id});
						# Email is valid:
					}
					else {
						# Email is *not* valid:
						print "Email is bad: $msg <br>";
						&db_update($dbh,"person",{person_eformat=>$msg},$p->{person_id});
					}


			}
	  }

		exit;

		# This is important:
		$Email::Verify::SMTP::FROM = 'verifier@downes.ca';

		# Just a true/false:
		if( verify_email('stephen@downes.ca') ) {
			print "email is valid<p>";
			# Email is valid
		}

		# Find out if, and why not (if not):
		my ($is_valid, $msg) = verify_email('stephensm@knox.nsw.edu.au');
		if( $is_valid ) {
						print "email is valid<p>";
			# Email is valid:
		}
		else {
			# Email is *not* valid:
			print "Email is bad: $msg";
		}



	}

	# -----------------------------------   Admin: Database   -----------------------------------------------
	#
	#   Initialization and editing site databases
	#
	# ------------------------------------------------------------------------------------------------------

	sub news_rollup {
		my ($dbh,$query) = @_;
		my $vars = $query->Vars;

		print $Site->{header};
		print "<h1>Content for Today & Future Issues</h1>";

		# Get Data for Today and Future Issues
		my $date = &cal_date(time - (3600*24));	# ie., yesterday
		my $issues = ();
		my $stmt = qq|SELECT * FROM post where post_pub_date >?|;
		my $sthl = $dbh->prepare($stmt);
		$sthl->execute($date);
		my $count = 0;
		while (my $post = $sthl -> fetchrow_hashref()) {
			my $text = qq|<a href="?post=$post->{post_id}">$post->{post_title}</a>
				[<a href="?action=edit&post=$post->{post_id}">Edit</a>]|;
			push @{$issues->{$post->{post_pub_date}}},$text;
			$count++; last if ($count>1000);
		}

		# Sort and Display Content
		my @index = sort keys %$issues;
		foreach my $iss (@index) {
			print "<p><b>ISSUE: $iss</b><br>\n";
			foreach my $pp (@{$issues->{$iss}}) {
				print "- $pp <br/>\n";
			}
			print "</p>\n";
		}
		print $Site->{footer};
		exit;
	}


	# -------   Autosubscribe All ----------------------------------------------------------
	#
	#	Autosubscribes all users to given newsletter
	#

	sub autosubscribe_all {



		my ($dbh,$query) = @_;
		my $vars = $query->Vars;

		print $Site->{header};
		print "<h2>Autosubscribe</h2>";
		my $page = $vars->{newsletter};
		my $stmt = qq|SELECT person_id FROM person|;
		my $pers = $dbh->selectcol_arrayref($stmt);

		# Delete Previous Subscriptions
		&save_subscriptions($dbh,$query);
		my $stmt2 = qq|DELETE FROM subscription WHERE subscription_box=?|;
		my $sth = $dbh->prepare($stmt2);
	    	$sth->execute($page);

		print "Subscribe to $page <p>";
		my $crdate = time;
		foreach my $person(@$pers) {
			&db_insert($dbh,$query,"subscription",{subscription_box => $page,
									   subscription_person => $person,
									   subscription_crdate => $crdate});


			print "$person subscribed OK<br>";

		}
		print $Site->{footer};
	exit;

	}



	# -------   Autosubscribe All ----------------------------------------------------------
	#
	#	Autosubscribes all users to given newsletter
	#

	sub autounsubscribe_all {

		my ($dbh,$query,$page,$return) = @_;
		my $vars = $query->Vars;

		unless ($return) {

			print $Site->{header};
			print "<h2>Autosubscribe</h2>";
		}
		$page ||= $vars->{newsletter};
		my $stmt = qq|SELECT person_id FROM person|;
		my $pers = $dbh->selectcol_arrayref($stmt);

		# Delete Previous Subscriptions
		&save_subscriptions($dbh,$query,$page);
		my $stmt2 = qq|DELETE FROM subscription WHERE subscription_box=?|;
		my $sth = $dbh->prepare($stmt2);
	    	$sth->execute($page);

		print "<p>All users unsubscribed from page number $page </p>";
		my $crdate = time;

		unless ($return) {
			print $Site->{footer};
			exit;
		}
		return;
	}

	sub save_subscriptions {

		my ($dbh,$query,$page) = @_;
		my $savefile = $Site->{data_dir}.$Site->{db_name}."_page_".$page."_subscriptions_".time;
		open OUT,">$savefile" or
			&error("$dbh","","","Save subscriptions: Cannot open $savefile: $!");
		my $stmt = qq|SELECT * FROM subscription|;
		my $sthl = $dbh->prepare($stmt);
		$sthl->execute();
		while (my $s = $sthl -> fetchrow_hashref()) {
			print OUT $s->{subscription_box}."\t".$s->{subscription_person}."\t".$s->{subscription_crdate}."\n"
			 or
			&error("$dbh","","","Save subscriptions: Cannot write to $savefile: $!");

		}
		print "<p>Backup of subscriptions saved to $savefile </p>";
		close OUT;
	}


	# -------   List Records -------------------------------------------------------
	#
	# List records of a certain type
	#

	sub send_nl {
	  $|++; # Stream output
		my ($dbh,$query,$page_id,$send_list,$verbose) = @_;
		my $vars = $query->Vars;

		my $report;

		# return unless (&is_allowed("send","newsletter"));	# Admin Only

		$page_id ||= $vars->{page_id};				# ID of page to send
		$send_list ||= $vars->{send_list};			# Send to admin or subscribers
		$verbose ||= $vars->{verbose};				# Silent (0) (for cron) or verbose (1)
		my $date = &nice_date(time);
		my $today = &day_today;


		# Publish page and get newsletter page data
		my $record = &db_get_record($dbh,"page",{page_id=>$page_id});
		my ($pgcontent,$pgtitle,$pgformat,$pgarchive,$keyword_count) 
			= &publish_page($dbh,$query,$page_id,0);

		$pgtitle .= " ~ $date";

		# I don't think mailchimp is working at the moment
		if ($record->{page_type} eq "mailchimp")	{	# send to mailchimp list

			if ($send_list =~ /admin/i) { $send_list = $Site->{mailchimp_test}; }
			else { $send_list = $record->{page_subsend}; }
			my $result = &send_mailchimp_email($pgcontent,$pgtitle,$send_list);
		}
		elsif ($record->{page_type} eq "mailgun")	{	# send to mailgun list
			my $listid;
			if ($send_list =~ /admin/i) { $listid = $Person->{person_email} || $Site->{st_email}; }  # Test
			else { $listid = $record->{page_listid} || $record->{page_title}; }                      # Send
			print "Sending $pgtitle to list $listid \n";
			my $result = &send_mailgun_email($pgcontent,$pgtitle,$listid);
		}
		elsif ($record->{page_type} eq "ses") {		# send via Amazon SES to subscriber table
			my $since;
			if ($send_list eq 'resend') {
				# Find when the most recent send batch started — skip anyone sent at or after that time
				($since) = $dbh->selectrow_array(qq|
					SELECT MIN(subscriber_lastsent) FROM subscriber
					WHERE subscriber_list = ? AND subscriber_lastsent IS NOT NULL
				|, undef, $page_id);
				print "Resending $pgtitle via SES (skipping already sent since " . localtime($since) . ") \n" if $since;
				print "Resending $pgtitle via SES (no previous sends recorded) \n" unless $since;
			} else {
				print "Sending $pgtitle via SES \n";
			}
			my $count = &ses_send_newsletter($pgcontent, $pgtitle, $page_id, $send_list, $since);

			# Trigger LinkedIn publisher (fire-and-forget) after a real send
			if ($count > 0 && $send_list !~ /admin/i && $Site->{li_publisher_url}) {
				eval {
					use LWP::UserAgent;
					my $ua = LWP::UserAgent->new(timeout => 5);
					$ua->post($Site->{li_publisher_url},
						[ token => $Site->{li_publisher_token} || '' ]);
				};
				# Ignore errors — LinkedIn publishing must never block the newsletter send
			}

			my $cmg = ($count == 1) ? "1 newsletter sent." : "$count newsletters sent.";
			print "<hr><p>$cmg</p>" if ($verbose);
			$report .= "Report for page $page_id: $pgtitle <br>\n$cmg.\n\n";
			if ($dbh) { $dbh->disconnect; }
			&send_email('stephen@downes.ca',$Site->{st_pub},"Send Report - $pgtitle",$report,'htm');
			return $report;
		} else {						# send to email subscription list


		}

		print qq|
			  <h2>Send Newsletter</h2>
				<p>Page $page_id:  $pgtitle <br>
				<br>Service: |.$record->{page_type}.qq|<br>
			  Today is $today, $date.</p>
		| if ($verbose);

		

									# Do not send empty newsletters
	#	unless ($keyword_count) {

	#		&send_email("stephen\@downes.ca","stephen\@downes.ca","Failed content",
	#			"No new content in $page_id; no newsletter sent.".$content.$status);
	#		if ($verbose) { print "<p>No new content for $page_id $pgtitle; no newsletter sent.</p>"; print $Site->{footer}; }
	#		$report .= "No new content in $page_id ; no newsletter sent. \n\n";
	#		return;
	#	}


		# Get subscriber List
		my @subscribers = &graph_list("page",$page_id,"person","subscribe");


									# Loop through subscriber list

		my $count = 0;

		foreach my $subscriber (@subscribers) {

			# Get subscriber data
			my $subdata = &db_get_record($dbh,"person",{person_id=>$subscriber});
			if ($send_list eq "admin") { next unless ($subdata->{person_status} eq "admin"); }
			next unless ($subdata->{person_eformat} eq "valid");
			# print $subscriber." ".$subdata->{person_email}." (".$subdata->{person_eformat}.")<br>" if ($verbose);
			print $subdata->{person_email}."\n" if ($verbose);
	    $count++;
	next;
	    # Customize Newsletter
			my $customcontent = $pgcontent;
			$customcontent =~ s/SUBSCRIBER/$subdata->{person_email}/sg;				# Customize
			$customcontent =~ s/PERSON/$subdata->{person_id}/sg;
			$customcontent =~ s/SUBSCRIBER/$subscriber/sg;

	    # Send Newsletter
			&send_email($subdata->{person_email},$Site->{st_pub},$pgtitle,$customcontent,$pgformat);

		}

		my $cmg = "$count newsletters sent.";
		if ($count == 1) { $cmg = "1 newsletter sent."; }
		if ($verbose) {	print "<hr><p>$cmg newsletter sent.</p>";	}


		$report .= "Report for page $page_id:  $pgtitle <br>\n$cmg.\n\n";
		if ($dbh) { $dbh->disconnect; }		# Close Database and Exit

		&send_email('stephen@downes.ca',$Site->{st_pub},"Send Report - $pgtitle",$report,'htm');

		return $report;

	}

	
	# -------   Admin Report -------------------------------------------------------

	sub admin_report {

		my ($dbh,$query,$count) = @_;
		my $vars = $query->Vars;
		my $ndate = &nice_date(time);

		my $subject - "Statistics for $ndate from $Site->{st_name}";
		$subject .= &nice_date(time);

		my $tag = $Site->{st_tag};
		$tag =~ s/#//;


		my ($oc,$op,$of,$ol,$ot,$om);
		open FSAVEIN,$Site->{cgif}."data/".$Site->{st_name}."_fsave.txt";
		while (<FSAVEIN>) {
			chomp;
			($oc,$op,$of,$ol,$ot,$om) = split "\t",$_;
			last;
		}
		close FSAVEIN;


		my $subCount = $dbh->selectrow_array(qq{SELECT count(*) FROM subscription},undef);
		my $personCount = $dbh->selectrow_array(qq{SELECT count(*) FROM person},undef);
		my $feedCount = $dbh->selectrow_array(qq{SELECT count(*) FROM feed},undef);

		my $lsql = qq|SELECT count(*) FROM link WHERE (link_title REGEXP '$tag' OR link_description REGEXP '$tag' OR link_category REGEXP '$tag') AND link_type = 'text/html'|;
		my $linkCount = $dbh->selectrow_array($lsql);

		my $tsql = qq|SELECT count(*) FROM link WHERE link_type = 'twitter'|;
		my $twitterCount = $dbh->selectrow_array($tsql);

		my $msql = qq|SELECT count(*) FROM link WHERE link_type = 'moodle'|;
		my $moodleCount = $dbh->selectrow_array($msql);

		my $msql = qq|SELECT count(*) FROM link WHERE link_type = 'diigo'|;
		my $diigoCount = $dbh->selectrow_array($msql);


		&log_status($dbh,$query,"General Stats","headers:Subscriptions,Persons,Feeds,Blog Posts,Twitter,Moodle,Diigo");
		&log_status($dbh,$query,"General Stats","$subCount,$personCount,$feedCount,$linkCount,$twitterCount,$moodleCount,$diigoCount");


		my $content = qq|Statistics for $ndate from $Site->{st_name}:\n|;
		$content .= "Subscriptions: Total: $count ; Since last: ".($count - $oc)."\n";
		$content .= "Persons:  Total: $personCount  ; Since last: ".($personCount - $op)."\n";
		$content .= "Feeds:  Total: $feedCount  ; Since last: ".($feedCount - $of)."\n";
		$content .= "Blog Posts  Total: $linkCount ; Since last: ".($linkCount - $ol)." \n";
		$content .= "Twitter: Total:  $twitterCount  ; Since last: ".($twitterCount - $ot)."\n";
		$content .= "Moodle:  Total: $moodleCount ; Since last: ".($moodleCount - $om)." \n";

		my $sql = qq|SELECT person_email FROM person WHERE person_status='admin'|;


		my $ary_ref = $dbh->selectcol_arrayref($sql);
		foreach my $admin (@$ary_ref) {
			next unless $admin =~ /downes/i;
			&send_email($admin,$Site->{em_from},$subject,$content,"html");

		}



	}





	# -------  Rotate Hit Counters -----------------------------------------------------------

	sub rotate_hit_counters {

		my ($dbh,$query,$table) = @_;


		# Set default variables for current table
		my $hitsfield = $table."_hits";
		my $idfield = $table."_id";
		my $message_text = "Hits record for today for $Site->{st_name}.<p><p>\n";

		# For each record with a hit today
		my $sql = "SELECT $idfield,$hitsfield FROM $table WHERE $hitsfield > 0";
		$message_text .= $sql;

		my $sth = $dbh->prepare($sql);
		$sth->execute();
		while (my $record = $sth -> fetchrow_hashref()) {


			# Reset Daily Hits to 0
			$message_text .= "Record $record->{$idfield} found $record->{$hitsfield} and reset $hitsfield to 0  <br>\n";
			my $usql = "UPDATE $table SET $hitsfield = ? WHERE $idfield = ?";
			my $usth = $dbh->prepare($usql);
			$usth->execute("0",$record->{$idfield});

		}

		$message_text .= "<br>Done";
		#&send_email("stephen\@downes.ca","stephen\@downes.ca","Rotating Hits Counter",
		#	$message_text);

		return;

	}


	# -------  Format Content -----------------------------------------------------------

1;
