
# API LIST / SEARCH
# -----------------
# Unified list and search function for api.cgi
#
# Entry point: api_list($table)
#   Reads filter/search/pagination parameters from $vars (global CGI params)
#   Executes query, formats each record, wraps in header/footer, prints and exits
#
# Format is determined by $vars->{format} (e.g. "html", "search", "json").
#   - Template-based formats (html, search, opml, rss, ...): each record is
#     passed to format_record(), which looks up the view in the 'view' table
#     (e.g. format="search", table="post", post_type="link" → "post_link_search")
#   - Special formats (json): handled by dedicated functions below
#
# Header/footer: fetched from the 'template' table, table-specific first with
#   fallback to generic:  post_list_header → list_header  (same for footer)
#   Placeholders available in header/footer templates:
#     [*query*]      — search term or "All Posts" etc.
#     [*table*]      — table name
#     [*count*]      — total matching records
#     [*start*]      — first record shown (1-based)
#     [*end*]        — last record shown (1-based)
#     [*number*]     — records per page
#     [*prev_link*]  — <a href="..."> for previous page, or empty string
#     [*next_link*]  — <a href="..."> for next page, or empty string
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

	# Search form convention: qkey=field_name + qval=search_term
	# Translate into a direct field param so the filter loop below handles it normally.
	# e.g. qkey=title, qval=foo  →  title=foo  →  post_title LIKE '%foo%'
	if ($parms->{qkey} && defined($parms->{qval}) && $parms->{qval} ne "") {
		$parms->{ $parms->{qkey} } = $parms->{qval};
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
# build_list_meta($table, $vars, $count, $start, $number)
#
# Build the metadata hash passed to apply_list_template() for header/footer.
# ---------------------------------------------------------------------------

sub build_list_meta {

	my ($table, $vars, $count, $start, $number) = @_;

	# Heading: show search term if present, otherwise "All Posts" etc.
	my $display = $vars->{query}
		? "Search: $vars->{query}"
		: "All " . ucfirst($table) . "s";

	my $end = $start + $number;
	$end = $count if $end > $count;

	# Build base query string for pagination links (all current params except start)
	my $base = $Site->{st_cgi} . "api.cgi?";
	my @qs;
	for my $key (sort keys %$vars) {
		next if $key eq 'start';
		my $val = $vars->{$key};
		next unless defined($val) && $val ne '';
		(my $safe_val = $val) =~ s/[^a-zA-Z0-9 ._-]//g;
		push @qs, "$key=$safe_val";
	}
	my $base_qs = join("&amp;", @qs);

	my $prev_link = "";
	if ($start > 0) {
		my $prev_start = ($start - $number > 0) ? $start - $number : 0;
		$prev_link = qq|<a href="${base}${base_qs}&amp;start=${prev_start}">&larr; Previous</a>|;
	}

	my $next_link = "";
	if ($start + $number < $count) {
		my $next_start = $start + $number;
		$next_link = qq|<a href="${base}${base_qs}&amp;start=${next_start}">Next &rarr;</a>|;
	}

	return {
		query     => $display,
		table     => $table,
		count     => $count,
		start     => $start + 1,    # 1-based for display
		end       => $end,
		number    => $number,
		prev_link => $prev_link,
		next_link => $next_link,
	};
}


# ---------------------------------------------------------------------------
# apply_list_template($text, $meta)
#
# Simple [*key*] substitution for list header/footer templates.
# Unknown placeholders are replaced with an empty string.
# ---------------------------------------------------------------------------

sub apply_list_template {
	my ($text, $meta) = @_;
	$text =~ s/\[\*(\w+)\*\]/ defined($meta->{$1}) ? $meta->{$1} : "" /ge;
	return $text;
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

	# Default to json for JSON POST requests (admin UI via loadData),
	# html for everything else (public-facing URLs with explicit format param)
	our $request_type;
	my $format = $vars->{format} || ($request_type eq 'post' ? 'json' : 'html');

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

	# Build metadata for header/footer substitution
	my $meta = &build_list_meta($table, $vars, $count, $start, $number);

	# Template-based output (html, search, opml, rss, ...)
	# (Content-type was already sent by check_user())

	# Header: table-specific first, fall back to generic list_header
	my $header_text = &db_get_template($dbh, $table."_list_header")
	               || &db_get_template($dbh, "list_header");
	print &apply_list_template($header_text, $meta) if $header_text;

	# Format each record via the view table
	while (my $record = $sth->fetchrow_hashref()) {

		# Unescape data that was HTML-encoded for storage
		while (my ($k, $v) = each %$record) {
			$record->{$k} =~ s/&amp;/&/g if defined $v;
		}

		my $formatted = &format_record($dbh, $query, $table, $format, $record, 1);
		print $formatted if $formatted;
	}

	# Footer: table-specific first, fall back to generic list_footer
	my $footer_text = &db_get_template($dbh, $table."_list_footer")
	               || &db_get_template($dbh, "list_footer");
	print &apply_list_template($footer_text, $meta) if $footer_text;

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

	# Content-type header was already sent by check_user() — do not print it again here
	# (printing it again would make it appear in the response body, breaking JSON.parse)

	# end = offset of last record shown; used by the JS footer as next page's start
	my $end = $start + $number;
	$end = $count if $end > $count;

	my @records;
	while (my $record = $sth->fetchrow_hashref()) {
		while (my ($k, $v) = each %$record) {
			$record->{$k} =~ s/&amp;/&/g if defined $v;
		}
		# Return short field names (no table prefix) to match what the admin JS
		# list templates expect: data[i].id, data[i].title, data[i].status, etc.
		my $item = {};
		for my $field (qw(id title name mimetype url link section genre category status type)) {
			$item->{$field} = $record->{ $table."_".$field };
		}
		push @records, $item;
	}

	my $response = {
		metadata => {
			table  => $table,
			count  => $count  + 0,
			start  => $start  + 1,   # 1-based for display ("Listing 1 to 40 of 500")
			end    => $end    + 0,   # used as start offset for next page load
			number => $number + 0,
		},
		data => \@records,
	};

	# Use to_json WITHOUT utf8=>1 so the output is a Perl Unicode string.
	# STDOUT has binmode :utf8 set in api.cgi, which encodes it correctly in one pass.
	# Using utf8=>1 here would produce UTF-8 bytes that :utf8 then re-encodes,
	# causing double-encoding (smart quotes etc. appear as â€™ instead of ').
	use JSON;
	print to_json($response, {pretty => 1});
	exit;
}

1;
