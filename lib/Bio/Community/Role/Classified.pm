package Bio::Community::Role::Classified;

use Moose::Role;
use namespace::autoclean;

=head2 taxon

 Title   : taxon
 Usage   : my $taxon = $member->taxon();
 Function: Get or set a taxon (or species) for this object.
 Args    : A Bio::Taxon object
 Returns : A Bio::Taxon object

=cut

has taxon => (
   is => 'rw',
   isa => 'Maybe[Bio::Taxon]',
   required => 0,
   default => undef,
   init_arg => '-taxon',
   lazy => 1,
);


1;
