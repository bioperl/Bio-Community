use strict;
use warnings;
use Bio::Root::Test;

use Bio::Community::Member;

use_ok($_) for qw(
    Bio::Community
);

my ($community, $member1, $member2, $member3);
my  @members;
my  %ids;

ok $community = Bio::Community->new();

isa_ok $community, 'Bio::Root::RootI';
isa_ok $community, 'Bio::Community';

$community = Bio::Community->new();
is $community->total_count, 0;

$member1 = Bio::Community::Member->new();
ok $community->add_member( $member1 );
is $community->total_count, 1;

$member2 = Bio::Community::Member->new();
ok $community->add_member( $member2, 23 );
is $community->total_count, 24;

$member3 = Bio::Community::Member->new();
ok $community->add_member( $member3, 4 );
is $community->total_count, 28;

isa_ok $community->get_member_by_id(2), 'Bio::Community::Member';
is $community->get_member_by_id(2)->id, 2;
is $community->get_count($member2), 23;

while (my $member = $community->next_member) {
   isa_ok $member, 'Bio::Community::Member';
   $ids{$member->id} = undef;
}
is_deeply [sort keys %ids], [1, 2, 3];

is $community->richness, 3;

%ids = ();
ok @members = $community->all_members;
for my $member (@members) {
   isa_ok $member, 'Bio::Community::Member';
   $ids{$member->id} = undef;
}
is_deeply [sort keys %ids], [1, 2, 3];

ok $community->remove_member( $member2 );
is $community->total_count, 27;

ok $community->remove_member( $member2, 22 );
is $community->total_count, 5;

is $community->get_member_by_id(2), undef;
is $community->get_count($member2), 0;

@members = ();
%ids = ();
ok @members = $community->all_members;
for my $member (@members) {
   $ids{$member->id} = undef;
}
is_deeply [sort keys %ids], [1, 3];

is $community->richness, 2;

is $community->name, 'Unnamed community';
ok $community->name('ocean sample 3');
is $community->name, 'ocean sample 3';



done_testing();

exit;
