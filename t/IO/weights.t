use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $output_file, $community, $community2, $community3, $member, $count);
my (@communities, @methods);


# Read generic format with arbitrary weights

ok $in = Bio::Community::IO->new(
   -file          => test_input_file('generic_table.txt'),
   -format        => 'generic',
   -weight_files  => [ test_input_file('weights_1.txt'), test_input_file('weights_2.txt') ],
   -weight_assign => 1,
), 'Read generic format with arbitrary weights';
isa_ok $in, 'Bio::Community::IO::generic';
is $in->sort_members, 0;
is $in->abundance_type, 'count';
is $in->missing_string, 0;
is_deeply $in->weight_files, [ test_input_file('weights_1.txt'), test_input_file('weights_2.txt') ];
is $in->weight_assign, 1;

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 1;
is $community->name, 'gut';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'soda lake';

is $in->next_community, undef;

$in->close;

ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community->get_count($member), 241;
is_deeply $member->weights, [1, 1];
delta_ok $community->get_rel_ab($member), 100.0;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community2->get_count($member), 334;
is_deeply $member->weights, [1, 1];
delta_ok $community2->get_rel_ab($member), 48.5747527632;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Lumpy skin disease virus';
is $community2->get_count($member), 123;
is_deeply $member->weights, [0.1, 100];
delta_ok $community2->get_rel_ab($member), 1.7888307155;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus';
is $community2->get_count($member), 1023.9;
is_deeply $member->weights, [3, 1];
delta_ok $community2->get_rel_ab($member), 49.6364165212;
is $community2->next_member, undef;


# Write generic format with weights

$output_file = test_output_file();

ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'generic',
), 'Write generic format with arbitrary weights';
ok $out->write_community($community);
ok $out->write_community($community2);
$out->close;

ok $in = Bio::Community::IO->new(
   -file          => $output_file,
   -format        => 'generic',
   -weight_files  => [ test_input_file('weights_1.txt'), test_input_file('weights_2.txt') ],
   -weight_assign => 1,
), 'Re-read generic format with arbitrary weights';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 1;
is $community->name, 'gut';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'soda lake';

ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community->get_count($member), 241;
is_deeply $member->weights, [1, 1];
delta_ok $community->get_rel_ab($member), 100.0;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus';
is $community2->get_count($member), 1023.9;
is_deeply $member->weights, [3, 1];
delta_ok $community2->get_rel_ab($member), 49.6364165212;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community2->get_count($member), 334;
is_deeply $member->weights, [1, 1];
delta_ok $community2->get_rel_ab($member), 48.5747527632;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $community2->next_member, undef;
is $member->desc, 'Lumpy skin disease virus';
is $community2->get_count($member), 123;
is_deeply $member->weights, [0.1, 100];
delta_ok $community2->get_rel_ab($member), 1.7888307155;
is $in->next_community, undef;

$in->close;


# Read generic format with weights

ok $in = Bio::Community::IO->new(
   -file          => test_input_file('generic_table.txt'),
   -format        => 'generic',
   -weight_files  => [ test_input_file('weights_1.txt'), test_input_file('weights_2.txt') ],
   -weight_assign => 'average',
), 'Read weights';
isa_ok $in, 'Bio::Community::IO::generic';
is $in->sort_members, 0;
is $in->abundance_type, 'count';
is $in->missing_string, 0;
is_deeply $in->weight_files, [ test_input_file('weights_1.txt'), test_input_file('weights_2.txt') ];
is $in->weight_assign, 'average';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 1;
is $community->name, 'gut';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'soda lake';

is $in->next_community, undef;

$in->close;

ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community->get_count($member), 241;
is_deeply $member->weights, [1, 200];
delta_ok $community->get_rel_ab($member), 100.0;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus';
is $community2->get_count($member), 1023.9;
is_deeply $member->weights, [3, 200];
delta_ok $community2->get_rel_ab($member), 10.8857206647;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community2->get_count($member), 334;
is_deeply $member->weights, [1, 200];
delta_ok $community2->get_rel_ab($member), 10.6528880809;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Lumpy skin disease virus';
is $community2->get_count($member), 123;
is_deeply $member->weights, [0.1, 100];
delta_ok $community2->get_rel_ab($member), 78.4613912544;
is $community2->next_member, undef;


# Write generic format with average weights assignment

$output_file = test_output_file();

ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'generic',
), 'Write generic format with average weight assignment';
ok $out->write_community($community);
ok $out->write_community($community2);
$out->close;

ok $in = Bio::Community::IO->new(
   -file          => $output_file,
   -format        => 'generic',
   -weight_files  => [ test_input_file('weights_1.txt'), test_input_file('weights_2.txt') ],
   -weight_assign => 'average',
), 'Re-read generic format and average weights';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 1;
is $community->name, 'gut';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 3;
is $community2->name, 'soda lake';

ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community->get_count($member), 241;
is_deeply $member->weights, [1, 200];
delta_ok $community->get_rel_ab($member), 100.0;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus';
is $community2->get_count($member), 1023.9;
is_deeply $member->weights, [3, 200];
delta_ok $community2->get_rel_ab($member), 10.8857206647;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community2->get_count($member), 334;
is_deeply $member->weights, [1, 200];
delta_ok $community2->get_rel_ab($member), 10.6528880809;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Lumpy skin disease virus';
is $community2->get_count($member), 123;
is_deeply $member->weights, [0.1, 100];
delta_ok $community2->get_rel_ab($member), 78.4613912544;
is $community2->next_member, undef;

$in->close;


done_testing();

exit;
