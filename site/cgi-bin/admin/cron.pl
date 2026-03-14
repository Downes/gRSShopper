	#--------------------------------------------------------
	#
	#       CRON TASKS
	#
	#	Cron Functions
	#	Perform Cron Function once a minute
	#
	#--------------------------------------------------------



	sub cron_tasks {

		my ($Site,$dbh) = @_;

		my $log = "";	# Flag that indicates whether an activity was logged
	
		&update_config_table($dbh,{cronrun=>time});
		&update_config_table($dbh,{cronerr=>"none"});

		# Begin logging
		my $loglevel = 10;
        &log_cron(8,sprintf("Context:%s, Args 0:%s, %s, 1:%s, 2:%s, 3:%s\n",$Site->{context},$ARGV[0],$ARGV[1],$ARGV[2],$ARGV[3]));

		# Get the time
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		my @wdays = qw|Sunday Monday Tuesday Wednesday Thursday Friday Saturday|;
		my $weekday = @wdays[$wday];
		$year += 1900;
		$mon++;if ($mon < 10) { $mon = "0".$mon; }
		
		
		if ($min < 10) { $min = "0".$min; }
		if ($mday < 10) { $mday = "0".$mday; }
		if ($loglevel > 1) { $log .= "Hour: $hour, Minute = $min\n"; }
		elsif ($loglevel > 0) { $log .= "$hour:$min - "; }

        # Republish  - Runs a batch every cron cycle (so as not to overload the whole system publishing 30K+ posts)
		my $republish = 0;
		foreach my $rtable ("feed","author","post","presentation") {
		    if ($republish == 1) { &republish($rtable,15); }
		}


											# Autopublish


		my $asql=""; my $amode;
			# Weekly
		if ($weekday eq "Sunday" && $hour eq "23" && $min eq "54") { 
			$amode = "Weekly"; 
			$asql = qq|SELECT * FROM page WHERE page_autopub='yes' AND page_autowhen='Weekly'|; }

			# Daily
		elsif ($hour eq "16" && $min eq "30") {
			$amode = "Daily";  
			$asql = qq|SELECT * FROM page WHERE page_autopub='yes' AND page_autowhen='Daily'|; }

			# Hourly
		elsif ($min eq "37") { 
			$amode = "Hourly"; 
			$asql = qq|SELECT * FROM page WHERE page_autopub='yes' AND page_autowhen='Hourly'|; }

		if ($amode) { 
			&log_cron(7,"Autopublishing $amode pages\n");
			my $asth = $dbh -> prepare($asql);
			$asth->execute() or &log_cron(0,sprintf("Autopublish error: %s \n",$dbh->errstr()));
			while (my $npage = $asth -> fetchrow_hashref()) {
				&publish_page($dbh,$query,$npage->{page_id},0);
				&log_cron(0,sprintf("Autopublished page: %s %s\n",$npage->{page_id},$npage->{page_title}));
			}
			$asth->finish;
		}

											# Newsletters


		&log_cron(9,"Checking for newsletters");
		my $sql = qq|SELECT * FROM page WHERE page_subsend='yes' AND page_subhour=? AND page_submin=? AND (page_subwday LIKE ? OR page_submday LIKE ?)|;
		my $sth = $dbh -> prepare($sql);
		$sth -> execute($hour,$min,'%'.$weekday.'%','%'.$mday.'%') or 
			&log_cron(0,sprintf("Newsletter Error: %s",$dbh->errstr()));;
		
		&log_cron(5,"$sql,$hour,$min,'%'.$weekday.'%','%'.$mday.'%'");

		while (my $npage = $sth -> fetchrow_hashref()) {
			my $report = &send_nl($dbh,$query,$npage->{page_id},"subscribers",0);
			&log_cron(0,sprintf("Sent newsletter: %s",$npage->{page_title}));
			&log_cron(5,"$report");			
		}
		$sth->finish;
	


											# Harvester



$Site->{st_harvest_on} = "no";
$Site->{st_harvest_int} = 5;

		if ($Site->{st_harvest_on} eq "yes") {

			# Calculate harvest interval trigger
			my $dividend = ($mday * 24 * 60) + ($hour * 60) + $min;
			my $divisor = $Site->{st_harvest_int}; $divisor ||= 60;
			&log_cron(7,sprintf("Harvester Interval: %s/%s and harvester on = %s)",
				$dividend,$divisor,$Site->{st_harvest_on}));

			if ($dividend % $divisor == 0) {  # Harvest timer

				# This is convoluted, but the intent here is to allow an external process
				# to actually do the harvesting, so I could later replace it witn Python or Erlang
				# or whatever

				# We need to get the actual directory of admin.cgi
				use Cwd 'abs_path';
				my $harvester = abs_path($0);

				# Now figure out the directory of harvest.cgi
				$harvester =~ s/admin\.cgi/harvest\.cgi/i;
				&log_cron(7,"Harvesting using process: $harvester");

				my $siteurl = $Site->{site_url}; $siteurl =~ s|http://||;$siteurl =~ s|/||;
				#my $status = system($harvester,$siteurl,$Site->{cronkey},"queue");

				# Making sure the call to harvester has the same args as the call to admin
        		my @args = ($harvester,$ARGV[0],$ARGV[1],$ARGV[2],"queue");  

				# Call the harvester
        		system(@args) == 0 or &log_cron(0,"system @args failed: $?");
				
				# Catch and report errors
				if ($? == -1) {	&log_cron(0,"Harvester failed to execute: $!");  }
        		elsif ($? & 127) { &log_cron(0,sprintf("Harvester died with signal %s",($? & 127))); }
		        else { &log_cron(5,sprintf("Harvester exited with value %d",($? >> 8))); } 

			}

	  #  &send_email("stephen\@downes.ca","stephen\@downes.ca","Harvester - $Site->{st_url}","\nHarvester run, Status: $status\n");

		}



											# Hourly Tasks

		if ($min eq "33") {
			&log_cron(8,"Performing hourly tasks");

	#		my $dsql = qq|select link_id FROM link WHERE link_link LIKE $deletelink|;
#print $dsql;
	#		my $sthl = $dbh->prepare($dsql);
	#		$sthl->execute();
#			while (my $stale_link = $sthl -> fetchrow_hashref()) {
			#	&record_delete($dbh,$query,"link",$stale_link->{link_id});
	#			if ($loglevel > 2) { $log .= "Deleted bad link $stale_link->{link_id} \n"; }
	#		}


		}

											# Daily Tasks


		if ($hour eq "23" && $min eq "44") {					
			&log_cron(8,"Performing daily tasks\n");

			# Make Fresh Links Stale

			&log_cron(8,"Making fresh links stale \n");
			my $staledate = time - (24 * 60 * 60);
			my $dsql = qq|UPDATE link SET link_status = 'Stale' WHERE (link_status = 'Fresh'
				OR link_status = 'RSS 0.91 Fresh' OR link_status = 'fresh') && link_crdate < '$staledate'|;

			my $affected = $dbh->do($dsql); 
			&log_cron(0,sprintf("Error making links stale in cron_tasks()",$dbh->errstr)) unless $affected;
			&log_cron(5,"No links made stale in cron_tasks()") if ($affected eq '0E0');
			
			# Clean Up Audio Downloads
			# See Admin 'Harvester' screen for settings
			
			&log_cron(8,"Cleaning up audio downloads \n");
			my $audio_dir = $Site->{st_urlf}.$Site->{audio_download_dir};
			if (-d $audio_dir) {
				my $audio_files_expire = $Site->{audio_files_expire} || 1;
				$audio_dir =~ s/\/$//;	# Remove trailing slash
				opendir (DIR, "$audio_dir/");
				my @audio_files = grep(/.txt/,readdir(DIR));
				closedir (DIR);

				foreach $audio_file (@audio_files) {
					if (-M "$dir/$FILES" > $audio_files_expire) { unlink("$dir/$FILES"); }
				}
			}

		}

		if ($hour eq "23" && $min eq "30") {					
			&log_cron(8,"Performing daily tasks\n");
			# Make Stale Links Disappear
			
			&log_cron(8,"Making stale links disappear \n");
$Site->{st_stale_expire} = (72 * 60 * 60);
			my $expires = $Site->{st_stale_expire};
			my $disappeardate = time - $expires;

			my $dsql = qq|select link_id FROM link WHERE (link_status = 'Stale'
				OR link_status = 'RSS 0.91 stale' OR link_status = 'stale') && link_crdate < '$disappeardate'|;
			my $sthl = $dbh->prepare($dsql);
			$sthl->execute();
			while (my $stale_link = $sthl -> fetchrow_hashref()) {

				# Need to filter so I don't delete links that are in the graph
	#			&record_delete($dbh,$query,"link",$stale_link->{link_id});
				&log_cron(2,"Deleted stale link %s \n",$stale_link->{link_id}); 
			}
		}

											# Clear the cache
		if ($hour eq "02" && $min eq "10") {
			&log_cron(8,"Performing daily tasks\n");
			&log_cron(8,"Clearing the cache \n");
			&cache_clear($dbh,$query);
		}



		if ($hour eq "23" && $min eq "50") {				# Reset Hits to 0
			&log_cron(8,"Performing daily tasks\n");

			&log_cron(8,"Rotating hit counters\n");
			&rotate_hit_counters($dbh,$query,"post");			# Reset post hit counters
			&rotate_hit_counters($dbh,$query,"page");			# Reset page hit counters

		}

		# Need to add a task to refresh the log file

		# Report cron completed
		#my ($sec, $min, $hour) = (localtime)[0,1,2];
		$min  = sprintf("%02d", $min);
		$hour = sprintf("%02d", $hour);
		my $ltime = "$hour:$min";
	  	&log_cron(5,sprintf("%s cron completed for %s",$Site->{st_name},$ltime));
		exit;
	}


	sub cache_clear {

		my ($dbh,$query) = @_;
		my $vars = $query->Vars;
		$Site->{pg_update} ||= 86000;
		my $expired = time - $Site->{pg_update};
	$sth = $dbh->prepare("TRUNCATE TABLE cache");

	$sth->execute();
	#	my $csql = qq|delete FROM cache WHERE cache_update < ?|;
	#	my $sth = $dbh->prepare($sql);
	#	print $csql."<br> $expired";
	 #       my $affected = $sth->execute($expired);


		#my $affected = $dbh->do($csql);
		print "$affected rows cleared <br>";

	}
1;
