use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $meta, $output_file);
my @methods;

 
# IO driver mechanism

ok $in = Bio::Community::IO->new(
   -format => 'dummy',
   -file   => $0,
), 'IO driver mechanism';
isa_ok $in, 'Bio::Root::RootI';
isa_ok $in, 'Bio::Root::IO';
isa_ok $in, 'Bio::Community::IO';
isa_ok $in, 'Bio::Community::IO::Driver::dummy';
is $in->format, 'dummy';
is $in->sort_members, 0;

@methods = qw( next_member write_member
               next_community _next_community_init _next_community_finish
               write_community _write_community_init _write_community_finish
               next_metacommunity _next_metacommunity_init _next_metacommunity_finish
               write_metacommunity _write_metacommunity_init _write_metacommunity_finish
               sort_members abundance_type missing_string multiple_communities
               weight_files weight_assign taxonomy );

for my $method (@methods) {
   can_ok($in, $method) || diag "Method $method() not implemented";
}

ok $in->dummy('this is a test');
is $in->dummy, 'this is a test';
$in->close;


# Read / write metacommunity

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('generic_table.txt'),
);

ok $meta = $in->next_metacommunity;
isa_ok $meta, 'Bio::Community::Meta';
is $meta->name, '';
is $meta->get_members_count, 1721.9;
is $meta->get_communities_count, 2;
is $meta->get_richness, 3;
$in->close;

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'generic',
);

ok $out->write_metacommunity($meta);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
);
isa_ok $meta, 'Bio::Community::Meta';
is $meta->name, '';
is $meta->get_members_count, 1721.9;
is $meta->get_communities_count, 2;
is $meta->get_richness, 3;
$in->close;


# -weight_files is tested in t/IO/weights.t

done_testing();

exit;
