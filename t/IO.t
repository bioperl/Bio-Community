use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    Bio::Community::IO
);


my $in;
my @methods;

 
# IO driver mechanism

ok $in = Bio::Community::IO->new(
   -format => 'dummy',
   -file => $0,
), 'IO driver mechanism';
isa_ok $in, 'Bio::Root::RootI';
isa_ok $in, 'Bio::Root::IO';
isa_ok $in, 'Bio::Community::IO';
isa_ok $in, 'Bio::Community::IO::dummy';
is $in->format, 'dummy';
is $in->sort_members, 0;

@methods = qw(next_member write_member next_community _next_community write_community);
for my $method (@methods) {
   can_ok($in, $method) || diag "Method $method() not implemented";
}

ok $in->dummy('this is a test');
is $in->dummy, 'this is a test';
$in->close;


done_testing();

exit;
