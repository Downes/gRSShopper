
# API LIST / SEARCH
# -----------------
# Unified list and search function for api.cgi
#
# Entry point: api_list($table)
#   Reads filter/search/pagination parameters from $vars (global CGI params)
#   Executes query, formats each record, wraps in header/footer, prints and exits
#
# Format is determined by $vars->{format} (e.g. "html", "json").
#   - Template-based formats (html, opml, rss, ...): each record is passed to
#     format_record(), which looks up the view in the 'view' table
#     (e.g. format="html", table="post" → view "post_html" or "post_blog_html")
#   - Special formats (json): handled by dedicated functions below
#
# List header/footer: fetched from the 'template' table by name, e.g.
#   "${table}_list_header" and "${table}_list_footer"
#   Silently omitted if no matching template exists.
#
# Query parameters recognised (all optional):
#   table   — which table to query (can also be passed as arg to api_list)
#   format  — output format; default "html"
#   sort    — ORDER BY expression, e.g. "post_crdate DESC"
#   number  — results per page; default $Site->{st_list} or 40
#   start   — offset (0-based)
#   query   — free-text search against _title and _description columns
#   Any other parameter whose name matches a column in the table is used as
#   a filter: exact match for _id/_status/_type/_genre/_category/_section/_class,
#   LIKE match for everything else.
#
# Replaces the multiple overlapping "list" handlers and the course-only search
# block in api.cgi.


# ---------------------------------------------------------------------------
# build_list_query($table, $parms)
#
# Shared helper: builds WHERE clause + pagination from a params hashref.
# Uses parameterised placeholders to prevent SQL injection.
#
# Returns: ($where_clause, \@bind_values, $sort, $limit, $count, $start, $number)
# ---------------------------------------------------------------------------

sub build_list_query {

	my ($table, $parms) = @_;

	# Special filter: id=latest → resolve to the most recent record id
	if ($parms->{id} && $parms->{id} eq "latest") {
		$parms->{id} = &db_get_single_value($dbh, $table, $table."_id", "", $table."_crdate DESC");
	}

	# Sort, start, number, limit  (reuses existing sort_start_number helper)
	my ($sort, $start, $number, $limit) = &sort_start_number($parms, $table);

	# Fetch actual column names once so we can validate filter keys
	my @columns = &db_columns($dbh, $table);

	my @wherelist;
	my @bind_vals;

	# These keys control query behaviour and must never be treated as data filters
	my %skip = map { $_ => 1 } qw(
		table number limit sort start finish format cmd
		qkey qval query where page search titname
	);

	# Build filter conditions from any param that maps to a real column
	while (my ($px, $py) = each %$parms) {

		next if !defined($py) || $py eq "" || $py eq "all";
		next if $skip{$px};

		# Normalise "status" → "post_status" etc.
		my $col = ($px =~ /^\Q${table}_\E/) ? $px : $table."_".$px;
		next unless grep { $_ eq $col } @columns;

		if ($col =~ /_(?:id|status|type|genre|category|section|class)$/) {
			push @wherelist, "($col = ?)";
			push @bind_vals, $py;
		} else {
			push @wherelist, "($col LIKE ?)";
			push @bind_vals, "%$py%";
		}
	}

	# Free-text search: $parms->{query} matches _title OR _description
	if ($parms->{query}) {
		my $q = $parms->{query};
		$q =~ s/[^a-zA-Z0-9 .]//g;    # allow letters, digits, spaces, dots only
		if ($q) {
			my @search_conds;
			for my $suffix (qw(title description)) {
				my $col = $table."_".$suffix;
				if (grep { $_ eq $col } @columns) {
					push @search_conds, "($col LIKE ?)";
					push @bind_vals, "%$q%";
				}
			}
			push @wherelist, "(" . join(" OR ", @search_conds) . ")" if @search_conds;
		}
	}

	my $where = @wherelist ? "WHERE " . join(" AND ", @wherelist) : "";

	# Count total matching rows (for pagination metadata)
	my $count_stmt = "SELECT COUNT(*) FROM $table $where";
	my ($count) = $dbh->selectrow_array($count_stmt, undef, @bind_vals);

	return ($where, \@bind_vals, $sort, $limit, $count, $start, $number);
}


# ---------------------------------------------------------------------------
# api_list($table)
#
# Main entry point. Called from the "list" command handler in api.cgi.
# ---------------------------------------------------------------------------

sub api_list {

	my ($table) = @_;
	$table ||= $vars->{table};
	unless ($table) { &status_error("api_list: no table specified"); }

	my $format = $vars->{format} || "html";

	# Build and execute query
	my ($where, $bind_vals, $sort, $limit, $count, $start, $number) =
		&build_list_query($table, $vars);

	my $stmt = qq|SELECT * FROM $table $where $sort $limit|;
	my $sth = $dbh->prepare($stmt)
		or &status_error("List query failed: " . $dbh->errstr);
	$sth->execute(@$bind_vals)
		or &status_error("List query failed: " . $sth->errstr);

	# Dispatch to format-specific handler for non-template formats
	if ($format eq "json") {
		return &api_list_json($table, $sth, $count, $start, $number);
	}

	# Template-based output (html, opml, rss, ...)
	print "Content-type: text/html\n\n";

	# Optional header from template table (e.g. "post_list_header")
	my $header = &db_get_template($dbh, $table."_list_header");
	print $header if $header;

	# Format each record via the view table
	while (my $record = $sth->fetchrow_hashref()) {

		# Unescape data that was HTML-encoded for storage
		while (my ($k, $v) = each %$record) {
			$record->{$k} =~ s/&amp;/&/g if defined $v;
		}

		my $formatted = &format_record($dbh, $query, $table, $format, $record, 1);
		print $formatted if $formatted;
	}

	# Optional footer from template table (e.g. "post_list_footer")
	my $footer = &db_get_template($dbh, $table."_list_footer");
	print $footer if $footer;

	exit;
}


# ---------------------------------------------------------------------------
# api_list_json($table, $sth, $count, $start, $number)
#
# JSON output path — returns full records as a JSON object with metadata.
# Called by api_list when format=json.
# ---------------------------------------------------------------------------

sub api_list_json {

	my ($table, $sth, $count, $start, $number) = @_;

	print "Content-type: application/json\n\n";

	my @records;
	while (my $record = $sth->fetchrow_hashref()) {
		while (my ($k, $v) = each %$record) {
			$record->{$k} =~ s/&amp;/&/g if defined $v;
		}
		push @records, $record;
	}

	my $response = {
		metadata => {
			table  => $table,
			count  => $count + 0,   # ensure numeric
			start  => $start + 0,
			number => $number + 0,
		},
		data => \@records,
	};

	print &hash_to_json($response);
	exit;
}

1;
