use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::Community;
use Bio::Community::Meta;

use_ok($_) for qw(
    Bio::Community::Tools::Transformer
);


my ($transformer, $meta, $transformed, $community, $community1, $community2,
    $member1, $member2, $member3, $member4, $member5, $member6);


# Build a metacommunity

$community1 = Bio::Community->new( -name => 'community1' );
$member1 = Bio::Community::Member->new( -id => 1 );
$member2 = Bio::Community::Member->new( -id => 2 );
$member3 = Bio::Community::Member->new( -id => 3 );
$member4 = Bio::Community::Member->new( -id => 4 );
$member5 = Bio::Community::Member->new( -id => 5 );
$member6 = Bio::Community::Member->new( -id => 6 );
$community1->add_member( $member1, 1);
$community1->add_member( $member2, 2);
$community1->add_member( $member3, 3);
$community1->add_member( $member4, 4);
$community1->add_member( $member5, 5);

$community2 = Bio::Community->new( -name => 'community2' );
$member6 = Bio::Community::Member->new( -id => 6 );
$community2->add_member( $member1, 2014);
$community2->add_member( $member3, 1057);
$community2->add_member( $member6, 2514);

$meta = Bio::Community::Meta->new( -communities => [$community1, $community2] );


# Basic transformer object

ok $transformer = Bio::Community::Tools::Transformer->new( );
isa_ok $transformer, 'Bio::Community::Tools::Transformer';


# Identity transformation

ok $transformer = Bio::Community::Tools::Transformer->new(
   -metacommunity => $meta,
   -type          => 'identity',
), 'Identity';

is $transformer->get_transformed_meta->get_communities_count, 2;
is $transformer->type, 'identity';

$transformed = $transformer->get_transformed_meta->get_community_by_name('community1');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community1';
is $transformed->get_members_count, 15;
is $transformed->get_count($member1), 1;
is $transformed->get_count($member2), 2;
is $transformed->get_count($member3), 3;
is $transformed->get_count($member4), 4;
is $transformed->get_count($member5), 5;
is $transformed->get_count($member6), 0;

$transformed = $transformer->get_transformed_meta->get_community_by_name('community2');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community2';
is $transformed->get_members_count, 5585;
is $transformed->get_count($member1), 2014;
is $transformed->get_count($member2),    0;
is $transformed->get_count($member3), 1057;
is $transformed->get_count($member4),    0;
is $transformed->get_count($member5),    0;
is $transformed->get_count($member6), 2514;


# Binary transformation

ok $transformer = Bio::Community::Tools::Transformer->new(
   -metacommunity => $meta,
   -type          => 'binary',
), 'Binary';

is $transformer->get_transformed_meta->get_communities_count, 2;
is $transformer->type, 'binary';

$transformed = $transformer->get_transformed_meta->get_community_by_name('community1');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community1';
is $transformed->get_members_count, 5;
is $transformed->get_count($member1), 1;
is $transformed->get_count($member2), 1;
is $transformed->get_count($member3), 1;
is $transformed->get_count($member4), 1;
is $transformed->get_count($member5), 1;
is $transformed->get_count($member6), 0;


$transformed = $transformer->get_transformed_meta->get_community_by_name('community2');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community2';
is $transformed->get_members_count, 3;
is $transformed->get_count($member1), 1;
is $transformed->get_count($member2), 0;
is $transformed->get_count($member3), 1;
is $transformed->get_count($member4), 0;
is $transformed->get_count($member5), 0;
is $transformed->get_count($member6), 1;


# Hellinger transformation

ok $transformer = Bio::Community::Tools::Transformer->new(
   -metacommunity => $meta,
   -type          => 'hellinger',
), 'Hellinger';

is $transformer->get_transformed_meta->get_communities_count, 2;
is $transformer->type, 'hellinger';

$transformed = $transformer->get_transformed_meta->get_community_by_name('community1');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community1';
delta_ok $transformed->get_members_count, 8.38233234744176;
delta_ok $transformed->get_count($member1), 1;
delta_ok $transformed->get_count($member2), 1.41421356237310;
delta_ok $transformed->get_count($member3), 1.73205080756888;
delta_ok $transformed->get_count($member4), 2;
delta_ok $transformed->get_count($member5), 2.23606797749979;
delta_ok $transformed->get_count($member6), 0;

#$transformed = $transformer->get_transformed_meta->get_community_by_name('community2');
#isa_ok $transformed, 'Bio::Community';
#is $transformed->name, 'community2';
#delta_ok $transformed->get_members_count, 127.528952305538;
#delta_ok $transformed->get_count($member1), 44.877611344633749;
#delta_ok $transformed->get_count($member2), 0;
#delta_ok $transformed->get_count($member3), 32.511536414017719;
#delta_ok $transformed->get_count($member4), 0;
#delta_ok $transformed->get_count($member5), 0;
#delta_ok $transformed->get_count($member6), 50.139804546886701;


# Transformation to total abundance

my $total_abundance = {
   'community1' => 666,
   'community2' => 1e7,
};

ok $transformer = Bio::Community::Tools::Transformer->new(
   -metacommunity   => $meta,
   -type            => 'total',
   -total_abundance => $total_abundance,
), 'Total abundance';

is $transformer->get_transformed_meta->get_communities_count, 2;
is $transformer->type, 'total';

$transformed = $transformer->get_transformed_meta->get_community_by_name('community1');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community1';
delta_ok $transformed->get_members_count, 666.0;
delta_ok $transformed->get_count($member1),  44.4;
delta_ok $transformed->get_count($member2),  88.8;
delta_ok $transformed->get_count($member3), 133.2;
delta_ok $transformed->get_count($member4), 177.6;
delta_ok $transformed->get_count($member5), 222.0;
delta_ok $transformed->get_count($member6),   0.0;

$transformed = $transformer->get_transformed_meta->get_community_by_name('community2');
isa_ok $transformed, 'Bio::Community';
is $transformed->name, 'community2';
delta_ok $transformed->get_members_count, 1e7;
delta_ok $transformed->get_count($member1), 3.60608773500448e+06;
delta_ok $transformed->get_count($member2), 0;
delta_ok $transformed->get_count($member3), 1.89256938227395e+06;
delta_ok $transformed->get_count($member4), 0;
delta_ok $transformed->get_count($member5), 0;
delta_ok $transformed->get_count($member6), 4.50134288272158e+06;


delete $total_abundance->{'community1'};
ok $transformer = Bio::Community::Tools::Transformer->new(
   -metacommunity   => $meta,
   -type            => 'total',
   -total_abundance => $total_abundance,
);

throws_ok { $transformer->get_transformed_meta } qr/EXCEPTION/;


done_testing();

exit;
