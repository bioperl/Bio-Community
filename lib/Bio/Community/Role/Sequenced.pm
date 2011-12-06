package Bio::Community::Role::Sequenced;

use Moose::Role;
use namespace::autoclean;

=head2 seqs

 Title   : seqs
 Usage   : my $seqs = $member->seqs();
 Function: Get or set some sequences for this object.
 Args    : An arrayref of Bio::SeqI objects
 Returns : An arrayref of Bio::SeqI objects

=cut

has seqs => (
   is => 'rw',
   isa => 'Maybe[ArrayRef[Bio::PrimarySeqI]]',
   required => 0,
   default => sub{ [] },
   init_arg => '-seqs',
   lazy => 1,
);


1;
