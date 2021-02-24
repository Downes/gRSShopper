#

#	en.pl

#

#	gRSShopper Language Pack for French

#

#	Stephen Downes

#	21:00 01/01/2014

#







$Site->{fr} = {



	'Meetings' => "<h2>R&eacute;unions</h2><p>This is the gRSShopper interface to Big Blue Button. If there is no instance of BBB available, this section will not be usable.</p>",
	'General Information' => "<h2>Information G&eacute;n&eacute;rale</h2><p>These values control site filenames and directories. Changing them can render gRSShopper inoperable. Exercise caution and do not make changes unless you are sure you know what the result will be.</p>",


	# Viewer
        'Viewer' => 'Parcourir',
	'It distresses me to say there was nothing found.' => 'Rien &arave; &eacute;t&eacute; trouv&eacute;.',
	'Comments' => 'Commentaires',	
	'S U B M I T' => 'S O U M E T T R E',
	'All Sections' => 'Toutes les sections',
	'Any Status' => 'Tous les &eacute;tat',
	'All Feeds' => 'Tous les flux',
	'All Topics' => 'Tous les sujets',
	'None' => 'Auncun',
	'All Genres' => 'Tous les genres',
	'Displaying resource number' => 'Resource',
	'of' => 'de',
	'Status' => '&Eacute;tat',
	'Tag' => 'Mot-di&egrave;se',
	'POST' => 'PUBLIER',
	'EDIT' => '&Eacute;DITER',
	'Post Comment' => 'Commenter',
	'Fresh' => 'Frais',
	'Stale' => '&Eacute;vent&eacute;',
	'Posted' => 'Affect&eacute;',
	

	# Execution  -  get_site()  -  get_person()
	
	'Run OK' => "#1 fonctionne correctement",
	'Error' => "Erreur",
	'Click here' => "Cliquez ici",	
	'click here' => "cliquez ici",	
	'Cron Error' => "Erreur Cron en #1",
	'Cron key mismatch' => "Erreur: Cron cl&eacute; d&eacute;calage. #1 doit correspondre &agrave; la valeur de la cronkey mis en #2 administrateur\n",
	'No Person Info' => "Aucune personne de vente",
	'Site info not found' => "Les informations sur le site ne se trouvent pas dans #1",	
	'Not found' => "#1 introuvable",
	'Cannot find' => "<p>Je ne peux pas trouver «#1» pour #2: #3</p>",	
	'Cannot create directory' => "Je ne peux pas cr&eacute;er le r&eacute;pertoire #1 &agrave; #2: #3",	
	
	

	# Permissions
	
	'Must be admin' => "Les champs nom, adresse courriel et mot de passe sont obligatoires.",
	'Must be registered' => "Vous devez &ecirc;tre identifi&eacute; en tant que membre pour ce faire.",	
	'Permission denied' => "Autorisation refus&eacute;e. Vous devez #1 &agrave; &ecirc;tre autoris&eacute; &agrave; #2 #3s #4",	
	'Permission denied to view' => "[Autorisation refus&eacute;e &agrave; voir #1]",	
	
	# Database Messages
	# #1 = function, #2 = error message from $sth->errstr(), #3 = SQL statement being executed


	'Database not initialized' => "Base de donn&eacute;es non initialis&eacute;e",
	'Required in' => "Une valeur pour #1 est exig&eacute;e &agrave; #2, mais n'a pas &eacute;t&eacute; trouv&eacute;",		
	'Cannot prepare SQL' => "Vous ne pouvez pas pr&eacute;parer instruction SQL dans #1: #2<br>#3",
	'Cannot execute SQL' => "Vous ne pouvez pas ex&eacute;cuter l'instruction SQL dans #1: #2<br>#3",
	'No box recursion' => "Je ne peux pas utiliser la m&ecirc;me bo&icirc;te deux fois, pour &eacute;viter la r&eacute;currence.",	

	
	# Admin Links   - admin_links()
		
	'Analyze' => "Analyser",
	'Harvest' => "R&eacute;colter",
	'Approve' => "Approuver",	
	'Publish' => "Publier",
	'Retire' => "Reculer",
	'Delete' => "Effacer",
	'Spam' => "Spam",
	'Edit' => "Modifier",
	'Previous' => "Pr&eacute;c&eacute;dent",
	'Next' => "Suivant",	

	# Page content   - format_content()
	
	'No content' => "Cette page n'a pas de contenu.",
	'No description' => "Cette page n'a pas de description.",
	'Untitled' => "Pas de titre",
	'Site Title'=> "Titre du site",

	# Comment Form  - make_comment_form()
	
	'Enter Email for Replies' => "Entrez une adresse pour recevoir des r&eacute;ponses:",	
	'Check Box for Replies' => "Cochez la case pour recevoir les r&eacute;ponses par courriel:",
	'Your email' => "Votre courriel:",
	'Your Comment' => "Votre commentaire",
	'Preview until satisfied' => "Vous pouvez pr&eacute;visualiser votre commentaire et continuer l'&eacute;dition jusqu'&agrave; ce que vous soyez satisfait.",	
	'Not posted until done' => "Le commentaire ne sera pas affich&eacute; sur le site #1 jusqu'&agrave; avant que vous ayez cliqu&eacute; sur «D'accord!».",
	'Preview' => "Aper&ccedil;u",
	'Done' => "D'accord!",		
        'comment_disclaimer' => "fr_comment_disclaimer",                             				# Refers to a box named 'fr_comment_disclaimer' 	


	
	# Autopost
	
	'Link error' => "Erreur de lien - #1 introuvable",
	
	
	# Initialize (to be done)
	

	# Big Blue Button (to be done)
	
	

	
	# Templates
	'Template file not found' => "Fichier de modèle #1 introuvable",	
	'admin_header' => "fr_admin_header",					# requires an entry in the Template table with the title 'fr_admin_header'
	'admin_footer' => "fr_admin_footer",					# etc., otherwise will fail silently to the 'admin_header' template
	'page_header' => "fr_page_header",					
	'page_footer' => "fr_page_footer",
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
	
	'Anon Message' => "Bienvenue &agrave; #1. Si vous utilisez ce site de façon anonyme vous serez alors identifi&eacute;s comme Anymouse si vous choisissez de poster des commentaires. <br/>Si vous souhaitez que votre votre nom apparaisse dans les commentaires ou recevoir un bulletin d'information par e-mail, vous devez vous connecter ou vous inscrire.",
	'Anon Login' => "<a href='#1'>Connexion</a> si vous avez d&eacute;j&agrave; un nom d'utilisateur",
	'Anon Register' => "<a href='#1'>Inscrivez</a> si vous n'en n'avez pas",	
	
	# Login Form

	'Login' => "Connexion",
        'Login Google' => "Se connecter en utilisant un identifiant Google", 
        'Login OpenID' => "Se connecter en utilisant un identifiant OpenID",  
      
        'Or login with' => "ou connexion avec",              
        'Remember me' => "Se souvenir de moi",   
        'Create account' => "Cr&eacute;er un compte",
        'Forgot password' => "Oubli&eacute; votre mot de passe?",    
        'Missing credentials' => "Droits insuffisants: saisissez votre nom d'utilisateur et mot de passe, ou",  
        'User name not found' => "Nom d'utilisateur introuvable.",    
        'Unknown error' => "Erreur inconnue (s&eacute;rieusement, cela ne devrait pas arriver)",                 

	# Registration Form
        
        'Enter your name' => "Veuillez entrer votre nom d'utilisateur ou votre adresse courriel",	
        'Enter your password' => "Entrer votre mot de passe",  
        'Enter your email' => "Entrer votre courriel",   
        'Register and subscribe' => "Inscription et abonnement au bulletin de nouvelles",   
	'You Agree' => "En vous connectant, vous acceptez que ce site sauvegarde trois t&eacute;moins (cookies) dans votre navigateur : le nom de connexion que vous entrerez ci-dessous, un num&eacute;ro d'identification correspondant &agrave; ce nom, et une variable de session servant &agrave; pr&eacute;venir les fausses connexions (cette variable de session change &agrave; chaque fois que vous vous connectez).",                       
        'How found' => "(Optionel) Comment avez-vous pris connaissance de cette initiative?",     
        'Captcha table not found' => "Ne trouve pas la table captcha",     
        'Enter capcha text' => "Saisissez le texte qui appara&icirc;t dans l'image",     
        'Site not open' => "Ce site n'est pas actuellement ouvert &agrave; de nouvelles inscriptions.",        
                
	# Logout
	
        'Logout successful' => "D&eacute;connexion r&eacute;ussie", 

	# Set up new user -   user_are_go()    ("Thunderbirds are go!")
	
	'Registration Error' => "Erreur d'enregistrement",
        'You must provide' => "Vous devez fournir votre nom, votre adresse e-mail et un mot de passe.",
        'Captcha table not found' => "La table de code n'a pas &eacute;t&eacute; trouv&eacute;e.",        
        'Incorrect Captcha' => "Captcha incorrect",
        'Bad email' => "Veuillez indiquer une adresse courriel valide.",
        'Someone using' => "Quelqu'un d'autre utilise cette adresse e-mail. Si cela est votre adresse e-mail, ",  
        'Someone using2' => "D&eacute;sol&eacute;! Cette adresse courriel existe d&eacute;j&agrave; dans notre base de donn&eacute;es. Utilisez une autre adresse.",
        'Someone named' => "Quelqu'un d'autre nomm&eacute; #1 est d&eacute;j&agrave; enregistr&eacute;. Si cela est votre nom d'utilisateur, ",  
        'Someone named2' => "Le nom indiqu&eacute; existe d&eacute;j&agrave; dans notre base de donn&eacute;es. SVP, entrez un autre nom.",
        'Spam registration' => "Quelque chose d'anormal a &eacute;t&eacute; d&eacute;tect&eacute;. Essayez de nouveau.",  
        'No new account' => "D&eacute;sol&eacute;, une erreur s'est produite. Essayez de nouveau.",     
	'Welcome to' => "Bienvenue &agrave; #1",
        'welcome message' => "fr_message de bienvenue",                             				# Refers to a box named 'en_welcome_message'   
        'New User Registration' => "Enregistrement d'un nouvel utilisateur",
        'Remove user' => "Supprimer cet utilisateur?",      

	'Setting session' => "R&eacute;glage de l'ID de session pour la personne #1",
        'Login successful' => "Connexion r&eacute;ussie",	

	# Navigation

	# Navigation Options  -  print_nav_options()
        'Site Administration' => "Administration",
        'Associate with Google ID' => "Associez votre compte avec Google OpenID",  
	'Associate with OpenID' => "Associer une identit&eacute; libre (OpenID) &agrave; votre compte #1",        
        'Options and Personal Info' => "Modifier vos informations personnelles et vos options",
        'Go Back' => "Retour",      
        'Site Home Page' => "#1 Page d'accueil",   
        'Newsletter subscriptions' => "Inscription et abonnement au bulletin de nouvelles",   
        'Change password' => "Changer votre mot de passe",    
        'Login as another user' => "Se connecter avec un nom d'utilisateur diff&eacute;rent",        
	'Logout' => "D&eacute;connexion",                             

	# D2L Nav  -   d2l_nav()
	'D2L error name' => "Erreur fatale, pr&eacute;nom et nom pas trouv&eacute; lors que D2L a redirig&eacute;",
	'D2L error email' => "Erreur fatale, adresse courriel introuvable lors que D2L rediriger",	
	'Return to D2L' => "Retour au site D2L - <a href='#1'>Cliquez ici</ a>",
	
	
	# User Info Management
		

	# Options -  options()
	
        'Your Private Page' => "Ceci est <i>votre</i> page personelle. Pour voir comment le public vous voit, ",
        'Options' => "Voici vos options", 
	'Welcome' => "Bienvenue",
	
        'Personal Information' => "Information personnelle",	
	'Userid' => "Nom d'utilisateur",	
	'Password' => "Mot de Passe",	
	'Edit Info' => "Changer votre courriel et vos informations personnelles",    
	
        'Social networks' => "R&eacute;seaux sociaux",          
        'Edit social networks' => "Modifier les  r&eacute;seaux sociaux",

        'Newsletter Subscriptions' => "Abonnement au bulletin de nouvelles",
        'Modify Subscriptions' => "Modifier l'abonnement au bulletin de nouvelles",
        'Read' => "Lire",

        'Blogs and RSS' => "Blogues et flux RSS",
        'View' => "Afficher",  
        'Pending Approval' => "En attente d'approbation",
 	'Approved' => "Approuv&eacute;",
	'Retired' => "&Eacute;limin&eacute;",        
        'Add a new feed' => "Ajouter un nouveau flux",

        'OpenID not supported' => "Open ID is not supported on this site.",
	
	# Edit Personal Information   - edit_info() - edit_info_input()

	'Change Email and Personal Info' => "Modifier votre adresse courriel et vos informations personnelles", 
	'Cannot edit anon' => "Vous ne pouvez pas modifier compte anonyme",
	'Not authorized' => "Vous n'&ecirc;tes pas autoris&eacute; &agrave; modifier ce compte.",	
        'User name' => "Nom d'utilisateur: ",
	'Name' => "Nom",
	'Email' => "Courriel",        	
	'Home Page' => "Page d'accueil",
	'RSS Feed' => "Flux RSS",	
	'Organization' => "Organisation",
	'City' => "Ville",		
	'Country' => "Pays",
        'Photo' => "Photo", 
	'Change photo' => "Changer de photo",       
	'Update Information' => "Mettre votre information &agrave; jour",	 
	'Personal data updated' => "Vos donn&eacute;es personnelles ont &eacute;t&eacute; mises &agrave; jour.",
	'Person OpenID' => "OpenID",

	# Manage Photo  -  manage_photo()
	
	'Error creating upload directory ' => "Erreur lors de la cr&eacute;ation du r&eacute;pertoire: #1<br>#2: #3",

	# Remove User
	'User Deleted' => "Utilisateur Supprim&eacute;",
	'Has been deleted' => "L'utilisateur numero #1 a &eacute;t&eacute; supprim&eacute;.",	
	
	

	# Subscription Management

	
	
	# Subscription form   - subscribe()   -  subscription_form_text()
	
	'Manage Subscriptions' => "G&eacute;rer les abonnements",
	'Displaying subscriptions' => "Affichez abonnements pour #1",
        'No subscriptions' => "Pas d'abonnement pour les utilisateurs anonymes",  
        'Subscribe newsletter' => "Abonnez-vous au bulletin de nouvelles",
	'Update Subscriptions' => "Mettre &agrave; jour",  	


	# Add subscription    -    add_subscription()
	
	'No ID number' => "Pas de num&eacute;ro d'identification pr&eacute;vu &agrave; l'abonnement",	
	'No longer subscribed' => "N'est plus abonn&eacute;(e) &agrave; rien.",	
	'Subscription failed' => "Pour une raison inconnue votre abonnement a &eacute;chou&eacute;. S'il vous pla&icirc;t r&eacute;essayer plus tard.",
	'Subscriptions have been updated' => "Les abonnements ont &eacute;t&eacute; mis &agrave; jour",


	# Unsubscribe

	'Unsubscribe' => "Vous d&eacute;sabonner de #1",
	'Unsubscribe user not found' => "Recherche de #1 #2 <br/><br/>L'utilisateur est introuvable et ne peut donc pas &ecirc;tre d&eacute;sinscrit. <br/><br/>S'il s'agit d'un courriel, s'il vous pla&icirc;t copier et coller l'ensemble de l'URL de d&eacute;sabonnement de la newsletter dans la barre d'adresse de votre navigateur.",
	'Subscription not found' => "La personne a &eacute;t&eacute; trouv&eacute;, mais l'abonnement au #1 n'a pas &eacute;t&eacute; trouv&eacute;",
	'Subscription cancelled' => "Votre courriel d'abonnement a &eacute;t&eacute; annul&eacute; <br/> Email:. # 1 <br/>Si vous souhaitez recommencer votre abonnement dans l'avenir, revenir &agrave; votre <a href='#2'>page d'options</a> pour vous r&eacute;abonner.",
	


	# Password Management

	
	# Check Password  -  password_check()
	
        'Login error' => "Erreur de connexion",
        'Incorrect password' => "Mot de passe incorrect.",
        'Recover registration' => "<a href='#1'>Cliquez ici</ a> pour retrouver vos informations de connexion",	


	# Password Reset   - email_password()   -  send_password()  -  reset_password()
	
	'Password reset' => "R&eacute;initialisation du mot de passe pour #1",	
	'Reset instructions' => "Pour r&eacute;initialiser votre mot de passe, entrez votre adresse e-mail, votre nom d'utilisateur ou votre nom:",	
	'Enter something' => "Merci de soumettre quelque chose",
	'Person not found' => "Impossible de trouver une personne correspondant &agrave; #1",	
	'Could not find email' => "Impossible de trouver votre adresse e-mail",
	'Could not find person' => "Impossible de trouver #1 dans ma base de donn&eacute;es.",	
	'To reset your password' => "Pour r&eacute;initialiser votre mot de passe pour #1",
	'Reset message' => "<p>Pour r&eacute;initialiser votre mot de passe pour #1 aller &agrave; l'URL suivante<br><br>#2</p>",	
	'Sent reset URL' => "Nous vous avons envoy&eacute; un URL de r&eacute;initialisation. Pour r&eacute;initialiser votre mot de passe, s'il vous pla&icirc;t regardez dans votre bo&icirc;te e-mail.",	
	'Password has been reset' => "Votre mot de passe pour #1 a &eacute;t&eacute; r&eacute;initialis&eacute;",
	'Has been reset' => "<p><b>Votre mot de passe a &eacute;t&eacute; r&eacute;initialis&eacute;</ b>: <br> Identifiant: #1 <br> Mot de passe: #2</p>",
	'Password emailed' => "Votre mot de passe a &eacute;t&eacute; r&eacute;initialis&eacute;. Vous pouvez le trouver dans votre bo&icirc;te e-mail.<br/><a href='#1'>Cliquez ici pour vous connecter</ a> avec votre nouveau mot de passe.",
	'Blank midm' => "Midm vide",
	'Reset key expired' => "La cl&eacute; a expir&eacute;",
	'Key mismatch' => "Incompatibilit&eacute; de cl&eacute;",	


	# Change Password  - change_password_screen()  -  change_password_input()   

	'Old Password' => "Ancien mot de passe",
	'New Password' => "Nouveau mot de passe",
	'New Password (Again)' => "Nouveau mot de passe (encore)",
	'Change Password' => "Changer le mot de passe",
	'Password Change Error' => "Erreur lors du changement du mot de passe",
	'Incorrect old' => "Tentative de modification du mot de passe: ancien mot de passe incorrect",
	'New password blank' => "Le nouveau mot de passe est vide",
	'New password match' => "Les nouveaux mots de passe ne correspondent pas",
	'Password changed' => "Votre mot de passe a &eacute;t&eacute; chang&eacute;.",
	'New password login' => "Cliquez ici pour vous connecter avec votre nouveau mot de passe",	
	

	# Edit Social Networks - form_socialnet() 
	
        'Social network instructions' => "Utilisez ce formulaire pour modifier les informations de votre r&eacute;seau social. Nous serons en mesure d'utiliser cette information pour vous aider &agrave; publier sur le site #1 de votre r&eacute;seau social, et d'associer les messages nous havest de ces r&eacute;seaux sociaux &agrave; votre identit&eacute; #2.<br/><br/>S'il vous pla&icirc;t noter que la fourniture de cette information est <i>option</i>. En outre, l'identit&eacute; de votre r&eacute;seau social ne sera pas affich&eacute; au public, sauf si vous avez coch&eacute; la case «public» pour ce nom de r&eacute;seau social.",
	'Network' => "R&eacute;seau",
	'Your ID' => "Votre ID",
	'Public?' => "Publique?",
	'Update Social Network Information' => "Mise &agrave; jour de r&eacute;seau social",	


	# Submit stuff - receive() 
	
	'Feed' => "Flux",'feed' => "flux",	
	'Dear' => "Cher",
	'Automatic approval' => "Votre #1 a été soumis et approuvé automatiquement.",
	'New submitted approval needed' => "Un nouveau #1 a été présentée par un lecteur de #2 #3. Dans cet e-mail vous pouvez consulter le #1 soumission et l'approuver ou de le rejeter.",
	'New submitted' => "Nouveau #1 (#2) soumis sur #3",
	'Back to the Home Page' => "Retour &agrave; la page d'accueil",
        'Your item has been submitted' => "Votre #1 a &eacute;t&eacute; soumis",
 	'Has been submitted' => "Votre #1 a été présenté et sera examiné par #2 éditeurs de sites. Merci pour votre présentation.",       
	'Check feed status' => "Pour vérifier l'état de votre flux, <a href='#1'>cliquez ici</ a>",

	# Preview
	'Start' => "Démarrer",
	'Preview' => "Avant-première",
	'Continue editing' => "Vous pouvez continuer à éditer en utilisant le formulaire ci-dessous la prévisualisation (faites défiler vers le bas)",
		
	# Deleting
	'Record no longer exists' => "Fiche n'existe plus",		
	'Sender banned' => "L'expéditeur #1 a été identifiée comme un spammeur et ajoutée à la liste des sites interdits.<br>",
	'Record id deleted' => "Fiche #1 supprimé.<br/>#2",
	'Deleted record' => "Fiche supprimé.",
	'Table id deleted' => "#1 (#2) supprimé par #3",

       # Date 

	'N/A' => 'N/D',

	
	'Sun' => "Dim",
	'Mon' => "Lun",
	'Tue' => "Mar",
	'Wed' => "Mer",
	'Thu' => "Jeu",
	'Fri' => "Ven",
	'Sat' => "Sam",
	
	'Sunday' => "Dimanche",
	'Monday' => "Lundi",
	'Tuesday' => "Mardi",
	'Wednesday' => "Mercredi",
	'Thursday' => "Jeudi",
	'Friday' => "Vendredi",
	'Saturday' => "Samedi",

	'Jan' => "Jan",
	'Feb' => "F&eacute;v",
	'Mar' => "Mar",
	'Apr' => "Avr",
	'May' => "May",
	'Jun' => "Juin",
	'Jul' => "Juil",
	'Aug' => "Ao&ucirc;t",
	'Sep' => "Sep",
	'Oct' => "Oct",
	'Nov' => "Nov",
	'Dec' => "D&eacute;c",

	'January' => "Janvier",
	'February' => "F&eacute;vrier",
	'March' => "Mars",
	'April' => "Avril",
	'May' => "Mai",
	'June' => "Juin",
	'July' => "Juillet",
	'August' => "Ao&ucirc;t",
	'September' => "Septembre",
	'October' => "Octobre",
	'November' => "Novembre",
	'December' => "D&eacute;cembre",


	'' => "",

	'' => "",

	'' => "",

        '' => ""





	};

	
