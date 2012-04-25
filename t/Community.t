use strict;
use warnings;
use Bio::Root::Test;

use Bio::Community::Member;

use_ok($_) for qw(
    Bio::Community
);

my ($community, $community2, $community3, $member1, $member2, $member3, $member4,
   $member5, $iters);
my (%ids, %rel_abs, %members);
my  @members;


# Add 3 members to a community

ok $community = Bio::Community->new( -name => 'simple', -use_weights => 0 );

isa_ok $community, 'Bio::Root::RootI';
isa_ok $community, 'Bio::Community';

$community = Bio::Community->new( -use_weights => 0 );
is $community->get_total_count, 0;

$member1 = Bio::Community::Member->new( -weights => [3] );
ok $community->add_member( $member1 );
is $community->get_total_count, 1;

$member2 = Bio::Community::Member->new();
ok $community->add_member( $member2, 23 );
is $community->get_total_count, 24;

$member3 = Bio::Community::Member->new( -weights => [2,7] );
ok $community->add_member( $member3, 4 );
is $community->get_total_count, 28;

isa_ok $community->get_member_by_id(2), 'Bio::Community::Member';
is $community->get_member_by_id(2)->id, 2;

is $community->get_count($member2), 23;
is $community->get_count($member3), 4;
is $community->get_count($member1), 1;

is $community->get_rank($member2), 1;
is $community->get_rank($member3), 2;
is $community->get_rank($member1), 3;

is $community->get_member_by_rank(1)->id, 2;
is $community->get_member_by_rank(2)->id, 3;
is $community->get_member_by_rank(3)->id, 1;
is $community->get_member_by_rank(4), undef;

while (my $member = $community->next_member) {
   isa_ok $member, 'Bio::Community::Member';
   $ids{$member->id} = undef;
}
is_deeply [sort keys %ids], [1, 2, 3];

is $community->get_richness, 3;

%ids = ();
ok @members = @{$community->get_all_members};
for my $member (@members) {
   isa_ok $member, 'Bio::Community::Member';
   $ids{$member->id} = undef;
}
is_deeply [sort keys %ids], [1, 2, 3];


# Remove a member from the community

ok $community->remove_member( $member2 );
is $community->get_total_count, 27;

ok $community->remove_member( $member2, 22 );
is $community->get_total_count, 5;

is $community->get_member_by_id(2), undef;
is $community->get_count($member2), 0;

@members = ();
%ids = ();
ok @members = @{$community->get_all_members};
for my $member (@members) {
   $ids{$member->id} = undef;
}
is_deeply [sort keys %ids], [1, 3];

is $community->get_richness, 2;

is $community->name, 'Unnamed community';
ok $community->name('ocean sample 3');
is $community->name, 'ocean sample 3';

is $community->use_weights, 0;

is $community->get_count($member3), 4;
is $community->get_count($member1), 1;
is $community->get_count($member2), 0;

is $community->get_rank($member3), 1;
is $community->get_rank($member1), 2;
is $community->get_rank($member2), undef;

is $community->get_member_by_rank(1)->id, 3;
is $community->get_member_by_rank(2)->id, 1;
is $community->get_member_by_rank(3), undef;

for my $member (@{$community->get_all_members}) {
   $rel_abs{$member->id} = $community->get_rel_ab($member);
}
is_deeply \%rel_abs, { 1 => 20, 3 => 80 };

ok $community->use_weights(1);
is $community->use_weights, 1;

for my $member (@{$community->get_all_members}) {
   $rel_abs{$member->id} = $community->get_rel_ab($member);
}
is_deeply \%rel_abs, { 1 => 53.846153846154, 3 => 46.1538461538463 };

is $community->get_member_by_rank(1)->id, 1;
is $community->get_member_by_rank(2)->id, 3;


# Get all the members from multiple communities

ok $community = Bio::Community->new();
ok $community->add_member($member1);
ok $community->add_member($member2);
ok $community->add_member($member3);

ok $community2 = Bio::Community->new();
ok $community2->add_member($member3);
ok $member4 = Bio::Community::Member->new( -id => 'asdf' );
ok $community2->add_member($member4);

ok $community3 = Bio::Community->new();
ok $community3->add_member( Bio::Community::Member->new( -id => 3) );
ok $member5 = Bio::Community::Member->new();
ok $community3->add_member($member5);

ok @members = @{$community2->get_all_members([$community, $community3])};
is scalar(@members), 5;

%members = map { $_->id => undef } @members;
ok exists $members{$member1->id};
ok exists $members{$member2->id};
ok exists $members{$member3->id};
ok exists $members{$member4->id};
ok exists $members{$member5->id};

ok @members = @{$community2->get_all_members([$community, $community2, $community3])};
is scalar(@members), 5;

%members = map { $_->id => undef } @members;
ok exists $members{$member1->id};
ok exists $members{$member2->id};
ok exists $members{$member3->id};
ok exists $members{$member4->id};
ok exists $members{$member5->id};


# Named iterators

$iters = 0;
while (my $memberA = $community->next_member('iterA')) {
   last if $iters >= 30; # prevent infinite loops
   while (my $memberB = $community->next_member('iterB')) {
      $iters++;
      last if $iters >= 30;
   }
}
is $iters, 9; # 3 members * 3 members


done_testing();

exit;
