#!/usr/bin/perl
#print "Content-type:text/html\n\n";
#    gRSShopper 0.7  Page  0.7  -- gRSShopper administration module
#    26 April 2017 - Stephen Downes

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
#
#-------------------------------------------------------------------------------
#
#	    gRSShopper
#           Public Page Script
#
#-------------------------------------------------------------------------------



# Load CGI

	use CGI;
	use CGI::Carp qw(fatalsToBrowser);
	my $query = new CGI;
	my $vars = $query->Vars;
	my $page_dir = "../";

# Load gRSShopper

	use File::Basename;
      use local::lib; # sets up a local lib at ~/perl5
	my $dirname = dirname(__FILE__);
	require $dirname . "/grsshopper.pl";

# Load modules

	our ($query,$vars) = &load_modules("page");

# Load Site

	our ($Site,$dbh) = &get_site("page");
	if ($vars->{context} eq "cron") { $Site->{context} = "cron"; }

# Get Person  (still need to make this an object)

	our $Person = {}; bless $Person;
	&get_person($dbh,$query,$Person);
	my $person_id = $Person->{person_id};

# Initialize system variables

	my $options = {}; bless $options;
	our $cache = {}; bless $cache;

  $vars->{table} ||= "link";
	my $id = $vars->{id};




# Determine Output Format  ( assumes admin.cgi?format=$format )
my $format ||= $vars->{format} || "viewer";		# Default to Viewer
my $table = $vars->{table} || "link";

if ($vars->{viewer_options}) {
   &viewer_body($dbh,$query,$table,$format);
} else {
	&viewer_frame($dbh,$query,$table,$format);
}



if ($dbh) { $dbh->disconnect; }			# Close Database and Exit
exit;




#-------------------------------------------------------------------------------
#
#           Functions
#
#-------------------------------------------------------------------------------

sub viewer_frame {

	# Print Header
	print "Content-type: text/html\n\n";
	my $url = $Site->{st_cgi}."viewer.cgi?viewer_options=yes&link_status=Fresh";
	print qq|<html>
		<head>
		<title>$Site->{st_name} @{[&printlang("Viewer")]}</title>
		<link rel="stylesheet" href="|.$Site->{st_url}.qq|assets/css/grsshopper_viewer.css">
		<script src="https://code.jquery.com/jquery-3.2.1.min.js"></script>
		<script src="$Site->{st_url}assets/js/grsshopper_viewer.js"></script>
		<!-- Font-Awesome -->
		<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.5.0/css/all.css" integrity="sha384-B4dIYHKNBt8Bc12p+WXckhzcICo0wtJAoU8YZTY5qE0Id1GSseTk6S+L3BlXeVIU" crossorigin="anonymous">

		</head>
		<body style="height:100%;margin:0;padding:20px;">
		<div id="viewer-main" style="height:100%;margin:0;;padding:20px;">|.
		&viewer_home_button().
		&viewer_controls($dbh,$query,$table,$format).
		qq|<div id="viewer-body"></div>
		<script>
		\$( "#viewer-body" ).load( "$url" );
		</script>
		</body></html>|;

}

sub viewer_home_button {

  return sprintf(qq|

     <span id="viewer-home-button" class="nav-link" style="cursor:pointer;float:left;" data-target="#readerModal">
		 <img src="%sassets/icons/grssicon.JPG" border=0 width=20 alt="Home" title="Home">
		 </span>
		 <script>
			 \$(document).ready(function() {
				 \$("#viewer-home-button").click(function() {
						 \$('#viewer-main')
								.html('<img src="%sassets/images/loader.gif" />')
								.load('%sstart.html');
				 });
			 });
		 </script>
  |,$Site->{st_url},$Site->{st_url},$Site->{st_url});





}





sub viewer_body {

	my ($dbh,$query,$table,$format) = @_;
	my $vars = $query->Vars;
	$vars->{tag} ||= "none";
	$vars->{status} ||= "Unread";
	print "Content-type: text/html\n\n";




									# Generate Search Parameters
	my @where_arr;
	my @search_string;

                    # Orig               ( link_orig = yes , so we only view the harvested link, not embedded links that were also saved )
	push @where_arr, "(link_orig = 'yes')";

										# Tag
	if ($vars->{tag} && $vars->{tag} ne "none") {
		$Site->{st_tag} =~ s/'//g; #'
		push @where_arr, "(link_type LIKE '%html%' AND (link_content LIKE '%$Site->{st_tag}%' OR link_category LIKE '%$Site->{st_tag}%' OR link_title LIKE '%$Site->{st_tag}%' OR link_description LIKE '%$Site->{st_tag}%'))";
		push @search_string,"Tag: $vars->{tag}";
	}

										# Feed
	if ($vars->{feed_id} && ($vars->{feed_id} ne "none")) {
		my @feedlist = split /\0/,$vars->{feed_id}; my @feed_arr;
		foreach my $f (@feedlist) { push @feed_arr,"link_feedid = '$f'"; }
		my $feedl = join " OR ",@feed_arr;
		push @where_arr, "($feedl)";
		push @search_string,"Feed: $vars->{feed_id}";
	} else {
		push @search_string,"all feeds";
	}

										# Section
	if ($vars->{feed_section} && $vars->{feed_section} ne "none") {
		push @where_arr, "(link_section = '$vars->{feed_section}')";
		push @search_string,"Section: $vars->{feed_section}";
	}else {
		push @search_string,"any section";
	}

										# Status
	if ($vars->{link_status} && $vars->{link_status} ne "none"  && $vars->{link_status} ne "undefined") {
    if ($vars->{link_status} eq "Unread") {
			push @where_arr, "(link_read = 0)";
			push @search_string,"Unread";
		} elsif ($vars->{link_status} eq "Starred") {
			push @where_arr, "(link_star = 1)";
			push @search_string,"Starred";
		} elsif ($vars->{link_status}) {
			push @where_arr, "(link_status = '$vars->{link_status}')";
      push @search_string,"Status: $vars->{link_status}";
		}
	}else {
		push @search_string,"any status";
	}


	my $where; my $wherestring;
	if (scalar(@where_arr) > 0) {
		$where = join " AND ",@where_arr; $where = " ".$where;
		$searchstring = join "; ",@search_string; $searchstring = "Listing: ".$searchstring."<br/>";
	}


									# Execute Search


									# Get List of Links
	my $msg = "";
	if ($where) { $where = "WHERE $where"; }
	my $sql_stmnt = "SELECT ".$table."_id FROM ".$table." $where ORDER BY ".$table."_id";


	my $links_list = $dbh->selectcol_arrayref($sql_stmnt);
	&error($dbh,"","","Links list not found for the following search:<br>$sql_stmnt <br> ".$dbh->errstr) unless ($links_list);
	my $links_count = scalar(@$links_list);
	if ($links_count == 0) { $msg .= "No links harvested with $sql_stmnt <br>".$dbh->errstr; }


										# Set Pointer
	my $lastreadindex = 0;
	if ($Person->{person_lastread}) {
		my $m = &index_of($Person->{person_lastread},$links_list);
		if ($m > 0) { $lastreadindex = $m; } else { $lastreadindex = 0; }
	}

	my @larray; foreach my $l (@$links_list) { push @larray,qq|"$l"|; }
	my $ll = join ",",@larray;
	my $post_scr; if ($Person-{person_status} eq "admin") { $post_scr = "admin"; } else { $post_scr = "page"; }

									# Create Screen


	my $jscr = &viewer_taskbar($table,$ll,$lastreadindex,$post_scr,$links_count);


# <input type="button" id="button5" style="height:2em; width:5em;" onclick="viewer_post(sitecgi,larr[index],'$post_scr')" value=" POST "/>


	if ($links_count == 0) {

		$jscr .= qq|
<div id="viewer-screen" style="height:100%;">
  @{[&printlang("It distresses me to say there was nothing found.")]}
</div>
		|;
	} else {
		$jscr .= qq|
<div id="viewer-screen" style="height:100%;">
  &nbsp;
</div>

<script>
document.getElementById('pointer').value=index;
document.getElementById('resource').value=larr[index];
document.getElementById('rescounter').innerHTML=index+1;
viewer_ajax_request(sitecgi+'page.cgi?$table='+larr[index]+'&format=viewer&force=yes','$table',1);
</script>

	|;

	}

	# Print Viewer

	print qq|$searchstring$jscr</div></body></html>|;

#	print $page->{content};


	exit;




}


sub viewer_controls {

	my ($dbh,$query,$table,$format) = @_;

  # Locked down for admin & link only, for now
  return unless ($table eq "link");
  &admin_only();


	my $controls = qq|
		<form method="post" id="viewer-options" action="#" style="margin:0;">
    <input type="hidden" name="action" value="viewer">
    <input type="hidden" name="table" value="$table">|.
		qq|Section |.&get_optlist($dbh,"feed_section",$vars->{section},&printlang("All Sections")).
		qq|Status |.&get_optlist($dbh,"link_status",$vars->{status},&printlang("Any Status")).
		qq|Feed |.&get_options($dbh,"feed",$vars->{feed},&printlang("All Feeds")).
		qq|Topic |.&get_options($dbh,"topic",$vars->{topic},&printlang("All Topics")).
		qq|Genre |.&get_optlist($dbh,"feed_genre",$vars->{genre},&printlang("All Genres")).
		qq|
		<input type="submit" class="viewer-submit" value="@{[&printlang("S U B M I T")]}">
		</form>
		<script>
		\$( document ).ready(function() {

			\$("#viewer-options").submit( function(e) {
         e.preventDefault();
				 var url = "$Site->{st_cgi}viewer.cgi?viewer_options=yes&"
					 + "table=" + \$("input[name=table]").val()
					 + "&action=" + \$("input[name=action]").val()
					 + "&feed_id=" + \$("#feed_id").val()
						+ "&link_status=" + \$("select[name=link_status]").val()
						+ "&feed_section=" + \$("select[name=feed_section]").val()
						+ "&topic=" + \$("select[name=topic]").val()
						+ "&feed_genre=" + \$("select[name=feed_genre]").val();
				 alert(url);
				 \$("#viewer-body").load(url, function(response, status, xhr) {
    if (status == "error") {
        var msg = "Sorry but there was an error: ";
        alert(msg + xhr.status + " " + xhr.statusText);
      }
});
	       return 0;
			});
		});

		</script>
	|;

	return $controls;
}




sub viewer_taskbar {

	my ($table,$ll,$lastreadindex,$post_scr,$links_count) = @_;

  my $buttons;
  if ($table eq "link") {
    $buttons .= qq|
		<button style="height:2em; width:5em;" onclick="parent.openDiv('|.$Site->{st_cgi}.qq|api.cgi','main','edit','post','new','','Edit','post-'+table+'-'+larr[index]);">Post</button>
		|;

  }

	return qq|
	<script type="text/javascript">
    var table = '$table';
		var larr = [$ll];
		var last = larr.length-1;
		var index=$lastreadindex;
		var sitecgi='$Site->{st_cgi}';
		var pscr = '$post_scr';
	</script>
	<div style="text-align: center;clear:both;margin-top:1em;background-color: lightgrey;padding-top:0.5em;padding-bottom:0.5em;">
		<span style="float:left;">
			<input type="button" id="button4" style="height:2em; width:5em;" onclick="viewer_increment(sitecgi,table,4,last)" value=" << "/>
			<input type="button" id="button2" style="height:2em; width:5em;" onclick="viewer_increment(sitecgi,table,2,last)" value=" < "/>
		</span>
		<span style="float:right;">
			<input type="button" id="button1" style="height:2em; width:5em;" onclick="viewer_increment(sitecgi,table,1,last)" value=" > "/>
			<input type="button" id="button3" style="height:2em; width:5em;" onclick="viewer_increment(sitecgi,table,3,last)" value=" >> "/>
		</span>
		<input type="hidden" id="resource" value="increment me!"/>
		<input type="hidden" id="pointer" value=""/>
		<span>|.ucfirst($table).qq| <span id="rescounter">0</span>  @{[&printlang("of")]} $links_count</span>
		$buttons
	</div>
	|;

}

sub get_tag_options {

	my ($dbh,$opted,$blank,$size,$width) = @_;
	$opted ||= "none";
	my $title = &printlang("Tag");
	$size ||= 1;
	$width ||= 15;
	my $output = "";

	my $nonselected; if ($opted eq "none") { $noneselected = qq| selected="selected"|; }
	my $tagselected; if ($opted eq "$Site->{st_tag}") { $tagselected = qq| selected="selected"|; }

	$output = qq|<h5>$title:</h5>
	<p class="options">
		<select name="tag" size="$size" width="$width" class="viewer-select">
		<option value="none"$nonselected>$blank</option>
		<option value="$Site->{st_tag}"$tagselected>$Site->{st_tag}</option>
		</select></p>
	|;

	return $output;
}

sub get_options {

	my ($dbh,$table,$opted,$blank,$size,$width) = @_;
	return "Table not specified in get_options" unless ($table);
	$opted ||= "none";
	my $titfield = $table."_title";
	my $title = &printlang(ucfirst($table));
	my $idfield = $table."_id";
	$size ||= 15;
	$width ||= 15;
	my $output = "";
	if ($table eq "feed") { $where = qq|WHERE feed_status = 'A'|; } else { $where = ""; }
	my $sql = qq|SELECT $titfield,$idfield from $table $where ORDER BY $titfield|;

	my $sth = $dbh -> prepare($sql);
	$sth -> execute() or die $dbh->errstr;
	while (my $ref = $sth -> fetchrow_hashref()) {
		next unless ($ref->{$titfield});
		my $selected="";
		if ($opted eq $ref->{$idfield}) { $selected = " selected"; }
		$output .= qq|    <option value="$ref->{$idfield}"$selected>$ref->{$titfield}</option>\n|;
	}

	if ($output) {
		$output = qq|<select name="|.$table.qq|_id" style="width:|.$width.qq|em;" class="viewer-select">
    <option value="none" selected>$blank</option>
		$output</select>
		|;
	}
	return $output."PPPPPPPPPPPPPPPPPPPPPPPPPPPPP";
}

sub get_optlist {

	my ($dbh,$optlist,$opted,$blank,$size,$width) = @_;
	return "Optlist not specified in get_optlists" unless ($optlist);
	$opted ||= "none";
	my ($table,$field) = split "_",$optlist;
	my $title = &printlang(ucfirst($field));
	my $output = "";
	my $sql = qq|SELECT optlist_data FROM optlist WHERE optlist_title=? LIMIT 1|;
	my $sth = $dbh -> prepare($sql);
	$sth -> execute($optlist) or die $dbh->errstr;
	my $ref = $sth -> fetchrow_hashref();
	my @opts = split ";",$ref->{optlist_data};
	foreach my $opt (@opts) {
		my ($oname,$ovalue) = split ",",$opt;
		next unless ($oname && $ovalue);
		my $selected; if ($opted eq $ovalue) { $selected = " selected"; }  else { $selected=""; }
		$output .= qq|    <option value="$ovalue"$selected>@{[&printlang($oname)]}</option>\n|;
	}

	if ($output) {
		$output = qq|<select name="$optlist" class="viewer-select">
		<option value="none" selected>$blank</option>
		$output
		</select>
		|;
	}

	return $output;
}




1;
