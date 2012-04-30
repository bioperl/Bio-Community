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

my $epsilon1 = 15;
my $epsilon2 = 1.00000000001;
my $epsilon3 = 0.4;


# Community with 1500 counts

$community1 = Bio::Community->new( -name => 'community1' );
$member1 = Bio::Community::Member->new( -id => 1 );
$member2 = Bio::Community::Member->new( -id => 2 );
$member3 = Bio::Community::Member->new( -id => 3 );
$member4 = Bio::Community::Member->new( -id => 4 );
$member5 = Bio::Community::Member->new( -id => 5 );
$community1->add_member( $member1, 301);
$community1->add_member( $member2, 300);
$community1->add_member( $member3, 300);
$community1->add_member( $member4, 300);
$community1->add_member( $member5, 299);


# Community with 5585 counts

$community2 = Bio::Community->new( -name => 'community2' );
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
   -verbose     => 1,
);

is scalar(@{$normalizer->get_average_communities}), 2;
is scalar(@{$normalizer->get_representative_communities}), 2;

is $normalizer->repetitions, 10;
isnt $normalizer->threshold, 0.1;
cmp_ok $normalizer->threshold, '<', 1;
is $normalizer->sample_size, 1000;
is $normalizer->verbose, 1;

$average = $normalizer->get_average_communities->[0];
isa_ok $average, 'Bio::Community';
delta_ok $average->get_total_count, 1000;
delta_within $average->get_count($member1), 200.7, $epsilon1;
delta_within $average->get_count($member2), 200.0, $epsilon1;
delta_within $average->get_count($member3), 200.0, $epsilon1;
delta_within $average->get_count($member4), 200.0, $epsilon1;
delta_within $average->get_count($member5), 199.3, $epsilon1;

$representative = $normalizer->get_representative_communities->[0];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->get_total_count, 1000;
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member2), $average->get_count($member2), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member4), $average->get_count($member4), $epsilon2;
delta_within $representative->get_count($member5), $average->get_count($member5), $epsilon2;

$average = $normalizer->get_average_communities->[1];
isa_ok $average, 'Bio::Community';
delta_ok $average->get_total_count, 1000;
delta_within $average->get_count($member1), 360.6, $epsilon1;
delta_within $average->get_count($member3), 189.3, $epsilon1;
delta_within $average->get_count($member6), 450.1, $epsilon1;

$representative = $normalizer->get_representative_communities->[1];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->get_total_count, 1000;
delta_within $representative->get_count($member1), $representative->get_count($member1), $epsilon2;
delta_within $representative->get_count($member3), $representative->get_count($member3), $epsilon2;
delta_within $representative->get_count($member6), $representative->get_count($member6), $epsilon2;


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
delta_ok $average->get_total_count, 1000;
delta_within $average->get_count($member1), 200.7, $epsilon1;
delta_within $average->get_count($member2), 200.0, $epsilon1;
delta_within $average->get_count($member3), 200.0, $epsilon1;
delta_within $average->get_count($member4), 200.0, $epsilon1;
delta_within $average->get_count($member5), 199.3, $epsilon1;

$representative = $normalizer->get_representative_communities->[0];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->get_total_count, 1000;
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member2), $average->get_count($member2), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member4), $average->get_count($member4), $epsilon2;
delta_within $representative->get_count($member5), $average->get_count($member5), $epsilon2;

$average = $normalizer->get_average_communities->[1];
isa_ok $average, 'Bio::Community';
delta_ok $average->get_total_count, 1000;
delta_within $average->get_count($member1), 360.6, $epsilon1;
delta_within $average->get_count($member3), 189.3, $epsilon1;
delta_within $average->get_count($member6), 450.1, $epsilon1;

$representative = $normalizer->get_representative_communities->[1];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->get_total_count, 1000;
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member6), $average->get_count($member6), $epsilon2;


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
delta_ok $average->get_total_count, 1500;
delta_within $average->get_count($member1), 301, $epsilon1;
delta_within $average->get_count($member2), 300, $epsilon1;
delta_within $average->get_count($member3), 300, $epsilon1;
delta_within $average->get_count($member4), 300, $epsilon1;
delta_within $average->get_count($member5), 299, $epsilon1;

$representative = $normalizer->get_representative_communities->[0];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->get_total_count, 1500;
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member2), $average->get_count($member2), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member4), $average->get_count($member4), $epsilon2;
delta_within $representative->get_count($member5), $average->get_count($member5), $epsilon2;

$average = $normalizer->get_average_communities->[1];
isa_ok $average, 'Bio::Community';
delta_ok $average->get_total_count, 1500;
delta_within $average->get_count($member1), 540.9, $epsilon1;
delta_within $average->get_count($member3), 283.9, $epsilon1;
delta_within $average->get_count($member6), 675.2, $epsilon1;

$representative = $normalizer->get_representative_communities->[1];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->get_total_count, 1500;
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member6), $average->get_count($member6), $epsilon2;


# Normalizer with sample that should exclude some members from representative

ok $normalizer = Bio::Community::Tools::CountNormalizer->new(
   -communities => [ $community1, $community2 ],
   -repetitions => 50,
   -sample_size => 4,
);
is scalar(@{$normalizer->get_average_communities}), 2;
is scalar(@{$normalizer->get_representative_communities}), 2;

is $normalizer->repetitions, 50;
isnt $normalizer->threshold, 0.1;
cmp_ok $normalizer->threshold, '<', 10;
is $normalizer->sample_size, 4;

$average = $normalizer->get_average_communities->[0];
isa_ok $average, 'Bio::Community';
delta_ok $average->get_total_count, 4;
delta_ok $average->get_richness, 5;
delta_within $average->get_count($member1), 0.803, $epsilon3;
delta_within $average->get_count($member2), 0.800, $epsilon3;
delta_within $average->get_count($member3), 0.800, $epsilon3;
delta_within $average->get_count($member4), 0.800, $epsilon3;
delta_within $average->get_count($member5), 0.797, $epsilon3;

$representative = $normalizer->get_representative_communities->[0];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->get_total_count, 4;
cmp_ok $representative->get_richness, '<=', 4; # statistically, one member should disappear
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member2), $average->get_count($member2), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member4), $average->get_count($member4), $epsilon2;
delta_within $representative->get_count($member5), $average->get_count($member5), $epsilon2;

$average = $normalizer->get_average_communities->[1];
isa_ok $average, 'Bio::Community';
delta_ok $average->get_total_count, 4;
delta_ok $average->get_richness, 3;
delta_within $average->get_count($member1), 1.44 , $epsilon3;
delta_within $average->get_count($member3), 0.757, $epsilon3;
delta_within $average->get_count($member6), 1.801, $epsilon3;

$representative = $normalizer->get_representative_communities->[1];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->get_total_count, 4;
cmp_ok $representative->get_richness, '<=', 3;
delta_within $representative->get_count($member1), $representative->get_count($member1), $epsilon2;
delta_within $representative->get_count($member3), $representative->get_count($member3), $epsilon2;
delta_within $representative->get_count($member6), $representative->get_count($member6), $epsilon2;


# Normalizer with sample that should exclude some members from representative

ok $normalizer = Bio::Community::Tools::CountNormalizer->new(
   -communities => [ $community1, $community2 ],
   -repetitions => 50,
   -sample_size => 4,
);
is scalar(@{$normalizer->get_average_communities}), 2;
is scalar(@{$normalizer->get_representative_communities}), 2;

is $normalizer->repetitions, 50;
isnt $normalizer->threshold, 0.1;
cmp_ok $normalizer->threshold, '<', 10;
is $normalizer->sample_size, 4;

$average = $normalizer->get_average_communities->[0];
isa_ok $average, 'Bio::Community';
delta_ok $average->get_total_count, 4;
delta_ok $average->get_richness, 5;
delta_within $average->get_count($member1), 0.803, $epsilon3;
delta_within $average->get_count($member2), 0.800, $epsilon3;
delta_within $average->get_count($member3), 0.800, $epsilon3;
delta_within $average->get_count($member4), 0.800, $epsilon3;
delta_within $average->get_count($member5), 0.797, $epsilon3;

$representative = $normalizer->get_representative_communities->[0];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->get_total_count, 4;
cmp_ok $representative->get_richness, '<=', 4;  # statistically, one member should disappear
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member2), $average->get_count($member2), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member4), $average->get_count($member4), $epsilon2;
delta_within $representative->get_count($member5), $average->get_count($member5), $epsilon2;

$average = $normalizer->get_average_communities->[1];
isa_ok $average, 'Bio::Community';
delta_ok $average->get_total_count, 4;
delta_ok $average->get_richness, 3;
delta_within $average->get_count($member1), 1.44 , $epsilon3;
delta_within $average->get_count($member3), 0.757, $epsilon3;
delta_within $average->get_count($member6), 1.801, $epsilon3;

$representative = $normalizer->get_representative_communities->[1];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->get_total_count, 4;
cmp_ok $representative->get_richness, '<=', 3;
delta_within $representative->get_count($member1), $representative->get_count($member1), $epsilon2;
delta_within $representative->get_count($member3), $representative->get_count($member3), $epsilon2;
delta_within $representative->get_count($member6), $representative->get_count($member6), $epsilon2;


# Representative of a specific average community

ok $normalizer = Bio::Community::Tools::CountNormalizer->new( );

$average = Bio::Community->new( -name => 'average' );
$average->add_member( $member1, 1.1);
$average->add_member( $member2, 1.2);
$average->add_member( $member3, 0.8);
$average->add_member( $member4, 0.9);

delta_ok $average->get_richness, 4;
delta_ok $average->get_total_count, 4;

ok $representative = $normalizer->_calc_representative($average);

delta_ok $representative->get_total_count, 4;
delta_ok $representative->get_richness, 4;
delta_ok $representative->get_count($member1), 1;
delta_ok $representative->get_count($member2), 1;
delta_ok $representative->get_count($member3), 1;
delta_ok $representative->get_count($member4), 1;


# Representative of an average community (decrement of last member needed)

ok $normalizer = Bio::Community::Tools::CountNormalizer->new( );

$average = Bio::Community->new( -name => 'average' );
$average->add_member( $member1, 1.2);
$average->add_member( $member2, 0.7);
$average->add_member( $member3, 0.6);
$average->add_member( $member4, 0.5);

delta_ok $average->get_richness, 4;
delta_ok $average->get_total_count, 3;

ok $representative = $normalizer->_calc_representative($average);

delta_ok $representative->get_total_count, 3;
delta_ok $representative->get_richness, 3;
delta_ok $representative->get_count($member1), 1;
delta_ok $representative->get_count($member2), 1;
delta_ok $representative->get_count($member3), 1;
delta_ok $representative->get_count($member4), 0;


# Representative of an average community (increment of last member needed)

ok $normalizer = Bio::Community::Tools::CountNormalizer->new( );

$average = Bio::Community->new( -name => 'average' );
$average->add_member( $member1, 2.3);
$average->add_member( $member2, 2.2);
$average->add_member( $member3, 2.1);
$average->add_member( $member4, 0.4);

delta_ok $average->get_richness, 4;
delta_ok $average->get_total_count, 7;

ok $representative = $normalizer->_calc_representative($average);

delta_ok $representative->get_total_count, 7;
delta_ok $representative->get_richness, 4;
delta_ok $representative->get_count($member1), 2;
delta_ok $representative->get_count($member2), 2;
delta_ok $representative->get_count($member3), 2;
delta_ok $representative->get_count($member4), 1;


# Representative of an average community (increment of before last member needed)

ok $normalizer = Bio::Community::Tools::CountNormalizer->new( );

$average = Bio::Community->new( -name => 'average' );
$average->add_member( $member1, 1.471);
$average->add_member( $member2, 1.040);
$average->add_member( $member3, 0.246);
$average->add_member( $member4, 0.243);

delta_ok $average->get_richness, 4;
delta_ok $average->get_total_count, 3;

ok $representative = $normalizer->_calc_representative($average);

delta_ok $representative->get_total_count, 3;
delta_ok $representative->get_richness, 3;
delta_ok $representative->get_count($member1), 1;
delta_ok $representative->get_count($member2), 1;
delta_ok $representative->get_count($member3), 1;
delta_ok $representative->get_count($member4), 0;


# Using weights should yield same results since we operate on counts (not relative abundance)

$community1 = Bio::Community->new( -name => 'community1' );
$member1 = Bio::Community::Member->new( -id => 1, -weights => [8] );
$member2 = Bio::Community::Member->new( -id => 2, -weights => [3] );
$member3 = Bio::Community::Member->new( -id => 3, -weights => [15] );
$member4 = Bio::Community::Member->new( -id => 4, -weights => [7] );
$member5 = Bio::Community::Member->new( -id => 5, -weights => [2] );
$community1->add_member( $member1, 301);
$community1->add_member( $member2, 300);
$community1->add_member( $member3, 300);
$community1->add_member( $member4, 300);
$community1->add_member( $member5, 299);

$community2 = Bio::Community->new( -name => 'community2' );
$member6 = Bio::Community::Member->new( -id => 10 );
$community2->add_member( $member1, 2014);
$community2->add_member( $member3, 1057);
$community2->add_member( $member6, 2514);

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
delta_ok $average->get_total_count, 1000;
delta_within $average->get_count($member1), 200.7, $epsilon1;
delta_within $average->get_count($member2), 200.0, $epsilon1;
delta_within $average->get_count($member3), 200.0, $epsilon1;
delta_within $average->get_count($member4), 200.0, $epsilon1;
delta_within $average->get_count($member5), 199.3, $epsilon1;

$representative = $normalizer->get_representative_communities->[0];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->get_total_count, 1000;
delta_within $representative->get_count($member1), $average->get_count($member1), $epsilon2;
delta_within $representative->get_count($member2), $average->get_count($member2), $epsilon2;
delta_within $representative->get_count($member3), $average->get_count($member3), $epsilon2;
delta_within $representative->get_count($member4), $average->get_count($member4), $epsilon2;
delta_within $representative->get_count($member5), $average->get_count($member5), $epsilon2;

$average = $normalizer->get_average_communities->[1];
isa_ok $average, 'Bio::Community';
delta_ok $average->get_total_count, 1000;
delta_within $average->get_count($member1), 360.6, $epsilon1;
delta_within $average->get_count($member3), 189.3, $epsilon1;
delta_within $average->get_count($member6), 450.1, $epsilon1;

$representative = $normalizer->get_representative_communities->[1];
isa_ok $representative, 'Bio::Community';
delta_ok $representative->get_total_count, 1000;
delta_within $representative->get_count($member1), $representative->get_count($member1), $epsilon2;
delta_within $representative->get_count($member3), $representative->get_count($member3), $epsilon2;
delta_within $representative->get_count($member6), $representative->get_count($member6), $epsilon2;


done_testing();

exit;
