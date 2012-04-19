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

my $epsilon = 8;

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
   -repetitions => 20,
   -sample_size => 1000,
);
is scalar(@{$normalizer->get_average_communities}), 2;
is scalar(@{$normalizer->get_representative_communities}), 2;

is $normalizer->repetitions, 20;
is $normalizer->sample_size, 1000;

$average = $normalizer->get_average_communities->[0];
isa_ok $average, 'Bio::Community';
delta_ok $average->total_count, 1000;
delta_within $average->get_count($member1), 200, $epsilon;
delta_within $average->get_count($member2), 200, $epsilon;
delta_within $average->get_count($member3), 200, $epsilon;
delta_within $average->get_count($member4), 200, $epsilon;
delta_within $average->get_count($member5), 200, $epsilon;

$average = $normalizer->get_average_communities->[1];
isa_ok $average, 'Bio::Community';
delta_ok $average->total_count, 1000;
delta_within $average->get_count($member1), 360.6, $epsilon;
delta_within $average->get_count($member3), 189.3, $epsilon;
delta_within $average->get_count($member6), 450.1, $epsilon;

###
use Data::Dumper;
print Dumper($average);
###

$representative = $normalizer->get_representative_communities->[0];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->total_count, 1000;
delta_ok $representative->get_count($member1), int( $representative->get_count($member1) );
delta_ok $representative->get_count($member2), int( $representative->get_count($member2) );
delta_ok $representative->get_count($member3), int( $representative->get_count($member3) );
delta_ok $representative->get_count($member4), int( $representative->get_count($member4) );
delta_ok $representative->get_count($member5), int( $representative->get_count($member5) );

$representative = $normalizer->get_representative_communities->[1];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->total_count, 1000;
delta_ok $representative->get_count($member1), int( $representative->get_count($member1) );
delta_ok $representative->get_count($member3), int( $representative->get_count($member3) );
delta_ok $representative->get_count($member6), int( $representative->get_count($member6) );


# Normalizer with automatic repetitions
ok $normalizer = Bio::Community::Tools::CountNormalizer->new(
   -communities => [ $community1, $community2 ],
   #-repetitions => , # do repetitions until average does not change anymore
   -sample_size => 1000,
);
is scalar(@{$normalizer->get_average_communities}), 2;
is scalar(@{$normalizer->get_representative_communities}), 2;

is $normalizer->repetitions, 20;
is $normalizer->sample_size, 1000;

###$average = $normalizer->get_average_communities->[0];
###isa_ok $average, 'Bio::Community';
###delta_ok $average->total_count, 1500;
###delta_within $average->get_count($member1), 200, $epsilon;
###delta_within $average->get_count($member2), 200, $epsilon;
###delta_within $average->get_count($member3), 200, $epsilon;
###delta_within $average->get_count($member4), 200, $epsilon;
###delta_within $average->get_count($member5), 200, $epsilon;

###$average = $normalizer->get_average_communities->[1];
###isa_ok $average, 'Bio::Community';
###delta_ok $average->total_count, 1000;
###delta_within $average->get_count($member1), 360.6, $epsilon;
###delta_within $average->get_count($member3), 189.3, $epsilon;
###delta_within $average->get_count($member6), 450.1, $epsilon;

###$representative = $normalizer->get_representative_communities->[0];
###isa_ok $representative, 'Bio::Community';
###delta_ok $representative->total_count, 1000;
###delta_ok $representative->get_count($member1), int( $representative->get_count($member1) );
###delta_ok $representative->get_count($member2), int( $representative->get_count($member2) );
###delta_ok $representative->get_count($member3), int( $representative->get_count($member3) );
###delta_ok $representative->get_count($member4), int( $representative->get_count($member4) );
###delta_ok $representative->get_count($member5), int( $representative->get_count($member5) );

###$representative = $normalizer->get_representative_communities->[1];
###isa_ok $representative, 'Bio::Community';
###delta_ok $representative->total_count, 1000;
###delta_ok $representative->get_count($member1), int( $representative->get_count($member1) );
###delta_ok $representative->get_count($member3), int( $representative->get_count($member3) );
###delta_ok $representative->get_count($member6), int( $representative->get_count($member6) );


# Normalizer with automatic sample size

# special case where repetitions = 0

# Test with some weights


##                 '_counts' => {
##                                '6' => '454.65',
##                                '1' => '357.25',
##                                '3' => '188.1'
## after taking the representative, I get 999 counts instead of 1000


done_testing();

exit;
