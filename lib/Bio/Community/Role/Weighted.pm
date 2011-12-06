package Bio::Community::Role::Weighted;

use Moose::Role;
use namespace::autoclean;

=head2 weights

 Title   : weights
 Usage   : my $weights = $member->weights();
 Function: Get or set some weights for this object. Weights represent how biased
           the sampling of this organism is. For example, when random shotgun
           sequencing microorganisms in the environment, the relative abundance
           of reads in the sequence library is not proportional to the relative
           abundance of the genomes because larger genomes contribute
           disproportionalely more reads than small genomes. In such a case, you
           could set the weight to the length of the genome.
 Args    : An arrayref of positive integers
 Returns : An arrayref of positive integers

=cut

has weights => (
   is => 'rw',
   isa => 'Maybe[ArrayRef[StrictlyPositiveNum]]',
   required => 0,
   default => sub{[ 1 ]},
   init_arg => '-weights',
   lazy => 1,
);


1;
