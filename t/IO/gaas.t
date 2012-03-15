use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $output_file, $community, $community2, $member, $count);
my (@communities, @methods);

# Read GAAS format

ok $in = Bio::Community::IO->new( -file => test_input_file('gaas_compo.txt'), -format => 'gaas' ), 'Read GAAS format';
is $in->sort_members, -1;
@methods = qw(next_member write_member);
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

ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus pyogenes phage 315.1';
is $community->get_rel_ab($member), 79.1035649011735;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Lumpy skin disease virus NI-2490';
is $community->get_rel_ab($member), 1.28701423616715;
ok $member = $community->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus Pellor';
is $community->get_rel_ab($member), 19.6094208626593;


# Write GAAS format

$output_file = test_output_file();
ok $out = Bio::Community::IO->new( -file => '>'.$output_file, -format => 'gaas' ), 'Write GAAS format';
ok $out->write_community($community);
$out->close;

ok $in = Bio::Community::IO->new( -file => '<'.$output_file, -format => 'gaas' );
ok $community2 = $in->next_community;
$in->close;

ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Streptococcus pyogenes phage 315.1';
is $community2->get_rel_ab($member), 79.1035649011735;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Lumpy skin disease virus NI-2490';
is $community2->get_rel_ab($member), 1.28701423616715;
ok $member = $community2->next_member;
isa_ok $member, 'Bio::Community::Member';
is $member->desc, 'Goatpox virus Pellor';
is $community2->get_rel_ab($member), 19.6094208626593;


done_testing();

exit;