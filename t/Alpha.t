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

delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'observed'  )->get_alpha, 3.0, 'Richness';
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'menhinick' )->get_alpha, 1.22474487139159;
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'margalef'  )->get_alpha, 1.11622125310249;
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'chao1'     )->get_alpha, 3.0;
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'ace'       )->get_alpha, 3.6;


# Test evenness

delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'buzas'     )->get_alpha, 0.916486424665735, 'Evenness';
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'shannon_e' )->get_alpha, 0.920619835714305;
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'simpson_e' )->get_alpha, 0.916666666666667;
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'hill'      )->get_alpha, 2.0;


# Test composite metrics

delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'shannon'   )->get_alpha, 1.01140426470735, 'Composite';
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'simpson'   )->get_alpha, 0.611111111111111;
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'simpson_r' )->get_alpha, 2.57142857142857;


# Test dominance
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'simpson_d' )->get_alpha, 0.388888888888889, 'Dominance';
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'berger'    )->get_alpha, 0.5;



# Extra tests

$comm = Bio::Community->new;
$comm->add_member( Bio::Community::Member->new(-id=>1), 1  );
$comm->add_member( Bio::Community::Member->new(-id=>2), 2  );
$comm->add_member( Bio::Community::Member->new(-id=>3), 11 );
$comm->add_member( Bio::Community::Member->new(-id=>4), 1  );

delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'chao1'    )->get_alpha, 4.5, 'Extra';
delta_ok Bio::Community::Alpha->new(-community => $comm, -type => 'ace'      )->get_alpha, 7.0, 'Extra';


### Tests with max or min evenness.

### Compare results to estimateS or vegan or QIIME alpha_diversity.py

### Should have an error when calculating ACE or chao1 with non-integers

done_testing();

exit;
