# BioPerl module for Bio::Community::Tools::Summarizer
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::Summarizer - Create a summary of a community

=head1 SYNOPSIS

  use Bio::Community::Tools::Summarizer;

  # Group community members less than 1% into a single group
  my $summarizer = Bio::Community::Tools::Summarizer->new(
     -communities => [$community1, $community2],
     -group       => ['<', 1],
  );
  my $summarized_communities = $summarizer->get_summaries;

=head1 DESCRIPTION

Summarize a community by collapsing or removing members smaller than a threshold.

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

 Function: Create a new Bio::Community::Tool::Summarizer object
 Usage   : my $summarizer = Bio::Community::Tools::Summarizer->new(
              -communities => [ $community1, $community2 ],
           );
 Args    : -communities
              An arrayref of the communities (Bio::Community objects) to
              calculate the summary from.
 Returns : a Bio::Community::Tools::Summarizer object

=cut


package Bio::Community::Tools::Summarizer;

use Moose;
use MooseX::NonMoose;
use MooseX::Method::Signatures;
use namespace::autoclean;

extends 'Bio::Root::Root';


=head2 communities

 Function: Get/set the communities to summarize.
 Usage   : my $communities = $summarizer->get_communities;
 Args    : an arrayref of Bio::Community objects
 Returns : an arrayref of Bio::Community objects

=cut

has communities => (
   is => 'rw',
   isa => 'ArrayRef[Bio::Community]',
   required => 0,
   lazy => 1,
   default => sub{ [] },
   init_arg => '-communities',
);


=head2 group

 Function: Get/set the relative abundance threshold to group members together.
           Example: You provide multiple communities and specify to group
           members with a relative abundance less than 1%. If member A is at
           less than 1% in all the communities, it is removed from the
           communities and added as a new member with the desciption 'Other < 1%'
           along with all other members that are less than 1% in all the
           communities.
 Usage   : $summarizer->group('<', 1);
 Args    : * the type of numeric comparison, '<', '<=', '>=', '>'
           * the relative abundance threshold (in %)
 Returns : * the type of numeric comparison, '<', '<=', '>=', '>'
           * the relative abundance threshold (in %)

=cut

has group => (
   is => 'rw',
   isa => 'ArrayRef[Str]',
   ### hot to specify a different type for first and second element of arrayref?
   ###   ArrayRef[Str, Num]
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-group',
);


=head2 get_summaries

 Function: Summarize the communities and return an arrayref of fresh communities.
 Usage   : my $summaries = $summarizer->get_summary;
 Args    : none
 Returns : an arrayref of Bio::Community objects

=cut

method get_summaries {
   my $communities = $self->communities;

   if (scalar @$communities == 0) {
      $self->throw("Need to provide at least one community.");
   }

   # Create fresh community objects to hold the summaries
   my $summaries = [
      map { Bio::Community->new( -name => $_->name.' summarized') } @$communities
   ];

   my $members = $communities->[0]->get_all_members($communities);


   ### First filter out members TODO

   # Then group members
   my $grouping_params = $self->group;
   if (defined $self->group) {
      $summaries = $self->_group_by_relative_abundance($members, $communities,
         $summaries, $grouping_params);
   }

   ### Finally summarize by taxonomy TODO

   return $summaries;
};


method _group_by_relative_abundance (
   ArrayRef[Bio::Community::Member] $members,
   ArrayRef[Bio::Community] $communities, ArrayRef[Bio::Community] $summaries,
   ArrayRef[Str] $params 
) {

   # Get grouping parameters
   my $thresh   = $params->[1] || $self->throw("No grouping threshold was provided.");
   my $operator = $params->[0] || $self->throw("No comparison operator was provided.");
   my $cmp;
   if      ($operator eq '<' ) {
      $cmp =  sub { $_[0] < $_[1] };
   } elsif ($operator eq '<=' ) {
      $cmp =  sub { $_[0] <= $_[1] };
   } elsif ($operator eq '>=' ) {
      $cmp =  sub { $_[0] >= $_[1] };
   } elsif ($operator eq '>' ) {
      $cmp =  sub { $_[0] > $_[1] };
   } else {
      $self->throw("Invalid comparison operator provided, '$operator'.");
   }


   my $nof_communities = scalar @$communities;
   my $group_count = [(0) x $nof_communities];
   my $total_group_count = 0;
   for my $member ( @$members ) {

      # Should this member be grouped?
      my $member_to_group = 1;
      my $rel_abs = [ map { $_->get_rel_ab($member) } @$communities ];
      for my $rel_ab (@$rel_abs) {
         if ( not &$cmp($rel_ab, $thresh) ) {
            # Do not put this guy in a group
            $member_to_group--;
            last;
         }
      }

      for my $i (0 .. $nof_communities-1) {
         my $community = $communities->[$i];
         my $count = $community->get_count($member);
         if ($member_to_group) {
            # Will group member
            $group_count->[$i] += $count;
            $total_group_count  += $count;
         } else {
            # Add member as-is, ungrouped
            my $summary = $summaries->[$i];
            $summary->add_member($member, $count);
         }
      }

   }

   # Create group if needed and add it to all communities
   if ($total_group_count > 0) {
      my $group = Bio::Community::Member->new( -desc => "Other $operator $thresh %" );
      for my $i (0 .. $nof_communities-1) {
         my $summary = $summaries->[$i];
         my $count = $group_count->[$i];
         $summary->add_member($group, $count);
      }
   }

   return $summaries;
}


__PACKAGE__->meta->make_immutable;

1;
