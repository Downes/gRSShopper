#!/usr/bin/perl

use strict;
use warnings;


$!++;							# CGI
use CGI qw(header);
use CGI::Carp qw(fatalsToBrowser);
my $query = new CGI;
my $vars = $query->Vars;

use JSON qw(encode_json decode_json);
use Fcntl qw(:flock SEEK_END);

print header('application/json');


use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname(dirname abs_path $0) . '/cgi-bin/modules/Blockchain/lib';
use Blockchain;


#----------------------------------------------------------------------------------------------------------
#
#   gRSShopper Blockchain APIs (because I can't resist playing)
#   Based on Daniel Flymen, Learn Blockchains by Building One
#   https://hackernoon.com/learn-blockchains-by-building-one-117428612f46
#
#----------------------------------------------------------------------------------------------------------


# NEW TRANSACTION
if ($vars->{cmd} eq "transaction") {

	my $blockchain = new Blockchain;
	#die "Missing values in blockchain transaction" unless ($vars->{sender} && $vars->{recipient} && $vars->{amount});
  delete $vars->{cmd};
  my $index = $blockchain->new_transaction($vars);          # So I can store anything I want in this blockchain

#	my $index = $blockchain->new_transaction({
#				sender => $vars->{sender},
#				recipient => $vars->{recipient},
#				amount => $vars->{amount}
#			});
	my $response = {message => "Transaction $index will be added to Block"};

	&blockchain_close($blockchain);

	print encode_json( $response );
	exit;
}

# MINE
elsif ($vars->{cmd} eq "mine") {

	my $blockchain = new Blockchain;
  my $response = $blockchain->mine();
	&blockchain_close($blockchain);
	print encode_json( $response );
	exit;
}


# CHAIN
elsif ($vars->{cmd} eq "chain") {

	my $blockchain = new Blockchain;

	my @chain = $blockchain->{chain};

	my $response = {
			chain => $blockchain->{chain},
			length => scalar @chain,
	};

	&blockchain_close($blockchain);
	print encode_json( $response );
	exit;
}

# REGISTER
elsif ($vars->{cmd} eq "register") {

	# Only registers one node at at time; I'll fix at a future point
	unless ($vars->{node}) { die "Error: Please supply a valid node"; }


	my @nodes;
	push @nodes,$vars->{node};
	my $blockchain = new gRSShopper::Blockchain;

	foreach my $node (@nodes) {
		$blockchain->register_node($node);
	}

	my $response = {
		message => 'New nodes have been added',
		total_nodes => @nodes,
	};

	&blockchain_close($blockchain);
	print encode_json( $response );
	exit;
}

# RESOLVE
elsif ($vars->{cmd} eq "resolve") {

	my $blockchain = new Blockchain;
	my $replaced = $blockchain->resolve_conflicts();
	my $response;

	if ($replaced) {
			$response = {
					message => 'Our chain was replaced',
					new_chain => $blockchain->{chain},
			};
	} else {
			$response = {
					message => 'Our chain is authoritative',
					chain => $blockchain->{chain},
			};
	}
	&blockchain_close($blockchain);
	print encode_json( $response );

	exit;

}

# Save the updated copy of the blockchain to a file

sub blockchain_close {

	my ($blockchain) = @_;

	my $output = ();
	$output->{chain} = $blockchain->{chain};
	$output->{current_transactions} = $blockchain->{current_transactions};
	$output->{nodes} = $blockchain->{nodes};
	my $json_data = encode_json( $output );

	# None of this worked
	# our $JSON = JSON->new->utf8;
	# $JSON->convert_blessed(1);
	# my $json_data = $JSON->encode($blockchain);
	# my $json_data = JSON::to_json($blockchain, { allow_blessed => 1, allow_nonref => 1 });

	my $blockchain_file = "data/blockchain.json";
	open(my $fh, ">$blockchain_file") || die "Could not open $blockchain_file for write";
	flock($fh, LOCK_EX) or die "Cannot lock $blockchain_file - $!\n";
	print $fh $json_data;
	close $fh;

}


 print "Command $vars->{cmd} not recognized.";
 exit;
