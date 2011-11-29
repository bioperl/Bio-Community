use strict;
use warnings;
use Bio::Root::Test;

use Bio::Community::Member;

use_ok($_) for qw(
    Bio::Community
);

my ($community, $member1, $member2, $member3, $richness);
my @members;

ok $community = Bio::Community->new();

isa_ok $community, 'Bio::Root::RootI';
isa_ok $community, 'Bio::Community';

$community = Bio::Community->new();
###is $community->total_count, 0;

$member1 = Bio::Community::Member->new();
ok $community->add_member( $member1 );
is $community->total_count, 1;

$member2 = Bio::Community::Member->new();
ok $community->add_member( $member2, 23 );
is $community->total_count, 24;

$member3 = Bio::Community::Member->new();
ok $community->add_member( $member3, 4 );
is $community->total_count, 28;

$richness = 0;
for my $member ($community->next_member) {
   isa_ok $member, 'Bio::Community::Member';
   $richness++;
}
###is $richness, 3

ok @members = $community->all_members;
is scalar(@members), 3;
for my $member (@members) {
   isa_ok $member, 'Bio::Community::Member';
}

ok $community->remove_member( $member2 );
is $community->total_count, 27;

ok $community->remove_member( $member2, 22 );
is $community->total_count, 5;

ok @members = $community->all_members;
is scalar(@members), 2;

done_testing();

exit;
