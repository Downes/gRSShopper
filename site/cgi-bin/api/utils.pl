# Utility functions: api_show_record, api_backup, parse_my_url, api_ok, api_error, build_shards

# "
# API Show ----------------------------------------------------------
# ------- Show Record ------------------------------------------------------
#
# Show in a table
# Will accept search parameters
#
# -------------------------------------------------------------------------

sub api_show_record {

	 unless ($vars->{table}) { &status_error("Don't know which table to show.");}
	 &status_error("Not allowed to show ".$vars->{table}) unless (&is_allowed("view",$vars->{table}));

	 # Set PLE start screen to login if needed
	 if ($vars->{table} eq "box" && $vars->{id} eq "Start") {
		 
		 	our $Person = {}; bless $Person;
 			&get_person($dbh,$query,$Person);
 			my $person_id = $Person->{person_id};
		 	&admin_only();
	 }


   unless ($vars->{id}) { &status_error("Don't know which ".$vars->{table}." number to show."); }
	 $vars->{format} ||= "html";	 

	 return	&output_record($dbh,$query,$vars->{table},$vars->{id},$vars->{format},"api");
	 exit;
}





# API BACKUP ----------------------------------------------------------
# ------- Back Up Table ------------------------------------------
#
# Alter a column in a database
# Expects semi-colon-delimited comtent as follows: "field;type;size;null;default;extra"
#
# -------------------------------------------------------------------------

sub api_backup {

	my $output = "Backing up $vars->{table} ";
	if ($vars->{table} eq "all") {$output .= " tables"; }
	$output .= "... ";
	my $savefile = &db_backup($vars->{table});
	my $saveurl = $savefile;
	$saveurl =~ s/$Site->{st_urlf}/$Site->{st_url}/;
	$output .= qq|Table '$vars->{table}' backed up to <a href="$saveurl">$savefile</a>|;
	$output .= $vars->{backup_message};
  	return $output;

}
# Parses gRSShopper URLs to return table and ID of the requests
# Used my the WEBMENTION api function

sub parse_my_url {

   my ($url) = @_;

   my $base = $Site->{st_url};
   if ($url =~ m/page\.cgi\?(.*?)=(.*?)$/) {
			return ($1,$2);
   } elsif ($url =~ /$base(.*?)\/(.*?)$/) {
			return ($1,$2);
   } else {
			return 0;
   }
}

sub api_ok {

	print qq|&nbsp;&nbsp;&nbsp;&nbsp;<span style="color:green;">ok!</a>|;
	exit;

}

sub api_error {


	print "300 API Error - failed to update $vars->{table_name}  $vars->{table_id} \n";
	exit;

}
sub build_shards {
    my ($dbh, %opt) = @_;

    my $rd_base = $opt{rd_base} // die "rd_base required";
    my $scheme  = $opt{scheme}  // 100;   # 100 or 1000
    my $dry     = $opt{dry_run} // 0;

    die "rd_base must be absolute\n" unless $rd_base =~ m{^/};

    # Ensure the base exists (unless dry_run)
    if (!$dry && !-d $rd_base) {
        make_path($rd_base, { mode => 0755 }) or die "make_path($rd_base): $!";
    }

    # Query: only posts that actually have an external link
    my $sql = q{
        SELECT post_id, post_link
        FROM post
        WHERE post_type = 'link'
          AND post_link IS NOT NULL
          AND post_link <> ''
    };

    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my ($n_total, $n_created, $n_updated, $n_unchanged, $n_skipped) = (0,0,0,0,0);

    while (my ($id, $link) = $sth->fetchrow_array) {
        ++$n_total;

        my $post_id = int($id || 0);
        my $url     = defined($link) ? $link : '';
        $url =~ s/^\s+|\s+$//g;

        # only http/https redirects
        unless ($post_id > 0 && $url =~ m{^https?://}i) {
            ++$n_skipped;
            next;
        }

        # compute shard path
        my ($parent, $leaf);
        if ($scheme == 100) {
            $leaf   = $post_id % 100;          # 57
            $parent = int($post_id / 100);     # 781   → 781/57
        } elsif ($scheme == 1000) {
            $leaf   = $post_id % 1000;         # 157
            $parent = int($post_id / 1000);    # 78    → 78/157
        } else {
            die "Unsupported scheme: $scheme (use 100 or 1000)";
        }

        my $dir  = File::Spec->catdir($rd_base, $parent);
        my $file = File::Spec->catfile($dir, $leaf);

        # ensure dir exists
        if (!$dry && !-d $dir) {
            make_path($dir, { mode => 0755 }) or die "make_path($dir): $!";
        }

        # if file exists and identical, skip
        my $current = '';
        if (-e $file) {
            if (open my $rfh, '<', $file) {
                local $/ = undef;
                $current = <$rfh>;
                close $rfh;
                $current //= '';
                $current =~ s/^\s+|\s+$//g;
            }
            if ($current eq $url) {
                ++$n_unchanged;
                next;
            }
        }

        if ($dry) {
            if (-e $file) { ++$n_updated } else { ++$n_created }
            next;
        }

        # atomic write: tmp → rename
        my $tmp = "$file.tmp.$$";
        open my $wfh, '>', $tmp or die "open($tmp): $!";
        binmode $wfh;
        print {$wfh} $url, "\n";
        close $wfh or die "close($tmp): $!";
        chmod 0644, $tmp;
        rename $tmp, $file or die "rename($tmp => $file): $!";

        if (defined $current && length $current) { ++$n_updated } else { ++$n_created }
    }

    $sth->finish;

    my $report_counts = sprintf <<"TXT",
Total rows:       %d
Created files:    %d
Updated files:    %d
Unchanged files:  %d
Skipped (bad):    %d
TXT
    $n_total, $n_created, $n_updated, $n_unchanged, $n_skipped;

syslog(LOG_INFO,
    "build_shards done base=%s scheme=%d dry=%d totals: rows=%d created=%d updated=%d unchanged=%d skipped=%d",
    $rd_base, $scheme, $dry, $n_total, $n_created, $n_updated, $n_unchanged, $n_skipped
);

return "[UTC " . (scalar gmtime) . "] build_shards complete\n" .
       "Base directory:   $rd_base\n" .
       "Scheme:           $scheme (100 => 781/57; 1000 => 78/157)\n" .
       "Dry run:          $dry\n" .
       $report_counts;

}

1;
