use strict;
use warnings;
use Bio::Root::Test;
use Bio::Community::Member;
use Bio::Community;

use_ok($_) for qw(
    Bio::Community::Tools::Sampler
);


my ($member1, $member2, $member3, $community, $sampler, $rand_member,
    $rand_community, $count);
my %descs;

$member1 = Bio::Community::Member->new( -desc => 'A' );
$member2 = Bio::Community::Member->new( -desc => 'B' );
$member3 = Bio::Community::Member->new( -desc => 'C' );


# Even community

$community = Bio::Community->new();
$community->add_member( $member1, 1);
$community->add_member( $member2, 1);
$community->add_member( $member3, 1);

ok $sampler = Bio::Community::Tools::Sampler->new( -community => $community );
isa_ok $sampler, 'Bio::Community::Tools::Sampler';

$count = 100;
for (1 .. $count) {
   ok $rand_member = $sampler->get_rand_member;
   isa_ok $rand_member, 'Bio::Community::Member';
   $descs{$rand_member->desc} = undef;
}
is_deeply \%descs, { 'A' => undef, 'B' => undef, 'C' => undef };


# Uneven community

$community = Bio::Community->new();
$community->add_member( $member1, 100);
$community->add_member( $member2, 10);
$community->add_member( $member3, 1);

ok $sampler = Bio::Community::Tools::Sampler->new( -community => $community );

$count = 1000;
for (1 .. $count) {
   ok $rand_member = $sampler->get_rand_member;
   isa_ok $rand_member, 'Bio::Community::Member';
   $descs{$rand_member->desc}++;
}
cmp_ok( $descs{'A'}, '>=',  500 ); # should be 1000
cmp_ok( $descs{'A'}, '<=', 1500 );
cmp_ok( $descs{'B'}, '>=',   50 ); # should be  100
cmp_ok( $descs{'B'}, '<=',  150 );
cmp_ok( $descs{'C'}, '>=',    4 ); # should be   10
cmp_ok( $descs{'C'}, '<=',   16 );

ok $rand_community = $sampler->get_rand_community($count);

isa_ok $rand_community, 'Bio::Community';
cmp_ok( $rand_community->get_count($member1), '>=',  500 ); # should be 1000
cmp_ok( $rand_community->get_count($member1), '<=', 1500 );
cmp_ok( $rand_community->get_count($member2), '>=',   50 ); # should be  100
cmp_ok( $rand_community->get_count($member2), '<=',  150 );
cmp_ok( $rand_community->get_count($member3), '>=',    4 ); # should be   10
cmp_ok( $rand_community->get_count($member3), '<=',   16 );


done_testing();

exit;
