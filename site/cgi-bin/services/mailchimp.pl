
sub send_mailchimp_email {
		my ($pgcontent,$pgtitle,$listid) = @_;
		my $response;

	    use lib $Site->{st_cgif}.'./modules/MailChimp/lib';
		use lib $Site->{st_cgif}.'./modules/MailChimp/lib/MailChimp';
		eval("use MailChimp;");  # eval so it doesn't try to load before st_cgif is defined
	
		# Initialize account
		print "Initializing account... <br>";
		my $account = MailChimp->new({
			datacenter => $Site->{mailchimp_datacenter},
			version => $Site->{mailchimp_version},
			url => $Site->{mailchimp_url},
			apikey => $Site->{mailchimp_apikey}
		});

		#username => 'stephen@downes.ca',
		#password => 'PSAF_rout3riff8yet',

		my $template_id = 69461;

		# Create a campaign
		my $email = 'stephen@downes.ca';
		my $ago = qq|<a href="admin.cgi">admin general options</a>|;
		unless ($Site->{st_crea}) { $response .= qq|<warn>Site Creator's name should be defined in $ago<br></warn>|;}
		unless ($Site->{st_crea}) { $response .= qq|<warn>Site email should be defined in $ago<br></warn>|;}

		print "Defining campaign... <br>";
		my $campaign = MailChimp::Campaigns->new({
			account => $account,
			type => 'regular',
			recipients => {
		    	list_id => $listid
	   	 	},
				settings => {
				subject_line => $pgtitle,
				preview_text => 'Text',
				title => $pgtitle,
				from_name => $Site->{st_crea},
				reply_to => $Site->{st_email},
				to_name => "",
				folder_id => "",
				auto_fb_post => [],
				template_id => $template_id
			},
			content_type => 'template',
		});

		print "Creating campaign... <br>";
		$campaign->create();
		print "Campaign created. ";

		print "Getting campaign info from Mailchimp<br>";
		print $campaign->to_string();
		print "<br>";	

		print "Adding content.<br>";
		# Assign content to a campaign
		my $data = {
			html => $pgcontent,
		};
		$campaign->add_content($data);	
		print "Content added.<p>";

		# Send a campaign
		$campaign->send();	
		return $response."Sent $pgtitle to MailChimp list $listid <p>";

	}


1;