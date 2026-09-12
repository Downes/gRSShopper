# Publishing functions: api_page_publish, api_publish, api_autopost

# API PAGE PUBLISH ---------------------------------------------------------- "
# ------- Page -----------------------------------------------------
#
# Publish Page
# Expects $vars->{id} as page id
#
# -------------------------------------------------------------------------


sub api_page_publish {

  # VCard
  if ($vars->{table} =~ /vcard/i) {

		use vCard;

		$Person->{person_work_email} ||= $Person->{person_email};
		$Person->{person_home_email} ||= $Person->{person_email};

		# create the object

		my $vcard_hash = {

		full_name    => $Person->{person_name},
    given_names  => $Person->{given_names},
    family_names => $Person->{family_names},
    title        => 'Research Scientist',
    photo        => $Person->{person_photo},

    addresses =>   [
    { type      => ['home'],
      city      => $Person->{person_city},
      region    => $Person->{person_province},
      post_code => '',
      country   => $Person->{person_country},
      preferred => 1,
    },
  ],

		};



		my $vcard = vCard->new;

		$vcard->load_hashref($vcard_hash);


    my $emails = [];
		if ($Person->{person_home_email}) { push @$emails,{ type => ['home'], address => $Person->{person_home_email} }; }
		if ($Person->{person_work_email}) { push @$emails, { type => ['work'], address => $Person->{person_work_email} };  }
		$vcard->email_addresses($emails);

    my $phones = [];
		if ($Person->{person_home_phone}) { push @$phones,{ type => ['home'], number => $Person->{person_home_phone} }; }
		if ($Person->{person_work_phone}) { push @$phones, { type => ['work'], number => $Person->{person_work_phone} };  }
  	$vcard->phones($phones);

		my $vcard_filename = $Site->{st_urlf}."vcard.vcf";
		open OUT,">$vcard_filename";
		print OUT $vcard->as_string();
		close OUT;
		print qq|vCard printed to |.
		   $Site->{st_url}.
		   qq|vcard.vcf <br><a href="|.
			 $Site->{st_url}.
			 qq|vcard.vcf">click here</a> to view. |;
		exit;

	}

	&status_error("Trying to publish but I got confused.");
	unless ($vars->{table} eq "page") { return qq|Only publishing pages at the moment|; exit; }
	unless ($vars->{id}) { return qq|Publish command needs a page ID to publish|; exit; }


}


# to force a new harvest: http://beeyard.lpss.me:8091/hive/d69ce375-4168-4a7d-b6f1-439216e6094f


# API UPDATE ----------------------------------------------------------
# ------- Publish -----------------------------------------------------
#
# Update a publish field, including actually publishing the resources
# on a third party site oif so directed by the field
#
# -------------------------------------------------------------------------

sub api_publish {

	#die "Field $vars->{table_name},$vars->{col_name} does not exist" unless (&__check_field($vars->{table_name},$vars->{col_name}));

	my $table = $vars->{table};
	my $id = $vars->{id};
	my $value = $vars->{value};
	my $col = $table ."_social_media";


	my $published = &db_get_single_value($dbh,$table,$col,$id);

$vars->{message} .= "api_publish(): $table $id <br>";



	my $result;
	# Don't publish if already published, except locally

	if ($published =~ /$vars->{value}/ && $vars->{value} !~ /web|rss|atom|json/i) {	
		$vars->{message} .= "Was already published";

	#	exit;
	} else {				# Not yet published, so publish it

	# So now, ideally, I'd use the name of the social network service to pick a subroutine to actually do the publishing, but...

		if ($vars->{value} =~ /twitter/i) {

			my $twitter = &twitter_post($dbh,"post",$id);
			$published .= ",twitter";
			my $result = &db_update($dbh,$table, {$col => $published}, $id); # Prevent publishing twice
			$vars->{message} .= "Published to <a href='$twitter' target='new'>$twitter</a>";
			&status_ok();

		}

		elsif ($vars->{value} =~ /bluesky/i) {
			my $bluesky = &bluesky_post($dbh,"post",$id);
			$published .= ",bluesky";

			my $result = &db_update($dbh,$table, {$col => $published}, $id); # Prevent publishing twice
			$vars->{message} .= "Published to <a href='$bluesky' target='new'>$bluesky</a>";
			&status_ok();

		}


		elsif ($vars->{value} =~ /mastodon/i) {


			my $mastodon = &mastodon_post($dbh,"post",$id);
			$published .= ",mastodon";
			my $result = &db_update($dbh,$table, {$col => $published}, $id); # Prevent publishing twice
			$vars->{message} .= "Published to <a href='$mastodon' target='new'>$mastodon</a>";
			&status_ok();
			exit;

		}

		elsif ($vars->{value} =~ /badgr/i) {

			# Find the task(s) associated with this badge
		my @keylist = &find_graph_of("badge",$id,"task");
		unless ($Site->{badgr_issuerid}) { print "You need to set up your Badgr account first"; exit;}
		unless (@keylist) { print "You need to associate at least one task with this badge before you can publish it"; exit;}
		foreach my $t (@keylist) {
				my $keyname = &get_key_name("task",$t);
				print "$t $keyname<p>";
			}

		my $badge = &db_get_record($dbh,"badge",{badge_id=>$id});
			print "Sending to Badgr<br>";

			# Initialize Badgr
			our $Badgr = gRSShopper::Badgr->new({
				badgr_url   => $Site->{badgr_url},
				badgr_account		=>	$Site->{badgr_account},
				badgr_password => $Site->{badgr_password},
				badgr_issuerid => $Site->{badgr_issuerid},
				secure => 1,							# Turns on SSH
			});

		# Format the badge image
			my $filerecord = &item_images("badge",$id,"smallest");
			my $imagestr;

		return "Module File::Slurp not loaded" unless (&new_module_load($query,"File::Slurp"));
		return "Module MIME::Base64 not loaded" unless (&new_module_load($query,"MIME::Base64"));

			if ($filerecord->{file_mime} eq "image/png") {
				my $imgfilename =  $Site->{st_urlf}.$filerecord->{file_dirname};
			#use File::Slurp;
			#use MIME::Base64 qw|encode_base64|;
			$imagestr = MIME::Base64::encode_base64( read_file( $imgfilename ) );
			$imagestr =~ s/\n//g;$imagestr =~ s/\n//g;						# because they get inserted somehow and Badgr chokes on them
			$imagestr = "data:image/png;base64,".$imagestr;
			} else {
				print "Badgr requires that image files be PNG format.";
			}


		# Create the Badge
			my $saved_badge = $Badgr->create_badge({
				criteriaUrl => $Site->{st_url}."badge/".$id,
		badge_title => $badge->{badge_title},
		badge_description => $badge->{badge_description},
				image => $imagestr,
		});

		print "Saved badge ID: ",$saved_badge->{entityId},"<p>";
		&db_update($dbh,"badge",{badge_badgrid=>$saved_badge->{entityId},
				badge_openbadgeid=>$saved_badge->{openBadgeId}},$id);   #Saves entityId to badge record

			exit;

		}

		elsif ($vars->{value} =~ /web/i) {



			$vars->{force} = "yes"; 							# Over-write cache
			#&output_record($dbh,$query,$table,$id,"html","api");

			my $printed = &print_record($table,$id);					# Publish

			&status_error("Printing error ,$table,$id  $? $!") unless ($printed);
			my $url = $Site->{st_url}.$table."/".$id;
			$published .= ",web";
			my $result = &db_update($dbh,$table,{$table."_social_media"=>$published}, $id); # Prevent publishing twice

			# Find the previous record, and print it (to create its 'next' link, which won't exist unless we do this)
			my $nextsql ="SELECT ".$table."_id FROM $table WHERE ".$table."_id <'".$id."' ORDER BY ".$table."_id DESC  LIMIT 1";
			my ($newprevid) = $dbh->selectrow_array($nextsql);
			if ($newprevid) {
					
				 &print_record($table,$newprevid); 

			} 

			# Publish feed and author records
			foreach my $assoc_table ("feed","author") {
				my @assoc_graph = &find_graph_of($table,$id,$assoc_table);
				if ($assoc_graph[0]) {
					foreach my $assoc_item (@assoc_graph) { 
						
						&print_record($assoc_table,$assoc_item);

					}
				}
			}


			# Scan links for webmentions
			my $record = &db_get_record($dbh,$table,{$table."_id"=>$id});
			my $scan_content = $record->{$table."_description"}.$record->{$table."_content"};
			my @links = $scan_content =~ /<a[^>]*\shref=['"](.*?)["']/gis;

			# Add the post link to the list, if it exists
			if ($record->{post_link}) { push @links, $record->{post_link}; }

			foreach my $l (@links) {
				my $loc = $Site->{st_url}; next if ($l =~ /$loc/i); # Don't analyze local links
				# Look for the link ID
       # print "Checking $l <br>";
				my $lid = &db_locate($dbh,"link",{link_link => $l});
				$lid ||= "new";

				# Get the remote URL of the link
				my $lcontent = get($l);

				# Find the Link title
				my $ltitle;
 				if ($lcontent =~ m/<title>(.*?)<\/title>/si) { $ltitle = $1; }
				elsif ($lcontent =~ m/<meta content=['"](.*?)['"] property=['"]og:title['"]\/>/) { $ltitle = $1; }       #'

				# Save the link data
				$vars->{link_link} = $l;
				$vars->{link_id} = $lid;
				$vars->{link_title} = $ltitle;
				$vars->{link_crdate} = time;
				$lid = &record_save($dbh,$vars,"link",$vars);

				# Create graph record linking published record and link
				if ($lid) {	&graph_add($table,$id,"link",$lid,"reference",""); }

				# Look for webmention endpoint
				my $endpoint = &find_webmention_endpoint($lcontent);
				if ($endpoint) { &send_webmention($endpoint,$l,$Site->{st_url}.$table."/".$id); }



			}

				
			$vars->{message} .= qq|Published to <a href="$url" target="new">$url</a>|;
			&status_ok();
			exit;
		}

		elsif ($vars->{value} =~ /json|rss/i) {

			$published .= ",".$vars->{value};



			my $result = &db_update($dbh,$table, {$col => $published}, $id); # Prevent publishing twice
			
			print "Published to ".$vars->{value}."<p>";
			exit;
		}

		&status_error("Couldn't figure out where to publish this.");

	}

}
# API AUTOPOST ----------------------------------------------------------
# ------- Clone Record -----------------------------------------------------
#
# Give a link id and a post based on the link is created
#
# -------------------------------------------------------------------------
#


sub api_autopost {

	my ($linkid) = @_;
	unless ($linkid) { &status_error("Don't know which ".$vars->{table}." number to clone."); }
	my $post_id = &auto_post($linkid);    # &auto_post() is in grsshopper.pl
	 if ($post_id > 0) { 
		my $tabs = []; 
		my $starting_tab = $vars->{starting_tab} || "Edit";	
		print &main_window($tabs,$starting_tab,"post",$post_id,$vars);
		exit;
	 } else { &status_error($post_id); } # which will be an error message
}

1;
