use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $output_file, $community, $community2, $member, $count);
my (@communities, @methods);


# Read QIIME format

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('qiime_w_greengenes_taxo.txt'),
   -format => 'qiime',
), 'Read QIIME format';
isa_ok $in, 'Bio::Community::IO::qiime';
is $in->sort_members, 0;
is $in->abundance_type, 'count';
is $in->missing_string, 0;

@methods = qw(next_member write_member _next_community_init _next_community_finish _write_community_init _write_community_finish);
for my $method (@methods) {
   can_ok($in, $method) || diag "Method $method() not implemented";
}


####
#use Data::Dumper;
#print "IN: ".Dumper($in);
####

ok $community = $in->next_community;
###isa_ok $community, 'Bio::Community';
###is $community->get_richness, 1;
###is $community->name, 'gut';

###ok $community2 = $in->next_community;
###isa_ok $community2, 'Bio::Community';
###is $community2->get_richness, 3;
###is $community2->name, 'soda lake';

###is $in->next_community, undef;

###$in->close;

###ok $member = $community->next_member;
###isa_ok $member, 'Bio::Community::Member';
###is $member->desc, 'Streptococcus';
###is $community->get_count($member), 241;
###is $community->next_member, undef;

###ok $member = $community2->next_member;
###isa_ok $member, 'Bio::Community::Member';
###is $member->desc, 'Streptococcus';
###is $community2->get_count($member), 334;
###ok $member = $community2->next_member;
###isa_ok $member, 'Bio::Community::Member';
###is $member->desc, 'Lumpy skin disease virus';
###is $community2->get_count($member), 123;
###ok $member = $community2->next_member;
###isa_ok $member, 'Bio::Community::Member';
###is $member->desc, 'Goatpox virus';
###is $community2->get_count($member), 1023.9;
###is $community2->next_member, undef;


#### Write qiime format

###$output_file = test_output_file();

###ok $out = Bio::Community::IO->new(
###   -file   => '>'.$output_file,
###   -format => 'qiime',
###), 'Write QIIME format';
###ok $out->write_community($community);
###ok $out->write_community($community2);
###$out->close;

###ok $in = Bio::Community::IO->new(
###   -file   => $output_file,
###   -format => 'qiime',
###), 'Re-read QIIME format';

###ok $community = $in->next_community;
###ok $member = $community->next_member;
###is $member->desc, 'Streptococcus';
###is $community->get_count($member), 241;
###is $community->next_member, undef;

###ok $community2 = $in->next_community;
###ok $member = $community2->next_member;
###is $member->desc, 'Goatpox virus';
###is $community2->get_count($member), 1023.9;
###ok $member = $community2->next_member;
###is $member->desc, 'Streptococcus';
###is $community2->get_count($member), 334;
###ok $member = $community2->next_member;
###is $member->desc, 'Lumpy skin disease virus';
###is $community2->get_count($member), 123;
###is $community2->next_member, undef;

###is $in->next_community, undef;

###$in->close;


done_testing();

exit;
