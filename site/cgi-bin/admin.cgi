#!/usr/bin/perl
use CGI::Carp qw(fatalsToBrowser);
use lib 'modules/lib/perl5';
binmode STDOUT, ':utf8';

  #  use lib '/home/downesca/public_html/cgi-bin/modules/MailChimp/lib';
	# use lib '/home/downesca/public_html/cgi-bin/modules/MailChimp/lib/MailChimp';

  # use lib '/var/www/html/cgi-bin/modules/MailChimp/lib';
#	 use lib '/var/www/html/cgi-bin/modules/MailChimp/lib/MailChimp';

#    gRSShopper 0.7  Admin  0.62  -- gRSShopper administration module
#    05 June 2017 - Stephen Downes

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
 
#--------------------------------------------------------
#
#	    gRSShopper
#           Admin Functions
#
#-------------------------------------------------------------------------------
 #print "Content-type: text/html\n\n";
 # print "Running<p>";

# Diagnostics

	our $diag = 0;
	if ($diag>0) { print "Content-type: text/html\n\n"; }
	
#print "Content-type: text/html\n\n";
#print "Admin \n";	
	


# Forbid bots
	# Check for cron
	my $is_cli_cron = (!defined $ENV{'GATEWAY_INTERFACE'} && defined $ARGV[1] && $ARGV[1] eq 'cron');
	unless ($is_cli_cron) {
		# Reject bad user agents (bots)
		my $ua = $ENV{'HTTP_USER_AGENT'} // '';
		if ($ua =~ /(bot|slurp|spider)/i) {
			print "Status: 403 Forbidden\r\nContent-Type: text/plain\r\n\r\nForbidden\n";
			exit;
		}
	

		use CGI;
		use CGI::Cookie;
		my $q = CGI->new;

		my %cookies = CGI::Cookie->fetch;
		my $sid = $cookies{CGISESSID} ? $cookies{CGISESSID}->value : '';

		# If no session id, bail fast (no DB)
		if (!$sid) {
			print $q->header(-status => 403, -type => 'text/plain');
			print "Forbidden\n";
			exit;
		}
	}


# Load gRSShopper

	use File::Basename;
	my $dirname = dirname(__FILE__);
	require $dirname . "/grsshopper.pl";

	# Admin sub-modules
	require $dirname . "/admin/cron.pl";
	require $dirname . "/admin/newsletters.pl";
	require $dirname . "/admin/users.pl";
	require $dirname . "/admin/database.pl";
	require $dirname . "/admin/records.pl";


# Load modules

	our ($query,$vars) = &load_modules("admin");


# Load Site
	
	our ($Site,$dbh) = &get_site("admin");	
	
	# Cron (which runs every 60 seconds)
	if (time - $Site->{cronrun} > 120)	{ $Site->{cronerr} = "Cron not running"; }
	if ($Site->{context} eq "cron") { &cron_tasks($Site,$dbh); } 
	
# Load User

	my ($session,$username) = &check_user("text/html");
	our $Person = {}; bless $Person;
	&get_person($Person,$username);

	my $person_id = $Person->{person_id};
	&show_login($session);
	&admin_only();

# Set vars
	my $vars = $query->Vars;
	my $page_dir = "../";
	if ($vars->{admin_pane}) {$Site->{admin_pane} = $vars->{admin_pane}; }  # Open the right admin page on completion of an action




# Restrict locally
	unless ($vars->{action} eq "rcomment") {   # Exception for remote comments
		my $refer = $ENV{HTTP_REFERER};
	#	die "Invalid call from external website" unless 
	#		($refer =~ /$Site->{st_url}/ || $Site->{context} eq "cron");
	}
	
	



	# Initialize system variables

		my $options = {}; bless $options;
		our $cache = {}; bless $cache;


	# Option to call initialize functions

	#	if ($vars->{action} eq "initialize") {  $Site->__initialize("command"); }
	#    print "Content-type: text/html\n\n";
	#    while (my($fx,$fy) = each %$vars) { print "$fx = $fy<br>";}   #{%}





# Analyze Request --------------------------------------------------------------------

	# Determine Action ( assumes admin.cgi?action=$action&id=$id )

		my $action = $vars->{action};
		my $id = $vars->{id};

if ($action eq "hub") {
	print $query->header();
	while (my($vx,$vy) = each %$vars) { print "$vx = $vy<br>"; }

}

	# Determine Request Table, ID number ( assumes admin.cgi?$table=$id and not performing action other than list, edit or delete)

		my @tables = &db_tables($dbh);
		foreach $t (@tables) {

			if ((!$action || $action =~ /^edit$/i || $action =~ /^list$/i || $action =~ /^Delete$/i || $action =~ /^extract_nouns$/i ) && $vars->{$t}) {
				$table = $t;
				$id = $vars->{$t};
				$vars->{id} = $id;
				last;
			}
		}


	# Direct Request Table, ID number, and list requests ( required for most actions, assumes admin.cgi?db=$table&id=$id or admin.cgi?table=$table&id=$id , no $id for action=list )

	if ($vars->{db} || $vars->{table}) {
		$table = $vars->{table} || $vars->{db};
		if ($vars->{id}) {
			$id = $vars->{id};
		} else {
			unless ($action) {
				$action = "list";
			}
		}
	}

	# Determine Output Format  ( assumes admin.cgi?format=$format )

	if ($vars->{format}) { 	$format = $vars->{format};  }
	if ($action eq "list") { $format = "list"; }
	$format ||= "html";		# Default to HTML

if ($action eq "do_slides") {

	print "Content-type: text/html\n\n";
my $uploaded=0;
	my $sql = "SELECT * FROM presentation";
	my $sth = $dbh -> prepare($sql);
	$sth -> execute();
	while (my $presentation = $sth -> fetchrow_hashref()) {
		print "<p>".$presentation->{presentation_id}.": ".$presentation->{presentation_title}."<br><ul>";	

#		print "<p>".$presentation->{presentation_title}."<br><ul>";
	my $uploadtitle;

		my @presfiles;
		if ($presentation->{presentation_slides} && ($presentation->{presentation_slides} ne " ")) {
			push @presfiles, $presentation->{presentation_slides};
		} else { 
			print "No slides<br>"; 
		}
		if ($presentation->{presentation_slide_player} && ($presentation->{presentation_slide_player} ne " ")) {
			push @presfiles, $presentation->{presentation_slide_player};
		} else { 
			print "No pdf<br>"; 
		}
		if ($presentation->{presentation_audio} && ($presentation->{presentation_audio} ne " ")) {
			push @presfiles, $presentation->{presentation_audio};
		} else { 
			print "No audio<br>"; 
		}

		if (@presfiles) {

			foreach $ffile (@presfiles) {
				my $filename = (split(/\//,$ffile))[-1];
				my $fsql = "SELECT * FROM file WHERE file_title = ?";
				my $fsth = $dbh->prepare($fsql);
				$fsth->execute($filename);
				if (my $file = $fsth->fetchrow_hashref()) {
					print "File $file->{file_title} exists in the file table<br>";
				} else {
					print "File $ffile does not exist in the file table<br>";
				}
			}
		} else {
			print "No files to upload<br>";
		}

		print "</ul></p>";

	}


	exit;

}



# Print HTML Page header
	print &admin_header();



# Actions ------------------------------------------------------------------------------

	# Perform Action, or





	if ($action) {

		for ($action) {
			#print "Action: $action <p>";												# Main admin menu nav

			/start/ && do { &admin_start($dbh,$query); last;			};	# 	- Start Menu
			/general/ && do { &admin_general($dbh,$query); last;			};	# 	- General Menu
			/harvester/ && do { &admin_harvester($dbh,$query); last;		};	# 	- Harvester Menu
			/users/ && do { &admin_users($dbh,$query); last;			};	# 	- Users Menu
			/newsletters/ && do { &admin_newsletters($dbh,$query); last;	};		#	- Newsletters Menu
			/database/ && do { &admin_database($dbh,$query); last;		};		#	- Database Menu
			/meetings/ && do { &admin_meetings($dbh,$query); last;		};		#	- Meetings Menu
			/logs/ && do { &admin_logs($dbh,$query); last;		};			#	- Logs Menu
			/accounts/ && do { &admin_accounts($dbh,$query); last;		};		#	- Accounts Menu
			/permissions/ && do { &admin_permissions($dbh,$query); last;		};	#	- Permissions Menu




															# Editing Functions

			/list/ && do { &admin_list_records($table); last;		};		#	- List records
			/edit/i && do { &edit_record($dbh,$query,$table,$id); last; 	};		#	- Edit Record - Show the Editing form
			/update/ && do { &update_record($dbh,$query,$table,$id);
				&edit_record($dbh,$query,$table, $id_number);last; };		# 	- Edit Record - Update with input data
			/Delete/i && do	{ &record_delete($dbh,$query,$table,$id);last; };		#	- Delete Record
			/Spam/i && do { &record_delete($dbh,$query,$table,$id);  last; };		#	- Delete Record and log creator IP to Spam
			/multi/i && do { &admin_multi($dbh,$query); last;		};		#	- Multi-Delete Record (FIXME needs work)
			/add_rcomment/i && do {&add_rcomment($dbh,$query); last; };					# Remote Comment
			/rcomment/i && do {&rcomment($dbh,$query); last; };					# Remote Comment


															# Feed Functions

			/approve/i && do { &record_approve($dbh,$query,$table,$id); last; };		#	- Approve Feed
			/retire|reject/i && do { &record_retire($dbh,$query,$table,$id); last; };	#	- Reject / Retire Feed


															# Site Configuration

			/config/ && do { &admin_update_config($dbh,$query); last;	};		#	- Update config data
			/export_table/ && do { &admin_db_export($dbh,$query); last;	};		#	- export a table
			/db_pack/ && do {&admin_db_pack($dbh,$query); last;		};		#	- Make a new pack
			/db_add_column/ && do { my $msg = &db_add_column($vars->{stable},$vars->{col});
				&showcolumns($dbh,$query,$msg); last; };				#	- Add new column to a table
			/removecolumnwarn/ && do { &removecolumnwarn($dbh,$query); last; };		#	- Remove column - warn user
			/removecolumndo/ && do { &removecolumndo($dbh,$query); last; };			#	- Remove column - remove it
			/make_search_forms/ && do { print &make_search_forms($dbh,$query); exit; last; };	 #Make search form templates 


															# Newsletter and Page Functions

			/publish/ && do {
					if ($table eq "badge"){ &publish_badge($dbh,$query,$id,"verbose"); last;}
					else { &publish_page($dbh,$query,$vars->{page},"verbose"); last; } };
	    /verify_email/ && do { &admin_verify_emails(); last; };
			/rollup/ && do { &news_rollup($dbh,$query); last;			};	#	- Show posts allocated to future newsletters
			/autosub/ && do { &autosubscribe_all($dbh,$query); last;   };			#	- Auto-subscribe all users to newsletter
			/autounsub/ && do { &autounsubscribe_all($dbh,$query); last; };			#	- Auto-unsubscribe all users from newsletter
			/send_nl/ && do { &send_nl($dbh,$query); last;	};				#	- Send newsletter to email subscribers
			/sharing/ && do { &share_graph($dbh,$query); last;	};				#	- Send newsletter to email subscribers

															# Cron Tasks (FIXME make a separate file? )

			/rotate/ && do { &rotate_hit_counters($dbh,$query,"post"); last;};		#	- Reset daily hits counter to '0'

			/remove_key/ && do { &remove_key($dbh,$query,$table,$id);
				&edit_record($dbh,$query,$table,$id); last;};

													#		# Database Functions

			/backup_db/ && do { &admin_db_backup($vars->{backup_table},"verbose"); last; };	#	- Back up database
			/showcolumns/ && do { &showcolumns($dbh,$query); last; };			#	- Show the columns in a table
			/add_table/ && do { admin_db_add_table($vars->{add_table}); last; };		#	- Add table
			/drop_table/ && do { admin_db_drop_table($vars->{drop_table}); last; };		#	- Drop table

			/fixmesubs/ && do { &fixmesubs($dbh,$query,$table); last;		};

	                       # API Functions
			/admin_api/ && do { &admin_api($dbh,$query); last; };	
	    	/access_api/ && do { &access_api($dbh,$query); last; };

			/export_users/ && do { &export_user_list($dbh,$query); last;			};
			/import/ && do { &import($dbh,$query,$table); last;		};
			/remove_all/ && do { &delete_all_users($dbh,$query); last; };


			/youtubepost/ && do { &parse_youtube($dbh,$query); last; };
			/autopost/ && do { &autopost($dbh,$query); last; };
			/postedit/ && do { &postedit($dbh,$query); last; };

			/eduser/ && do { &admin_users_edit($dbh,$query); last;			};
			/subs/ && do { &edit_subs($dbh,$query); last;			};

												 # Analyze
			/analyze_text/ && do {
				&analyze_text($table,$id); last; };
			/extract_nouns/ && do {
				&extract_nouns($table,$id); last; };
			/show_graph/ && do {
				&show_graph($table,$id); last; };

			/make_icon/ && do { &auto_make_icon($table,$id);
					&edit_record($dbh,$query,$table,$id); last;};
			/logview/ && do { &log_view($dbh,$query); last; };
			/logreset/ && do { &log_reset($dbh,$query); last; };
			/reindex_topics/ && do { &reindex_topics($dbh,$query,$id); last; };
			/refield/ && do { &refield($dbh,$query); last; };
			/recache/ && do { &recache($dbh,$query); last; };
			/reindex/ && do { &reindex_matches($dbh,$query,$table,$id); };

			/count/ && do { &count_feed($dbh,$query); last; };

			/cache_clear/ && do { &cache_clear($dbh,$query); last; };
			#/stats/ && do { &calculate_stats($dbh,$query); last;  };
			/graph/ && do { &make_graph($dbh,$query); last;  };
			/sendmsg/ && do { &admin_users_send_message($dbh,$query); last; };
			/moderate_meeting/ && do { &moderate_meeting($dbh,$query); last;			};	# 	- General
			/test_rest/ && do { api_send_rest($dbh,$query); last; };
			/cstats/ && do { &calculate_cstats($dbh,$query); last; };


								# External APIs

			/get_favicon/ && do { &favicon_generate($vars->{image_file},
				$vars->{border},$vars->{background}); last; };
			/favicon_button/ && do { &favicon_button($vars->{image_file}); };
			/mailchimp/ && do { &mailchimp($dbh,$query); last; };

		}

	# Output Record, or

	} elsif ($table) {					# Default Data Output

		&output_record($dbh,$query,$table,$id,$format);

	} 
	
	# Previous processes should all terminate internally; this is the default
	# Show Admin Menu
	$vars->{admin_pane} ||= "general";
	my $admin_function = "admin_".$vars->{admin_pane};		
	my $admin_content = eval{ &$admin_function($dbh,$query) };

	exit; # And we're done
	
	

	#---------------------------------------------------------------------------------------------
	#
	#                 Functions
	#
	#---------------------------------------------------------------------------------------------










	# -----------------------------------   Admin: Config Table   -----------------------------------------------

	sub admin_configtable {

		my ($dbh,$query,$title,@vals) = @_;

		my $content = qq|
			<div class="menubox">
			<h3>$title</h3>
			<div class="adminpanel">
			<ul><form method="post" action="$Site->{st_cgi}admin.cgi">
			<input type="hidden" name="action" value="config">
			<input type="hidden" name="title" value="$title">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">
		|;

		foreach my $v (@vals) {
			my ($t,$v,$f,$o,$h) = split ":",$v;    # Title, variable name, format, default, help #"

			$content .= qq|
			   <div class="option_div">
			   <span class="option_title">$t</span>
			   <span class="option_input">|;

			if ($f eq "yesno") {
				my $yesselected=""; my $noselected="";
				if ($Site->{$v} eq "yes") { $yesselected = qq| selected="selected"|; }
				else { $noselected = qq| selected="selected"|; }

				$content .= $title_td . qq|
				<select name="$v">
				<option value="yes" $yesselected >Yes</option>
				<option value="no" $noselected >No</option>
				</select>
				\n|;

			} elsif($f eq "dir") {
				my $vfval; $vfval = $Site->{$v} || $o;
				$content .= qq|$Site->{st_urlf}<input type="text" size="60" name="$v" value="$vfval">|;
			} elsif($f eq "url") {
				my $vuval; $vuval = $Site->{$v} || $o;
				$content .= qq|$Site->{st_url}<input type="text" size="60" name="$v" value="$vuval">\n|;
			} else {
				my $vval; $vval = $Site->{$v} || $f;
				$content .= qq|<input type="text" size="60" name="$v" value="$vval">\n|;
			}
			$content .= qq|</span><span class="option_help">$h</span></div>|;
		}


		$content .= qq|<p><input type="submit" class="button" value="Submit $title"></p>|;
		$content .= "</form></ul>
			</div></div>\n";


	}

	# -----------------------------------   Admin: Start   -----------------------------------------------
	#
	#  Start screen for gRSShopper PLE
	#
	# ------------------------------------------------------------------------------------------------------

	sub admin_start {

		   my ($dbh,$query) = @_;

			 &admin_frame($dbh,$query,"Welcome to gRSShopper","Welcome to gRSShopper");					# Print Output
		 	exit;

	}

	# -----------------------------------   Admin: General   -----------------------------------------------
	#
	#   Initialization and editing of general site configuration data
	#   Expects and requires access to a 'config' table in the database
	#   The config table in turn is used by init_site() in grsshopper.pl
	#
	# ------------------------------------------------------------------------------------------------------

	sub admin_general {

		my ($dbh,$query) = @_;
		$Site->{admin_pane}	= "general";
		# Heading
	    my $content = "<h1>".&printlang("General Information")."</h1>";


		# Sections
		$content .= &admin_update_grsshopper($dbh,$query);

        $content .= &admin_cron($dbh,$query);

		$content .= &admin_configtable($dbh,$query,"Site Information",
			("Site Name:st_name","Site Tag:st_tag","Site Image:st_image","Site Logo:st_logo","Site Icon:st_icon","Email:st_email","Description:st_desc","Publisher:st_pub","Creator:st_crea","License:st_license","Time Zone:st_timezone","Reset Key:reset_key"));

		$content .= &admin_configtable($dbh,$query,"Base URLs and Directories",
			("Base URL:st_url","Base Directory:st_urlf","CGI URL:st_cgi","CGI Directory:st_cgif","Login URL:st_login"));

		$content .= &admin_configtable($dbh,$query,"Media Directories incl. AWS",
			("Images:st_img","Photos:st_photo","Files:st_file","Icons:st_icon","Audio:st_audio","Slides:st_slides"));

		$content .= &admin_configtable($dbh,$query,"Upload Directories",
			("Uploads:st_upload","Images:up_image","Documents:up_docs","Slides:up_slides","Audio:up_audio","Videos:up_video"));

		&admin_frame($dbh,$query,"Admin General",$content);					# Print Output
		exit;



	}



	sub admin_api {

		my ($dbh,$query) = @_;

		$Site->{admin_pane}	= "api";

		my $content = qq|<h1>Access API</h1>
		<div style="float:left;width:25%">
		<form method="post" action="">
		 <input type="hidden" name="action" value="access_api">
		<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">
		 URL: <input type="text" name="url" id="apiurl" style="width:95%;" value="$Site->{st_cgi}api.cgi"><br>
		 JSON:<br> <textarea style="width:95%;height:340px;" id="postdata" name="postdata">
	{
	 "cmd": "list",
	 "table": "page"
	}
		 </textarea>
		 <input type="submit" onClick="
		 	alert(document.getElementById('postdata').value);
			fetch(document.getElementById('apiurl').value,{
        		method: 'POST', // or 'PUT'
        		headers: {
          			'Content-Type': 'application/json',
        		},
        		body: document.getElementById('postdata').value,
      		})
	        .then(response => response.json())
    	    .then(function (data) {
				var myJSON = JSON.stringify(data);
				document.getElementById('api_result').innerHTML = myJSON;
				// alert(data.metadata.testing);
            	// appendData(request,data);
        	})
        	.catch((error) => {
				document.getElementById('api_result').innerHTML = error;
            	//console.error('Error:', error);
				}
      		);


		 	
			return false;
		 ">
		 </form></p>
		 </div>
		 <div id="api_result" style="width:70%;border:solid black 1px;float:left;">Result</div>
	   |;

	   print $content;

		exit;



	}









	# -----------------------------------   Admin: Accounts   -----------------------------------------------
	#
	#  
	#   Set values label:name using the admin_accounts panel
	#   Access values from $Site->{name}
	#
	# ------------------------------------------------------------------------------------------------------


	sub admin_accounts {

		my ($dbh,$query) = @_;
		$Site->{admin_pane}	= "accounts";
		return unless (&is_viewable("admin","accounts")); 		# Permissions

		my $content = qq|<h2>Accounts</h2><p>These values control access information to external accounts.</p>|;

		$content .= &admin_configtable($dbh,$query,"S3",
			("S3 Account:s3_account","Key:s3_key","Secret:s3_secret","Bucket:s3_bucket"));

		$content .= &admin_configtable($dbh,$query,"S3files",
			("S3 Account:s3f_account","Key:s3f_key","Secret:s3f_secret","Bucket:s3f_bucket"));

		$content .= &admin_configtable($dbh,$query,"Twitter",
			("Twitter Account:tw_account","Post to Twitter:tw_post:yesno","Use Site Hashtag:tw_use_tag:yesno","Consumer Key:tw_cckey","Consumer Secret:tw_csecret","Token:tw_token","Token Secret:tw_tsecret"));

		$content .= &admin_configtable($dbh,$query,"Facebook",
			("Facebook Account:fb_account","Post to Facebook:fb_post:yesno","Use Site Hashtag:fb_use_tag:yesno","Application ID:fb_app_id","Application Secret:fb_app_secret","Postback URL:fb_postback_url","Access Code:fb_code","Access Token:fb_token","Authorization URL:fb_auth_url"));

		$content .= &admin_configtable($dbh,$query,"Mastodon",
			("Mastodon Instance:mas_instance","Post to Mastodon:mas_post:yesno","Use Site Hashtag:mas_use_tag:yesno","Client ID:mas_cli_id","Client Secret:mas_cli_secret","Access Token:mas_acc_token"));
		$content .= qq|To fill this form, login to Mastodon and then <a href="https://takahashim.github.io/mastodon-access-token/">get access token</a><br>|;

		$content .= &admin_configtable($dbh,$query,"Bluesky",
			("Bluesky Instance:blue_instance","Post to Bluesky:blue_post:yesno","Use Site Hashtag:blue_use_tag:yesno","Handle:blue_handle","App Password:blue_app_pass","API Key:blue_api_key"));
		$content .= qq|To fill this form, login to Bluesky and then <a href="https://takahashim.github.io/mastodon-access-token/">get access token</a><br>|;

		$content .= &admin_configtable($dbh,$query,"MailChimp",
			("MailChimp Account:mailchimp_account","API Key:mailchimp_apikey","Datacenter:mailchimp_datacenter","API URL:mailchimp_url","API Version:mailchimp_version","Test List ID:mailchimp_test"));

		$content .= &admin_configtable($dbh,$query,"RealFaviconGenerator",
			("API Key:realfavicon_apikey"));
		$content .= qq|<a href="https://realfavicongenerator.net">RealFaviconGenerator</a>|;

		$content .= &admin_configtable($dbh,$query,"MailGun",
			("API Key:mailgun_apikey","Domain:mailgun_domain","Locale:mailgun_locale"));
		$content .= qq|<a href="https://www.mailgun.com/">MailGun</a> (Locale is either EU or US)|;

		$content .= &admin_configtable($dbh,$query,"Amazon SES",
			("SMTP User:ses_smtp_user","SMTP Password:ses_smtp_password","SMTP Server:ses_smtp_server"));
		$content .= qq|<a href="https://us-east-1.console.aws.amazon.com/ses/">Amazon SES console</a>
			(Server defaults to email-smtp.us-east-1.amazonaws.com if left blank)<br>
			<b>Bounce/complaint notifications:</b> After setting up SES, you must configure SNS to forward
			bounces and complaints to this server. In the SES console go to
			<i>Verified identities &rarr; your domain &rarr; Notifications</i> and set both Bounce and Complaint
			topics to an SNS topic that has an HTTPS subscription pointing to
			<tt>$Site->{st_cgi}api.cgi?cmd=ses_bounce</tt>.
			This is required to suppress bad addresses and stay compliant with anti-spam rules.|;
			
		$content .= &admin_configtable($dbh,$query,"LinkedIn Publisher",
			("Publisher URL:li_publisher_url","Publish Token:li_publisher_token",
			 "LinkedIn Email:li_email","LinkedIn Password:li_password",
			 "Newsletter Name:li_newsletter_name"));
		$content .= qq|Triggers a LinkedIn newsletter post after each real OLDaily send.
			Set Publisher URL to <tt>http://linkedin_publisher:5000/publish</tt> when the container is running.
			Leave blank to disable. (Credentials currently read from container .env; these fields are for future use.)|;


		$content .= &admin_configtable($dbh,$query,"Badgr",
			("Badgr API base URL:badgr_url","Badgr Account ID (email):badgr_account","Badgr Account Password:badgr_password","Access Key:badgr_cckey","Issuer ID:badgr_issuerid"));
    $content .= sprintf(qq|To create and award badges, <a href="https://badgr.io/auth/login">create a Badgr account</a> and input email address and password above. The Base URL is usually https://api.badgr.io and the Access key is automatically generated.
       However, before badges are awarded, a Badge Issuer must be created; <a href="%sadmin.cgi?action=badgr&badgr=issuer">Click here</a> to generate an Issuer
       automatically.|,$Site->{st_cgi});

		&admin_frame($dbh,$query,"Admin Accounts",$content);					# Print Output
		exit;


	}

	# -----------------------------------   Admin: Cron   ------------------------------------------------------
	#
	#   Display cron status (running / errors)
	#
	# ---------------------------------------------------------------------------------------------

	sub admin_cron {

		my ($dbh,$query) = @_;

	    my $croncolor; my $croncontent;
	    if ($Site->{cronerr} eq "none") { 
			$croncontent = "Cron OK"; 
			$croncolor = "green";
		} else { 
			$croncontent = $Site->{cronerr};
			$croncolor = "red";
		}

		
		my $content = qq|<div class="menubox"><h3>Cron Status</h3><p>
		 <ul><table cellspacing="0" cellpadding="2" border="0">
		 <tr><td style="background-color:$croncolor">&nbsp;&nbsp</td>
		 <td>$croncontent</td><td>&nbsp;</td><td>
		 <a href="|.$Site->{st_cgi}.qq|admin.cgi?action=logview&logfile=cronlog">
		 View Cron Log</a></td></tr></table></ul></div>|;

		


	    return $content;

		exit;



	}

	# -----------------------------------   Admin: Permissions   -----------------------------------------------
	#
	#   View and Set Default Permissions
	#
	# ------------------------------------------------------------------------------------------------------



	sub admin_harvester {

		my ($dbh,$query) = @_;

		return unless (&is_viewable("admin","harvester")); 		# Permissions
		$Site->{admin_pane}	= "harvester";
		my $content = qq|<h2>Harvester</h2><p>On this page you can manage and operate your harvester. To turn
			on automated harvesting, set 'Enable Harvester' to 'yes' (requires cron). The harvester will
			process one feed every 'Harvester Interval' minutes. To add, manage and delete content sources,
			create, edit and delete feeds (see the menu at left) or use the OPML options below.</p>|;

		my $harvesterlink = $Site->{st_cgi}."harvest.cgi";
		my $edursslink = $Site->{st_cgi}."edurss02.cgi";

											# Harvester Controls
		$content .= &admin_configtable($dbh,$query,"Enable Harvester",
		("Enable Harvester:st_harvest_on:yesno","Harvester Interval:st_harvest_int","Feed Cache Location:feed_cache_dir"));

											# Audio Download Controls
		my $default_audio_download = "dir:files/podaudio/";
		my $default_playlist_file = "url:files/podaudio/playlist.pls";
		$content .= &admin_configtable($dbh,$query,"Audio Harvesting",
		("Download Audio:st_audio_dl:yesno","Make Playlist:st_audio_pl:yesno","Audio File Directory:audio_download_dir:$default_audio_download",
			"Audio Playlist File:audio_playlist_file:$default_playlist_file","Files Expire (in days):audio_files_expire:1"));


		# Get Feed List
		my $feedselector = qq|<option value="0">Please select a feed from the list....</option>\n|;
		my $sql = qq|SELECT feed_id,feed_title,feed_status from feed ORDER BY feed_title|;
		my $sth = $dbh -> prepare($sql);
		$sth -> execute();
		while (my $feed = $sth -> fetchrow_hashref()) {
			$feed->{feed_title} = substr($feed->{feed_title},0,45);
			$feedselector .= qq|<option value="$feed->{feed_id}">$feed->{feed_title} ($feed->{feed_status})</option>\n|;
		}

		$content .= qq|

			<h3>Operate Harvester</h3>
			<form method="post" action="harvest.cgi">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">
			<ul>
			<input type="radio" name="source" value="queue" selected> Harvest Next In Queue<br/>
			<input type="radio" name="source" value="feed"> Harvest Feed: <select name="feed">$feedselector</select>
			<br/>
			<input type="radio" name="source" value="url"> Harvest URL:
			<input type="text" name="url" placeholder="Enter full URL here" size="40"><br/>
			<input type="radio" name="source" value="file"> Harvest File:
			<input type="text" name="file" placeholder="File name, file needs to be in same directory as script (for now)" size="40"><br/>
			<input type="radio" name="source" value="all"> Harvest All<br/>
			<input type="radio" name="action" value="document"> Scrape Document:
			<input type="text" name="document_url" placeholder="Enter full URL here" size="40"><br/><br/>
			<input type="submit" class="button" value="Harvest">
			</ul>
			</form>


			<h3>View Harvest Results</h3>
			<p><ul>
			<li><a href="$Site->{cgi}page.cgi?action=viewer">Viewer</a></li>
			</ul></p>

			<h3>Import and Export Feeds</h3>|;

		if (&new_module_load($query,"XML::OPML")) {
			$content .= qq|
			<p><ul>
			<li><a href="|.$Site->{st_cgi}.qq|harvest.cgi?action=export">Export OPML File</a></li>
			<li> <a href="$harvesterlink?action=opmlopts">Import Feed List From OPML</a>
			</ul></p>|;
		} else {
			$content .= $vars->{error};
		}

		&admin_frame($dbh,$query,"Admin General",$content);					# Print Output
		exit;

	}

	# -----------------------------------   Admin: Users   -----------------------------------------------
	#
	#   Manage Users
	#
	# ------------------------------------------------------------------------------------------------------



















	sub admin_update_config {

		my ($dbh,$query,$silent,$config) = @_;
		return unless (&is_allowed("edit","config"));

		while (my ($vx,$vy) = each %$vars) { $config->{$vx} = $vy; }
		unless ($config) { print "No config information received."; return; }
		&update_config_table($dbh,$config,1);
        return;
		
	}

# --------------------------------------   Update Config -----------------------------------------------
#
#    Accept input from other process updates the config table
#    based on values found in $%config
#
#	 Note that setting $reset to 1 will reset all $Site variables, meaning that if any are
#    changed during previous execution (eg. $Site->context}) it will have to be captured
#    and reset after.
#
# ------------------------------------------------------------------------------------------------------

sub update_config_table {

	my ($dbh,$config,$reset) = @_;

		# Update Config Table

		while (my ($vx,$vy) = each %$config) {

			next if ($vx =~ /^(action|mode|cronsite|format|button|force|comment|id|title|mod_load|msg|test)$/);

			my $sth; my $sql;
			if (&db_locate($dbh,"config",{"config_noun" => $vx})) {	# Existing

				$sql = qq|UPDATE config SET config_value=? WHERE config_noun='$vx'|;
				$sth = $dbh->prepare($sql)  or die "Cannot prepare: " . $dbh->errstr();
				$sth->execute($vy) or die "Cannot execute: " . $sth->errstr();
			} else {

				$sql = "INSERT INTO config (config_noun,config_value) VALUES (?,?)";
				$sth = $dbh->prepare($sql)  or die "Cannot prepare: " . $dbh->errstr();
				$sth->execute($vx,$vy) or die "Cannot execute: " . $sth->errstr();
			}
			$sth->finish();

			# Status Message
			$vars->{msg} .= "$vars->{title} : $vx has been set to $vy <br/>";

		}


		# Reload Site Data
		if ($reset) {
			my $sth = $dbh -> prepare("SELECT * FROM config"); $sth -> execute();
			while (my $c = $sth -> fetchrow_hashref()) { $Site->{$c->{config_noun}} = $c->{config_value}; }
			$sth->finish();
		}

		return 1;

}


# --------------------------------------   Update gRSShopper -----------------------------------------------
#
#    Option to calls a shell script that downloads most recent gRSShopper code from
#    GitHub and installs it in cgi-bin
#
# ------------------------------------------------------------------------------------------------------


sub admin_update_grsshopper{

	my ($dbh,$query) = @_;

	return unless (&is_viewable("admin","update")); 		# Permissions

  	my $update_string = "";
  	my $local_version = &read_text_file($Site->{cgif}.'version.txt') || "Cannot read version file: $?";
	my $remote_version = get("https://raw.githubusercontent.com/Downes/gRSShopper/master/version");

#	if ($local_version eq  $remote_version) {
#    	$update_string = "gRSShopper is up to date at version $local_version."
#	} else {
		$update_string = qq|<p>Update needed. Local version is $local_version and master version is $remote_version</p>
			<button
			onClick="update_grsshopper('$Site->{st_cgi}'+'api.cgi?cmd=gRSShopper_update')">Update gRSShopper</button>|;
#	}

	return qq|<div class="menubox">

		<h3>Update gRSShopper</h3>
		<script src="$Site->{st_url}/assets/js/jquery.js"></script>
		<script>
		function update_grsshopper(url) {


			\$('#gRSShopper_update').load(url, function(response, status, xhr) {
	        if (status == "error") {
	            var msg = "Sorry but there was an error: ";
	            alert(msg + xhr.status + " " + xhr.statusText);
	        }
	     });

		}

		</script>
		<p><ul>
		<div id="gRSShopper_update">$update_string</div>
		</ul></p>

	</div>|;

}



	# -------   Admin Menu: Courses   -----------------------------------------------

	sub admin_courses {

		return unless (&is_viewable("admin","courses")); 		# Permissions

		return qq|<div class="menubox">

			<h4>Courses</h4>
			<p><ul>
			<li><a href="course.cgi">My Courses</a></li>
			</ul>

		</div>|;

	}






	# -------   Admin Menu: graph ---------------------------------------------

	sub admin_graph {

		return unless (&is_viewable("admin","graph")); 		# Permissions
		my $adminlink = $Site->{st_cgi}."admin.cgi";


		return qq|<div class="menubox">

			<h4>Graph</h4>



			<ul>
			<b>Generate Graph</b><br/>
			<form method="post" action="$adminlink">
			<input type="hidden" name="action" value="graph">
			<input type="hidden" name="admin_pane" value="$Site->{admin_pane}">			
			<input type="submit" value="Generate" class="button">
			</form>
			</ul>

		</div>|;

	}


	# -------   Export User List --------------------------------------------------------























	
















	sub make_heading {
		my ($script) = @_;
		return unless ($script->{heading});
		my $heading = "";
		if ($script->{format} =~ /txt/) { $heading = "\n\n$script->{heading}\n\n"; }
		else {	$heading = "<h1>$script->{heading}</h1>\n"; }
		return $heading;
	}

	sub make_next_link {
		my ($dbh,$vars,$options,$person,$script) = @_;
		my @optlist; my $optstring;
		while (my($ox,$oy) = each %$script) { my $st = "$ox=$oy"; push @optlist,$st; }
		$optstring = join ";",@optlist;
		return "http://www.downes.ca/cgi-bin/page.cgi?".$optstring;
	}





	# -------  DB Creator IP ------------------------------------------------------------

	# Returns the creator IP for a record given table and IP
	# Used to delete spam

	sub db_record_crip {

		my ($dbh,$table,$value) = @_;
		return unless ($value);					# Never compare blank values
		my $stmt = "SELECT ".$table."_crip FROM $table WHERE ".$table."_id='$value'";
		my $ary_ref = $dbh->selectcol_arrayref($stmt);
		return $ary_ref->[0];
	}




	sub day_today {

		# What day is it Today? Return the name of the day
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		my @days = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
		return $days[$wday];
	}



	# -------   Capitalize ---------------------------------------------------------

	# For titles
	# Adapted from Joseph Brenner >  Text-Capitalize >  Text::Capitalize
	# http://search.cpan.org/~doom/Text-Capitalize/Capitalize.pm

	sub capitalize {

		my $sentence = shift;
	return $sentence;
		$sentence =~ s/&apos;/'/ig;				# '
		$sentence =~ s/&#39;/'/ig;
		my $words; my @words;

		my $title = shift; my $first; my $last;
		my $new_sentence;

									# Defines a word array
		my $word_rule =  qr{ ([^\w\s]*)   			# $1 - leading punctuation
	                   ([\w']*) #'   				# $2 - the word itself
	                   ([^\w\s]*)  					# $3 - trailing punctuation
	                   (\s*)       					# $4 - trailing whitespace
	                 }x ;

									# Define exceptions
		my @exceptions = qw(a an the and or nor for but so yet
			to of by at for but in with has de von);
		my $exceptions_or = join '|', @exceptions;
		my $exception_rule = qr/^(?:$exceptions_or)$/oi;

		my $i = 0;						# Extract Words
		while ($sentence =~ /$word_rule/g) {
			if ( ($2 ne '') or $1 or $3 or ($4 ne '') ) {
				$words[$i] = [$1, $2, $3, $4];
				$i++;
			}
		}

		$first = 0;						# For each word...
		$last = @words+0;
		for (my $i=$first; $i<=$last; $i++) {
			my $punct_leading; my $word; my $punct_trailing; my $spc;
	       		{  						# Spoof 'continue'
			if ($i >= 0){ $punct_leading = $words[$i]; } else { $punct_leading = ""; }
			$word = $words[$i];
			$punct_trailing = $words[$i+1];
			$spc = $words[$i+2];

	#		($punct_leading, $word, $punct_trailing, $spc) = ( @{ $words[$i] } );

			$_ = $word;

			next if ( /[[:upper:]]/ );			# Skip special caps eg. iMac
			next if ( /^[[:upper:]]+$/);

			if ( /^[dl]'/) { #'				# Skip special french cases
				s{ ^(d') (\w) }{ lc($1) . uc($2) }iex;
				s{ ^(l') (\w) }{ lc($1) . uc($2) }iex;
				if ( ($i == $first) or ($i == $last) ) {
					$_ = ucfirst;
				}
				next;
			}

			if ( ($i == $first) or ($i == $last) ) {	# Capitalize first and last
				$_ = ucfirst( lc );
				next;
			}

	 								# Skip exceptions
			if ( /$exception_rule/ ) {
				$_ = lc;
			} else {
				$_ = ucfirst( lc );			# Cap the rest
			}

	       		} continue {
									# Append word to title
				$new_sentence .=  $punct_leading . $_ . $punct_trailing . $spc;
			}

		}  # end of per word for loop

		# Fix upper-case contractions
		$new_sentence =~ s/(\S')(\S)/$1\l$2/ig;
		$new_sentence =~ s/'/&#39;/ig;  #'

		return $new_sentence;
	}


	sub moderate_meeting {

		my ($dbh,$query) = @_;
		my $vars = $query->Vars;

		unless ($vars->{meeting_name}) { $vars->{meeting_name} = "Administrator Meeting"; }
		unless ($vars->{meeting_id}) { $vars->{meeting_id} = "12345"; }


		&bbb_join_as_moderator($vars->{meeting_id},$Person->{person_name},$Person->{person_title});

		exit;



	}

	sub admin_header {
		return if ($Site->{context} eq "cron");
		my $assets = $Site->{st_url}."assets";
		return qq|
			<html>
			<head>
				<title>Admin $vars->{action} </title>
				<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/mini.css/3.0.1/mini-default.min.css">
				<link rel="stylesheet" href="$assets/css/grsshopper_admin.css">
				<!-- Scripts -->
				<!-- JQuery -->
				<script src="$assets/js/jquery.min.js"></script>
				<!-- JQuery UI -->
				<script src="$assets/js/jquery-ui.min.js"></script>
				<!-- JQuery ToggleButton -->
				<script src="$assets/js/select-togglebutton.js"></script>
				<!-- CK Editor -->
				<script src="//cdn.ckeditor.com/4.7.0/standard/ckeditor.js"></script>
				<script src="//cdn.ckeditor.com/4.7.0/basic/adapters/jquery.js"></script>
				<!-- File Upload -->
				<script src="https://hayageek.github.io/jQuery-Upload-File/4.0.11/jquery.uploadfile.min.js" defer></script>
				<!-- DateTime Picker -->
				<script src="$assets/js/jquery.datetimepicker.full.min.js"></script>
				<!-- Font-Awesome -->
				<script src="https://kit.fontawesome.com/bf62bb2348.js"crossorigin="anonymous"></script>
				<script src="$assets/js/grsshopper_admin.js"></script>
			</head>
			<body>
			<div id="spinner-donut" class="spinner-donut"></div>
		|;


	}


	
	sub fix_graph() {

		#   Submissions will include info about authors, feeds, etc.
		#   Values for these other records are submitted in $vars and always have the prefix 'keyname_'
		#   For example, a field named 'keyname_author' will refer to the name of an author in the 'author' table
		#   The function produces a record in the graph table
		#   It will also create a new record in the other table, if necessary

	print "Posts.<p>";
		my $sth = $dbh->prepare("SELECT * FROM post");
		$sth -> execute();
		my $ccount=0; my $articles;my $comments; my $links; my $other;
		while (my $c = $sth -> fetchrow_hashref()) {
			$ccount++;
			if ($c->{post_type} =~ /article/) { $articles++; }
			elsif ($c->{post_type} =~ /link/) { $links++; }
			elsif ($c->{post_type} =~ /comment/) { $comments++; }
			else { $other++; }
			next unless ($c->{post_type} =~ /link/);
			#last if ($ccount > 5);
			$c->{post_author} =~ s/Reviewed by//i;
			$c->{post_author} =~ s/, eds\.//i;
			print qq|$ccount : |.$c->{post_id}.qq| (|.$c->{post_type}.qq|) |.$c->{post_title}.qq|, |;
			print qq||.$c->{post_authorname}.qq|, |;
			print qq||.$c->{post_author}.qq|<br>|;
			print qq||.$c->{post_journal}.qq|<br>|;

			$c->{keyname_author} = $c->{post_author};
			$c->{keyname_feed} = $c->{post_journal};
		&record_graph($dbh,$c,"post",$c);					# Save Graph Records
		}
		print "<p>Links: $links  Comments:  $comments  Articles: $articles  Other: $other <p>";
		$sth->finish();

	exit;

	}






	sub mastodon {

		return unless (&new_module_load($query,"Mastodon::Client"));

	    my $client = Mastodon::Client->new(
	      instance        => $Site->{mas_instance},
	      name            => 'gRSShopper',
	      client_id       => $Site->{mas_cli_id},
	      client_secret   => $Site->{mas_cli_secret},
	      access_token    => $Site->{mas_acc_token},
	      coerce_entities => 1,
	    );

	    $client->post_status('Posted to a Mastodon server! From gRSShopper.');
	    $client->post_status('And now in secret...',
	      { visibility => 'unlisted' }
	    );

	    # Streaming interface might change!
	    my $listener = $client->stream( 'public' );
	    $listener->on( update => sub {
	      my ($listener, $status) = @_;
	      printf "%s said: %s\n",
	        $status->account->display_name,
	        $status->content;
	    });
	    $listener->start;

	}


	#my $url = "$endpoint/$listid/members/" . Digest::MD5::md5(lc($email));

	# -------  Republish Records -----------------------------------------------------------
	#
	#   Republish records in batch mode - this allows me to make changes to templates
	#   and then republish existing content to reflect those changes
	#   in a way that won't overwhelm the server. Called from cron_tasks()
	# -----------------------------------------------------------------------------------
   sub republish {

      my ($rtable,$batch) = @_;

      $batch ||= 10;
	  if ($rtable eq "post") { $batch=1000;}
      my $count = 0;

	  # Log the republish action and arguments
      &log_cron(8,sprintf("Republishing %s batch of %d records",$rtable,$batch));
      while ($count < $batch) {


#&send_email("stephen\@downes.ca","stephen\@downes.ca","Republish","\nRepub: $rtable $reppub\n");

			# Get crdate of previous item published 

			#my $reppub_indexfile = "/home/downesca/ethics.mooc.ca/cgi-bin/data/".$rtable."_repubindex.txt";
			my $reppub_indexfile = $Site->{st_cgif}. "data/".$rtable."_repubindex.txt";
			my $reppub;
			if (-e $reppub_indexfile) { $reppub = &get_file($reppub_indexfile); }
			unless ($reppub) { $reppub = 0; }

				

			# Find the next record id and crdate, and print it 
			my $nextsql = "SELECT ".$rtable."_id,".$rtable."_crdate FROM $rtable WHERE ".$rtable."_crdate >'".$reppub."' ORDER BY ".$rtable."_crdate LIMIT 1";
			my ($newprevid,$newprevcrdate) = $dbh->selectrow_array($nextsql);

			# Print record number id if it exists
			if ($newprevid) { 
				# But only print it if it has *already* been published - this function is
				# intended to update existing content, not generate new content
				# and may create permissions problems if cron is creating new files
				my $page_file = $Site->{st_urlf}.$rtable."/".$newprevid;
				#if (-e $page_file) { 
					&print_record($rtable,$newprevid);	
					&log_cron(8,sprintf("Republished %s ",$page_file));
				#}
				$reppub = $newprevcrdate;
			} else { $reppub = 0; }

			# Save item crdate
			# print "Site is ".$Site->{st_cgif}."\n\nFile is $reppub_indexfile \n\n";
			open FILE, ">$reppub_indexfile" or &log_cron(1,sprintf("Cannot open %s : %s",$reppub_indexfile,$!));
			print FILE $reppub or &log_cron(1,sprintf("Cannot print to %s : %s",$reppub_indexfile,$!));
			close FILE;
            $count++;
      }
	  return 1;
}




	# -----------------------------------   Admin: Logs   -----------------------------------------------
	#
	#   View Logs
	#
	# ------------------------------------------------------------------------------------------------------


	sub admin_logs {

		my ($dbh,$query) = @_;

		return unless (&is_viewable("admin","logs")); 		# Permissions


		my $content .= &admin_configtable($dbh,$query,"Logging Options",
			("Log Level (0-10):st_log_level","Refresh interval (days):st_log_refresh"));

		$content .= qq|<h2>View Logs</h2><p>
			General Statistics -
			[<a href="admin.cgi?action=logview&logfile=General Stats&format=table">Table</a>]
			[<a href="admin.cgi?action=logview&logfile=General Stats&format=tsv">TSV</a>]
			[<a href="admin.cgi?action=logview&logfile=General Stats&format=csv">CSV</a>]<br/>
			Cron Logs - [<a href="admin.cgi?action=logview&logfile=cronlog">Text File</a>]
			</p>|;




		&admin_frame($dbh,$query,"Admin General",$content);					# Print Output
		exit;



	}

	