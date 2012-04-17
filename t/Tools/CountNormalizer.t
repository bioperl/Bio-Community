use strict;
use warnings;
use Bio::Root::Test;
use Bio::Community;

use_ok($_) for qw(
    Bio::Community::Tools::CountNormalizer
);


my ($normalizer, $community1, $community2, $average, $representative, $member1,
   $member2, $member3, $member4, $member5, $member6);

$community1 = Bio::Community->new();
$member1 = Bio::Community::Member->new( -id => 1 );
$member2 = Bio::Community::Member->new( -id => 2 );
$member3 = Bio::Community::Member->new( -id => 3 );
$member4 = Bio::Community::Member->new( -id => 4 );
$member5 = Bio::Community::Member->new( -id => 5 );
$community1->add_member( $member1, 300);
$community1->add_member( $member2, 300);
$community1->add_member( $member3, 300);
$community1->add_member( $member4, 300);
$community1->add_member( $member5, 300);

$community1 = Bio::Community->new();
$member1 = Bio::Community::Member->new( -id => 1 );
$member3 = Bio::Community::Member->new( -id => 3 );
$member6 = Bio::Community::Member->new( -id => 6 );
$community1->add_member( $member1, 2014);
$community1->add_member( $member3, 1057);
$community1->add_member( $member6, 2514);

ok $normalizer = Bio::Community::Tools::CountNormalizer->new( );
isa_ok $normalizer, 'Bio::Community::Tools::CountNormalizer';


done_testing();

exit;
