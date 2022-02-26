#
#	en.pl
#
#	gRSShopper Language Pack for English
#
#	Stephen Downes
#	21:00 01/01/2014
#

# completed to end of permissions - line 1270 in grsshopper.pl
# done all of login.cgi except for google and openid login functions

$Site->{en} = {
	
	'Meetings' => "<h2>Meetings</h2><p>This is the gRSShopper interface to Big Blue Button. If there is no instance of BBB available, this section will not be usable.</p>",
	'General Information' => "<h2>General Information</h2><p>These values control site filenames and directories. Changing them can render gRSShopper inoperable. Exercise caution and do not make changes unless you are sure you know what the result will be.</p>",
       

	# Viewer
        'Viewer' => 'Viewer',
        'It distresses me to say there was nothing found.' => 'It distresses me to say there was nothing found.',
        'Comments' => 'Comments',
        'S U B M I T' => 'S U B M I T',
        'All Sections' => 'All Sections',
        'Any Status' => 'Any Status',
        'All Feeds' => 'All Feeds',
        'All Topics' => 'All Topics',
        'None' => 'None',
        'All Genres' => 'All Genres',
        'Displaying resource number' => 'Displaying resource number',
        'of' => 'of',   
        'Status' => 'Status',
        'Tag' => 'Tag',
        'POST' => 'POST',
        'EDIT' => 'EDIT',
        'Post Comment' => 'Post Comment',
        'Fresh' => 'Fresh',
        'Stale' => 'Stale',
        'Posted' => 'Posted',

	
	# Execution  -  get_site()  -  get_person()
	
	'Run OK' => "#1 run successfully",
	'Error' => "Error",
	'click here' => "click here",
	'Click here' => "Click here",
	'Cron Error' => "Cron Error in #1",
	'Cron key mismatch' => "Error: Cron key mismatch. #1 must match the value of the cronkey set in #2 admin \n",
	'No Person Info' => "No Person Info",
	'Site info not found' => "Site information not found in #1",
	'Not found' => "#1 not found",
	'Cannot find' => "<p>Cannot find #1 for #2: #3</p>",
	'Cannot create directory' => "Cannot create directory #1 in #2: #3",

	# Permissions
	
	'Must be admin' => "You must be logged in as admin.",
	'Must be registered' => "You must be logged in as a registered user to do this.",
	'Permission denied' => "Permission Denied. You must #1 to be allowed to #2 #3s #4",
	'Permission denied to view' => "[Permision denied to view #1]",


	# Database Messages
	# #1 = function, #2 = error message from $sth->errstr(), #3 = SQL statement being executed

	'Database not initialized' => "Database not initialized",
	'Required in' => "A value for #1 is required in #2 but was not found",
	'Cannot prepare SQL' => "Cannot prepare SQL statement in #1: #2<br>#3",
	'Cannot execute SQL' => "Cannot execute SQL statement in #1: #2<br>#3",
	'No box recursion' => "Cannot use the same box twice, to avoid recursion.",
	
	# Admin Links   - admin_links()
		
	'Analyze' => "Analyze",
	'Harvest' => "Harvest",		
	'Publish' => "Publish",
	'Approve' => "Approve",		
	'Retire' => "Retire",
	'Delete' => "Delete",
	'Spam' => "Spam",
	'Edit' => "Edit",
	'Previous' => "Previous",
	'Next' => "Next",
	

	# Page content   - format_content()
	
	'No content' => "This page has no content.",
	'No description' => "This page has no description.",
	'Untitled' => "Untitled",
	'Site Title'=> "Site Title",

	# Comment Form   - make_comment_form()
	
	'Enter Email for Replies' => "Enter email to receive replies:",
	'Check Box for Replies' => "Check the box to receive email replies:",	
	'Your email' => "Your email:",
	'Your Comment' => "Your Comment",
	'Preview until satisfied' => "You can preview your comment and continue editing until you are satisfied with it.",
	'Not posted until done' => "Comment will not be posted on the #1 until you have clicked 'Done'.",
	'Preview' => "Preview",
	'Done' => "Done",
        'comment_disclaimer' => "en_comment_disclaimer",                             				# Refers to a box named 'en_comment_disclaimer'  

	
	# Autopost
	
	'Link error' => "Link error - #1 not found",
	
	# Initialize (to be done)
	

	# Big Blue Button (to be done)
	
	



	# Templates
	'Template file not found' => "Template file #1 not found",
	'admin_header' => "admin_header",					# requires an entry in the Template table with the title 'admin_header'
	'admin_footer' => "admin_footer",	
	'page_header' => "page_header",					
	'page_footer' => "page_footer",	
	'email_header' => "email_header",					
	'email_footer' => "email_footer",	
	'section_header' => "section_header",					
	'section_footer' => "section_footer",	
	'rss_header' => "rss_header",					
	'rss_footer' => "rss_footer",	
	'json_header' => "json_header",					
	'json_footer' => "json_footer",	

		
	# Login and Registration   


	# Anonymous Options   - anon_options()
	'Anon Message' => "Welcome to #1 You are using this site anonymously and will be identified as 'Anymouse' if you choose to post comments. <br/><br/>If you wish to sign your name to comments or to receive a newsletter by email, you will need to login or register.",
	'Anon Login' => "<a href='#1'>Login</a> if you already have a UserID",
	'Anon Register' => "<a href='#1'>Register</a> if you don't",	

	# Login Form    -   login_form_text  -  login_form_input()

 	'Login' => "Login",
        'Login Google' => "log in using your Google ID",
        'Login OpenID' => "log in using OpenID",    
        'Or login with' => "or login with",        
	'Remember me' => "Remember me",
        'Forgot password' => "Forgot your password?",	
        'Create account' => "Create a new account",
        'Missing credentials' => "Missing credentials: either enter your user name and password, or ",     
        'User name not found' => "User name not found.",    
        'Unknown error' => "Unknown error (seriously, this shouldn't happen)",             

	# Registration Form  - registration_form_text()

	'Enter your name' => "Please choose user name or enter your email address",
        'Enter your password' => "Enter your password",	
        'Enter your email' => "Enter your email address",  
        'Register and subscribe' => "Registration and newsletter subscription",
	'You Agree' => "By logging in you agree to allow this site to set three cookies on your browser: the login name you enter below, an ID number corresponding to that name, and a session variable, used to prevent fake logins, that changes each time you login.",              
        'How found' => "(Optional) How did you find out about this site?",    
        'Enter capcha text' => "Enter the text that appears on the image", 
        'Site not open' => "This site is not accepting new registrations at the moment.",  

	# Logout
	
        'Logout successful' => "D&eacute;connexion r&eacute;ussie", 

	# Set up new user -   new_user(), user_are_go()    ("Thunderbirds are go!")

        'Registration error' => "Registration Error",
        'You must provide' => "You must provide your name, email address and a password.",
        'Captcha table not found' => "Captcha table not found.",
        'Incorrect Captcha' => "Incorrect Captcha",
        'Bad email' => "Improperly formed email address",
        'Someone using' => "Someone else is using this email address. If this is your email address, ",
        'Someone named' => "Someone else named #1 has already registered. If this is your user name, ",
        'Spam registration' => "Spam registration detected.",
        'No new account' => "Database error. No new account was created. Please try again.",
        'Welcome to' => "Welcome to #1",
        'welcome message' => "en_welcome_message",                             				# Refers to a box named 'en_welcome_message'    
        'New User Registration' => "New User Registration",
        'Remove user' => "Remove this user?",    

	'Setting session' => "Setting session ID for Person #1",
        'Login successful' => "Login successful",	
	
	# D2L Login   -   d2l_remote_login()
	
	'Return to D2L' => "Return to D2L website - <a href='#1'>Click here</a>",
	
	


	# Navigation


	
	# Navigation Options  -  print_nav_options()
        'Site Administration' => "Site Administration",
        'Associate with Google ID' => "Associate your account with a Google OpenID",
	'Associate with OpenID' => "Associate your #1 account with an OpenID",
        'Options and Personal Info' => "Modify your personal information and options",     
        'Go Back' => "Go back to where you were",    
        'Site Home Page' => "#1 Home Page",      
        'Newsletter subscriptions' => "Manage your newsletter subscriptions",   
        'Change password' => "Change your password",   
        'Login as another user' => "Login as another user",         
	'Logout' => "Logout",                         

	# D2L Nav  -   d2l_nav()
	'D2L error name' => "Fatal error, first and last name not found on D2L redirect",
	'D2L error email' => "Fatal error, email address not found on D2L redirect",
	


	# User Info Management
	

	# Options -  options()
	
        'Your Private Page' => "This is <i>your</i> private page. If you want to see how the public sees you, ",  
	'Options' => "Here are your Options", 
	'Welcome' => "Welcome",
 
        'Personal Information' => "Personal Information",	
	'Userid' => "UserID",
	'Password' => "Password",	
        'Edit Info' => "Change your email address and personal information",
        
        'Social networks' => "Social networks",	
        'Edit social networks' => "Edit social networks",
        
        'Blogs and RSS' => "Blogs and RSS Feeds",
        'View' => "View",
	'Pending Approval' => "Pending Approval",
 	'Approved' => "Approved",
	'Retired' => "Retired",         
        'Add a new feed' => "Add a new feed",
        
        'Newsletter Subscriptions' => "Newsletter Subscriptions",
        'Read' => "Read",
        'Modify Subscriptions' => "Modify newsletter subscriptions",

        'OpenID not supported' => "Open ID is not supported on this site.",
        

	# Edit Personal Information   - edit_info() - edit_info_input()

	'Change Email and Personal Info' => "Change Email and Personal Information",   
	'Could not find person' => "Could not find #1 in my database.",	
	'Cannot edit anon' => "Cannot edit anonymous account",
	'Not authorized' => "You are not authorized to edit this account.",
        'User name' => "Nom d’utilisateur: ",	
	'Name' => "Name",
	'Email' => "Email",        
	'Home Page' => "Home Page",
	'RSS Feed' => "Flux RSS",	
	'Organization' => "Organization",
	'City' => "City",		
	'Country' => "Country",
	'Change photo' => "Change photo", 	
        'Photo' => "Photo", 
	'Update Information' => "Update your personal information",        
	'Personal data updated' => "Your personal data has been updated.",


	# Manage Photo  -  manage_photo()
	
	'Error creating upload directory ' => "Error creating upload directory: #1<br>#2: #3",


	# Remove User
	'User Deleted' => "User Deleted",
	'Has been deleted' => "User number #1 has been deleted.",
	
	

	# Subscription Management

	
	# Subscription form   -  subscribe()   -  subscription_form_text()	
	
	'Manage Subscriptions' => "Manage Subscriptions",
	'Displaying subscriptions' => "Displaying subscriptions for #1",
	'No subscriptions' => "No subscriptions for anonymous users", 
        'Subscribe newsletter' => "Subscribe to newsletters (you may choose more than one; leave blank for none)",
	'Update Subscriptions' => "Update Subscriptions",  

	# Add subscription    -    add_subscription()	
	
	'No ID number' => "No ID number provided for subscription",
	'No longer subscribed' => "No longer subscribed to anything",
	'Subscription failed' => "For some unknown reason your subscription failed. Please try again later.",
	'Subscriptions have been updated' => "Subscriptions have been updated",

	# Unsubscribe   -   unsubscribe()
	
	'Unsubscribe' => "Unsubscribe from #1",
	'Unsubscribe user not found' => "Looking for #1 #2 <br/><br/>User not found, cannot unsubscribe.<br/><br/>If this is a partial email address, please cut and paste the entire unsubscribe URL from the email newsletter to the address bar.",
	'Subscription not found' => "The person has been found, but the subscription to #1 has not been found",
	'Subscription cancelled' => "Your email subscription has been cancelled.<br/>Email: #1 <br/>If you wish to restart it any time in the future, return to your <a href='#2'>options page</a> to resubscribe.",


	# Password Management

	
	# Check Password  -  password_check()
	
	'Login error' => "Login Error",
        'Incorrect password' => "Incorrect password.",
        'Recover registration' => "<a href='#1'>Click here</a> to recover your login inormation.", 

	# Password Reset   - email_password()   -  send_password()  -  reset_password()
	
	'Password reset' => "Password reset for #1",	
	'Reset instructions' => "To reset your password, enter your email address, your User ID, or your name:",
	'Enter something' => "Please enter <i>something</i>!",
	'Person not found' => "Could not find any person matching #1",
	'Could not find email' => "Could not find your email address",
	'To reset your password' => "To reset your password from #1",
	'Reset message' => "<p>To reset your password from #1 go to the following URL  <br><br>#2</p>",
	'Sent reset URL' => "We have sent you a reset URL. To reset your password, please check your email inbox.",
	'Password has been reset' => "Your #1 password has been reset",
	'Has been reset' => "<p><b>Your password has been reset</b>:<br><br>Userid: #1<br>Password: #2</p>",
	'Password emailed' => "Your password has been reset. Please check your email inbox.<br/><br/><a href='#1'>Click here to login</a> with your new password.",
	'Blank midm' => "Blank midm",
	'Reset key expired' => "Reset key expired",
	'Key mismatch' => "Key mismatch",		

	# Change Password  - change_password_screen()  -  change_password_input()   

	'Old Password' => "Old Password",
	'New Password' => "New Password",
	'New Password (Again)' => "New Password (Again)",
	'Change Password' => "Change Password",
	'Password Change Error' => "Password Change Error",
	'Incorrect old' => "Attempting to change password: incorrect old password",
	'New password blank' => "New password is blank",
	'New password match' => "New passwords do not match",
	'Password changed' => "Your password has been changed.",
	'New password login' => "Click here to login with your new password",


	# Edit Social Networks - form_socialnet() 
	
        'Social network instructions' => "Use this form to edit your social network information. We will be able to use	this information to help you post from the #1 site to your social network, and to associate posts we havest from these social networks with your #2 identity.<br/><br/>Please note that providing this information is <i>optional</i>. Also, your social network identity will not be displayed to the public unless you have checked the 'public' box for that social network name.",
	'Network' => "Network",
	'Your ID' => "Your ID",
	'Public?' => "Public?",
	'Update Social Network Information' => "Update Social Network Information",	

	
	# Submit stuff - receive() 	
	
	'Feed' => "Feed",'feed' => "feed",
	'Dear' => "Dear",
	'Automatic approval' => "Your #1 has been submitted and automatically approved.",
	'New submitted approval needed' => "A new #1 has been submitted by a #2 reader #3. In this email you may review the #1 submission and either approve it or reject it.",
	'New submitted' => "New #1 (#2) submitted on #3",
	'Back to the Home Page' => "Back to the Home Page",
        'Your item has been submitted' => "Your #1 has been submitted",
	'Has been submitted' => "Your #1 has been submitted and will be reviewed by #2 website editors. Thank you for your submission.",
	'Check feed status' => "To check the status of your feed, <a href='#1'>click here</a>",
	
	# Preview
	'Start' => "Start",
	'Preview' => "Preview",
	'Continue editing' => "You can continue editing using the form below the preview (scroll down)",
	
	# Deleting
	'Record no longer exists' => "Record no longer exists",		
	'Sender banned' => "The sender #1 has been identified as a spammer and added to the list of banned sites.<br>",
	'Record id deleted' => "Record #1 deleted.<br/>#2",
	'Deleted record' => "Deleted record #1.",
	'Table id deleted' => "#1 (#2) deleted by #3",


       # Date 

	'N/A' => 'N/A',
		
	'Sun' => "Sun",
	'Mon' => "Mon",
	'Tue' => "Tue",
	'Wed' => "Wed",
	'Thu' => "Thu",
	'Fri' => "Fri",
	'Sat' => "Sat",
	
	'Sunday' => "Sunday",
	'Monday' => "Monday",
	'Tuesday' => "Tuesday",
	'Wednesday' => "Wednesday",
	'Thursday' => "Thursday",
	'Friday' => "Friday",
	'Saturday' => "Saturday",

	'Jan' => "Jan",
	'Feb' => "Feb",
	'Mar' => "Mar",
	'Apr' => "Apr",
	'May' => "May",
	'Jun' => "Jun",
	'Jul' => "Jul",
	'Aug' => "Aug",
	'Sep' => "Sep",
	'Sept' => "Sept",
	'Oct' => "Oct",
	'Nov' => "Nov",
	'Dec' => "Dec",

	'January' => "January",
	'February' => "February",
	'March' => "March",
	'April' => "April",
	'May' => "May",
	'June' => "June",
	'July' => "July",
	'August' => "August",
	'September' => "September",
	'October' => "October",
	'November' => "November",
	'December' => "December",

	'' => "",
	'' => "",
	'' => "",
	'' => "",
	'' => "",
	'' => "",
	'' => "",
	'' => "",
	'' => "",
	'' => "",
	'' => "",
	'' => ""
	};
	
