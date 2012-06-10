use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::DB::Taxonomy;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $output_file, $community, $community2, $community3, $member,
   $count, $taxonomy);
my (@communities, @methods);


# Automatic format detection

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('unifrac_quantitative.txt'),
), 'Format detection';
is $in->format, 'unifrac';


# Read Unifrac quantitative format

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('unifrac_quantitative.txt'),
   -format => 'unifrac',
), 'Read Unifrac quantitative format';
isa_ok $in, 'Bio::Community::IO::unifrac';
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
is $community->get_richness, 3;
is $community->name, 'Sample.2';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 2;
is $community2->name, 'Sample 3';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 4;
is $community3->name, 'Sample.1';

is $in->next_community, undef;

$in->close;

ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.4';
delta_ok $community->get_count($member), 8;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community->get_count($member), 1;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community->get_count($member), 2;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community2->get_count($member), 1;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community2->get_count($member), 1;
is $community2->next_member, undef;

ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community3->get_count($member), 1;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.2';
delta_ok $community3->get_count($member), 15;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.5';
delta_ok $community3->get_count($member), 4;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence 3';
delta_ok $community3->get_count($member), 2;
is $community3->next_member, undef;


# Write Unifrac quantitative format

$output_file = test_output_file();

ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'unifrac',
), 'Write Unifrac quantitative format';
ok $out->write_community($community);
ok $out->write_community($community2);
ok $out->write_community($community3);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'unifrac',
), 'Re-read Unifrac quantitative format';

ok $community = $in->next_community;
is $community->name, 'Sample_3'; # space replaced by underscore
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community->get_count($member), 1;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community->get_count($member), 1;
is $community->next_member, undef;

ok $community2 = $in->next_community;
is $community2->name, 'Sample.2';
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community2->get_count($member), 1;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.4';
delta_ok $community2->get_count($member), 8;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community2->get_count($member), 2;
is $community2->next_member, undef;

ok $community3 = $in->next_community;
is $community3->name, 'Sample.1';
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence_3'; # space replaced by underscore
delta_ok $community3->get_count($member), 2;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community3->get_count($member), 1;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.2';
delta_ok $community3->get_count($member), 15;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.5';
delta_ok $community3->get_count($member), 4;

is $community3->next_member, undef;

$in->close;


# Read Unifrac qualitative format

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('unifrac_qualitative.txt'),
   -format => 'unifrac',
), 'Read Unifrac qualitative format';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 3;
is $community->name, 'Sample.2';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 1;
is $community2->name, 'Sample.3';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 4;
is $community3->name, 'Sample.1';

is $in->next_community, undef;

$in->close;

ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community->get_count($member), 1;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community->get_count($member), 1;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.4';
delta_ok $community->get_count($member), 1;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community2->get_count($member), 1;
is $community2->next_member, undef;

ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.3';
delta_ok $community3->get_count($member), 1;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.2';
delta_ok $community3->get_count($member), 1;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.5';
delta_ok $community3->get_count($member), 1;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community3->get_count($member), 1;
is $community3->next_member, undef;


# Write Unifrac qualitative format

$output_file = test_output_file();

ok $out = Bio::Community::IO->new(
   -file   => '>'.$output_file,
   -format => 'unifrac',
), 'Write Unifrac qualitative format';
ok $out->write_community($community);
ok $out->write_community($community2);
ok $out->write_community($community3);
$out->close;

ok $in = Bio::Community::IO->new(
   -file   => $output_file,
   -format => 'unifrac',
), 'Re-read Unifrac qualitative format';

ok $community = $in->next_community;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community->get_count($member), 1;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community->get_count($member), 1;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.4';
delta_ok $community->get_count($member), 1;
is $community->next_member, undef;

ok $community2 = $in->next_community;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community2->get_count($member), 1;
is $community2->next_member, undef;

ok $community3 = $in->next_community;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.3';
delta_ok $community3->get_count($member), 1;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.2';
delta_ok $community3->get_count($member), 1;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.5';
delta_ok $community3->get_count($member), 1;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community3->get_count($member), 1;
is $community3->next_member, undef;

is $in->next_community, undef;

$in->close;


# Read Unifrac quantitative format (with some missing values)

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('unifrac_quantitative_tricky.txt'),
   -format => 'unifrac',
), 'Read a tricky Unifrac file';

ok $community = $in->next_community;
isa_ok $community, 'Bio::Community';
is $community->get_richness, 1;
is $community->name, 'Sample.2';

ok $community2 = $in->next_community;
isa_ok $community2, 'Bio::Community';
is $community2->get_richness, 1;
is $community2->name, 'Sample.3';

ok $community3 = $in->next_community;
isa_ok $community3, 'Bio::Community';
is $community3->get_richness, 4;
is $community3->name, 'Sample.1';

is $in->next_community, undef;

$in->close;

ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community->get_count($member), 1;
is $community->next_member, undef;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.6';
delta_ok $community2->get_count($member), 1;
is $community2->next_member, undef;

ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.1';
delta_ok $community3->get_count($member), 1;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.3';
delta_ok $community3->get_count($member), 2;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.5';
delta_ok $community3->get_count($member), 4;
ok $member = $community3->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Sequence.2';
delta_ok $community3->get_count($member), 15;

is $community3->next_member, undef;


done_testing();

exit;
