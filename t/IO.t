use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    Bio::Community::IO
);


my ($in, $member, $count);

 
# dummy format

ok $in = Bio::Community::IO->new( -format => 'dummy', -file => $0 );
isa_ok $in, 'Bio::Root::RootI';
isa_ok $in, 'Bio::Root::IO';
isa_ok $in, 'Bio::Community::IO';

ok $in->dummy('this is a test');
is $in->dummy, 'this is a test';


# GAAS format

ok $in = Bio::Community::IO->new( -file => test_input_file('gaas_compo.txt'), -format => 'gaas' );

ok( ($member, $count) = $in->next_member );

#while (my $community = $in->next_community) {
#   
#}



done_testing();

exit;
