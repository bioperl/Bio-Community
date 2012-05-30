use strict;
use warnings;
use Bio::Root::Test;
#use Test::Number::Delta;
use Bio::Community;

use_ok($_) for qw(
    Bio::Community::Tools::SingletonRemover
);


my ($remover, $community1, $community2, $member1, $member2, $member3, $member4,
    $member5, $member6);

my $epsilon1 = 20;
my $epsilon2 = 1.5;
my $epsilon3 = 0.4;


$member1 = Bio::Community::Member->new( -id => 1 );
$member2 = Bio::Community::Member->new( -id => 2 );
$member3 = Bio::Community::Member->new( -id => 3 );
$member4 = Bio::Community::Member->new( -id => 4 );
$member5 = Bio::Community::Member->new( -id => 5 );
$member6 = Bio::Community::Member->new( -id => 6 );


# Two communities

$community1 = Bio::Community->new( -name => 'community1' );
$community1->add_member( $member1,   1);
$community1->add_member( $member2,   1);
$community1->add_member( $member3,   5);
$community1->add_member( $member4,   1);
$community1->add_member( $member5, 125);

$community2 = Bio::Community->new( );
$community2->add_member( $member1,   1);
$community2->add_member( $member3, 100);
$community2->add_member( $member6,   4);


# Basic remover object

ok $remover = Bio::Community::Tools::SingletonRemover->new( );
isa_ok $remover, 'Bio::Community::Tools::SingletonRemover';


# Remover with default

ok $remover = Bio::Community::Tools::SingletonRemover->new(
   -communities => [ $community1, $community2 ],
), 'Default';
ok $remover->remove;

is $community1->get_count($member1),   1;
is $community1->get_count($member2),   0;
is $community1->get_count($member3),   5;
is $community1->get_count($member4),   0;
is $community1->get_count($member5), 125;
is $community1->get_count($member6),   0;

is $community2->get_count($member1),   1;
is $community2->get_count($member2),   0;
is $community2->get_count($member3), 100;
is $community2->get_count($member4),   0;
is $community2->get_count($member5),   0;
is $community2->get_count($member6),   4;


# Remover with specified threshold

ok $remover = Bio::Community::Tools::SingletonRemover->new(
   -communities => [ $community1, $community2 ],
   -threshold   => 5,
), 'Specified threshold';
ok $remover->remove;

is $community1->get_count($member1),   1;
is $community1->get_count($member2),   0;
is $community1->get_count($member3),   5;
is $community1->get_count($member4),   0;
is $community1->get_count($member5), 125;
is $community1->get_count($member6),   0;

is $community2->get_count($member1),   1;
is $community2->get_count($member2),   0;
is $community2->get_count($member3), 100;
is $community2->get_count($member4),   0;
is $community2->get_count($member5),   0;
is $community2->get_count($member6),   0;


done_testing();

exit;
