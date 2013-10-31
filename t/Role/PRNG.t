use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    t::Role::TestPRNG
);


my $obj;


# Basic object

ok $obj = t::Role::PRNG->new(), 'Basic object';
isa_ok $obj, 't::Role::PRNG';

is $obj->set_seed(123456), 123456;


done_testing();

