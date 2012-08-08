use strict;
use warnings;
use Bio::Root::Test;

use Bio::Community;
use Bio::Community::Member;

use_ok($_) for qw(
    Bio::Community::Alpha
);


my ($alpha, $comm, $member1, $member2, $member3);


# Community for which to measure alpha diversity

$member1 = Bio::Community::Member->new( -id => 1 );
$member2 = Bio::Community::Member->new( -id => 2 );
$member3 = Bio::Community::Member->new( -id => 3 );

$comm = Bio::Community->new;

$comm->add_member( $member1, 1 );
$comm->add_member( $member2, 2 );
$comm->add_member( $member3, 3 );


# Basic object

$alpha = Bio::Community::Alpha->new( -community => $comm, -type => 'richness' );
isa_ok $alpha, 'Bio::Community::Alpha';


# Test metrics

is Bio::Community::Alpha->new( -community => $comm, -type => 'richness' )->get_alpha, 3;


done_testing();

exit;
