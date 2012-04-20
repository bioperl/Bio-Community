use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::Community;

use_ok($_) for qw(
    Bio::Community::Tools::CountNormalizer
);


my ($normalizer, $community1, $community2, $average, $representative, $member1,
   $member2, $member3, $member4, $member5, $member6);

my $epsilon = 15;


# Community with 1500 counts

$community1 = Bio::Community->new( -name => 'community1' );
$member1 = Bio::Community::Member->new( -id => 1 );
$member2 = Bio::Community::Member->new( -id => 2 );
$member3 = Bio::Community::Member->new( -id => 3 );
$member4 = Bio::Community::Member->new( -id => 4 );
$member5 = Bio::Community::Member->new( -id => 5 );
$community1->add_member( $member1, 300);
$community1->add_member( $member2, 300);
$community1->add_member( $member3, 300);
$community1->add_member( $member4, 300);
$community1->add_member( $member5, 300);


# Community with 5585 counts

$community2 = Bio::Community->new( -name => 'community1' );
$member1 = Bio::Community::Member->new( -id => 1 );
$member3 = Bio::Community::Member->new( -id => 3 );
$member6 = Bio::Community::Member->new( -id => 6 );
$community2->add_member( $member1, 2014);
$community2->add_member( $member3, 1057);
$community2->add_member( $member6, 2514);


# Basic normalizer object

ok $normalizer = Bio::Community::Tools::CountNormalizer->new( );
isa_ok $normalizer, 'Bio::Community::Tools::CountNormalizer';


# Normalizer with specified settings

ok $normalizer = Bio::Community::Tools::CountNormalizer->new(
   -communities => [ $community1, $community2 ],
   -repetitions => 10,
   -sample_size => 1000,
);
is scalar(@{$normalizer->get_average_communities}), 2;
is scalar(@{$normalizer->get_representative_communities}), 2;

is $normalizer->repetitions, 10;
isnt $normalizer->threshold, 0.1;
cmp_ok $normalizer->threshold, '<', 1;
is $normalizer->sample_size, 1000;

$average = $normalizer->get_average_communities->[0];
isa_ok $average, 'Bio::Community';
delta_ok $average->total_count, 1000;
delta_within $average->get_count($member1), 200, $epsilon;
delta_within $average->get_count($member2), 200, $epsilon;
delta_within $average->get_count($member3), 200, $epsilon;
delta_within $average->get_count($member4), 200, $epsilon;
delta_within $average->get_count($member5), 200, $epsilon;

$representative = $normalizer->get_representative_communities->[0];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->total_count, 1000;
delta_within $representative->get_count($member1), $average->get_count($member1), 1;
delta_within $representative->get_count($member2), $average->get_count($member2), 1;
delta_within $representative->get_count($member3), $average->get_count($member3), 1;
delta_within $representative->get_count($member4), $average->get_count($member4), 1;
delta_within $representative->get_count($member5), $average->get_count($member5), 1;

$average = $normalizer->get_average_communities->[1];
isa_ok $average, 'Bio::Community';
delta_ok $average->total_count, 1000;
delta_within $average->get_count($member1), 360.6, $epsilon;
delta_within $average->get_count($member3), 189.3, $epsilon;
delta_within $average->get_count($member6), 450.1, $epsilon;

$representative = $normalizer->get_representative_communities->[1];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->total_count, 1000;
delta_within $representative->get_count($member1), $representative->get_count($member1), 1;
delta_within $representative->get_count($member3), $representative->get_count($member3), 1;
delta_within $representative->get_count($member6), $representative->get_count($member6), 1;


# Normalizer with manually specified threshold

ok $normalizer = Bio::Community::Tools::CountNormalizer->new(
   -communities => [ $community1, $community2 ],
   -threshold   => 1E-1,
   -sample_size => 1000,
);
is scalar(@{$normalizer->get_average_communities}), 2;
is scalar(@{$normalizer->get_representative_communities}), 2;

cmp_ok $normalizer->repetitions, '>=', 3;
is $normalizer->threshold, 0.1;
is $normalizer->sample_size, 1000;

$average = $normalizer->get_average_communities->[0];
isa_ok $average, 'Bio::Community';
delta_ok $average->total_count, 1000;
delta_within $average->get_count($member1), 200, $epsilon;
delta_within $average->get_count($member2), 200, $epsilon;
delta_within $average->get_count($member3), 200, $epsilon;
delta_within $average->get_count($member4), 200, $epsilon;
delta_within $average->get_count($member5), 200, $epsilon;

$representative = $normalizer->get_representative_communities->[0];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->total_count, 1000;
delta_within $representative->get_count($member1), $average->get_count($member1), 1;
delta_within $representative->get_count($member2), $average->get_count($member2), 1;
delta_within $representative->get_count($member3), $average->get_count($member3), 1;
delta_within $representative->get_count($member4), $average->get_count($member4), 1;
delta_within $representative->get_count($member5), $average->get_count($member5), 1;

$average = $normalizer->get_average_communities->[1];
isa_ok $average, 'Bio::Community';
delta_ok $average->total_count, 1000;
delta_within $average->get_count($member1), 360.6, $epsilon;
delta_within $average->get_count($member3), 189.3, $epsilon;
delta_within $average->get_count($member6), 450.1, $epsilon;

$representative = $normalizer->get_representative_communities->[1];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->total_count, 1000;
delta_within $representative->get_count($member1), $average->get_count($member1), 1;
delta_within $representative->get_count($member3), $average->get_count($member3), 1;
delta_within $representative->get_count($member6), $average->get_count($member6), 1;


# Normalizer with automatic sample size and repetitions overriding threshold

ok $normalizer = Bio::Community::Tools::CountNormalizer->new(
   -communities => [ $community1, $community2 ],
   -threshold   => 1E-1,
   -repetitions => 10,
);
is scalar(@{$normalizer->get_average_communities}), 2;
is scalar(@{$normalizer->get_representative_communities}), 2;

is $normalizer->repetitions, 10;
isnt $normalizer->threshold, 0.1;
cmp_ok $normalizer->threshold, '<', 1;
is $normalizer->sample_size, 1500;

$average = $normalizer->get_average_communities->[0];
isa_ok $average, 'Bio::Community';
delta_ok $average->total_count, 1500;
delta_within $average->get_count($member1), 300, $epsilon;
delta_within $average->get_count($member2), 300, $epsilon;
delta_within $average->get_count($member3), 300, $epsilon;
delta_within $average->get_count($member4), 300, $epsilon;
delta_within $average->get_count($member5), 300, $epsilon;

$representative = $normalizer->get_representative_communities->[0];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->total_count, 1500;
delta_within $representative->get_count($member1), $average->get_count($member1), 1;
delta_within $representative->get_count($member2), $average->get_count($member2), 1;
delta_within $representative->get_count($member3), $average->get_count($member3), 1;
delta_within $representative->get_count($member4), $average->get_count($member4), 1;
delta_within $representative->get_count($member5), $average->get_count($member5), 1;

$average = $normalizer->get_average_communities->[1];
isa_ok $average, 'Bio::Community';
delta_ok $average->total_count, 1500;
delta_within $average->get_count($member1), 540.9, $epsilon;
delta_within $average->get_count($member3), 283.9, $epsilon;
delta_within $average->get_count($member6), 675.2, $epsilon;

$representative = $normalizer->get_representative_communities->[1];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->total_count, 1500;
delta_within $representative->get_count($member1), $average->get_count($member1), 1;
delta_within $representative->get_count($member3), $average->get_count($member3), 1;
delta_within $representative->get_count($member6), $average->get_count($member6), 1;


# Special case where repetitions = 0

##ok $normalizer = Bio::Community::Tools::CountNormalizer->new(
##   -communities => [ $community1, $community2 ],
##   -threshold   => 1E-1,
##   -repetitions => 0,
##);


### Test with some weights


##                 '_counts' => {
##                                '6' => '454.65',
##                                '1' => '357.25',
##                                '3' => '188.1'
## after taking the representative, I get 999 counts instead of 1000


done_testing();

exit;
