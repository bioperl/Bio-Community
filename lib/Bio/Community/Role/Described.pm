package Bio::Community::Role::Described;

use Moose::Role;
use namespace::autoclean;

=head2 desc

 Title   : desc
 Usage   : my $description = $member->desc();
 Function: Get or set a description for this object.
 Args    : A string
 Returns : A string

=cut

has desc => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   default => '',
   init_arg => '-desc',
   lazy => 1,
);


1;
