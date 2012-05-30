# BioPerl module for Bio::Community::Tools::ShrapnelCleaner
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::ShrapnelCleaner - Remove unique, low-abundance members 

=head1 SYNOPSIS

  use Bio::Community::Tools::ShrapnelCleaner;

  # Remove singletons from $community1 and $community2
  my $cleaner = Bio::Community::Tools::ShrapnelCleaner->new(
     -communities => [$community1, $community2],
  );
  $cleaner->clean;

=head1 DESCRIPTION

This module takes biological communities and remove shrapnel, low abundance,
low prevalence members that are likely to be the result of sequencing errors
(when doing sequence-based analyses). By default, only the cleaner removes only
singletons, i.e. community members that appear in only one community (prevalence
of 1) and have only 1 count. You can specify your own count and prevalence
thresholds though.

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

 Function: Create a new Bio::Community::Tool::ShrapnelCleaner object
 Usage   : my $cleaner = Bio::Community::Tool::ShrapnelCleaner->new( );
 Args    : -communities, -count_threshold. See details below.
 Returns : a new Bio::Community::Tools::ShrapnelCleaner object

=cut


package Bio::Community::Tools::ShrapnelCleaner;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;

extends 'Bio::Root::Root';


=head2 communities

 Function: Get or set the communities to process.
 Usage   : my $communities = $cleaner->communities;
 Args    : arrayref of Bio::Community objects
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


=head2 count_threshold

 Function: Get or set the count threshold. Community members with a count equal
           or lower than this threshold are removed (provided they also meet the
           prevalence_threshold).
 Usage   : my $count_thresh = $cleaner->count_threshold;
 Args    : positive integer for the count
 Returns : positive integer for the count

=cut

has count_threshold => (
   is => 'rw',
   isa => 'Maybe[PositiveNum]',
   required => 0, 
   default => 1,
   lazy => 1,
   init_arg => '-count_threshold',
);


=head2 prevalence_threshold

 Function: Get or set the prevalence threshold. Community members with a count
           equal or lower than this threshold are removed (provided they also
           meet the count_threshold).
 Usage   : my $prevalence_thresh = $cleaner->prevalence_threshold;
 Args    : positive integer for the prevalence
 Returns : positive integer for the prevalence

=cut

has prevalence_threshold => (
   is => 'rw',
   isa => 'Maybe[PositiveNum]',
   required => 0, 
   default => 1,
   lazy => 1,
   init_arg => '-prevalence_threshold',
);


=head2 clean

 Function: Remove singletons from the communities and return the updated
           communities.
 Usage   : my $communities = $cleaner->clean;
 Args    : none
 Returns : arrayref of Bio::Community objects

=cut

method clean {
   # Sanity check
   my $communities = $self->communities;
   if (scalar @$communities == 0) {
      $self->throw('Need to provide at least one community');
   }

   # Get all members
   my $members = $communities->[0]->get_all_members($communities);

   # Remove singletons
   my $count_thresh = $self->count_threshold;
   my $prevalence_thresh = $self->prevalence_threshold;
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
      if ( ($total_count <= $count_thres) && ($prevalence <= $prevalence_thres) ) {
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
