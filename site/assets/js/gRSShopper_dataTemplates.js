
	function boxSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="boxPanel">

		<form method="post" action="#" id="boxSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Default <select name="box_default" id="defaultbox">
				    <option value="all" selected>All</a>
			
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'boxSearchForm'}); 
				document.getElementById('boxPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function organizationSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="organizationPanel">

		<form method="post" action="#" id="organizationSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Category <select name="organization_category" id="categoryorganization">
				    <option value="all" selected>All</a>
			<option value="Academic">Academic</a><option value="Community">Community</a><option value="Cooperative">Cooperative</a><option value="Education">Education</a><option value="Government">Government</a><option value="Health">Health</a><option value="Industry">Industry</a><option value="International">International</a><option value="Media">Media</a><option value="NGO">NGO</a><option value="Political">Political</a><option value="Research">Research</a><option value="Technical">Technical</a><option value="Trade/Commerce">Trade/Commerce</a>
							</select></div>
				<div class="table-list-search-form">Genre <select name="organization_genre" id="genreorganization">
				    <option value="all" selected>All</a>
			<option value="Advocacy">Advocacy</a><option value="Coordination">Coordination</a><option value="Development">Development</a><option value="Governance">Governance</a><option value="Knowledge Exchange">Knowledge Exchange</a><option value="Policy Development">Policy Development</a><option value="Research">Research</a><option value="Resource Sharing">Resource Sharing</a><option value="Standards">Standards</a>
							</select></div>
				<div class="table-list-search-form">Type <select name="organization_type" id="typeorganization">
				    <option value="all" selected>All</a>
			<option value="Alliance">Alliance</a><option value="Association">Association</a><option value="Board">Board</a><option value="Centre">Centre</a><option value="Club">Club</a><option value="Coalition">Coalition</a><option value="Commission">Commission</a><option value="Committee">Committee</a><option value="Consortium">Consortium</a><option value="Federation">Federation</a><option value="Foundation">Foundation</a><option value="Incubator">Incubator</a><option value="Lab">Lab</a><option value="Movement">Movement</a><option value="Network">Network</a><option value="Organization">Organization</a><option value="SIG">SIG</a><option value="Society">Society</a><option value="Syndicate">Syndicate</a><option value="System">System</a><option value="Trust">Trust</a><option value="Union">Union</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'organizationSearchForm'}); 
				document.getElementById('organizationPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function feedSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="feedPanel">

		<form method="post" action="#" id="feedSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Category <select name="feed_category" id="categoryfeed">
				    <option value="all" selected>All</a>
			<option value="Corporate">Corporate</a><option value="cyberculture">Cyberculture</a><option value="design">Design</a><option value="Ed Tech">Ed Tech</a><option value="edubloggers">Education Blogs</a><option value="news---ed">Education News</a><option value="Higher Ed">Higher Ed</a><option value="ideas">Ideas</a><option value="K12">K12</a><option value="Language">Language</a><option value="media">Media</a>
							</select></div>
				<div class="table-list-search-form">Genre <select name="feed_genre" id="genrefeed">
				    <option value="all" selected>All</a>
			<option value="Art">Art</a><option value="Biology">Biology</a><option value="Chemistry">Chemistry</a><option value="Economics">Economics</a><option value="Engineering">Engineering</a><option value="Farming">Farming</a><option value="Geography">Geography</a><option value="History">History</a><option value="Language">Language</a><option value="Management">Management</a><option value="Math">Math</a><option value="Philosophy">Philosophy</a><option value="Science">Science</a><option value="Sociology">Sociology</a><option value="Zoology">Zoology</a>
							</select></div>
				<div class="table-list-search-form">Section <select name="feed_section" id="sectionfeed">
				    <option value="all" selected>All</a>
			<option value="Blog">Blog</a><option value="Book">Book</a><option value="Events">Events</a><option value="Journal">Journal</a><option value="Magazine">Magazine</a><option value="News Media">News Media</a><option value="Other">Other</a><option value="Podcast">Podcast</a><option value="Serial">Serial</a>
							</select></div>
				<div class="table-list-search-form">Status <select name="feed_status" id="statusfeed">
				    <option value="all" selected>All</a>
			<option value="A">Approved</a><option value="O">On Hold</a><option value="R">Retired</a><option value="B">Unlinked</a>
							</select></div>
				<div class="table-list-search-form">Table <select name="feed_table" id="tablefeed">
				    <option value="all" selected>All</a>
			<option value="competency">Competency</a><option value="event">Event</a><option value="link">Link</a>
							</select></div>
				<div class="table-list-search-form">Topic <select name="feed_topic" id="topicfeed">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Type <select name="feed_type" id="typefeed">
				    <option value="all" selected>All</a>
			<option value="Atom">Atom</a><option value="Facebook">Facebook</a><option value="JSON">JSON</a><option value="Not Harvesting">Not Harvesting</a><option value="OAI">OAI</a><option value="RSS 0.91">RSS 0.91</a><option value="RSS 1.0">RSS 1.0</a><option value="RSS 2.0">RSS 2.0</a><option value="Twitter">Twitter</a><option value="YouTube">YouTube</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'feedSearchForm'}); 
				document.getElementById('feedPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function subscriptionSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="subscriptionPanel">

		<form method="post" action="#" id="subscriptionSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Default <select name="subscription_default" id="defaultsubscription">
				    <option value="all" selected>All</a>
			
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'subscriptionSearchForm'}); 
				document.getElementById('subscriptionPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function citeSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="citePanel">

		<form method="post" action="#" id="citeSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Default <select name="cite_default" id="defaultcite">
				    <option value="all" selected>All</a>
			
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'citeSearchForm'}); 
				document.getElementById('citePanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function queueSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="queuePanel">

		<form method="post" action="#" id="queueSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Default <select name="queue_default" id="defaultqueue">
				    <option value="all" selected>All</a>
			
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'queueSearchForm'}); 
				document.getElementById('queuePanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function eventSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="eventPanel">

		<form method="post" action="#" id="eventSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Category <select name="event_category" id="categoryevent">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Section <select name="event_section" id="sectionevent">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Status <select name="event_status" id="statusevent">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Type <select name="event_type" id="typeevent">
				    <option value="all" selected>All</a>
			<option value="Debate">Debate</a><option value="Interview">Interview</a><option value="Keynote">Keynote</a><option value="Lecture">Lecture</a><option value="Panel">Panel</a><option value="Poster">Poster</a><option value="Seminar">Seminar</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'eventSearchForm'}); 
				document.getElementById('eventPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function topicSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="topicPanel">

		<form method="post" action="#" id="topicSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Status <select name="topic_status" id="statustopic">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Type <select name="topic_type" id="typetopic">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'topicSearchForm'}); 
				document.getElementById('topicPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function templateSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="templatePanel">

		<form method="post" action="#" id="templateSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Default <select name="template_default" id="defaulttemplate">
				    <option value="all" selected>All</a>
			
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'templateSearchForm'}); 
				document.getElementById('templatePanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function personSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="personPanel">

		<form method="post" action="#" id="personSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Status <select name="person_status" id="statusperson">
				    <option value="all" selected>All</a>
			<option value="admin">Admin</a><option value="anon">Anon</a><option value="registered">Registered</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'personSearchForm'}); 
				document.getElementById('personPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function journalSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="journalPanel">

		<form method="post" action="#" id="journalSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Genre <select name="journal_genre" id="genrejournal">
				    <option value="all" selected>All</a>
			<option value="Open Access">Open Access</a><option value="Subscription">Subscription</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'journalSearchForm'}); 
				document.getElementById('journalPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function optlistSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="optlistPanel">

		<form method="post" action="#" id="optlistSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Type <select name="optlist_type" id="typeoptlist">
				    <option value="all" selected>All</a>
			<option value="checkbox">Checkbox</a><option value="radio">Radio</a><option value="select">Select</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'optlistSearchForm'}); 
				document.getElementById('optlistPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function institutionSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="institutionPanel">

		<form method="post" action="#" id="institutionSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Category <select name="institution_category" id="categoryinstitution">
				    <option value="all" selected>All</a>
			<option value="government">Government</a><option value="museum">Museum</a><option value="nonprofit">Nonprofit</a><option value="university">University</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'institutionSearchForm'}); 
				document.getElementById('institutionPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function fileSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="filePanel">

		<form method="post" action="#" id="fileSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Type <select name="file_type" id="typefile">
				    <option value="all" selected>All</a>
			<option value="Audio">Audio</a><option value="Document">Document</a><option value="Enclosure">Enclosure</a><option value="Illustration">Illustration</a><option value="Slides">Slides</a><option value="Thumbnail">Thumbnail</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'fileSearchForm'}); 
				document.getElementById('filePanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function presentationSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="presentationPanel">

		<form method="post" action="#" id="presentationSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Catdetails <select name="presentation_catdetails" id="catdetailspresentation">
				    <option value="all" selected>All</a>
			<option value="Debate">Debate</a><option value="Interview">Interview</a><option value="Keynote">Keynote</a><option value="Lecture">Lecture</a><option value="Panel">Panel</a><option value="Poster">Poster</a><option value="Seminar">Seminar</a><option value="Workshop">Workshop</a>
							</select></div>
				<div class="table-list-search-form">Category <select name="presentation_category" id="categorypresentation">
				    <option value="all" selected>All</a>
			<option value="J - Presented Papers and Talks">J - Presented Papers and Talks</a>
							</select></div>
				<div class="table-list-search-form">Topics <select name="presentation_topics" id="topicspresentation">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Type <select name="presentation_type" id="typepresentation">
				    <option value="all" selected>All</a>
			<option value="A Publications in Refereed Journals">A Publications in Refereed Journals</a><option value="B Publications in Refereed Conference Proceedings">B Publications in Refereed Conference Proceedings</a><option value="C Publications in Trade Journals">C Publications in Trade Journals</a><option value="">D Publicatio</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'presentationSearchForm'}); 
				document.getElementById('presentationPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function linkSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="linkPanel">

		<form method="post" action="#" id="linkSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Category <select name="link_category" id="categorylink">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Genre <select name="link_genre" id="genrelink">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Section <select name="link_section" id="sectionlink">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Status <select name="link_status" id="statuslink">
				    <option value="all" selected>All</a>
			<option value="Fresh">Fresh</a><option value="Posted">Posted</a><option value="Retired">Retired</a><option value="Stale">Stale</a>
							</select></div>
				<div class="table-list-search-form">Topics <select name="link_topics" id="topicslink">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Type <select name="link_type" id="typelink">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'linkSearchForm'}); 
				document.getElementById('linkPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function threadSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="threadPanel">

		<form method="post" action="#" id="threadSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Extype <select name="thread_extype" id="extypethread">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Status <select name="thread_status" id="statusthread">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Twitterstatus <select name="thread_twitterstatus" id="twitterstatusthread">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'threadSearchForm'}); 
				document.getElementById('threadPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function formSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="formPanel">

		<form method="post" action="#" id="formSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Default <select name="form_default" id="defaultform">
				    <option value="all" selected>All</a>
			
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'formSearchForm'}); 
				document.getElementById('formPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function graphSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="graphPanel">

		<form method="post" action="#" id="graphSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Type <select name="graph_type" id="typegraph">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Typeval <select name="graph_typeval" id="typevalgraph">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'graphSearchForm'}); 
				document.getElementById('graphPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function aSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="aPanel">

		<form method="post" action="#" id="aSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'aSearchForm'}); 
				document.getElementById('aPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function projectSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="projectPanel">

		<form method="post" action="#" id="projectSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Category <select name="project_category" id="categoryproject">
				    <option value="all" selected>All</a>
			<option value="advocacy">Advocacy</a><option value="competition">Competition</a><option value="development">Development</a><option value="research">Research</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'projectSearchForm'}); 
				document.getElementById('projectPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function ratingSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="ratingPanel">

		<form method="post" action="#" id="ratingSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Default <select name="rating_default" id="defaultrating">
				    <option value="all" selected>All</a>
			
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'ratingSearchForm'}); 
				document.getElementById('ratingPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function configSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="configPanel">

		<form method="post" action="#" id="configSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Type <select name="config_type" id="typeconfig">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'configSearchForm'}); 
				document.getElementById('configPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function placeSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="placePanel">

		<form method="post" action="#" id="placeSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Category <select name="place_category" id="categoryplace">
				    <option value="all" selected>All</a>
			<option value="city">City or Town</a><option value="continent">Continent</a><option value="country">Country</a><option value="province">Province or State</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'placeSearchForm'}); 
				document.getElementById('placePanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function mediaSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="mediaPanel">

		<form method="post" action="#" id="mediaSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Mimetype <select name="media_mimetype" id="mimetypemedia">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Type <select name="media_type" id="typemedia">
				    <option value="all" selected>All</a>
			<option value="audio">Audio</a><option value="document">Document</a><option value="image">Image</a><option value="video">Video</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'mediaSearchForm'}); 
				document.getElementById('mediaPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function chatSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="chatPanel">

		<form method="post" action="#" id="chatSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Default <select name="chat_default" id="defaultchat">
				    <option value="all" selected>All</a>
			
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'chatSearchForm'}); 
				document.getElementById('chatPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function pageSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="pagePanel">

		<form method="post" action="#" id="pageSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Autowhen <select name="page_autowhen" id="autowhenpage">
				    <option value="all" selected>All</a>
			<option value="">
</a><option value="Daily">
Daily</a><option value="Hourly">
Hourly</a><option value="Weekly">
Weekly</a><option value="Never">Never</a>
							</select></div>
				<div class="table-list-search-form">Subwday <select name="page_subwday" id="subwdaypage">
				    <option value="all" selected>All</a>
			<option value="Friday">
Friday</a><option value="Monday">
Monday</a><option value="Saturday">
Saturday</a><option value="Thursday">
Thursday</a><option value="Tuesday">
Tuesday</a><option value="Wednesday">
Wednesday</a><option value="Sunday">Sunday</a>
							</select></div>
				<div class="table-list-search-form">Topics <select name="page_topics" id="topicspage">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Type <select name="page_type" id="typepage">
				    <option value="all" selected>All</a>
			<option value="CSS">CSS</a><option value="HTML">HTML</a><option value="JS">JS</a><option value="JSON">JSON</a><option value="mailgun">Mailgun</a><option value="RSS">RSS</a><option value="TEXT">TEXT</a><option value="XML">XML</a><option value="XSL">XSL</a><option value="email">Email</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'pageSearchForm'}); 
				document.getElementById('pagePanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function fieldSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="fieldPanel">

		<form method="post" action="#" id="fieldSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Type <select name="field_type" id="typefield">
				    <option value="all" selected>All</a>
			<option value="select">Select</a><option value="text">Text</a><option value="textarea">Textarea</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'fieldSearchForm'}); 
				document.getElementById('fieldPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function productSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="productPanel">

		<form method="post" action="#" id="productSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Category <select name="product_category" id="categoryproduct">
				    <option value="all" selected>All</a>
			<option value="3D">3D</a><option value="AR">AR</a><option value="Advertising">Advertising</a><option value="Animation">Animation</a><option value="Audio">Audio</a><option value="Blog">Blog</a><option value="Citation">Citation</a><option value="Class">Class</a><option value="Comment">Comment</a><option value="Competency">Competency</a><option value="Computer">Computer</a><option value="Content">Content</a><option value="Course">Course</a><option value="Database">Database</a><option value="Discussion">Discussion</a><option value="Employment">Employment</a><option value="Event">Event</a><option value="Feed/API">Feed/API</a><option value="File">File</a><option value="Form">Form</a><option value="Game">Game</a><option value="Identity">Identity</a><option value="Image">Image</a><option value="Journal">Journal</a><option value="Learning">Learning</a><option value="Learning Content">Learning Content</a><option value="Learning Design">Learning Design</a><option value="Learning Object">Learning Object</a><option value="Lecture">Lecture</a><option value="Message">Message</a><option value="Metadata">Metadata</a><option value="Microcontent">Microcontent</a><option value="Note">Note</a><option value="Payment">Payment</a><option value="Photo">Photo</a><option value="Portfolio">Portfolio</a><option value="Presentation">Presentation</a><option value="Project">Project</a><option value="Prototype">Prototype</a><option value="Quiz">Quiz</a><option value="Research">Research</a><option value="SEO">SEO</a><option value="School">School</a><option value="Screen">Screen</a><option value="security">Security</a><option value="Simulation">Simulation</a><option value="Social">Social</a><option value="Software">Software</a><option value="Spreadsheet">Spreadsheet</a><option value="Student">Student</a><option value="Survey">Survey</a><option value="Team">Team</a><option value="Test">Test</a><option value="Text">Text</a><option value="VR">VR</a><option value="Video">Video</a><option value="virtualization">Virtualization</a><option value="Website">Website</a><option value="Workforce">Workforce</a><option value="eBook">EBook</a><option value="eMail">EMail</a>
							</select></div>
				<div class="table-list-search-form">Genre <select name="product_genre" id="genreproduct">
				    <option value="all" selected>All</a>
			<option value="Aggregating">Aggregating</a><option value="Amplification">Amplification</a><option value="Analytics">Analytics</a><option value="Annotation">Annotation</a><option value="Assistant">Assistant</a><option value="Authoring">Authoring</a><option value="Browser">Browser</a><option value="Calendar">Calendar</a><option value="Captioning">Captioning</a><option value="Capture">Capture</a><option value="Charging">Charging</a><option value="Collaboration">Collaboration</a><option value="Communication">Communication</a><option value="Community">Community</a><option value="Converting">Converting</a><option value="Curation">Curation</a><option value="Delivery">Delivery</a><option value="Design">Design</a><option value="Discovery">Discovery</a><option value="Display">Display</a><option value="Editing">Editing</a><option value="Environment">Environment</a><option value="Exchange">Exchange</a><option value="Framework">Framework</a><option value="Gaming">Gaming</a><option value="Hosting">Hosting</a><option value="Integration">Integration</a><option value="Language">Language</a><option value="Library">Library</a><option value="Management">Management</a><option value="Marketplace">Marketplace</a><option value="Monitoring">Monitoring</a><option value="Network">Network</a><option value="Platform">Platform</a><option value="Printing">Printing</a><option value="Production">Production</a><option value="Publishing">Publishing</a><option value="Registry">Registry</a><option value="Repository">Repository</a><option value="Robotics">Robotics</a><option value="Server">Server</a><option value="Validation">Validation</a><option value="Viewer">Viewer</a><option value="Webcasting
">Webcasting</a>
							</select></div>
				<div class="table-list-search-form">Type <select name="product_type" id="typeproduct">
				    <option value="all" selected>All</a>
			<option value="app">App</a><option value="cots">Commercial Software</a><option value="documentation">Documentation</a><option value="hardware">Hardware</a><option value="Language">Language</a><option value="Network">Network</a><option value="Open Content">Open Content</a><option value="open source">Open Source Software</a><option value="service">Service</a><option value="thing">Thing</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'productSearchForm'}); 
				document.getElementById('productPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function providerSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="providerPanel">

		<form method="post" action="#" id="providerSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Default <select name="provider_default" id="defaultprovider">
				    <option value="all" selected>All</a>
			
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'providerSearchForm'}); 
				document.getElementById('providerPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function banned_sitesSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="banned_sitesPanel">

		<form method="post" action="#" id="banned_sitesSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Default <select name="banned_sites_default" id="defaultbanned_sites">
				    <option value="all" selected>All</a>
			
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'banned_sitesSearchForm'}); 
				document.getElementById('banned_sitesPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function courseSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="coursePanel">

		<form method="post" action="#" id="courseSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Default <select name="course_default" id="defaultcourse">
				    <option value="all" selected>All</a>
			
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'courseSearchForm'}); 
				document.getElementById('coursePanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function authorSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="authorPanel">

		<form method="post" action="#" id="authorSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Type <select name="author_type" id="typeauthor">
				    <option value="all" selected>All</a>
			<option value="Organization">Organization</a><option value="Person">Person</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'authorSearchForm'}); 
				document.getElementById('authorPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function postSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="postPanel">

		<form method="post" action="#" id="postSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Category <select name="post_category" id="categorypost">
				    <option value="all" selected>All</a>
			<option value="OLDaily">OLDaily</a>
							</select></div>
				<div class="table-list-search-form">Field <select name="post_field" id="fieldpost">
				    <option value="all" selected>All</a>
			<option value="Audio">
Audio</a><option value="Display">
Display</a><option value="Enclosure">
Enclosure</a><option value="Other Image">
Other Image</a><option value="Genre">Genre</a><option value="Interview">Interview</a><option value="Thumbnail">Thumbnail</a>
							</select></div>
				<div class="table-list-search-form">Genre <select name="post_genre" id="genrepost">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Language <select name="post_language" id="languagepost">
				    <option value="all" selected>All</a>
			<option value="English:French">English</a>
							</select></div>
				<div class="table-list-search-form">Section <select name="post_section" id="sectionpost">
				    <option value="all" selected>All</a>
			<option value="Blog">Blog</a><option value="Book">Book</a><option value="Events">Events</a><option value="Journal">Journal</a><option value="Magazine">Magazine</a><option value="News Media">News Media</a><option value="Other">Other</a><option value="Podcast">Podcast</a><option value="Serial">Serial</a>
							</select></div>
				<div class="table-list-search-form">Topic <select name="post_topic" id="topicpost">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Topics <select name="post_topics" id="topicspost">
				    <option value="all" selected>All</a>
			<option value="something else">Something</a>
							</select></div>
				<div class="table-list-search-form">Type <select name="post_type" id="typepost">
				    <option value="all" selected>All</a>
			<option value="announcement">Announcement</a><option value="article">Article</a><option value="comment">Comment</a><option value="course">Course</a><option value="link">Link</a><option value="musing">Musing</a><option value="preview">Preview</a><option value="shownotes">Shownotes</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'postSearchForm'}); 
				document.getElementById('postPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function conceptSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="conceptPanel">

		<form method="post" action="#" id="conceptSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Category <select name="concept_category" id="categoryconcept">
				    <option value="all" selected>All</a>
			<option value="Algorithm">Algorithm</a><option value="concept">Concept</a><option value="Curriculum">Curriculum</a><option value="License">License</a><option value="model">Model</a><option value="standard">Standard or specification</a><option value="theory">Theory</a><option value="type">Type</a>
							</select></div>
				<div class="table-list-search-form">Genre <select name="concept_genre" id="genreconcept">
				    <option value="all" selected>All</a>
			<option value="commerce">Business and commerce</a><option value="education">Education</a><option value="general">General</a><option value="philosophy">Philosophy</a><option value="political">Political</a><option value="technology">Technology</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'conceptSearchForm'}); 
				document.getElementById('conceptPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function viewSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="viewPanel">

		<form method="post" action="#" id="viewSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Default <select name="view_default" id="defaultview">
				    <option value="all" selected>All</a>
			
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'viewSearchForm'}); 
				document.getElementById('viewPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	
	function publicationSearchTemplate(request) {	
		return `<button class="accordion" onClick="togglePanel(this.nextElementSibling);">Filter ${request.table}</button>
		<div class="panel" id="publicationPanel">

		<form method="post" action="#" id="publicationSearchForm">
		<input type="hidden" name="div" value="${request.div}">
		<input type="hidden" name="cmd" value="${request.cmd}">
		<input type="hidden" name="table" value="${request.table}">		
		
				<div class="table-list-search-form">Catdetails <select name="publication_catdetails" id="catdetailspublication">
				    <option value="all" selected>All</a>
			<option value=" "> </a><option value="Refereed">Refereed</a><option value="Unrefereed">Unrefereed</a>
							</select></div>
				<div class="table-list-search-form">Category <select name="publication_category" id="categorypublication">
				    <option value="all" selected>All</a>
			<option value=""></a><option value="Application">Application</a><option value="Article">Article</a><option value="Chapter">Chapter</a><option value="Column">Column</a><option value="Grant">Grant</a><option value="Report">Report</a>
							</select></div>
				<div class="table-list-search-form">Type <select name="publication_type" id="typepublication">
				    <option value="all" selected>All</a>
			<option value=""></a><option value="Book">Book</a><option value="Funding">Funding</a><option value="Internal">Internal</a><option value="Journal">Journal</a><option value="Magazine">Magazine</a><option value="Newspaper">Newspaper</a><option value="Patent">Patent</a><option value="Research">Research</a>
							</select></div>
		<div class="table-list-search-form">
		<select name="qkey">
		<option value="id"> ID</option>
		<option value="title"> Title </option>
		<option value="description"> Description </option>
		<option value="link"> Link </option>
		</select>
		<input type="text" name="qval" placeholder="search term" class="text-input-field"></div>
		<div class="table-list-search-form">
		<input type="button" value="Submit" 
			onClick="
				$('.list-result').remove();
				loadDataFromForm({div:'${request.div}',cmd:'${request.cmd}',table:'${request.table}',formid:'publicationSearchForm'}); 
				document.getElementById('publicationPanel').style.display = 'none';
				return false;
			"></div>
			</div>`;
	};

	