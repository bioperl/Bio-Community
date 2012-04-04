use strict;
use warnings;
use Bio::Root::Test;

use Bio::Taxon;
use Bio::Seq;
use Bio::PrimarySeq;

use_ok($_) for qw(
    Bio::Community::Member
);

my ($member, $taxon, $sequence1, $sequence2);


# Test object type

ok $member = Bio::Community::Member->new( );

isa_ok $member, 'Bio::Root::RootI';
isa_ok $member, 'Bio::Community::Member';


# Test ID

ok $member = Bio::Community::Member->new( -id => 3 ), 'ID';
is $member->id, 3;

ok $member = Bio::Community::Member->new( -id => 0 );
is $member->id, 0;

ok $member = Bio::Community::Member->new( -id => 'asdf' );
is $member->id, 'asdf';

ok $member = Bio::Community::Member->new( );
is $member->id, 2;

ok $member = Bio::Community::Member->new( );
is $member->id, 4;


# Test description

ok $member = Bio::Community::Member->new( -desc => 'H. sapiens' ), 'Description';
is $member->desc(), 'H. sapiens';

ok $member->desc('mouse');
is $member->desc(), 'mouse';

ok $member = Bio::Community::Member->new( );
is $member->desc, '';


# Test taxon

$taxon = Bio::Taxon->new( -name => 'some_taxon' );
ok $member = Bio::Community::Member->new( -taxon => $taxon ), 'Taxon';
is $member->taxon(), $taxon;

$taxon = Bio::Taxon->new( -name => 'some_other_taxon' );
ok $member->taxon($taxon);
is $member->taxon(), $taxon;

ok $member = Bio::Community::Member->new( );
is $member->taxon, undef;


# Test sequences

$sequence1 = Bio::PrimarySeq->new( -seq => 'AACGT' );
$sequence2 = Bio::PrimarySeq->new( -seq => 'AACGAAAAA' );
ok $member = Bio::Community::Member->new( -seqs => [ $sequence1, $sequence2 ] ), 'Sequences';
is_deeply $member->seqs(), [$sequence1, $sequence2];

$sequence1 = Bio::PrimarySeq->new( -seq => 'AACGAAAAA' );
ok $member->seqs([$sequence1]);
is_deeply $member->seqs(), [$sequence1];

ok $member = Bio::Community::Member->new( );
is_deeply $member->seqs, [];


# Test weights

ok $member = Bio::Community::Member->new( -weights => [ 0.1, 3 ] ), 'Weights';
is_deeply $member->weights(), [ 0.1, 3 ];

ok $member->weights([4124]);
is_deeply $member->weights(), [4124];

ok $member = Bio::Community::Member->new( );
is_deeply $member->weights, [ 1 ];


done_testing();

exit;
