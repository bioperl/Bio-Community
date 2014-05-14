use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;

use_ok($_) for qw(
    Bio::Community::Tools::Accumulator
);


my ($accumulator);


# Basic object

ok $accumulator = Bio::Community::Tools::Accumulator->new( );
isa_ok $accumulator, 'Bio::Community::Tools::Accumulator';
throws_ok { $accumulator->get_curve } qr/EXCEPTION.*metacommunity/msi;


done_testing();

exit;
