use strict;
use warnings;
use Bio::Root::Test;
use Bio::DB::Taxonomy;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $output_file, $community, $community2, $community3, $member,
   $count, $taxonomy);
my (@communities, @methods);


# Automatic format detection

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('qiime_w_no_taxo.txt'),
), 'Format detection';
is $in->format, 'qiime';


# Read QIIME file without taxonomy

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('qiime_w_no_taxo.txt'),
   -format => 'qiime',
), 'Read QIIME file';
isa_ok $in, 'Bio::Community::IO::qiime';
is $in->sort_members, 0;
is $in->abundance_type, 'count';
is $in->missing_string, 0;
is $in->multiple_communities, 1;

@methods = qw(next_member write_member _next_community_init _next_community_finish _write_community_init _write_community_finish);
for my $method (@methods) {
   can_ok($in, $method) || diag "Method $method() not implemented";
}

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
is $member->id, 0;
is $member->desc, '';
is $community->get_count($member), 40;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 2;
is $member->desc, '';
is $community->get_count($member), 41;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 1;
is $member->desc, '';
is $community2->get_count($member), 142;
is $community2->next_member, undef;

ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 1;
is $member->desc, '';
is $community3->get_count($member), 2;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 0;
is $member->desc, '';
is $community3->get_count($member), 76;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 2;
is $member->desc, '';
is $community3->get_count($member), 43;
is $community3->next_member, undef;


# Write QIIME file without taxonomy

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'qiime',
), 'Write QIIME file';
ok $out->write_community($community);
ok $out->write_community($community2);
ok $out->write_community($community3);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'qiime',
), 'Re-read QIIME file';

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
is $member->id, 0;
is $member->desc, '';
is $community->get_count($member), 40;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 2;
is $member->desc, '';
is $community->get_count($member), 41;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 1;
is $member->desc, '';
is $community2->get_count($member), 142;
is $community2->next_member, undef;

ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 1;
is $member->desc, '';
is $community3->get_count($member), 2;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 0;
is $member->desc, '';
is $community3->get_count($member), 76;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 2;
is $member->desc, '';
is $community3->get_count($member), 43;
is $community3->next_member, undef;


# Read QIIME file with GreenGenes taxonomy

ok $taxonomy = Bio::DB::Taxonomy->new(
   -source   => 'greengenes',
   -taxofile => test_input_file('taxonomy', 'greengenes_taxonomy_16S_candiv_gg_2011_1.txt'),
);

ok $in = Bio::Community::IO->new(
   -file     => test_input_file('qiime_w_greengenes_taxo.txt'),
   -format   => 'qiime',
   -taxonomy => $taxonomy,
), 'Read QIIME file with taxonomy';

is $in->taxonomy, $taxonomy;

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
is $member->id, 0;
is $member->desc, 'k__Bacteria;p__Proteobacteria;c__Alphaproteobacteria;o__Rickettsiales;f__;g__Candidatus Pelagibacter;s__';
is $member->taxon->node_name, 'g__Candidatus Pelagibacter';
is $community->get_count($member), 40;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 2;
is $member->desc, 'No blast hit';
is $member->taxon, undef;
is $community->get_count($member), 41;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 1;
is $member->desc, 'k__Archaea;p__Euryarchaeota;c__Thermoplasmata;o__E2;f__Marine group II;g__;s__';
is $member->taxon->node_name, 'f__Marine group II';
is $community2->get_count($member), 142;
is $community2->next_member, undef;

ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 1;
is $member->desc, 'k__Archaea;p__Euryarchaeota;c__Thermoplasmata;o__E2;f__Marine group II;g__;s__';
is $member->taxon->node_name, 'f__Marine group II';
is $community3->get_count($member), 2;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 0;
is $member->desc, 'k__Bacteria;p__Proteobacteria;c__Alphaproteobacteria;o__Rickettsiales;f__;g__Candidatus Pelagibacter;s__';
is $member->taxon->node_name, 'g__Candidatus Pelagibacter';
is $community3->get_count($member), 76;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 2;
is $member->desc, 'No blast hit';
is $member->taxon, undef;
is $community3->get_count($member), 43;
is $community3->next_member, undef;


# Write QIIME file with GreenGenes taxonomy

$output_file = test_output_file();
ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'qiime',
), 'Write QIIME format with taxonomy';
ok $out->write_community($community);
ok $out->write_community($community2);
ok $out->write_community($community3);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'qiime',
), 'Re-read QIIME format with taxonomy';

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
is $member->id, 0;
is $member->desc, 'k__Bacteria;p__Proteobacteria;c__Alphaproteobacteria;o__Rickettsiales;f__;g__Candidatus Pelagibacter;s__';
is $community->get_count($member), 40;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 2;
is $member->desc, 'No blast hit';
is $community->get_count($member), 41;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 1;
is $member->desc, 'k__Archaea;p__Euryarchaeota;c__Thermoplasmata;o__E2;f__Marine group II;g__;s__';
is $community2->get_count($member), 142;
is $community2->next_member, undef;

ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 1;
is $member->desc, 'k__Archaea;p__Euryarchaeota;c__Thermoplasmata;o__E2;f__Marine group II;g__;s__';
is $community3->get_count($member), 2;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 0;
is $member->desc, 'k__Bacteria;p__Proteobacteria;c__Alphaproteobacteria;o__Rickettsiales;f__;g__Candidatus Pelagibacter;s__';
is $community3->get_count($member), 76;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 2;
is $member->desc, 'No blast hit';
is $community3->get_count($member), 43;
is $community3->next_member, undef;


# Read QIIME file where a community has no members and a member is not present
# in any community

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('qiime_w_missing.txt'),
   -format => 'qiime',
), 'Read QIIME file with missing element';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 2;
is $community->name, '20100302';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 1;
is $community2->name, '20100823';

is $in->next_community, undef;

$in->close;

ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 0;
is $member->desc, 'k__Bacteria;p__Proteobacteria;c__Alphaproteobacteria;o__Rickettsiales;f__;g__Candidatus Pelagibacter;s__';
is $community->get_count($member), 40;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 2;
is $member->desc, 'No blast hit';
is $community->get_count($member), 41;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 2;
is $member->desc, 'No blast hit';
is $community2->get_count($member), 76;
is $community2->next_member, undef;


# Read QIIME file where a taxonomy has root and Consensuslineage is spelt differently

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('qiime_w_root.txt'),
   -format => 'qiime',
), 'Read QIIME file with root';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 2;
is $community->name, 'Bact.12.15';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 4;
is $community2->name, 'Bact.0.2';

is $in->next_community, undef;

$in->close;

ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 4;
is $member->desc, 'Root; k__Bacteria; p__Bacteroidetes; c__Bacteroidia; o__Bacteroidales; f__Prevotellaceae';
is $community->get_count($member), 1;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 0;
is $member->desc, 'Root; k__Bacteria; p__TM7; c__TM7-3; o__CW040; f__F16';
is $community->get_count($member), 41;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 8;
is $member->desc, 'Root; k__Bacteria; p__Firmicutes; c__Clostridia; o__Clostridiales; f__';
is $community2->get_count($member), 1;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 4;
is $member->desc, 'Root; k__Bacteria; p__Bacteroidetes; c__Bacteroidia; o__Bacteroidales; f__Prevotellaceae';
is $community2->get_count($member), 11;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 0;
is $member->desc, 'Root; k__Bacteria; p__TM7; c__TM7-3; o__CW040; f__F16';
is $community2->get_count($member), 2;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->id, 5;
is $member->desc, 'Root; k__Bacteria; p__Bacteroidetes; c__Bacteroidia; o__Bacteroidales; f__Prevotellaceae';
is $community2->get_count($member), 2;

done_testing();

exit;
