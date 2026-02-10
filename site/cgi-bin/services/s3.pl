#
#   S3
#
#   Functions for working with S3
#


#   s3_upload($bucket_name,$key_name,$metadata)
#
#   key_name - is the file name for use in the bucket.
#   local_file - is the full file path of the file to upload.
#   mine - file mine_type
#   Returns URL of the uploaded file on S3
#

sub s3_upload {

    my ($bucket_name,$key_name,$local_file,$mime,$metadata) = @_;
    my $bucket = s3_initialize($bucket_name);
    my $value   = 'T';


    # store a key with a content-type and some optional metadata
    $bucket->add_key_filename(
        $key_name, $local_file, { content_type => $mime,}
    );

    my $key_file = 'https://'.$bucket_name.'.s3.amazonaws.com/'.$key_name;
    return $key_file;

}



sub s3_initialize {

    my ($bucket_name) = @_;

    # Set Up mailgun
    eval "use Amazon::S3";
    if ($@) { &status_error("Amazon::S3 module is required to use S3."); }
    unless ($Site->{s3_key} && $Site->{s3_secret}) {
        &status_error("Please define Amazon S3 API key and secret in Social:Accounts."); 
    }

    my $s3 = Amazon::S3->new(
        {   aws_access_key_id     => $Site->{s3_key},
            aws_secret_access_key => $Site->{s3_secret},
            retry                 => 1
        }
    );
    #my $response = $s3->buckets;

    my $bucket = $s3->bucket($bucket_name);
    unless ($bucket) { &status_error("Unsuccessful initiatization for S3 bucket $bucket_name");} 
    return $bucket;
}

1;