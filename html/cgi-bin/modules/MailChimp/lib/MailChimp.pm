package MailChimp;

use 5.010001;
use strict;
use warnings;

use lib '/var/www/html/cgi-bin/modules/MailChimp/lib';
use lib '/var/www/html/cgi-bin/modules/MailChimp/lib/MailChimp';

use warnings;

use WWW::Curl::Easy;
use JSON;
use Digest::MD5;

use MailChimp::Request;
use MailChimp::Lists;
use MailChimp::Campaigns;
use MailChimp::Templates;
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
    my ( $account ) = @_;

    my $self = bless {
        datacenter => $account->{datacenter},
        url => $account->{url},
        version => $account->{version},
        apikey => $account->{apikey},
    }, $class;

    return $self;
}

sub test {

  my $self = shift;
  my $request = MailChimp::Request->new({account => $self});
  return $request->submit();


}


sub campaigns {

  my $self = shift;
  my $count = shift;
  my $requesttype = 'campaigns';
  if ($count) { $requesttype .= "?count=$count"; }
  my $request = MailChimp::Request->new({account => $self,request=>$requesttype});
  return $request->submit();

}

sub lists {

  my $self = shift;
  my $count = shift;
  my $requesttype = 'lists';
  if ($count) { $requesttype .= "?count=$count"; }
  my $request = MailChimp::Request->new({account => $self,request=>$requesttype});
  return $request->submit();

}

sub templates {

  my $self = shift;
  my $count = shift;
  my $requesttype = 'templates';
  if ($count) { $requesttype .=  "?count=$count"; }
  my $request = MailChimp::Request->new({account => $self,request=>$requesttype});
  return $request->submit();

}


1;
__END__


=head1 NAME

MailChimp - Interface for MailChimp API 3.0

See https://mailchimp.com/developer/marketing/api/

=head1 SYNOPSIS

use MailChimp;

my $account = MailChimp->new({
		username => 'username email',
		datacenter => 'us18',
		version => '3.0',
		url => 'api.mailchimp.com',
		apikey => 'apikey'
});

$account->campaigns();      # List campaigns, etc
$account->templates();
$account->lists();

my $listid = "375520a149";  # Can also be defined using API but I haven't built that in yet
my $template_id = 69461;

	my $campaign = MailChimp::Campaigns->new({
		account => $account,
		type => 'regular',
		recipients => {
		    list_id => $listid
	    },
		settings => {
		    subject_line => 'Test',
		    preview_text => 'Text',
		    title => '',
		    from_name => 'moi',
		    reply_to => $account->{username},
		    to_name => "",
		    folder_id => "",
		    auto_fb_post => [],
		    template_id => $template_id
		},
		content_type => 'template'
	});
  
	$campaign->create();    # I prefer to keep this as an extra step 

	print $campaign->to_string();

  $campaign->add_content({
		html => "Some test HTML content",
		plain_text => "Some test text content"
	});

	$campaign->send();

=head1 DESCRIPTION

Implements a basic campaign creation and send topredefined email list in MailChimp.
Created by Stephen Downes to support the gRSShopper project.

=head2 EXPORT

None by default.

=head1 SEE ALSO

https://grsshopper.downes.ca

=head1 AUTHOR

Stephen Downes <lt>stephen@downes.ca<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 by Stephen Downes

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
