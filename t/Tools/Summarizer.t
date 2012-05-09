use strict;
use warnings;
use Bio::Root::Test;
use Test::Number::Delta;
use Bio::Community::Member;
use Bio::Community;

use_ok($_) for qw(
    Bio::Community::Tools::Summarizer
);


my ($summarizer, $member1, $member2, $member3, $member4, $member5, $community1,
   $community2, $summaries, $summary, $group, $id);


# Bare object

ok $summarizer = Bio::Community::Tools::Summarizer->new(), 'Bare object';
isa_ok $summarizer, 'Bio::Community::Tools::Summarizer';


# Test with multiple communities

$member1 = Bio::Community::Member->new( -desc => 'A' );
$member2 = Bio::Community::Member->new( -desc => 'B' );
$member3 = Bio::Community::Member->new( -desc => 'C' );
$member4 = Bio::Community::Member->new( -desc => 'D' );
$member5 = Bio::Community::Member->new( -desc => 'E' );

$community1 = Bio::Community->new();
$community1->add_member( $member1, 1 );
$community1->add_member( $member2, 95);
$community1->add_member( $member3, 1 );
$community1->add_member( $member4, 3 );

$community2 = Bio::Community->new( -name => 'grassland' );
$community2->add_member( $member1, 8 );
$community2->add_member( $member2, 90);
$community2->add_member( $member3, 1 );
$community2->add_member( $member5, 1 );

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -communities => [$community1, $community2],
   -group       => ['<', 2],
), 'Multiple communities';

is_deeply $summarizer->communities, [$community1, $community2];
is_deeply $summarizer->group, ['<', 2];

ok $summaries = $summarizer->get_summaries;
is scalar @$summaries, 2;

$summary = $summaries->[0];

$group = get_group($summary);
isa_ok $group, 'Bio::Community::Member';
is $group->desc, 'Other < 2 %';
$id = $group->id;

is $summary->name, 'Unnamed community summarized';
delta_ok $summary->get_count($member1), 1;
delta_ok $summary->get_count($member2), 95;
delta_ok $summary->get_count($member3), 0;
delta_ok $summary->get_count($member4), 3;
delta_ok $summary->get_count($member5), 0;
delta_ok $summary->get_count($group)  , 1;

$summary = $summaries->[1];
$group = get_group($summary);
is $group->id, $id; # different object because the weight is different,
                          # but ID need to be the same
is $summary->name, 'grassland summarized';
delta_ok $summary->get_count($member1), 8;
delta_ok $summary->get_count($member2), 90;
delta_ok $summary->get_count($member3), 0;
delta_ok $summary->get_count($member4), 0;
delta_ok $summary->get_count($member5), 0;
delta_ok $summary->get_count($group)  , 2;

$summary = $summaries->[0];


# Test community where nothing is to be grouped.

$community1 = Bio::Community->new();
$community1->add_member( $member1, 100 );

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -communities => [$community1],
   -group       => ['<', 2],
), 'No grouping';

ok $summaries = $summarizer->get_summaries;
is scalar @$summaries, 1;

$summary = $summaries->[0];
delta_ok $summary->get_count($member1), 100;

$group = get_group($summary);
is $group, undef;


# Test <= operators

$community1 = Bio::Community->new();
$community1->add_member( $member1,  2 );
$community1->add_member( $member2, 98 );

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -communities => [$community1],
   -group       => ['<=', 2],
), "Operator '<='";

ok $summaries = $summarizer->get_summaries;
is scalar @$summaries, 1;

$summary = $summaries->[0];
ok $group = get_group($summary);
delta_ok $summary->get_count($member1), 0;
delta_ok $summary->get_count($member2), 98;
delta_ok $summary->get_count($group  ), 2;


# Test < operators

$community1 = Bio::Community->new();
$community1->add_member( $member1,  1 );
$community1->add_member( $member2, 99 );

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -communities => [$community1],
   -group       => ['<', 2],
), "Operator '<'";

ok $summaries = $summarizer->get_summaries;
is scalar @$summaries, 1;

$summary = $summaries->[0];
ok $group = get_group($summary);
delta_ok $summary->get_count($member1), 0;
delta_ok $summary->get_count($member2), 99;
delta_ok $summary->get_count($group  ), 1;


# Test > operators

$community1 = Bio::Community->new();
$community1->add_member( $member1,  1 );
$community1->add_member( $member2, 99 );

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -communities => [$community1],
   -group       => ['>', 2],
), "Operator '>'";

ok $summaries = $summarizer->get_summaries;
is scalar @$summaries, 1;

$summary = $summaries->[0];
ok $group = get_group($summary);
delta_ok $summary->get_count($member1), 1;
delta_ok $summary->get_count($member2), 0;
delta_ok $summary->get_count($group  ), 99;


# Test >= operators

$community1 = Bio::Community->new();
$community1->add_member( $member1,  1 );
$community1->add_member( $member2, 99 );

ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -communities => [$community1],
   -group       => ['>=', 2],
), "Operator '>='";

ok $summaries = $summarizer->get_summaries;
is scalar @$summaries, 1;

$summary = $summaries->[0];
ok $group = get_group($summary);
delta_ok $summary->get_count($member1), 1;
delta_ok $summary->get_count($member2), 0;
delta_ok $summary->get_count($group  ), 99;


# Test with multiple communities with weighted members

$member1 = Bio::Community::Member->new( -desc => 'A', -weights => [1] );
$member2 = Bio::Community::Member->new( -desc => 'B', -weights => [2] );
$member3 = Bio::Community::Member->new( -desc => 'C', -weights => [3] );
$member4 = Bio::Community::Member->new( -desc => 'D', -weights => [4] );

$community1 = Bio::Community->new();
$community1->add_member( $member1, 87 );
$community1->add_member( $member2,  1 );
$community1->add_member( $member3,  2 );
$community1->add_member( $member4, 10 );

$community2 = Bio::Community->new( -name => 'grassland' );
$community2->add_member( $member1, 25 );
$community2->add_member( $member2, 25 );
$community2->add_member( $member3, 25 );
$community2->add_member( $member4, 25 );

delta_ok $community1->get_rel_ab($member1), 95.9558824;
delta_ok $community1->get_rel_ab($member2),  0.5514706;
delta_ok $community1->get_rel_ab($member3),  0.7352941;
delta_ok $community1->get_rel_ab($member4),  2.7573529;

delta_ok $community2->get_rel_ab($member1), 48.0000000;
delta_ok $community2->get_rel_ab($member2), 24.0000000;
delta_ok $community2->get_rel_ab($member3), 16.0000000;
delta_ok $community2->get_rel_ab($member4), 12.0000000;


ok $summarizer = Bio::Community::Tools::Summarizer->new(
   -communities => [$community1, $community2],
   -group       => ['<', 20],
), 'Multiple weighted communities';

ok $summaries = $summarizer->get_summaries;
is scalar @$summaries, 2;

$summary = $summaries->[0];
$group = get_group($summary);
$id = $group->id;
is $summary->name, 'Unnamed community summarized';
delta_ok $summary->get_rel_ab($member1), 95.9558824;
delta_ok $summary->get_rel_ab($member2),  0.5514706;
delta_ok $summary->get_rel_ab($member3),  0;
delta_ok $summary->get_rel_ab($member4),  0;
delta_ok $summary->get_rel_ab($group)  ,  3.4926470;

$summary = $summaries->[1];
$group = get_group($summary);
is $group->id, $id;
is $summary->name, 'grassland summarized';
delta_ok $summary->get_rel_ab($member1), 48.0000000;
delta_ok $summary->get_rel_ab($member2), 24.0000000;
delta_ok $summary->get_rel_ab($member3), 0;
delta_ok $summary->get_rel_ab($member4), 0;
delta_ok $summary->get_rel_ab($group)  , 28.0000000;

$summary = $summaries->[0];



sub get_group {
   my ($community) = @_;
   my $group;
   while (my $member = $community->next_member) {
      if ($member->desc =~ m/other/i) {
         $group = $member;
         last;
      }
   }
   return $group;
}


done_testing();

exit;

