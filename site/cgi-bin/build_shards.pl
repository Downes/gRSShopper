#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use Getopt::Long qw(GetOptions);
use File::Spec;
use File::Path qw(make_path);
use Fcntl qw(:flock :mode);
use Encode qw(encode);
use POSIX qw(strftime);

# -----------------------------
# Options
# -----------------------------
my %opt = (
    dsn     => $ENV{DB_DSN}     || 'DBI:mysql:database=yourdb;host=127.0.0.1;port=3306',
    user    => $ENV{DB_USER}    || 'youruser',
    pass    => $ENV{DB_PASS}    || '',
    rd_base => $ENV{RD_BASE}    || '/vsrv/www/www.downes.ca/html/_rd',  # << per-host base
    dry_run => 0,
    scheme  => 100,  # 100 => 781/57 (parent=int(id/100), leaf=id%100); 1000 => 78/157
);
GetOptions(
    'dsn=s'     => \$opt{dsn},
    'user=s'    => \$opt{user},
    'pass=s'    => \$opt{pass},
    'rd-base=s' => \$opt{rd_base},
    'dry-run!'  => \$opt{dry_run},
    'scheme=i'  => \$opt{scheme},  # 100 or 1000
) or die "Usage: $0 --dsn ... --user ... --pass ... --rd-base /path [--dry-run] [--scheme 100|1000]\n";

die "rd-base must be an absolute path\n" unless $opt{rd_base} =~ m{^/};

# -----------------------------
# Connect
# -----------------------------
my $dbh = DBI->connect(
    $opt{dsn},
    $opt{user},
    $opt{pass},
    {
        RaiseError         => 1,
        PrintError         => 0,
        AutoCommit         => 1,
        mysql_enable_utf8mb4 => 1,   # for DBD::mysql >= 4.050
        mysql_enable_utf8    => 1,   # fallback for older DBD::mysql
    }
) or die "DB connect failed\n";

# -----------------------------
# Query rows to export
# -----------------------------
my $sql = q{
    SELECT post_id, post_link
    FROM post
    WHERE post_type = 'link'
      AND post_link IS NOT NULL
      AND post_link <> ''
};
my $sth = $dbh->prepare($sql);
$sth->execute;

# -----------------------------
# Helpers
# -----------------------------
sub trim {
    my ($s) = @_;
    return '' unless defined $s;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}
sub is_good_url {
    my ($u) = @_;
    return defined($u) && $u =~ m{^https?://}i;
}
sub shard_path {
    my ($base, $id, $scheme) = @_;
    my ($parent, $leaf);
    if ($scheme == 100) {
        $leaf   = $id % 100;
        $parent = int($id / 100);   # 781/57 for 78157
    } elsif ($scheme == 1000) {
        $leaf   = $id % 1000;
        $parent = int($id / 1000);  # 78/157 for 78157
    } else {
        die "Unsupported scheme: $scheme (use 100 or 1000)\n";
    }
    my $dir  = File::Spec->catdir($base, $parent);
    my $file = File::Spec->catfile($dir, $leaf);
    return ($dir, $file);
}

# -----------------------------
# Walk rows
# -----------------------------
my ($n_total, $n_created, $n_updated, $n_skipped_bad, $n_unchanged) = (0,0,0,0,0);

while (my ($id, $link) = $sth->fetchrow_array) {
    ++$n_total;

    # normalize
    my $post_id = int($id || 0);
    my $url = trim($link);

    # validate
    if ($post_id <= 0 || !is_good_url($url)) {
        ++$n_skipped_bad;
        next;
    }

    # target path
    my ($dir, $file) = shard_path($opt{rd_base}, $post_id, $opt{scheme});

    # ensure dir exists
    unless (-d $dir) {
        if ($opt{dry_run}) {
            print "[DRY] mkdir -p $dir\n";
        } else {
            make_path($dir, { mode => 0755 }) or die "make_path($dir) failed: $!";
        }
    }

    # if file exists and content identical, skip
    my $current = '';
    if (-e $file) {
        if (open my $rfh, '<', $file) {
            local $/ = undef;
            $current = <$rfh>; close $rfh;
            $current = trim($current);
        }
        if ($current eq $url) {
            ++$n_unchanged;
            next;
        }
    }

    # write atomically: tmp -> rename
    if ($opt{dry_run}) {
        if (-e $file) {
            print "[DRY] UPDATE $file  ($current -> $url)\n";
        } else {
            print "[DRY] CREATE $file  ($url)\n";
        }
    } else {
        my $tmp = "$file.tmp.$$";
        open my $wfh, '>', $tmp or die "open($tmp) failed: $!";
        binmode $wfh;
        print {$wfh} $url, "\n";
        close $wfh or die "close($tmp) failed: $!";
        chmod 0644, $tmp;
        rename $tmp, $file or die "rename($tmp => $file) failed: $!";
        if (-e $current ? ++$n_updated : ++$n_created) { } # bump counters
    }
}

$sth->finish;
$dbh->disconnect;

# -----------------------------
# Report
# -----------------------------
my $ts = strftime('%Y-%m-%d %H:%M:%S', gmtime);
print <<"REPORT";
[$ts UTC] Done.
  Total rows:       $n_total
  Created files:    $n_created
  Updated files:    $n_updated
  Unchanged files:  $n_unchanged
  Skipped (bad):    $n_skipped_bad
  Base directory:   $opt{rd_base}
  Scheme:           $opt{scheme} (100 => 781/57; 1000 => 78/157)
  Dry run:          $opt{dry_run}
REPORT
