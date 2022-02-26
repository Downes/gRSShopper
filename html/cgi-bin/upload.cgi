#!/usr/bin/perl -w
use CGI;
use CGI::Carp qw(fatalsToBrowser);

$upload_dir = "/var/www/html/uploads";
$query = new CGI;
$filename = $query->param("photo");
$filename =~ s/.*[\/\\](.*)/$1/;
$upload_filehandle = $query->upload("photo");

open UPLOADFILE, ">$upload_dir/$filename";
while ( <$upload_filehandle> )
{
print UPLOADFILE;
}
close UPLOADFILE;

print $query->header ();

print qq|
<HTML>
<HEAD>
<TITLE>Thanks!</TITLE>
</HEAD>
<BODY>
<P>Thanks for uploading your photo $upload_dir $filename!</P>
    <P>Your photo:</P>
<img src="../uploads/$filename" border="0">
</BODY>
</HTML>|;