package MailChimp::Request;

use 5.010001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use NewModule ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';



sub new {
    my $class = shift;
    my ( $request ) = @_;


    my $self = bless {
        account => $request->{account},
        method => $request->{method},
        request => $request->{request},
        body => $request->{body},
    }, $class;
print "Request: ".$self->{request},"<p>";
    return $self;
}



# method can be GET or POST
# url is API url
# body is JSON encoded payload for POST requests

sub submit {

    my $self = shift;
    my $method = $self->{method};       # GET, POST, PUT
    my $request = $self->{request};     # 'lists','campaigns', etc
    my $body = $self->{body};           # hash of request content
    my $account = $self->{account};     # user account
    my $apikey = $account->{apikey};
#	my ($method,$url,$body) = @_;


    unless ($request) { $request = "ping"; }        # Default request    
    unless ($method)   { $method = "GET"; }         # Default method
    

    my $endpoint = sprintf("https://%s.%s/%s/%s",$account->{datacenter},$account->{url},$account->{version},$request);

# print "Method: $method Request: $endpoint<p>";

    my $curl = WWW::Curl::Easy->new;

    #my $url = $endpoint;
	#/$listid/members/" . Digest::MD5::md5(lc($email));

    $curl->setopt(WWW::Curl::Easy::CURLOPT_HEADER,0);
    $curl->setopt(WWW::Curl::Easy::CURLOPT_URL, $endpoint);

    $curl->setopt(WWW::Curl::Easy::CURLOPT_VERBOSE, 1);
    $curl->setopt(WWW::Curl::Easy::CURLOPT_USERPWD, 'user:' . $apikey);
    #$curl->setopt(WWW::Curl::Easy::CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    $curl->setopt(WWW::Curl::Easy::CURLOPT_TIMEOUT, 20);
    $curl->setopt(WWW::Curl::Easy::CURLOPT_CUSTOMREQUEST, $method);
    $curl->setopt(WWW::Curl::Easy::CURLOPT_SSL_VERIFYPEER, 0);
    if ($body) { $curl->setopt(WWW::Curl::Easy::CURLOPT_POSTFIELDS, $body); }

    # A filehandle, reference to a scalar or reference to a typeglob can be used here.
    my $response_body;
    $curl->setopt(WWW::Curl::Easy::CURLOPT_WRITEDATA,\$response_body);

    # Starts the actual request
    my $retcode = $curl->perform;

    # Looking at the results...
    if ($retcode == 0) {

		# print("Transfer went ok<p>");
		my $response_code = $curl->getinfo(WWW::Curl::Easy::CURLINFO_HTTP_CODE);

		# print "Received response: $response_body\n";

		use JSON::Parse 'parse_json';
		my $json = $response_body;
		if ($json) {
			my $perl = parse_json ($json);
			return $perl;
		} else {
			return $response_code;
		}
    } else {
        # Error code, type of error, error message
        my $message = "An error happened: $retcode ".$curl->strerror($retcode)." ".$curl->errbuf."\n";
		return $message;
	}

}

