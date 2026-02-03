
	sub favicon_button {
		my ($image_file) = @_;
		print qq|
			<style>
				#loader {
					display: none;
					position: fixed;
					top: 0;
					left: 0;
					right: 0;
					bottom: 0;
					width: 100%;
					background: rgba(0,0,0,0.75) url(|.$Site->{st_url}.qq|assets/images/hug.gif) no-repeat center center;
					z-index: 10000;
				}
			</style>
			<div id="loader"></div>
			<img src="|.$Site->{st_url}.qq|$image_file" style="width:100px;margin:1em;"><br>
			<form id="faviconform" method="post" action="admin.cgi" onSubmit="document.getElementById('loader').style.display = 'block';">
			<input type="hidden" name="image_file" value="$image_file">
			<input type="hidden" name="action" value="get_favicon">
			Border: <input type="text" size=3 name="border" value=1>
			Background Colour: <input type="text" size=3 name="background" value="#ffffff"><br>
			<input type="submit" class="button">
			</form><p style="margin:1em;">Note that it may take a few minutes for the icons to generate.</p>
		|;
		exit;
	}

	sub favicon_generate {

		my $image_file = shift;
		print qq|<div style="margin:1em;"><h2>Favicon API response</h2>|;


		my $url = "https://realfavicongenerator.net/api/favicon";
		my $json = &favicon_json($image_file,$border,$background);
		
		my $req = HTTP::Request->new(POST => $url);
		$req->content_type('application/json');
		$req->content($json);

		my $ua = LWP::UserAgent->new; # You might want some options here
		my $res = $ua->request($req);
		my $content = $res->content( );

		# Parse the JSON Data
		use JSON;
		use JSON::Parse 'parse_json';
		my $result = eval { parse_json($content) };
		if ($@)	{ # Catch error
			print "Content-type:application/json\n\n";
    		print "parse_json failed, invalid json. error:$@\n </div>";
			exit;
		}
	

		if ($result->{favicon_generation_result}->{result}->{status} eq "success") {
			# print $result->{favicon_generation_result}->{result}->{status},"<p>";

			# save the icon files
			foreach my $fvurl (@{$result->{favicon_generation_result}->{favicon}->{files_urls}}) {
				my @fnamearray = split '/',$fvurl;
				my $fvfile = pop @fnamearray;
				$fvfile = $Site->{urlf}."assets/icons/".$fvfile;
				my $code = getstore($fvurl, $fvfile) or print "Error saving $fvfile: $? <br>";

			}

			# Save the favicon box
			my $boxid = &db_locate($dbh,"box",{"box_title" => "favicon"});
			my $faviconcode = $result->{favicon_generation_result}->{favicon}->{html_code};

			if ($boxid) {
				&db_update($dbh,"box",{box_content => $faviconcode},$boxid);
			} else {
				$boxid = &db_insert($dbh,"","box",{box_content => $faviconcode,box_title => "favicon"});
			}

			print qq|<p><img src="|.$Site->{st_url}.qq|assets/icons/open-graph.png" style="width:100px"><br>
				<p>Created favicons<br/>Favicon locations are listed in the favicon box (id $boxid)<br>
				To use it, place &lt;box favicon&gt; in the page head</p></div>|;

		} else {
			print "<p>Favicon update failed.</p>";
			print $result->{favicon_generation_result}->{result}->{status}."<p>";
			print $result->{favicon_generation_result}->{result}->{error_message}."<p></div>";

		}

		exit;


	}

	sub favicon_json {
		my $image_file = shift;
		unless ($image_file) { print "Image file not defined in favicon_json() <br>"; exit; }

		# Load the image file and encode it
		$image_file = $Site->{st_urlf}.$image_file;
		print "Image filename is: ".$image_file."<br>";
		open (IMAGE, "$image_file") or die "$!";
		use MIME::Base64 ('encode_base64');
		my $raw_string = do{ local $/ = undef; <IMAGE>; };
		my $encoded_image = encode_base64( $raw_string );
		
		close IMAGE;

		my $jsonhash = {
			"favicon_generation" => {
				"api_key" => $Site->{realfavicon_apikey},
				"master_picture" => {
					"type" => "inline",
					"content" => $encoded_image
				},
				"files_location" => {
					"type" => "path",
					"path" => $Site->{st_url}."assets/icons"
				},
				"favicon_design" => {
					"desktop_browser" => {},
					"ios" => {
						"picture_aspect" => "background_and_margin",
						"margin" => "$border",
						"background_color" => "$background",
						"startup_image" => {
							"master_picture" => {
								"type" => "inline",
								"content" => "$encoded_image"
							},
							"background_color" => "$background"
						},
						"assets" => {
							"ios6_and_prior_icons" => false,
							"ios7_and_later_icons" => true,
							"precomposed_icons" => false,
							"declare_only_default_icon" => true
						}
					},
					"windows" => {
						"picture_aspect" => "white_silhouette",
						"background_color" => "$background",
						"assets" => {
							"windows_80_ie_10_tile" => true,
							"windows_10_ie_11_edge_tiles" => {
								"small" => false,
								"medium" => true,
								"big" => true,
								"rectangle" => false
							}
						}
					},
					"firefox_app" => {
						"picture_aspect" => "circle",
						"keep_picture_in_circle" => "true",
						"circle_inner_margin" => "$border",
						"background_color" => "$background",
						"manifest" => {
							"app_name" => "$Site->{st_name}",
							"app_description" => "$Site->{st_description}",
							"developer_name" => "$Site->{st_creator}",
							"developer_url" => "$Site->{st_url}"
						}
					},"android_chrome" => {
						"picture_aspect" => "shadow",
						"manifest" => {
							"name" => "$Site->{st_name}",
							"display" => "standalone",
							"orientation" => "portrait",
							"start_url" => "index.html"
						},
						"assets" => {
							"legacy_icon" => true,
							"low_resolution_icons" => false
						},
						"theme_color" => "$background"
					},
					"safari_pinned_tab" => {
						"picture_aspect" => "black_and_white",
						"threshold" => 60,
						"theme_color" => "$background"
					},
					"coast" => {
						"picture_aspect" => "background_and_margin",
						"background_color" => "$vackground",
						"margin" => "12%"
					},
					"open_graph" => {
						"picture_aspect" => "background_and_margin",
						"background_color" => "$background",
						"margin" => "12%",
						"ratio" => "1.91:1"
					},
					"yandex_browser" => {
						"background_color" => "$background",
						"manifest" => {
							"show_title" => true,
							"version" => "1.0"
						}
					}

				},
				"settings" => {
					"compression" => "3",
					"scaling_algorithm" => "Mitchell",
					"error_on_image_too_small" => true,
					"readme_file" => true,
					"html_code_file" => false,
					"use_path_as_is" => false
				},
				"versioning" => {
					"param_name" => "ver",
					"param_value" => "15Zd8"
				}
			}
		};		

		use JSON::XS;
		my $utf8_encoded_json_text = encode_json $jsonhash;
		return $utf8_encoded_json_text;

	}

1;
