
	# -------  Send Email ----------------------------------------------------------
sub send_email {


return;

	my ($to,$from,$subj,$page) = @_;


   my $page_text = $page;

   $page_text =~ s/<head(.*?)head>//sig;
   $page_text =~ s/<style(.*?)style>//sig;
   $page_text =~ s/\[(.*?)\]//sig;
   $page_text =~ s/<a(.*?)href="(.*?)"(.*?)>(.*?)<\/a>/$4 $2/sig;
   $page_text =~ s/<br\/>/\n/sig;
   $page_text =~ s/<\/p>/\n/sig;
   $page_text =~ s/<(.*?)>//sig;
   $page_text =~ s/  //sig;
   $page_text =~ s/\r//sig;
   $page_text =~ s/\n\n/\n/sig;

	# I can make this much more efficient later


	$subj = '🍁' .$subj;	# Adds maple leaf emoji

	my $html_file = $Site->{st_urlf}."email_html.htm";
	my $text_file = $Site->{st_urlf} . "email_text.txt";
	open OUTFILE, ">$html_file" or die "could not save $html_file for emailing. $!";
	print OUTFILE $page;
	close OUTFILE;

	open OUTFILE, ">$text_file" or die "could not save $text_file for emailing. $!";
	print OUTFILE $page_text;
	close OUTFILE;


    use MIME::Lite::TT::HTML;

    my $msg = MIME::Lite::TT::HTML->new(
        From        => $from,
        To          => $to,
        Subject     => $subj,
        TimeZone    => 'America/Toronto',
        Encoding    => 'quoted-printable',
        Template    => {
            html => 'email_html.htm',
            text => 'email_text.txt',
        },
        Charset     => 'UTF-8',
        TmplOptions =>  {INCLUDE_PATH => $Site->{st_urlf}}
       # TmplOptions => \%options,
       # TmplParams  => \%params,
    );

    $msg->send;

  return;




}

	#--------------------------------------------------------
	#
	#	line_lengths($text)
	#
	#	For text-style output, converts the file to
	#	line lengths of 60 characters
	#
	#--------------------------------------------------------
sub send_notifications {

		my ($dbh,$vars,$table,$subject,$mailtext) = @_;


		# List who gets notified?

		my $req = lc($Site->{"approve_".$table});
		my @rlist = db_get_record_list($dbh,"person",{person_status=>$req});
		my @alist = db_get_record_list($dbh,"person",{person_status=>'admin'});
		my @list = arrays("union",@rlist,@alist);

		# Send each one the message

		foreach my $approver (@list) {

			my $apers = &db_get_record($dbh,"person",{person_id=>$approver});
			my $admintext = $mailtext;
			$admintext =~ s/<name>/$apers->{person_name}/g;
			$admintext =~ s/<email>/$apers->{person_email}/g;
			&send_email($apers->{person_email},$Site->{st_pub},$subject,$admintext,"htm");

		}



	}
sub line_lengths {

	# Get text string from input
	my $pagetext = shift @_;

	# Initialize variables
	my $line; my $word; my $linelength;
	my $newline; my $newpage;
	$pagetext =~ s/\r//;

	my @linelist = split /\n/,$pagetext;

	foreach $line (@linelist) {
		$linelength=0; my $first = "yes";
		my @wordlist = split / /,$line;
		$newline = "\n  ";
		foreach $word (@wordlist) {
			my $wordlength = length($word) + 1;
			if ($first eq "yes") {
				$first = "no";
				$linelength = $wordlength;}
			else {
				if (($linelength + $wordlength) > 60) {
					$word = "\n  " . $word;
					$linelength = $wordlength;
				} else {
					$word = " " . $word;
					$linelength += $wordlength;
				}
			}
			$newline .= $word;
		}
		$newpage .= $newline;
	}
	$newpage =~ s/\n\s*\n\s*\n\s*\n/\n\n\n/g;
	return $newpage;
}


1;