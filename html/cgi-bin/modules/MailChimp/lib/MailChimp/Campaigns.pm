package MailChimp::Campaigns;

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
    my ( $campaign ) = @_;

    my $self = bless {
        campaign => $campaign->{campaign},
        list => $campaign->{list},
        account => $campaign->{account},
        settings => $campaign->{settings},
        recipients => $campaign->{recipients},
        type => 'regular',
        id => $campaign->{id},
        'content-type' => 'template',
    }, $class;    

    return $self;
}


# Get campaign
# We are referring to a specific MailChimp campaign, get it from MailChimp

sub get {

    my $self = shift;

    if ($self->{id}) {         
        print "Campaign ID: ",$self->{id};
        my $request = MailChimp::Request->new({
            account => $self->{account},
            request=>'campaigns/'.$self->{id}
        });
        my $response = $request->submit();
        while (my ($lx,$ly) = each %$response) {
            $self->{$lx} = $ly;
            }
        
        return $self;
    }
}

sub create {

    my $self = shift;

    # Campaign needs an account and a list before it can be created
    die "Cannot create a campaign without an account" unless ($self->{account});
    die "Cannot create a campaign without specifying a list" unless ($self->{recipients}->{list_id});
 #   die "Cannot create a campaign without specifying a template" unless ($self->{settings}->{template_id});
    die "Cannot create a campaign without an email" unless
        (($self->{settings}->{reply_to}) || ($self->{account}->{email}));

    my $email = $self->{settings}->{reply_to} || $self->{account}->{email};
    my $new_campaign = {
		type => 'regular',
		recipients => {
		    list_id => $self->{recipients}->{list_id}
		},
		settings => {
			subject_line => $self->{settings}->{subject_line},
			preview_text => $self->{settings}->{preview_text},
			title => $self->{settings}->{title},
			from_name => $self->{settings}->{from_name},
			reply_to => $email,
			to_name => "",
			folder_id => "",
			auto_fb_post => [],
			template_id => $self->{settings}->{template_id}
		},
		content_type => 'template'
	};

	use JSON;
	my $json_text = encode_json $new_campaign;

    my $request = MailChimp::Request->new({
        account => $self->{account},
        request=>'campaigns/',
        method => 'POST',
        body => $json_text
    });
    my $response = $request->submit();

    # Store values in campaign object
    while (my ($lx,$ly) = each %$response) {
        print "$lx = $ly <br>";
        if ($lx eq "errors") { foreach my $e (@$ly) { while (my ($ex,$ey) = each %$e) { print $ex = $ey; }}}
        $self->{$lx} = $ly;
    }
    return $self;
}

sub add_content {

    my $self = shift;
    my $data = shift;
 

    die "Campaign must be created (use campaign->create();) on mailchimp before content can be added"
        unless ($self->{id});
    die "Content not defined in add_content()" unless ($data);
    
	# my $id = "fbb57afe8e";	# campaign id
	# my $id = $self->{id};	    # campaign id


	use JSON;
	my $json = encode_json $data;


    my $request = MailChimp::Request->new({
        account => $self->{account},
        request=> sprintf("campaigns/%s/content",$self->{id}),
        method => 'PUT',
        body => $json
    });
    my $response = $request->submit();

}

sub send {

    my $self = shift;
	print "Sending campaign<p>";

    my $request = MailChimp::Request->new({
        account => $self->{account},
        request=> sprintf("campaigns/%s/actions/send",$self->{id}),
        method => 'POST',
    });
    my $response = $request->submit();

		use Data::Dumper;
		print "<pre>";
		print Dumper($response);
			print "</pre>";		
		exit;

}

sub to_string {

    my $self = shift;
    return "Campaign:" . sprintf("%s : %s (%s)",$self->{create_time},$self->{id},$self->{account}->{apikey});

}

1;