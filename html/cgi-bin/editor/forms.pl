
	# FORM ELEMENT ----------------------------------------------------------
	# -------  Text Input -----------------------------------------------------
	#
	# Creates Text Input Form Field for varchar and other shgort text input
	#
	# -------------------------------------------------------------------------

#           FORM FUNCTIONS
	#-------------------------------------------------------------------------------

sub fieldlable {				# Creates Lable value used by forms
	my ($col, $table) = @_; 

	my $fieldlable = $col;
	$fieldlable =~ s/$table//i;
	$fieldlable =~ s/_//i;
	$fieldlable = ucfirst($fieldlable);
	return $fieldlable;
}
sub form_publish_page {

	my ($table,$id,$export) = @_;
	my $div = $table."_publish";
	$table ||= "page";
	my $formtext = qq|
		<div class="text-input">
			<label for="$col">Publish Page</label>
			<div class="text-input-form">|;

	my @export_list = split / /,$export;

	foreach my $epf (@export_list) {
		$formtext .= qq|

				<div tabindex="0" role="button" class="btn" aria-pressed="false"  style="display:inline;"
					onclick="
						submitData(
							{ div:'$div',
								cmd:'publish',
								table:'$table',
								id:'$id',
								export:'$epf',
							});
					">Publish $epf
				</div>
		|;
	}
	$formtext .= qq|
			</div>
		</div>
		<div id="$div" class="result"></div>|;
	return $formtext;
}

sub form_pushbutton {

	my ($table,$id,$col,$cmd,$div,$label,$confirm) = @_;

	unless ($table) { return qq|Table not specified for pushbutton|;}
	unless ($id) { return ucfirst($table).qq| ID not specified for pushbutton|;}
	unless ($cmd) { return qq|Cmd not specified for pushbutton|;}

	$label ||= ucfirst($cmd);
	$bcmd = ucfirst($cmd);
	$div ||= $col."_".$cmd."_result";


	my $ca; my $cb;
	if ($confirm) { 
		$ca = qq|var r = confirm('Are you sure?'); if (r == true) {|;
		$cb = qq|}|;
		}

	return qq|
		<div class="text-input">
			<label for="$col">$label</label>
			<div class="text-input-form">
				<div tabindex="0" role="button" class="btn" aria-pressed="false" 
			   		onclick="
					   $ca
						   submitData(
							{ div:'$div',
								cmd:'$cmd',
								col: '$col',
								table:'$table',
								id:'$id',
							});
							setTimeout(function(){ 
								loadList({div:'List',cmd:'list',table:'$table'});
							}, 3000);
							
						$cb
					">$bcmd
				</div>
			</div>
		</div>
		<div id="$div" class="result"></div>
	|;
}

sub form_showrecorddata {

	my ($table,$id) = @_;

	my $output = &form_pushbutton($table,$id,"dump","dump","record-dump","Show Record Data").
	qq|<div id="record-dump"></div>|;

	return $output;

}

sub form_password {
	my ($table,$id,$col,$value,$size,$fieldlable,$advice) = @_;
  	my $url = $Site->{st_cgi}."api.cgi";
	my $placeholder = ucfirst($col); $placeholder =~ s/_/ /g;
	unless ($fieldlable) { $fieldlable = &fieldlable($col,$table); }
		return qq|
		<div class="text-input"> 
			<label for="$col">$fieldlable</label>
			<div class="text-input-form">
				<input type="password" class="text-input-field" placeholder="$placeholder" id="|.$col.qq|" value="$value" style="width:|.$size.qq|em;max-width:90%;" onChange="
				   	var submitValue=\$('#|.$col.qq|').val();
					submitData(
					   {div:'|.$col.qq|_result',
					    type: 'password',
					    cmd:'update',
						table:'$table',
						field:'$col',
						id:'$id',
						value: submitValue,
						});
				"> $link_button 
				<div id="|.$col.qq|_result"></div>
			</div>
		</div>
	|;


}

sub form_textinput {
	my ($table,$id,$col,$value,$size,$fieldlable,$advice) = @_;
  	my $url = $Site->{st_cgi}."api.cgi";
	$value =~ s/"/&quot;/sg;
	my $placeholder = ucfirst($col); $placeholder =~ s/_/ /g;
	unless ($fieldlable) { $fieldlable = &fieldlable($col,$table); }

	# extra for link form submission
	my $link_button = "";
	if ($col =~ /_link/) { $link_button = &form_linkinput($table,$id,$col,$value);	}

	# Old-Style Form Alternative
	if (defined($vars->{raw_form})) { return qq|<tr><td class="column-name" align="right" width="200">$col</td><td><input type="text" name="$col" value="$value"></td></tr>|; }

	return qq|
		<div class="text-input"> 
			<label for="$col">$fieldlable</label>
			<div class="text-input-form">
				<input type="text" class="text-input-field" placeholder="$placeholder" id="|.$col.qq|" value="$value" style="width:|.$size.qq|em;max-width:90%;" onChange="
				   	var submitValue=\$('#|.$col.qq|').val();
					submitData(
					   {div:'|.$col.qq|_result',
					    cmd:'update',
						table:'$table',
						field:'$col',
						id:'$id',
						value: submitValue,
						});
				"> $link_button 
				<div id="|.$col.qq|_result"></div>$advice
			</div>
		</div>
	|;


}

	# FORM ELEMENT ----------------------------------------------------------
	# -------  Link Input -------------------------------------------------------
	#
	# Creates a button to collect data about the link and
	# sets up Javascript to use the resulting data in the current form
	#
	# -------------------------------------------------------------------------
sub form_linkinput {
	my ($table,$id,$col,$value) = @_;
	my $colval = qq|\$('#|.$col.qq|').val()|;
	return qq|
		<button name="Anlyze Link"
			onClick="
				var submitValue=\$('#|.$col.qq|').val();
				populateForm(
				   {div:'|.$col.qq|_link_result',
				    cmd:'analyze_link',
					table:'$table',
					field:'$col',
					id:'$id',
					link: submitValue,
					});
			
			"
			alert('value:'+\$('#|.$col.qq|').val());"
		>Load Link Data</button>
	|;

}


	# FORM ELEMENT ----------------------------------------------------------
	# -------  Textarea -------------------------------------------------------
	#
	# Creates plain textarea input for code, rules and raw text
	#
	# -------------------------------------------------------------------------
sub form_textarea {

	my ($table,$id,$col,$value,$size,$advice) = @_;
  my $url = $Site->{st_cgi}."api.cgi";
  unless ($size =~ /x/i) { $size = "50x".$size; }
	my ($width,$height) = split 'x',$size;
	$height ||= 10;
	$width ||= 40;

	my $fieldlable = &fieldlable($col,$table);
	my $placeholder = ucfirst($col); $placeholder =~ s/_/ /g;
	#$value ||= $col;

	# Escape markup
	$value =~ s/</&lt;/sig;
	$value =~ s/>/&gt;/sig;


	# Old-Style Form Alternative
	if (defined($vars->{raw_form})) { return qq|$col<br><textarea name="$col" cols="$width" rows="$height">$value</textarea>|; }

	return qq|

		<div class="text-input">
		   <label for="$col">$fieldlable</label>$advice
		   <div class="text-input-form">
				<textarea id="|.$col.qq|" placeholder="$placeholder" class="text-input-textarea" 
					style="width:|.$width.qq|em;height:|.$height.qq|em;" 
					contenteditable="true" onChange="
						var submitValue=\$('#|.$col.qq|').val();
						submitData(
							{   div:'|.$col.qq|_result',
								cmd:'update',
								table:'$table',
								field:'$col',
								id:'$id',
								value: submitValue,
							});
						">$value</textarea>
				<div id="|.$col.qq|_result"></div> 
		   </div>
		</div>
	|;

}

	# FORM ELEMENT ----------------------------------------------------------
	# -------  WYSI HTML Input -----------------------------------------------------
	#
	# Creates Formatted HTML Text Input Form Field
	#
	# -------------------------------------------------------------------------
sub form_wysihtml {
	my ($table,$id,$col,$value,$size,$advice) = @_;
  	my $url = $Site->{st_cgi}."api.cgi";
	my ($width,$height) = split 'x',$size;
	$height ||= 10;
	$width ||= 40;
	$ckheight = $height-3;  #Leaves room for toolbars


	my $placeholder = ucfirst($col); $placeholder =~ s/_/ /g;
	my $fieldlable = &fieldlable($col,$table);

	$value ||= $placeholder;

	# Escape markup
	$value =~ s/</&lt;/sig;
	$value =~ s/>/&gt;/sig;

	# Old-Style Form Alternative
	if (defined($vars->{raw_form})) { return qq|$col<br><textarea name="$col" cols="$width" rows="$height">$value</textarea>|; }

	return qq|

		<!-- Integration based on instructions here http://docs.ckeditor.com/#!/guide/dev_jquery - Downes -->
		<!-- CKEditor  width is sized using the div -->
    	<div id="editordiv" class="text-input" style="width:|.$width.qq|em;">
			<label for="$col">$fieldlable</label>
			<div class="text-input-form">
    			<textarea id="|.$col.qq|" contenteditable="true" class="text-input-textarea"
					style="width:|.$width.qq|em;height:|.$height.qq|em;">$value</textarea>
				<div id="|.$col.qq|_result"></div>$advice
			</div>
   		</div>
	
		<script>
   		\$( document ).ready(function() {
			CKEDITOR.replace( '|.$col.qq|', {
				width: '100%',
				height: '|.$ckheight.qq|em',
				// Define the toolbar groups as it is a more accessible solution.
				toolbarGroups: [
					{"name":"basicstyles","groups":["basicstyles"]},
					{"name":"links","groups":["links"]},
					{"name":"insert","groups":["insert"]},
					{"name":"paragraph","groups":["list","blocks"]},
					{"name":"styles","groups":["styles"]},
					{"name":"document","groups":["mode"]}
				],
				// Remove the redundant buttons from toolbar groups defined above.
				removeButtons: 'Underline,Strike,Subscript,Superscript,Anchor,Styles,Specialchar'} 
			);

			var editor = CKEDITOR.instances['|.$col.qq|'];
			var timer_|.$col.qq|;

			editor.on('change',function(){
				// do stuff only when user has been idle for 1 second
				clearTimeout(timer_|.$col.qq|);
				timer_|.$col.qq| = setTimeout(function() {

					// Submit Changed Content
					var url = "$url";
					var editor = CKEDITOR.instances['|.$col.qq|'];
					var content = editor.getData();

					submitData(
						{div:'|.$col.qq|_result',
						cmd:'update',
						table:'$table',
						field:'$col',
						id:'$id',
						value: content, }
					);
					var previewUrl = url+"?cmd=show&table=$table&id=$id&format=summary";
					\$('#Preview').load("previewUrl");
				},1000);
			});
		});
		</script>

	|;


}

	# FORM ELEMENT ----------------------------------------------------------
	# ------- Rules -----------------------------------------------------
	#
	# Creates Textarea Form Field for Rules
	#
	# -------------------------------------------------------------------------
sub form_rules {


	my ($table,$id_number,$col,$value,$fieldsize,$advice) = @_;

	$advice .= qq|<span class="small_nav">[<a href="http://grsshopper.downes.ca/rules.htm" target="_new">Rules Help</a></span>]|;
	$output .= &form_textarea($table,$id_number,$col,$value,$fieldsize,$advice);

	return $output;

}

	# FORM ELEMENT ----------------------------------------------------------
	# -------  Key List --------------------------------------------
	#
	#   This allows records from one table to be associeted with another.
	#   For example, a post may have an author; the 'author' field is a keylist
	#   The user submits the name or title of the author; if it is found it
	#   is associeted with the post in the graph, otherwise a new 'author'
	#   record is created, and it is associated with the post in the graph.
	#   The choices are made available in a dropdown if fewer than 20, or
	#   available as an autofill if fewer than 100, otherwise a record search
	#   is provided.
	#
	# -------------------------------------------------------------------------
sub form_keylist {

	my ($table,$id,$key,$host,$noedit) = @_;
	my $col = $table."_".$key;
	my $key_title = ucfirst($key);
	my $url = $Site->{st_cgi}."api.cgi";
	if ($host) { $host = "'$host'"; }

	my $keylist_text = &form_graph_list($table,$id,$key,'',$noedit);

    my $input_field;
    $input_field = qq|<input list="$key_title" class="keylist-input-field empty-after" placeholder="Add $key_title" id="|.$col.qq|" style="width:|.$size.qq|em;max-width:100%;">|;

  	my $count = &db_count($dbh,$key);

	# Add autofill if there aren't too many items
  	if ($count < 50) {
		$input_field .= qq|\n<datalist id="$key_title">\n|;
		my $titles = &db_get_column($dbh,$key,$key."_title");
		unless ($titles) { $titles = &db_get_column($dbh,$key,$key."_name");}
    	foreach my $t (@$titles) { 
			$input_field .= qq|<option value="$t">\n|; }
    	$input_field .= qq|</datalist>\n|;
  	} else {
		$input_field .= "Search and Select";
	}	 

	return qq|

	<div class="keylist-input">
	   <label for="$key_title">$key_title</label>
       <div id="|.$key.qq|_graph_list" class="keylist-text">$keylist_text</div>
       <div id="keylist-input-field" class="keylist-input-form">
		    $input_field
			<button type="button" id="|.$col.qq|_button" class="keylist-input-button" onClick="
					var submitValue=\$('#|.$col.qq|').val();
				   	submitData(
					   {div:'|.$key.qq|_graph_result',
					    cmd:'update',
						table:'$table',
						key:'$key',
						id:'$id',
						noedit:'$noedit',
						type: 'keylist',
						value: submitValue,
						},$host);
			">Update</button>
			<div id="|.$key.qq|_graph_result"></div>
       </div>

    </div>
	|;
}

	# -------  File Select -----------------------------------------------------
	#
sub form_file_from_url {

	my ($col,$placeholder,$value,$table,$id,$advice) = @_;

	return qq|	
		<div class="text-input">
			<label for="$col">Import From URL</label>
			<div class="text-input-form">
				<input type="text" class="text-input-field" placeholder="$placeholder" id="|.$col.qq|" value="$value" style="width:|.$size.qq|em;max-width:90%;" onChange="
				   var submitValue=\$('#|.$col.qq|').val();
				   submitData(
					   {div:'|.$col.qq|_url_result',
					    cmd:'update',
						table:'$table',
						field:'$col',
						id:'$id',
						type: 'file_url',
						value: submitValue,
						});
				">
				<div id="|.$col.qq|_url_result"></div>$advice
			</div>
		</div>
		
	|;
}	



sub form_file_upload {

	my ($col,$table,$id) = @_;

	return qq|
		<div class="text-input">
			<label for="$col">Upload File</label>
			<div class="text-input-form">
				<form id="fileUploadForm"  class="text-input-field" >
				<input type="hidden" name="div" value="|.$col.qq|_upload_result">
				<input type="hidden" name="cmd"	value="update">
				<input type="hidden" name="table" value="$table">
				<input type="hidden" name="field" value="$col">
				<input type="hidden" name="id" value="$id">
				<input type="hidden" name="type" value="file">
				<input type="file" id="fileUpload" />
				</form>
			</div>
			<script>
			document.querySelector('#fileUpload').addEventListener('change', event => {
			  uploadFile(event,{div:'|.$col.qq|_upload_result',table:'$table',id:'$id'})
			});
			</script>


		</div>
		<div id="|.$col.qq|_upload_result"></div>
	|;

}
	# Creates File Select Form Field
sub form_file_select {

	my ($dbh,$table,$id,$col) = @_;
  	my $fieldlable = &fieldlable($col,$table);

	# Create list of already associated files - Put in div #file_graph_list
	my $keylist_text = &form_graph_list($table,$id,"file");
	$keylist_text ||= qq|<div style="margin-left:3em;">None. Enter a URL or browse local files to upload.</div>|;

	# Return the form for File Uploads, with options for URLs and Browse
	return qq|
		<label for="keylist">File(s) Uploaded</label>
		<div class="text-input">
			<div id="file_graph_list" class="keylist-text">
			$keylist_text
			</div>
		</div>|.
		&form_file_from_url($col,$placeholder,$value,$table,$id).
		&form_file_upload($col,$table,$id).
		"<br /><br />";

}
	# -------  Form Submit -----------------------------------------------------
	#
	# Creates Form Submit Button
sub form_submit {


	if (defined($vars->{raw_form})) {
		return qq|<tr><td colspan="4"><input type="submit" value="Update Record" class="button"></td></tr>|;
	}

}
sub form_boolean {


	my ($col,$data,$table,$record) = @_;

	my $output = "";
	unless (defined $data) { $data = 1; }
	my $fieldlable = &fieldlable($col,$table);


	foreach my $opt ("TRUE","FALSE") {
		my $optbin; if ($opt eq "TRUE") { $optbin=1; } else { $optbin=0; }
		my $selected; if ($optbin eq $data) { $selected = " selected"; } else { $selected=""; }
		$output .= qq|    <option value="$optbin"$selected>$opt</option>\n|;

	}


	$output = qq|<select name="$col" style="width:12em;">$output</select>|;

	my $open="";my$close="";
	if ($Site->{newrow} eq "1") {
		$Site->{newrow} = 0;
		$close = "</tr>";
	} else {
		$Site->{newrow} = 1;
		$open = "<tr>";
	}

	return qq|$open<td><label for="$col">$fieldlable</label></td><td>$output</td>$close|;

}

	# Form Data
	#
	# Displayes in editable form data that is stored in a single field
	# as follows:  value1a,value1b,value1c,...;value2a,value2b,value2c,...
sub form_data {


	my ($col,$data,$id,$table) = @_;
	my $fieldlable = &fieldlable($col,$table);


	my $output = qq|
	</form>
	<label for="$col">$fieldlable</label>
	<form id="$col" action="$Site->{st_cgi}api.cgi" method="post">
	<input type="hidden" name="table_name" value="$table">
	<input type="hidden" name="table_id" value="$id">
	<input type="hidden" name="col_name" value="$col">
	<input type="hidden" name="type" value="data">
	<input type="hidden" name="value" value="data input">
	<input type="hidden" name="updated" value="1">
	<table border=0>|;

	# Assign default data to initialize the grid
	unless ($data) {
		$data = qq|fieldname1,fieldname2,fieldname3;value1,value2,value3;value1,value2,value3|;
	}


	my $rows=0; my $maxcols=0;

	# For each row (delimited by ; in storage)
	my @data_items = split /;/,$data;
	foreach my $data_item (@data_items) {

		# For each column (delimeted by , in storage)
		$output .= "<tr>"; my $cols=0;
		@data_bits = split /,/,$data_item; my $datacol = 0;
		foreach my $databit (@data_bits) {




			# Create an input form
			$cols++; if ($cols > $maxcols) { $maxcols = $cols; }
			if ($rows) { $output .= qq|<td style="padding-top: 12px;"><input name="$rows-$cols" type="text" value="$databit" style="width:15em"></td>\n|; }
			else {  $output .= qq|<td style="border-bottom: 1px solid black;"><input name="$rows-$cols" type="text" value="$databit"  style="width:15em"></td>\n|; }

		}
		$output .= "</tr>"; $rows++;
	}

	# Add an extra row for new data
	$output .= "<tr>";
	for (my $i=0; $i < $maxcols; $i++) { $output .= qq|<td style="padding-top: 12px;"><input name="$rows-$i" type="text" value="" style="width:15em"></td>\n|; }

	$output .= qq|</tr><tr><td><input type="Submit"> <span id="|.$col.qq|_okindicator"></span></form></td></tr></table>|;




	#$output .= qq|<textarea style="font-family: Courier;" name="$col" rows="$rows" cols=60>$data</textarea>|;

  $output .= qq|
  <script type="text/javascript">
    var frm = \$('#$col');
    frm.submit(function (e) {
        e.preventDefault();
        \$.ajax({
            type: frm.attr('method'),
            url: frm.attr('action'),
            data: frm.serialize(),
            success: function (data) {
		\$("#form_commit_button_text").show();
		\$("#form_commit_button_done").hide();
		\$('#|.$col.qq|_okindicator').show();
		\$('#|.$col.qq|_okindicator').html(data);
		\$('#|.$col.qq|_okindicator').hide(4000);
            },
            error: function (data) {
                alert('An error occurred.');
                alert(data);
            },
        });
    });

 </script>\n\n|;



	return qq|
		<tr><td align="right" class="column-name" style="width:10%;min-width:50px;" valign="top">$col</td>
		<td class="column-content" colspan=3 style="width:90%; min-width:200px;" valign="top">
	<div>$output</div></td></tr><form>




	|;



}

	# FORM ELEMENT ----------------------------------------------------------
	# -------  Graph List --------------------------------------------
	#
	#   This produces a list of related items of a certain key (eg. 'author')
	#   from the graph for a particular resource (eg. 'post' number 'id').
	#   The list of items can be restricted to a certain 'type' of relations.
	#
	#   Links in the list open form editor screens in the gRSShopper app
	#   (requires grsshopper_admin.js)
	#
	# -------------------------------------------------------------------------
sub form_graph_list {

	my ($table,$id,$key,$type,$noedit) = @_;
	my $output = "";
	my $admin = &admin_only();

	my @keylist = &find_graph_of($table,$id,$key,$type);
  my $onclickurl = $Site->{st_cgi}."api.cgi";
	foreach my $keyid (@keylist) {
		next unless ($keyid > 0);
		my $keyname = &get_key_name($key,$keyid);
		if ($admin && !$noedit) {
			 # Open Main: url,cmd,db,id,title,starting_tab
		#	$editlink = qq|[<a href="#" onClick="openDiv('$onclickurl','main','edit','$key','$keyid','','Edit');">Edit</a>] |;

			$editlink = qq|[<a href="#" onClick="openDiv(url,'editor','edit','$key','$keyid','Edit');">Edit</a>]|;

			#$editlink = qq|[<a href="$Site->{st_cgi}admin.cgi?$key=$keyid&action=edit">Edit</a>]|;
			$removelink = qq|[<a href="#" onClick="submitData(
				{div:'|.$key.qq|_graph_result',
				cmd:'remove',
				table:'$table',
				id: '$id',
				noedit: '$noedit',
				key:'$key',
				keyid:'$keyid',
			});
			">Remove</a>] |;
			#removeKey('$onclickurl','$table','$id','$key','$keyid');
			#$removelink = qq| [<a href="$Site->{st_cgi}admin.cgi?table=$table&id=$id&remove=$key/$keyid&action=remove_key">Remove</a>]|;
		}
		$output .= qq|<li class="graph-list-element"><a href="|.
			$Site->{st_cgi}.qq|page.cgi?$key=$keyid" target="new">$keyname</a> $editlink $removelink</li>|;
		#$output .= $keyid." ".$keyname."<p>";
	}

  	if ($output) {
	$output = sprintf(qq|
		<div id="%s">
     		<ul class="graph_list" style="margin:0px;">
			%s
			</ul>  
		</div>
		<div id="%s"></div>|,$key."_graph_list",$output,$key."_graph_result");
	}
	return $output;

}

	# -------  Date Select -----------------------------------------------------
	#
	# Creates Date Select Form Field
sub form_date_select {

	my ($table,$id,$col,$value,$size,$fieldlable) = @_;
	my $fieldlable = &fieldlable($col,$table);

  	$size ||= 20;
  	my $url = $Site->{st_cgi}."api.cgi";
	# Default to today's date
	unless ($value) {
		$value = &cal_date(time);
	}


	# Old-Style Form Alternative
	if (defined($vars->{raw_form})) {
		my $dateformat = 'yyyy/mm/dd';
		my $datetype = "date";
		my $output = &form_dates_general($table,$id,$title,$col,$value,$dateformat,$datetype,$fieldlable);
		return $output;
	}



	return qq |
		<div class="text-input">
			<label for="$col">$fieldlable</label>
			<div class="text-input-form">
				<input type="text" id="$col" value="$value" style="width:|.$size.qq|em;max-width:100%;">
				<div id="|.$col.qq|_result"></div>
			</div>
		</div>
		
		<script>
		\$( document ).ready(function() {
			\$( "#$col" ).datepicker({
				dateFormat: "yy/mm/dd",
				onSelect: function(date, instance) {
					var submitValue = \$('#|.$col.qq|').val();
					submitData(
					   {div:'|.$col.qq|_result',
					    cmd:'update',
						table:'$table',
						field:'$col',
						id:'$id',
						value: submitValue,
						});
					var previewUrl = url+"?cmd=show&table=$table&id=$id&format=summary";
					\$('#Preview').load(previewUrl);
				}
			});
		} );
		</script>
	|;

}

	# -------  Date-Time Select -----------------------------------------------------
	#
	# Creates Date-Time Select Form Field
sub form_date_time_select {

	my ($record,$col,$colspan,$advice,$fieldlable) = @_;
	my ($table,$title) = split /_/,$col;
	my $id = $record->{$table."_id"};
	my $value = $record->{$col} || "";
	my $url = $Site->{st_cgi}."api.cgi";
#$value=time;
  # DateTime is stored as epoch, we need to convert to datetimepicker
	unless ($value) { $value = time; }
  my $dpvalue;
  if ($value =~ /^\d+?$/) { $dpvalue = &epoch_to_datepicker($value,$Site->{st_timezone}); }
  else { $dpvalue = &epoch_to_datepicker(time,$Site->{st_timezone}); }  # Failsafe
  unless ($fieldlable) { $fieldlable = ucfirst($title); }
   my $output = qq|

	 <div>
  	 <label for="$col">$fieldlable</label>
	 <input type="text" id="$col" value="$dpvalue" style="width:|.$size.qq|em;max-width:100%;">
	 <div id="|.$col.qq|_result"></div>
	 
	 <script>
   \$( document ).ready(function() {
		 \$('#$col').datetimepicker({
			 inline:false,
			 onSelectDate: function(date, instance) {
				 var url = "$url";
				 var submitValue = \$('#|.$col.qq|').val();
				 submitData(
					   {div:'|.$col.qq|_result',
					    cmd:'update',
						table:'$table',
						field:'$col',
						id:'$id',
						value: submitValue,
				 });
				 var previewUrl = url+"?cmd=show&table=$table&id=$id&format=summary";
				 \$('#Preview').load(previewUrl);
			 },
			 onSelectTime: function(date, instance) {
				 var url = "$url";
				 var submitValue = \$('#|.$col.qq|').val();
				 submitData(
					   {div:'|.$col.qq|_result',
					    cmd:'update',
						table:'$table',
						field:'$col',
						id:'$id',
						value: submitValue,
				 });
				 var previewUrl = url+"?cmd=show&table=$table&id=$id&format=summary";
				 \$('#Preview').load(previewUrl);
			 },
		 });
   });
	 </script>
	 		</div>|;

return $output;


	# Time Zone - default to site defined time zone
	my $tzkey = $table."_timezone";
	unless ($record->{$tzkey}) { $record->{$tzkey} = $Site->{st_timezone};	}

	# Date-time - convert epoch into date-time
	if ($value =~ /^[0-9,.E]+$/) { $value = &cal_date($value,"min",$record->{$tzkey}); }

	my $dateformat = 'yyyy/mm/dd hh:ii';
	my $datetype = "datetime";

	my $output = &form_dates_general($table,$id,$title,$col,$value,$dateformat,$datetype,$fieldlable);
	return $output .$value;
}

	# -------  Dates General -----------------------------------------------------
	# Implementation of x-editables plus datetimepicker
	# and requires additional datetimepicker.css and datetimepicker.js
	# from https://github.com/smalot/bootstrap-datetimepicker
	# Select format and formtype to toggle between date and datetime
sub form_dates_general {

	my ($table,$id,$title,$col,$value,$dateformat,$datetype,$fieldlable) = @_;
  my $url = $Site->{st_cgi}."api.cgi";


	# Old-Style Form Alternative
	$value =~ s/"/\\"/sg;
	if (defined($vars->{raw_form})) { return qq|<tr><td class="column-name" align="right" width="200">$col</td><td><input type="text" name="$col" value="$value"></td></tr>|; }

  if ($fieldlable) { $fieldlable = qq|<span class="fieldlable" id="$col-fieldlable">$fieldlable</span>|;}

	return qq|
		<tr><td colspan=2><label for="$col">$fieldlable</label></td></tr>
		<tr><td align="right" class="column-name" style="width:10%;min-width:50px;" valign="top">$col</td>
		<td class="column-content" colspan=3 style="width:90%; min-width:200px;" valign="top">
		<span id="|.$col.qq|" contenteditable="true" style="width:40em; line-height:1.8em;" >$value</span>
		<span id="|.$col.qq|_button"><button>Update</button></span>
		<span id="|.$col.qq|_result"></span>

		<script>
		\$(document).ready(function(){
			\$('#|.$col.qq|_button').hide();
			\$('#|.$col.qq|').click(function() { onclick_function("$col");});
			\$('#|.$col.qq|_button').click(function(){
				var content = \$('#|.$col.qq|').text();
				var url = "$url";
				submit_function(url,"$table","$id","$col",content,"text");
				var previewUrl = url+"?cmd=show&table=$table&id=$id&format=summary";
				\$('#Preview').load("previewUrl");
			});
		});
		</script>
		</td></tr>
	|;



}

	# -------  Form Timezone -----------------------------------------------------
sub form_timezone {

	my ($name,$value,$table,$record) = @_;
	my $col = $table."_timezone";
	my $fieldlable = &fieldlable($col,$table);

	# Time Zone - default to site defined time zone
	my $tzkey = $table."_timezone";
	unless ($record->{$tzkey}) { $record->{$tzkey} = $Site->{st_timezone};	}

	my @dt = DateTime::TimeZone->all_names;
	my $dtstr = qq|<label for="$col">$fieldlable</label><select name="|.$table.qq|_timezone" style="height:18pt;">\n|; foreach my $dts (@dt) {
		my $sel; if ($dts eq $record->{$tzkey}) { $sel = " selected"; } else { $sel = ""; }
		$dtstr .= qq|<option value="$dts" $sel>$dts</option>\n|;
	}

	$dtstr .= "</select>\n";


	return qq|<tr><td valign="top">Time Zone</td><td colspan="3">$dtstr</td></tr>|;


}
sub date_time_parse {
	my ($value) = @_;
	$value =~ /(.*?)(\/|-)(.*?)(\/|-)(.*?) (.*?):(.*?)/;
	my $year = $1; my $month = $3; my $day = $5; my $hour = $6, my $min = $7;
	return ($year,$month,$day,$hour,$min);
}
sub date_time_find {

	my ($time) = @_;
	unless ($time) { $time = time; }
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
	if ($sec < 10) { $sec = "0".$sec; }
	if ($min < 10) { $min = "0".$min; }
	if ($hour < 10) { $hour = "0".$hour; }
	if ($mday < 10) { $mday = "0".$mday; }
	$mon++; if ($mon < 10) { $mon = "0".$mon; }
	if ($year < 2000) { $year += 1900; }
	return ($sec,$min,$hour,$mday,$mon,$year);
}

	# FORM ELEMENT ----------------------------------------------------------
	# -------  Yes-No -------------------------------------------------------
	#
	# Creates select dropdown
	#
	# -------------------------------------------------------------------------
sub form_yesno {

	my ($table,$col,$id,$value,$size,$fieldlable,$advice) = @_;
	my $url = $Site->{st_cgi}."api.cgi";
	$value =~ s/"/\\"/sg;
	my $placeholder = ucfirst($col); $placeholder =~ s/_/ /g;
   	my $host = $Site->{st_cgi}."api.cgi";

	# Old-Style Form Alternative
	if (defined($vars->{raw_form})) { return qq|<tr><td class="column-name" align="right" width="200">$col</td><td><input type="text" name="$col" value="$value"></td></tr>|; }
	my $checked; 
	if ($value eq "yes") { $checked = "checked" };
	return qq|
		<div class="yesno-input">
	    <label for="$col">$fieldlable</label>
		<label class="toggle-check">
		  <input type="checkbox" id="$col-checkbox" class="toggle-check-input" $checked/>
		  <span class="toggle-check-text"></span> $advice
		</label>
		</div>
		<script>
			var url = "$url";
			\$('#|.$col.qq|-checkbox').change(function() {
				if(this.checked) {

			  		submitData({
						div:'|.$col.qq|_result',
						cmd:'update',
						table:'$table',
						field: '$col',
						value: 'yes',
						id:'$id',
						host:'$host',
					});
					return false;

				} else {
					submitData({
					   div:'$col-yesnoResult',
						cmd:'update',
						field: '$col',
						value: 'no',
						table:'$table',
						id:'$id',
						host:'$host',
					});
					return false;
				}
				var previewUrl = url+"?cmd=show&table=$table&id=$id&format=summary";
		  		\$('#Preview').load("previewUrl");
			});
		</script>
		<span id="|.$col.qq|_result"></span>
	|;

}

	# FORM ELEMENT -----------------------------------------------------------
	# -------  Optlist -------------------------------------------------------
	#
	# Customizes drodown options for form select
	#
	# -------------------------------------------------------------------------
sub form_optlist {

	# Organize field data

	my ($window,$table,$id,$col,$selected_value,$fieldsize,$advice,$fieldlable,$defined,$ajax) = @_;

	# Find eligible options
	my $opts = &db_get_record($dbh,"optlist",{optlist_title=>$col});

	# Default to varchar if we can't find eligible options
	unless ($opts->{optlist_data} || $opts->{optlist_list}) {
		return &form_textinput($table,$id,$col,$value,$size,$advice);
	}

	# Create list of options 
	my $options = "";
	my $option_lables="";
	my @opts = split ";",$opts->{optlist_data};
	my $lablecounter=1;

	# Enable additional selection to be submitted as an optlist option
	$fieldsize.="+";

	foreach my $opt (@opts) {
		my ($oname,$ovalue) = split ",",$opt;
		next unless ($oname && $ovalue);

		my $selected;

		if ($selected_value =~ /$ovalue/) { $selected = qq| selected="selected"|; }

		$options .= qq|\n<option class="optlist-option" value="$ovalue" $selected >$oname</option>|;

		my $lableid = $col.$lablecounter; $lablecounter++;
		$option_lables .= qq|
            <span class="form__answer"> <input type="radio" id="$lableid" name="$col" value="$ovalue" style="display:none;"> Add
        	<label for="$col">$fieldlable $oname</label></span>|;
	}


	if ($ajax) {
	    return &form_select($window,$table,$id,$col,$selected_value,$fieldsize,$advice,$options,$fieldlable);
	} else {
	    return qq|$option_lables|;
	}

}

	# FORM ELEMENT ----------------------------------------------------------
	# -------  Select -------------------------------------------------------
	#
	# Creates select dropdown
	#
	# -------------------------------------------------------------------------
sub form_select {

	my ($window,$table,$id,$col,$selected_value,$fieldsize,$advice,$options,$fieldlable,$defined) = @_;
	unless ($window->{form_defined}) { $fieldsize=1;}

  	my $host = $Site->{st_cgi}."api.cgi";
	unless ($fieldlable) { $fieldlable = $col;}
	$fieldlable =~ s/$table_//;
	$fieldlable = ucfirst $fieldlable;

	# Check $fieldsize to see if there's a + which indicates we want to allow new terms
	my $newOptionText;
#	if ($fieldsize =~ m/\+/) {
		$fieldsize =~ s/\+//;
		$newOptionText = qq|
			<input type="text" size=15 id="$col-newOption" placeholder="Add $fieldlable?">
			<input type="button" value="Create new $fieldlable" onClick="
				var oval = document.getElementById('$col-newOption').value;
				submitData(
					{   div:'$col-newOptionResult',
						cmd:'newOption',
						col: '$col',
						value: document.getElementById('$col-newOption').value,
						table:'$table',
						id:'$id',
						host:'$host',
					});

				return false;
			">
			<div id="$col-newOptionResult"></div>|;
#	}

	my $multiple; if ($window->{form_defined} && $fieldsize>1) { $multiple = " multiple size=$fieldsize";}
  if ($defined) { $defined = "defined";} else { $defined = "undefined"; }  #Was this field defined in a form table for the current table
  # Uses plugin from
	# https://www.jqueryscript.net/form/Bootstrap-Plugin-To-Convert-Select-Boxes-Into-Button-Groups-select-togglebutton-js.html

	# $fieldlable

	# This is a special command to reload the harvester 
	# commands if feed status is changed
	my $uhc = ""; my $uhcasync = "";
	if ($table eq "feed" && $col =~ /_status/) {
	#	$uhc = qq|alert('hi');|;
		$uhc = qq|
			updateFeedStatus();
		|;
		$uhcasync = qq|
			// Haven't been able to make async work properly, alert is a hack
			function updateFeedStatus() {
				submitDataFromSelect('$col','$table',$id,'$host');;
				alert('Status Changed. Confirm.');
				loadHTML({'cmd':'harvester-commands','id':'$id','div':'harvester-commands'});
			}
		|;

	# This is what we do otherwise, which is 99% of the time	
	} else {
		$uhc = qq|submitDataFromSelect('$col','$table',$id,'$host');|;
	}

	return qq|
		<div class="optlist-input"> 
	  		<label for="$col">$fieldlable</label>
			<div class="optlist-input-form">
	      		<div class="row form-group" style="margin-left:5px;"> 		
		  			<select id="$col" $multiple onChange="$uhc">$options</select> 
					$newOptionText
				</div>
				<div id="|.$col.qq|_result"></div>
			</div>
		</div>
		<script>
			\$('#|.$col.qq|').togglebutton();
			$uhcasync
		</script>
	|;

}

	# FORM UTILITY ----------------------------------------------------------
	# -------  Table Option List --------------------------------------------
	#
	# Creates a standard option list from the list of tables
	#
	# -------------------------------------------------------------------------
sub table_option_list {
   	my ($selected) = @_;

	 # Create generic tables dropdown
	 my @tables = $dbh->tables();
	 my $table_option_list;

	 foreach my $table (@tables) {
		# Remove database name from specification of table name
		if ($table =~ /\./) {	my ($db,$dt) = split /\./,$table;	$table = $dt;	}

		# User cannot view or manipulate person or config tables
		next if ($table eq "person" || $table eq "config");
		$table=~s/`//g;

		my $sel; if ($table eq $selected) { $sel = " selected"; } else {$sel = ""; }
		$table_dropdown  .= qq|		<option value="$table"$sel>$table</option>\n|;
	}
  return $table_option_list;
}

	# -------  get Key Name --------------------------------------------
	#
	#   Returns a name for table $key and id $id
sub get_key_name {

	my ($key,$id) = @_;
	my $field = get_key_namefield($key);
	my $name = &db_get_single_value($dbh,$key,$field,$id);
	return $name;

}

	# -------- get key name array ---------------------------------------
	#
	#   Returns an array of names or titles for a table $key
	#   Use for form typeahead lookup
sub get_key_name_array {

	my ($key) = @_;
	my $field = get_key_namefield($key);
	my $names_ref = &db_get_column($dbh,$key,$field);
	return $names_ref;

}

	# -------- get key namefield ---------------------------------------
sub get_key_namefield {
	my ($key) = @_;
	my $field = $key."_title";
	if ($key eq "person" || $key eq "author") { $field = $key."_name"; }
	return $field;

}

	# -------  Key Input -----------------------------------------------------
	#
	# Creates Key inoput and lookup
sub form_keyinput {
	my ($name,$value) = @_;

	if ($name =~ m/id$/) { $name =~ s/(.*?)id$/$1/; }		# Remove 'id' from end of field name
	my $title = $name;									# This gives us our table name


	$title =~ s/(.*?)_(.*?)/$2/;
	$title = ucfirst($title);
	my $editlink; if ($value) {
		$editlink = qq|[<a href="$Site->{st_cgi}admin.cgi?|.lc($title)."=".$value.qq|&action=edit">Edit</a>]|;
	}

	return qq |
		<tr><td>Key: $title</td><td colspan="3">
		<input type="text" name="$name" value="$value" size="10" style="height:1.8em;">
		$editlink
		</td>
		</tr>
		|;

}

	# -------  Page Options -----------------------------------------------------
	#
	#
sub form_page_options {

	my ($table,$id_number,$record) = @_;


	return unless (&is_viewable("publish","page"));
	return unless ($table eq "page");
	return unless ($Site->{script} =~ /admin/);

	my @auto = qw|Never Weekly Daily Hourly|;
	my @wdays = qw|Sunday Monday Tuesday Wednesday Thursday Friday Saturday|;
	my @mdays = qw|01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31|;
	my @dhour = qw|00 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23|;
	my @dmin = qw|00 05 10 15 20 25 30 35 40 45 50 55|;
	my @noyes = qw|no yes|;

	my $archivelink = "";
	if ($record->{page_archive} eq "yes") {
		my $archivefile = $record->{page_location};
		$archivefile =~ s/\//_/g;
		$archivelink=qq|[<a href="$Site->{st_cgi}archive.cgi?page=$archivefile">View Page Archive</a>]|;
	}

	my $autopubpanel = qq|
		<br/><h3>Publishing Options</h3>
		<div class="adminpanel" style="text-align:left;"><table><tr><td>
		Publish to: $Site->{st_url}<input style="height:1.8em;" type="text"
		name="page_location" value="$record->{page_location}" />\n
		<br>Archive page? |.&form_opt_multiple("page_archive",$record,\@noyes,1,100,0)." $archivelink".
		qq|<br>Autopublish? |.&form_opt_multiple("page_autopub",$record,\@noyes,1,100,0).
		qq|How often? |.&form_opt_multiple("page_autowhen",$record,\@auto,1,100,0).
		qq|<br>Allow empty (keywords)? |.&form_opt_multiple("page_allow_empty",$record,\@noyes,1,100,0).
		qq|<br>Note that pages are also autopublished and archived when sent as newsletters.\n
		</td></tr></table></div>
	|;


	my $newsletter_panel = qq|
		<br/><h3>Newsletter Options</h3>
		<div class="adminpanel" style="text-align:left;">
		<table cellpadding="3" border="1" width="90%">
		<tr><td colspan="3">Enable newsletter subscriptions? |.
		&form_opt_multiple("page_sub",$record,\@noyes,1,100,0).
		qq|<br>Auto-send newsletters turned on? |.
		&form_opt_multiple("page_subsend",$record,\@noyes,1,100,0).
		qq|<br>Autosubscribe to this newsletter? |.
		&form_opt_multiple("page_autosub",$record,\@noyes,1,100,0).
		qq|</td></tr>
		<tr><td>Weekdays</td><td>Days of Month</td><td>Time</td></tr>
		<tr><td>|.&form_opt_multiple("page_subwday",$record,\@wdays,5,150,1).qq|</td>
		<td valign="top">|.&form_opt_multiple("page_submday",$record,\@mdays,5,60,1).qq|</td>
		<td valign="top">|.&form_opt_multiple("page_subhour",$record,\@dhour,1,60,0).qq|:|.
		&form_opt_multiple("page_submin",$record,\@dmin,1,60,0).qq|</td></tr>
		<tr><td colspan="3">When should the newsletter be published and sent?
		Select more than one weekday or date as desired</td></tr>
		</table><p><input value="Update Record" class="button" type="submit"></p></div>
	|;
	my $text = "";
	$text .=  qq|
		<p>[<a href="$Site->{st_cgi}admin.cgi?db=page&action=list">List Pages</a>]
		[<a href="$Site->{st_cgi}admin.cgi?page=$id_number&force=yes">View Generated Version of Page</a>]
		[<a href="$Site->{st_cgi}admin.cgi?action=publish&page=$id_number&force=yes">Publish Page</a>]
		[<a href="$Site->{st_url}$record->{page_location}">View Published Page</a>]</p>|.
		$autopubpanel .
		$newsletter_panel .
		qq||;

  # &jq_panel("Set this page up as a newsletter?",$newsletter_panel,"330px").

	return $text;

}

	# -------  Badge Options -----------------------------------------------------
	#
	#
sub form_badge_options {

	my ($table,$id_number,$record) = @_;


	return unless (&is_viewable("publish","badge"));
	return unless ($table eq "badge");
	return unless ($Site->{script} =~ /admin/);



	my $autopubpanel = qq|
		<br/><h3>Publishing Options</h3>
		<div class="adminpanel" style="text-align:left;">
		Publish to: $Site->{st_url}<input style="height:1.8em;" type="text"
		name="badge_location" value="$record->{badge_location}" />\n
                <input value="Update Record" class="button" type="submit">
		</div>
	|;


	my $text = "";
	$text .=  qq|
		<p>
		[<a href="$Site->{st_cgi}admin.cgi?action=publish&badge=$id_number&force=yes">Publish Badge</a>]
		[<a href="$Site->{st_url}$record->{page_location}">View Published Badge</a>]</p>|.
		$autopubpanel .
		qq||;


	return $text;

}
sub form_opt_multiple {

	my ($field,$record,$list,$size,$width,$multiple) = @_;
	my @selected = split ",",$record->{$field};
	my $multi = ""; if ($multiple) { $multi = qq| multiple="multiple"|; }
	my $output = qq|<select $multi name="$field" size="$size" width="$width" style="width: |.$width.qq|px">\n|;
	foreach my $litem (@$list) {
		my $sel= ""; if (&index_of($litem,\@selected) > -1) { $sel = " selected"; }
		$output .= qq|<option value="$litem"$sel>$litem</option>\n|;
	}
	$output .= "</select>\n";
	return $output;
}
sub form_database {

	my ($table,$col,$id_value,$record,$data) = @_;

  my $stable = lc($record->{form_title});							# Define table name that we're working with
	unless ($stable) { $stable = $data->{title}; }			# Allow us to work with a tablename without an associated 'form' record
	                                              			# eg. when we've created a new database table, or selected from the option list

	my $table_option_list = &table_option_list($stable);
  my $onclickurl = $Site->{st_cgi}."api.cgi";

  # Open Main: url,cmd,db,id,title,starting_tab
	return qq|

	        <div id="submit_columns_result"></div>
          <div id="columns_table">
						  \n|.&show_columns($stable).qq|</div>
					<!-- More Database Functions -->
					<div style="padding:3px;width:100%;border: solid #f8f8f8 1px; background-color:#f0f0f0;color:#888888;">
						   More Database Functions \| Select a different database:
						   <select id="database_table_selection" name="stable">$table_dropdown</select> \|
               <a href="#" id="database_functions_selection">More Database Functions</a>
					</div>
					<script>
						\$('#database_table_selection').on('change',function(){
							var content = \$('#database_table_selection').val();
							openTab(event, 'editor', 'mainlinks');
							openDiv('$onclickurl','editor','edit','form','',content,'mainWindowTable');
						});

							\$('#database_functions_selection').on('click',function(){
								openTab(event, 'Admin', 'mainlinks');
								openDiv('$onclickurl','Admin','admin','database','','','mainWindowDatabase');
							});
					</script>|;
}
sub form_publish {

	my ($table,$id,$col,$value,$fieldsize,$advice) = @_;
  my $url = $Site->{st_cgi}."api.cgi";
  my @accounts;

# Badges
  if ($table eq "badge") { @accounts = qw(Badgr); }
  else {  @accounts = qw(Web Twitter Mastodon Facebook RSS JSON); }

	# List of supported social media sites


										# Future work - get this from the list of accounts
	# Set up return content
	my $return_text = qq|hello
	    <div class="text-input">
			<label for="$col">Publish!</label>
		</div>|;

	foreach my $account (@accounts) {

		my $published = "";
		# $value is the content of $table_social media, and contains a list of places already published
		if ($value =~ /$account/i) { $published = "Previously published"; }

		$return_text .= qq|
			<div class="text-input">
				<div class="text-input-form">
					<div tabindex="0" role="button" class="btn" aria-pressed="false" 
						onclick="
							submitData(
								{   div:'|.$account.qq|_publish_result',
									cmd:'publish',
									value:'$account',
									table:'$table',
									id:'$id',

								});
						">Publish to $account
					</div> <div class="results" id="|.$account.qq|_publish_result">$published</div>
				</div>
			</div>
			
		|;
	}
	return $return_text;
}


sub form_socialmedia {

	my ($table,$id_number,$col,$value,$fieldsize,$advice) = @_;
  my $url = $Site->{st_cgi}."api.cgi";
	my $return_text = qq|<tr><td>dPublish</td><td colspan="3">|;

	my @socialmedias = qw(twitter facebook web);				# List of supported social media sites

	foreach my $socialmedia (@socialmedias) {
		$return_text .= ucfirst($socialmedia).": ";

		if ($record->{post_social_media} =~ /$socialmedia/i) { $return_text .= "Published&nbsp;&nbsp;&nbsp;"; }
		else {
			$return_text .= qq|<select name="post_|;
			$return_text .= $socialmedia;
			$return_text .= qq|"><option value="">Later</option>
			<option value="yes">Publish Now</option>
			</select>&nbsp;&nbsp;&nbsp;|;	}
	}


	$return_text .= qq|<input type="submit" value="Publish" class="button"></td></tr>|;
	return $return_text;

	return qq|
		<tr><td align="right" valign="top">$col</td><td colspan=3 valign="top">
		<span id="|.$col.qq|" contenteditable="true" style="width:40em; line-height:1.8em;" >$value</span>
		<span id="|.$col.qq|_button"><button>Update</button></span>
		<span id="|.$col.qq|_result"></span>$advice

		<script>
		\$(document).ready(function(){
			\$('#|.$col.qq|_button').hide();
			\$('#|.$col.qq|').click(function() { onclick_function("$col");});
			\$('#|.$col.qq|_button').click(function(){
				var content = \$('#|.$col.qq|').text();
				var url = "$url";
				submit_function(url,"$table","$id","$col",content,"text");
				var previewUrl = url+"?cmd=show&table=$table&id=$id&format=summary";
				\$('#Preview').load("previewUrl");
			});
		});
		</script>
		</td></tr>
	|;




}
sub form_twitter {

	my ($record) = @_;

	my $return_text = qq|<tr><td>Publish</td><td colspan="3">|;

	my @socialmedias = qw(twitter facebook web);				# List of supported social media sites
	foreach my $socialmedia (@socialmedias) {
		$return_text .= ucfirst($socialmedia).": ";

		if ($record->{post_social_media} =~ /$socialmedia/i) { $return_text .= "Published&nbsp;&nbsp;&nbsp;"; }
		else {
			$return_text .= qq|<select name="post_|;
			$return_text .= $socialmedia;
			$return_text .= qq|"><option value="">Later</option>
			<option value="yes">Publish Now</option>
			</select>&nbsp;&nbsp;&nbsp;|;	}
	}


	$return_text .= qq|<input type="submit" value="Publish" class="button"></td></tr>|;
	return $return_text;


}
sub jq_panel {
	my ($message,$content,$height) = @_;
	$height ||= "280px";
	return qq|<script type="text/javascript">
  \$(document).ready(function(){
  \$(".flip").click(function(){
    \$(".panel").slideToggle("slow");
  });
 });
 </script>

 <style type="text/css">
 div.panel,p.flip
 {
 margin:0px;
 padding:5px;
 text-align:center;
 background:#e5eecc;
 border:solid 1px #c3c3c3;
 }
 div.panel
 {
 height: $height;
 display:none;
 }
 </style>

 <div class="panel">$content</div>

 <p class="flip">$message</p>


	|;


}

	# -------  Thread Options -----------------------------------------------------
	#
	#
sub form_thread_options {

	my ($table,$id_number,$pagefile) = @_;

	return unless ($table eq "thread");

	my $text = "";
	$text .=  qq|
		<p>[<a href="$Site->{st_cgi}cchat.cgi">Chat Selection Page</a>]<br/>
		[<a href="$Site->{st_cgi}cchat.cgi?chat_thread=$id_number&force=yes">Enter Chat Thread</a>]<br/>|;

	return $text;

}
	# ------- Submit Data -----------------------------------------------------
	#
sub form_update_submit_data {

	my ($dbh,$query,$table,$id_number,$data) = @_;
	my $vars = $data || $query->Vars;

	if ($table eq "post") {

		if ($Person->{person_status} eq "admin") { $vars->{$table."_source"} = "admin"; }

	}


	if ($id_number eq "new") {	# Create Record, or

		$vars->{$table."_crdate"} = time;
		$vars->{$table."_creator"} = $Person->{person_id};
		$id_number = &db_insert($dbh,$query,$table,$vars);
		$vars->{msg} .= "Created new $table ($id_number) <br/>";

		if ($vars->{$table."_thread"}) {										# If it's a comment
			my $ctable; my $cid;									# identify table and id of item being commented upon
			if ($vars->{$table."_thread"} =~ /:/) {	($ctable,$cid) = split /:/,$vars->{$table."_thread"}; }
			else { $ctable = "post"; $cid = $vars->{$table."_thread"}; }					# and increment its comment count
			$rep .= "<br>Incrementing $ctable $cid <br>";
			&db_increment($dbh,$ctable,$cid,$table."_comments","form_update_submit_data");
		}




	} else {				# Update Record

		my $where = { $table."_id" => $id_number};

		$id_number = &db_update($dbh,$table, $vars, $id_number);
		$vars->{msg} .= ucfirst($table)." $id_number successfully updated<br/>";
	}

							# Trap Errors
	unless ($id_number) {
		&error($dbh,$query,"","I attempted to create this record, but failed, sorry.");
		exit;
	}


	return $id_number;
}

	# -------   Admin Database ----------------------------------------------------------
sub show_columns {
	my ($stable) = @_;
  unless ($stable) { return "Sorry, you did not provide a table name to show."}
  # Set API URL
  my $api_url = $Site->{st_cgi}."api.cgi";

	my $columns = qq|<h3>Table: $stable </h3>\n<table  id="show_columns" cellpadding=3 cellspacing=0 border=1">
		<tr><td>Field</td>
		<td>Type</td><td>Size</td><td>Null</td>
		<td>Default</td><td>Extra</td></tr>\n|;



 #	my $showstmt = qq|SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = ? AND table_schema = ? ORDER BY column_name|;
	# Replaces:
	my $showstmt = "SHOW COLUMNS FROM $stable";


	my $sth = $dbh -> prepare($showstmt)  or return "Cannot prepare: $showstmt FOR $vars->{stable}, $Site->{db_name} " . $dbh->errstr();
 #	$sth -> execute($stable,$Site->{db_name})  or die "Cannot execute: $showstmt " . $dbh->errstr();
	$sth -> execute()  or return "Cannot execute: $showstmt " . $dbh->errstr();

	my $alt; # Toggle to shade table rows
	while (my $showref = $sth -> fetchrow_hashref()) {
 #print "Content-type: text/html\n\n";
 #print "Data: <p>";
 #while (my($cx,$cy) = each %$showref) { print "$cx = $cy <br>"; }

    # Identify column name
    my $cname = $showref->{Field};
    # Separate out type and size
		my $ctype; my $csize;
		if ($showref->{Type} =~ /(.*?)\((.*?)\)/) { $ctype=$1; $csize=$2 } else { $ctype = $showref->{Type}; }

		if($alt) { $alt=""; } else { $alt=qq| class="alt"|;}
		unless ($showref->{COLUMN_DEFAULT}) { $showref->{COLUMN_DEFAULT} = "none"; }
		unless ($showref->{COLUMN_KEY}) {  $showref->{COLUMN_KEY} = "-"; }
		unless ($showref->{EXTRA}) {  $showref->{EXTRA} = "-"; }

		$columns .= qq|<tr$alt>
		   <td>$cname</td>
			 <td><input size=12 name="|.$cname.qq|_type" id="|.$cname.qq|_type" value="|.$ctype.qq|"></td>\n
			 <td><input size=4 name="|.$cname.qq|_size" id="|.$cname.qq|_size" value="|.$csize.qq|"></td>\n
			 |;
		$columns .= qq|<td>$showref->{Null}</td><td>$showref->{Default}</td>

		<td>$showref->{Extra}

		   <a href="#" title="Update Column"
		   onclick="alter_column('$api_url','$stable','|.$showref->{Field}.qq|');">
			 <i class="fa fa-floppy-o"></i></a>

			 <a href="#" title="Remove Column"
			 onclick="remove_column('$api_url','$stable','|.$showref->{Field}.qq|','remove');">
			 <i class="fa fa-minus-square-o"></i></a> </td>

		</tr>\n|;

	}

  # Form to create new column
	$columns .= qq|
		<tr>
		<td><input name="new_column_field" id="new_column_field"  placeholder="Field name" size="20"></td>
		<td><select name="new_column_type" id="new_column_type" placeholder="Field Type">
        <option value="varchar">varchar</option>
        <option value="text">text</option>
				<option value="int">integer</option>
				<option value="bit">yes/no</option>
		    </select></td>
		    <td><input name="new_column_size" id="new_column_size" size="6" placeholder="Size"></td>
				<td><input name="new_column_default" id="new_column_null" size="5" placeholder="Null?"></td>
		<td><input name="new_column_default" id="new_column_default" size="10" placeholder="Default"></td>

		<td><input name="new_column_extra" id="new_column_extra" size="10" placeholder="Extra">
		<a href="#" title="Create Column" id="new_column_submit">
			 <i class="fa fa-floppy-o"></i></a></td>
		</tr>

		<script>
			\$('#new_column_submit').on('click',function(){
					var content = \$('#new_column_field').val() +";"+
					    \$('#new_column_type').val() +";"+
							\$('#new_column_size').val() +";"+
							\$('#new_column_null').val() +";"+
							\$('#new_column_default').val() +";"+
							\$('#new_column_extra').val();
					submit_column("$api_url","$stable","new","column",content,"column");
					openColumns("$Site->{st_cgi}api.cgi?app=show_columns&db=$stable","$stable");
			});


		</script>|;

	$columns .=  qq|</table>\n|;

  return $columns;
}

1;
