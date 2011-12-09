use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $community, $member, $count);
my @communities;

 
# dummy format

ok $in = Bio::Community::IO->new( -format => 'dummy', -file => $0 );
isa_ok $in, 'Bio::Root::RootI';
isa_ok $in, 'Bio::Root::IO';
isa_ok $in, 'Bio::Community::IO';

ok $in->dummy('this is a test');
is $in->dummy, 'this is a test';


# GAAS format

ok $in = Bio::Community::IO->new( -file => test_input_file('gaas_compo.txt'), -format => 'gaas' );

@communities = ();
while ($community = $in->next_community) {
   isa_ok $community, 'Bio::Community';
   push @communities, $community;
}
is scalar @communities, 1;
$community = $communities[0];
is $community->get_richness, 3;

ok $member = $community->next_member;
is $community->get_rel_ab($member), 79.1035649011735;
ok $member = $community->next_member;
is $community->get_rel_ab($member), 1.28701423616715;
ok $member = $community->next_member;
is $community->get_rel_ab($member), 19.6094208626593;


done_testing();

exit;
