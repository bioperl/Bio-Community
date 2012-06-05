use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::DB::Taxonomy;

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


# Read generic format with average weights

ok $in = Bio::Community::IO->new(
   -file          => test_input_file('generic_table.txt'),
   -format        => 'generic',
   -weight_files  => [ test_input_file('weights_1.txt'), test_input_file('weights_2.txt') ],
   -weight_assign => 'file_average',
), 'Read generic format with average weights';
isa_ok $in, 'Bio::Community::IO::generic';
is $in->sort_members, 0;
is $in->abundance_type, 'count';
is $in->missing_string, 0;
is_deeply $in->weight_files, [ test_input_file('weights_1.txt'), test_input_file('weights_2.txt') ];
is $in->weight_assign, 'file_average';

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
is $member->desc, 'Lumpy skin disease virus';
is $community2->get_count($member), 123;
is_deeply $member->weights, [0.1, 100];
delta_ok $community2->get_rel_ab($member), 78.4613912544;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community2->get_count($member), 334;
is_deeply $member->weights, [1, 200];
delta_ok $community2->get_rel_ab($member), 10.6528880809;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus';
is $community2->get_count($member), 1023.9;
is_deeply $member->weights, [3, 200];
delta_ok $community2->get_rel_ab($member), 10.8857206647;
is $community2->next_member, undef;


# Read qiime format with ancestor-based weights

ok $in = Bio::Community::IO->new(
   -file          => test_input_file('qiime_w_greengenes_taxo.txt'),
   -format        => 'qiime',
   -taxonomy      => Bio::DB::Taxonomy->new( -source => 'list' ), # on-the-fly taxonomy
   -weight_files  => [ test_input_file('weights_taxo.txt') ],
   -weight_assign => 'ancestor',
), 'Read qiime format with ancestor-based weights';
is_deeply $in->weight_files, [ test_input_file('weights_taxo.txt') ];
is $in->weight_assign, 'ancestor';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 2;
is $community->name, '20100302';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 1;
is $community2->name, '20100304';


ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 3;
is $community3->name, '20100823';

is $in->next_community, undef;

$in->close;

ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'k__Bacteria;p__Proteobacteria;c__Alphaproteobacteria;o__Rickettsiales;f__;g__Candidatus Pelagibacter;s__';
is $community->get_count($member), 40;
is_deeply $member->weights, [100];
delta_ok $community->get_rel_ab($member), 62.9741120;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'No blast hit';
is $community->get_count($member), 41;
is_deeply $member->weights, [174.333333333333];
delta_ok $community->get_rel_ab($member), 37.0258880;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'k__Archaea;p__Euryarchaeota;c__Thermoplasmata;o__E2;f__Marine group II;g__;s__';
is $community2->get_count($member), 142;
is_deeply $member->weights, [300];
delta_ok $community2->get_rel_ab($member), 100;
is $community2->next_member, undef;

ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'k__Archaea;p__Euryarchaeota;c__Thermoplasmata;o__E2;f__Marine group II;g__;s__';
is $community3->get_count($member), 2;
is_deeply $member->weights, [300];
delta_ok $community3->get_rel_ab($member), 0.6579030;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'k__Bacteria;p__Proteobacteria;c__Alphaproteobacteria;o__Rickettsiales;f__;g__Candidatus Pelagibacter;s__';
is $community3->get_count($member), 76;
is_deeply $member->weights, [100];
delta_ok $community3->get_rel_ab($member), 75.0009435;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'No blast hit';
is $community3->get_count($member), 43;
is_deeply $member->weights, [174.333333333333];
delta_ok $community3->get_rel_ab($member), 24.3411535;
is $community3->next_member, undef;


$in->close;

done_testing();

exit;
