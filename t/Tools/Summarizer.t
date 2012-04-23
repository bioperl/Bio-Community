use strict;
use warnings;
use Bio::Root::Test;
use Bio::Community::Member;
use Bio::Community;

use_ok($_) for qw(
    Bio::Community::Tools::Summarizer
);


my ($summarizer, $member1, $member2, $member3, $community1, $community2,
   $summaries, $summary1, $summary2);


# Bare object

ok $summarizer = Bio::Community::Tools::Summarizer->new();
isa_ok $summarizer, 'Bio::Community::Tools::Summarizer';


# Create some test communities:

$member1 = Bio::Community::Member->new( -desc => 'A' );
$member2 = Bio::Community::Member->new( -desc => 'B' );
$member3 = Bio::Community::Member->new( -desc => 'C' );
$member3 = Bio::Community::Member->new( -desc => 'D' );

$community1 = Bio::Community->new();
$community1->add_member( $member1,   1); # 0.1%
$community1->add_member( $member2,  10); # 1%
$community1->add_member( $member3, 989); # 98.8%

$community2 = Bio::Community->new();
$community2->add_member( $member1,  1);
$community2->add_member( $member2,  1);
$community2->add_member( $member3, 98);

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -communities => [$community1, $community2],
   -group       => ['<', 10],
);

ok $summaries = $summarizer->get_summaries;
#is_deeply $summarizer->communities, [$community1, $community2];










#### Even community



###ok $sampler = Bio::Community::Tools::Sampler->new( -community => $community );

###$count = 100;
###for (1 .. $count) {
###   ok $rand_member = $sampler->get_rand_member;
###   isa_ok $rand_member, 'Bio::Community::Member';
###   $descs{$rand_member->desc} = undef;
###}
###is_deeply \%descs, { 'A' => undef, 'B' => undef, 'C' => undef };


#### Uneven community

###$community = Bio::Community->new();
###$community->add_member( $member1, 100);
###$community->add_member( $member2, 10);
###$community->add_member( $member3, 1);

###ok $sampler = Bio::Community::Tools::Sampler->new( -community => $community );

###$count = 1000;
###for (1 .. $count) {
###   ok $rand_member = $sampler->get_rand_member;
###   isa_ok $rand_member, 'Bio::Community::Member';
###   $descs{$rand_member->desc}++;
###}
###cmp_ok( $descs{'A'}, '>=',  500 ); # should be 1000
###cmp_ok( $descs{'A'}, '<=', 1500 );
###cmp_ok( $descs{'B'}, '>=',   50 ); # should be  100
###cmp_ok( $descs{'B'}, '<=',  150 );
###cmp_ok( $descs{'C'}, '>=',    4 ); # should be   10
###cmp_ok( $descs{'C'}, '<=',   15 );

###ok $rand_community = $sampler->get_rand_community($count);

###isa_ok $rand_community, 'Bio::Community';
###cmp_ok( $rand_community->get_count($member1), '>=',  500 ); # should be 1000
###cmp_ok( $rand_community->get_count($member1), '<=', 1500 );
###cmp_ok( $rand_community->get_count($member2), '>=',   50 ); # should be  100
###cmp_ok( $rand_community->get_count($member2), '<=',  150 );
###cmp_ok( $rand_community->get_count($member3), '>=',    5 ); # should be   10
###cmp_ok( $rand_community->get_count($member3), '<=',   15 );


done_testing();

exit;

