# BioPerl module for Bio::Community::Tools::SingletonRemover
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::SingletonRemover - Remove unique, low-abundance members 

=head1 SYNOPSIS

  use Bio::Community::Tools::SingletonRemover;

  # Remove singletons from $community1 and $community2
  my $remover = Bio::Community::Tools::SingletonRemover->new(
     -communities => [$community1, $community2],
  );
  $remover->remove;

=head1 DESCRIPTION

This module takes biological communities and remove all singles, i.e. community
members that appear in only one community and have only 1 count (or any
threshold you supply). The purpose behind this is that analyses of communities
that use amplicon sequences as a species markers are biased by sequencing errors.
Removing community members that are specific to a community and have a very low
count (likely to be erroneous) may provide a more accurate picture of community
composition.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this
and other Bioperl modules. Send your comments and suggestions preferably
to one of the Bioperl mailing lists.

Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support 

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and 
reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem 
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via the
web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR - Florent Angly

Email florent.angly@gmail.com

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=head2 new

 Function: Create a new Bio::Community::Tool::SingletonRemover object
 Usage   : my $remover = Bio::Community::Tool::SingletonRemover->new( );
 Args    : -communities, -threshold. See details below.
 Returns : a new Bio::Community::Tools::SingletonRemover object

=cut


package Bio::Community::Tools::SingletonRemover;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;

extends 'Bio::Root::Root';


=head2 communities

 Function: Get or set the communities to process.
 Usage   : my $communities = $remover->communities;
 Args    : arrayref of Bio::Community objects or nothing
 Returns : arrayref of Bio::Community objects

=cut

has communities => (
   is => 'rw',
   isa => 'ArrayRef[Bio::Community]',
   required => 0,
   default => sub{ [] },
   lazy => 1,
   init_arg => '-communities',
);


=head2 threshold

 Function: Get or set the threshold. Community members appearing in a single
           community, and with a count equal or lower than this threshold are
           removed.
 Usage   : my $threshold = $remover->threshold;
 Args    : positive integer for the number of repetitions
 Returns : positive integer for the (minimum) number of repetitions

=cut

has threshold => (
   is => 'rw',
   isa => 'Maybe[PositiveNum]',
   required => 0, 
   default => 1,
   lazy => 1,
   init_arg => '-threshold',
);


=head2 remove

 Function: Remove singletons from the communities and return the updated
           communities.
 Usage   : my $communities = $remover->remove;
 Args    : none
 Returns : arrayref of Bio::Community objects

=cut


method remove {
   # Sanity check
   my $communities = $self->communities;
   if (scalar @$communities == 0) {
      $self->throw('Need to provide at least one community');
   }

   # Get all members
   my $members = $communities->[0]->get_all_members($communities);

   # Remove singletons
   my $threshold = $self->threshold;
   for my $member ( @$members ) {
      my $total_count = 0; # sum of member counts in all communities
      my $prevalence  = 0; # in how many communities was the member seen
      for my $community (@$communities) {
         my $count = $community->get_count($member);
         if ($count > 0) {
            $prevalence++;
            $total_count += $count;
         }
      }
      if ( ($total_count <= $threshold) && ($prevalence <= 1) ) {
         # Remove all of this member
         for my $community (@$communities) {
            $community->remove_member($member);
         }
      }
   }

   return $communities;
}


__PACKAGE__->meta->make_immutable;

1;
