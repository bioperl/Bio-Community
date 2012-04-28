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

@methods = qw( next_member write_member
               next_community _next_community_init _next_community_finish
               write_community _write_community_init _write_community_finish );
for my $method (@methods) {
   can_ok($in, $method) || diag "Method $method() not implemented";
}

ok $in->dummy('this is a test');
is $in->dummy, 'this is a test';
$in->close;


# -weight_files is tested in t/IO/weights.t

done_testing();

exit;
