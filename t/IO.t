use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $out, $output_file, $community, $community2, $member, $count);
my (@communities, @methods);

 
# IO driver mechanism

ok $in = Bio::Community::IO->new( -format => 'dummy', -file => $0 ), 'IO driver mechanism';
isa_ok $in, 'Bio::Root::RootI';
isa_ok $in, 'Bio::Root::IO';
isa_ok $in, 'Bio::Community::IO';

@methods = qw(next_member write_member next_community write_community);
for my $method (@methods) {
   can_ok($in, $method) || diag "Method $method() not implemented";
}

ok $in->dummy('this is a test');
is $in->dummy, 'this is a test';
$in->close;


# Read GAAS format

ok $in = Bio::Community::IO->new( -file => test_input_file('gaas_compo.txt'), -format => 'gaas' ), 'Read GAAS format';

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


# Read GAAS format

$output_file = test_output_file();
ok $out = Bio::Community::IO->new( -file => '>'.$output_file, -format => 'gaas' ), 'Write GAAS format';
ok $out->write_community($community);
$out->close;

ok $in = Bio::Community::IO->new( -file => '<'.$output_file, -format => 'gaas' );
ok $community2 = $in->next_community;
$in->close;

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


done_testing();

exit;
