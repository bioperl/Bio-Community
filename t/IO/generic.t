use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $output_file, $community, $community2, $community3, $member, $count);
my (@communities, @methods);


# Automatic format detection

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('generic_table.txt'),
), 'Format detection';
is $in->format, 'generic';


# Read generic format

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('generic_table.txt'),
   -format => 'generic',
), 'Read generic format';
isa_ok $in, 'Bio::Community::IO::generic';
is $in->sort_members, 0;
is $in->abundance_type, 'count';
is $in->missing_string, 0;

@methods = qw(next_member write_member _next_community_init _next_community_finish _write_community_init _write_community_finish);
for my $method (@methods) {
   can_ok($in, $method) || diag "Method $method() not implemented";
}

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
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus';
is $community2->get_count($member), 334;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Lumpy skin disease virus';
is $community2->get_count($member), 123;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus';
is $community2->get_count($member), 1023.9;
is $community2->next_member, undef;


# Write generic format

$output_file = test_output_file();

ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'generic',
), 'Write generic format';
ok $out->write_community($community);
ok $out->write_community($community2);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'generic',
), 'Re-read generic format';

ok $community = $in->next_community;
ok $member = $community->next_member;
is $member->desc, 'Streptococcus';
is $community->get_count($member), 241;
is $community->next_member, undef;

ok $community2 = $in->next_community;
ok $member = $community2->next_member;
is $member->desc, 'Goatpox virus';
is $community2->get_count($member), 1023.9;
ok $member = $community2->next_member;
is $member->desc, 'Streptococcus';
is $community2->get_count($member), 334;
ok $member = $community2->next_member;
is $member->desc, 'Lumpy skin disease virus';
is $community2->get_count($member), 123;
is $community2->next_member, undef;

is $in->next_community, undef;

$in->close;


# Read QIIME summarized OTU table (Silva taxonomy)

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('qiime_w_silva_taxo_L2.txt'),
   -format => 'generic',
), 'Read summarized QIIME file';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 3;
is $community->name, 'FI.5m';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 2;
is $community2->name, 'RI.5m';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 3;
is $community3->name, 'TR.5m';

is $in->next_community, undef;

$in->close;

ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
is $community->get_count($member), 0.2142857143;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Archaea;Euryarchaeota';
is $community->get_count($member), 0.2342192691;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
is $community->get_count($member), 0.5514950166;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
is $community2->get_count($member), 0.9536354057;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
is $community2->get_count($member), 0.0463645943;
is $community2->next_member, undef;

ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
is $community3->get_count($member), 0.0195488722;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Archaea;Euryarchaeota';
is $community3->get_count($member), 0.4;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
is $community3->get_count($member), 0.5804511278;
is $community3->next_member, undef;


# Write QIIME summarized OTU table

$output_file = test_output_file();

ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'generic',
), 'Write summarized QIIME file';
ok $out->write_community($community);
ok $out->write_community($community2);
ok $out->write_community($community3);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'generic',
), 'Re-read summarized QIIME file';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 3;
is $community->name, 'FI.5m';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 2;
is $community2->name, 'RI.5m';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 3;
is $community3->name, 'TR.5m';

is $in->next_community, undef;

$in->close;

ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
is $community->get_count($member), 0.2142857143;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
is $community->get_count($member), 0.5514950166;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Archaea;Euryarchaeota';
is $community->get_count($member), 0.2342192691;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
is $community2->get_count($member), 0.9536354057;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
is $community2->get_count($member), 0.0463645943;
is $community2->next_member, undef;

ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Eukaryota;Viridiplantae';
is $community3->get_count($member), 0.0195488722;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Bacteria;Proteobacteria';
is $community3->get_count($member), 0.5804511278;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Archaea;Euryarchaeota';
is $community3->get_count($member), 0.4;
is $community3->next_member, undef;


done_testing();

exit;
