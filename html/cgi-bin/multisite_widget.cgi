#!/usr/bin/perl

#    gRSShopper 1.0  MultiSite_Widget 1.0  -- gRSShopper administration module
#    15 September 2020 - Stephen Downes

# WORK IN PROGRESS 28 January 2021


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
#
#-------------------------------------------------------------------------------
#
#	    gRSShopper
#           Multisite Widget Script
#           Suitable for putting into an iframe on an otherwise static page 
#
#-------------------------------------------------------------------------------




	use File::Basename;
	use CGI::Carp qw(fatalsToBrowser);	
	my $dirname = dirname(__FILE__);
	require $dirname . "/grsshopper.pl";
	our ($query,$vars) = &load_modules("page");

	if (-e $dirname."/data/multisite.txt") {

		# If a multisite already exists, require a user login
		our ($Site,$dbh) = &get_site("page");	
		my ($session,$username) = &check_user();
		our $Person = {}; bless $Person;
		&get_person($Person,$username);
		my $person_id = $Person->{person_id};
		die "Must be logged in to add to multisite" unless $person_id;

	} else {

		# Multisite doesn't exist, define the first line
		print "Content-type: text/html\n\n";
		print "Defining site information for the first time.<br>";
		my $Site->{st_url} = $ENV{'SERVER_NAME'};
		$vars->{st_url} = $Site->{st_url};

	}

	if ($vars->{action} eq "Submit") {

		# Basic cleaning, might change passwords, but it's still in multisite.txt
		while (my ($vx,$vy) = each %$vars) { $vars->{$vx} =~ s/'|;|"|\t|\n//; }  
			
    	# Make variables easy to read :)
		my $siteurl = $vars->{st_url};
    	my $dbname = $vars->{db_name};
    	my $dbhost = $vars->{db_host};
    	my $dbuser = $vars->{db_user};
    	my $dbpwd = $vars->{db_pwd};
		my $language = $vars->{st_lang};

		if ($siteurl && $dbname && $dbhost && $dbuser && $dbpwd && $language ) {
			my $multisite = $dirname."/data/multisite.txt";
			open MULTI,">>$multisite" or die "Can't open $multisite: $?";
			print MULTI "$siteurl\t$dbname\t$dbhost\t$dbuser\t$dbpwd\t$language\n";
			
			print "Form submitted<br>"; 

			# Create the database locally, if needed
			if ($dbhost eq "localhost") {
				my $cmd = sprintf(qq|mysql -u %s -p%s -e "create database %s; GRANT ALL PRIVILEGES ON %s.* TO %s\@localhost IDENTIFIED BY '%s'"|,
					$Site->{database}->{usr},$Site->{database}->{pwd},$dbname,$dbname,$dbuser,$dbpwd);
				
				print $cmd;

				my $response = qx{$cmd};
				print $response;
			}

			# Test database connection
			# Connect to the Database
			my $dbh = DBI->connect("DBI:mysql:database=$dbname;host=$dbhost;port=3306",$dbuser,$dbpwd);

			# Catch connection error
			if( ! $dbh ) {

					print "Content-type: text/html\n\n";
				print "Database connection error for db '$dbname'. Please contact the site administrator.<br>";   

				# Print error report and exit
				print "Error String Reported: $DBI::errstr <br>";
				exit;

			# I'll put more error-checking here
			} else {
			
					print "<p>Database successfully connected.</p>";
				eval {
				#$dbh->do( whatever );
				#$dbh->{dbh}->do( something else );
				};

				if( $@ ) {
					print "Ugg, problem: $@\n";
				}
			}


			exit;
		} else {
			print "The entire form must be filled before submitting.";
		}
	}

	print qq|
			We're going to define the site information and database.
			<form method="post" action="multisite_widget.cgi">
			<table border=0>
			<tr><td>Base URL</td><td><input type="text" name="st_url" value="|.$vars->{st_url}.qq|"></td></tr>
			<tr><td>Database Name</td><td><input type="text" name="db_name" value="|.$vars->{db_name}.qq|"></td></tr>			
			<tr><td>Database URL</td><td><input type="text" name="db_host" value="localhost"></td></tr>
			<tr><td>Database User</td><td><input type="text" name="db_user" value="|.$vars->{db_user}.qq|"></td></tr>
			<tr><td>DB User Password</td><td><input type="password" name="db_pwd"></td></tr>	
			<tr><td>Language</td><td><input type="text" name="st_lang" value="EN"></td> (choices: EN, FR)</tr>
			<tr><td><br><input type="submit" name="action" value="Submit"></td><td></td></tr>
			<table><br></form>
			You probably won't need these values again, but you should note them just in case. Make sure that
			the database user and password are unique and can't be easily guessed.					
		|;

	
	
