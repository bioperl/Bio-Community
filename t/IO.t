use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in);

ok $in = Bio::Community::IO->new( -format => 'generic' );
isa_ok $in, 'Bio::Root::RootI';
isa_ok $in, 'Bio::Community::IO';

ok $in->test('this is a test');
is $in->test, 'this is a test';

done_testing();

exit;
