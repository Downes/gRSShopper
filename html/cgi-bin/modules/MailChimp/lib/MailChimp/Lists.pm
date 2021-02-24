package MailChimp::Lists;

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
    my ( $list ) = @_;

    my $self = bless {
        list => $list->{list},
        account => $list->{account},
        id => $list->{id},
    }, $class;    

    print "List ID: ",$self->{list}->{id};
    my $request = MailChimp::Request->new({
        account => $self->{account},
        request=>'lists/'.$self->{list}->{id}
    });
    my $response = $request->submit();
    while (my ($lx,$ly) = each %$response) {
         $self->{$lx} = $ly;
        }

    return $self;
}

sub to_string {

    my $self = shift;
    return "List:" . sprintf("%s %s",$self->{list}->{id},$self->{account}->{datacenter});

}