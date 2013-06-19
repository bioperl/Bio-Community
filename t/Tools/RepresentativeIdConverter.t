use strict;
use warnings;
use Bio::Root::Test;
use Bio::Community::Member;
use Bio::Community;

use_ok($_) for qw(
    Bio::Community::Tools::RepresentativeIdConverter
);


my ($meta1, $meta2, $community1, $community2, $member1, $member2, $member3, $count, $converter);

my %info;


# Test ID conversion to cluster ID representative

$member1 = Bio::Community::Member->new( -id => 187144 );
$member2 = Bio::Community::Member->new( -id => 563209 );
$member3 = Bio::Community::Member->new( -id => 310677 );

$community1 = Bio::Community->new();
$community1->add_member( $member1, 1);
$community1->add_member( $member2, 2);
$community1->add_member( $member3, 3);
$meta1 = Bio::Community::Meta->new( -communities => [$community1] );

ok $converter = Bio::Community::Tools::RepresentativeIdConverter->new(
   -metacommunity => $meta1,
   -cluster_file  => test_input_file('gg_99_otu_map.txt'),
), 'Cluster ID representative';
isa_ok $converter, 'Bio::Community::Tools::RepresentativeIdConverter';

ok $meta2 = $converter->get_converted_meta;
isa_ok $meta2, 'Bio::Community::Meta';
ok $community2 = $meta2->get_all_communities->[0];

%info = ();
while (my $member = $community2->next_member) {
   isa_ok $member, 'Bio::Community::Member';
   my $id = $member->id;
   my $count = $community2->get_count($member);
   $info{$id} = $count;
}
is_deeply \%info, { '187144' => 1, '355095' => 5 };

isnt $meta1, $meta2;


# Test ID conversion to taxonomic ID representative

$member1 = Bio::Community::Member->new( -id => 340 );
$member2 = Bio::Community::Member->new( -id => 345 );
$member3 = Bio::Community::Member->new( -id => 344 );

$community1 = Bio::Community->new();
$community1->add_member( $member1, 1);
$community1->add_member( $member2, 2);
$community1->add_member( $member3, 3);
$meta1 = Bio::Community::Meta->new( -communities => [$community1] );

ok $converter = Bio::Community::Tools::RepresentativeIdConverter->new(
   -metacommunity  => $meta1,
   -taxassign_file => test_input_file('rep_set_tax_assignments.txt'),
);
isa_ok $converter, 'Bio::Community::Tools::RepresentativeIdConverter';

ok $meta2 = $converter->get_converted_meta;
isa_ok $meta2, 'Bio::Community::Meta';
ok $community2 = $meta2->get_all_communities->[0];

%info = ();
while (my $member = $community2->next_member) {
   isa_ok $member, 'Bio::Community::Member';
   my $id = $member->id;
   my $count = $community2->get_count($member);
   $info{$id} = $count;
}
is_deeply \%info, { '1042485' => 5, '219826' => 1 };

isnt $meta1, $meta2;


done_testing();

exit;
