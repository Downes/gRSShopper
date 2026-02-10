

sub linkedin_post {

print "Content-type: text/html\n\n";

my $access_token = $ENV{'LINKEDIN_ACCESS_TOKEN'}; 
my $api_url = 'https://api.linkedin.com/rest/posts'; # Endpoint for creating posts

my $content = "This is the content of your newsletter post.";

my $post_data = qq|{
 "author": "urn:li:person:stdownes",
 "commentary": "test strings",
 "visibility": "PUBLIC",
 "distribution": {
   "feedDistribution": "MAIN_FEED",
   "targetEntities": [],
   "thirdPartyDistributionChannels": []
 },
 "content": {
     "article": {
         "source": "https://www.downes.ca",
         "title": "prod test title two",
         "description": "test description"
     }
 },
 "lifecycleState": "PUBLISHED",
 "isReshareDisabledByAuthor": false

}|;

my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new(POST => $api_url);
$req->header('Content-Type' => 'application/json');
$req->header('LinkedIn-Version' => '202401');
$req->header('Authorization' => "Bearer $access_token");
$req->content($post_data);

my $resp = $ua->request($req);

if ($resp->is_success) {
    print "Post successful: ", $resp->decoded_content, "\n";
} else {
    print "Error posting: ", $resp->status_line, "\n";
}
exit;


}

1;