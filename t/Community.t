use strict;
use warnings;
use Bio::Root::Test;

use Bio::Community::Member;

use_ok($_) for qw(
    Bio::Community
);

my ($community, $member1, $member2, $member3);

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

ok $community->remove_member( $member2 );
is $community->total_count, 27;

ok $community->remove_member( $member2, 22 );
is $community->total_count, 5;

# Now member 2 is gone from the community

done_testing();

exit;
