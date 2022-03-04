#-------------------------------------------------------------------------------

#	 gRSShopper  -     Common Functions  -   13 April 2021
#
#    Copyright (C) <2021>  <Stephen Downes, National Research Council Canada>
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

my $dirname = dirname(__FILE__);

# Editor
require $dirname . "/editor/analyze.pl";
require $dirname . "/editor/dates.pl";
require $dirname . "/editor/db.pl";
require $dirname . "/editor/editor.pl";
require $dirname . "/editor/files.pl";
require $dirname . "/editor/find.pl";
require $dirname . "/editor/format.pl";
require $dirname . "/editor/forms.pl";
require $dirname . "/editor/graph.pl";
require $dirname . "/editor/login.pl";
require $dirname . "/editor/logs.pl";
require $dirname . "/editor/make.pl";
require $dirname . "/editor/publish.pl";
require $dirname . "/editor/records.pl";
require $dirname . "/editor/tabs.pl";

# Services
require $dirname . "/services/bigbluebutton.pl";
require $dirname . "/services/email.pl";
require $dirname . "/services/facebook.pl";
require $dirname . "/services/mastodon.pl";
require $dirname . "/services/twitter.pl";
require $dirname . "/services/realfavicongenerator.pl";
require $dirname . "/services/webmentions.pl";
require $dirname . "/services/wikipedia.pl";
require $dirname . "/services/mailchimp.pl";
require $dirname . "/services/mailgun.pl";

# API
require $dirname . "/api/subscribe.pl";

our $gRSShopper_version = &read_text_file("version.txt");
our $diag = 0;



#		  INITIALIZATION
#-------------------------------------------------------------------------------


sub load_modules {
	my ($context) = @_;
	
	# Require Valid User Agent
  	#	die "Requests without valid user agent will be rejected" unless ($ENV{'HTTP_USER_AGENT'});

	use strict;
	use warnings;

	$!++;							# CGI
	use CGI;
	use CGI::Carp qw(fatalsToBrowser);
    

	use CGI::Session;
	our $query = new CGI;
	our $vars = $query->Vars;
	&filter_input($vars);				#	- filter CGI input

	# Required Modules
	use DBI;
	use LWP;
	use LWP::UserAgent;
	use LWP::Simple;



	# Added by Luc - Support for french (or other) dates
	# Required by : locale_date
	use POSIX qw(locale_h);
	use POSIX qw(strftime);
  	use POSIX qw(tzset);   # for time zones
	use Scalar::Util 'looks_like_number';
	use Date::Parse;

	# Moved from admin context below to here (for dates)
	use HTML::Entities;
							# Admin Modules
	if ($context eq "admin" || $context eq "api") {
		use File::Basename;
		use File::stat;
		use Scalar::Util 'blessed';
		use Text::ParseWords;
		use Lingua::EN::Inflect qw ( PL );
	}

						

							# Optional Modules
	unless (&new_module_load($query,"MIME::Types")) { $vars->{warnings} .= "MIME::Types;"; }
	unless (&new_module_load($query,"Net::Twitter::Lite::WithAPIv1_1")) { $vars->{warnings} .= "Net::Twitter::Lite::WithAPIv1_1;"; }
	unless (&new_module_load($query,"Image::Resize")) { $vars->{warnings} .= "Image::Resize;"; }
	unless (&new_module_load($query,"DateTime")) { $vars->{warnings} .= "DateTime;"; }
	unless (&new_module_load($query,"DateTime::TimeZone")) { $vars->{warnings} .= "DateTime::TimeZone;"; }
	unless (&new_module_load($query,"Time::Local")) { $vars->{warnings} .= "Time::Local;"; }
	unless (&new_module_load($query,"Digest::SHA1 qw/sha1 sha1_hex sha1_base64/")) { $vars->{warnings} .= "Digest::SHA1 qw/sha1 sha1_transform sha1_hex sha1_base64/"; }
	unless (&new_module_load($query,"XML::OPML")) { $vars->{warnings} .= "XML::OPML;"; }
	return ($query,$vars);
}
	#-------------------------------------------------------------------------------
	#
	#		New Module Load
	#
	#-------------------------------------------------------------------------------
sub new_module_load {

								# Load Non-Standard Modules

		my ($query,$module,@export) = @_;


		my $vars = ();
		if (ref $query eq "CGI") { $vars = $query->Vars; }
		eval("use $module @export;"); $vars->{mod_load} = $@;
		if ($vars->{mod_load}) {

			$vars->{error} .= qq|<p>In order to perform this function gRSShopper requires the $module
				Perl module. This has not been installed on your system. Please consult
				your system administratoir and request that the $module Perl mocule
				be installed.</p>|;
			return 0;

		}

		return 1;
	}
	#-------------------------------------------------------------------------------
	#
	#		Filter Input
	#
	#		All CGI input is filtered for security
	#
	#-------------------------------------------------------------------------------
sub filter_input {

	my ($vars) = @_;
	my $numArgs = $#ARGV + 1;					# Command Line Args (For Cron)

									# Do not allow these to be set by input
	$vars->{mode} = "";
	$vars->{cronsite} = "";
	$vars->{context} = "";

	# Default input variables
	unless (defined $vars->{format}) { $vars->{format} = "html"; }
	unless (defined $vars->{action}) { $vars->{action} = ""; }
	unless (defined $vars->{button}) { $vars->{button} = ""; }
	unless (defined $vars->{force}) { $vars->{force} = "no"; }
	unless (defined $vars->{comment}) { $vars->{comment} = ""; }


									# Apostraphe-proofs and hack-proof system

	while (my ($vx,$vy) = each %$vars) {        # Wipe apostraphes
		$vars->{$vx} =~ s/'/&#39;/g; # '
		$vars->{$vx} =~ s/\Q#!\E//g; # '
	}
	unless ($vars->{db}) { 											# Make old form requests compatible
		if ($vars->{table}) {
			$vars->{db} = $vars->{table};
		}
	}
	if ($numArgs > 1) {              					  # Cron
		$vars->{context} = "cron";
		$vars->{cronsite} = $ARGV[0];                # Site
		$vars->{action} = $ARGV[1];		# Command
		if ($vars->{action} eq "publish") { $vars->{page} = $ARGV[2]; }
		$vars->{preview} = $ARGV[2];		# Preview Option
		$vars->{person_status} = "cron";
		$vars->{mode} = "silent";
	}

}
	#-------------------------------------------------------------------------------
	#
	#		Get Site
	#
	#       Creates a new $Site object, initializes from data/multisite.txt
	#
	#-------------------------------------------------------------------------------
sub get_site {

	# print "Content-type: text/html\n\n";
	my ($context) = @_;


	if ($ARGV[1]) { $context = "cron"; }					# Set cron context, as appropriate
	if ($vars->{action} eq "cron") { 					# Note that a cron key is required to execute
		$context = "cron"; 						# from the command line
		$vars->{cronuser} = "web";
	}
	if ($context) { $vars->{context} = $context; }

	# Create new Site object
	our $Site = gRSShopper::Site->new({
		context		=>	$context,
		data_dir	=>	'./data/',		# Location of site configuration files
		secure => 1,							# Turns on SSH

	});

	# Open Site Database
	my $dbh = $Site->{dbh};


	# Get Site Info From Database
	&get_config($dbh);

	# Clear site database info so it's not available later
	$Site->{database}="";

	# Prevent accidental (or otherwise) print of config file.
	$_ = "";

	# File Upload Limit
	my $upload_limit = $Site->{file_limit} || 10000;
	$CGI::POST_MAX = 1024 * $upload_limit;
#&send_email("stephen\@downes.ca","stephen\@downes.ca","Returning $context... $Site,$dbh  ","Args: $ARGV[0] 1 $ARGV[1] 2 $ARGV[2] 3 $ARGV[3] \n");

	# Local::Lib (for cpanel sites)
	if ($Site->{st_url} =~ /downes\.ca/) { eval("use local::lib"); }

	return ($Site,$dbh);

}
	#-------------------------------------------------------------------------------
	#
	#		Get Config
	#
	#       Loads Site configuration from Database
	#
	#-------------------------------------------------------------------------------
sub get_config {

	my ($dbh) = @_;

	my $sth = $dbh->prepare("SELECT * FROM config");
	$sth -> execute() or die "Failed to load site configuration data";
	while (my $c = $sth -> fetchrow_hashref()) {
		next if ($c->{config_noun} =~ /context|script|st_home|st_url|st_urlf|st_cgif|st_cgi|co_host|msg/ig);	# Can't change basic site data
		next unless ($c->{config_value});
		$Site->{$c->{config_noun}} = $c->{config_value};
	}
	$sth->finish();

  # Set the time zones
  if ($Site->{st_timezone}) { $ENV{TZ} = $Site->{st_timezone}; }

}
	#-------------------------------------------------------------------------------
	#
	#		Get Person
	#
	#       Gets login information based on session cookie data
	#
	#-------------------------------------------------------------------------------
sub get_person {

	my ($Person,$username,$pstatus) = @_;


	if ($Site->{context} eq "cron") { 			# Create cron person, if applicable,
								# and exit

		$Person->{person_title} = $Site->{st_name};
		$Person->{person_name} = $Site->{st_name};
		$Person->{person_email} = $Site->{em_from};
		$Person->{person_status} = "Admin";
		return;

	}

	# Language, will fix
	$Site->{lang_user} = $query->cookie($language_cookie_name) || $Site->{lang_user} || "en";
  # print "Cookie data: ID $id Title $pt <br>";



					# Define Default Headers and Footers

	my $nowstr = &nice_date(time);	my $tempstr;
	$Site->{context} ||= "page";

	if (($Site->{context} eq "page")||($Site->{context} eq "admin")) {
		$Site->{header} = &get_template($Site->{context}."_header");
		$Site->{footer} = &get_template($Site->{context}."_footer");

		for ($Site->{header},$Site->{footer}) {
			$_ =~ s/\Q[*page_crdate*]\E|\Q[*page_update*]\E/$nowstr/sig;
		}
	}

	unless ($username) {		# No Person Info - Return anonymous User

		&anonymous(&printlang("No Person Info"));
		return;
	}


						# Get Person Data
						# Temporary - I should be building a proper Person object here

	my $persondata = &db_get_record($dbh,"person",{person_title=>$username});
	while (my($x,$y) = each %$persondata) {	$Person->{$x} = $y; }



	unless ($Person->{person_status} eq "admin") {		# Screen all non-admin from changing person_status
		$vars->{person_status} = "";
	}

	unless ($Person->{person_id}) { 	# No Person Data - Return anonymous User

		&anonymous("No Person Data");
		$Person->{person_status} = "anonymous";
	}

	unless ($Person->{person_status} || ($Person->{person_status} eq "reg")) {
		$Person->{person_status} = "registered";
	}

}

	# -------   Get Cookie Base ---------------------------------------------------
	#
	# Internal function to get site-specific cookie bases, derived from site URL
	# as defined in global $Site->{st_url} variable
sub get_cookie_base {

  my ($a) = @_;  # $a can be used for diagnostics

	my $site_base = $Site->{st_url};	# Get Site Cookie Prefix
	$site_base =~ s/http(s|):|\///ig;
	$site_base =~ s/\./_/ig;
	die "Site info not found in get_cookie_base" unless $site_base;
	return $site_base;
}

	# -------   Get File ---------------------------------------------------
	#
	# Internal function to get files
sub get_file {

	my ($file) = @_;
	my $content;

	open FIN,"$file" or return &printlang("Not found",$file);

	while (<FIN>) {
		$content .= $_;
	}
	close FIN;

	return $content;

}

	# -------   Anonymous ---------------------------------------------------------
	#
	# Makes an anonymous person
sub anonymous {
	my ($why) = @_;
	$Person->{person_title} = "Anymouse";
	$Person->{person_id} = 2;
	$Person->{person_name} = "Anymouse";
	$Person->{person_status} = "anonymous";
	$Person->{person_mode} = $why;

	# Get Person Data

	my $p;
	my $stmt = qq|SELECT * FROM person WHERE person_id = ?|;
	my $sth = $dbh -> prepare($stmt);
	$sth -> execute(2);
	my $ref = $sth -> fetchrow_hashref();
	while (my($x,$y) = each %$ref) {
		$p->{$x} = $y;
	}
	$sth->finish(  );

	# Place selected data into person hash
	$Person->{person_lastread} = $p->{person_lastread};

}

#           API INTEROP FUNCTIONS
#-------------------------------------------------------------------------------
	#----------Auto-Post------------------------------------------------------------
	#
	#	Takes a harvested link id as input
	#       Converts into a post
	#
	#-------------------------------------------------------------------------------

sub auto_post() {

	my ($linkid) = @_;

	my $link = &db_get_record($dbh,"link",{link_id=>$linkid});
	unless ($link->{link_id}) { return &printlang("Link error",$linkid); }


									# Uniqueness Constraints
	my $l = "";
	if (
	    ($l = &db_locate($dbh,"post",{post_link => $link->{link_link}}))  ||
	    ($l = &db_locate($dbh,"post",{post_title => $link->{link_title},post_feedid => $link->{link_feedid}}))
	    ) {
	    	$vars->{message} = "Not unique"; 
	    	return $l;
	}

									# Create post

	my $post = {
		post_journal => $link->{link_feed},
		post_journalname => $link->{link_feedname},
		post_creator => $Person->{person_id},
		post_feedid => $link->{link_feedid},
		post_crdate => $now,
		post_type => "link"
	};
									# Fill with link data
	while (my($lx,$ly) = each %$link) {

		my $px=$lx; $px =~ s/link_/post_/i;
		$post->{$px} ||= $ly;

	}

									# Fill with feed data
	my $feed = &db_get_record($dbh,"feed",{feed_id=>$link->{link_feedid}});
	while (my($lx,$ly) = each %$feed) {
		my $px=$lx; $px =~ s/feed_/post_/i;
		# $post->{$px} ||= $ly;   # Creates an error for post_updated
	}

	my $now = time;
  	$post->{post_crdate} = $now;	# Over-writes link crdate

	$post->{post_id} = &db_insert($dbh,$query,"post",$post);	# save post record

	# We don't want to auto-post to social media
	#$vars->{post_twitter}="yes";
	#$vars->{post_facebook}="yes";
	# $vars->{msg} .= &publish_post($dbh,"post",$post->{post_id});	# Publish to Social Media

									# Create post graph

	$post->{type} = "post";			# Declare types for graphing
	$link->{type} = "link";
	&clone_graph($link,$post)		# Clone link graph items for post
	&save_graph("posted",$link,$post);	# Create graph linking link, post


									# Update link status
	my $link = {
		link_post => $post->{post_id},
		link_status => "Posted"
	};
	&db_update($dbh,"link",$link,$linkid);


	my $file = &auto_make_icon("post",$post->{post_id});			# Make post icon

	if ($file) {								# If a file was uploaded to make the icon
										# Graph it to the post
		$file->{type} = "file";							# Declare types for graphing
		&save_graph("contains",$post,$file);					# Create graph linking post, file
	}




	return $post->{post_id};


}

# -------   API --------------------------------------------------------                                                  API
  #
  # 	General API Functions
  #
  #	      Edited: 24 September 2012
  #
  #----------------------------------------------------------------------
  #----------API: Send REST---------------------------------------------

sub api_send_rest {

  my ($dbh,$query,$url,$path,$data,$target) = @_;

								# Load REST::Client module
  unless (&new_module_load($query,"REST::Client")) {
	  print $vars->{error};
	  exit;
  }
								# Load JSON Module
  unless (&new_module_load($query,"JSON")) {
	  print $vars->{error};
	  exit;
  }

								# Load URI::Escape
  unless (&new_module_load($query,"URI::Escape")) {
	  print $vars->{error};
	  exit;
  }


			# Prepare content

			my $body = JSON->new->utf8->encode($data);

  $target =~ s/&amp;/&/g;
  $target = uri_escape($target);
  if ($target) { $target = "?target=$target"; }

  # Send Request

  my $client = REST::Client->new();
  $client->POST($url.$path.$target,$body);
  my $loc = $client->responseContent();

  # Return Redirect URL

  $loc =~ s/"//g;
  return $loc;

  exit;



}
sub api_receive_rest {

  my ($dbh,$query) = @_;




}

	#
	# -------  Next Buttom --------------------------------------------------------
	#
	#          Creates a 'Next' Button to page lists
	#          Called from list()
	#	     Edited: 27 March 2010
	#

sub next_button {

	my ($query,$table,$format,$start,$number,$count,$app) = @_;
    	my $vars = ();
    	if (ref $query eq "CGI") { $vars = $query->Vars; }

						# Reset Search Variables
	unless ($vars) { $vars = (); }
	$vars->{format} = $format;
	$vars->{start} = $start+$number;
	$vars->{number} = $number;
	$vars->{table} = $table;
	my $button = "";

						# Create Next Button Using Search Variables
	if (($start+$number)<$count) {

		$button = qq|<p><form method="post" id="$table-next-form"
		   action="javascript:list_form_submit('|.$Site->{st_cgi}.qq|api.cgi','$table-next-form',);">\n|;
		while (my ($fx,$fy) = each %$vars) {
			$fy =~ s/"/&quot;/g;		# "
			$button .= qq|<input type="hidden" name="$fx" value="$fy">|;

		}
		$button .= qq|
						 <input type="submit" id="$table-next-button" value="Next $number Results" class="button">|;
		$button .= "<form></p>";
	}



	return $button;
}

	# -------------------------------------------------------------------
	#
	#  Prevents endless loops
	#
sub escape_hatch {
	$vars->{escape_hatch}++; die "Endless recursion keyword loop" if ($escape_hatch > 10000);

}






#           Utility Functions

	#-------------------------------------------------------------------------------
	#
	#           Misc. Utilities
	#
	#-------------------------------------------------------------------------------
sub printlang {						# Print in current language
							# languages loaded in gRSShopper::Site::__load_languages()

	my @vars = @_; $counter = 1;
	my $langstring = $vars[0];
	return unless ($langstring);

  	$langstring =~ s/&#39;/&apos;/g;                       # (probably need a more generic decoder here
	$Site->{lang_user} ||= $Site->{site_language};		   # Current language, as selected from session
	my $output = "";

	# Are we using a dictionary? If so, $langstring will specify it using a colon
	# ie., dictionary:langstring
	# The first time we encounter the dictionary, we'll load it

	my ($dictionary,$lstring) = split /:/,$langstring;					# Find duictionary and string, fix
	unless ($lstring) {$lstring = $dictionary; $dictionary = ""; }		# in case no dictionary is declared
	my $instructions;
	if ($dictionary && $Site->{$Site->{lang_user}}->{$dictionary} ne "loaded") { 
		$instructions .= &load_dictionary($dictionary,$lstring);
	} 

	# Convert the language string. Note how we can insert variables (designated by #1, #2, etc)
	# into the string
	if ($Site->{$Site->{lang_user}}->{$lstring}) {
		$output .= $Site->{$Site->{lang_user}}->{$lstring};
		while () {
			my $var_number = '#'.$counter;
			if ($output =~ m/$var_number/) {
				$vars[$counter] =~ s/&#39;/&apos;/g;
				$vars[$counter] =~ s/&quot;/"/g;   								# Allows insertion of quotation marks for eg. URLs
				$output =~ s/$var_number/$vars[$counter]/g;

			} else { last; }
			$counter++;
		}
	}

	if ($output) {	# Return the translated output, or
		$output =~ s/&quot;/"/g;
		return $output;
	} elsif ($dictionary) {   # Return instructions for the dictionary, or
		return $instructions;
	} else {
		return $langstring; # Return the unaltered language string
	}
}

sub load_dictionary {
	my ($dictionary,$langstring) = @_;

	$dictionary = $dictionary.".".$Site->{lang_user};    # eg. 'terms.en'
	my $dictionary_record = &db_get_record($dbh,"optlist",{optlist_title=>$dictionary});
	my $dictionary_contents = $dictionary_record->{optlist_data};
	
	unless ($dictionary_contents) { 
		return &dictionary_help($dictionary,$Site->{lang_user}); 
	}
	my @langitems = split /;/,$dictionary_contents;
	foreach my $l (@langitems) {
		my ($lstr,$ltxt) = split /,/,$l; 
		$lstr =~ s/^\s*//; # Remove leading spaces (allows us to use cr in optlist)
print "Loading: $lstr = $ltxt <p>";
		$Site->{$Site->{lang_user}}->{$lstr} = $ltxt;

	
	}

	#print "SET TO LOADED: $dictionary".$Site->{$Site->{lang_user}}->{$dictionary}."<p>";
	#$Site->{$Site->{lang_user}}->{$dictionary} = "loaded";

}

sub dictionary_help {

	my ($d,$l) = @_;
	return qq|Dict help|;
	return qq|
		Dictionary $d not found. To create this dictionary, create an optlist and
		give it the title $d.$l and place in the optlist_data field the language strings you would
		like converted, in the form: string:text;string:text etc. Do this for each language
		you would like to support. Call this function in the page with: langstring $d:string;
	|;


}
	#-------------------------------------------------------------------------------
sub isint{						# Is it an integer?
  my $val = shift;
  return ($val =~ m/^\d+$/);
}



sub status_error {

	my ($message) = @_;
	my $errorResponse = {
		status => "Error",
		response => "Error",
		message => $message
	};
	my $json = encode_json $errorResponse;
	#unless ($Person->{person_id}) { print "Content-type: text/json\n\n"; } 
	print $json;
	exit;

}

sub status_ok {

	my ($div,$contents) = @_;		# Information to reload a div for a status update
	my $json_text = encode_json ($contents);

	unless ($Person->{person_id}) { print "Content-type: text/json\n\n"; } 
	print "{";
	print sprintf(qq|"response":"OK"|);
	print sprintf(qq|,"status":"OK"|);
	if ($div && $contents) {
		print sprintf(qq|,"div":"$div"|);
		print sprintf(qq|,"contents":$json_text|);
	}
	my $json = encode_json $vars->{message};
	print sprintf(qq|,"message":%s|,$json) if ($vars->{message}); 
	print "}";
	exit;

}


sub error {

	my ($dbh,$query,$person,$msg,$supl) = @_;
	my $vars = ();
	if (ref $query eq "CGI") { $vars = $query->Vars; }

	if ($vars->{mode} eq "silent") { exit; }


	if ($person eq "api") {

		print qq|<p class="notice">$msg</p>|;
		exit;
	}



	if ($msg eq "404") {
 print "Content-type: text/html\n\n";
		print "Status: 404 Not Found\n\n";
		print '<!-- ' . ' ' x 512 . ' -->'; # IE 512 byte limit cure
		print "404 - File Not Found\n$supl";
	} else {


							# Page header


		print qq|<div class="error"><b>Error</b>: $msg</div>|;


  #	my $adr = 'stephen@downes.ca';
  #	my $env_values = &show_environment();
  #	&send_email($adr,$adr,
  #		"Error on Website",
  #		"Error message: $msg\nSupplementary:$supl\n\n$env_values\n\n");
  #	&log_event($dbh,$query,"error","Error message: $msg\nSupplementary:$supl");


	}

	exit if ($dbh eq "nil");
	if ($dbh) { $dbh->disconnect; }
	exit;
}
 #
#
sub error_inline {

	my ($dbh,$msg,$supl) = @_;
	my $vars = ();

	if (ref $query eq "CGI") { $vars = $query->Vars; }
	if ($vars->{mode} eq "silent") { exit unless ($supl eq "nonterminal"); return; }

	# API Error
	if ($person eq "api") {  print qq|<p class="notice">$msg</p>|;	exit;	}

	# 404 Error
	if ($msg eq "404") {
		print "Content-type: text/html\n\n";
		print "Status: 404 Not Found\n\n";
		print '<!-- ' . ' ' x 512 . ' -->'; # IE 512 byte limit cure
		print "404 - File Not Found\n$supl";
		exit;
	}


	# Other Errors
	print "Content-type: text/html\n\n";
	print qq|<h2>@{[&printlang("Error")]}</h2>|;
	print "<div id='notice_box'>";
	print "<p>$msg</p></div>";

	if ($dbh) { $dbh->disconnect; }
	exit unless ($supl eq "nonterminal");
}
 #

	# -------  Index Of ------------------------------------------------------------
	#   Checks for membership of variable in an array
sub index_of {


	my ($item,$array) = @_;
	my $index_count = 0;
	foreach my $i (@$array) {
		if ($item eq $i) { return $index_count; }
		$index_count++;
	}
	return "-1";
}

	# -------  Base URL ------------------------------------------------------------
sub site_url {

	my ($url) = @_;

	my @urlarr = split "/",$url;
	return $urlarr[2];

}
















#           PACKAGES
#----------------------------------------------------------------------------------------------------------

package gRSShopper::Temp;

   use strict;
  use warnings;
  our $VERSION = "1.00";


  sub new {

  	my($class, $context, $args) = @_;
   	my $self = bless({}, $class);

   	$self->{context} = $context;
   	while (my ($ax,$ay) = each %$args) {
		$self->{$ax} = $ay;
   	}

  	$self->{process} = time;					# Make process name
  	$self->{site_url} = $self->home();

 	return $self;
  }

 1;

	#----------------------------------------------------------------------------------------------------------
	#
	#                                             gRSShopper::Site
	#
	#----------------------------------------------------------------------------------------------------------
package gRSShopper::Site;

  # $Site = gRSShopper::Site->new({name=>value});


  use strict;
  use warnings;
  our $VERSION = "1.00";


  sub new {

  	# Load Site object
  	my($class, $args) = @_;
   	my $self = bless({}, $class);

  	# Assign default values when Site created, eg. location of site configuration file multisite.txt
  	#   context =>	$context,
  	#   data_dir =>	'/var/www/cgi-bin/data/',
  	#   secure => 1,

   	while (my ($ax,$ay) = each %$args) { $self->{$ax} = $ay;  }


   	# Make process name
  	$self->{process} = time;


	# Define Site home URL from $ENV data
  	# (Used to find database info in multisite.txt)
    $self->__home();
	$self->__dbinfo();			    # Find db info from multisite.txt


  	unless ($self->{no_db}) {
	  	$self->__db_connect();
  		unless ($self->{dbh}) { die "Cannot connect to site database"; }
  	}

   	# Load language translation packages
   	$self->__load_languages();

  	return $self;
  }


  #  __home()  - assigns core directory and database names and data
  #  	- Determines site URL based on CGI or Cron request

  sub __home {

  	my($self, $args) = @_;

  	# Check whether URLs are https or http
  	my $http;
  	if ($self->{st_secure} || $self->{secure}) { $http = "https://" } else { $http = "http://"; }

	# Assumes directory structure is /var/www/$host/html/cgi-dir/data/multisite.txt

  	# Determine site host for HTTP or Cron
	my $numArgs = $#ARGV + 1;  
  	if ($ENV{'HTTP_HOST'}) { $self->{st_host} = $ENV{'HTTP_HOST'}; }     				 # HTTP
  	elsif ($numArgs > 1) { $self->{context} = "cron";$self->{st_host} = $ARGV[0]; }		 # Cron
	else { die "Cannot find website host from HTTP or Cron input."; }

	# Set Up Site Variables
	my $host = $self->{st_host}; my $hostdir;

	our $first = &get_file("/var/www/html/cgi-bin/first.txt");   # Contains the name of the first host
	if ($self eq $first) { $hostdir = "/var/www/html/"; }		 # First host uses plain html/ directory
	else {  $hostdir = "/var/www/$hostdir/html/";	}			 # Subsequent hosts get their own directories
	$self->{script} = $0; 
	$self->{data_dir} = $hostdir."cgi-bin/data/";
	$self->{st_urlf} = $hostdir;
	$self->{st_cgif} = $hostdir."cgi-bin/";		

  	# Set derived URLs based on st_host
   	$self->{st_url} = $http . $self->{st_host} . "/";
	$self->{st_cgi} = $self->{st_url} . "cgi-bin/";

  	# Set cookie host
 	$self->{co_host} = $self->{st_host};

   	# Set Default Language
	$self->{site_language}  ||= 'en';

  }




  #  db_info - gets the database info for the site in multisite mode
  #          - requires as input the 'base url' as determiend by $self->home()
  #          - data is in cgi-bin/data/multisite.txt   (this can be changed at the top of this file)
  #          - format:   site_url\tdatabase name\tdatabase host\tdatabase user\tdatabase user password\n
  #

  sub __dbinfo {


  	my ($self,$args) = @_;

	# Open the multisite configuration file,
	# Initialize if file can't be found or opened

  	my $data_file = $self->{st_cgif}."data/multisite.txt";
	open IN,"$data_file" or die qq|Cannot find $data_file|; 
	
#	    $data_file to define website parameters. $?
#		  Args: 0 $ARGV[0] 1 $ARGV[1] 2 $ARGV[2] 3 $ARGV[3]|;
#
		#$self->__initialize("file");  # -------------------------------------------------------------> Initialize file


	# Find the line beginning with site URL
	# and read site database information from it

	my $url_located = 0; my $count=0;
  	while (<IN>) {
		my $line = $_; $line =~ s/(\s|\r|\n)$//g;

# No longer using first line as default; if it doesn't match the domain, it isn't used

#		if ($line && $count==0) { # Assign defualts with first line
#			( $self->{st_home},
#			$self->{database}->{name},
#			$self->{database}->{loc},
#			$self->{database}->{usr},
#			$self->{database}->{pwd},
#			$self->{site_language},
#			$self->{urlf},
#			$self->{cgif} ) = split "\t",$line;   
#		}
		if ($line =~ /^$self->{st_host}/) {
			( $self->{st_home},
			  $self->{database}->{name},
			  $self->{database}->{loc},
			  $self->{database}->{usr},
			  $self->{database}->{pwd},
			  $self->{site_language} ) = split "\t",$line;
			$url_located = 1;
			last;
		}
		$count++;
	}
	close IN;

	# Initialize if line beginning with site URL can't be found
	unless ($self->{database}->{name}) { 
		die "Cannot determine the name of the database to use. Please initialize site at ".$self->{st_cgi}."server_test.cgi"; 
	} 
	
	return;
  }

  # load_languages - gets list of comma-delimited languages from multisite.txt
  #    - cycles though the list and runs the related language file eg. en.pl
  #    - thus storing language strings in a language hash
  #    - which is used by printlang() to print text in the right language

  sub __db_connect {

    	my ($self,$args) = @_;

    	# Make variables easy to read :)
    	my $dbname = $self->{database}->{name};
    	my $dbhost = $self->{database}->{loc};
    	my $usr = $self->{database}->{usr};
    	my $pwd = $self->{database}->{pwd};

	# Connect to the Database
  	$self->{dbh} = DBI->connect("DBI:mysql:database=$dbname;host=$dbhost;port=3306",$usr,$pwd);

	# Catch connection error
	if( ! $self->{dbh} ) {
		die qq|Database connection error for db '$dbname' on '$dbhost'. 
			Please contact the site administrator.\n
			Error String Reported: $DBI::errstr \n|; 
	}

  }

  sub __load_languages {

  	my ($self,$args) = @_;

  	# Set default language
  	$self->{site_language} ||= "en";

      # Find location of language pack directory
	use File::Basename;
      my $dirname = dirname(__FILE__);
      $dirname .= "/";

  	# Cycle through list of languages from multisite.txt (separated by commas)
  	my @languages = split /,/,$self->{site_language};
	foreach my $lang (@languages) {

		# Set current site and user defaults (the first language in the list)(
		unless ($self->{lang_default}) { $self->{lang_default} = $lang; }
		unless ($self->{lang_user}) { $self->{lang_user} = $lang; }

		# Determine language file name, this is where translations are stored
		my $lang_filename = $dirname . "languages/".$lang . ".pl";

		# Execute the language file (stores translations into a hash)
		if (-e $lang_filename) {
			open LIN,"$lang_filename" or die "Language file $lang_filename not found.";
			while (<LIN>) {
				my $l = $_;

				$l =~ m/'(.*?)'(.*?)('|")(.*?)('|")/;
				if ($1) { $self->{$lang}->{$1} = $4;  }

			}
			close LIN;

		} else {
			die "Was expecting to find $lang_filename but it was not found.";
		}
	}

  }

  # -------   Get File ---------------------------------------------------

  # Internal function to get files

  sub get_file {

	my ($file) = @_;
	my $content;
	open FIN,"$file" or return "$file not found";
	while (<FIN>) {
		$content .= $_;
	}
	close FIN;
	return $content;

  }


	#----------------------------------------------------------------------------------------------------------
	#
	#                                             gRSShopper::Page;
	#
	#----------------------------------------------------------------------------------------------------------
package gRSShopper::Page;

  use strict;
  use warnings;
  our $VERSION = "1.00";

  sub new {
  	my($class, $site, %args) = @_;
   	my $self = bless({}, $class);
 	my $target = exists $args{target} ? $args{target} : "world";
	$self->{target} = $target;

	$self->{site} = $site;
	$self->{context} = $site->{context};



 	return $self;
  }

  
  sub target {
	my $self = shift;
	if( @_ ) {
		my $target = shift;
      	$self->{target} = $target;
	}
	return $self->{target};
  }


  sub to_string {
   	my $self = shift;
   	return $self->{page_content};
  }

  sub print {
  	my $self = shift;
   	print $self->to_string(), "\n";
  }

	#----------------------------------------------------------------------------------------------------------
	#
	#                                             gRSShopper::File
	#
	#----------------------------------------------------------------------------------------------------------
package gRSShopper::File;

  # $item = gRSShopper::Record->new("count",$itemcount);


  use strict;
  use warnings;
  our $VERSION = "1.00";


  sub new {
  	my($class, %args) = @_;
   	my $self = bless({}, $class);

 	$self->{file_title} = "Title";
 	$self->{file_dir} = "";
 	$self->{file_type} = "";


 	$self->{filename} = "";
 	$self->{filedirname} = "";
	$self->{fullfilename} = "";
	$self->{dir} = "";
	$self->{filetype} = "";

 	return $self;
  }
 1;



	#----------------------------------------------------------------------------------------------------------
	#
	#                                             gRSShopper::Database;
	#
	#----------------------------------------------------------------------------------------------------------
package gRSShopper::Database;

  #  $Person = gRSShopper::Person->new({person_title=>'title',person_password=>'password'});
  # Note that password will be encrypted in save


  use strict;
  use warnings;
  our $VERSION = "1.00";



sub new {
  	my($class, $args) = @_;
   	my $self = bless({}, $class);
   	while (my($ax,$ay) = each %$args) {
   		#print "$ax = $ay <br>";
   		$self->{$ax} = $ay;

    }
		return $self;

  }




		# -------   Columns -----------------------------------------------------------
sub db_columns {


		my ($self,$table) = @_;			# Get a list of columns

		my $dbh = $self->{dbh};
		die "Database not ready in db_columns" unless ($dbh);
		die "No table defined in db_columns" unless ($table);


		my @columns = ();
		my $showstmt = "SHOW COLUMNS FROM $table";

		my $sth = $dbh -> prepare($showstmt);
		$sth -> execute();
		while (my $showref = $sth -> fetchrow_hashref()) {
			push @columns,$showref->{Field};
		}
		return @columns;

	}

	# -------   Get Column --------------------------------------------------------
sub db_get_column {

	my ($self,$table,$field) = @_;

	my $dbh = $self->{dbh};
	die "Database not ready in db_get_columne" unless ($dbh);

	my $stmt = qq|SELECT $field FROM $table|;
	my $names_ref = $dbh->selectcol_arrayref($stmt);
	return $names_ref;
}


	# -------   Get Single Value--------------------------------------------------------
sub db_get_single_value {

	my ($self,$table,$field,$id,$sort,$cmp) = @_;

	my $dbh = $self->{dbh};
	die "Database not ready in db_get_single_value" unless ($dbh);

	&error($dbh,"","","Database not initialized in get_single_value") unless ($dbh);
	&error($dbh,"","","Table not initialized in get_single_value") unless ($table);
	unless ($sort) { &error($dbh,"","","Field not initialized in get_single_value") unless ($field); }
	#&error($dbh,"","","ID number not initialized in get_single_value") unless ($id);
	return unless ($id || $sort);

	my $idfield = $table."_id";								# define id field name
	my $t = $table."_";unless ($field =~ /$t/) { $field = $t.$field; }	# Normalize field field name
	if ($sort) { $sort = "ORDER BY $sort"; }
	my $where; if ($idfield && $id) {
		if ($cmp eq "lt" && $id>0) { $where = qq|WHERE $idfield<$id|; }
		elsif ($cmp eq "gt" && $id>0) { $where = qq|WHERE $idfield>$id|; }
		else { $where = qq|WHERE $idfield='$id'|; }
	}

	my $stmt = qq|SELECT $field FROM $table $where $sort LIMIT 1|; 	# Perform SQL
	my $ary_ref = $dbh->selectcol_arrayref($stmt);
	my $ret = $ary_ref->[0];

	return $ret;

}

# -------   Get Record -------------------------------------------------------------
sub db_get_record {

	my ($self,$table,$value_arr) = @_;

	my $dbh = $self->{dbh};

	die "Database not ready in db_get_record" unless ($dbh);
	die "Table not defined in db_get_record" unless ($table);

	my @value_list; my @value_vals;
	while (my($kx,$ky) = each %$value_arr) { push @value_list,"$kx=?"; push @value_vals,$ky; }
	my $value_str = join " AND ",@value_list;
	unless ($value_vals[0]) { warn "No value input to db_get_record"; return; }
	my $stmt = "SELECT * FROM $table WHERE $value_str LIMIT 1";
	my $sth = $dbh -> prepare($stmt);
	$sth -> execute(@value_vals);
	my $ref = $sth -> fetchrow_hashref();
	$sth->finish(  );

	return $ref;
}

# -------   Insert --------------------------------------------------------

# Adapted from SQL::Abstract by Nathan Wiger
sub db_insert {		# Inserts record into table from hash


	my ($self,$table,$input) = @_;

  my $dbh = $self->{dbh};
  die "Database not ready in db_insert" unless ($dbh);
  die "No table provided for db_insert" unless ($table);
  die "No input data provided for db_insert" unless ($input);

  # Filter  input hash to contain only columns in given table
	my $data= $self->db_prepare_input($table,$input);

  # Prepare SQL Statement
	my $sql   = "INSERT INTO $table ";
	my(@sqlf, @sqlv, @sqlq) = ();
	for my $k (sort keys %$data) {
		push @sqlf, $k;
		push @sqlq, '?';
		push @sqlv, $data->{$k};
	}
	$sql .= '(' . join(', ', @sqlf) .') VALUES ('. join(', ', @sqlq) .')';

  # Insert into database
	my $sth = $dbh->prepare($sql) or die "Could not prepare sql in db_insert: ".$dbh->errstr;		# Prepare SQL Statement
	$sth->execute(@sqlv) or die "Could not execute sql in db_insert: ".$sth->errstr;		# Execute SQL Statement
	my $insertid = $dbh->{'mysql_insertid'};
	$sth->finish(  );
	return $insertid;
}
# -------  Update---------------------------------------------------------
# Updates record $where (must be ID) in table from hash
# Adapted from SQL::Abstract by Nathan Wiger
# -------  Update---------------------------------------------------------
# Updates record $where (must be ID) in table from hash
# Adapted from SQL::Abstract by Nathan Wiger
sub db_update {

	my ($self,$table,$input,$where,$msg) = @_;
	my $dbh = $self->{dbh};
	#print "Content-type: text/html\n\n";
	unless ($dbh) { die "Error $msg Database handler not initiated"; }
	unless ($table) { die "Error $msg Table not specified on update"; }
	unless ($input) { die "Error $msg No data provided on update"; }
	unless ($where) { die "Error $msg Record ID not specified on update"; }

	die "Unsupported data type specified to update" unless (ref $input eq 'HASH' || ref $input eq 'Link' || ref $input eq 'Feed' || ref $input eq 'gRSShopper::Record' || ref $input eq 'gRSShopper::Feed');
	#print "Updating $table $input $where <br>";
	my $data = $self->db_prepare_input($table,$input);
	#print "Data: $data <br>";
	#return "No data" unless ($data);

	my $sql = "UPDATE $table SET ";
	my(@sqlf, @sqlv) = ();

	for my $k (sort keys %$data) {
		push @sqlf, "$k = ?";
		push @sqlv, $data->{$k};

				}

	$sql .= join ', ', @sqlf;
	$sql .= " WHERE ".$table."_id = '".$where."'";

	#  print "$sql <br>";
	#  foreach $l (@sqlv) { print "$l ; "; }
	my $sth = $dbh->prepare($sql);

	$sth->execute(@sqlv) or die "Update $sql failed: ".$sth->errstr;

	return $where;


}
# -------   Locate -------------------------------------------------------------

# Find the ID number given input values
# Used by new_user() among other things

sub db_locate {

	my ($self,$table,$vals) = @_;

	my $dbh = $self->{dbh};
	die "Database not ready in db_locate" unless ($dbh);
						# Verify Input Data

	die "db_locate(): Cannot locate with no values" unless ($vals);

						# Prepare SQL Statement
	my $stmt = "SELECT ".$table.
		"_id from $table WHERE ";
	my $wherestr = ""; my @whvals;
	while (my($vx,$vy) = each %$vals) {
		if ($wherestr) { $wherestr .= " AND "; }
		$wherestr .= "$vx = ?";
		push @whvals,$vy;
	}
	$stmt .= $wherestr . " LIMIT 1";

	my $sth = $dbh->prepare($stmt);		# Execute SQL Statement

	$sth->execute(@whvals) or return 0;

		my $hash_ref = $sth->fetchrow_hashref;
	$sth->finish(  );

	return $hash_ref->{$table."_id"};

}

# -------   Prepare Input ----------------------------------------------------
sub db_prepare_input {	# Filters input hash to contain only columns in given table

  my ($self,$table,$input) = @_;

	my $dbh = $self->{dbh};
	die "Database not ready in db_prepare_input" unless ($dbh);
	die "No table provided for db_prepare_input" unless ($table);
	die "No input data provided for db_prepare_input" unless ($input);

	#print "DB Prepare Input ($table $input)<br/>\n";
	my $data = ();

	# Get a list of columns
	my @columns = $self->db_columns($table);

	# Clean input for save
	foreach my $ikeys (keys %$input) {

    # Make sure the value is defined
		next unless (defined $input->{$ikeys});

    # Not allowed to set primary key
		next if ($ikeys =~ /_id$/i);
		next if ($ikeys =~ /^id$/i);

		# Skip if the table doesn't have that field defined
		next unless (grep( /$ikeys/, @columns ));

		# Set data
		# print "$ikeys = $input->{$ikeys} <br>";
		$data->{$ikeys} = $input->{$ikeys};
	}

	return $data;

}


sub db_table_exist {
			my ($self,$table_name) = @_;

      my $dbh = $self->{dbh};
	    die "Database not ready in db_table_exist" unless ($dbh);

			my @tables = $self->db_tables();
			if (grep( /$table_name/, @tables )) { return 1; }
			else { return 0; }

	}


#-------------------------------------------------------------------------------
#
# -------   Database Tables ---------------------------------------------------------
#
# 		Returns the list of tables in the database
#	      Edited: 28 March 2010
#-----------------------------------------------------------------------------
sub db_tables {

	my ($self) = @_; my @tables;

	my $dbh = $self->{dbh};
	die "Database not ready in db_tables" unless ($dbh);

	my $sql = "show tables";
	my $sth = $dbh->prepare($sql);
	$sth->execute();
	while (my $hash_ref = $sth->fetchrow_hashref) {
		while (my($hx,$hy) = each %$hash_ref) { push @tables,$hy; }
	}
	return @tables;
}
1;




	#----------------------------------------------------------------------------------------------------------
	#
	#                                             gRSShopper::Feed
	#
	#----------------------------------------------------------------------------------------------------------
package gRSShopper::Feed;

  # $item = gRSShopper::Feed->new("count",$itemcount);


  use strict;

  use warnings;
  our $VERSION = "1.00";
  our @ISA = qw(gRSShopper::Record);    # inherits from Record


  sub new {

  	my($class, $args) = @_;
   	my $self = bless({}, $class);

	$self->set_type("feed");				# Default values
	$self->{content_buffer} = "";
	$self->{attributes_buffer} = "";
 	$self->{feed_title} = "";
 	$self->{feed_id} = "new";
 	$self->{feed_dir} = "";
 	$self->{feed_type} = "";
 	$self->{error} = "";
 	$self->{feedstring} = "";				# Feed as single string
 	$self->{stack} = [];					# array of tags used in processing


	if ($args->{id}) {
		$self->load_feed($args->{dbh},$args->{id});
	}


 	return $self;
  }


  sub load_feed {

	my $self = shift;
	my $dbh = shift;
	my $id = shift;

	die "Database not ready in _load_feed" unless ($dbh);
	my $stmt = "SELECT * FROM feed WHERE feed_id = ?";
	my $sth = $dbh->prepare($stmt);
	$sth -> execute($id);
	my $ref = $sth -> fetchrow_hashref();
	while (my($fx,$fy) = each %$ref) {
		$self->{$fx} = $fy;
	}

	return;

  }
 ## use padre_syntax_check
  sub get_feed {

	my ($self) = @_;
	$self->{feedstring} = "";
	my $cache = &feed_cache_filename($self->{feed_link});
	if ((time - (stat($cache))[9]) < (60*60)) {			# If the file is less than 1 hour old
		$self->{feedstring} = &get_file($cache);
  #print "Getting feedstring from cache<p>";
	} else {

  #print "Getting feedstring from web<p>";
		my $ua = LWP::UserAgent->new();
		my $response = $ua->get($self->{feed_link},{
			'User-Agent' => 'gRSShopper 0.3',
			'Accept' => '*/*','application/atom+xml',
			'Accept-Charset' => 'iso-8859-1,*,utf-8',
			'timeout' => '30'
		});

		if (! $response->is_success) {
			my $err = $response->status_line;
			my $as_string = $response->as_string;
			my ($r_header,$r_body) = split "<",$as_string;
			$r_header =~ s/\n/<br>\n/g;
			#$err .= $response->head;
			return "ERROR:  $err ".$r_header." <br>$r_body<br>";
		}

		$self->{feedstring} =~ s/^\s+//;			# Remove leading spaces
		$self->{feedstring} = $response->content;
		return "ERROR: Couldn't get $self->{feed_link} <br>" unless ($self->{feedstring});   #'

									# Save common cache
		open FOUT,">$cache" or die "Error opening $cache: $!";
		print FOUT $self->{feedstring}  or die "Error writing to $cache: $!";
		close FOUT;
	}

	return;

  }

  sub feed_cache_filename  {


	my ($feedurl,$feed_cache_dir) = @_;

	my $feed_file = $feedurl;
	$feed_file =~ s/http:\/\///g;
	$feed_file =~ s/https:\/\///g;
	$feed_file =~ s/\%|\$|\@//g;
	$feed_file =~ s/(\/|=|\?)/_/g;

	return $feed_cache_dir.$feed_file;

  }

  # -------   Get File ---------------------------------------------------

  # Internal function to get files

  sub get_file {

	my ($file) = @_;
	my $content;
	open FIN,"$file" or return "$file not found";
	while (<FIN>) {
		$content .= $_;
	}
	close FIN;
	return $content;

  }
  1;









	#----------------------------------------------------------------------------------------------------------
	#
	#                                             gRSShopper::Person;
	#
	#----------------------------------------------------------------------------------------------------------
package gRSShopper::Person;

  # $Person = gRSShopper::Person->new({person_title=>'title',person_password=>'password'});
  # Note that password will be encrypted in save


  use strict;
  use warnings;
  our $VERSION = "1.00";
  # use Temp;

  sub new {
  	my($class, $args) = @_;
   	my $self = bless({}, $class);
   	while (my($ax,$ay) = each %$args) {
   		print "$ax = $ay <br>";
   		$self->{$ax} = $ay; }
 	 return $self;
   }


  sub create {

	my ($self,$dbh) = @_;

	return "no database handler" unless $dbh;
	return "no person title defined" unless $self->{person_title};
	return "no person password defined" unless $self->{person_password};
	return "no person emaild defined" unless $self->{person_email};

	$self->{person_password} = _password_encrypt($self->{person_password},4);
	$self->{person_crdate} = time;
	$self->{person_status} = "reg";
	$self->{person_id} = &db_insert($dbh,"","person",$self);
	unless ($self->{person_id}) { &error($dbh,"","","Error, no new account was created."); 	}

  }

  sub _password_encrypt {
	my ($pwd,$count) = @_;
	my @salt = ('.', '/', 'a'..'z', 'A'..'Z', '0'..'9');
	my $salt = "";
	$salt.= $salt[rand(63)] foreach(1..$count);
	my $encrypted = crypt($pwd, $salt);
	return $encrypted;
  }

  sub target {
	my $self = shift;
	if( @_ ) {
		my $target = shift;
      	$self->{target} = $target;
	}
	return $self->{target};
  }


  sub to_string {
   	my $self = shift;
   	return $self->{page_content};
  }

  sub print {
  	my $self = shift;
   	print $self->to_string(), "\n";
  }

  1;



	#----------------------------------------------------------------------------------------------------------
	#
	#         gRSShopper::Record;
	#
	#      	table			   	(string) Record Table
	#		id 						(int) Record ID
	#       parent        (::Record) Parent record
	#       person        (::Person) person creating the record
	#		tags		Record type - associated with different types of record: feed, link, content, media, author, event
	#   	db            (::Database) Pointer to database functions
	#   	dbh          	(::DBI) Pointer to DBI database handler
	#		data 					(hash reference) Data that accompanies the opening of the record
	#		load  				(boolean) if 1, load record data from database

	#----------------------------------------------------------------------------------------------------------
		#
		#  Create using tag:  $item = gRSShopper::Record->new({tag=>'tagname'});
		#  Tags are associated with different types of record: feed, link, content, media, author, event

	package gRSShopper::Record;

	  # $item = gRSShopper::Record->new("count",$itemcount);


	  use strict;
	  use warnings;
	  our $VERSION = "1.00";


	  sub new {
	  	my($class, %args) = @_;
	   	my $self = bless({}, $class);

			# Import values from call
	  	foreach ( keys %args ) { $self->{$_} = $args{$_};
        #print "New record: $class \n";
				#printf("%s = %s\n",$self->{$_},$args{$_});
			}

			# Set Record Type
	    $self->{type} ||= $self->set_type($self->{tag});

			# Import values from parent
			if ($self->{parent}->{type}) {
				&flow_values($self->{parent},$self->{parent}->{type},$self,$self->{type});	# Inherit values from the parent
			}											# Actual values may override

	    # Load record data from databases
			if ($self->{id} && $self->{id} eq "new") { $self->{id} = $self->create();}
			&load($self) if ($self->{load});

			# If autopost is called...

			#NOTE: this is disabled, it's in 
			if (0 && $self->{data}->{autopost} && $self->{data}->{autopost} ne "" && $self->{data}->{autopost} ne "undefined") {
#print "Main window  trying to do autopost on ".$self->{data}->{autopost}." <p>";
				my ($autocommand,$autotable,$autoid) = split '-',$self->{data}->{autopost};

				# Get the link being autoposted
				my $autorecord = gRSShopper::Record->new(
					table => $autotable,
					id => $autoid,
					db => $self->{db},
					dbh => $self->{dbh},
					person => $self->{person},
					load => 1,
				);

				# Copy its values into the new record and save the record
				if ($autocommand eq "post") {
					$self->{$self->{table}."_title"} = $autorecord->{$autotable."_title"};
					$self->{$self->{table}."_link"} = $autorecord->{$autotable."_link"};
					$self->{$self->{table}."_description"} = $autorecord->{$autotable."_description"};
					$self->{$self->{table}."_content"} = $autorecord->{$autotable."_content"};
				}

				$self->{db}->db_update($self->{table},$self,$self->{$self->{table}."_id"});


				# Copy its graph to the new post as well
				if ($self->{table} eq "post" && $autotable eq "link") { # only works for post and link for now
					&clone_graph($self,$self->{db},$self->{dbh},$self->{person},$autoid,$self->{$self->{table}."_id"});
				}

      		}

	 		return $self;
	  }

	  # Load record from database
	  sub load {

	    my $self = shift;
			my $db = $self->{db};
			my $dbh = $self->{dbh};
			my $table = $self->{table};
			my $record;


			die "Tried to load record but no table was defined" unless ($table);

			# Get record data
			if ($self->{id} =~ /new|none/) { $record = &create($self); }
			if ($self->{id}) { 	$record = $db->db_get_record($table,{$table."_id" => $self->{id}}); }
			elsif ($self->{data}->{title}) { $record = $db->db_get_record($table,{$table."_title" => $self->{data}->{title}}); }


			# Load it into current record_delete
			while (my ($rx,$ry) = each %$record) { $self->{$rx} = $ry; }

		}

	  sub create {

			my $self = shift;
			my $db = $self->{db};
			my $dbh = $self->{dbh};
			my $table = $self->{table};
			my $record;

			# Record might be a database table where we know the title but not the id
			# so we'll try to look up the ID and then load it
	  	if ($self->{data} && ref($self->{data}) eq "string") {
				  $self->{id} = &db_locate($dbh,"form",{$table."_title"=>$self->{data}});
					if ($self->{id}) { &load(); return $self->{id}; }
			}

	    # If $data is a string, it's our new title
			my $record_name = "";
	  	if ($self->{data} && ref($self->{data}) eq "string") {	$record_name = $self->{data}; }

			# Initialize time/date values
			#my $tz = $tz || $Site->{st_timezone} || "America/Toronto";					# Allows input to specify timezone
			#my $dt = DateTime->now( time_zone => $tz );													# Create DateTime
			my $dt = DateTime->now();

			my $table_record = {
						$table."_creator"=>$self->{person}->{person_id},
						$table."_crdate"=>$dt->epoch(),
						$table."_name"=>$record_name,
						$table."_title"=>$record_name,
						$table."_pub_date"=> $dt->ymd('/'),
			};

	#

			# Save the values and obtain new record id
			my $id_number = $db->db_insert($table,$table_record);
			return $id_number;

		}

	  sub set_type {
			my $self = shift;
			my ($tag) = @_;
			return unless ($tag);
			if ($tag =~ /(^feed$|^channel$)/i) { $self->{type} = "feed"; }
			elsif ($tag =~ /(^item$|^entry$)/i) { $self->{type} = "link"; }
			elsif ($tag =~ /(^content$|^description$)/i) { $self->{type} = "content"; }
			elsif ($tag =~ /(^author$|^dc:creator$)/i) { $self->{type} = "author"; }
			elsif ($tag =~ /(^media$|^media:content$)/i) { $self->{type} = "media"; }
			elsif ($tag =~ /(^event$)/i) { $self->{type} = "event"; }

	  }




				# -------  Clone Graph  --------------------------------------------------------
			#
			#
			#	      Edited: 21 January 2013
		# This is a duplicate of the one in the main grsshopper scripts...
		# eventually set up to require these functions by package
			#
			#----------------------------------------------------------------------
			sub clone_graph {

				my ($self,$db,$dbh,$Person,$linkid,$postid) = @_;

			  my $now = time;
			  my $cr = $Person->{person_id};


				my $sql = qq|SELECT * FROM graph WHERE graph_tableone=? AND graph_idone = ?|;
			  my $sth = $dbh->prepare($sql);
			  $sth->execute("link",$linkid);

				while (my $ref = $sth -> fetchrow_hashref()) {

					$ref->{graph_tableone} = "post";
					$ref->{graph_idone} = $postid;
					$ref->{graph_crdate} = $now;
					$ref->{graph_creator} = $cr;

					$db->db_insert("graph",$ref);

				}


				my $sqlg = qq|SELECT * FROM graph WHERE graph_tabletwo=? AND graph_idtwo = ?|;
				my $file_list = "";
				my $sthg = $dbh->prepare($sqlg);
				$sthg->execute("link",$linkid);
				while (my $ref = $sthg -> fetchrow_hashref()) {

					$ref->{graph_tabletwo} = "post";
					$ref->{graph_idtwo} = $postid;
					$ref->{graph_crdate} = $now;
					$ref->{graph_creator} = $cr;

					$db->db_insert("graph",$ref);
				}

		}





	  #----------------------------- Flow Values ------------------------------
	  #                    (might all be replaced by autopost)
	  #  Flow values from one type of record to another
	  #  Eg., fill empty valies in a link with values from the feed
	  #  Used to initialize record values


	   sub flow_values {

		my ($from,$from_prefix,$to,$to_prefix) = @_;

		while (my ($fx,$fy) = each %$from) {
			my $fprefix = $from_prefix."_";
			my $tprefix = $to_prefix."_";
			next unless ($fx =~ /$fprefix/i);					# Only flow through record values (signified by the presence of the prefix)
			next if ($to_prefix =~ /feed_/);					# Never flow *to* feed
			next if ($fx =~ /_id$/i);							# Never flow-through ID
			next if ($fx =~ /_type$/i);							# Never flow-through type

			if ($fx =~ /genre|section|author|publisher|title|descxription/) {		# Limited list of flow-through values
				my $tx = $fx;												# These are intended to be defaults and
				$tx =~ s/$fprefix/$tprefix/ig;									# re over-written by actual discovered values
				$to->{$tx} ||= $from->{$fx};
			}
		}



	   }




	  sub load_from_db {

	    my $self = shift;
	    my ($dbh,$id) = @_;

	    unless ($self->{type}) { $self->{error} = "Record type not defined on load from db"; return 0; }
	    my $idfield = $self->{type}."_id";
	    my $stmt = "SELECT * FROM $self->{type} WHERE $idfield=? LIMIT 1";
	    my $sth = $dbh -> prepare($stmt);
	    $sth -> execute($id);
	    my $data = $sth -> fetchrow_hashref();
	    $sth->finish(  );
	    unless ($data) { $self->{error} = "$self->{type} '$id' not found in database."; return 0; }
	    while (my($dx,$dy) = each %$data) { $self->{$dx} = $data->{$dx}; }
	    return 1;
	  }

	  #
	  #   Add a value to the end of a list of values in an element
	  #   Delimeter defaults to ;


	  # Adding values to elements

	  sub set_value {

		my ($self,$tag,$con) = @_;
		$self->{$tag} = $con; 					# Just set a value, eg. title
		$self->{$self->{type}."_".$tag} = $con;   		# Set a value for db storage, eg. feed_title
	  }

	  sub extend_list {

		my ($self,$tag,$con,$delimiter) = @_;
		$delimiter ||= ";";
		if ($con) {
			if ($self->{$tag}) { $self->{$tag} .= $delimiter; }  	# Just set a value, eg. title
			$self->{$tag} .= $con;
										# Set a value for db storage, eg. feed_title
			if ($self->{$self->{type}."_".$tag}) { $self->{$self->{type}."_".$tag} .= $delimiter; }
			$self->{$self->{type}."_".$tag} .= $con;

		}
	  }

	    sub do_not_replace {

		my ($self,$tag,$con) = @_;
		unless ($self->{$tag}) { $self->{$tag} = $con; 	}	# Just set a value, eg. title
		unless ($self->{$self->{type}."_".$tag}) {
			$self->{$self->{type}."_".$tag} = $con;   }		# Set a value for db storage, eg. feed_title
	  }

	  sub target {
		my $self = shift;
		if( @_ ) {
			my $target = shift;
	      	$self->{target} = $target;
		}
		return $self->{target};
	  }


	  sub to_string {
	   	my $self = shift;
	   	return $self->{page_content};
	  }

	  sub print {
	  	my $self = shift;
	   	print $self->to_string(), "\n";
	  }

	 1;




		#----------------------------------------------------------------------------------------------------------
		#
		#                                             gRSShopper::Window;
    	#
		#   table            		(string) Table being displayed in the window
		#   id 			  		  		(int) ID of record being displayed in the woindow
		#   starting_tab 				(string) Tab to display when window is opened
		#		person_name					(::Person)  person opening the window
		#   db                  (::Database) Pointer to database functions
		#   dbh               	(::DBI) Pointer to DBI database handler
		#   data								(hash reference)  Data that accompanies the opening of the window
		#
		#   record              (::Record) Record being displayed
		#   field_list          (array) List of fields in the table being displayed		(generated)
		#   tab_list            (hash reference) Tabs being displayed (generated)
		#   show_active 				(string) Toggle to show active (inserts some css) (generated)
		#
		#----------------------------------------------------------------------------------------------------------
	package gRSShopper::Window;

	  #  Window to display various tabs (aka Scaffolds) associated with a data record


	  use strict;
	  use warnings;

	  our $VERSION = "1.00";

	  sub new {

	  	my($class, $args) = @_;
	   	my $self = bless({}, $class);

			# Import Arguments
	   	while (my($ax,$ay) = each %$args) {
	   		#print "$ax = $ay <br>";
	   		$self->{$ax} = $ay;
      }


      # get a record to display
			if  ($self->{table}) {
				# Import Record Data
		  		$self->{record} = gRSShopper::Record->new(
					table => $self->{table},
					id => $self->{id},
					data => $self->{data},
					db => $self->{db},
					dbh => $self->{dbh},
					person => $self->{person},
					load => 1,
				);
	  	}

      $self->get_tab_list($self->{table},$self->{dbh});
      return $self;



	  }

		sub get_tab_list {

		  my ($self,$table,$dbh) = @_;
			my $db = $self->{db};
			# If the Form table exists

		  my @fieldlist;
			my $tablist;
			my $active;
			my $defined = 0;		# Flag set if this table has a form defined, 0 if this form is set using default values


			if ($db->db_table_exist("form")) {

				# Find the form record for the current $table
				my $tableid = $db->db_locate("form",{form_title=>$table});

				if  ($tableid) {

					# Get the form_help from the record and store it as a window value
					$self->{help} = $db->db_get_single_value("form","form_help",$tableid);

					# Get the 'data' from the record, and split it into fields
					my $table_data = $db->db_get_single_value("form","form_data",$tableid);
					$table_data =~ s/\n//g;
					@fieldlist = split /;\s*/,$table_data;

					if ($table_data) { $self->{form_defined} = 1; }

				} else {
							@fieldlist = &auto_generate_fieldlist($self,$table);
				}
			} else {
				@fieldlist = &auto_generate_fieldlist($self,$table);
			}

			unless (@fieldlist) { @fieldlist = &auto_generate_fieldlist($self,$table); }

		  my $currenttab = "Edit"; my $temp;
			foreach my $field (@fieldlist) {

		      	if ($field =~ /tab:/i) {
					($temp,$currenttab) = split /:/,$field;
					$currenttab =~ s/^\s|\s$//g;  # Remove leading or trailing space
					push @{$self->{tabs}},$currenttab;
					if ($field =~ /,active/i) { $active = $currenttab; }
					push @{$tablist->{$currenttab}},"Placeholder to make sure tab is found";
				}	else {
					push @{$tablist->{$currenttab}},$field;
				}
			}
			$self->{tab_list} = $tablist;
			$self->{show_active} = $active;
      		$self->{field_list} = @fieldlist;

			return ($tablist,$active,$defined,@fieldlist);

		}

		sub auto_generate_fieldlist {

			my ($self,$table) = @_;

			my $db = $self->{db};
			my $dbh = $self->{dbh};

			# Get the list of columns from the database
			my @columns = ();
			my @fieldlist = ();

			my $showstmt = "SHOW COLUMNS FROM $table";
			my $sth = $dbh -> prepare($showstmt);
			$sth -> execute();

			# Get optlist values just once, ahead of time
			my $optlist_array = $db->db_get_column("optlist","optlist_title");


			# For each column...
			while (my $showref = $sth -> fetchrow_hashref()) {

				# Normalize the column name
				my $fullfieldname = $showref->{Field};
				my $prefix = $table."_"; $showref->{Field} =~ s/$prefix//;

				# Extract column type and length values
				my ($fieldtype,$fieldsize) = split /\(|\)/,$showref->{Type};
				if ($fieldsize+0 == 0) { $fieldsize = 10; }  # Prevent 0 fieldsize

				# Some defaults fieldtypes for important fields


				if ($table eq "form" && $showref->{Field} eq "data") { $fieldtype = "data"; }
				elsif ($table eq "presentation" && ($showref->{Field} eq "post")) { $fieldtype = "keylist"; } # Temporary
				elsif ($table eq "optlist" && $showref->{Field} eq "data") { $fieldtype = "text"; }
				elsif ($table eq "view" && $showref->{Field} eq "text") { $fieldtype = "text"; }
				elsif ($table eq "box" && $showref->{Field} eq "content") { $fieldtype = "text"; }
				elsif ($table eq "box" && $showref->{Field} eq "description") {  $fieldtype = "textarea_input"; }
				elsif ($showref->{Field} eq "description") { $fieldtype = "text"; }
				elsif ($showref->{Field} eq "data") { $fieldtype = "data"; }
				elsif ($fullfieldname =~ /_file/) { $fieldtype = "file"; }
				elsif ($fullfieldname =~ /_password/) { $fieldtype = "password"; }
				elsif ($fullfieldname =~ /_date/) { $fieldtype = "date"; }
				elsif ($fullfieldname =~ /_social_media/) { $fieldtype = "publish"; }
				elsif ($fullfieldname =~ /_start/ || $fullfieldname =~ /_finish/) { $fieldtype = "datetime"; }
				elsif (grep { /$fullfieldname/ } @$optlist_array) { $fieldtype = "optlist"; }
				elsif ($table eq "post" && ($showref->{Field} eq "author" || $showref->{Field} eq "feed")) { $fieldtype = "keylist"; } # Temporary
				elsif ($table eq "publication" && ($showref->{Field} eq "post")) { $fieldtype = "keylist"; } # Temporary
				else { $fieldtype = "varchar"; }

				# Push the column information into the new @fieldlist array
				# (which will now look just like the comma-delimited data if it were retrieved from the Form table
				push @fieldlist,"$showref->{Field},$fieldtype,$fieldsize,$showref->{Default}";
			}



			return @fieldlist;

		}













1;
	#----------------------------------------------------------------------------------------------------------
	#
	#                                             gRSShopper::Blockchain;
	#
	#   Just playinng
	#   Based on Daniel Flymen, Learn Blockchains by Building One
	#   https://hackernoon.com/learn-blockchains-by-building-one-117428612f46
	#
	#----------------------------------------------------------------------------------------------------------
package gRSShopper::Blockchain;

  #  $Person = gRSShopper::Person->new({person_title=>'title',person_password=>'password'});
  # Note that password will be encrypted in save

	use JSON qw(encode_json decode_json);
	use Digest::SHA qw(hmac_sha256_base64);
	use LWP::Simple;
	use Fcntl qw(:flock SEEK_END);

  use strict;
  use warnings;
  our $VERSION = "1.00";

  sub new {
  	my($class, $args) = @_;
		my $self = bless({}, $class);
		$self->{current_transactions} = [];
		$self->{nodes} = [];
		$self->{chain} = [];

		# Retrieve stored version of the boockchain from file

		my ($chain,$current,$nodes) = $self->open();
		if ($chain) {	$self->{chain} = $chain; }
		if ($current) {	$self->{current_transactions} = $current }
		if ($nodes) {	$self->{nodes} = $nodes; }

		unless ( $self->{chain}) {
				$self->new_block(1,100);		# Initializes; previous_hash=1, proof=100
		}

    return $self;
  }


	# Create a new Block in the Blockchain
	# :param proof: <int> The proof given by the Proof of Work algorithm
	# :param previous_hash: (Optional) <str> Hash of previous Block
	# :return: (object) New Block

	sub new_block {

    my ($self,$proof,$previous_hash) = @_;
	  $previous_hash ||= "None";

		my @chain = $self->{chain};
		my $index = $#chain;
		my @transactions = $self->{current_transactions};

	#	my $self_hash = $self->hash($self->{chain}[$#chain+1]);


		my $block = {
				index => $index,
				timestamp => time,
				transactions =>  @transactions,
				proof => $proof,
				previous_hash => $previous_hash,
		};

    push @{$self->{chain}},$block;
		return $block;

	}

	# Creates a new transaction to go into the next mined Block
	# :param sender: <str> Address of the Sender
	# :param recipient: <str> Address of the Recipient
	# :param amount: <int> Amount
	# :return: <int> The index of the Block that will hold this transaction



	sub new_transaction {

     my ($self,$sender,$recipient,$amount) = @_;

		 push @{$self->{current_transactions}},
		 	{
				sender => $sender,
				recipient => $recipient,
				amount => $amount
			};

		  return $#{$self->{current_transactions}} +1;
	}

	# Creates a SHA-256 hash of a Block
	# :param block: <dict> Block
	# :return: <str>

	sub hash {

   my ($self,$block) = @_;


   # Canonical because we must make sure that it is ordered, or we'll have inconsistent hashes
	 my $json_text = JSON::XS->new->canonical()->encode($block);
	 my $digest = hmac_sha256_base64($json_text, "secret");
	 # Fix padding of Base64 digests
   while (length($digest) % 4) { $digest .= '='; }
	 return $digest;

	}

	sub last_block {

		 my ($self) = @_;
		 my @chain = $self->{chain};
		 return $self->{chain}[$#chain];

	}

		#Simple Proof of Work Algorithm:
		# - Find a number p' such that hash(pp') contains leading 4 zeroes, where p is the previous p'
		# - p is the previous proof, and p' is the new proof
		#:param last_proof: <int>
		#:return: <int>

	sub proof_of_work {

   my ($self,$last_proof) = @_;

	 	my $proof = 0;
		while ($self->valid_proof($last_proof, $proof) == 0) {
			$proof++;
    }

    return $proof;
	}

	# Validates the Proof: Does hash(last_proof, proof) contain 4 leading zeroes?
	# :param last_proof: <int> Previous Proof
	# :param proof: <int> Current Proof
	# :return: <bool> True if correct, False if not.

  sub valid_proof {

   my ($self,$last_proof,$proof) = @_;

	 	my $guess = $last_proof.$proof;
		my $digest = hmac_sha256_base64($guess, "secret");
		my $test = substr $digest, 0, 4;
		if ($test eq "0000") { return 1;} else { return 0;}

	}


  #	Determine if a given blockchain is valid
	# :param chain: <list> A blockchain
	# :return: <bool> True if valid, False if not

  sub valid_chain {

    my ($self,@chain) = @_;

		my $last_block = $chain[0];
    my $current_index = 0;
		my $length = $#chain +1;


		while ($current_index < $length) {
			my $block = $chain[$current_index];
			print($last_block);
			print($block);
			return 0 unless ($block->{previous_hash} eq $self->hash($last_block));
			return 0 unless ($self->valid_proof($last_block->{proof},$block->{proof}));
			$last_block = $block;
			$current_index++;
		}
		return 1;
	}

	# This is our Consensus Algorithm, it resolves conflicts
	# by replacing our chain with the longest one in the network.
	# :return: <bool> True if our chain was replaced, False if not

  sub resolve_conflicts {

    my ($self) = @_;

		my @neighbours = $self->{nodes};
		my @new_chain;
		my @chain = $self->{chain};

		# We're only looking for chains longer than ours
		my $max_length = $#chain+1;
		foreach my $node (@neighbours) {
			my $url = $node . "?cmd=chain";
			my $response = get($url);
			if ($response) {
				my $data = decode_json($response);
				my @chain = $data->{chain};
				my $length = scalar @chain;

				# Check if the length is longer and the chain is valid
			  if ($length > $max_length && $self->valid_chain(@chain)) {
				  $max_length = $length;
					@new_chain = @chain;
				}
			}
		}

		if (@new_chain) {
			$self->{chain} = @new_chain;
			return 1;
		}

		return 0;

	}



	# Add a new node to the list of nodes
  # :param address: <str> Address of node. Eg. 'http://192.168.0.5:5000'
  # :return: None

   sub register {

      my ($self,$url) = @_;
			unless (grep($url, @{$self->{nodes}})) {   # Ensure uniqueness of members in array
				push @{$self->{nodes}},$url;
		  }

	 }

	 # Open the currently persisting copy of the blockchain from a file

	sub open {

	  my ($self) = @_;

	  my $blockchain_file = "data/blockchain.json";
	  open(my $fh, "$blockchain_file") || die "Could not open $blockchain_file for read";
		flock($fh, LOCK_EX) or die "Cannot lock $blockchain_file - $!\n";
		my $blockchain_data = <$fh>;
	  close $fh;
		my $new_blockchain;
		if ($blockchain_data && $blockchain_data ne "null") { $new_blockchain = decode_json($blockchain_data); }
		return unless (ref $new_blockchain eq "HASH" &&  $new_blockchain->{chain});
		my $chain = $new_blockchain->{chain};
		my $current = $new_blockchain->{current_transactions};
		my $nodes = $new_blockchain->{nodes};
		return ($chain,$current,$nodes);

  }





1;


package gRSShopper::Badgr;

  use strict;
  use warnings;
	use HTTP::Request::Common qw(POST);
	use LWP::UserAgent;
	use JSON qw(encode_json decode_json);

  our $VERSION = "1.00";


  sub new {

  	my($class, $args) = @_;
   	my $self = bless({}, $class);

   	while (my ($ax,$ay) = each %$args) {$self->{$ax} = $ay;}
    $self->generate_access_token();
   	return $self;
  }

	sub generate_access_token {

		my ($self) = @_;
    my $access_token_url = $self->{badgr_url}."/o/token";
		my $ua = LWP::UserAgent->new;
		my $req = POST $access_token_url,[ username => $self->{badgr_account}, password => $self->{badgr_password} ];
		my $response = $ua->request($req);
		if ($response->is_success) {
			 my $hashref  = decode_json $response->decoded_content;
			 $self->{access_token} =  $hashref->{access_token};
			 $self->{refresh_token} =  $hashref->{refresh_token};
		}
		else {
		   print STDERR $response->status_line, "\n";
		}
	}


	# Creates an issuer on Badgr
  # using site data in $Site
  # Returns issuer ID and stores in Badgr object

	sub create_issuer {

		my ($self,$issuer) = @_;

		# Create Request JSON
		my $issuer_json = qq|{
	   "name": "$issuer->{name}",
	 	 "email": "$issuer->{email}",
	 	 "description": "$issuer->{description}",
	 	 "url": "$issuer->{url}"
	 }|;

	  # Format Request
    my $create_issuer_url = $self->{badgr_url}."/v2/issuers";
	  my $header = ['Authorization' => 'Bearer '.$self->{access_token},"Content-Type" => "application/json"];
		my $req = HTTP::Request->new('POST', $create_issuer_url, $header, $issuer);

		# Make Request
    my $ua = LWP::UserAgent->new;
		my $response = $ua->request($req);
		if ($response->is_success) {

		# Process Response
		my $hashref  = decode_json $response->decoded_content;
			foreach my $r (@{$hashref->{result}}) {
			   if ($r->{entityId}) {

		  			# Process Successful Response, or
            $self->{badgr_issuerid} = $r->{entityId};

						# Report Request Error
         } else {
					   print "Failed to create an EntityId for Issuer<p>"
         }
			}

		}
		else {

			 # Report Connection Error
			 print STDERR $response->status_line, "\n";
		}


	}

  # Publishes a badge on Badgr
  # using data from a previously defined badge entity $badge
  # Returns the newly created badge

  sub create_badge {

		my ($self,$badge) = @_;
		my $req = POST $self->{badgrapi},[ username => $self->{badgruserid}, password => $self->{badgrpwd} ];

    die "Cannot creat a badge without an issuer ID" unless ($self->{badgr_issuerid});

    # Define Badge JSON
    my $badge_json = qq|
		 {"criteriaUrl":"$badge->{criteriaUrl}",
			"issuer":"$self->{badgr_issuerid}",
			"name":"$badge->{badge_title}",
			"image":"$badge->{image}",
			"description":"$badge->{badge_description}",
			"alignments": [
				{"targetName":"Testing",
				 	"targetUrl":"$badge->{criteriaUrl}",
					"targetDescription":"$badge->{badge_description}",
					"targetFramework":"No framework",
					"targetCode":"No code"}
			 ]}|;


		# Create Request
	  my $uri = $self->{badgr_url}."/v2/badgeclasses";
	  my $header = ['Authorization' => 'Bearer '.$self->{access_token},"Content-Type" => "application/json",'username' => $self->{badgruserid}];
		my $data = {foo => 'bar', baz => 'quux'};
		my $reqb = HTTP::Request->new('POST', $uri, $header, $badge_json);

    # Execute Request
    my $ua = LWP::UserAgent->new;
	  my $response = $ua->request($reqb);
		if ($response->is_success) {
			my $hashref  = decode_json $response->decoded_content;
			foreach my $r (@{$hashref->{result}}) {
				 if ($r->{entityId}) {
						$self->{badgr_issuerid} = $r->{entityId};
            printf("Created badge %s <br>",$r->{entityId});
            return $r; # Return the newly created badge
				 } else {
						 print "Failed to create an EntityId for Issuer<p>"
				 }
			}

		}
		else {
			 print STDERR $response->status_line, "\n";
		}


	}


	# Award a badge $badge to a recipient $recipient on Badgr
  # using data from a previously defined badge entity $badge
  # Returns the newly created badge

	sub award_badge {
print "Awarding badge<p>";

		my ($self,$badge,$recipient,$evidence) = @_;

    # Define recipient identity
    my $recipient_identity;
    my $recipient_type;
    my $recipient_hash;
    if ($recipient->{email}) { $recipient_type = "email"; $recipient_identity = $recipient->{email}; }
    elsif ($recipient->{url}) { $recipient_type = "url"; $recipient_identity = $recipient->{url}; }
		elsif ($recipient->{phone}) { $recipient_type = "telephone"; $recipient_identity = $recipient->{phone}; }
		die "Badge recipient not correctly specified in award_badge()" unless ($recipient_identity);
		my $recipient_plaintext_identity = $recipient_identity;
print "To: ". $recipient_plaintext_identity."<p>";
		# Hash recipient identity if requested
 		if ($recipient->{hash}) {
			use Digest::SHA qw(sha512_base64);
			my $recipient_identity = sha512_base64($recipient_plaintext_identity);
			$recipient_hash=qq|"hashed": true,|;
		} else {
			$recipient_hash=qq|"hashed": false,|;
		}
print "OK";
    # Create recipient JSON
		my $recipient_json = qq|"recipient": {
        "identity": "$recipient_identity",
        "type": "$recipient_type",
        $recipient_hash
        "plaintextIdentity": "$recipient_plaintext_identity"
      },|;

		die "Evidence URL not correctly specified in award_badge()" unless ($evidence->{url});
		$evidence->{narrative} ||= "None.";

    # Create request JSON
		my $request_json = qq|
    {
      $recipient_json
      "notify":true,
      "evidence":[
        {
          "url":"$evidence->{url}",
          "narrative":"$evidence->{narrative}"
        }
      ]
    }
		|;

print $request_json;
		# Create request
		my $uri = $self->{badgr_url}."/v2/badgeclasses/".$badge->{badge_entityid}."/assertions";
		my $header = ['Authorization' => 'Bearer '.$self->{access_token},"Content-Type" => "application/json"];
		my $req = HTTP::Request->new('POST', $uri, $header, $request_json) or die "Error formating request: $!";
print "$uri";
print "<p>";
#print $req->as_string;
    # Execute Request
		my $ua = LWP::UserAgent->new;
		my $response = $ua->request($req)  or die "Error sending request: $!";
print $response->as_string;
		if ($response->is_success) {
			my $hashref  = decode_json $response->decoded_content;

			foreach my $r (@{$hashref->{result}}) {
				 if ($r->{entityId}) {
						$self->{badgr_issuerid} = $r->{entityId};
						print "Awarded badge %s to %s <br>";
						return $r; # Return the newly created badge
				 } else {
						 print "Failed to award badge<p>"
				 }
			}

		}
		else {
			 print STDERR $response->status_line, "\n";
		}


	}



 1;
