#!/usr/bin/perl -w

use lib 'modules/lib/perl5';
binmode STDOUT, ':utf8';
our $mimetype = "application/json";
# Print OK for blank api request
    use CGI;
	use CGI::Carp qw(fatalsToBrowser);    
			use JSON;
			use JSON::Parse 'parse_json';
use File::Path qw(make_path);
use File::Spec;
use Sys::Syslog qw(:standard :macros); 



#    gRSShopper 0.7  API 0.01  -- gRSShopper api module
#    30 December 2017 - Stephen Downes

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

#-------------------------------------------------------------------------------
#
#	    gRSShopper
#           API Functions
#
#-------------------------------------------------------------------------------

  


# Forbid bots

	if ($ENV{'HTTP_USER_AGENT'} =~ /bot|slurp|spider/) {
		print "Status: 403 Forbidden\r\n";
		print "Content-Type: text/plain\r\n\r\n";
		print "403 Forbidden\n";
		exit;
	}

# Load gRSShopper
  use strict;
	use File::Basename;
	use CGI::Carp qw(fatalsToBrowser);
    eval("use local::lib;");  # sets up a local lib at ~/perl5, fails silently if it's impossible
	use Fcntl qw(:flock SEEK_END);
	my $dirname = dirname(__FILE__);
	require $dirname . "/grsshopper.pl";
	require $dirname . "/api/metadata.pl";
	require $dirname . "/api/utils.pl";
	require $dirname . "/api/publish.pl";
	require $dirname . "/api/database.pl";
	require $dirname . "/api/keylist.pl";
	require $dirname . "/api/update.pl";
	require $dirname . "/api/files.pl";
	require $dirname . "/api/hub_bookmarklet.pl";
	require $dirname . "/api/hub_feed.pl";
	require $dirname . "/api/hub_images.pl";
	require $dirname . "/api/list.pl";

# Load modules and set query and vars

	our ($query,$vars) = &load_modules("api");

# Load Site

	our ($Site,$dbh) = &get_site("api");

# Load User

	my ($session,$username) = &check_user("text/html");
	our $Person = {}; bless $Person;

	&get_person($Person,$username);

	my $person_id = $Person->{person_id};
	&show_login($session);


	# If there is a file being uploaded, we have to handle the file before writing the session cookie
	# So we'll do that here, leaving the uploaded file object location as the value of $vars->{file}


	my $file;
	if (($query->content_type() // '') =~ 'multipart/form-data') {
		my $session = new CGI::Session(undef, $query, {Directory=>'/tmp'});	# Must be logged in to upload
		&status_error("No uploads unless logged in") unless ($session->param("~logged-in"));
		$vars->{file} ||= "myfile";
		$file = &upload_file($vars->{file});
	}

	if (($vars->{cmd} // '') =~ /edit|autopost/) { $mimetype = "text/html"; }



 	# Allow use of db and table interchangeably
	if ($vars->{source} && $vars->{target}) { $vars->{cmd} = "webmention"; }
	$vars->{db} ||= $vars->{table};
	$vars->{table} ||= $vars->{db};

# Get Post Data
  our $request_data; our $request_type;
 # my $postdata = $query->param('POSTDATA');
	my $postdata = $query->param('POSTDATA');
	if ($postdata) {
	#	print "Content-type:application/json\n\n";


		# Convert input HTML entities into utf8
		$postdata =~ s/&amp;|&#38;/&/g;
		$postdata =~ s/&#38;/&/g;
		decode_entities($postdata) or &status_error("Failed to decode entities. $! $?");


			$request_type = "post";
			# Parse the JSON Data
			use JSON;
			use JSON::Parse 'parse_json';
			$vars = eval { parse_json($postdata) };
			if ($@)
			{
			#	print "Content-type:application/json\n\n";
    			&status_error("parse_json failed, invalid json. error:$@\n");
			}
			#$vars = parse_json($postdata);
			# CGI.pm doesn't parse query string for application/json POSTs — read it directly
		$vars->{cmd} ||= $1 if $ENV{QUERY_STRING} =~ /(?:^|&)cmd=([^&]+)(?:&|$)/;
			$request_data = $vars;

			#exit;
	}



# Load Site






# -------------------------------------------------------------------------------------
#          Public App Functions
#
# These are requests put to the app to offer some sort of form or interaction
#
# -------------------------------------------------------------------------------------

	# Zenodo
	# Show
	if ($vars->{cmd} eq "show" && ($vars->{table} eq "link" || $vars->{table} eq "feed")) {

   		$vars->{format} = "json";
		my ($metadata,$data) = &list_records($vars->{table},{cmd=>"show",$vars->{table}."_id"=>$vars->{id}});
		my $json = to_json $data;
   		# my $json = encode_json $data;
   		print $json;
		exit;
	}

	# List / Search — delegates to api_list() in api/list.pl
	if ($vars->{cmd} eq "list") { &api_list($vars->{table}); }



  # LOGIN
	if ($vars->{cmd} eq "login") {
		print "Content-type: text/html\n\n";
		 print &api_login();
		 exit;
	}

	#################################################
	# Commands handled by /api/subscribe.pl

	# SUBSCRIBE FORM
	elsif ($vars->{cmd} eq "subform") {
		print "Content-type: text/html\n\n";
		 print &api_subscription_form();
		 exit;
	}

  # SUBSCRIBE
	elsif ($vars->{cmd} eq "subscribe") {
		print "Content-type: text/html\n\n";
		 print &api_subscribe();
		 exit;
	}

	# UNSUBSCRIBE FORM
	elsif ($vars->{cmd} eq "unsubform") {
		print "Content-type: text/html\n\n";
		 print &api_unsubscribe_form();
		 exit;
	}

	# UNSUBSCRIBE
	elsif ($vars->{cmd} eq "unsubscribe") {
		print "Content-type: text/html\n\n";
		 print &api_unsubscribe();
		 exit;
	}

	# CONFIRM
	elsif ($vars->{cmd} eq "confirm") {
		print "Content-type: text/html\n\n";
		 print &api_confirm();
		 exit;
	}

	# SES BOUNCE/COMPLAINT WEBHOOK
	elsif ($vars->{cmd} eq 'ses_bounce') {
		print "Content-type: application/json\n\n";
		&api_ses_bounce($query);
		exit;
	}

	#################################################


  # START
  elsif ($vars->{cmd} eq "start") {
		print "Content-type: text/html\n\n";
		my @tabs = split",",$vars->{tabs};
		unless (@tabs) { @tabs = ('Database');}
			 #{}print qq|<textarea cols=60 rows=60>|;
			 print &main_window(\@tabs,$tabs[0]);
			#{} print qq|</textarea>|;
			 exit;
  }


	# SHOW
  elsif ($vars->{cmd} eq "show") {
	    #print "Content-type: text/html\n\n";
		print &api_show_record(); exit;
	}

# LINKEDIN
elsif ($vars->{cmd} eq "linkedin") {

	&linkedin_post();

}

# ----- Admin endpoint: build shards on demand -----
# Example: /cgi-bin/api.cgi?build_shards=1&scheme=100&dry_run=0
elsif ($vars->{cmd} eq "build_shards") {

    my $docroot = $vars->{st_urlf};
    # OPTIONAL: protect this endpoint!
    # e.g., require a shared secret or limit by IP
    # my $secret = $q->param('secret') // '';
    # return send_error($q,"Unauthorized") unless $secret eq 'something-long-and-random';

    my $rd_base = "$docroot/_rd";                # host-scoped shard base
    my $scheme  = $vars->{scheme} // 100;    # 100 => 781/57 ; 1000 => 78/157
    my $dry_run = ($vars->{dry_run} // 0) ? 1 : 0;

    my $report = build_shards($dbh, rd_base => $rd_base, scheme => $scheme, dry_run => $dry_run);

    # Return a plain-text report
    print $query->header(-type => 'text/plain; charset=UTF-8');
    print $report;
    closelog();
    exit 0;
}
elsif ($vars->{cmd} eq "print_all_records") {
    my $itemlist = "";
    my $table = $vars->{table} // 'post';
    $table =~ m/^[a-z_]+$/i or die "Bad table name";
    my $pk = "${table}_id";

    my $start_id  = $vars->{start_id};
    my $end_id    = $vars->{end_id};
    $start_id = ($start_id && $start_id =~ /^\d+$/) ? 0 + $start_id : undef;
    $end_id   = ($end_id   && $end_id   =~ /^\d+$/) ? 0 + $end_id   : undef;

    my $batch_size = $vars->{batch_size};
    $batch_size = (defined $batch_size && $batch_size =~ /^\d+$/) ? 0 + $batch_size : 500;
    $batch_size = 1    if $batch_size < 1;
    $batch_size = 5000 if $batch_size > 5000;

    # RENAMED: use 'cursor' instead of 'after_id' to avoid matching 'id='
    my $cursor = $vars->{cursor};
    $cursor = (defined $cursor && $cursor =~ /^\d+$/) ? 0 + $cursor : 0;

    my $auto = $vars->{auto};
    $auto = (!defined $auto || $auto =~ /^[1y]/i) ? 1 : 0;  # default ON

    # WHERE clause (range + cursor)
    my @where; my @bind;
    if (defined $start_id) { push @where, "$pk >= ?"; push @bind, $start_id; }
    if (defined $end_id)   { push @where, "$pk <= ?"; push @bind, $end_id;   }
    push @where, "$pk > ?"; push @bind, $cursor;

    my $sql = "SELECT $pk FROM $table";
    $sql .= " WHERE " . join(" AND ", @where) if @where;
    $sql .= " ORDER BY $pk ASC LIMIT ?";
    push @bind, $batch_size;

    my $sth = $dbh->prepare($sql);
    $sth->execute(@bind);

    my (@ids, $last_id, $ok, $fail) = ((), $cursor, 0, 0);
    while (my ($id) = $sth->fetchrow_array) { push @ids, 0 + $id; }
    $sth->finish;

    for my $id (@ids) {
        $last_id = $id if $id > $last_id;
        my $res;
        my $ok_this = eval {
            # ensure numeric
            $res = print_record($table, 0 + $id, 'html', undef);
            1;
        };
        if ($ok_this) {
            $ok++;
            $itemlist .= "$table, $id, $res\n";
        } else {
            $fail++;
            # (optional) capture first few errors during troubleshooting
            # my $e = $@ // 'unknown error'; ... print or collect if desired
        }
    }

    my $done = 0;
    $done = 1 if @ids < $batch_size;
    $done = 1 if (defined $end_id && $last_id >= $end_id);

    my $script = $ENV{SCRIPT_NAME} || '/cgi-bin/api.cgi';
    my @qs = ("cmd=print_all_records", "table=$table", "batch_size=$batch_size", "cursor=$last_id", "auto=$auto");
    push @qs, "start_id=$start_id" if defined $start_id;
    push @qs, "end_id=$end_id"     if defined $end_id;
    my $next_url = "$script?" . join("&", @qs);

    print "Content-type: text/html; charset=UTF-8\n";
    print "X-Accel-Buffering: no\n\n";
    print "<!doctype html><meta charset='utf-8'>\n";
    print "<title>print_all_records</title>\n";
    print "<style>body{font-family:system-ui,Segoe UI,Roboto,Helvetica,Arial,sans-serif;margin:16px}pre{white-space:pre-wrap}</style>\n";
    if ($auto && !$done) {
        print "<meta http-equiv='refresh' content='0;url=$next_url'>\n";
    }
    print "<pre>\n";
    print "print_all_records batch complete\n";
    print "Table:       $table\n";
    print "Range:       " . (defined $start_id && defined $end_id ? "$start_id..$end_id" : "ALL") . "\n";
    print "Processed:   " . scalar(@ids) . " in this batch\n";
    print "Succeeded:   $ok\n";
    print "Failed:      $fail\n";
    print "Last ID:     $last_id\n";
    print "\nItems:\n$itemlist";
    if ($done) {
        print "\nALL DONE ✅\n";
    } else {
        print "\nNext URL:    $next_url\n";
        print "Auto-advance: " . ($auto ? "ON" : "OFF") . "\n";
        print "Click the link above to continue if auto is off.\n";
    }
    print "</pre>\n";
    exit 0;
}



  # WEBMENTION

  elsif ($vars->{cmd} eq "webmention") {


 		&record_sanitize_input($vars);
		if ($vars->{source} =~ /$Site->{st_url}/) { print "Source domain the same as target."; exit;}
    unless ($vars->{source}) { print "Webmention request incomplete. Needs to specify source URL"; exit; }
		unless ($vars->{target}) { print "Webmention request incomplete. Needs to specify target URL"; exit; }

    # Verify that my (target) URL exists
    my ($table,$id) = &parse_my_url($vars->{target});
    unless (&db_locate($dbh,$table,{$table."_id" => $id})) { print "Webmention error. Resource not found."; exit;}

		# Verify that source links to target url
		my $content = get($vars->{source});
    if ($content =~ /<a(.*?)href="$vars->{target}"(.*?)>/) {    # Found it

				# If necessary, create link record
				my $link_id = &db_locate($dbh,"link",{link_link => $vars->{source}});
				$link_id ||= "new";
				my $link_link = $vars->{source}; $link_link =~ s/'//; #'

				# Get a title
				my $link_title;
				if ($content =~ m/<title>(.*?)<\/title>/si) {
					$link_title = $1; $link_title =~ s/'/&apos;/g;    #'
				}

				%$vars = ();					# Clear all input data, to prevent injection
				$vars->{link_link} = $link_link;
				$vars->{link_id} = $link_id;
				$vars->{link_title} = $link_title;
				$vars->{link_crdate} = time;
				$link_id = &record_save($dbh,$vars,"link",$vars);

				# Create graph record linking target and Source
				if ($link_id) {
					&graph_add($table,$id,"link",$link_id,"webmention","");
					print "Accepted";
					exit;
				} else {
					print "Webreference error: could not save data.";
					exit;
				}
    }  else {
			print "Webreference error: source does not link to target.";
			exit;
		}

		print "Webreference error.";
		exit;

	}

	elsif ($vars->{cmd} eq "harvester-commands") {

		unless ($vars->{id}) { print "Need to provide a feed id."; exit;}
		my $record = &db_get_record($dbh,"feed",{feed_id=>$vars->{id}});
		my $table = "feed";
		my $status = $record->{$table."_status"};
		my $link = $record->{$table."_link"};
		my $harvestlink = $Site->{st_cgi}."harvest.cgi";
		print &harvester_commands($vars->{id},$status,$harvestlink,$link);
		exit;
	}







if ($vars->{cmd} eq "authenticate") {

	if ($Person->{person_status} =~ /admin|Admin/) { print 1; } else { print 0; }
	exit;

}

	
# Admin Only
#	unless (&admin_only()) { &status_error("Admin Login Required"); }
	
# List Tables
	
	if ($vars->{cmd} eq "list_tables") { 
		print &list_tables(); exit; 
	}




# Done updating


# -------------------------------------------------------------------------------------
#          Create Functions
#
# 		   Create major new elements in the database
#		   Input variables: obj  - the type of thing to be created (eg. table, )
#			                name - the name of the thing to be created (eg., 'Hotels')
#
# -------------------------------------------------------------------------------------

if ($vars->{cmd} eq "create") {
   	if ($vars->{obj} eq "table") {
		&status_error("Thing to create not defined") unless ($vars->{obj});
		&status_error("Name of the $vars->{obj} to create not defined") unless ($vars->{name});
		$vars->{name} =~ s/[^a-zA-Z0-9_-]//g;
		&db_create_table($dbh,$vars->{name});

		my $apilink = $Site->{st_cgi}."api.cgi";

		$vars->{message} .= "Creating table $vars->{name} " .
		sprintf(qq|<a href="#" onClick="
			openTab(event, 'editor', 'mainlinks');
			openDiv('%s','editor','edit','form','','%s','mainWindowTable');
			">Edit the New Table</a>|,$apilink,$vars->{name});
		&status_ok();
		exit;

    }
}

# -------------------------------------------------------------------------------------
#          Graph Functions
#
#
# -------------------------------------------------------------------------------------

if ($vars->{cmd} eq "graph_submit") {

	my $msg; my $nodes;
	my $t1 = $vars->{t1}; my $t2 = $vars->{t2};
	while (my ($vx,$vy) = each %$vars) {
		#$msg .= "$vx = $vy \n";
		if ($vx eq "nodes") { 
			foreach my $n (@$vy) { 
				next if ($n->{rgb} eq "#ff0000");
				#next if ($n->{rgb} eq "#808080");
				#next if ($n->{rgb} eq "#ccdddd");
				next if ($n->{rgb} eq "#ffbbbb");	
				$n->{label} =~ s/\xC3;/&apos;/g;			
				$nodes->{$n->{id}} = $n->{label};
			} 
		}
		if ($vx eq "graph") { 
			foreach my $n (@$vy) { 
				next unless ($nodes->{$n->{n1}} && $nodes->{$n->{n2}});
				$msg .= $nodes->{$n->{n1}}." --- ".$nodes->{$n->{n2}}." \n"; 
			}
		}
		if ($t1 && $t2) {
			if ($vx =~ /^$t1(.*?)$t2(.*?)$/) {
				$msg .= "$t1 $1 --- $t2 $2 \n"; 
				graph_add($t1,$1,$t2,$2,"user",1);
			} elsif ($vx =~ /^$t2(.*?)$t1(.*?)$/) {
				$msg .= "$t2 $1 --- $t1 $2 \n"; 
				graph_add($t2,$1,$t1,$2,"user",1);				
			}

		}
	}

	open OUT,">>data/graphupdate.txt";
	print OUT $msg;
	close OUT;
		$vars->{message} = "Your graph was submitted successfully. You added:\n\n".$msg;
	&status_ok();
	exit;

}


# -------------------------------------------------------------------------------------
#          Editor Functions
#
# 		   Produce an Editor screen for a given table + id
#
# -------------------------------------------------------------------------------------





if ($vars->{cmd} eq "edit") {

	unless ($vars->{table} ) { print "Table to $vars->{cmd} has not been specified."; exit; }
	my $tabs = [];

	if ($vars->{autopost} > 0) { &api_autopost($vars->{autopost}); }
	if ($vars->{table} eq "person" && $vars->{id} eq "me") { 
		$vars->{id} = $Person->{person_id}};		# Edit myself
	if ($vars->{id} eq "new") {
		$vars->{id} = &make_new_record($vars->{table});
	}
	# Candidate images gathered client-side (bookmarklet DOM scan, feed
	# thumbnail, or feed content HTML) - the bookmarklet scrape below may
	# add its own og:image/twitter:image find to the same list.
	my $images = [];
	if ($vars->{images}) {
		use JSON::Parse 'parse_json';
		eval { $images = parse_json($vars->{images}); };
		$images = [] unless (ref($images) eq 'ARRAY');
	}

	my $report;
	if ($vars->{hub} eq "yes") {				# Autopost from bookmarklet - scrape the source page
		$report = &api_hub_bookmarklet($vars->{id},$vars->{url},$images);
	} elsif ($vars->{hub} eq "feed") {			# Autopost from feed reader - use feed metadata, no page fetch
		$report = &api_hub_feed($vars->{id});
	}
	$images = &sanitize_images($images);

	my $starting_tab = $vars->{starting_tab} || "Edit";
	print &main_window($tabs,$starting_tab,$vars->{table},"$vars->{id}",$vars);
print &render_image_picker($vars->{id},$images);
print qq|<textarea cols=80 rows=20>$report</textarea>|;
print qq|OK THEN<div id="mySidenav"><div id="closeNav"></div></div>|;

	exit;

}





# -------------------------------------------------------------------------------------
#          Update Functions
#
#   Submit or modify content
#
# -------------------------------------------------------------------------------------


# cmd: remove
# Removes an item from a graph list
# Expects table, id, key, keyid, optional div
# Returns revised graph list of key for table id
if ($vars->{cmd} eq "remove") { &api_keylist_remove(); }

# cmd: newOption
# Adds a new option to the end of optlkist for table $table and column $col
# Then inserts that option as a value for record $table $id
if ($vars->{cmd} eq "newOption") { 

	unless ($vars->{table} && $vars->{id} && $vars->{col}) { &status_error("Missing table, id or column"); }
	unless ($vars->{value}) { &status_error("Please create text for the new option");}
	&status_error("Option name ".$vars->{value}." can only contain up to 30 alphanumeric characters") 
		unless ($vars->{value} =~ /^[\p{Alnum}\s_-]{0,30}\z/ig);

	# Check for dumplicate and rewrite optlist list
	my $opts = &db_get_record($dbh,"optlist",{optlist_title=>$vars->{col}});
	my @opts = split ";",$opts->{optlist_data}; 
	foreach my $opt (@opts) {
		my ($oname,$ovalue) = split ",",$opt;
		&status_error("This is a duplicate. Just click on the $ovalue button.") 
			if ($ovalue =~ /^$vars->{value}$/i);
	}
	push @opts,$vars->{value}.",".$vars->{value};	# We'll just name the option name the option
	$opts->{optlist_data} = join ';',@opts;
	&db_update($dbh,"optlist",{optlist_data=>$opts->{optlist_data}},$opts->{optlist_id});

	# Opdate the value for the record
	&db_update($dbh,$vars->{table},{$vars->{col}=>$vars->{value}},$vars->{id});
	$vars->{message} = "Added ".$vars->{value}." for ".$vars->{table}.$vars->{id};
	&status_ok();
}


if ($vars->{cmd} eq "update") {

	# Restrict to Admin
    unless (&admin_only()) { &status_error("Admin Login Required"); }
	
	#print qq|{"response":"hello"}|; exit;
	# Verify Data
	&status_error("Table name not provided") unless ($vars->{table_name} || $vars->{table});
	&status_error("Table ID not provided") unless ($vars->{table_id} || $vars->{id});
	# die "Column name not provided" unless ($vars->{col_name});
	#die "Input value not provided" unless ($vars->{value});
	&status_error("Input type not provided") unless ($vars->{type} || $vars->{field});

	&record_sanitize_input($vars);

	# Identify update by type
	my $type = $vars->{type} // '';
	if ($type eq "text" ||
		$type eq "textarea"  ||
		$type eq "wysihtml5" ||
		$type eq "select") {
			&status_ok() if (&api_textfield_update($vars));
		}

	elsif ($vars->{type} eq "password") {
		&api_password_update(); 
	}

	elsif ($vars->{type} eq "keylist") { 
		my ($key_graph_list,$newlist) = &api_keylist_update($vars);
		&status_ok($key_graph_list,$newlist);
	}



	# record publish
	elsif ($vars->{type} eq "data") { &api_data_update();  }

	# file upload
	elsif ($vars->{type} eq "file") { &api_file_upload($file); }

	# url upload
	elsif ($vars->{type} eq "file_url") { &api_url_upload(); }

	# column create
	elsif ($vars->{type} eq "column") { &api_column_create(); }

	# column update
	elsif ($vars->{type} eq "alter") { &api_column_alter(); }

	# column remove
	elsif ($vars->{type} eq "column_remove") { &api_column_remove(); }

	# commit
	elsif ($vars->{type} eq "commit") { &api_commit(); }

	# Simple one-field update, returns JSON
	elsif ($vars->{field}) { &status_ok() if (&api_textfield_update($vars)); } 

	exit;
}

# -------------------------------------------------------------------------------------
#          Delete Functions
#
#    These are requests to delete a record
#		Note that record_delete() also removes graph entries pointing to 
#		the deleted record
#
# -------------------------------------------------------------------------------------

if ($vars->{cmd} eq "delete") {

	my $apilink = $Site->{st_cgi}."api.cgi";
	unless ($vars->{table}) { &status_error("Table to delete has not been specified."); }
	unless ($vars->{id}) { &status_error("ID number to delete has not been specified."); }

	&record_delete($dbh,$query,$vars->{table},$vars->{id},"silent");
			# Back up table
		  #my $savemsg = &api_backup($vars->{table});

			# Drop table
			#my $dropmsg = &db_drop_table($dbh,$vars->{table});
	$vars->{message} .= ucfirst($vars->{table})." has been deleted";
	status_ok();
	exit;

}

# -------------------------------------------------------------------------------------
#          Publish Functions
#
#    These are requests put to the app to publish contents somewhere
#
# -------------------------------------------------------------------------------------


if ($vars->{cmd} eq "publish") {

	# Publish Page
	if ($vars->{table} eq "page") {


		&publish_page($dbh,$query,$vars->{id},"",$vars->{export});  # Information stored in $vars->{message}
		&status_ok();								# and returned as {... ,"message":$vars->{message}}
		exit;
	}

	# Publish Graph

	if ($vars->{table} eq "graph") {
		&publish_graph($dbh,$query,$vars->{id},"");  # Information stored in $vars->{message}
		&status_ok();								# and returned as {... ,"message":$vars->{message}}
		exit;

	}



	&api_publish();
	exit;
	
	#&status_error("Publishing account not found");
}

# -------------------------------------------------------------------------------------
#          List Functions
#
#     Add or remove elements from stored lists, useful for multi-step operations
#     
#     Commands always begin with 'array'
#
# -------------------------------------------------------------------------------------

if ($vars->{cmd} eq "arrayAdd") { &arrayAdd($vars->{term},$vars->{list}); &status_ok(); }
if ($vars->{cmd} eq "arrayRemove") { &arrayRemove($vars->{term},$vars->{list}); &status_ok(); }


# -------------------------------------------------------------------------------------
#          Backup Functions
#
#     Create backups of database tables and make these available for download
#     (or possibly sharing, we'll see)
#     Looks for a table name in $vars->{table} or it might be 'all'
#
# -------------------------------------------------------------------------------------

if ($vars->{cmd} eq "backup") { 
	
	unless ($vars->{table}) { &status_error("API need a table name to know what to backup"); }
	$vars->{message} = &api_backup();
	&status_ok(); 
}


# -------------------------------------------------------------------------------------
#          Dump Functions
#
#    Just dump the record into an HTML display
#    Should probably be merged with show at some point
#
# -------------------------------------------------------------------------------------

if ($vars->{cmd} eq "dump") {

	&status_error("Table not specified") unless ($vars->{table});
	&status_error("Record ID not specified") unless ($vars->{id});

	my $record = &db_get_record($dbh,$vars->{table},{$vars->{table}."_id" => $vars->{id}});
	&status_error("This ".$vars->{table}." does not exist.") unless ($record);

	my $output = qq|<div tabindex="0" role="button" class="btn" aria-pressed="false" 
		onclick="document.getElementById('record-dump').style.display='none';">Hide
		</div>|.
		"<p>Table: $vars->{table} <br />ID: $vars->{id}</p><p>";
	while (my($dx,$dy) = each %$record) {
		$output .= qq|<b>$dx</b>: $dy <br>|;
	}
	$output .= "</p>";
		
	&status_ok($vars->{div},$output);

}

# -------------------------------------------------------------------------------------
#          Clone Functions
#
#    These are requests put to the app to make a copy of something
#
# -------------------------------------------------------------------------------------

if ($vars->{cmd} eq "clone") {

   	unless ($vars->{table}) { &status_error("Don't know which table to clone."); }
   	unless ($vars->{id}) { &status_error("Don't know which ".$vars->{table}." ID to clone."); }
	my $record = &db_get_record($dbh,$vars->{table},{$vars->{table}."_id" => $vars->{id}});
	$record->{$vars->{table}."_title"} = sprintf(qq|Copy of "%s"|,$record->{$vars->{table}."_title"});
	$record->{$vars->{table}."_name"} = sprintf(qq|Copy of "%s"|,$record->{$vars->{table}."_name"});
	my $id = &make_new_record($vars->{table},$record);

	$vars->{message} .= "Cloning ".$record->{$vars->{table}."_title"}.": ".
		qq|Created new <a href="|.$Site->{st_url}.$vars->{table}.qq|/$id" target="_new">|.
		$vars->{table}.qq| number $id</a> |.
		qq|[<a href="#" onclick="openDiv('$Site->{script}','editor','edit','$vars->{table}','$id','Edit');">Edit</a>]|;
	&status_ok();
	exit;
}

# -------------------------------------------------------------------------------------
#          Analyze Link Functions
#
#    These are requests to analyze a remote URL and return metadata
#
# -------------------------------------------------------------------------------------

if ($vars->{cmd} eq "analyze_link") {
	&status_error("The 'analyze_link' command requires a 'link' to analyze") unless ($vars->{link});
	&analyze_link($vars->{link});
	exit;
}
# -------------------------------------------------------------------------------------
#          Admin Functions
#
# This is the interface to admin.cgi
# Though I'd like to evolve that over time
#
# -------------------------------------------------------------------------------------

if ($vars->{cmd} eq "admin") {

# print qq|{"cmd":"|.$vars->{cmd}.qq|","app":"|.$vars->{app}.qq|","db":"|.$vars->{db}.qq|"}|; 

		my $starting_tab = $vars->{db} || "Database";
		print &main_window(['Database','API','Harvester','Newsletters','Users','Permissions','Logs','General'],$starting_tab);
	 	exit;
	}


# Show Columns
# called in the database eduting functions
if (($vars->{cmd} eq "show_columns") || ($vars->{app} eq "show_columns")) {

#print qq|{"cmd":"|.$vars->{cmd}.qq|","app":"|.$vars->{app}.qq|","db":"|.$vars->{db}.qq|"}|;

		&status_error("No table defined for show_columns()") unless ($vars->{table});
		print &show_columns($vars->{table},$vars->{msg});
	 	exit;
	}




# SOCIAL
if ($vars->{cmd} eq "social") {


		my $starting_tab = $vars->{db} || "Accounts";
		print &main_window(['Sharing','Subscribers','Newsletters','Accounts','Meetings'],$starting_tab);
		exit;
	}


# -------------------------------------------------------------------------------------
#          App Functions
#
# These are requests put to the app to offer some sort of form or interaction
#
# -------------------------------------------------------------------------------------




if ($vars->{app}) { $vars->{cmd} = $vars->{app}; }        #  temporary
if ($vars->{db}) { $vars->{table} = $vars->{db}; }        #  temporary
if ($vars->{cmd} eq "list_tables") { $vars->{cmd} = "list"; $vars->{obj}="tables"; }


my $cmd = $vars->{cmd};
my $table = $vars->{table};


# COMMANDS

if ($vars->{cmd}) {




	# IMPORT
  if ($vars->{cmd} eq "import") {
		unless ($vars->{table} ) { print "Table to $vars->{cmd} has not been specified."; exit; }
		my $tabs = ['Import','Export'];
		my $starting_tab = $vars->{starting_tab} || "Import";
		print &main_window($tabs,$starting_tab,$vars->{table},"none",$vars);
		exit;
	}

	# HARVEST
  elsif ($vars->{cmd} eq "harvest") {
		unless ($vars->{table} ) { print "Table to $vars->{cmd} has not been specified."; exit; }
		unless ($vars->{id} ) { print ucfirst($vars->{table})." to $vars->{cmd} has not been specified."; exit; }
		my $tabs = ['Harvest'];
		my $starting_tab = $vars->{starting_tab} || "Harvest";
		print &main_window($tabs,$starting_tab,$vars->{table},"$vars->{id}",$vars);
		exit;
	}

	# DROP
	elsif ($vars->{cmd} eq "drop") {
		if ($vars->{obj} eq "table") {

			my $apilink = $Site->{st_cgi}."api.cgi";
			unless ($vars->{table}) { print "Table to $vars->{cmd} has not been specified."; exit; }

			# Back up table
		  my $savemsg = &api_backup($vars->{table});

			# Drop table
			my $dropmsg = &db_drop_table($dbh,$vars->{table});

		  print qq|$savemsg <br>$dropmsg|;
			exit;


		}
	}




	# PUBLISHING
  elsif ($vars->{cmd} eq "publishing") {
		my $starting_tab = $vars->{starting_tab} || "Newsletters";
		print &main_window(['Subscribers','Newsletters','Accounts','Meetings'],$starting_tab);
		exit;
	}







	# GRSSHOPPER UPDATE
	elsif ($vars->{cmd} eq "gRSShopper_update") {
    	my $version = get("https://raw.githubusercontent.com/Downes/gRSShopper/master/version");
		my $update_script = $Site->{st_cgif}."update/update.sh";

		print "Update script: $update_script <p>";
		print `chmod 755 $update_script`;
		print `$update_script 2>&1` || "Can't get a response from $update_script <br>";
		
		my $version_text_file = $Site->{st_cgif}."version.txt";
		print "gRSShopper Version text file: $version_text_file <p>";
		my $printstatus = &write_text_file($version_text_file,$version);
		unless ($printstatus eq "1") { print $printstatus; exit; }
		print "Updated to version $version";
    	exit;
	}

	&status_error("Command '$vars->{cmd}' not recognized.");
	

}







# API LOGIN ----------------------------------------------------------
# ------- ------------------------------------------------------------
#
# Receives login credentials
# Writes login cookies
#
# -------------------------------------------------------------------------

sub api_login {

	  my $login_error = &printlang("Login error")."<br/>".
		    &printlang("Try again",$Site->{st_cgi}."login.cgi")."<br>".
		    &printlang("Recover registration",$Site->{st_cgi}."login.cgi?refer=$vars->{refer}&action=Email");

		# Check Input Variables
		unless (($vars->{person_title}) && ($vars->{person_password})) { print $login_error; exit;	}

		# Create query (email or title)
		my $stmt;
		if ($vars->{person_title} =~ /@/) {
			$vars->{person_email} = $vars->{person_title};
			$stmt = qq|SELECT * FROM person WHERE person_email = ? ORDER BY person_id LIMIT 1|;
		} else {
			$vars->{person_title} = $vars->{person_title};
			$stmt = qq|SELECT * FROM person WHERE person_title = ? ORDER BY person_id LIMIT 1|;
		}

    # Execute Query
		my $sth = $dbh -> prepare($stmt);
		$sth -> execute($vars->{person_title});
		my $ref = $sth -> fetchrow_hashref();

		# Eerror if Data not found
		unless ($ref) { print $login_error; exit; }

		# Password Check
		unless ($ref->{person_password} eq crypt($vars->{person_password}, $ref->{person_password})) { print $login_error; exit; }	# Salted crypt match

    # Successful Login. Reset 'Person' values.
		while (my($x,$y) = each %$ref) { $Person->{$x} = $y; }
    $sth->finish(  );

    # Define Cookie Names
		my $site_base = &get_cookie_base();
		my $id_cookie_name = $site_base."_person_id";
		my $title_cookie_name = $site_base."_person_title";
		my $session_cookie_name = $site_base."_session";
		my $admin_cookie_name = $site_base."_admin";

		my $exp; 							# Expiry Date
		if ($vars->{remember}) { $exp = '+1y'; }
		else { $exp = '+1h'; }

										# Session ID
		my $salt = $site_base . time;
		my $sessionid = crypt("anymouse",$salt); 			# Store session ID in DB
		&db_update($dbh,"person",{person_mode => $sessionid}, $Person->{person_id},&printlang("Setting session",$Person->{person_id}));

		# Admin Cookie
		# Not secure; can be spoofed, use only to create links
    my $admin_cookie_value = "";
    if ($Person->{person_status}  eq "admin") { $admin_cookie_value="admin"; }
    else { my $admin_cookie_value="registered"; }

		return qq|{"site_base":"$site_base",
			  "person_id": "$Person->{person_id}",
				"person_title": "$Person->{person_title}",
				"session": "$sessionid",
				"admin": "$admin_cookie_value"}|;

		# User is successfully logged in, reload the page now

   exit;
}









# Print OK for blank api request

$vars->{message} .= qq|No command submitted or executed|; 
&status_ok();
	
exit;

# API OK & error responses are in grsshopper.pl
# see status+ok() and status_error()

