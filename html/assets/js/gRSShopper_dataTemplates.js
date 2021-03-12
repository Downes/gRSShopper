
	function ratingSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="ratingPanel">

		<form method="post" action="#" id="ratingSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>default <select name="default" id="defaultrating">
				    <option value="all" selected>All</a>
			
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'ratingSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'ratingSearchForm'}); 

			document.getElementById('ratingPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function banned_sitesSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="banned_sitesPanel">

		<form method="post" action="#" id="banned_sitesSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>default <select name="default" id="defaultbanned_sites">
				    <option value="all" selected>All</a>
			
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'banned_sitesSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'banned_sitesSearchForm'}); 

			document.getElementById('banned_sitesPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function configSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="configPanel">

		<form method="post" action="#" id="configSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>type <select name="type" id="typeconfig">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'configSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'configSearchForm'}); 

			document.getElementById('configPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function mediaSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="mediaPanel">

		<form method="post" action="#" id="mediaSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>type <select name="type" id="typemedia">
				    <option value="all" selected>All</a>
			
					<option value="document">document</a>
					<option value="image">image</a>
					<option value="video">video</a>
					<option value="audio">audio</a>
							</select></p>
				<p>mimetype <select name="mimetype" id="mimetypemedia">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'mediaSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'mediaSearchForm'}); 

			document.getElementById('mediaPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function aSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="aPanel">

		<form method="post" action="#" id="aSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'aSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'aSearchForm'}); 

			document.getElementById('aPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function eventSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="eventPanel">

		<form method="post" action="#" id="eventSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>section <select name="section" id="sectionevent">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>type <select name="type" id="typeevent">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>status <select name="status" id="statusevent">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>category <select name="category" id="categoryevent">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'eventSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'eventSearchForm'}); 

			document.getElementById('eventPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function publicationSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="publicationPanel">

		<form method="post" action="#" id="publicationSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>catdetails <select name="catdetails" id="catdetailspublication">
				    <option value="all" selected>All</a>
			
					<option value=" "> </a>
					<option value="Refereed">Refereed</a>
					<option value="Unrefereed">Unrefereed</a>
							</select></p>
				<p>category <select name="category" id="categorypublication">
				    <option value="all" selected>All</a>
			
					<option value="Grant">Grant</a>
					<option value=""></a>
					<option value="Report">Report</a>
					<option value="Column">Column</a>
					<option value="Article">Article</a>
					<option value="Application">Application</a>
					<option value="Chapter">Chapter</a>
							</select></p>
				<p>type <select name="type" id="typepublication">
				    <option value="all" selected>All</a>
			
					<option value="Research">Research</a>
					<option value=""></a>
					<option value="Internal">Internal</a>
					<option value="Journal">Journal</a>
					<option value="Magazine">Magazine</a>
					<option value="Book">Book</a>
					<option value="Newspaper">Newspaper</a>
					<option value="Funding">Funding</a>
					<option value="Patent">Patent</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'publicationSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'publicationSearchForm'}); 

			document.getElementById('publicationPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function viewSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="viewPanel">

		<form method="post" action="#" id="viewSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>default <select name="default" id="defaultview">
				    <option value="all" selected>All</a>
			
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'viewSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'viewSearchForm'}); 

			document.getElementById('viewPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function postSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="postPanel">

		<form method="post" action="#" id="postSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>category <select name="category" id="categorypost">
				    <option value="all" selected>All</a>
			
					<option value="OLDaily">OLDaily</a>
							</select></p>
				<p>genre <select name="genre" id="genrepost">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>type <select name="type" id="typepost">
				    <option value="all" selected>All</a>
			
					<option value="announcement">Announcement</a>
					<option value="shownotes">shownotes</a>
					<option value="link">Link</a>
					<option value="article">Article</a>
					<option value="preview">Preview</a>
					<option value="course">Course</a>
					<option value="comment">Comment</a>
					<option value="musing">Musing</a>
							</select></p>
				<p>field <select name="field" id="fieldpost">
				    <option value="all" selected>All</a>
			
					<option value="Other Image">
Other Image</a>
					<option value="Interview">Interview</a>
					<option value="Genre">Genre</a>
					<option value="Display">
Display</a>
					<option value="Thumbnail">Thumbnail</a>
					<option value="Enclosure">
Enclosure</a>
					<option value="Audio">
Audio</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'postSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'postSearchForm'}); 

			document.getElementById('postPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function templateSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="templatePanel">

		<form method="post" action="#" id="templateSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>default <select name="default" id="defaulttemplate">
				    <option value="all" selected>All</a>
			
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'templateSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'templateSearchForm'}); 

			document.getElementById('templatePanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function presentationSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="presentationPanel">

		<form method="post" action="#" id="presentationSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>category <select name="category" id="categorypresentation">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>catdetails <select name="catdetails" id="catdetailspresentation">
				    <option value="all" selected>All</a>
			
					<option value="Seminar">Seminar</a>
					<option value="Keynote">Keynote</a>
					<option value="Debate">Debate</a>
					<option value="Interview">Interview</a>
					<option value="Workshop">Workshop</a>
					<option value="Panel">Panel</a>
					<option value="Poster">Poster</a>
					<option value="Lecture">Lecture</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'presentationSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'presentationSearchForm'}); 

			document.getElementById('presentationPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function pageSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="pagePanel">

		<form method="post" action="#" id="pageSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>type <select name="type" id="typepage">
				    <option value="all" selected>All</a>
			
					<option value="email">email</a>
					<option value="CSS">CSS</a>
					<option value="TEXT">TEXT</a>
					<option value="XSL">XSL</a>
					<option value="JSON">JSON</a>
					<option value="HTML">HTML</a>
					<option value="RSS">RSS</a>
					<option value="JS">JS</a>
					<option value="XML">XML</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'pageSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'pageSearchForm'}); 

			document.getElementById('pagePanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function productSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="productPanel">

		<form method="post" action="#" id="productSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>type <select name="type" id="typeproduct">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>genre <select name="genre" id="genreproduct">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>category <select name="category" id="categoryproduct">
				    <option value="all" selected>All</a>
			
					<option value="Workforce">Workforce</a>
					<option value="Course">Course</a>
					<option value="Team">Team</a>
					<option value="Animation">Animation</a>
					<option value="virtualization">Virtualization</a>
					<option value="Note">Note</a>
					<option value="Prototype">Prototype</a>
					<option value="Text">Text</a>
					<option value="Form">Form</a>
					<option value="School">School</a>
					<option value="Photo">Photo</a>
					<option value="3D">3D</a>
					<option value="SEO">SEO</a>
					<option value="Learning">Learning</a>
					<option value="Identity">Identity</a>
					<option value="Employment">Employment</a>
					<option value="Software">Software</a>
					<option value="Payment">Payment</a>
					<option value="Image">Image</a>
					<option value="Quiz">Quiz</a>
					<option value="Test">Test</a>
					<option value="Simulation">Simulation</a>
					<option value="Message">Message</a>
					<option value="Game">Game</a>
					<option value="Audio">Audio</a>
					<option value="Portfolio">Portfolio</a>
					<option value="AR">AR</a>
					<option value="Content">Content</a>
					<option value="eMail">eMail</a>
					<option value="Class">Class</a>
					<option value="security">Security</a>
					<option value="Microcontent">Microcontent</a>
					<option value="Citation">Citation</a>
					<option value="Learning Content">Learning Content</a>
					<option value="Journal">Journal</a>
					<option value="Feed/API">Feed/API</a>
					<option value="Learning Object">Learning Object</a>
					<option value="Social">Social</a>
					<option value="Advertising">Advertising</a>
					<option value="Presentation">Presentation</a>
					<option value="Screen">Screen</a>
					<option value="eBook">eBook</a>
					<option value="Lecture">Lecture</a>
					<option value="Comment">Comment</a>
					<option value="Spreadsheet">Spreadsheet</a>
					<option value="Student">Student</a>
					<option value="Learning Design">Learning Design</a>
					<option value="Event">Event</a>
					<option value="Project">Project</a>
					<option value="Database">Database</a>
					<option value="Computer">Computer</a>
					<option value="Discussion">Discussion</a>
					<option value="Video">Video</a>
					<option value="Competency">Competency</a>
					<option value="Survey">Survey</a>
					<option value="Metadata">Metadata</a>
					<option value="Blog">Blog</a>
					<option value="Research">Research</a>
					<option value="File">File</a>
					<option value="VR">VR</a>
					<option value="Website">Website</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'productSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'productSearchForm'}); 

			document.getElementById('productPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function providerSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="providerPanel">

		<form method="post" action="#" id="providerSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>default <select name="default" id="defaultprovider">
				    <option value="all" selected>All</a>
			
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'providerSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'providerSearchForm'}); 

			document.getElementById('providerPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function projectSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="projectPanel">

		<form method="post" action="#" id="projectSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>category <select name="category" id="categoryproject">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'projectSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'projectSearchForm'}); 

			document.getElementById('projectPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function formSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="formPanel">

		<form method="post" action="#" id="formSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>default <select name="default" id="defaultform">
				    <option value="all" selected>All</a>
			
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'formSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'formSearchForm'}); 

			document.getElementById('formPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function organizationSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="organizationPanel">

		<form method="post" action="#" id="organizationSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>genre <select name="genre" id="genreorganization">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>type <select name="type" id="typeorganization">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>category <select name="category" id="categoryorganization">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'organizationSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'organizationSearchForm'}); 

			document.getElementById('organizationPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function chatSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="chatPanel">

		<form method="post" action="#" id="chatSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>default <select name="default" id="defaultchat">
				    <option value="all" selected>All</a>
			
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'chatSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'chatSearchForm'}); 

			document.getElementById('chatPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function feedSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="feedPanel">

		<form method="post" action="#" id="feedSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>status <select name="status" id="statusfeed">
				    <option value="all" selected>All</a>
			
					<option value="R">Retired</a>
					<option value="A">Approved</a>
					<option value="B">Unlinked</a>
					<option value="O">On Hold</a>
							</select></p>
				<p>category <select name="category" id="categoryfeed">
				    <option value="all" selected>All</a>
			
					<option value="design">Design</a>
					<option value="news---ed">Education News</a>
					<option value="Higher Ed">Higher Ed</a>
					<option value="K12">K12</a>
					<option value="cyberculture">Cyberculture</a>
					<option value="Ed Tech">Ed Tech</a>
					<option value="Language">Language</a>
					<option value="media">Media</a>
					<option value="ideas">Ideas</a>
					<option value="edubloggers">Education Blogs</a>
					<option value="Corporate">Corporate</a>
							</select></p>
				<p>type <select name="type" id="typefeed">
				    <option value="all" selected>All</a>
			
					<option value="Not Harvesting">Not Harvesting</a>
					<option value="Atom">Atom</a>
					<option value="YouTube">YouTube</a>
					<option value="RSS 1.0">RSS 1.0</a>
					<option value="Facebook">Facebook</a>
					<option value="RSS 0.91">RSS 0.91</a>
					<option value="OAI">OAI</a>
					<option value="JSON">JSON</a>
					<option value="RSS 2.0">RSS 2.0</a>
					<option value="Twitter">Twitter</a>
							</select></p>
				<p>genre <select name="genre" id="genrefeed">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>section <select name="section" id="sectionfeed">
				    <option value="all" selected>All</a>
			
					<option value="blog">Blog</a>
					<option value="other">Other</a>
					<option value="news media">News Media</a>
					<option value="podcast">Podcast</a>
					<option value="journal">Journal</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'feedSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'feedSearchForm'}); 

			document.getElementById('feedPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function queueSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="queuePanel">

		<form method="post" action="#" id="queueSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>default <select name="default" id="defaultqueue">
				    <option value="all" selected>All</a>
			
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'queueSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'queueSearchForm'}); 

			document.getElementById('queuePanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function subscriptionSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="subscriptionPanel">

		<form method="post" action="#" id="subscriptionSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>default <select name="default" id="defaultsubscription">
				    <option value="all" selected>All</a>
			
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'subscriptionSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'subscriptionSearchForm'}); 

			document.getElementById('subscriptionPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function boxSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="boxPanel">

		<form method="post" action="#" id="boxSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>default <select name="default" id="defaultbox">
				    <option value="all" selected>All</a>
			
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'boxSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'boxSearchForm'}); 

			document.getElementById('boxPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function linkSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="linkPanel">

		<form method="post" action="#" id="linkSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>category <select name="category" id="categorylink">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>status <select name="status" id="statuslink">
				    <option value="all" selected>All</a>
			
					<option value="Posted">Posted</a>
					<option value="Fresh">Fresh</a>
					<option value="Retired">Retired</a>
					<option value="Stale">Stale</a>
							</select></p>
				<p>section <select name="section" id="sectionlink">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>genre <select name="genre" id="genrelink">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>type <select name="type" id="typelink">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'linkSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'linkSearchForm'}); 

			document.getElementById('linkPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function conceptSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="conceptPanel">

		<form method="post" action="#" id="conceptSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>category <select name="category" id="categoryconcept">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>genre <select name="genre" id="genreconcept">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'conceptSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'conceptSearchForm'}); 

			document.getElementById('conceptPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function fileSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="filePanel">

		<form method="post" action="#" id="fileSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>type <select name="type" id="typefile">
				    <option value="all" selected>All</a>
			
					<option value="Slides">Slides</a>
					<option value="Document">Document</a>
					<option value="Thumbnail">Thumbnail</a>
					<option value="Illustration">Illustration</a>
					<option value="Audio">Audio</a>
					<option value="Enclosure">Enclosure</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'fileSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'fileSearchForm'}); 

			document.getElementById('filePanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function fieldSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="fieldPanel">

		<form method="post" action="#" id="fieldSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>type <select name="type" id="typefield">
				    <option value="all" selected>All</a>
			
					<option value="textarea">textarea</a>
					<option value="select">select</a>
					<option value="text">text</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'fieldSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'fieldSearchForm'}); 

			document.getElementById('fieldPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function courseSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="coursePanel">

		<form method="post" action="#" id="courseSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>default <select name="default" id="defaultcourse">
				    <option value="all" selected>All</a>
			
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'courseSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'courseSearchForm'}); 

			document.getElementById('coursePanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function optlistSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="optlistPanel">

		<form method="post" action="#" id="optlistSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>type <select name="type" id="typeoptlist">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'optlistSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'optlistSearchForm'}); 

			document.getElementById('optlistPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function graphSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="graphPanel">

		<form method="post" action="#" id="graphSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>type <select name="type" id="typegraph">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>typeval <select name="typeval" id="typevalgraph">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'graphSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'graphSearchForm'}); 

			document.getElementById('graphPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function personSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="personPanel">

		<form method="post" action="#" id="personSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>status <select name="status" id="statusperson">
				    <option value="all" selected>All</a>
			
					<option value="registered">registered</a>
					<option value="admin">admin</a>
					<option value="anon">anon</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'personSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'personSearchForm'}); 

			document.getElementById('personPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function topicSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="topicPanel">

		<form method="post" action="#" id="topicSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>status <select name="status" id="statustopic">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>type <select name="type" id="typetopic">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'topicSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'topicSearchForm'}); 

			document.getElementById('topicPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function authorSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="authorPanel">

		<form method="post" action="#" id="authorSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>type <select name="type" id="typeauthor">
				    <option value="all" selected>All</a>
			
					<option value="Organization">Organization</a>
					<option value="Person">Person</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'authorSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'authorSearchForm'}); 

			document.getElementById('authorPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function citeSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="citePanel">

		<form method="post" action="#" id="citeSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>default <select name="default" id="defaultcite">
				    <option value="all" selected>All</a>
			
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'citeSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'citeSearchForm'}); 

			document.getElementById('citePanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function placeSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="placePanel">

		<form method="post" action="#" id="placeSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>category <select name="category" id="categoryplace">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'placeSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'placeSearchForm'}); 

			document.getElementById('placePanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function institutionSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="institutionPanel">

		<form method="post" action="#" id="institutionSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>category <select name="category" id="categoryinstitution">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'institutionSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'institutionSearchForm'}); 

			document.getElementById('institutionPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function journalSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="journalPanel">

		<form method="post" action="#" id="journalSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>genre <select name="genre" id="genrejournal">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'journalSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'journalSearchForm'}); 

			document.getElementById('journalPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	
	function threadSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="threadPanel">

		<form method="post" action="#" id="threadSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<p>extype <select name="extype" id="extypethread">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>twitterstatus <select name="twitterstatus" id="twitterstatusthread">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
				<p>status <select name="status" id="statusthread">
				    <option value="all" selected>All</a>
			
					<option value="something else">something</a>
							</select></p>
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Description </option>
		</option>
		<input type="text" name="qval" placeholder="search term">
		<input type="button" value="Submit" 
			onClick="alert(JSON.stringify({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'threadSearchForm'}));
			
			loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'threadSearchForm'}); 

			document.getElementById('threadPanel').style.display = 'none';

			return false;

			">
			</div>`;
	};

	