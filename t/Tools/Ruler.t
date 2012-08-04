use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::Community;
use Bio::Community::Member;
use Bio::Community::Meta;

use_ok($_) for qw(
    Bio::Community::Tools::Ruler
);

my ($ruler, $meta, $community1, $community2, $community3, $name1, $name2, $name3,
    $average, $distances);


# Identical communities

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 1 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 1 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

ok $ruler = Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'euclidean' );
isa_ok $ruler, 'Bio::Community::Tools::Ruler';

delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '2-norm'        )->get_distance, 0, 'Identical communities';
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '1-norm'        )->get_distance, 0;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_distance, 0;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'hellinger'     )->get_distance, 0;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_distance, 0;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'shared'        )->get_distance, 100;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'permuted'      )->get_distance, 0;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_distance, 0;


# Communities with all members shared and 0% permuted

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 3), 49 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '2-norm'        )->get_distance, 0.4438603, 'Communities with all members shared and 0% permuted';
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '1-norm'        )->get_distance, 0.7046154;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_distance, 0.3523078;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'hellinger'     )->get_distance, 0.3138566;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_distance, 0.3523077;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'shared'        )->get_distance, 100.00000;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'permuted'      )->get_distance, 0;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_distance, 0;


# Communities with all members shared and 100% permuted

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 3), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 1), 49 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '2-norm'        )->get_distance, 0.4619764, 'Communities with all members shared and 100% permuted';
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '1-norm'        )->get_distance, 0.7312821;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_distance, 0.3656410;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'hellinger'     )->get_distance, 0.3266667;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_distance, 0.3656410;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'shared'        )->get_distance, 100.00000;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'permuted'      )->get_distance, 100.00000;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_distance, 0.5000000;


# Other communities with all members shared and 100% permuted

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 3), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 1), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 49 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '2-norm'        )->get_distance, 0.4552674, 'Other Communities with all members shared and 100% permuted';
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '1-norm'        )->get_distance, 0.7179487;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_distance, 0.3589744;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'hellinger'     )->get_distance, 0.3219226;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_distance, 0.3589744;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'shared'        )->get_distance, 100.00000;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'permuted'      )->get_distance, 100.00000;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_distance, 0.5000000;


# Communities with all members shared and 66% permuted

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 2), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 1), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 3), 49 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '2-norm'        )->get_distance, 0.4507392, 'Communities with all members shared and 66% permuted';
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '1-norm'        )->get_distance, 0.7179487;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_distance, 0.3589744;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'hellinger'     )->get_distance, 0.3187207;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_distance, 0.3589744;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'shared'        )->get_distance, 100.00000;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'permuted'      )->get_distance, 66.666667;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_distance, 0.3333333;


# Equally rich communities with some shared members

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 4), 49 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '2-norm'        )->get_distance, 0.4972609, 'Equally rich communities with some shared members';
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '1-norm'        )->get_distance, 0.8584615;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_distance, 0.3523077;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'hellinger'     )->get_distance, 0.3516165;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_distance, 0.4292308;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'shared'        )->get_distance, 66.666666;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'permuted'      )->get_distance, 0;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_distance, 0.3333333;


# Unequally rich communities with some shared members (0% permuted)

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 52 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 4), 49 );
$community2->add_member( Bio::Community::Member->new(-id => 5), 48 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '2-norm'        )->get_distance, 0.5576910, 'Unequally rich communities with some shared members (0% permuted)';
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '1-norm'        )->get_distance, 1.0184615;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_distance, 0.4323077;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'hellinger'     )->get_distance, 0.3943471;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_distance, 0.5092308;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'shared'        )->get_distance, 66.666666;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'permuted'      )->get_distance, 0;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_distance, 0.3333333;


# Other unequally rich communities with some shared members (90% permuted)

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 10), 270 );
$community1->add_member( Bio::Community::Member->new(-id => 1 ),  90 );
$community1->add_member( Bio::Community::Member->new(-id => 2 ),  30 );
$community1->add_member( Bio::Community::Member->new(-id => 3 ),  10 );
$community1->add_member( Bio::Community::Member->new(-id => 4 ),   3 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 3), 53 );
$community2->add_member( Bio::Community::Member->new(-id => 5), 52 );
$community2->add_member( Bio::Community::Member->new(-id => 1), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 6), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 49 );
$community2->add_member( Bio::Community::Member->new(-id => 7), 48 );
$community2->add_member( Bio::Community::Member->new(-id => 4), 47 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '2-norm'        )->get_distance, 0.7433693, 'Unequally rich communities with some shared members (90 % permuted)';
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '1-norm'        )->get_distance, 1.4951719;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_distance, 0.6699752;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'hellinger'     )->get_distance, 0.5256415;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_distance, 0.7475860;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'shared'        )->get_distance, 80.000000;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'permuted'      )->get_distance, 80.000000;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_distance, 0.5200000;


# Communities with no shared members

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 90 );
$community1->add_member( Bio::Community::Member->new(-id => 2), 30 );
$community1->add_member( Bio::Community::Member->new(-id => 3), 10 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 4), 51 );
$community2->add_member( Bio::Community::Member->new(-id => 5), 50 );
$community2->add_member( Bio::Community::Member->new(-id => 6), 49 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '2-norm'        )->get_distance, 0.9337472, 'Communities with no shared members';
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '1-norm'        )->get_distance, 2.0000000;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_distance, 0.6923077;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'hellinger'     )->get_distance, 0.6602589;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_distance, 1.0000000;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'shared'        )->get_distance, 0.0000000;
is       Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'permuted'      )->get_distance, undef;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_distance, 1.0000000;


# Maximum distance (no shared members)

$community1 = Bio::Community->new( -name => 'sample1' );
$community1->add_member( Bio::Community::Member->new(-id => 1), 100 );

$community2 = Bio::Community->new( -name => 'sample2' );
$community2->add_member( Bio::Community::Member->new(-id => 2), 100 );

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );

delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '2-norm'        )->get_distance, 1.4142136, 'Maximum distance';
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => '1-norm'        )->get_distance, 2.0000000;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'infinity-norm' )->get_distance, 1.0000000;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'hellinger'     )->get_distance, 1.0000000;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'bray-curtis'   )->get_distance, 1.0000000;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'shared'        )->get_distance, 0.0000000;
is       Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'permuted'      )->get_distance, undef;
delta_ok Bio::Community::Tools::Ruler->new( -metacommunity => $meta, -type => 'maxiphi'       )->get_distance, 1.0000000;


# Distance between all pairs

$community3 = Bio::Community->new( -name => 'sample3' );
$community2->add_member( Bio::Community::Member->new(-id => 1), 100 );
$community2->add_member( Bio::Community::Member->new(-id => 2), 100 );
$community2->add_member( Bio::Community::Member->new(-id => 3), 100 );

$name1 = $community1->name;
$name2 = $community2->name;
$name3 = $community3->name;

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2, $community3] );

ok $ruler = Bio::Community::Tools::Ruler->new(
   -metacommunity => $meta,
   -type          => 'hellinger',
), 'All pairwise distances';
ok( ($average, $distances) = $ruler->get_all_distances );
delta_ok $average, 0.6005191;
delta_ok $distances->{$name1}->{$name2}, 0.6614378;
delta_ok $distances->{$name2}->{$name1}, 0.6614378;
delta_ok $distances->{$name1}->{$name3}, 0.7071068;
delta_ok $distances->{$name3}->{$name1}, 0.7071068;
delta_ok $distances->{$name2}->{$name3}, 0.4330127;
delta_ok $distances->{$name3}->{$name2}, 0.4330127;



###ok $ruler = Bio::Community::Tools::Ruler->new(
###   -metacommunity => [],
###   -type          => '1-norm',
###);
###ok( ($average, $distances) = $ruler->get_all_distances );
###is $average  , undef;
###is $distances, undef;


done_testing();

exit;
