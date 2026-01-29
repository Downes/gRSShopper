#    gRSShopper 0.7  Rules  -- gRSShopper harvester module
#    March 4, 2018 - Stephen Downes
#    cgi-bin/harvest/rules.pl

#    Copyright (C) <2018>  <Stephen Downes, National Research Council Canada>
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

#    Rules are applied to harvested items before they are saved.

#----------------------------- Rules ------------------------------


	# Autopost & Rules
	#
	# Multiple reules are separated with ;
	# Rules are expressed: [else] condition => action
	# Rules preceded with [else] are run only if no previous rule has been run
	# condition is expressed: field~value,$field~value for a disjunction of values
	# action is expressed: field=value,field=value  for a list of values to set
	# action is expressed: autopost  to post link as a post
	#
	# eg.
	# title~Moncton,description~Moncton => category=City,autopost;

sub rules {

	my ($feed,$item) = @_;
	&diag(4,qq|<div class="function">Rules<div class="info">|);

	my @rules = split ";",$feed->{feed_rules};
	my $triggered = 0;
	foreach my $rule (@rules) {
		if ($rule =~ /^else/i) { next if $triggered; } 			# else
		else { $triggered = 0; }
		$rule =~ s/else//i; $rule =~ s/^\s*//;
		my ($if,$then) = split /\s*=>\s*/i,$rule;			# if - then
		if (&rule_conditions($if,$item)) {
			$triggered = 1;
			&rule_actions($then,$item);
		}
	}
	&diag(4,qq|</div></div>|);
}

sub rule_conditions {

	my ($if,$item) = @_;
	&diag(5,qq|<div class="function">Rule CVonditions<div class="info">|);
	my $true = 1;								# Always true if there are no conditions

	my @conditions = split /\s*&\s*/,$if;
	foreach my $cond (@conditions) {
		$true = 0;
		if ($cond =~ m/(.*?)=(.*?)/) {							# field = value
			my ($fieldlist,$match) = split /\s*=\s*/,$cond;
	 		foreach my $field (split /\s*\|\s*/,$fieldlist) {
	 			if ($item->{$field} eq $match) { $true = 1; }
				if ($item->{"link_".$field} eq $match) { $true = 1; }
	 		}
	 	} elsif ($cond =~ m/(.*?)\s*~\s*(.*?)/) {						# field ~ value
			my ($fieldlist,$match) = split /\s*~\s*/,$cond;
	 		foreach my $field (split /\s*\|\s*/,$fieldlist) {
	 			if ($item->{$field} =~ /$match/i) { $true = 1; }
				if ($item->{"link_".$field} =~ /$match/i) { $true = 1; }
	 		}
	 	} elsif ($cond =~ m/(.*?)>(.*?)/) {						# field > value
			my ($fieldlist,$match) = split /\s*>\s*/,$cond;
	 		foreach my $field (split /\s*\|\s*/,$fieldlist) {
	 			if (defined($item->{$field}) && ($item->{$field} > $match)) { $true = 1; }
				if (defined($item->{"link_".$field}) && ($item->{"link_".$field} > /$match/i)) { $true = 1; }
	 		}
	 	} elsif ($cond =~ m/(.*?)<(.*?)/) {						# field < value
			my ($fieldlist,$match) = split /\s*<\s*/,$cond;
	 		foreach my $field (split /\s*\|\s*/,$fieldlist) {
	 			if (defined($item->{$field}) && ($item->{$field} < $match)) { $true = 1; }
				if (defined($item->{"link_".$field}) && ($item->{"link_".$field} < $match)) { $true = 1; }
	 		}
	 	}

	 	last unless ($true);
	}
	&diag(5,qq|</div></div>|);
	return $true;
}




sub rule_actions {

	my ($then,$item) = @_;
	&diag(5,qq|<div class="function">Rule Actions<div class="info">|);
#			do {} while ($then =~ s/\((.*?),(.*?)\)/COMMA/g);   # screen commas in brackets

	my @actions = split /(?![^(]+\)),/, $then;

#			my @actions = split ",",$then;

	my $dbupdate = ();
	foreach my $a (@actions) {
		&diag(4,"$a<br>\n");
		if ($a =~ /autopost/i) { &rule_autopost($item); }		# autopost

		elsif ($a =~ /=/) { &rule_assign($item,$a); }			# change value

		elsif ($a =~ /extract/i) { &rule_extract($item,$a); }		# extract

		elsif ($a =~ /remove/i) { &rule_remove($item,$a); }		# remove

	}
	&diag(5,qq|</div></div>|);
}


#----------------------------- Rule:  Autopost ------------------------------


sub rule_autopost {

	my ($item) = @_;
	&diag(5,qq|<div class="function">Rule Autopost<div class="info">|);
	my $post_id = &auto_post($dbh,$query,$item->{link_id});
	&diag(5,qq|</div></div>|);
}



#----------------------------- Rule:  Assign ------------------------------


sub rule_assign {

	my ($item,$a) = @_;
	&diag(5,qq|<div class="function">Rule Assign<div class="info">|);
	my ($fieldlist,$match) = split /\s*=\s*/,$a;
	unless ($fieldlist =~ /_link/) { $fieldlist = "link_".$fieldlist; }
	$item->{$fieldlist}=$match;
	unless ($analyze eq "on") { &db_update($dbh,"link",{$fieldlist=>$match},$item->{link_id}); }
	&diag(5,qq|</div></div>|);
}


#----------------------------- Rule:  Extract ------------------------------


sub rule_extract {

	my ($item,$a) = @_;
	&diag(5,qq|<div class="function">Rule Extract<div class="info">|);
	$a =~ s/extract\(//; $a =~ s /\)//;
	my ($f,$s,$e) = split /,/,$a;
	next unless ($f && $e);
	unless ($f =~ /_link/) { $f = "link_".$f; }		# Standardize field names

	my $extracted = "";
	if ($s eq '^') { if ($item->{$f} =~ /^(.*?)$e/i) { $extracted = $1; } }
	elsif ($e eq '$') { if ($item->{$f} =~ /$s(.*?)$/i) { $extracted = $1; }	}
	else { if ($item->{$f} =~ /$s(.*?)$e/i) { $extracted = $1; } }

	if ($extracted) {
		$item->{$f} = $extracted;
		unless ($analyze eq "on") { &db_update($dbh,"link",{$f=>$extracted},$item->{link_id}); }
	}
	&diag(5,qq|</div></div>|);
}

#----------------------------- Rule:  Remove ------------------------------


sub rule_remove {

	my ($item,$a) = @_;
	&diag(5,qq|<div class="function">Rule Remove<div class="info">|);
	$a =~ s/remove\(//; $a =~ s /\)//;
	my ($f,$s,$e) = split /,/,$a;
	next unless ($f && $e);
	unless ($f =~ /_link/) { $f = "link_".$f; }		# Standardize field names

	my $removed = "";
	if ($s eq '^') { if ($item->{$f} =~ /^(.*?)$e/i) { $removed = $1; } }
	elsif ($e eq '$') { if ($item->{$f} =~ /$s(.*?)$/i) { $removed = $1; }	}
	else { if ($item->{$f} =~ /$s(.*?)$e/i) { $removed = $1; } }

	if ($removed) {
		$item->{$f} =~ s/$removed//ig;
		unless ($analyze eq "on") { &db_update($dbh,"link",{$f=>$item->{$f}},$item->{link_id}); }
	}
	&diag(5,qq|</div></div>|);
}

1;
