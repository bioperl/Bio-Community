use strict;
use warnings;
use Bio::Root::Test;
use Bio::Taxon;

use_ok($_) for qw(
    Bio::Community::Member
);

my ($member, $taxon);

# Test ID

ok $member = Bio::Community::Member->new( -id => 2 ), 'ID';
is $member->id(), 2;

isa_ok $member, 'Bio::Root::RootI';
isa_ok $member, 'Bio::Community::Member';

ok $member = Bio::Community::Member->new( );
is $member->id, 1;

ok $member = Bio::Community::Member->new( );
is $member->id, 3;


# Test description

ok $member = Bio::Community::Member->new( -desc => 'H. sapiens' ), 'description';
is $member->desc(), 'H. sapiens';

ok $member->desc('mouse');
ok $member->desc(), 'mouse';

ok $member = Bio::Community::Member->new( );
is $member->desc, '';


# Test taxon

$taxon = Bio::Taxon->new( -name => 'some_taxon' );
ok $member = Bio::Community::Member->new( -taxon => $taxon ), 'taxon';
is $member->taxon(), $taxon;

$taxon = Bio::Taxon->new( -name => 'some_other_taxon' );
ok $member->taxon($taxon);
ok $member->taxon(), $taxon;

ok $member = Bio::Community::Member->new( );
is $member->taxon, undef;


done_testing();

exit;
