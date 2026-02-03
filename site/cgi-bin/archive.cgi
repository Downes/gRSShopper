#!/usr/bin/perl

#    gRSShopper 0.7  Archive  0.4  -- gRSShopper archive module
#    Stephen Downes, April 26, 2017
#    Updated 2013 03 04 to use File::Basename

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

#print "Content-type: text/html\n\n";

#-------------------------------------------------------------------------------
#
#	    gRSShopper 
#           Archive Page Script 
#
#-------------------------------------------------------------------------------

# Load gRSShopper

	use File::Basename;												
	use CGI::Carp qw(fatalsToBrowser);
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



# Prepare Archives --------------------------------------------------------------

						# Get filename, if needed
my $page_filename = $vars->{page} || "news/OLDaily.htm";
$page_filename =~ s/\//_/ig;

						# Set Up Variables

my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
$year = $year - 100 + 2000;   # Y2K fix

my $start_year = $year;
my $end_year = 2000;
my $start_month = 0;
my $start_mday = 1;
my $base_dir = $Site->{st_urlf}."archive";
my $base_url = $Site->{st_url}."archive";
my $archive_page = $base_dir . "/index.html";
print "Content-type: text/html\n\n";
my $page_content = "<h1>Archives</h1>";
# = $Site->{header};
my @months = ('Jan','Feb','Mar','Apr','May','Jun','Jul',
 			   'Aug','Sept','Oct','Nov','Dec');


						# For Each Year
while ($start_year > $end_year) {

						# Write a Nice Year Banner

	$page_content .= "<center><table width=80% border=1 cellpadding=2 cellspacing=0>\n" .
		"<tr><td colspan=12 bgcolor=\"#aaaaaa\">" .
		"<b>$start_year</b></td></tr>\n";

						# Write Headers for Each Month
	$page_content .= "<tr>";
	while ($start_month < 12) {
		$page_content .=  "<td width=50><center>$months[$start_month]</center></td>\n";
		$start_month++;
	}
	$page_content .=  "</tr>\n";
	$start_month = 0;

						# For each Month..
	$page_content .=  "<tr>";
	while ($start_month < 12) {
		$page_content .= "<td width=50><center>";

						# For each day in each Month
		while ($start_mday < 32) {

						# Figure out what the archive file is
						# Contains some legacy (1998) code

			my $dmonth = $start_month+1;
			unless ($start_year eq "1998") {
				$dmonth = "0$dmonth" if ($dmonth < 10);
			}
			my $dday = $start_mday;
			$dday = "0$dday" if ($dday < 10);
			my $dyear = $start_year;
			if ($dyear < 2000) { $dyear = $dyear - 1900; } else { $dyear = $dyear - 2000; }
			$dyear = "0$dyear" if ($dyear < 10);
			$dyear = "" if ($dyear eq "98");
			my $archivefile = $base_dir . "/" . $dyear . "/" . $dmonth . "_" . $dday . "_". $page_filename;
			my $archiveurl = $base_url . "/" . $dyear . "/" . $dmonth . "_" . $dday . "_". $page_filename;
			if ($dyear eq "98" && $dmonth eq "9") { $archivefile .= "l"; }

						# Check to see if the file exists
						# print link if it does, plain number otherwise

			if (-e $archivefile) { $page_content .= "<a href=\"$archiveurl\">"; }
			else { $page_content .= "<font color=\"white\">"; }
			$page_content .=  "$dday<br>";
			if (-e $archivefile) { $page_content .=  "</a>"; }
			else { $page_content .= "</font>"; }
			$start_mday++;
		}

						# Close table stuff when done

		$page_content .= "</center></td>";
		$start_mday=1;
		$start_month++;
	
	}

	$page_content .= "</tr>\n";
	$start_month = 0;
	$page_content .= "</table></center><p>";
	$start_year--;
}

# $page_content .= $Site->{footer};

# Print Archives -----------------------------------------------------------------

open OUT,">$archive_page" or &error($dbh,"","","Error opening $archive_page : $!");
print OUT $page_content or  &error($dbh,"","","Error printing to $archive_page  : $!");
close OUT;

unless ($vars->{mode} eq "cron") {		# Allow cron to process as well
	print "Content-type: text/html; charset=utf-8\n\n";
	print $page_content;
}

exit;



1;