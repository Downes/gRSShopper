#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use File::Basename;

# Directory to scan for files (set this to the desired directory)
my $directory = '/srv/www/www.downes.ca/html/agora';

# Create a new CGI object
my $cgi = CGI->new;
use CGI::Carp qw(fatalsToBrowser); # This will send errors to the browser
# Set the content type to HTML
print "Content-type: text/html\n\n";
print "<html><head><style>
    .image-container {
        position: relative;
        display: inline-block;
        width: 300px; /* Adjust to match your image width */
        height: 246px; /* Adjust to match your image height */
        margin: 10px;
        background-size: cover;
    }
    .overlay-text {
        position: absolute;
        top: 75px; /* Position 75px from the top */
        left: 15px; /* Indent 15px from the left */
        color: white;
        font-size: 24px; /* Increase font size */
        font-weight: bold;
        text-shadow: -2px -2px 0 #000, 2px -2px 0 #000, -2px 2px 0 #000, 2px 2px 0 #000;
    }
</style></head><body>";
print "<h1>Agora Puzzle Pieces</h1>";

# Open the directory
opendir(my $dh, $directory) or print "Cannot open directory: $!";

# Loop through each file in the directory
while (my $filename = readdir($dh)) {
    # Skip directories and files containing '_small'
    next if $filename =~ /_small/ || -d "$directory/$filename";
    
    # Generate the small version filename
    my $small_filename = $filename;
    $small_filename =~ s/(\.[^.]+)$/_small$1/;

    # Clean up the filename for display
    my $display_name = $filename;
    $display_name =~ s/_/ /g;           # Replace underscores with spaces
    $display_name =~ s/\.png$//i;       # Remove the .png extension (case insensitive)
    $display_name = ucfirst($display_name);  # Capitalize the first letter

    # Print the HTML with div overlay
    print qq(
        <div class="image-container" style="background-image: url('https://www.downes.ca/agora/$small_filename');">
            <a href="https://www.downes.ca/agora/$filename">
                <span class="overlay-text">$display_name</span>
            </a>
        </div>
    );
}
# Close the directory
closedir($dh);

# End HTML
print $cgi->end_html;

exit;
