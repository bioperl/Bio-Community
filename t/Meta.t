use strict;
use warnings;
use Bio::Root::Test;

use Bio::Community;
use Bio::Community::Member;

use_ok($_) for qw(
    Bio::Community::Meta
);

my ($meta, $community1, $community2, $community3, $member1, $member2, $member3);


# Basic

ok $meta = Bio::Community::Meta->new( -name => 'basic' );
isa_ok $meta, 'Bio::Root::RootI';
isa_ok $meta, 'Bio::Community::Meta';


# Add 3 communities to a metacommunity

$member1 = Bio::Community::Member->new( );
$member2 = Bio::Community::Member->new( );
$member3 = Bio::Community::Member->new( );

$community1 = Bio::Community->new( -name => 'GOM' );
$community1->add_member( $member1, 10);
$community1->add_member( $member2, 10);
$community1->add_member( $member3,  0);

$community2 = Bio::Community->new( -name => 'BBC' );
$community2->add_member( $member1,   0);
$community2->add_member( $member2,  10);
$community2->add_member( $member3, 100);

$community3 = Bio::Community->new( -name => 'SAR' );
$community3->add_member( $member1, 25);
$community3->add_member( $member2,  0);
$community3->add_member( $member3,  0);

ok $meta = Bio::Community::Meta->new( -communities => [$community1] );
is $meta->name, 'Unnamed metacommunity';
ok $meta->name('marine regions');
is $meta->name, 'marine regions';

is $meta->next_community->name, 'GOM';
is $meta->next_community, undef;

is_deeply [map {ref $_}   @{$meta->get_all_communities}], ['Bio::Community'];
is_deeply [map {$_->name} @{$meta->get_all_communities}], ['GOM'];

ok $meta->add_communities([$community2, $community3]);

is $meta->next_community->name, 'GOM';
is $meta->next_community->name, 'BBC';
is $meta->next_community->name, 'SAR';
is $meta->next_community, undef;

is_deeply [map {ref $_}   @{$meta->get_all_communities}], ['Bio::Community', 'Bio::Community', 'Bio::Community'];
is_deeply [map {$_->name} @{$meta->get_all_communities}], ['GOM', 'BBC', 'SAR'];




#ok $community->add_member( $member2, 23 );
#is $community->get_total_count, 24;


#ok $community->add_member( $member3, 4 );
#is $community->get_total_count, 28;

#isa_ok $community->get_member_by_id(2), 'Bio::Community::Member';
#is $community->get_member_by_id(2)->id, 2;

#is $community->get_count($member2), 23;
#is $community->get_count($member3), 4;
#is $community->get_count($member1), 1;

#is $community->get_rank($member2), 1;
#is $community->get_rank($member3), 2;
#is $community->get_rank($member1), 3;

#is $community->get_member_by_rank(1)->id, 2;
#is $community->get_member_by_rank(2)->id, 3;
#is $community->get_member_by_rank(3)->id, 1;
#is $community->get_member_by_rank(4), undef;

#while (my $member = $community->next_member) {
#   isa_ok $member, 'Bio::Community::Member';
#   $ids{$member->id} = undef;
#}
#is_deeply [sort keys %ids], [1, 2, 3];

#is $community->get_richness, 3;

#%ids = ();
#ok @members = @{$community->get_all_members};
#for my $member (@members) {
#   isa_ok $member, 'Bio::Community::Member';
#   $ids{$member->id} = undef;
#}
#is_deeply [sort keys %ids], [1, 2, 3];


## Remove a member from the community

#ok $community->remove_member( $member2, 5 );
#is $community->get_total_count, 23;

#ok $community->remove_member( $member2 ); # remove all of it
#is $community->get_total_count, 5;

#ok $community->remove_member( $member2 ); # remove already removed member

#is $community->get_member_by_id(2), undef;
#is $community->get_count($member2), 0;

#@members = ();
#%ids = ();
#ok @members = @{$community->get_all_members};
#for my $member (@members) {
#   $ids{$member->id} = undef;
#}
#is_deeply [sort keys %ids], [1, 3];

#is $community->get_richness, 2;

#is $community->name, 'Unnamed community';
#ok $community->name('ocean sample 3');
#is $community->name, 'ocean sample 3';

#is $community->use_weights, 0;

#is $community->get_count($member3), 4;
#is $community->get_count($member1), 1;
#is $community->get_count($member2), 0;

#is $community->get_rank($member3), 1;
#is $community->get_rank($member1), 2;
#is $community->get_rank($member2), undef;

#is $community->get_member_by_rank(1)->id, 3;
#is $community->get_member_by_rank(2)->id, 1;
#is $community->get_member_by_rank(3), undef;

#for my $member (@{$community->get_all_members}) {
#   $rel_abs{$member->id} = $community->get_rel_ab($member);
#}
#is_deeply \%rel_abs, { 1 => 20, 3 => 80 };

#ok $community->use_weights(1);
#is $community->use_weights, 1;

#for my $member (@{$community->get_all_members}) {
#   $rel_abs{$member->id} = $community->get_rel_ab($member);
#}
#is_deeply \%rel_abs, { 1 => 53.846153846154, 3 => 46.1538461538463 };

#is $community->get_member_by_rank(1)->id, 1;
#is $community->get_member_by_rank(2)->id, 3;


## Get all the members from multiple communities

#ok $community = Bio::Community->new();
#ok $community->add_member($member1);
#ok $community->add_member($member2);
#ok $community->add_member($member3);

#ok $community2 = Bio::Community->new();
#ok $community2->add_member($member3);
#ok $member4 = Bio::Community::Member->new( -id => 'asdf' );
#ok $community2->add_member($member4);

#ok $community3 = Bio::Community->new();
#ok $community3->add_member( Bio::Community::Member->new( -id => 3) );
#ok $member5 = Bio::Community::Member->new();
#ok $community3->add_member($member5);

#ok @members = @{$community2->get_all_members([$community, $community3])};
#is scalar(@members), 5;

#%members = map { $_->id => undef } @members;
#ok exists $members{$member1->id};
#ok exists $members{$member2->id};
#ok exists $members{$member3->id};
#ok exists $members{$member4->id};
#ok exists $members{$member5->id};

#ok @members = @{$community2->get_all_members([$community, $community2, $community3])};
#is scalar(@members), 5;

#%members = map { $_->id => undef } @members;
#ok exists $members{$member1->id};
#ok exists $members{$member2->id};
#ok exists $members{$member3->id};
#ok exists $members{$member4->id};
#ok exists $members{$member5->id};


## Named iterators

#$iters = 0;
#while (my $memberA = $community->next_member('iterA')) {
#   last if $iters >= 30; # prevent infinite loops
#   while (my $memberB = $community->next_member('iterB')) {
#      $iters++;
#      last if $iters >= 30;
#   }
#}
#is $iters, 9; # 3 members * 3 members


done_testing();

exit;
