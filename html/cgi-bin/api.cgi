#!/usr/bin/perl -w
use CGI;
use CGI::Carp qw(fatalsToBrowser);
# Print OK for blank api request


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

	die "HTTP/1.1 403 Forbidden\n\n403 Forbidden\n" if ($ENV{'HTTP_USER_AGENT'} =~ /bot|slurp|spider/);


# Load gRSShopper
  use strict;
	use File::Basename;
	use CGI::Carp qw(fatalsToBrowser);
    eval("use local::lib;");  # sets up a local lib at ~/perl5, fails silently if it's impossible
	use Fcntl qw(:flock SEEK_END);
	my $dirname = dirname(__FILE__);
	require $dirname . "/grsshopper.pl";
	require $dirname . "/api/metadata.pl";
	use JSON;





# Load modules

	our ($query,$vars) = &load_modules("api");
 	$vars->{db} ||= $vars->{table};
	$vars->{table} ||= $vars->{db};
  	if ($vars->{source} && $vars->{target}) { $vars->{cmd} = "webmention"; }



# Get Post Data
  our $request_data; our $request_type;
  my $postdata = $query->param('POSTDATA');
	#my $postdata = $query->param('POSTDATA');
	if ($postdata) {
		#print "Content-type:application/json\n\n";
		#print $postdata; exit;
			$request_type = "post";
			# Parse the JSON Data
			use JSON;
			use JSON::Parse 'parse_json';
			$vars = eval { parse_json($postdata) };
			if ($@)
			{
				print "Content-type:application/json\n\n";
    			&status_error("parse_json failed, invalid json. error:$@\n");
			}
			#$vars = parse_json($postdata);
			$request_data = $vars;

			#exit;
	}



# Load Site




	our ($Site,$dbh) = &get_site("api");


#print "Content-type: text/html\n\n";
#while (my($vx,$vy) = each %$vars) { print "$vx = $vy <br>"; }                      #"





# -------------------------------------------------------------------------------------
#          Public App Functions
#
# These are requests put to the app to offer some sort of form or interaction
#
# -------------------------------------------------------------------------------------



	# Show
	if ($vars->{cmd} eq "show" && ($vars->{table} eq "link" || $vars->{table} eq "feed")) {

		print "Content-type: text/json\n\n";
   		$vars->{format} = "json";
		my ($metadata,$data) = &list_records($vars->{table},{cmd=>"show",$vars->{table}."_id"=>$vars->{id}});
   		my $json = encode_json $data;
   		print $json;exit;
	}

	# List (is also search)
	my $listsearch;
	if ($vars->{cmd} eq "list") {

		# Set up input parameters
		
		while (my($vx,$vy) = each %$vars) {
		#	if ($vx =~ /category|genre|status|section|class|type/) {  	# Parameters for filter
				$listsearch->{$vx} = $vy; 
		#	}
		}
		if ($vars->{qkey} && $vars->{qval}) {						  	# Text search input
			$listsearch->{$vars->{qkey}} = $vars->{qval};
		}

		# for now...
		print "Content-type: text/json\n\n";
   		$vars->{format} = "json";

$listsearch->{$vars->{qkey}} = $vars->{qval};
																		# get search result
   		my ($metadata,$data) = &list_records($vars->{table},$listsearch);

#die "Testing: ".$metadata->{testing}."\n";	
$metadata->{$vars->{qkey}} = $vars->{qval};
$metadata->{testing} = "test";
#my $json = encode_json $metadata;
	   	#	print $json;exit;	
		#$metadata->{test} = "test";   
		my $response = {
			metadata => $metadata,
			data => $data
		};
		#my $datastring = join ",",@$data;
			
		#   $datastring = qq|{metadata:"$metadata",results:"$datastring"}|;															# Encode into JSON and print	
   		my $json = encode_json $response;
   		print $json;exit;

	}


#	if ( ($vars->{cmd} eq "list" && $vars->{table} eq "link") ||
#	   ( $vars->{cmd} eq "list" && $vars->{table} eq "feed" ) ) {

	# these if statements are all temporary as I work to replace 'list'
	if ($vars->{cmd} eq "list" && $vars->{table}) {
	unless ($vars->{table} eq "tables" || $vars->{table} eq "general") {

		print "Content-type: text/json\n\n";
   		$vars->{format} = "json";

   		my ($metadata,$data) = &list_records($vars->{table},$listsearch);

   		my $json = encode_json $data;
   		print $json;exit;
	} }


	if ($vars->{cmd} eq "list" && $vars->{table} eq "media") {

		print "Content-type: text/json\n\n";
   $vars->{format} = "json";
   my ($metadata,$data) = &list_records("media",{mimetype=>"audio/mpeg"});
   
   my $json = encode_json $data;
   print $json;exit;

	}


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

	#################################################


  # START
  elsif ($vars->{cmd} eq "start") {
		print "Content-type: text/html\n\n";
		my @tabs = split",",$vars->{tabs};
		unless (@tabs) { @tabs = ('Database');}
			 #{}print qq|<textarea cols=60 rows=60>|;
			 print &main_window(\@tabs,@tabs[0]);
			#{} print qq|</textarea>|;
			 exit;
  }


	# SHOW
  elsif ($vars->{cmd} eq "show") {
	    print "Content-type: text/html\n\n";
		print &api_show_record(); exit;
	}


  # WEBMENTION

  elsif ($vars->{cmd} eq "webmention") {

    print "Content-type: text/html\n\n";
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
		print "Content-type: text/html\n\n";
		unless ($vars->{id}) { print "Need to provide a feed id."; exit;}
		my $record = &db_get_record($dbh,"feed",{feed_id=>$vars->{id}});
		my $table = "feed";
		my $status = $record->{$table."_status"};
		my $link = $record->{$table."_link"};
		my $harvestlink = $Site->{st_cgi}."harvest.cgi";
		print &harvester_commands($vars->{id},$status,$harvestlink,$link);
		exit;
	}





	# If there is a file being uploaded, we have to handle the file before writing the session cookie
	# So we'll do that here, leaving the uploaded file object location as the value of $vars->{file}


	my $file;
	if ($query->content_type() =~ 'multipart/form-data') {
		my $session = new CGI::Session(undef, $query, {Directory=>'/tmp'});	# Must be logged in to upload
		&status_error("No uploads unless logged in") unless ($session->param("~logged-in"));
		$vars->{file} ||= "myfile";
		$file = &upload_file($vars->{file});
	}



# Load User
	#my ($session,$username) = &check_user();
	my $mimetype = "application/json";
	if ($vars->{cmd} =~ /edit|autopost/) { $mimetype = "text/html"; }
	my ($session,$username) = &check_user($mimetype);
	our $Person = {}; bless $Person;
	&get_person($Person,$username);
	my $person_id = $Person->{person_id};
	# print &show_login($session);


if ($vars->{cmd} eq "authenticate") {

	if ($Person->{person_status} =~ /admin|Admin/) { print 1; } else { print 0; }
	exit;

}

	
# Admin Only
	unless (&admin_only()) { &status_error("Admin Login Required"); }
	
# List Tables
	
	if ($vars->{cmd} eq "list_tables") { 
		print &list_tables(); exit; 
	}



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
	my $starting_tab = $vars->{starting_tab} || "Edit";	
	print &main_window($tabs,$starting_tab,$vars->{table},"$vars->{id}",$vars);
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
		unless ($vars->{value} =~ /^[\p{Alnum}\s-_]{0,30}\z/ig);

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
	if ($vars->{type} eq "text" || 
		$vars->{type} eq "textarea"  || 
		$vars->{type} eq "wysihtml5" || 
		$vars->{type} eq "select") { 
			&api_textfield_update(); }

	elsif ($vars->{type} eq "password") {
		&api_password_update(); 
	}

	elsif ($vars->{type} eq "keylist") { &api_keylist_update();  }



	# record publish
	elsif ($vars->{type} eq "data") { &api_data_update();  }

	# file upload
	elsif ($vars->{type} eq "file") { &api_file_upload($file); }

	# url upload
	elsif ($vars->{type} eq "file_url") { &api_url_upload(); }

	# record publish
	elsif ($vars->{type} eq "publish") { &api_publish(); }

	# column create
	elsif ($vars->{type} eq "column") { &api_column_create(); }

	# column update
	elsif ($vars->{type} eq "alter") { &api_column_alter(); }

	# column remove
	elsif ($vars->{type} eq "column_remove") { &api_column_remove(); }

	# commit
	elsif ($vars->{type} eq "commit") { &api_commit(); }

	# Simple one-field update, returns JSON
	elsif ($vars->{field}) { &api_textfield_update(); } 

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
		&publish_page($dbh,$query,$vars->{id},"");  # Information stored in $vars->{message}
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

if (0) {
print sprintf(qq|{"cmd":"$cmd","table":"$table"}|);
exit;
}

# COMMANDS

if ($vars->{cmd}) {

	# LIST

	if ($vars->{cmd} eq "list") {

# testing
if ($vars->{table} eq "media") {
  # print "Content-type: text/json\n\n";
  
   $vars->{format} = "json";
   my ($metadata,$data) = &list_records("media",{mimetype=>"audio/mpeg"});
   my $json = encode_json $data;
   print $json;
   exit;

}
  #  print "Content-type: text/html\n\n";

    # List Tables
		if ($vars->{obj} eq "tables") { print &list_tables(); exit; }  # Temporary
		if ($vars->{table} eq "tables") { print &list_tables(); exit; }

		# List Records - produces a lovely formatted list of records with edit and delete options
    unless ($vars->{table}) { print "Table to $vars->{cmd} has not been specified."; exit; }
	  unless ($vars->{tab}) { $vars->{tab} = "no-tab"; }
	  
	  print "Broken".&list_records($vars->{table},$vars->{tab});
    exit;

  }










  # EDIT
  elsif ($vars->{cmd} eq "edit") {

	}



	# IMPORT
  elsif ($vars->{cmd} eq "import") {
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

	# DELETE
  elsif ($vars->{cmd} eq "delete") {
		if ($vars->{obj} eq "record") {

			my $apilink = $Site->{st_cgi}."api.cgi";
			unless ($vars->{table}) { print "Table to $vars->{cmd} has not been specified."; exit; }
			unless ($vars->{id}) { print "ID number to $vars->{cmd} has not been specified."; exit; }

			&record_delete($dbh,$query,$vars->{table},$vars->{id},"silent");
			# Back up table
		  #my $savemsg = &api_backup($vars->{table});

			# Drop table
			#my $dropmsg = &db_drop_table($dbh,$vars->{table});

		  print qq|OK|;
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

  # AWARD BADGE
	if ($vars->{cmd} eq "award_badge") {

		# Make sure the badge and the resource exist
	  my $badgedata = &db_get_record($dbh,"badge",{badge_id=>$vars->{badge_id}});
		unless ($badgedata) { printf("Badge %s does not exist.",$vars->{badge_id}); exit;}
		my $evidata = &db_get_record($dbh,$vars->{badge_table},{$vars->{badge_table}."_id"=>$vars->{badge_table_id}});
		unless ($evidata) { printf("%s %s does not exist.",$vars->{badge_table},$vars->{badge_table_id}); exit;}

		# Find the author(s) of the resource
    my @authors = &find_graph_of($vars->{badge_table},$vars->{badge_table_id},"author");
		unless (@authors) {    # Could not find author assicuated with the resource itself, try feed maybe?
    	my @feeds = &find_graph_of($vars->{badge_table},$vars->{badge_table_id},"feed");
			foreach my $feed (@feeds) {    # Usually only one feed, but covering my bases
			  my @feed_authors = &find_graph_of("feed",$feed,"author");
				if (@feed_authors) { push @authors,@feed_authors; }
  		}
 		}

		# Cannot award badge if there's nobody to award it to
		unless (@authors) {
			print "I could not find an author to award this badge to.";	exit;
		}

		# For each author...
		my $author_names = "";
		foreach my $author (@authors) {

			# Get the author identifier
			my $author_record =  &db_get_record($dbh,"author",{author_id=>$author});
			my $author_identifier; my $identifiertype;
			if ($author_record->{author_email}) { $author_identifier = $author_record->{author_email}; $identifiertype="email"; }
			elsif ($author_record->{author_link}) { $author_identifier = $author_record->{author_link}; $identifiertype="url";  }
			elsif ($author_record->{author_url}) { $author_identifier = $author_record->{author_url}; $identifiertype="url"; }
			elsif ($author_record->{author_phone}) { $author_identifier = $author_record->{author_phone};$identifiertype="telephone";  }

			# Option to edit author record if no identifier is found
			unless ($author_identifier) {
					printf("I found %s as the author of this resource, however ",$author_record->{author_name});
					print "I need an email, url or phone number to identify this badge recipient. ";
					printf(qq|<a href="#"	data-dismiss="modal" onclick="openDiv('%sapi.cgi',
						'main','edit','author','%s','','Edit');">Edit</a> the author record and then award the badge|,
						$Site->{st_cgi},$author_record->{author_id});
					exit;
			}
			if ($author_names) { $author_names .= ", "; }
			$author_names.=$author_record->{author_name}." (identified by $author_identifier)";

			# Get the evidence URL
			my $evidence_url = $evidata->{$vars->{badge_table}."_guid"} || $evidata->{$vars->{badge_table}."_link"} || $evidata->{$vars->{badge_table}."_url"};

			# Award the badge

			# Check to see if badge already awarded to this author, exit if so
			my @found = &find_graph_of("badge",$vars->{badge_id},"author");
			if (grep(/^$author$/i, @found)) { print "This badge has already been awarded to $author_identifier."; exit; }

			# Associate the badge with the author and the link, graph_type is 'awarded' and graph_typeval is the evidence_url
			&db_insert($dbh,$query,"graph",{
				graph_tableone=>"badge", graph_idone=>$vars->{badge_id}, graph_tabletwo=>"author", graph_idtwo=>$author,
				graph_creator=>$Person->{person_id}, graph_crdate=>time, graph_type=>"awarded",graph_typeval=>$evidence_url});
			&db_insert($dbh,$query,"graph",{
				graph_tableone=>"badge", graph_idone=>$vars->{badge_id}, graph_tabletwo=>$vars->{badge_table}, graph_idtwo=>$vars->{badge_table_id},
				graph_creator=>$Person->{person_id}, graph_crdate=>time, graph_type=>"awarded",graph_typeval=>$author});

			# Award on Badgr
			our $Badgr = gRSShopper::Badgr->new({
				badgr_url   => $Site->{badgr_url},
				badgr_account		=>	$Site->{badgr_account},
				badgr_password => $Site->{badgr_password},
				badgr_issuerid => $Site->{badgr_issuerid},
				secure => 1,							# Turns on SSH
			});

			unless ($evidence_url) { printf("There is no URL for the evidence data provided, %s",$evidata->{$vars->{badge_table}."_title"}); }
				print qq|award_badge({badge_entityid=>$badgedata->{badge_badgrid},{$identifiertype=>$author_identifier},{url=>$evidence_url})|;
			$Badgr->award_badge({badge_entityid=>$badgedata->{badge_badgrid}},{$identifiertype=>$author_identifier},{url=>$evidence_url});

			# Send WebMention

			my $lcontent = get($evidence_url);
			if ($lcontent) {
				my $endpoint = &find_webmention_endpoint($lcontent);
				if ($endpoint) { &send_webmention($endpoint,$evidence_url,$Site->{st_url}."badge/".$vars->{badge_id}); }
				else { print "Tried to send WebMention but couldn't find an endpoint for $evidence_url <br>."}
			} else { print "Tried to send WebMention but the evidence link is not responding."; }

			# Record in Blockchain

			# Load Blockchain Module
			use File::Basename qw(dirname);
			use Cwd  qw(abs_path);
			use lib dirname(dirname abs_path $0) . '/cgi-bin/modules/Blockchain/lib';
			use Blockchain;

      # Create Transaction
			my $blockchain = new Blockchain;
		  delete $vars->{cmd};
			my $assertion = {
						sender=>{
							url=>$Site->{st_url},
							email=>$Site->{st_email},
							name=>$Site->{st_name}
						},
						badge=>{
								badge_entityid=>$badgedata->{badge_badgrid},
								badge_url=>$Site->{st_url}."badge/".$vars->{badge_id}."/".$author_record->{author_id}
						},
						recipient=>{
								name=>$author_record->{author_name},
								$identifiertype=>$author_identifier
						},
						evidence=>{
								url=>$evidence_url
						}
			};
		  my $index = $blockchain->new_transaction($assertion);
			# I can store anything I want in this blockchain

			print "Saved transaction number $index and will be added to blockchain.<br>";
			# If index is high enough, mine a new block
			print "Content-type: tet/html\n\n";
			print "mining from api";		
			if ($index>5) { $blockchain->mine(); print "New block mined.<br>"; }
			&blockchain_close($blockchain);


		}


		print "Awarded Badge $vars->{badge_id} to $author_names.<br>";
		exit;

	}
	#----------------------------------------------------------------------------------------------------------
	#
  #   gRSShopper Blockchain APIs (because I can't resist playing)
	#   Based on Daniel Flymen, Learn Blockchains by Building One
	#   https://hackernoon.com/learn-blockchains-by-building-one-117428612f46
	#
	#----------------------------------------------------------------------------------------------------------


	# NEW TRANSACTION
  elsif ($vars->{cmd} eq "transaction") {

    my $blockchain = new gRSShopper::Blockchain;
    die "Missing values in blockchain transaction" unless ($vars->{sender} && $vars->{recipient} && $vars->{amount});
		my $index = $blockchain->new_transaction($vars->{sender},$vars->{recipient},$vars->{amount});
    my $response = {message => "Transaction will be added to Block $index"};

		&blockchain_close($blockchain);

		print encode_json( $response );
		exit;
	}

	# MINE
  elsif ($vars->{cmd} eq "mine") {

	  my $blockchain = new gRSShopper::Blockchain;
		my $node_identifier = 1;

		# We run the proof of work algorithm to get the next proof...
		my $last_block = $blockchain->last_block();
		my $last_proof = $last_block->{proof};
		my $proof = $blockchain->proof_of_work($last_proof);

		# We must receive a reward for finding the proof.
	  # The sender is "0" to signify that this node has mined a new coin.
		$blockchain->new_transaction(0,$node_identifier,1);
		my $previous_hash = $blockchain->hash($last_block);
		my $block = $blockchain->new_block($proof,$previous_hash);

		my $response = {
			message => "New Block Forged",
			index => $block->{index},
			transactions =>  $block->{transactions},
			proof =>  $block->{proof},
			previous_hash => $block->{previous_hash}
		};

		&blockchain_close($blockchain);
		print encode_json( $response );
		exit;
	}


	# CHAIN
  elsif ($vars->{cmd} eq "chain") {

	  my $blockchain = new gRSShopper::Blockchain;

		my @chain = $blockchain->{chain};

		my $response = {
        chain => $blockchain->{chain},
        length => scalar @chain,
    };

		&blockchain_close($blockchain);
		print encode_json( $response );
		exit;
	}

	# REGISTER
  elsif ($vars->{cmd} eq "register") {

    # Only registers one node at at time; I'll fix at a future point
	  unless ($vars->{node}) { die "Error: Please supply a valid node"; }


		my @nodes;
		push @nodes,$vars->{node};
		my $blockchain = new gRSShopper::Blockchain;

	  foreach my $node (@nodes) {
			$blockchain->register_node($node);
		}

	  my $response = {
			message => 'New nodes have been added',
			total_nodes => @nodes,
	  };

		&blockchain_close($blockchain);
		print encode_json( $response );
	  exit;
	}

	# RESOLVE
  elsif ($vars->{cmd} eq "resolve") {

		my $blockchain = new gRSShopper::Blockchain;
		my $replaced = $blockchain->resolve_conflicts();
		my $response;

    if ($replaced) {
        $response = {
            message => 'Our chain was replaced',
            new_chain => $blockchain->{chain},
        };
    } else {
        $response = {
            message => 'Our chain is authoritative',
            chain => $blockchain->{chain},
        };
    }
		&blockchain_close($blockchain);
		print encode_json( $response );

    exit;

  
  

			if ($request_data->{action} eq "search") {


				# Table
				unless ($request_data->{table}) { print "Error: table name must be provided."; exit; }
				$request_data->{table} =~ s/[^a-zA-Z0-9 _]//g;  # Just make sure there's no funny business

				my $sql = &create_sql($request_data->{table},$request_data->{language},$request_data->{sort},$request_data->{page});
				my $query = '%'.$request_data->{query}.'%';

				# Execute query and convert the result to JSON, then print
				my $json->{entries} = $dbh->selectall_arrayref( $sql, {Slice => {} },$query,$query );
				my $json_text = to_json($json);
				print $json_text;
	      exit;

	    }


	    # Identify, Save and Associate File





	  #my $return = &form_graph_list("post","60231","author");

		# &send_email('stephen@downes.ca','stephen@downes.ca', 'api failed', 	qq|Table ID  - |.$vars->{table_id}.qq|	Column  - |.$vars->{col_name}.qq|	Input value  - |.$vars->{value}.qq|	Input type  - |.$vars->{type}.qq|$return|);


		#print $return;

		exit;


	}

	# Save the updated copy of the blockchain to a file

	sub blockchain_close {

		my ($blockchain) = @_;

		my $output = ();
		$output->{chain} = $blockchain->{chain};
		$output->{current_transactions} = $blockchain->{current_transactions};
		$output->{nodes} = $blockchain->{nodes};
		my $json_data = encode_json( $output );

    # None of this worked
		# our $JSON = JSON->new->utf8;
		# $JSON->convert_blessed(1);
		# my $json_data = $JSON->encode($blockchain);
		# my $json_data = JSON::to_json($blockchain, { allow_blessed => 1, allow_nonref => 1 });

		my $blockchain_file = "data/blockchain.json";
		open(my $fh, ">$blockchain_file") || die "Could not open $blockchain_file for write";
    flock($fh, LOCK_EX) or die "Cannot lock $blockchain_file - $!\n";
		print $fh $json_data;
    close $fh;

	}

	&status_error("Command '$vars->{cmd}' not recognized.");
	

}
# "
# API Show ----------------------------------------------------------
# ------- Show Record ------------------------------------------------------
#
# Show in a table
# Will accept search parameters
#
# -------------------------------------------------------------------------

sub api_show_record {

	 unless ($vars->{table}) { &status_error("Don't know which table to show.");}
	 &status_error("Not allowed to show ".$vars->{table}) unless (&is_allowed("view",$vars->{table}));

	 # Set PLE start screen to login if needed
	 if ($vars->{table} eq "box" && $vars->{id} eq "Start") {
		 
		 	our $Person = {}; bless $Person;
 			&get_person($dbh,$query,$Person);
 			my $person_id = $Person->{person_id};
		 	&admin_only();
	 }


   unless ($vars->{id}) { &status_error("Don't know which ".$vars->{table}." number to show."); }
	 $vars->{format} ||= "html";	 

	 return	&output_record($dbh,$query,$vars->{table},$vars->{id},$vars->{format},"api");
	 exit;
}





# API BACKUP ----------------------------------------------------------
# ------- Back Up Table ------------------------------------------
#
# Alter a column in a database
# Expects semi-colon-delimited comtent as follows: "field;type;size;null;default;extra"
#
# -------------------------------------------------------------------------

sub api_backup {

	my $output = "Backing up $vars->{table}. ";
	if ($vars->{table} eq "all") {$output .= " tables"; }
	my $savefile = &db_backup($vars->{table});
	my $saveurl = $savefile;
	$saveurl =~ s/$Site->{st_urlf}/$Site->{st_url}/;
	$output .= qq|Table '$vars->{table}' backed up to <a href="$saveurl">$savefile</a>|;
  	return $output;

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


sub create_sql {

	my ($table,$language,$sort,$page) = @_;

  #  Language
  my $lang_where = "";
	$language =~ s/[^a-zA-Z]*//g;
  if ($language && $vars->{language} ne "All") {
		  $lang_where = "course_language LIKE '%".$language."%' AND ";
	}

	# Orderby
	my $orderby = "";
	$sort =~ s/[^a-zA-Z_]*//g;
	if ($sort eq "Title") {
		$orderby = " ORDER BY course_title";
	} else  {
		$sort = "Recent";
		$orderby = " ORDER BY course_crdate DESC";
	}


	# Start and Limit
	my $count = "Need to create counter";
	$page =~ s/[^0-9]*//g;
  my $limit; my $results_per_page = 10; my $start=0;
  unless ($page) { $page=0;}
	if ($page > 0) 	{ $start = $page*10; $limit = "LIMIT $start,$results_per_page"}
	else { $limit = "LIMIT $results_per_page"; }
	my $end = $start+$results_per_page; my $s = $start+1;
	my $results_range = "$s to $end of $count";


  my $sql = "SELECT * FROM  course	WHERE $lang_where (course_title LIKE ? OR course_description LIKE ?) $orderby $limit ";


	return $sql;
}


sub keylist {

  my ($sutocontent) = @_;
	my $script = {}; my $replace;

	&parse_keystring($script,$sutocontent);


	$script->{separator} = $script->{separator} || ", ";

	for (qw(prefix postfix separator)) {
		if ($script->{$_} =~ /(BR|HR|P)/i) {
			$script->{$_} = "<".$script->{$_}.">";
		}
	}



	our $ddbbhh = $dbh;
	#print " Finbding graph $script->{db},$script->{id},$script->{keytable} <br>";
	my @connections = &find_graph_of($script->{db},$script->{id},$script->{keytable});

	foreach my $connection (@connections) {

								# Get item data

								# Prepare SQL Query for each item
								# (We could probably combine into one
								# by making a large 'OR' out of all the ID
								# numbers...
		my $titfield = get_key_namefield($script->{keytable});
		my $klid = $script->{keytable}."_id";
		$script->{search} =~ s/'//; $connection =~ s/'//;

		my $keylistsql = qq|SELECT * FROM $script->{keytable} WHERE $klid = '$connection'|;


		if ($script->{search}) {
			my $descfield = $script->{keytable}."_description";
			my $catfield = $script->{keytable}."_category";
			my $contfield = $script->{keytable}."_content";
			my $keylistwhere = qq| AND ($descfield LIKE '%$script->{search}' OR
					$titfield LIKE '%$script->{search}%' OR
					$contfield LIKE '%$script->{search}%' OR
					$catfield LIKE '%$script->{search}%')|;
			$keylistsql .= $keylistwhere;
		}

								# Execute SQL Query for each item
		my $sth = $dbh->prepare($keylistsql);
		$sth -> execute();
		while (my $c = $sth -> fetchrow_hashref()) {

			next unless ($c);			# Items that don't match $script->{search}
								# if it's used will not return results

								# Display the result
			my $kname = $c->{$titfield};
			if ($replace) { $replace .= $script->{separator}; }
			if ($script->{format} eq "text") { $replace .= qq|$kname|; }
			elsif ($script->{format}) {
				my $ftext = &format_record($dbh,$query,$script->{keytable},"$script->{format}",$c);
				$replace .= $ftext; }
			else { $replace .= qq|<a href="$Site->{st_url}$script->{keytable}/$connection" style="text-decoration:none;">$kname</a>|; $replace =~ s/\n/<br\/>/ig; }



		}
		$sth->finish();
	}


    return $replace;

}




# API UPDATE ----------------------------------------------------------
# ------- Keylist Update-----------------------------------------------
#
# Find or, if not found, create a new $key record named $value
# Then create a graph entry linking the new $key with $table $id
#
# -------------------------------------------------------------------------



sub api_keylist_update {

	my ($table,$key) = split /_/,$vars->{col_name};
  #	die "Field does not exist" unless &__check_field($table,$vars->{col_name});
	my $table = $vars->{table};
	my $id = $vars->{id};
	my $value = $vars->{value};
	my $key = $vars->{key};
	my $noedit = $vars->{noedit};

	# Split list of input $value by ;
	$value =~ s/&apos;|&#39;/'/g;   # ' Remove apostraphe escaping, just for the split
	my @keynamelist = split /;/,$value;

	# For each member of the list...
	foreach my $keyname (@keynamelist) {

	  $keyname =~ s/'/&#39;/g;   # Replace apostraphe escaping

		# Trim leading, trailing white space
		$keyname =~ s/^ | $//g;

		# Are we looking for _name, _title ...?
		my $keyfield = &get_key_namefield($key);

		# can we find a record with that name or title?
		my $keyrecord = &db_get_record($dbh,$key,{$keyfield=>$keyname});

		# Record wasn't found, create a new record, eg., a new 'author'
		unless ($keyrecord) {

			# Initialize values
			$keyrecord = {
				$key."_creator"=>$Person->{person_id},
				$key."_crdate"=>time,
				$keyfield=>$keyname
			};

			# Save the values and obtain new record id
			$keyrecord->{$key."_id"} = &db_insert($dbh,$query,$key,$keyrecord);
		}

		# Error unless we have a new record id
		print &error() unless $keyrecord->{$key."_id"};

		# Save Graph Data
		my $graphid = &db_insert($dbh,$query,"graph",{
			graph_tableone=>$key, graph_idone=>$keyrecord->{$key."_id"}, graph_urlone=>$keyrecord->{$key."_url"},
			graph_tabletwo=>$table, graph_idtwo=>$id, graph_urltwo=>"",
			graph_creator=>$Person->{person_id}, graph_crdate=>time, graph_type=>"", graph_typeval=>""});
	}

	# Return new graph output for the form
	
	my $newlist = &form_graph_list($table,$id,$key,'',$noedit);

	&status_ok($key."_graph_list",$newlist);

}

# API UPDATE ----------------------------------------------------------
# ------- KeylistRemove -----------------------------------------------
#
# Remove any graph entry linking the new $key $value with $table $id
#
# -------------------------------------------------------------------------

sub api_keylist_remove {

	my $table = $vars->{table};
	my $id = $vars->{id};
	my $key = $vars->{key};
	my $keyid = $vars->{keyid};
	my $noedit = $vars->{noedit};
	unless ($table && $id && $key && $keyid) {
		&status_error("Missing input value (either table, id, key or keyid) from api_keylist_remove()");
	}

   # Remove Graph Database

	my $sql = "DELETE FROM graph WHERE graph_tableone=? AND graph_idone = ? AND graph_tabletwo =? AND graph_idtwo = ?";
	my $sth = $dbh->prepare($sql);
	$sth->execute($table,$id,$key,$keyid);
	$sth->execute($key,$keyid,$table,$id);

	# Return new graph output for the form
	my $newlist = &form_graph_list($table,$id,$key,'',$noedit);
	&status_ok($key."_graph_list",$newlist);

	exit;
}


# API UPDATE ----------------------------------------------------------
# ------- Text -----------------------------------------------------
#
# Update a text field
#
# -------------------------------------------------------------------------

sub api_textfield_update {

	$vars->{format} = "json"; 
					
	unless ($vars->{table} && $vars->{field} && $vars->{value} && $vars->{id}) {
		&status_error("Update command requires a table name, ID number, and a value");
	}
	
	my $field = $vars->{field}; my $fieldprefix = $vars->{table}."_";
	unless ($field =~ /^$fieldprefix/) { $field = $fieldprefix.$field; }
		
	&status_error("Field $field does not exist") unless (&__check_field($vars->{table},$vars->{field}));
	
	# Check for duplicates
	if ($vars->{value} && $vars->{col_name} =~ /_title|_name|_url|_link/) {
		if (my $l = &db_locate($dbh,$vars->{table_name},{$vars->{col_name} => $vars->{value}})) {
			&status_error(qq|<p>Duplicate Entry. This $vars->{col_name} will not be saved.<br/>
			If you would like to edit the existing $vars->{table_name} then please
			<span title="Edit" onclick="openDiv('$Site->{st_cgi}api.cgi','main','edit','$vars->{table_name}','$l','Edit');"> <i class="fa fa-edit"> Click Here</i></span></p>|);
		}

	}

	# Submit the data
	my $id_number = &db_update($dbh,$vars->{table}, {$vars->{field} => $vars->{value}}, $vars->{id});

	# If successful
	if ($id_number) {

$vars->{message} .= "Suvvessfully updated $id_number";

		# If table is optlist, update search forms
		if ($vars->{table} eq "optlist") {
$vars->{message} .= " Updating search form";			
			$vars->{message} .= &make_search_forms();    # Located in make.pl
		}

		# Update the cached version of the record
 		# &output_record($dbh,$query,$vars->{table},$vars->{id},"viewer");
		 
		my $published = &db_get_single_value($dbh,$vars->{table},$vars->{table}."_social_media",$vars->{id});

		# Update if already published to web
		# Autopublishing author, feed
		if ($published =~ /web/ || $vars->{table} =~ /author|feed|post/) { 
			&print_record($vars->{table},$vars->{id});
		}   
		
		&status_ok();

  } else { &api_error(); }
	die "api failed to update $vars->{table_name}  $vars->{table_id}" unless ($id_number);


}
# API UPDATE ----------------------------------------------------------
# ------- Password -----------------------------------------------------
#
# Encrypt and Update Password
#
# -------------------------------------------------------------------------

sub api_password_update {

	$vars->{format} = "json";

	# Encrypt password
	my $encr_pass = &_encrypt_password($vars->{value});
	
	# Submit the data
	my $id_number = &db_update($dbh,$vars->{table}, {$vars->{field} => $encr_pass}, $vars->{id});
	$vars->{message} .= "Updated $vars->{type} for $vars->{table} $vars->{id}";
	&status_ok();

}
# API UPDATE ----------------------------------------------------------
# ------- DateTime -----------------------------------------------------
#
# Update Date Time
#
# -------------------------------------------------------------------------

sub api_datetime_update {


	unless (&__check_field($vars->{table_name},$vars->{col_name})) {
		print "Content-type: text/html\n\n";
		print "Field does not exist";
	  die "Field does not exist";
	}

  my $epoch = datepicker_to_epoch($vars->{value});
	# Convert value to epoch (which is what we'll actually save for a datetime)

	my $id_number = &db_update($dbh,$vars->{table_name}, {$vars->{col_name} => $epoch}, $vars->{table_id});

	# Update the cached version of the record
	if ($id_number) {
		
		&output_record($dbh,$query,$vars->{table_name},$vars->{table_id},"viewer");
		my $published = &db_get_single_value($dbh,$vars->{table_name},$vars->{table_name}."_social_media",$vars->{table_id});
		if ($published =~ /web/) { &print_record($vars->{table_name},$vars->{table_id}); }   # Update if alread published to web

		&api_ok();
	} else { &api_error(); }
	die "api failed to update $vars->{table_name}  $vars->{table_id}" unless ($id_number);


}
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

		elsif ($vars->{value} =~ /mastodon/i) {

			print "Sending to Mastodon<br>";
			my $mastodon = &mastodon_post($dbh,"post",$id);
			print "Mastodon result: $mastodon<br>";
			$published .= ",mastodon";
			my $result = &db_update($dbh,$table, {$col => $published}, $id); # Prevent publishing twice
			print "Recorded publication success $result<br>";
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
			if ($newprevid) { &print_record($table,$newprevid); } 

			# Publish feed and author records
			foreach my $assoc_table ("author","feed") {
				my @assoc_graph = &find_graph_of($table,$id,$assoc_table);
				if (@assoc_graph[0]) {
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

			my $result = &db_update($dbh,$table, {$table."_web" => 1}, $id); # Prevent publishing twice
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

# API UPDATE ----------------------------------------------------------
# ------- Create Column -----------------------------------------------------
#
# Update a column in a database
# Expects semi-colon-delimited comtent as follows: "field;type;size;null;default;extra"
#
# -------------------------------------------------------------------------

sub api_column_create {

	my $table = $vars->{table_name};
	my $id = $vars->{table_id};
	my $value = $vars->{value};
	my $column = $vars->{col_name};
  my ($field,$type,$size,$null,$default,$extra) = split ';',$value;

  # Validate column name
  unless ($field) {
		print "No column created because no column name was provided."; exit;
	}

	# Validate field sizes
	($type,$size) = validate_column_sizes($type,$size);

  if ($id eq "new") {
     print &db_add_column($table,$field,$type,$size,$default); exit;
	} else {

     print "Error creating new column. 'id' should equal 'new'."; exit;

	}
	exit;

	die "Field does not exist" unless (&__check_field($vars->{table_name},$vars->{col_name}));
	my $id_number = &db_update($dbh,$vars->{table_name}, {$vars->{col_name} => $vars->{value}}, $vars->{table_id});
	if ($id_number) { &api_ok();   } else { &api_error(); }
	die "api failed to update $vars->{table_name}  $vars->{table_id}" unless ($id_number);


}

# API UPDATE ----------------------------------------------------------
# ------- Alter Column -----------------------------------------------
#
# Alter a column in a database
# Expects semi-colon-delimited comtent as follows: "field;type;size;null;default;extra"
#
# -------------------------------------------------------------------------

sub api_column_alter {

	my $table = $vars->{table_name};
	my $value = $vars->{value};
	my $column = $vars->{col_name};
  my ($field,$type,$size,$null,$default,$extra) = split ';',$value;
	my $result = "";

  print &db_alter_column($table,$field,$type,$size,$default);

	exit;


}

# API UPDATE ----------------------------------------------------------
# ------- Remove Column Warn ------------------------------------------
#
# Alter a column in a database
# Expects semi-colon-delimited comtent as follows: "field;type;size;null;default;extra"
#
# -------------------------------------------------------------------------

sub api_column_remove {

	my $table = $vars->{table_name};
	my $value = $vars->{value};
	my $col = $vars->{col_name};
	my $second_look = $vars->{second_look};
  my ($field,$type,$size,$null,$default,$extra) = split ';',$value;
	my $result = "";
  my $api_url = $Site->{st_cgi}."api.cgi";


  if ($value eq "confirm") {

    if (($col =~ /_id/) || ($col =~ /_name/) || ($col =~ /_title/) ||
			($col =~ /_description/) || ($col =~ /_crdate/) || ($col =~ /_creator/)) {
					print "The column <i>$col</i> is a required column and cannot be removed"; exit;
		} else {
					$dbh->do("ALTER TABLE $table DROP COLUMN $col");
					print "The column <i>$col</i> has been removed. I hope that's what you wanted."; exit;
		}


	} else {
  	print qq|
	  	<h1>WARNING</h1>
			<p>Are you <i>sure</i> you want to drop $col from $table ?????</p>
			<p><b>All data</b> in $col will be lost. Never to be recovered again.</p>
			<p>You <b>cannot</b> fix this. Backspace to get out of this.</p>
			<p>If you're <i>sure</i>, press the button:</p>
     	<input type="button" name="remove_column_warn" id="remove_column_warn" value=" Remove Column ">
		 	<script>
 				\$('#remove_column_warn').on('click',function(){
 					remove_column("$api_url","$table","$col","confirm");
 					openColumns("$Site->{st_cgi}api.cgi?cmd=show_columns&db=$table","$table");
 				});
 			</script>
		|;
	}
	exit;


}


#
#             API Commit
#
#             Commits changes saved in the 'Form' table to the database
#             - creates table if necessary
#             - creates columns if necessary
#             - alters column to new type if necessary
#


sub api_commit {

  print "Commit";
  return "Commit";
  exit;

	# Get the Form record from database
	my $record = &db_get_record($dbh,$vars->{table_name},{$vars->{table_name}."_id" => $vars->{table_id}});
	unless ($record) { print "<span style='color:red;'>Error: API failed to update $vars->{table_name}  $vars->{table_id}</span>"; exit; }

	# Standardize form names to lower case (because some operations are case insensitive)
	$record->{form_title} = lc($record->{form_title});


	# Create table if table doesn't exist
	&db_create_table($dbh,$record->{form_title});

	# Get the existing columns from the table
	my $columns;
	#my $showstmt = qq|SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = ? AND table_schema = ? ORDER BY column_name|;
	my $showstmt = "SHOW COLUMNS FROM ".$record->{form_title};
	my $sth = $dbh -> prepare($showstmt)  or die "Cannot prepare: $showstmt FOR $record->{form_title} in $Site->{db_name} " . $dbh->errstr();
	$sth -> execute()  or die "Cannot execute: $showstmt " . $dbh->errstr();
  #	$sth -> execute($record->{form_title},$Site->{db_name})  or die "Cannot execute: $showstmt " . $dbh->errstr();
	while (my $showref = $sth -> fetchrow_hashref()) {
  #print $showref->{Field},"<p>";
		# Stash Column Data for future reference
		$columns->{$showref->{Field}}->{type} = $showref->{Type};
		$columns->{$showref->{Field}}->{size} = $showref->{CHARACTER_MAXIMUM_LENGTH};

	}

	# Go though the table structure defined in $record->{form_data}
	my @fcols = split /;/,$record->{form_data};
	my $titles = 0;

	# For each of the columns defined in the form data
	foreach my $fcol (@fcols) {
		my ($fname,$ftype,$fsize) = split /,/,$fcol; 	# This assumes an order which could be a problem
		if ($titles == 0) {
								# Fix that problem here
			$titles = 1; next; 			# Skip past titles
		}

		# Does the column exist?
		my $columntitle = $record->{form_title}."_".$fname;

		# No
		unless ($columns->{$columntitle}) {

			next if (&__map_field_types($ftype) eq "none");

			# Create New Column as per the Form Data
			my $sql;
			if (&__map_field_types($ftype) eq "text") {
				$sql = qq|alter table |.$record->{form_title}.qq| add column $columntitle text;|;
			} elsif (&__map_field_types($ftype) eq "int") {
				unless ($fsize) { $fsize=15; }
				$sql = qq|alter table |.$record->{form_title}.qq| add column $columntitle int ($fsize);|;
			} elsif (&__map_field_types($ftype) eq "varchar") {
				unless ($fsize) { $fsize = 256; }
				$sql = qq|alter table |.$record->{form_title}.qq| add column $columntitle varchar ($fsize);|;
			} else {
				$sql = qq|alter table |.$record->{form_title}.qq| add column $columntitle varchar ($fsize);|;
			}
			#print "Doing: $sql <br>";
			$dbh->do($sql) or die "error creating $fname using $sql";


		# Yes
		} else {

			# Check for increased varchar size
			if (&__map_field_types($ftype) eq "varchar") {
				if ($columns->{$columntitle}->{size} < $fsize) {

					# And alter column size if necessary

					my $sql = qq|alter table |.$record->{form_title}.qq| modify $columntitle VARCHAR($fsize);|;
					$dbh->do($sql) or die "error embiggening $fname";

				}

			}

		}


	}


	my $id_number = &db_update($dbh,$vars->{table_name}, {$vars->{col_name} => 1}, $vars->{table_id});
	if ($id_number) { &api_ok();   } else { &api_error(); }
	die "api failed to update $vars->{table_name}  $vars->{table_id}" unless ($id_number);

}

sub __map_field_types {

	my ($field) = @_;
	if ($field eq "select" || $field eq "date" || $field eq "varchar") { return "varchar"; }
	elsif ($field eq "text" || $field eq "textarea" || $field eq "wysihtml5" || $field eq "data") { return "text"; }
	elsif ($field eq "commit" || $field eq "publish" || $field eq "int") { return "int"; }
	else { return "none"; }

}



sub api_data_update {



    my $data = "";
    for (my $i=-1; $i < 100; $i++) {
    	my $row = "";
    	for (my $j=-1; $j < 100; $j++) {
    	   my $slot = $i."-".$j;
	   if ($vars->{$slot}) {
	   	if ($row) { $row .= ","; }
	   	$row .= $vars->{$slot};
	   }
        }
        if ($data && $row) { $data .= ";"; }
	$data .= $row;
    }

  #$data = qq|name,type,size;name,textarea,256;nickname,textarea,256|;
    my $id_number = &db_update($dbh,$vars->{table_name}, {$vars->{col_name} => $data}, $vars->{table_id});


  #my $str; while (my ($x,$y) = each %$vars) 	{ $str .= "$x = $y <br>\n"; }
  #&send_email('stephen@downes.ca','stephen@downes.ca', 'data  update',$str.$data);

	# Reset commit flag in case the table is 'form'
	if ($vars->{table_name} eq "form") {
  #		&db_update($dbh,$vars->{table_name}, {form_commit => 0}, $vars->{table_id});
	}

	# Rebuild search forms in case the table is 'optlist'
	# We'll just call the function with a request to admin.cgi
	if ($vars->{table_name} eq "optlist") {
		my $findurl = $Site->{st_cgi}."admin.cgi?action=make_search_forms";
		my $content = get $findurl;
		&status_error("Couldn't get $findurl") unless defined $content;
		$vars->{message} .= $content;
	}

    if ($id_number) { &api_ok();   } else { &api_error(); }



  #	my $id_number = &db_update($dbh,$vars->{table_name}, {$vars->{name} => $vars->{value}}, $vars->{table_id});
  #	if ($id_number) { &api_ok();   } else { &api_error(); }
	#die "api failed to update $vars->{table_name}  $vars->{table_id}";
    #enless ($id_number);


}

# Parses gRSShopper URLs to return table and ID of the requests
# Used my the WEBMENTION api function

sub parse_my_url {

   my ($url) = @_;

   my $base = $Site->{st_url};
   if ($url =~ m/page\.cgi\?(.*?)=(.*?)$/) {
			return ($1,$2);
   } elsif ($url =~ /$base(.*?)\/(.*?)$/) {
			return ($1,$2);
   } else {
			return 0;
   }
}

sub api_ok {

	print qq|&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">ok!</a>|;
	exit;

}

sub api_error {


	print "300 API Error - failed to update $vars->{table_name}  $vars->{table_id} \n";
	exit;

}

# API UPDATE ----------------------------------------------------------
# ------- File -----------------------------------------------------
#
# Retrieves the file uploaded, saves it, stores
# metadata as a 'file' entry, then creates a graph entry linking the new
# file with $table $id
#
# -------------------------------------------------------------------------

sub api_file_upload {

	my ($file) = @_;

	# File was actually uploaded before calling check_user() 
	# If you need to find it, search for multipart/form-data
	&api_save_file($file);
	# Return new graph output for the form
	my $newlist = &form_graph_list($vars->{table},$vars->{id},"file");
	&status_ok("file_graph_list",$newlist);
	exit;	
}

# API UPDATE ----------------------------------------------------------
# ------- URL -----------------------------------------------------
#
# Retrieves the file found at the URL supplied, saves it, stores
# metadata as a 'file' entry, then create a graph entry linking the new
# file with $table $id
#
# -------------------------------------------------------------------------

sub api_url_upload {

	# Upload the file
	my $file = &upload_url($vars->{value});
	&api_save_file($file);

	# Return new graph output for the form
	my $newlist = &form_graph_list($vars->{table},$vars->{id},"file");
	&status_ok("file_graph_list",$newlist);
	exit;
}

# API UPDATE ----------------------------------------------------------
# ------- API Save File -----------------------------------------------
#
# Save a file, then create a graph entry
# linking the new file with $table $id
#
# -------------------------------------------------------------------------

sub api_save_file {

	my ($file) = @_;

	# Reject unless there's a full file name
	return unless ($file && $file->{fullfilename});

	$vars->{graph_table} ||= $vars->{table};
	$vars->{graph_id} ||= $vars->{id};
	&status_error("Graph table name not provided") unless ($vars->{graph_table});
	&status_error("Graph table ID not provided") unless ($vars->{graph_id});

	# Save the file
	my $file_record = &save_file($file);
	unless ($file_record) { &status_error("Error saving file $!"); }


	# Set up Graph Data
	return unless ($vars->{graph_id} && $vars->{graph_table});
	my $urltwo = $Site->{st_url}.$vars->{graph_table}."/".$vars->{graph_id};
	my $graph_typeval = "";
	if ($file_record->{file_type} eq "Illustration") { 
		$graph_typeval = $vars->{file_align} . "/" . $vars->{file_width}; }
	else { $graph_typeval = $file_record->{file_mime}; }


	# Save Graph Data
	my $graphid = &db_insert($dbh,$query,"graph",{
		graph_tableone=>'file', graph_idone=>$file_record->{file_id}, graph_urlone=>$file_record->{file_url},
		graph_tabletwo=>$vars->{graph_table}, graph_idtwo=>$vars->{graph_id}, graph_urltwo=>$urltwo,
		graph_creator=>$Person->{person_id}, graph_crdate=>time, graph_type=>$file_record->{file_type}, graph_typeval=>$graph_typeval});

	# Make Icon (from smallest uploaded image thus far)

	if ($file_record->{file_type} eq "Illustration") {

		my $icon_image = &item_images($vars->{graph_table},$vars->{graph_id},"smallest");

		my $filename = $icon_image->{file_title};
		my $filedir = $Site->{st_urlf}."files/images/";
		my $icondir = $Site->{st_urlf}."files/icons/";
		my $iconname = $vars->{graph_table}."_".$vars->{graph_id}.".jpg";

		my $tmb = &make_thumbnail($filedir,$filename,$icondir,$iconname);
	#	print "Content-type: text/html\n\n";
	# 	print "Thumbnail: $tmb <p>";
	}



}

# API UPDATE ----------------------------------------------------------
# ------- Save File -----------------------------------------------------
#
# Save a file, get metadata, store a 'file' entry in the db, return the
# new file record
#
# -------------------------------------------------------------------------
#
#   	Saves file
#
#   	Expects input from either upload_file() or upload_url()
#       input hash $file needs:
# 		$file->{fullfilename}   - full directory and file name of upload file


sub save_file {

	my ($file) = @_;

	my ($ffdev,$ffino,$ffmode,$ffnlink,$ffuid,$ffgid,$ffrdev,$ffsize, $ffatime,$ffmtime,$ffctime,$ffblksize,$ffblocks)
			= stat($file->{fullfilename});
	my $ffwidth = "400";


	my $mime;
	if (&new_module_load($query,"MIME::Types")) {
		use MIME::Types;
		my MIME::Types $types = MIME::Types->new;
			my MIME::Type  $m = $types->mimeTypeOf($file->{fullfilename});
			$mime = $m;
	} else {
		$mime="Unknown; install MIME::Types module to decode upload file mime types";
		$vars->{msg} .= "Could not determine mime type of upload file; install MIME::types module<br>";
	}

	my $file_type; if ($mime =~ /image/) {
		$file_type = "Illustration";



	} else { $file_type = "Enclosure"; }



	my $file_record = gRSShopper::Record->new(
		file_title => $file->{file_title},
		file_dirname => $file->{file_dir}.$file->{file_title},
		file_url => $Site->{st_url}.$file->{file_dir}.$file->{file_title},
		file_dir => $file->{file_dir},
		file_mime => $mime,
		file_size => $ffsize,
		file_crdate => time,
		file_creator => $Person->{person_id},
		file_type => $file_type,
		file_width => $ffwidth,
		file_align => "top");



	# Create File Record
	$file_record->{file_id} = &db_insert($dbh,$query,"file",$file_record);

	if ($file_record->{file_id}) { return $file_record; }
	else { &error($dbh,"","","File save failed: $! <br>"); }


}

sub __check_field {
	my ($table,$field) = @_;
	my @columns = &db_columns($dbh,$table);
	return 1 if (&index_of($field,\@columns)>-1);
	return 0;

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


# -------------------------------------------------------------------------------------
#          Search Functions
#
# Will all be replaced by list
# -------------------------------------------------------------------------------------


if ($vars->{search}) {

	# Sanitize seach input
	$vars->{query} =~ s/[^a-zA-Z0-9\ \.]*//g;

  my $lang_where = "";
  if ($vars->{language} && $vars->{language} ne "All") {
		  $lang_where = "course_language LIKE '%".$vars->{language}."%' AND ";
	}

	# Count Results
	my $count = &db_count($dbh,"course"," WHERE $lang_where (course_title LIKE '%".$vars->{query}."%' OR course_description LIKE '%".$vars->{query}."%')");


  # Start and Limit
  my $limit; my $results_per_page = 10; my $start=0;
  unless ($vars->{page}) { $vars->{page}=0;}
	if ($vars->{page} > 0) 	{ $start = $vars->{page}*10; $limit = "LIMIT $start,$results_per_page"}
	else { $limit = "LIMIT $results_per_page"; }
	my $end = $start+$results_per_page; my $s = $start+1;
	my $results_range = "$s to $end of $count";


  # Orderby
	my $orderby = "";

	if ($vars->{sort} eq "Title") {
		$orderby = " ORDER BY course_title";
	} else  {
		$vars->{sort} = "Recent";
		$orderby = " ORDER BY course_crdate DESC";
	}



  # Output headers, depending on request format

	# links
	if ($vars->{format} eq "links") {

		# Search Title
		my $p = $vars->{page}+1;
		print qq|<div style="padding:2%">Searching for: |.($vars->{query} || "Everything").
					qq|<br>Sort: $vars->{sort} <br>Page $p: $results_range </div></p><hr>|;

		if ($vars->{query} eq "") {

			#print qq|<a href="javascript:void(0)" onclick="openMail('Welcome');w3_close();" id="firstTab">Welcome</a>|;}
		}

  }

	elsif ($vars->{format} eq "summary") {

		# Print mobile hamburger menu
		print qq|
			<i class="fa fa-bars w3-button w3-white w3-hide-large w3-xlarge w3-margin-left w3-margin-top" onclick="w3_open()"></i>
			<a href="javascript:void(0)" class="w3-hide-large w3-red w3-button w3-right w3-margin-top w3-margin-right" onclick="document.getElementById('id01').style.display='block'">
			<i class="fa fa-pencil"></i></a>|;

		# Print welcome message
		unless ($vars->{query})  {
			print qq|
 				<div id="Welcome" class="w3-container person">
				<br>
				<img class="w3-round  w3-animate-top" src="https://www.w3schools.com/w3images/avatar3.png" style="width:20%;">
				<h5 class="w3-opacity">Welcome to MOOC.ca</h5>
				<h4><i class="fa fa-clock-o"></i> Your host for free and open online learning content</h4>
				<hr>
				<p>MOOC.ca was created as a demonstration of open educational resource aggregation. The page you are viewing is
				an interface to our search function; use this to get a sense of the range of resources listed on this site.
				Click on the search button (upper left) to enter your query.</p>
				</div>
			|;
		}
	}


  # Execute search
	my $sql = "SELECT * FROM  course	WHERE $lang_where (course_title LIKE ? OR course_description LIKE ?) $orderby $limit ";
	# print $sql;

	my $sth = $dbh->prepare($sql) || die "Error: " . $dbh->errstr;
  $sth->execute("%".$vars->{query}."%","%".$vars->{query}."%")
		    || die "Error: " . $dbh->errstr;

  # Define defaults to identify first results
	my $firsttab = ""; if ($vars->{query}) { $firsttab = qq| id="firstTab"|; }

	my $block = qq|style="display:none;"|; if ($vars->{query}) { $block = qq|style="display:block;"|; }

	# Cycle through search results
	while (my $course = $sth -> fetchrow_hashref()) {

  	# Output search result, depending on request format

		if ($vars->{format} eq "links") {

   		print qq|<a href="javascript:void(0)" class="w3-bar-item w3-button w3-border-bottom test w3-hover-light-grey"
	    	onclick="openMail('course_|.$course->{course_id}.qq|');w3_close();" $firsttab>
      	<div class="w3-container">
        <img class="w3-round w3-margin-right" src="http://www.mooc.ca/images/|.$course->{course_provider}.qq|.icon.JPG" style="width:10%;">
				<span class="w3-opacity w3-large">$course->{course_title} </span>
        <p> </p>
      	</div>
    		</a>
			|;
    	$firsttab = "";

		} elsif ($vars->{format} eq "summary") {

      my $provider = &keylist("db=course;id=$course->{course_id};keytable=provider;");
			print qq|
				<div id="course_|.$course->{course_id}.qq|" class="w3-container person" $block>
  			<br>
  			<img class="w3-round w3-animate-top" src="http://www.mooc.ca/images/|.$course->{course_provider}.qq|.JPG" style="width:50%;">
  			<h5 class="w3-opacity">$course->{course_provider}</h5>
  			<h4><i class="fa fa-clock-o"></i> $course->{course_title}</h4>
  			<a target="_new" href="|.$course->{course_url}.qq|" class="w3-button w3-light-grey">View Course<i class="w3-margin-left fa fa-arrow-right"></i></a>
  			<hr>
				<p>Provider: $course->{course_provider}<p>
				<p>Language: $course->{course_language} <p>
  			<p>$course->{course_description}</p><p>Retrieved: |.&nice_date($course->{course_crdate},"day").qq|</p>
				</div>
    	|;
    	$block = qq|style="display:none;"|;

		}
	}

  # Output search footer, depending on request format


  if ($vars->{format} eq "links") {
		my $pg = $vars->{page}+1;
  	print qq|<div style="padding:2%"><a href="#" onClick="search_function('$vars->{query}','$vars->{language}','$vars->{sort}','links','Demo1',$pg);
	     search_function('$vars->{query}','$vars->{language}','$vars->{sort}','summary','Results-Content',$pg);">Next |;
		print $results_per_page;
		print qq| of $count results</a></div>|;
  }

	exit;

}

# Print OK for blank api request
#print "Content-type: text/json\n\n";
$vars->{message} .= qq|No command submitted or executed|; 
&status_ok();
	
exit;

# API OK & error responses are in grsshopper.pl
# see status+ok() and status_error()
