use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::Community;
use Bio::Community::Member;

use_ok($_) for qw(
    Bio::Community::Tools::Ruler
);

my ($ruler, $community1, $community2, $community3, $name1, $name2, $name3,
    $average, $distances);


# Identical communities

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 1 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 1 );

ok $ruler = Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '2-norm' );
isa_ok $ruler, 'Bio::Community::Tools::Ruler';

delta_ok $ruler->get_distance, 0, 'Identical communities';
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'euclidean'     )->get_distance, 0;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '1-norm'        )->get_distance, 0;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'infinity-norm' )->get_distance, 0;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'hellinger'     )->get_distance, 0;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'bray-curtis'   )->get_distance, 0;

# Communities with all members shared, but different relative abundances

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 10 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 90 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 3), 50 );

delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '2-norm'        )->get_distance, 0.452910813657838, 'Communities with all members shared';
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '1-norm'        )->get_distance, 0.717948717948718;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'infinity-norm' )->get_distance, 0.358974358974359;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'hellinger'     )->get_distance, 0.3202563;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'bray-curtis'   )->get_distance, 0.3589744;


# Communities with some shared members

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 10 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 90 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 4), 50 );

delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '2-norm'        )->get_distance, 0.816496580927726, 'Communities with some shared members';
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '1-norm'        )->get_distance, 1.38461538461538;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'infinity-norm' )->get_distance, 0.692307692307692;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'hellinger'     )->get_distance, 0.5773503;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'bray-curtis'   )->get_distance, 0.6923077;


# Communities with no shared members

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 10 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 90 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 4), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 5), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 6), 50 );

delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '2-norm'        )->get_distance, 0.933699561847853, 'Communities with no shared members';
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '1-norm'        )->get_distance, 2.00000;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'infinity-norm' )->get_distance, 0.692307692307692;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'hellinger'     )->get_distance, 0.6602253;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'bray-curtis'   )->get_distance, 1.0000000;


# Maximum distance

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 100 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 2), 100 );

delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '2-norm'        )->get_distance, 1.4142136, 'Maximum distance';
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '1-norm'        )->get_distance, 2.00000;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'infinity-norm' )->get_distance, 1.0000000;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'hellinger'     )->get_distance, 1.0;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'bray-curtis'   )->get_distance, 1.0;


# Distance between all pairs

$community3 = Bio::Community->new( -name => 'sample3' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 100 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 100 );
$community2->add_member( Bio::Community::Member->new(-id => 3), 100 );

$name1 = $community1->name;
$name2 = $community2->name;
$name3 = $community3->name;

ok $ruler = Bio::Community::Tools::Ruler->new(
   -communities => [$community1, $community2, $community3],
   -type => 'hellinger',
), 'All pairwise distances';
ok( ($average, $distances) = $ruler->get_all_distances );
delta_ok $distances->{$name1}->{$name2}, 0.6614378;
delta_ok $distances->{$name2}->{$name1}, 0.6614378;
delta_ok $distances->{$name1}->{$name3}, 0.7071068;
delta_ok $distances->{$name3}->{$name1}, 0.7071068;
delta_ok $distances->{$name2}->{$name3}, 0.4330127;
delta_ok $distances->{$name3}->{$name2}, 0.4330127;
delta_ok $average, 0.6005191;


ok $ruler = Bio::Community::Tools::Ruler->new(
   -communities => [],
   -type => '1-norm',
);
ok( ($average, $distances) = $ruler->get_all_distances );
is $average  , undef;
is $distances, undef;


done_testing();

exit;
