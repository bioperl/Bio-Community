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
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'shared'        )->get_distance, 100;


# Communities with all members shared, but different relative abundances

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 3), 49 );

delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '2-norm'        )->get_distance, 0.4438603, 'Communities with all members shared';
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '1-norm'        )->get_distance, 0.7046154;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'infinity-norm' )->get_distance, 0.3523078;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'hellinger'     )->get_distance, 0.3138566;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'bray-curtis'   )->get_distance, 0.3523077;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'shared'        )->get_distance, 100.00000;


# Equally rich communities with some shared members

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 4), 49 );

delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '2-norm'        )->get_distance, 0.4972609, 'Communities with some shared members';
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '1-norm'        )->get_distance, 0.8584615;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'infinity-norm' )->get_distance, 0.3523077;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'hellinger'     )->get_distance, 0.3516165;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'bray-curtis'   )->get_distance, 0.4292308;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'shared'        )->get_distance, 66.666666;


# Unequally rich communities with some shared members

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 52 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 4), 49 );
$community2->add_member( Bio::Community::Member->new(-id => 5), 48 );

delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '2-norm'        )->get_distance, 0.5576910, 'Other communities with some shared members';
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '1-norm'        )->get_distance, 1.0184615;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'infinity-norm' )->get_distance, 0.4323077;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'hellinger'     )->get_distance, 0.3943471;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'bray-curtis'   )->get_distance, 0.5092308;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'shared'        )->get_distance, 66.666666;


# Communities with no shared members

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 4), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 5), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 6), 49 );

delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '2-norm'        )->get_distance, 0.9337472, 'Communities with no shared members';
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '1-norm'        )->get_distance, 2.0000000;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'infinity-norm' )->get_distance, 0.6923077;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'hellinger'     )->get_distance, 0.6602589;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'bray-curtis'   )->get_distance, 1.0000000;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'shared'        )->get_distance, 0.0000000;


# Maximum distance

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 100 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 2), 100 );

delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '2-norm'        )->get_distance, 1.4142136, 'Maximum distance';
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => '1-norm'        )->get_distance, 2.0000000;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'infinity-norm' )->get_distance, 1.0000000;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'hellinger'     )->get_distance, 1.0000000;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'bray-curtis'   )->get_distance, 1.0000000;
delta_ok Bio::Community::Tools::Ruler->new( -communities => [$community1, $community2], -type => 'shared'        )->get_distance, 0.0000000;


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
