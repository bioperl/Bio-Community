use strict;
use warnings;
use Bio::Root::Test;

use Bio::Community;
use Bio::Community::Member;

use_ok($_) for qw(
    Bio::Community::Meta
);

my ($meta, $community1, $community2, $community3, $member1, $member2, $member3);


# Bare object

ok $meta = Bio::Community::Meta->new( ), 'Bare object';
isa_ok $meta, 'Bio::Root::RootI';
isa_ok $meta, 'Bio::Community::Meta';

is $meta->name, 'Unnamed';
is $meta->next_community, undef;

is_deeply [map {ref $_}   @{$meta->get_all_communities}], [];
is_deeply [map {$_->name} @{$meta->get_all_communities}], [];

is $meta->get_community_count, 0;

is_deeply [map {ref $_}   @{$meta->get_all_members}], [];
is_deeply [map {$_->id}   @{$meta->get_all_members}], [];

is $meta->get_richness, 0;


# Basic metacommunity

$member1 = Bio::Community::Member->new( -id => 1 );
$member2 = Bio::Community::Member->new( -id => 2 );
$member3 = Bio::Community::Member->new( -id => 3 );

$community1 = Bio::Community->new( -name => 'GOM' );
$community1->add_member( $member1, 10);
$community1->add_member( $member2, 10);
#community1->add_member( $member3,  0);

$community2 = Bio::Community->new( -name => 'BBC' );
#community2->add_member( $member1,   0);
$community2->add_member( $member2,  10);
$community2->add_member( $member3, 100);

$community3 = Bio::Community->new( -name => 'SAR' );
$community3->add_member( $member1, 25);
#community3->add_member( $member2,  0);
#community3->add_member( $member3,  0);

ok $meta = Bio::Community::Meta->new(
   -communities => [$community1],
   -name        => 'oceanic provinces'
), 'Basic metacommunity';
is $meta->name, 'oceanic provinces';
ok $meta->name('marine regions');
is $meta->name, 'marine regions';

is $meta->next_community->name, 'GOM';
is $meta->next_community, undef;

is_deeply [map {ref $_}   @{$meta->get_all_communities}], ['Bio::Community'];
is_deeply [map {$_->name} @{$meta->get_all_communities}], ['GOM'];

is $meta->get_community_count, 1;

is_deeply [map {ref $_}   @{$meta->get_all_members}], ['Bio::Community::Member', 'Bio::Community::Member'];
is_deeply [map {$_->id}   @{$meta->get_all_members}], [1, 2];

is $meta->get_richness, 2;

is $meta->get_member_count, 20;


# Add communities

ok $meta->add_communities([$community2, $community3]), 'Add communities';

is $meta->next_community->name, 'GOM';
is $meta->next_community->name, 'BBC';
is $meta->next_community->name, 'SAR';
is $meta->next_community, undef;

is_deeply [map {ref $_}   @{$meta->get_all_communities}], ['Bio::Community', 'Bio::Community', 'Bio::Community'];
is_deeply [map {$_->name} @{$meta->get_all_communities}], ['GOM', 'BBC', 'SAR'];

is $meta->get_community_count, 3;

is_deeply [map {ref $_}   @{$meta->get_all_members}], ['Bio::Community::Member', 'Bio::Community::Member', 'Bio::Community::Member'];
is_deeply [sort {$a <=> $b} (map {$_->id} @{$meta->get_all_members})], [1, 2, 3];

is $meta->get_richness, 3;

is $meta->get_member_count, 155;


# Remove communities

ok $meta->remove_community($community2), 'Remove communities';

is $meta->next_community->name, 'GOM';
is $meta->next_community->name, 'SAR';
is $meta->next_community, undef;

is_deeply [map {ref $_}   @{$meta->get_all_communities}], ['Bio::Community', 'Bio::Community'];
is_deeply [map {$_->name} @{$meta->get_all_communities}], ['GOM', 'SAR'];

is $meta->get_community_by_name('SAR')->name, 'SAR';
is $meta->get_community_by_name('BBC'), undef;
is $meta->get_community_by_name('GOM')->name, 'GOM';

is $meta->get_community_count, 2;

is_deeply [map {ref $_}   @{$meta->get_all_members}], ['Bio::Community::Member', 'Bio::Community::Member'];
is_deeply [sort {$a <=> $b} (map {$_->id} @{$meta->get_all_members})], [1, 2];

is $meta->get_richness, 2;

is $meta->get_member_count, 45;


done_testing();

exit;
