package MailChimp::Templates;

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
    my ( $template ) = @_;

    my $self = bless {
        template => $template->{template},
        account => $template->{account},
        id => $template->{id},
    }, $class;    

    return $self;
}

# Get template
# We are referring to a specific MailChimp template, get it from MailChimp

sub get {

    my $self = shift;

    if ($self->{id}) {         
        print "Template ID: ",$self->{id};
        my $request = MailChimp::Request->new({
            account => $self->{account},
            request=>'templates/'.$self->{id}
        });
        my $response = $request->submit();
        while (my ($lx,$ly) = each %$response) {
            $self->{$lx} = $ly;
            }
        
        return $self;
    }
}


sub to_string {

    my $self = shift;
    return "List:" . sprintf("%s %s",$self->{list}->{id},$self->{account}->{datacenter});

}