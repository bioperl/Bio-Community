use strict;
use warnings;
use Bio::Root::Test;

use Bio::Community::IO;

use_ok($_) for qw(
    Bio::Community::Meta::Gamma
);


my ($gamma, $meta);


# Metacommunity for which to measure gamma diversity

$meta = Bio::Community::IO->new(
   -file => test_input_file('generic_table.txt'),
)->next_metacommunity;


# Basic object

$gamma = Bio::Community::Meta::Gamma->new( -metacommunity => $meta, -type => 'observed' );
isa_ok $gamma, 'Bio::Community::Meta::Gamma';


# Test metrics

is Bio::Community::Meta::Gamma->new( -metacommunity => $meta, -type => 'observed' )->get_gamma, 3;

# TODO: Should have a method that tests all the methods that Bio::Community::Alpha has


done_testing();

exit;
