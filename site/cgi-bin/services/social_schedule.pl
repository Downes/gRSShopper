# -------   Social Media Post Scheduling --------------------------------------------------
#
# Handles the scheduling and cron-driven publishing of social media posts (Mastodon, Bluesky,
# Twitter) whose record's pub date is in the future.
#
# Immediate publishing (pub date is today or in the past) still goes straight out via
# social_media_post(). A future pub date instead gets a row in the social_schedule table via
# schedule_social_post(), and cron_tasks() calls process_social_schedule() every minute to
# publish anything that's come due.
#
# Queue rule: the first post scheduled for a given date goes out at 9:00am (site timezone),
# and each post scheduled after it for the same date goes out an hour later, regardless of
# which service it's going to (Mastodon + Bluesky share one queue for the day).


# -------   Publish Now? --------------------------------------------------------------
#
# Given a post's pub date string (YYYY/MM/DD, as stored in eg. post_pub_date), decide
# whether it should be published immediately. No date set behaves the same as today.

sub should_publish_now {

	my ($pubdate) = @_;
	return 1 unless ($pubdate);

	my $today = &cal_date(time);
	return ($pubdate le $today) ? 1 : 0;
}


# -------   Social Media Post --------------------------------------------------------------
#
# Dispatches to the right service's *_post() function and records that the item was
# published so it isn't published twice. Reused by both the immediate-publish path in
# api_publish() and the cron-driven scheduled path below.
#
# Requires: $dbh, $table, $id, $service ("twitter"|"bluesky"|"mastodon")
# Returns: whatever the service's *_post() function returns (usually a URL)

sub social_media_post {

	my ($dbh,$table,$id,$service) = @_;

	my $col = $table."_social_media";
	my $published = &db_get_single_value($dbh,$table,$col,$id);
	my $result;

	if ($service =~ /twitter/i) { $result = &twitter_post($dbh,$table,$id); $published .= ",twitter"; }
	elsif ($service =~ /bluesky/i) { $result = &bluesky_post($dbh,$table,$id); $published .= ",bluesky"; }
	elsif ($service =~ /mastodon/i) { $result = &mastodon_post($dbh,$table,$id); $published .= ",mastodon"; }
	else { &status_error("social_media_post(): Unknown service '$service'"); }

	&db_update($dbh,$table,{$col => $published},$id);		# Prevent publishing twice

	return $result;
}


# -------   Ensure Social Schedule Table --------------------------------------------------------------
#
# Creates the social_schedule table on first use, and migrates older installs that predate
# the retry-count column.

our $SOCIAL_MAX_RETRIES = 3;		# After this many failed attempts, stop retrying and mark it an error
our $SOCIAL_RETRY_DELAY = 5 * 60;	# Retry a failed post 5 minutes later

sub ensure_social_schedule_table {

	my ($dbh) = @_;

	unless (&db_table_exist($dbh,"social_schedule")) {

		my $sql = qq|CREATE TABLE `social_schedule` (
  `social_schedule_id` int(11) NOT NULL auto_increment,
  `social_schedule_crdate` int(15) default NULL,
  `social_schedule_creator` int(15) default NULL,
  `social_schedule_table` varchar(50) default NULL,
  `social_schedule_recordid` int(11) default NULL,
  `social_schedule_service` varchar(50) default NULL,
  `social_schedule_pubdate` varchar(20) default NULL,
  `social_schedule_time` int(15) default NULL,
  `social_schedule_status` varchar(20) default NULL,
  `social_schedule_retries` int(3) default 0,
  `social_schedule_result` text,
  PRIMARY KEY (`social_schedule_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;|;

		$dbh->do($sql) or &log_cron(0,"Could not create social_schedule table: ".$dbh->errstr);
		return;
	}

	my ($col_exists) = $dbh->selectrow_array(qq|SHOW COLUMNS FROM social_schedule LIKE 'social_schedule_retries'|);
	unless ($col_exists) {
		$dbh->do(qq|ALTER TABLE social_schedule ADD COLUMN social_schedule_retries int(3) default 0|)
			or &log_cron(0,"Could not add social_schedule_retries column: ".$dbh->errstr);
	}
}


# -------   Schedule Social Post --------------------------------------------------------------
#
# Queues a post to go out later, at the next available hourly slot (starting 9:00am site time)
# on the given date's shared queue.
#
# Requires: $dbh, $table, $id, $service, $pubdate (YYYY/MM/DD)
# Returns: ($schedule_id, $scheduled_epoch)

sub schedule_social_post {

	my ($dbh,$table,$id,$service,$pubdate) = @_;

	&ensure_social_schedule_table($dbh);

	# If this same post already has a slot queued for this date (eg. Bluesky was
	# scheduled a moment ago and this call is now scheduling Mastodon for the same
	# post), reuse that time so every service chosen for one post goes out together
	# instead of each click claiming its own hourly slot.
	my $esth = $dbh->prepare(qq|SELECT social_schedule_time FROM social_schedule
		WHERE social_schedule_table = ? AND social_schedule_recordid = ? AND social_schedule_pubdate = ? LIMIT 1|);
	$esth->execute($table,$id,$pubdate);
	my ($scheduled_time) = $esth->fetchrow_array();
	$esth->finish;

	unless ($scheduled_time) {
		$scheduled_time = &next_social_slot_time($dbh,$pubdate);
	}

	my $sid = &db_insert($dbh,$query,"social_schedule",{
		social_schedule_table    => $table,
		social_schedule_recordid => $id,
		social_schedule_service  => lc($service),
		social_schedule_pubdate  => $pubdate,
		social_schedule_time     => $scheduled_time,
		social_schedule_status   => "pending",
		social_schedule_crdate   => time,
		social_schedule_creator  => $Person->{person_id},
	});

	return ($sid,$scheduled_time);
}


# -------   Next Social Slot Time --------------------------------------------------------------
#
# Given a date (YYYY/MM/DD), returns the epoch for the next open hourly slot in that date's
# shared queue (9:00am site time, plus one hour per distinct post already queued for that date).
# Shared by schedule_social_post() (new posts) and reschedule_social_posts_for_post() (moved posts).

sub next_social_slot_time {

	my ($dbh,$pubdate) = @_;

	my $csth = $dbh->prepare(qq|SELECT COUNT(DISTINCT CONCAT(social_schedule_table,':',social_schedule_recordid)) AS n
		FROM social_schedule WHERE social_schedule_pubdate = ?|);
	$csth->execute($pubdate);
	my ($slot) = $csth->fetchrow_array();
	$csth->finish;

	my ($y,$m,$d) = split /\//,$pubdate;
	use DateTime;
	my $dt = DateTime->new(
		year => $y, month => $m, day => $d,
		hour => 9, minute => 0, second => 0,
		time_zone => $Site->{st_timezone} || "America/Toronto",
	);
	$dt->add(hours => $slot);
	return $dt->epoch;
}


# -------   Reschedule Social Posts For Post --------------------------------------------------------------
#
# Called when a post's pub date changes (eg. from the schedule Rollup screen). Moves any still-
# pending social_schedule rows for that post to the new date, keeping all services for that post
# sharing one slot. Rows already posted/errored are left alone.
#
# Requires: $dbh, $table, $id, $new_pubdate (YYYY/MM/DD)

sub reschedule_social_posts_for_post {

	my ($dbh,$table,$id,$new_pubdate) = @_;

	return unless ($new_pubdate);
	return unless (&db_table_exist($dbh,"social_schedule"));

	my $sth = $dbh->prepare(qq|SELECT * FROM social_schedule
		WHERE social_schedule_table = ? AND social_schedule_recordid = ? AND social_schedule_status = 'pending'|);
	$sth->execute($table,$id);
	my @rows;
	while (my $row = $sth->fetchrow_hashref()) { push @rows,$row; }
	$sth->finish;

	return unless (@rows);

	my $new_time = &should_publish_now($new_pubdate) ? time : &next_social_slot_time($dbh,$new_pubdate);

	foreach my $row (@rows) {
		&db_update($dbh,"social_schedule",{
			social_schedule_pubdate => $new_pubdate,
			social_schedule_time    => $new_time,
		},$row->{social_schedule_id});
	}

	&log_cron(5,"Rescheduled ".scalar(@rows)." pending social post(s) for $table #$id to $new_pubdate");
}


# -------   Process One Scheduled Post --------------------------------------------------------------
#
# Attempts a single social_schedule row and updates its status. Reused by process_social_schedule()
# (the cron loop, for future-dated posts) and by api_publish() (the immediate-publish path, so a
# "publish now" click gets the same fork-isolation and retry behaviour as a scheduled post).
#
# The post is published in a forked child: the *_post() functions call status_error(), which exits,
# on any failure (missing credentials, service outage, etc) - forking keeps that exit() from killing
# the caller (cron run, or the CGI request itself) instead of just this one attempt.
#
# On failure, retries up to $SOCIAL_MAX_RETRIES times, $SOCIAL_RETRY_DELAY seconds apart, before
# giving up and marking the row 'error'.
#
# Requires: $dbh, $row (a social_schedule hashref, eg. from db_get_record or a SELECT *)
# Returns: 1 if this attempt succeeded, 0 otherwise (row may still be pending a retry)

sub process_one_scheduled_post {

	my ($dbh,$row) = @_;

	my $pid = fork();

	if (!defined $pid) {
		&log_cron(0,"Fork failed for social_schedule #$row->{social_schedule_id}: $!");
		&db_update($dbh,"social_schedule",
			{social_schedule_status=>"error",social_schedule_result=>"fork failed: $!"},$row->{social_schedule_id});
		return 0;
	}

	if ($pid == 0) {
		# Child - isolated so a status_error() exit() here can't take down the caller
		$dbh->{InactiveDestroy} = 1;		# Don't close the shared DB connection when this child exits
		my $result = &social_media_post($dbh,$row->{social_schedule_table},$row->{social_schedule_recordid},$row->{social_schedule_service});
		&db_update($dbh,"social_schedule",{social_schedule_result=>$result},$row->{social_schedule_id}) if ($result);
		exit 0;
	}

	waitpid($pid,0);

	# The child may have exited early via status_error(), so check the record itself
	# rather than trust a return value we never got.
	my $col = $row->{social_schedule_table}."_social_media";
	my $published = &db_get_single_value($dbh,$row->{social_schedule_table},$col,$row->{social_schedule_recordid});

	if ($published =~ /\Q$row->{social_schedule_service}\E/i) {
		&db_update($dbh,"social_schedule",{social_schedule_status=>"posted"},$row->{social_schedule_id});
		&log_cron(5,"Scheduled post #$row->{social_schedule_id} succeeded");
		return 1;
	}

	my $retries = ($row->{social_schedule_retries} || 0) + 1;

	if ($retries <= $SOCIAL_MAX_RETRIES) {
		&db_update($dbh,"social_schedule",{
			social_schedule_status  => "pending",
			social_schedule_time    => time + $SOCIAL_RETRY_DELAY,
			social_schedule_retries => $retries,
			social_schedule_result  => "Attempt $retries failed - retrying",
		},$row->{social_schedule_id});
		&log_cron(0,"Scheduled post #$row->{social_schedule_id} to $row->{social_schedule_service} failed (attempt $retries) - retrying in ".($SOCIAL_RETRY_DELAY/60)." min");
	} else {
		&db_update($dbh,"social_schedule",{
			social_schedule_status  => "error",
			social_schedule_retries => $retries,
			social_schedule_result  => "Failed after $retries attempts - see cron log",
		},$row->{social_schedule_id});
		&log_cron(0,"Scheduled post #$row->{social_schedule_id} to $row->{social_schedule_service} failed permanently after $retries attempts");
	}

	return 0;
}


# -------   Process Social Schedule --------------------------------------------------------------
#
# Called once per minute from cron_tasks(). Publishes anything whose scheduled time has come.

sub process_social_schedule {

	my ($dbh) = @_;
	return unless (&db_table_exist($dbh,"social_schedule"));

	my $now = time;
	my $sql = qq|SELECT * FROM social_schedule WHERE social_schedule_status = 'pending' AND social_schedule_time <= ? ORDER BY social_schedule_time ASC|;
	my $sth = $dbh->prepare($sql);
	$sth->execute($now) or &log_cron(0,"Social schedule query error: ".$dbh->errstr);

	my @due;
	while (my $row = $sth->fetchrow_hashref()) { push @due,$row; }
	$sth->finish;

	foreach my $row (@due) {

		&log_cron(5,sprintf("Posting scheduled %s #%s to %s (attempt %s)",
			$row->{social_schedule_table},$row->{social_schedule_recordid},$row->{social_schedule_service},($row->{social_schedule_retries}||0)+1));

		&process_one_scheduled_post($dbh,$row);
	}
}


# -------   Publish Immediately, With Retry --------------------------------------------------------------
#
# Used by api_publish() for the "pub date is today or in the past" case. Queues a social_schedule
# row for right now and attempts it immediately, so a failure gets the same fork-isolation and
# automatic 5-minute retry as a future-dated scheduled post, instead of just giving up.
#
# Requires: $dbh, $table, $id, $service, $pubdate (may be blank)
# Returns: ($success, $row) - $success is 1/0, $row is the resulting social_schedule hashref

sub publish_now_with_retry {

	my ($dbh,$table,$id,$service,$pubdate) = @_;

	&ensure_social_schedule_table($dbh);

	my $sid = &db_insert($dbh,$query,"social_schedule",{
		social_schedule_table    => $table,
		social_schedule_recordid => $id,
		social_schedule_service  => lc($service),
		social_schedule_pubdate  => $pubdate || &cal_date(time),
		social_schedule_time     => time,
		social_schedule_status   => "pending",
		social_schedule_crdate   => time,
		social_schedule_creator  => $Person->{person_id},
	});

	my $row = &db_get_record($dbh,"social_schedule",{social_schedule_id=>$sid});
	my $success = &process_one_scheduled_post($dbh,$row);
	my $final_row = &db_get_record($dbh,"social_schedule",{social_schedule_id=>$sid});

	return ($success,$final_row);
}

1;
