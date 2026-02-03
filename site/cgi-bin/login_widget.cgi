#!/usr/bin/perl

#    gRSShopper 1.0  Login_Widget 1.0  -- gRSShopper administration module
#    15 September 2020 - Stephen Downes

# WORK IN PROGRESS 07 September 2020
# Updated 21 January 2022


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
#           Login Widget Script
#           Suitable for putting into an iframe on an otherwise static page 
#
#-------------------------------------------------------------------------------

#print "Content-type: text/html\n\n";
#print "<h1>Login Widget</h1>";

	use File::Basename;
	use CGI::Carp qw(fatalsToBrowser);	
	use lib 'modules/lib/perl5';
	my $dirname = dirname(__FILE__);
	require $dirname . "/grsshopper.pl";
	&load_modules("page");
#print "Vars in Login Widget<p>";
#while (my($vx,$vy) = each %$vars) { print "$vx = $vy <br>";}	
	our ($Site,$dbh) = &get_site("page");	
#print "Checking user <p>";	
#print "Login name: ".$vars->{lg_name}."<p>";
	my ($session,$username) = &check_user();
	our $Person = {}; bless $Person;
	&get_person($Person,$username);
	my $person_id = $Person->{person_id};
	print &show_login($session);
	
