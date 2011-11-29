use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    Bio::Community::Member
);

my $member;

ok $member = Bio::Community::Member->new({ id => 426 });
is $member->id(), 426;

done_testing();

exit;
