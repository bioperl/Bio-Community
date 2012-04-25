use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $output_file, $community, $community2, $member, $count);
my (@communities, @methods);


# Automatic format detection

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('gaas_compo.txt'),
), 'Format detection';
is $in->format, 'gaas';


# Read GAAS format

ok $in = Bio::Community::IO->new(
   -file   => test_input_file('gaas_compo.txt'),
   -format => 'gaas',
), 'Read GAAS format';
isa_ok $in, 'Bio::Community::IO::gaas';
is $in->sort_members, -1;
is $in->abundance_type, 'fraction';
is $in->missing_string, 0;

@methods = qw(next_member write_member _next_community_init _next_community_finish _write_community_init _write_community_finish);
for my $method (@methods) {
   can_ok($in, $method) || diag "Method $method() not implemented";
}

@communities = ();
while ($community = $in->next_community) {
   isa_ok $community, 'Bio::Community';
   push @communities, $community;
}
$in->close;

is scalar @communities, 1;
$community = $communities[0];
is $community->get_richness, 3;

use Data::Dumper; print Dumper($community);

ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus pyogenes phage 315.1';
print $member->desc."\n";
is $community->get_rel_ab($member), 79.1035649011735;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Lumpy skin disease virus NI-2490';
print $member->desc."\n";
is $community->get_rel_ab($member), 1.28701423616715;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus Pellor';
print $member->desc."\n";
is $community->get_rel_ab($member), 19.6094208626593;


#use Data::Dumper; print Dumper($community);


#### Write GAAS format and re-read it

###$output_file = test_output_file();
###ok $out = Bio::Community::IO->new(
###   -file   => '>'.$output_file,
###   -format => 'gaas',
###), 'Write GAAS format';
###ok $out->write_community($community);
###$out->close;

###ok $in = Bio::Community::IO->new(
###   -file   => '<'.$output_file,
###   -format => 'gaas',
###), 'Re-read GAAS format';
###ok $community2 = $in->next_community;
###is $in->next_community, undef;
###$in->close;

###ok $member = $community2->next_member;
###isa_ok $member, 'Bio::Community::Member';
###is $member->desc, 'Lumpy skin disease virus NI-2490';
###is $community2->get_rel_ab($member), 1.28701423616715;
###ok $member = $community2->next_member;
###isa_ok $member, 'Bio::Community::Member';
###is $member->desc, 'Streptococcus pyogenes phage 315.1';
###is $community2->get_rel_ab($member), 79.1035649011735;
###ok $member = $community2->next_member;
###isa_ok $member, 'Bio::Community::Member';
###is $member->desc, 'Goatpox virus Pellor';
###is $community2->get_rel_ab($member), 19.6094208626593;


done_testing();

exit;
