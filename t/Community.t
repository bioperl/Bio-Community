use strict;
use warnings;
use Bio::Root::Test;

use Bio::Community::Member;

use_ok($_) for qw(
    Bio::Community
);

my ($community, $member1, $member2, $member3);
my (%ids, %rel_abs);
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

is $community->get_member_by_rank(1), $member2;
is $community->get_member_by_rank(2), $member3;
is $community->get_member_by_rank(3), $member1;
is $community->get_member_by_rank(4), undef;

while (my $member = $community->next_member) {
   isa_ok $member, 'Bio::Community::Member';
   $ids{$member->id} = undef;
}
is_deeply [sort keys %ids], [1, 2, 3];

is $community->get_richness, 3;

%ids = ();
ok @members = $community->get_all_members;
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
ok @members = $community->get_all_members;
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

is $community->get_member_by_rank(1), $member3;
is $community->get_member_by_rank(2), $member1;
is $community->get_member_by_rank(3), undef;

for my $member ($community->get_all_members) {
   $rel_abs{$member->id} = $community->get_rel_ab($member);
}
is_deeply \%rel_abs, { 1 => 20, 3 => 80 };

ok $community->use_weights(1);
is $community->use_weights, 1;

for my $member ($community->get_all_members) {
   $rel_abs{$member->id} = $community->get_rel_ab($member);
}
is_deeply \%rel_abs, { 1 => 53.846153846154, 3 => 46.1538461538463 };

is $community->get_member_by_rank(1), $member1;
is $community->get_member_by_rank(2), $member3;


done_testing();

exit;
