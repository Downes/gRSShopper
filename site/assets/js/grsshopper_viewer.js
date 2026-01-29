function viewer_ajax_request(url,table,index) {
  parent.readerTable = table;
  parent.readerIndex = index;
	$('#viewer-screen').html('<p><img src="https://www.electrictoolbox.com/images/ajax-loader-2.gif" width="220" height="19" /></p>');
	$('#viewer-screen').load(url, "",function(responseText, textStatus, XMLHttpRequest) {
            if(textStatus == 'error') { $('#viewer-screen').html('<p>There was an error making the AJAX request</p><p>'+responseText+'</p>');}
        });
}

function viewer_post(sitecgi,link,sc)
{
viewer_ajax_request(sitecgi+"page.cgi?"+table+"=db=post&action=comment&autoblog="+link);


}


function viewer_increment(sitecgi,table,var1,last)
{

   if(var1 == 1)
   {
   	index++;
   	if (index > last) { index = last; }
   	document.getElementById('pointer').value=index;
   	document.getElementById('resource').value=larr[index];
   	document.getElementById('rescounter').innerHTML=index+1;

   	viewer_ajax_request(sitecgi+"page.cgi?"+table+"="+larr[index]+"&format=viewer",table,index);
   }

   if(var1 == 2)
   {
   	index--;
   	if (index < 0) { index = 0; }
   	document.getElementById('pointer').value=index;
   	document.getElementById('resource').value=larr[index];
   	document.getElementById('rescounter').innerHTML=index+1;
   	viewer_ajax_request(sitecgi+"page.cgi?"+table+"="+larr[index]+"&format=viewer",table,index);

   }

   if(var1 == 3)
   {
   	index = last;
   	document.getElementById('pointer').value=index;
   	document.getElementById('resource').value=larr[index];
   	document.getElementById('rescounter').innerHTML=index+1;
   	viewer_ajax_request(sitecgi+"page.cgi?"+table+"="+larr[index]+"&format=viewer",table,index);

   }

   if(var1 == 4)
   {
	index = 0;
   	document.getElementById('pointer').value=index;
   	document.getElementById('resource').value=larr[index];
   	document.getElementById('rescounter').innerHTML=index+1;
   	viewer_ajax_request(sitecgi+"page.cgi?"+table+"="+larr[index]+"&format=viewer",table,index);

   }
 }

 $(document).ready(function(){
  $('#comment').submit(function() { // catch the form's submit event
    $.ajax({ // create an AJAX call...
        data: $(this).serialize(), // get the form data
        type: $(this).attr('method'), // GET or POST
        url: $(this).attr('action'), // the file to call
        success: function(response) { // on success..
            $('#commented').html(response); // update the DIV
        }
    });
    return false; // cancel original event to prevent form submitting
 });

});
