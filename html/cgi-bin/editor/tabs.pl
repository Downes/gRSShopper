
	# TABS ----------------------------------------------------------
	# ------- Edit --------------------------------------------
	#
	# Generic Edit Functions
	#
	# Uses the _summary view but I'll fix this later
	#
	# -------------------------------------------------------------------------
sub Tab_Edit {

	my ($window,$table,$id_number,$record,$data,$defined) = @_;

	my $output = qq|<div>|;
	#print "Content-type: text/html\n\n";

  	if ($id_number eq "me") { $id_number = $Person->{person_id}; }
	foreach my $field (@{$window->{tab_list}->{Edit}}) {
		$output .= &process_field_types($window,$table,$id_number,$field,$record,$data,$defined);
	}

	$output .= &form_pushbutton($table,$id_number,"tab","delete","none","Delete Record","confirm");
	$output .= &form_showrecorddata($table,$id_number);

	$output .= "</div>";

	return  $output;

}
# TABS ----------------------------------------------------------
# ------- Resources --------------------------------------------
#
# Generic Resource Functions - as boring as a tab gets
#
# -------------------------------------------------------------------------
sub Tab_Resources {

	my ($window,$table,$id_number,$record,$data,$defined) = @_;

	my $output = "";
	#print "Content-type: text/html\n\n";

	foreach my $field (@{$window->{tab_list}->{Resources}}) {
		$output .= &process_field_types($window,$table,$id_number,$field,$record,$data,$defined);
	}
	return  $output;

}
	# TABS ----------------------------------------------------------
	# ------- Import --------------------------------------------
	#
	# Generic Import Functions
	#
	#
	# -------------------------------------------------------------------------
sub Tab_Import {

	my ($window,$table,$id_number,$record,$data,$defined) = @_;

	my $output = "";
  print "Database not initialized" unless ($dbh);
	my $stmt = qq|SELECT * from feed WHERE feed_table = ? AND feed_link<>''|;
	my $sth = $dbh -> prepare($stmt) or print "Error: $!".$sth->errstr();
	$sth -> execute($table) or print "Error: $!".$sth->errstr();
	while (my $showref = $sth -> fetchrow_hashref()) {
		 # Open Main: url,cmd,db,id,title,starting_tab
		$output .= qq|<li><a href="#" onclick="openDiv('|.$Site->{st_cgi}.qq|api.cgi','main','harvest','feed','|.$showref->{feed_id}.qq|');">|.$showref->{feed_title}.qq|</li>|;
	}
	$sth ->finish();
	unless ($output) { $output = "No import sources found for $table data."}
	$output = "<p>Importing for $table</p>".$output;
	return  $output;

}
# TABS ----------------------------------------------------------
# ------- Write --------------------------------------------
#
# Just like edit but used for great big writing areas
#
#
# -------------------------------------------------------------------------
sub Tab_Write {

my ($window,$table,$id_number,$record,$data,$defined) = @_;
my $output = "";
foreach my $field (@{$window->{tab_list}->{Write}}) {
	$output .= &process_field_types($window,$table,$id_number,$field,$record,$data,$defined);
}
return  $output;

}

# TABS ----------------------------------------------------------
# ------- Reader --------------------------------------------
#
# Generic Reader Function
#
#
#
# -------------------------------------------------------------------------
sub Tab_Reader {

  my ($window,$table,$id_number,$record,$data,$defined) = @_;
	return;  # Temporary
  my $output = qq|<iframe id="viewer" style="border:0;width:100%;height:95%;"></iframe>
   <script>
   \$('#viewer').attr('src','|.$Site->{st_cgi}.qq|page.cgi?action=viewer&table='+readerTable+'&index='+readerIndex);
   </script>
  |;

  return $output;

}

# TABS ----------------------------------------------------------
# ------- Reader --------------------------------------------
#
# Generic Reader Function
#
#
#
# -------------------------------------------------------------------------
sub Tab_Help {

  my ($window,$table,$id_number,$record,$data,$defined) = @_;

	my $help_page = $window->{help};
	my $output = "";

	# Try to find it locally
	my $tableid = &db_locate($dbh,"page",{page_location=>$help_page});
	if ($tableid) { $output = my $table_data = &db_get_single_value($dbh,"page","page_code",$tableid); }

  # Get it from gRSShopper.ca
	unless ($output) {
		my $url = 'http://grsshopper.downes.ca/'.$help_page;
		$output = get($url);
	}

	# Finish
	unless ($output) { $output = "Help not found. To create help, create a page with the page location: $help_page "; }
  return $output;


	return;  # Temporary
  my $output = qq|<iframe id="viewer" style="border:0;width:100%;height:95%;"></iframe>
   <script>
   \$('#viewer').attr('src','|.$Site->{st_cgi}.qq|page.cgi?action=viewer&table='+readerTable+'&index='+readerIndex);
   </script>
  |;

  return $output;

}

	# TABS ----------------------------------------------------------
	# ------- Upload --------------------------------------------
	#
	# Generic Upload Functions
	#
	# Uses the _summary view but I'll fix this later
	#
	# -------------------------------------------------------------------------
sub Tab_Upload {

	my ($window,$table,$id_number,$record,$data,$defined) = @_;
	my $output = "";

	foreach my $field (@{$window->{tab_list}->{Upload}}) {
		$output .= &process_field_types($window,$table,$id_number,$field,$record,$data,$defined);
	}
	return  $output;

}



	# TABS ----------------------------------------------------------
	# ------- Preview --------------------------------------------
	#
	# Generic Preview Functions
	#
	# Uses the _summary view but I'll fix this later
	#
	# -------------------------------------------------------------------------
sub Tab_Preview {

	my ($window,$table,$id,$record,$data,$defined) = @_;
  $table ||= $vars->{table};
	$id ||= $vars->{id};
	return "Permission Denied" unless (&is_viewable("admin",$vars->{table}));
	unless ($table) { return "Don't know which table to preview."; exit;}
	unless ($id) { return "Don't know which ".$vars->{table}." number to preview."; exit;}
	return qq|
	<script>\$(document).ready(function(){\$('#preview-record-summary').load("|.$Site->{st_cgi}.qq|api.cgi?cmd=show&table=$table&id=$id&format=summary");});</script>
	<div id="preview-record-summary"></div>

	|;

	return "Preview";
}

	# TABS ----------------------------------------------------------
	# ------- Classify --------------------------------------------
	#
	# Generic Classify Functions
	#
	# Uses the _summary view but I'll fix this later
	#
	# -------------------------------------------------------------------------
sub Tab_Classify {

	my ($window,$table,$id_number,$record,$data,$defined) = @_;

	my $output = qq|<div>|;
	foreach my $field (@{$window->{tab_list}->{Classify}}) {
		$output .= &process_field_types($window,$table,$id_number,$field,$record,$data,$defined);
	}
	$output .= "</div>";
	return  $output;
}

	# TABS ----------------------------------------------------------
	# ------- Publish --------------------------------------------
	#
	# Generic Publish Functions
	#
	# Uses the _summary view but I'll fix this later
	#
	# -------------------------------------------------------------------------
sub Tab_Publish {

	my ($window,$table,$id_number,$record,$data,$defined) = @_;
	my $output = "";

	foreach my $field (@{$window->{tab_list}->{Publish}}) {
		$output .= &process_field_types($window,$table,$id_number,$field,$record,$data,$defined);
	}
	return  $output;

}

	# TABS ----------------------------------------------------------
	# ------- Harvest --------------------------------------------
	#
	# Generic Publish Functions
	#
	# Uses the _summary view but I'll fix this later
	#
	# -------------------------------------------------------------------------
sub Tab_Harvest {

	my ($window,$table,$id,$record,$data,$data,$defined) = @_;
	my $output = sprintf(qq|<div style="border:solid 1px orange;">
  		<label for="feed_link">Harvester</label><p class="info">Source: %s</p>|,
	  	$record->{$table."_title"});

  	my $adminlink = $Site->{st_cgi}."admin.cgi";
  	my $apilink = $Site->{st_cgi}."api.cgi";
  	my $harvestlink = $Site->{st_cgi}."harvest.cgi";
  	my $ffeed = $record->{$table."_id"};
  	my $status = $record->{$table."_status"};
	unless ($record->{$table."_link"}) { $status = "B"; $record->{$table."_status"} = "B"; }
	
	$output .= &harvester_commands($id,$status,$harvestlink,$harvestersource);




	foreach my $field (@{$window->{tab_list}->{Harvest}}) {
		$output .= &process_field_types($window,$table,$id,$field,$record,$data,$defined);
	}

	$output .= "</div>";
  	return  $output;

}
	# ------- Harvester Commands --------------------------------------------
	#
	# Returns different harvester command optoions depending on status
	#
	#
	# -------------------------------------------------------------------------
sub harvester_commands {

	my ($id,$status,$harvestlink,$harvestersource) = @_;

	# Build Log levels Dropdown
  	my $levels = qq|<select class="harvest-select" id="s1">\n|;
	my $s;
	foreach my $n (1 .. 10) { 
		if ($n == 1) { $s = "selected"; } else { $s = ""; }
		$levels .= qq|<option class="harvest-option" $s value="$n">$n</option>\n|; 
	}
	$levels .= qq|</select>\n|; 

	# Create feed status icons
	my $A = qq|<img src="|.$Site->{st_url}.qq|assets/img/A.jpg">|;
  	my $R = qq|<img src="|.$Site->{st_url}.qq|assets/img/R.jpg">|;
  	my $O = qq|<img src="|.$Site->{st_url}.qq|assets/img/O.jpg">|;
	my $B = qq|<img src="|.$Site->{st_url}.qq|assets/img/B.jpg">|;
	my $Y = qq|<img src="|.$Site->{st_url}.qq|assets/img/Y.jpg">|;
 
  	# Harvest Status Display
  	my $output = qq|<div id="harvester-commands">|;

	if ($status eq "A" || $status eq "Published") {
		$output .=  qq|<p class="info">$A Feed is approved and is harvested automatically
		if the harvester is active. It may also be harvested manually right here.</p>|; }
			
	elsif ($status eq "R" || $status eq "Retired") {
		$output .=  qq|<p class="info">$R Feed has been retired and is not available for harvest. Change status to 'Approved' or 'On Hold' for harvesting functions.</p>|; }

	elsif ($status eq "O" || $status eq "On Hold") {
		$output .=  qq|<p class="info">$O Feed exists and is on hold until approval. It may be harvested or analyzed manually right here but will not be automatically harvested.</p>|; }

	elsif ($status eq "Y" || $status eq "Feed Error") {
		$output .=  qq|<p class="info">$Y Feed is returning server errors right now and is on hold until approval. It may be harvested or analyzed manually right here.</p>|; }

	else {
		$output .= qq|<p class="info">$B Feed exists but a harvest link has not been provided.
		   It cannot be harvested until a link address is provided.</p>|; }


	# Provide the harvester controls
	if ($status eq "A" || $status eq "O" || $status eq "Y") {
		$output .= qq|<div class="text-input-form">
		<button class="harvest-button" onClick="openHarvester('$harvestlink?feed=$id&analyze=on');">@{[&printlang("Analyze")]}</button>|.
		qq|$levels|.
		qq|<button class="harvest-button" onClick="openHarvester('$harvestlink?feed=$id');">@{[&printlang("Harvest")]}</button>|.
		qq|<button class="harvest-button"onClick="openHarvesterSource('$record->{$table."_link"}');">@{[&printlang("Source")]}</button></div>|;

	}

  	$output .= qq|<span id="harvester-closebutton" style="display:none;"><button
	  class="harvest-button" onClick="closeHarvester();">Close</button></span>|;
	  
	 $output .= qq|</div>|;



  # Harvest Output Display Window
  $output .= qq|
		<div id="harvester-output" style="display:none;width:100%;height:600px;overflow: scroll;"></div>
		<div id="harvester-source" style="display:none;width:100%;height:600px;overflow: scroll;">
	     <form><textarea style="width:95%;height:590px" id="harvester-source-textarea"></textarea></form>
		</div>
		<script>
    var diag_level = 1;
		var harvestURL;
		function download_to_textbox(url, el) {
			\$.get(url, null, function (data) {el.val(data);}, "text");
		}

		\$(function() {
          \$('#s1').change(function() {
                diag_level = \$(this).val();
								if (harvestURL) { openHarvester(harvestURL); }
          });
    });

		function openHarvester(url) {
			harvestURL = url;
			closeHarvester();
			\$('#harvester-closebutton').show();
			\$('#harvester-output').show();
			url = url + "&diag_level="+diag_level;
			\$('#harvester-output').load(url);
		}
		function openHarvesterSource(url) {
			harvestURL = url;
			closeHarvester();
			\$('#harvester-closebutton').show();
			\$('#harvester-source').show();
	    download_to_textbox(url, \$("#harvester-source-textarea"));
		}
		function closeHarvester() {
			\$('#harvester-output').hide();
			\$('#harvester-source').hide();
			\$('#harvester-closebutton').hide();
		}
		</script>
	|;





   # Open Main: url,cmd,db,id,title,starting_tab
  $output .= qq|[<a href="#" onClick="openDiv('$onclickurl','main','import','$table');">Import More |.ucfirst($table).qq| Data</a>] |;
  $output .= qq|[<a href="#" id="harvester_functions_selection">Harvester Admin Functions</a>]|;
	$output .= qq|<script>
	              \$('#harvester_functions_selection').on('click',function(){
								openDiv('$apilink','main','admin','','','','Harvester');
							});
							</script>|;





	
	return $output;

}
	# TABS ----------------------------------------------------------
	# ------- Page --------------------------------------------
	#
	# Page-Specific Functions
	#
	#
	# -------------------------------------------------------------------------
sub Tab_Page {

	my ($window,$table,$id_number,$record,$data,$defined) = @_;
	$table ||= $vars->{table};
	$id_number ||= $vars->{id_number};
	unless ($table eq "page") { return "Page tab only works for pages.<br>You need to specify 'table=page&id=##' in your request."; exit;}
	unless ($id_number) { return "Don't know which page number to manage."; exit;}
	my $output = "";

	foreach my $field (@{$window->{tab_list}->{Page}}) {
		$output .= &process_field_types($window,$table,$id_number,$field,$record,$data,$defined);
	}


	$output .= &form_pushbutton($table,$id_number,"tab","publish");

	$output .= &form_pushbutton($table,$id_number,"tab","clone");

	$output .= &form_pushbutton($table,$id_number,"tab","delete","none","confirm");

	return  $output;
}
	# TABS ----------------------------------------------------------
	# ------- Table --------------------------------------------
	#
	# Used by the Form table, provides access to database functions
	#
	#
	# -------------------------------------------------------------------------
sub Tab_Table {

  my ($window,$table,$id_number,$record,$data,$defined) = @_;
  my $output = "";

  foreach my $field (@{$window->{tab_list}->{Table}}) {
	  $output .= &process_field_types($window,$table,$id_number,$field,$record,$data,$defined);
  }
  return  $output;

}
sub Tab_Newsletter {

	my ($window,$table,$id,$record,$defined) = @_;
	my $output = "";

	unless (&is_allowed("publish","page")) { return "Permission Denied"; exit; }
	unless ($vars->{table} eq "page") { return "Newsletters only work for pages. <br>You need to specify 'table=page&id=##' in your request."; exit;}
	unless ($vars->{id}) { return "Don't know which page number to manage."; exit;}



	foreach my $field (@{$window->{tab_list}->{Newsletter}}) {
		$output .= &process_field_types($window,$table,$id,$field,$record,$data,$defined);
	}
	return  $output;

}
  # TABS ----------------------------------------------------------
  # ------- Harvester --------------------------------------------
  #
  # Manage the Harvester
  #
  # -------------------------------------------------------------------------
sub Tab_Harvester {

	return "Permission Denied" unless (&is_viewable("admin","database"));
	my $adminlink = $Site->{st_cgi}."admin.cgi";

  my $output = qq|<iframe class="admin-iframe"  src="$adminlink?action=harvester"></iframe>|;
	return $output;

}
  # TABS ----------------------------------------------------------
  # ------- Permissions --------------------------------------------
  #
  # Manage permissions
  #
  # -------------------------------------------------------------------------
sub Tab_Permissions {

   return "Permission Denied" unless (&is_viewable("admin","database"));
   my $adminlink = $Site->{st_cgi}."admin.cgi";
   my $output = qq|<iframe class="admin-iframe"  src="$adminlink?action=permissions"></iframe>|;
   return $output;

}
# TABS ----------------------------------------------------------
# ------- Users --------------------------------------------
#
# Manage users
#
# -------------------------------------------------------------------------
sub Tab_Users {

 return "Permission Denied" unless (&is_viewable("admin","users"));
 my $adminlink = $Site->{st_cgi}."admin.cgi";
 my $output = qq|<iframe class="admin-iframe"  src="$adminlink?action=users"></iframe>|;

 return $output;

}
  # TABS ----------------------------------------------------------
  # ------- General  --------------------------------------------
  #
  # General Admin Functions
  #
  # -------------------------------------------------------------------------
sub Tab_General {

   return "Permission Denied" unless (&is_viewable("admin","database"));
   my $adminlink = $Site->{st_cgi}."admin.cgi";
   my $output = qq|<iframe class="admin-iframe"  src="$adminlink?action=general"></iframe>|;
   return $output;

}
  # TABS ----------------------------------------------------------
  # ------- Subscribers  --------------------------------------------
  #
  # General Subscriber Functions
  #
  # -------------------------------------------------------------------------
sub Tab_Subscribers {

   return "Permission Denied" unless (&is_viewable("admin","database"));
   my $adminlink = $Site->{st_cgi}."admin.cgi";
   my $output = qq|<iframe class="admin-iframe"  src="$adminlink?action=users"></iframe>|;
   return $output;

}
  # TABS ----------------------------------------------------------
  # ------- General  --------------------------------------------
  #
  # General Accounts Functions
  #
  # -------------------------------------------------------------------------
sub Tab_Accounts {

   return "Permission Denied" unless (&is_viewable("admin","database"));
   my $adminlink = $Site->{st_cgi}."admin.cgi";
   my $output = qq|<iframe class="admin-iframe"  src="$adminlink?action=accounts"></iframe>|;
   return $output;

}
  # TABS ----------------------------------------------------------
  # ------- General  --------------------------------------------
  #
  # General Accounts Functions
  #
  # -------------------------------------------------------------------------
sub Tab_Meetings {

  return "Permission Denied" unless (&is_viewable("admin","database"));
  my $adminlink = $Site->{st_cgi}."admin.cgi";
  my $output = qq|<iframe class="admin-iframe"  src="$adminlink?action=meetings"></iframe>|;
  return $output;

}
	# TABS ----------------------------------------------------------
	# ------- General  --------------------------------------------
	#
	# General Accounts Functions
	#
	# -------------------------------------------------------------------------
sub Tab_Newsletters {

	return "Permission Denied" unless (&is_viewable("admin","database"));
	my $adminlink = $Site->{st_cgi}."admin.cgi";
	my $output = qq|<iframe class="admin-iframe" src="$adminlink?action=newsletters"></iframe>|;
	return $output;

}
	# TABS ----------------------------------------------------------
	# ------- Identity  --------------------------------------------
	#
	# Edit Person Functions
	#
	# -------------------------------------------------------------------------
sub Tab_Identity {


	return "Permission Denied" unless (&is_viewable("edit","person"));
	my ($window,$table,$id_number,$record,$data) = @_;
	my $output = "";

	foreach my $field (@{$window->{tab_list}->{Identity}}) {
		$output .= &process_field_types($window,$table,$id_number,$field,$record,$data,$defined);
	}
	return  $output;

}
	# TABS ----------------------------------------------------------
	# ------- Visibility  --------------------------------------------
	#
	# Edit Person Functions
	#
	# -------------------------------------------------------------------------
sub Tab_Visibility {

	return "Permission Denied" unless (&is_viewable("edit","person"));
	my ($window,$table,$id_number,$record,$data) = @_;
	my $output = "";

	foreach my $field (@{$window->{tab_list}->{Visibility}}) {
		$output .= &process_field_types($window,$table,$id_number,$field,$record,$data,$defined);
	}
	return  $output;

}
	# TABS ----------------------------------------------------------
	# ------- location  --------------------------------------------
	#
	# Edit Person Functions
	#
	# -------------------------------------------------------------------------
sub Tab_Location {

	return "Permission Denied" unless (&is_viewable("edit","person"));
	my ($window,$table,$id_number,$record,$data) = @_;
	my $output = "";

	foreach my $field (@{$window->{tab_list}->{Location}}) {
		$output .= &process_field_types($window,$table,$id_number,$field,$record,$data,$defined);
	}
	return  $output;

}
	# TABS ----------------------------------------------------------
	# ------- Web  --------------------------------------------
	#
	# Edit Person Functions
	#
	# -------------------------------------------------------------------------
sub Tab_Web {

	return "Permission Denied" unless (&is_viewable("edit","person"));
	my ($window,$table,$id_number,$record,$data) = @_;
	my $output = "";

	foreach my $field (@{$window->{tab_list}->{Web}}) {
		$output .= &process_field_types($window,$table,$id_number,$field,$record,$data,$defined);
	}
	return  $output;

}
	# TABS ----------------------------------------------------------
	# ------- General  --------------------------------------------
	#
	# General Accounts Functions
	#
	# -------------------------------------------------------------------------
sub Tab_Logs {

	return "Permission Denied" unless (&is_viewable("admin","database"));
	my $adminlink = $Site->{st_cgi}."admin.cgi";
	my $output = qq|<iframe class="admin-iframe" src="$adminlink?action=logs"></iframe>|;
	return $output;

}
	# TABS ----------------------------------------------------------
	# ------- Database --------------------------------------------
	#
	# Generic Database Functions
	#
	# -------------------------------------------------------------------------
sub Tab_Database {


	# Permissions
	return "Permission Denied" unless (&is_viewable("admin","database"));
	my $apilink = $Site->{st_cgi}."api.cgi";
  my $adminlink = $Site->{st_cgi}."admin.cgi";

	my $content = qq|<div class="container"><div id="admin_editor_area" style="width:100%;">
	   $vars->{dbmsg}<h2 style='font-family:-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";'>Database</h2><p>Get database information and manage database tables.</p>|;


	# Manage Database

	# Create generic tables dropdown
	my @tables = $dbh->tables();
	my $table_dropdown;
	foreach my $table (@tables) {

		# Remove database name from specification of table name
		if ($table =~ /\./) {
			my ($db,$dt) = split /\./,$table;
			$table = $dt;
		}

		# User cannot view or manipulate person or config tables
		next if ($table eq "person" || $table eq "config");
		$table=~s/`//g;  #`

		my $sel; if ($table eq $sst) { $sel = " selected"; } else {$sel = ""; }
		$table_dropdown  .= qq|		<option value="$table"$sel>$table</option>\n|;
	}
	my $select_a_table = qq|		<option value="">Select a table</option>\n|;


	# Edit a Database
   # Open Main: url,cmd,db,id,title,starting_tab
	$content .= qq|
	  <div>Select a database:
			 <select id="database_table_selection" name="stable">
			    $select_a_table
					$table_dropdown
			 </select>
	 </div>
	 <script>
			\$('#database_table_selection').on('change',function(){
			var content = \$('#database_table_selection').val();
			openDiv('$apilink','main','edit','form','',content,'Database');
			});
	 </script>|;


	# Back Up Database

	$content .= qq|
		<div class="text-input">
			<label for="database_table_backup">Back Up Database</label>
			<div class="text-input-form">
				<select id="database_table_backup" name="database_table_backup">
				  $select_a_table
				  <option value="all">All Tables</option>
				  $table_dropdown</select>
				<div tabindex="0" role="button" class="btn" aria-pressed="false" 
			   		onclick="
					    var content = \$('#database_table_backup').val();
						submitData(
							{ div:'back_up_database_result',
								cmd:'backup',
								table: content,
							});
					">Back Up Database
				</div>
			</div>
		</div>
		<div id="back_up_database_result"></div>|;


	# Create a Table

	$content .= qq|
		<div>
    Add Table: <input type="text" id="add_table_content" name="add_table_content" placeholder="Enter table name" required>
    <input type="button" id="add_table_submit" name="add_table_submit"  value="Add Table">
		<div id="add_table_submit_result"></div>
		</div>

		<script>
		\$('#add_table_submit').on('click',function(){
			var content = \$('#add_table_content').val();
			if (content.length == 0) {
					\$('#add_table_submit_result').html("<div class='error'>You must provide a table name.</div>"); return;
			}
			api_submit('$apilink','add_table_submit','create','table',content,'','',content);
		});
	 </script>|;



	# Drop a Table

	 $content .= qq|
 		<div>Drop Table:
		<select id="drop_table_content" name="drop_table_content">
			$select_a_table
			$table_dropdown</select>
 		<input type="button" id="drop_table_submit" name="drop_table_submit" value="Drop Table">
 		<div id="drop_table_submit_result"><span style="color:red;">Warning</span>: dropping a table will eliminate all data in the table. Table data will be saved in a backup file.</div>
 		</div>

 		<script>
 		\$('#drop_table_submit').on('click',function(){
 			var content = \$('#drop_table_content').val();
 			if (!content) { alert("You must provide a table name."); exit; }
 			api_submit('$apilink','drop_table_submit','drop','table',content,'','',content);
 		});
 	 </script>|;

	# Drop a Table




	# Import from File


	my $tout = qq|<select name="table">$table_dropdown</select><br/>\n|;


	$content  .= qq|
		<br/><h3>Import Data From File</h3>
		<div class="adminpanel">
		The file needs to be preloaded on the server. The system expects a tab delimited file with
		field names in the first row. Importer will ignore field names it does not recognize.<br/><br/>
		<form method="post" action="$adminlink" enctype="multipart/form-data">
		<input type="hidden" name="action" value="import">
		<table cellpadding=2>
		<tr><td>Import into table:</td><td>$tout</td></tr>
		<tr><td>File URL:</td><td><input type="text" name="file_url" size="40"></td></tr>
		<tr><td>Or Select:</td><td><input type="file" name="myfile" /></td></tr>
		<tr><td>Data Format:</td><td><select name="file_format"><option value="">Select a format...</option>
		<option value="tsv">Tab delimited (TSV)</option>
		<option value="csv">Comma delimited (CSV)</option>
		<option value="json">JSON</option></select></td>
		<tr><td colspan=2><input type="submit" value="Import" class="button"></tr></tr></table>
		</form></div>|;

	# Export data

	$content  .= qq|
		<br/><h3>Export Data</h3>
		<div class="adminpanel">
		<form method="post" action="$adminlink">
		<input type="hidden" name="action" value="export_table">
		<table cellpadding=2>
		<tr><td>Export from table:</td><td>$tout</td></tr>
		<tr><td>Data Format:</td><td><select name="export_format"><option value="">Select a format...</option>
		<option value="tsv">Tab delimited (TSV)</option>
		<option value="csv">Comma delimited (CSV)</option>
		<option value="json">JSON</option></select></td>
		<tr><td colspan=2><input type="submit" value="Export" class="button"></tr></tr></table>
		</form></div>|;


	$content .=  qq|</table></ul>|;






	$Site->{ServerInfo}  =  $dbh->{'mysql_serverinfo'};
	$Site->{ServerStat}  =  $dbh->{'mysql_stat'};

	$content .= qq|
		<h3>Database Information</h3><br/><ul>
		&nbsp;&nbsp;Server Info: $Site->{ServerInfo} <br/>
		&nbsp;&nbsp;Server Stat: $Site->{ServerStat}<br/><br/></ul>|;

  $content .= "</div></div>";
   return $content;


}



1;