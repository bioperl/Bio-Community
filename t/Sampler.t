use strict;
use warnings;
use Bio::Root::Test;
use Bio::Community::Member;
use Bio::Community;

use_ok($_) for qw(
    Bio::Community::Tools::Sampler
);


my ($member1, $member2, $member3, $community, $sampler);

$member1 = Bio::Community::Member->new( -desc => 'A' );
$member2 = Bio::Community::Member->new( -desc => 'B' );
$member3 = Bio::Community::Member->new( -desc => 'C' );


# Even community

$community = Bio::Community->new();
$community->add_member( $member1, 1);
$community->add_member( $member2, 1);
$community->add_member( $member3, 1);

ok $sampler = Bio::Community::Tools::Sampler->new( -community => $community );


# Uneven community

$community = Bio::Community->new();
$community->add_member( $member1, 100);
$community->add_member( $member2, 10);
$community->add_member( $member3, 1);

ok $sampler = Bio::Community::Tools::Sampler->new( -community => $community );


done_testing();

exit;
