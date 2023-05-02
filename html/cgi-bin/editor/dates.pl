

#           DATES
#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	#
	# -------   AutoTimezones ---------------------------------------------------
	#
	# 		Inserts dates into string
	#           Defaults to system timezone
	#           But will defer to query variable 'timezone'
	#
	#-------------------------------------------------------------------------------

sub autotimezones {
	my ($query,$text_ptr) = @_;
    	my $vars = ();
    	if (ref $query eq "CGI") { $vars = $query->Vars; }

	$$text_ptr =~ s/&#60time(.*?)&#62/<time$1>/g;  # Restore formatting command
	while ($$text_ptr =~ /<timezone epoch="(.*?)">/sg) {
		my $epoch = $1; my $tz = $vars->{timezone};
		my $replace;
		if ($epoch+0 > 0) { $replace = &tz_date($epoch,"min",$tz); }
		else { $replace = "Non epoch: ".$epoch; }
		my $original = qq|<timezone epoch="|.$epoch.qq|">|;
		$$text_ptr =~ s/$original/$replace/sig;
	}

	while ($$text_ptr =~ /<timezonedropdown>/sg) {
		my $db; my $id;
		if ($vars->{page}) { $vars->{db} = "page"; $vars->{id} = $vars->{page}; }
		if ($vars->{event}) { $vars->{db} = "event"; $vars->{id} = $vars->{page}; }
		my $ctz = $vars->{timezone} || $Site->{st_timezone};
		my $replace = qq|<p><form method="post" action="?">
			<input type="hidden" name="db" value="$vars->{db}">
			<input type="hidden" name="id" value="$vars->{id}">

			Time Zone:
		|;
		$replace .= &tzdropdown($query,$ctz);
		$replace .= qq|<input type="submit" value="Select time zone">
			</form></p>|;

		$$text_ptr =~ s/<timezonedropdown>/$replace/sig;
	}

}

	#-------------------------------------------------------------------------------
	#
	# -------   TZ Dropdown ---------------------------------------------------
	#
	#		Creates a select dropdown to select time zone
	#
	#-------------------------------------------------------------------------------
sub tzdropdown {

	my ($query,$ctz) = @_;
	unless (&new_module_load($query,"DateTime::TimeZone")) {
		return "DateTime::TimeZone module not available in sub tzdropdown";
	}

	my @TZlist = DateTime::TimeZone->all_names;
	my $replace = qq|<select name="timezone">\n|;
	foreach $tzl (@TZlist) {
		my $sel=""; if ($ctz eq $tzl) { $sel = " selected"; }
		$replace .= qq|<option value="$tzl"$sel>$tzl</option>\n|;
	}
	$replace .= "</select>\n";
	return $replace;

}


	#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	#
	# -------   AutoDates ---------------------------------------------------
	#
	# 		Inserts dates into string
	# 		Provide text pointer
	#		Format: <date_type>time<END_date_type>
	#
	#		Supported:
	#		<NICE_DATE>		Nice date string
	#		<MON_DATE>		Nice date string, month only
	#           <822_DATE>		RFC 822 Date
	#		<GMT_DATE>		GMT Date
	#
	#		I'd like to fix this for nicer syntax
	#		and include other date types
	#-------------------------------------------------------------------------------
sub autodates {
	my ($text_ptr) = @_;


	$$text_ptr =~ s/&#60;date (.*?)&#62;/<date $1>/g;  # Restore formatting command

	while ($$text_ptr =~ /<date (.*?)>/sg) {

		my $autocontent = $1; my $replace = "date not found";
		&escape_hatch();
		my $script = {}; &parse_keystring($script,$autocontent);

		my $time = $script->{time} || $script->{date} || time;					# Date / time from record (in epoch format)
		if (lc($time) eq "now") { $time = time; }
		my $tz = $script->{timezone} || $Site->{st_timezone};			# Allows input to specify timezone

		if ($script->{input} eq "date") {												# Convert input-style date to epoch (for eg. post_pub_date)
			my ($y,$m,$d) = split /\//,$time;   # 2018/11/14
			use DateTime;
			my $dt = DateTime->new( year => $y, month => $m, day => $d, time_zone => $tz );
			$time  = $dt->epoch;
    	}

		elsif ($script->{input} eq "datetime") {
			my ($dt,$t) = split / /,$time;												# Convert input-style date-time to epoch (for eg. post_pub_date)
			my ($y,$m,$d) = split /\//,$dt;   # 2018/11/14
			my ($hh,$mm,$ss) = split /:/,$t;   
			unless ($ss) { $ss = "00"; }  # 12:01:01 or #12:01
			use DateTime;
			my $dt = DateTime->new( year => $y, month => $m, day => $d, hour => $hh, minute => $mm, second => $ss,time_zone => $tz );
			$time  = $dt->epoch;
    	}

		my $format = $script->{format} || "nice";				# Format


		if ($format eq "nice") { $replace = &nice_date($time,"day",$tz);	}
		elsif ($format eq "niceh") { $replace = &nice_date($time,"min",$tz);	}
		elsif ($format eq "time") { $replace = &epoch_to_time($time,"min",$tz); }
		elsif ($format eq "rfc822") { $replace = &epoch_to_rfc822($time,"min",$tz); }
		elsif ($format eq "tzdate") { $replace = &tz_date($time,"day",$tz); }
		elsif ($format eq "datepicker") { $replace = &tz_date($time,"min",$tz); }
		elsif ($format eq "iso") { $replace = &iso_date($time,"day",$tz); }
		elsif ($format eq "ics") { $replace = &ics_date($time,$tz); }
		elsif ($format eq "isoh") { $replace = &iso_date($time,"min",$tz); }
		else { $replace = "Autodates error"; }


		$$text_ptr =~ s/<date $autocontent>/$replace/sg
	}







	for my $date_type ("NICE_DATE","NICE_DT","822_DATE","MON_DATE","GMT_DATE","YEAR") {

		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		$year = $year+1900;
	
		$$text_ptr =~ s/&#60;$date_type&#62;/<$date_type>/g;  # Restore formatting command


		if ($date_type =~ /YEAR/i) { $$text_ptr =~ s/<YEAR>/$year/ig; next;}
		elsif ($date_type =~ /NOW/i) { my $replace = &nice_date(time); $$text_ptr =~ s/<NOW>/$replace/ig; next;}


		my $date_type_end = "END_".$date_type;
		while ($$text_ptr =~ /<$date_type>(.*?)<$date_type_end>/sg) {
			my $autotext = $1; my $otime; my $replace;
			$otime = $autotext;
			if ($date_type =~ /822/) {
				$replace = &rfc822_date($otime);
			} elsif ($date_type =~ /GMT_DATE/) {
				$replace = &nice_date($otime,"GMT");
			}	elsif ($date_type =~ /ICS_DATE/) {
					$replace = &ics_date($otime,"GMT");
			} elsif ($date_type =~ /MON/) {
				$replace = &nice_date($otime,"month");
			} elsif ($date_type =~ /NICE_DT/) {
				$replace = &nice_dt($otime,"month");
			} else {
				$replace = &nice_date($otime);
			}
			$$text_ptr =~ s/<$date_type>\Q$autotext\E<$date_type_end>/$replace/sig;
		}
	}

}

	#-------------------------------------------------------------------------------
	#
	# -------   Locale Date ---------------------------------------------------
	#
	# 		Returns a date string based on the specified locale
	#		Edited: 18 Feb 2014
	#		Author: Luc Belliveau <luc.belliveau@nrc-cnrc.gc.ca>
	#		Requires: system that supports locales (and POSIX)
	#-------------------------------------------------------------------------------
	#-------------------------------------------------------------------------------
	#
	# -------   ISO Date ---------------------------------------------------
	#
	# 		ISO format string supported is either YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS
	#
	#	      Edited: 21 Jun 2014
	#-------------------------------------------------------------------------------
sub iso_date {



	my ($time,$h,$tz) = @_;

	my $dt = &set_dt($time,$tz);

	my ($year,$month,$day,$dow,$hour,$minute,$second) = &dt_to_array($dt);

	if ($h eq "min") { return $year."-".$month."-".$day."T".$hour.":".$minute.":00"; }

	return $dt->year."-".$dt->month."-".$dt->day;

}
# -------   ICS Date ---------------------------------------------------
#
# 		ICS format string string returns YYYYMMDDTHHMMSS
#
#	      Edited: 21 Sep 2018
#-------------------------------------------------------------------------------
sub ics_date {



my ($time,$tz) = @_;

my $dt = &set_dt($time,$tz);

my ($year,$month,$day,$dow,$hour,$minute,$second) = &dt_to_array($dt);

return $year.$month.$day."T".$hour.$minute."00";

}

	#-------------------------------------------------------------------------------
	#
	# -------   Nice Date ---------------------------------------------------
	#
	# 		Returns a nice date string given the time
	#	      Edited: 29 Jul 2010
	#-------------------------------------------------------------------------------
sub nice_date {

	# Get date from input
	my ($time,$h,$tz) = @_; my $date;
	unless (defined $h) { $h = "day"; }
	unless (defined $time) { $time = time; }

	my $dt = &set_dt($time,$tz);

	# return locale_date($current, "%e %b %Y", "fr_CA");

	my ($year,$month,$day,$dow,$hour,$minute,$second) = &dt_to_array($dt);
	my @months = &month_array();
	my @days = &day_array();



	if ($h eq "month") {							# April, 1959
		return "$months[$month], $year";
	} elsif ($h eq "day" ) {						# April 6, 1959
		return "$months[$month] $day, $year";
	} else {								# April 6, 1959 3:12 p.m.

		$date = "$months[$month] $day, $year";
		my $midi;
		if ($hour > 11) { $midi = "p.m."; }
		else { $midi = "a.m."; }
		if ($hour > 12) { $hour = $hour - 12; }
		if ($hour == 0) { $hour = 12; $midi = "a.m."; }

		return "$months[$month] $day, $year $hour:$minute $midi";
	}

}

	# -------   Nice Date ---------------------------------------------------
	#
	# 		Returns a nice date string with the exact time given the time
	#	      Edited: 29 Jul 2010
	#-------------------------------------------------------------------------------
sub nice_dt {

	# Get date from input
	my ($current) = @_;
	return &nice_date($current,"hour");



}
	#-------------------------------------------------------------------------------
	#
	# -------   RFC 822 Date ---------------------------------------------------
	#
	# 		Returns an rfc822 date string given the time
	#	      Edited: 29 Jul 2010
	#-------------------------------------------------------------------------------
sub rfc822_date {

	# Get date from input
	my ($time,$h,$tz) = @_;

	my $dt = &set_dt($time,$tz);
	my ($year,$month,$day,$dow,$hour,$minute,$second) = &dt_to_array($dt);
	my @months = &month_array();
	my @days = &day_array();
	unless ($minute) { $minute="00"; }
	unless ($second) { $second="00"; }
	return "$days[$dow], $day $months[$month] $year $hour:$minute:$second -0400";
}

	#-------------------------------------------------------------------------------
	#
	# -------   Calendar Date ---------------------------------------------------
	#
	# 		Returns an cal date string given the time Format: year/month/day
	# 		Used to match input from date-picker
	#	      Edited: 29 Jul 2010
	#-------------------------------------------------------------------------------
sub cal_date {

	my ($time,$h,$tz) = @_;

	my $dt = &set_dt($time,$tz);

	my ($year,$month,$day,$dow,$hour,$minute,$second) = &dt_to_array($dt);

	if ($h eq "min") { return $year."/".$month."/".$day." ".$hour.":".$minute; }

	return $year."/".$month."/".$day;
}

	#-------------------------------------------------------------------------------
	#
	# -------   TZ Date ---------------------------------------------------
	#
	# 		Returns a date string given the epoch date, a time zone,
	#           and optional formatting parameter
	#           Do not cache tz date, run immediately before print
	#
	#	      Edited: 24 April 2011
	#-------------------------------------------------------------------------------
sub tz_date {

	# Get date from input
	my ($time,$h,$tz) = @_;

	my $dt = &set_dt($time,$tz);
	my ($year,$month,$day,$dow,$hour,$minute,$second) = &dt_to_array($dt);
	my @months = &month_array();
	my @weekdays = &day_array();

	if ($h eq "min") {
		return "$year/$month/$day $hour:$minute";
	} elsif ($h eq "day") {
		return "$year/$month/$day";
	} else {
		return "$hour:$minute, $weekdays[$dow], $day $months[$month] $year ";
	}
}

	#-------------------------------------------------------------------------------

	# -------   set_dt -------------------------------------------------------
sub set_dt {


	my ($time,$tz) = @_;

	# Fail silently and return text if text sent instead of epoch
	unless ($time =~ /^[0-9]+$/) { return; }




	unless (&new_module_load($query,"DateTime")) {
		return "DateTime module not available in sub set_dt";
	}

	my $dt = DateTime->from_epoch( epoch => $time );				# Convert to DateTime
	my $tz = $tz || $Site->{st_timezone} || "America/Toronto";					# Allows input to specify timezone
	unless (DateTime::TimeZone->is_valid_name($tz)) {
		print "Content-type: text/html\n\n"; print "Invalid time zone in set_dt(): $tz <p>"; return; }
	if ($tz) { $dt->set_time_zone($tz); }

	return $dt;

}

	# -------   $dt to array  ---------------------------------------------------
sub dt_to_array {

	my ($dt) = @_;
	unless (defined $dt) {
		$Site->{warn} .= "dt_to_array received no input <br>\n";
      	return;
	}

	my $year   = $dt->year;

	my $month  = $dt->month;       # 1-12
	if ($month < 10) { $month = "0".$month; }

	$day    = $dt->day;            # 1-31
	if ($day < 10) { $day = "0".$day; }

	$dow    = $dt->day_of_week;    # 1-7 (Monday is 1)

	$hour   = $dt->hour;           # 0-23
	if ($hour < 10) { $hour = "0".$hour; }

  	$minute = $dt->minute;         # 0-59
	if ($minute < 10) { $minute = "0".$minute; }

	return ($year,$month,$day,$dow,$hour,$minute,$second);
}
sub month_array {

	return 	("",&printlang("Jan"),&printlang("Feb"),&printlang("Mar"),&printlang("Apr"),
		&printlang("May"),&printlang("Jun"),&printlang("Jul"),&printlang("Aug"),
		&printlang("Sept"),&printlang("Oct"),&printlang("Nov"),&printlang("Dec"));

}
sub day_array {

											# String Arrays
	return (&printlang("Sun"),&printlang("Mon"),&printlang("Tue"),
		&printlang("Wed"),&printlang("Thu"),&printlang("Fri"),&printlang("Sat"));


}

	#-------------------------------------------------------------------------------
	#
	# -------   Locale Date ---------------------------------------------------
	#
	# 		Returns a date string based on the specified locale
	#		Edited: 18 Feb 2014
	#		Author: Luc Belliveau <luc.belliveau@nrc-cnrc.gc.ca>
	#		Requires: system that supports locales (and POSIX)
	#-------------------------------------------------------------------------------
sub locale_date {
	my ($current, $fmt, $locale) = @_;
	unless (defined $fmt) { $fmt = "%c"; }
	unless (defined $locale) { $locale = "en_US"; }

	my $date = $current;
	unless (looks_like_number($current)) {
		$date = str2time($current);
	}

	if ($current eq 0) { return &printlang("N/A"); }

	# Save old locale
	my $old_locale = setlocale(LC_TIME);

	# Set current locale to specified value (TODO: add sanity check))
	setlocale(LC_TIME, $locale);

	# Extract values for date
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);
	if ($h eq "GMT") { ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($date); }
	else { ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($date); }

	# Format date
	my $str = strftime($fmt, $sec, $min, $hour, $mday, $mon, $year);

	# Return locale to it's original setting
	setlocale(LC_TIME, $old_locale);

	# Return our formated date, with any extended characters encoded as html entities.
	return encode_entities($str);

}

	#-------------------------------------------------------------------------------
	#
	# -------   RFC3339 to eopch ---------------------------------------------------
	#
	#           Converts an RFC 3339 (ISO ISO 8601)
	#		to epoch, GMT value
	#	      Edited: 28 March 2010
	#-------------------------------------------------------------------------------
sub rfc3339_to_epoch {

	my ($rfc3339,$tz) = @_;

	my ($y,$m,$d,$h,$mm,$s) = $rfc3339 =~ /(.*?)\-(.*?)\-(.*?)T(.*?):(.*?):(.*?)Z/;
	$y+=0;$m+=0;$d+=0;$h+=0;$mm+=0;	# Convert to numeric;
	$y-=1900;$m-=1;
	my $epoch = timegm($s,$mm,$h,$d,$m,$y);
	return $epoch;


}
sub epoch_to_rfc822 {

	# Get date from input
	my ($time,$h,$tz) = @_;
	my $dt = &set_dt($time,$tz);
	my ($year,$month,$day,$dow,$hour,$minute,$second) = &dt_to_array($dt);
	my @months = &month_array();
	my @days = &day_array();
	unless ($minute) { $minute="00"; }
	unless ($second) { $second="00"; }

	return "$days[$dow], $day $months[$month] $year $hour:$minute:$second -0400";

}

	#-------------------------------------------------------------------------------
	#
	# -------   Datepicker to eopch ---------------------------------------------------
	#
	#           Converts a datepicker Date
	#		to epoch, GMT value
	#               Datepicker dates have the form:  yyyy/mm/dd hh:mm
	#             Time zone offset (in hours) is $Site->{st_timezone}
	#	      Edited: 28 March 2010
	#-------------------------------------------------------------------------------
sub datepicker_to_epoch {

	my ($datepick,$tz) = @_;

	unless (&new_module_load($query,"DateTime")) {
		return "DateTime module not available in epoch_to_datepicker";
	}

	my $s = 0;
	my ($date,$hour) = split " ",$datepick;
	my ($y,$m,$d) = split "/",$date;
	my ($h,$mm) = split ":",$hour;
  #	my ($y,$m,$d,$h,$mm) = $datepick =~ /(.*?)\/(.*?)\/(.*?) (.*?):(.*?)/;    Doesn't work for some reason (drops minutes to 0 )
	return "" unless ($y);	# Catch parsing errors

	$m = int($m); $h = int($h); $y = int($y); $d = int($d); $mm = int($mm);		# Convert datepicker to integers

	my $tz ||= $Site->{st_timezone} || "America/Toronto";	# Needs to be the server time zone setting

	my $dt = DateTime->new(
		year 	   => $y,
		month      => $m,
		day        => $d,
		hour       => $h,
		minute     => $mm,
		time_zone  => $tz,
	);

	my $epoch = $dt->epoch();

	return $epoch;

}

	#-------------------------------------------------------------------------------
	#
	# -------   Epoch to Datepicker ---------------------------------------------------
	#
	#           Converts an epoch Date
	#		to Datepicker
	#               Datepicker dates have the form:  yyyy/mm/dd hh:mm
	#             Time zone offset (in hours) is $Site->{st_timezone}
	#	      Edited: 28 March 2010
	#-------------------------------------------------------------------------------
sub epoch_to_datepicker {

	# Get date from input
	my ($time,$tz) = @_;
	my $dt = &set_dt($time,$tz);
	my ($year,$month,$day,$dow,$hour,$minute,$second) = &dt_to_array($dt);

	return "$year/$month/$day $hour:$minute";
}

	#-------------------------------------------------------------------------------
	#
	# -------   Epoch to Date ---------------------------------------------------
	#
	#           Return the date in an epoch
	#            Eg. March 26  or May 5
	#             Time zone offset (in hours) is $Site->{st_timezone}
	#	      Edited: 28 March 2010
	#-------------------------------------------------------------------------------
sub epoch_to_time {

	# Get date from input
	my ($time,$h,$tz) = @_;
	my $dt = &set_dt($time,$tz);
	my ($year,$month,$day,$dow,$hour,$minute,$second) = &dt_to_array($dt);

	return $hour.":".$minute;
}

	#-------------------------------------------------------------------------------
	#
	# -------   Epoch to Time ---------------------------------------------------
	#
	#           Return the time in an epoch
	#            Eg. 18:35
	#             Time zone offset (in hours) is $Site->{st_timezone}
	#	      Edited: 28 March 2010
	#-------------------------------------------------------------------------------
sub epoch_to_date {

	# Get date from input
	my ($time,$h,$tz) = @_;
	my $dt = &set_dt($time,$tz);
	my ($year,$month,$day,$dow,$hour,$minute,$second) = &dt_to_array($dt);
	my @months = &month_array();

	return $months[$month]." ".$day;
}
	#-------------------------------------------------------------------------------
	#
	# -------   RFC3339 to eopch ---------------------------------------------------
	#
	#           Converts an RFC 3339 (ISO ISO 8601)
	#		to epoch, GMT value
	#	      Edited: 28 March 2010
	#-------------------------------------------------------------------------------
sub ical_to_epoch {

	my ($tval,$feedtz) = @_;

	my $tz; my $val;					# Establish time zone
	if ($tval =~ /TZID=(.*?):(.*?)/) {
		$tz = $1; $val = $2;
	} elsif ($tval =~ /Z/) {
		$tz = "UTC"; $val = $tval;
	} else {
		if ($feedtz) { $tz = $feedtz; $val = $tval; }
		else { $tz = "UTC"; $val = $tval; }
	}


    	$val =~ tr/a-zA-Z0-9/X/cs;             	# remove non-alphas from iCal date
    	$val =~ s/X//g;             			# (complicated because Google throws a weird char in there)

								# parse ical vals and create dt
  #print "parsing icaldate<br>";
	my ($y,$m,$d,$h,$mm,$s) = &parse_icaldate($val);
	unless ($y) { $y = "2011"; }
	unless ($m) { $m = 1; }
	unless ($d) { $d = 1; }
	unless ($h) { $h = 0; }
	unless ($mm) { $mm = 0; }
	unless ($s) { $s = 0; }
  #print "($y,$m,$d,$h,$mm,$s)";
	my $dt = DateTime->new(
 	     year       => $y,
 	     month      => $m,
 	     day        => $d,
 	     hour       => $h,
 	     minute     => $mm,
 	     second     => $s,
 	     time_zone  => $tz,
 	);

	my $epoch_time  = $dt->epoch;
	return ($tz,$epoch_time);


}

	#-------------------------------------------------------------------------------
	#
	# -------   RFC3339 to local ---------------------------------------------------
	#
	#           Converts an RFC 3339 (ISO ISO 8601)
	#		to epoch, GMT value
	#	      Edited: 28 March 2010
	#-------------------------------------------------------------------------------
sub ical_to_local {

	my ($datetime) = @_;

	my $offset="";						# Offset as determined from the dt


	if ($datetime =~ /Z/) { $datetime =~ s/Z//; $offset=0; }

	my ($year,$month,$day,$hour,$minute,$second) = &parse_datetime($datetime);





 print "Length $length ; $year : $month : $day : $hour : $minute : $second <br>";


}

	# Parse Datetime
	#
	# parses an iCal datetime string
	# bleah
sub parse_icaldate {

	my ($datetime) = @_;

	if ($datetime =~ /Z/) { $datetime =~ s/Z//; $offset=0; }
	my $length = length($datetime);
	my ($year,$month,$day,$hour,$minute,$second);

	if ($length == 15) {
		if ($datetime =~ /^(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)(\d\d)$/) {
			$year = $1;
			$month = $2;
			$day = $3;
			$hour = $4;
			$minute = $5;
			$second = $6;
		}
	} elsif ($length == 13) {
		if ($datetime =~ /^(\d\d\d\d)(\d\d)(\d\d)T(\d\d)(\d\d)$/) {
			$year = $1;
			$month = $2;
			$day = $3;
			$hour = $4;
			$minute = $5;
		}
	} elsif ($length == 11) {
		if ($datetime =~ /^(\d\d\d\d)(\d\d)(\d\d)T(\d\d)$/) {
			$year = $1;
			$month = $2;
			$day = $3;
			$hour = $4;
		}
	} elsif ($length == 8) {
		if ($datetime =~ /^(\d\d\d\d)(\d\d)(\d\d)$/) {
			$year = $1;
			$month = $2;
			$day = $3;
		}
	} else {
		print "Odd length: $length for $datetime <br>";
	}

	return ($year,$month,$day,$hour,$minute,$second);

}

1;