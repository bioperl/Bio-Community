use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::Community;
use Bio::Community::Member;

use_ok($_) for qw(
    Bio::Community::Alpha
);


my ($alpha, $c1, $c2);


# Communities for which to measure alpha diversity

$c1 = Bio::Community->new;
$c1->add_member( Bio::Community::Member->new(-id=>1), 1 );
$c1->add_member( Bio::Community::Member->new(-id=>2), 2 );
$c1->add_member( Bio::Community::Member->new(-id=>3), 3 );

$c2 = Bio::Community->new;
$c2->add_member( Bio::Community::Member->new(-id=>1), 1  );
$c2->add_member( Bio::Community::Member->new(-id=>2), 2  );
$c2->add_member( Bio::Community::Member->new(-id=>3), 11 );
$c2->add_member( Bio::Community::Member->new(-id=>4), 1  );


# Basic object

$alpha = Bio::Community::Alpha->new( -community=>$c1 );
isa_ok $alpha, 'Bio::Community::Alpha';


# Test richness

delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'observed' )->get_alpha, 3.0, 'Richness';
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'menhinick')->get_alpha, 1.22474487139159;
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'margalef' )->get_alpha, 1.11622125310249;
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'chao1'    )->get_alpha, 3.0;
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'ace'      )->get_alpha, 3.6;

delta_ok Bio::Community::Alpha->new(-community=>$c2, -type=>'chao1'    )->get_alpha, 4.5;
delta_ok Bio::Community::Alpha->new(-community=>$c2, -type=>'ace'      )->get_alpha, 7.0;


# Test evenness

delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'buzas'      )->get_alpha, 0.916486424665735, 'Evenness';
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'heip'       )->get_alpha, 0.874729636998600;
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'shannon_e'  )->get_alpha, 0.920619835714305;
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'simpson_e'  )->get_alpha, 0.916666666666667;
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'brillouin_e')->get_alpha, 0.909892831516493;
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'hill_e'     )->get_alpha, 0.935248830832905;
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'mcintosh_e' )->get_alpha, 0.881917103688197;
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'camargo'    )->get_alpha, 0.777777777777778;


# Test composite metrics

delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'shannon'  )->get_alpha, 1.01140426470735, 'Composite';
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'simpson'  )->get_alpha, 0.611111111111111;
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'simpson_r')->get_alpha, 2.57142857142857;
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'brillouin')->get_alpha, 0.682390760370350;
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'hill'     )->get_alpha, 2.0;
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'mcintosh' )->get_alpha, 0.636061424871458;


# Test dominance

delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'simpson_d')->get_alpha, 0.388888888888889, 'Dominance';
delta_ok Bio::Community::Alpha->new(-community=>$c1, -type=>'berger'   )->get_alpha, 0.5;


### Tests with max or min evenness / richness.

### Compare results to estimateS or vegan or QIIME alpha_diversity.py

### Should have an error when calculating ACE or chao1 with non-integers

### Test Brillouin's factorial with 100,000 individuals (should still be quite fast)

### What if communities have a richness of zero?

### What happens for evenness when communities has richness < 2. What does the evenness of a single species mean??

done_testing();

exit;
