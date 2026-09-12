# Shared image-candidate picker for hub-created posts: sanitize_images, render_image_picker

# API HUB IMAGES ----------------------------------------------------------

# Given a list of candidate image URLs gathered client-side (bookmarklet DOM
# scan, feed thumbnail, or scraped from feed content HTML) plus any image
# already found by the bookmarklet's own page scrape, renders a clickable
# thumbnail strip into the edit page. Clicking a thumbnail attaches it via
# the existing cmd=update&type=file_url endpoint (same call Downes Clip's
# picker already makes) - no new remote fetch, just the pre-existing
# fetch-and-host-locally behaviour triggered by the one image the user picks.

# ----------------------------------------------------------------------------

sub sanitize_images {

	my ($images) = @_;
	my %seen;
	my @out;
	foreach my $u (@$images) {
		next unless ($u && $u =~ m{^https?://}i);
		next if ($seen{$u}++);
		push @out, $u;
		last if (scalar(@out) >= 10);
	}
	return \@out;
}

sub render_image_picker {

	my ($id, $images) = @_;
	return "" unless ($images && @$images);

	my $html = qq|<div id="hub_image_picker" style="margin:10px 0;padding:10px;border:1px solid #ccc;">
<div style="margin-bottom:6px;font-family:sans-serif;font-size:13px;color:#333;">Choose a thumbnail image:</div>
<div id="hub_image_strip" style="display:flex;flex-wrap:wrap;gap:8px;">|;

	foreach my $u (@$images) {
		my $esc = $u;
		$esc =~ s/"/&quot;/g;
		$html .= qq|<img src="$esc" onerror="this.remove()" style="width:100px;height:75px;object-fit:cover;cursor:pointer;border:2px solid transparent;" onclick="hubAttachImage(this,'$esc')">|;
	}

	$html .= qq|</div><div id="hub_image_status" style="font-family:sans-serif;font-size:12px;color:#666;margin-top:6px;"></div></div>
<script>
function hubAttachImage(el, url) {
	document.querySelectorAll('#hub_image_strip img').forEach(function(i){ i.style.border = '2px solid transparent'; });
	el.style.border = '2px solid #2a7';
	var status = document.getElementById('hub_image_status');
	status.textContent = 'Attaching...';
	fetch('/cgi-bin/api.cgi', {
		method: 'POST',
		credentials: 'same-origin',
		headers: {'Content-Type': 'application/json'},
		body: JSON.stringify({cmd:'update', table:'post', id:'$id', type:'file_url', value:url})
	}).then(function(r){ return r.text(); }).then(function(t){
		status.textContent = 'Attached \\u2713';
	}).catch(function(e){
		status.textContent = 'Failed: ' + e.message;
	});
}
</script>|;

	return $html;
}

1;
