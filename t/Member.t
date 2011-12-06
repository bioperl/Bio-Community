use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    Bio::Community::Member
);

my $member;

ok $member = Bio::Community::Member->new( -id => 2 );
is $member->id(), 2;

isa_ok $member, 'Bio::Root::RootI';
isa_ok $member, 'Bio::Community::Member';

ok $member = Bio::Community::Member->new( );
is $member->id, 1;

ok $member = Bio::Community::Member->new( );
is $member->id, 3;

done_testing();

exit;
