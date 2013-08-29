use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::Community;
use Bio::Community::Member;

use_ok($_) for qw(
    Bio::Community::Alpha
);


my ($alpha, $comm);


# Community for which to measure alpha diversity

$comm = Bio::Community->new;
$comm->add_member( Bio::Community::Member->new(-id=>1), 1 );
$comm->add_member( Bio::Community::Member->new(-id=>2), 2 );
$comm->add_member( Bio::Community::Member->new(-id=>3), 3 );


# Basic object

$alpha = Bio::Community::Alpha->new( -community => $comm );
isa_ok $alpha, 'Bio::Community::Alpha';


# Test richness

delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'observed' )->get_alpha, 3.0, 'Richness';
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'menhinick')->get_alpha, 1.22474487139159;
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'margalef' )->get_alpha, 1.11622125310249;
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'chao1'    )->get_alpha, 3.0;


# Test evenness

delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'shannon_e')->get_alpha, 0.920619835714305, 'Evenness';
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'simpson_e')->get_alpha, 0.916666666666667;


# Test composite metrics

delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'shannon'  )->get_alpha, 1.01140426470735, 'Composite';
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'simpson'  )->get_alpha, 0.611111111111111;
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'simpson_r')->get_alpha, 2.57142857142857;


# Extra tests

$comm = Bio::Community->new;
$comm->add_member( Bio::Community::Member->new(-id=>1), 1 );
$comm->add_member( Bio::Community::Member->new(-id=>2), 2 );
$comm->add_member( Bio::Community::Member->new(-id=>3), 3 );
$comm->add_member( Bio::Community::Member->new(-id=>4), 1 );

delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'chao1'    )->get_alpha, 4.5, 'Extra';


done_testing();

exit;
