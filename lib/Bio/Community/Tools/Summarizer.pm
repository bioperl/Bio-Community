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

  # Group community members less than 1% into a single group and summarize their
  # taxonomy at the second level (i.e. phylum level when using the Greengenes
  # taxonomy)
  my $summarizer = Bio::Community::Tools::Summarizer->new(
     -communities  => [$community1, $community2],
     -by_tax_level => 2,
     -by_rel_ab    => ['<', 1],
  );
  my $summarized_communities = $summarizer->get_summaries;

=head1 DESCRIPTION

Summarize a community by grouping members based on their taxonomic affiliation
first, then by collapsing or removing members with a relative abundance above
or below a specified threshold. Summarizing communities should be the last step
of any community analysis, because it compresses communities (members, weights,
taxonomy, etc.) in a way that cannot be undone.

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
           -merge_dups
           -by_tax_level
           -by_rel_ab
 Returns : a Bio::Community::Tools::Summarizer object

=cut


package Bio::Community::Tools::Summarizer;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;
use Bio::Community::IO;

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
   default => sub { [] },
   init_arg => '-communities',
);


=head2 merge_dups

 Function: Merge community members with the exact same taxonomic affiliation
           together. For example, if your community contained several members
           with a taxonomic lineage of 'Archaea;Euryarchaeota;Halobacteria', all
           would be merged into a new member with the same taxonomy and the sum
           of the counts. Note that merging duplicates takes place before grouping
           by taxonomy level, by_tax_level().
 Usage   : $summarizer->merge_dups(1);
 Args    : 0 (no) or 1 (yes). Default: 1
 Returns : a positive integer

=cut

has merge_dups => (
   is => 'rw',
   isa => 'Bool',
   required => 0,
   lazy => 1,
   default => 1,
   init_arg => '-merge_dups',
);


=head2 by_tax_level

 Function: Get/set the taxonomic level at which to group community members. When
           community members have taxonomic information attached, add the
           relative abundance of all members belonging to the same taxonomic
           level. The taxonomic level depends on which taxonomy is used. For the
           Greengenes taxonomy, level 1 represents kingdom, level 2 represents
           phylum, and so on, until level 7, representing the species level.
           Members without taxonomic information are grouped together in a Member
           with the description 'Unknown taxonomy'.
           Note that summarizing by taxonomy level takes place before grouping by
           relative abundance, by_rel_ab(). Also, since each community member
           represents the combination of multiple members, they have to be given
           a new weight, that is specific to the community they belong to.
 Usage   : $summarizer->by_tax_level(2);
 Args    : a positive integer
 Returns : a positive integer

=cut

has by_tax_level => (
   is => 'rw',
   isa => 'Maybe[StrictlyPositiveInt]',
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-by_tax_level',
);


=head2 by_rel_ab

 Function: Get/set the relative abundance threshold to group members together.
           Example: You provide multiple communities and specify to group
           members with a relative abundance less than 1%. If member A is at
           less than 1% in all the communities, it is removed from the
           communities and added as a new member with the desciption 'Other < 1%'
           along with all other members that are less than 1% in all the
           communities.
           Note that when community members are weighted, the 'Other' group also
           has to be weighted differently for each community.
 Usage   : $summarizer->by_rel_ab('<', 1);
 Args    : * the type of numeric comparison, '<', '<=', '>=', '>'
           * the relative abundance threshold (in %)
 Returns : * the type of numeric comparison, '<', '<=', '>=', '>'
           * the relative abundance threshold (in %)

=cut

has by_rel_ab => (
   is => 'rw',
   isa => 'Maybe[ArrayRef]', # how to specify ArrayRef[Str, Num]?
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-by_rel_ab',
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

   #### First, filter out members TODO

   # Then merge duplicates
   my $merge_dups = $self->merge_dups();
   if ($merge_dups) {
      $summaries = $self->_merge_duplicates($members, $communities, $summaries,
          $merge_dups);
   }

   # Then summarize by taxonomy
   my $tax_level = $self->by_tax_level();
   if (defined $tax_level) {
      $summaries = $self->_group_by_taxonomic_level($members, $communities,
         $summaries, $tax_level);
   }

   # Finally, group members by abundance
   my $rel_ab_params = $self->by_rel_ab;
   if (defined $rel_ab_params) {
      $summaries = $self->_group_by_relative_abundance($members, $communities,
         $summaries, $rel_ab_params);
   }

   return $summaries;
};


method _merge_duplicates ( $members, $communities, $summaries, $merge_dups ) {
   my $nof_communities = scalar @$communities;
   my $taxa_counts = {};
   my $taxa_objs   = {};
   for my $member ( @$members ) {

      my $taxon = $member->taxon;
      if ($taxon) {
         # Member has taxonomic information
         my $lineage_arr = Bio::Community::IO::_get_lineage_obj_arr($taxon);
         my $lineage_str = Bio::Community::IO::_get_lineage_string($lineage_arr);

         # Save taxon object
         if (not exists $taxa_objs->{$lineage_str}) {
            $taxa_objs->{$lineage_str} = $taxon;
         }

         # For each community, add member counts and weighted counts to the taxonomic group
         for my $i (0 .. $nof_communities-1) {
            my $community = $communities->[$i];
            my $count = $community->get_count($member);
            my $wcount = $count / Bio::Community::_prod($member->weights);
            $taxa_counts->{$lineage_str}->{$i}->[0] += $count;
            $taxa_counts->{$lineage_str}->{$i}->[1] += $wcount;
         }

      } else {
         # Member has no taxonomic assignment. Add member as-is in all summaries.
         for my $i (0 .. $nof_communities-1) {
            my $count = $communities->[$i]->get_count($member);
            my $summary = $summaries->[$i];
            $summary->add_member($member, $count);
         }
      }

   }

   # Add taxonomic groups to all communities
   $self->_add_groups($taxa_objs, $taxa_counts, $summaries);

   return $summaries;
}


method _group_by_taxonomic_level ( $members, $communities, $summaries, $tax_level ) {
   my $nof_communities = scalar @$communities;
   my $taxa_counts = {};
   my $taxa_objs   = {};
   for my $member ( @$members ) {

      my $taxon = $member->taxon;
      if ($taxon) {
         # Member has taxonomic information
         my $lineage_arr = Bio::Community::IO::_get_lineage_obj_arr($taxon);
         my $end_idx = $tax_level-1 > $#$lineage_arr ?  $#$lineage_arr : $tax_level-1;
         $lineage_arr = [ @{$lineage_arr}[0 .. $end_idx] ];

         if ( scalar @$lineage_arr > 0 ) {
            # Could find Bio::Taxon at requested taxonomic level
            my $lineage_str = Bio::Community::IO::_get_lineage_string($lineage_arr);
            $taxon = $lineage_arr->[-1];

            # Save taxon object
            if (not exists $taxa_objs->{$lineage_str}) {
               $taxa_objs->{$lineage_str} = $taxon;
            }

            # For each community, add member counts and weighted counts to the taxonomic group
            for my $i (0 .. $nof_communities-1) {
               my $community = $communities->[$i];
               my $count = $community->get_count($member);
               my $wcount = $count / Bio::Community::_prod($member->weights);
               $taxa_counts->{$lineage_str}->{$i}->[0] += $count;
               $taxa_counts->{$lineage_str}->{$i}->[1] += $wcount;
            }

         } else {
            # Member had taxonomic information at a higher level than requested.
            # Add member as-is in all summaries.
            for my $i (0 .. $nof_communities-1) {
               my $count = $communities->[$i]->get_count($member);
               my $summary = $summaries->[$i];
               $summary->add_member($member, $count);
            }
         }
      }

      if (not $taxon) {
         # Member had no taxonomic info. Add it in a separate group.
         my $lineage_str = 'Unknown taxonomy';
         if (not exists $taxa_objs->{$lineage_str}) {
            $taxa_objs->{$lineage_str} = undef;
         }
         for my $i (0 .. $nof_communities-1) {
            my $community = $communities->[$i];
            my $count = $community->get_count($member);
            my $wcount = $count / Bio::Community::_prod($member->weights);
            $taxa_counts->{$lineage_str}->{$i}->[0] += $count;
            $taxa_counts->{$lineage_str}->{$i}->[1] += $wcount;
         }
      }

   }

   # Add taxonomic groups to all communities
   $self->_add_groups($taxa_objs, $taxa_counts, $summaries);

   return $summaries;
}


method _group_by_relative_abundance ( $members, $communities, $summaries, $params ) {
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

   my $taxa_counts = {};
   my $desc = "Other $operator $thresh %";
   my $taxa_objs = { $desc => undef };

   for my $member ( @$members ) {

      # Determine if this member should be grouped
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
         my $rel_ab = $rel_abs->[$i];
         my $count  = $communities->[$i]->get_count($member);
         if ($member_to_group) {
            # Will group member
            my $wcount = $count / Bio::Community::_prod($member->weights);
            $taxa_counts->{$desc}->{$i}->[0] += $count;
            $taxa_counts->{$desc}->{$i}->[1] += $wcount;
         } else {
            # Add member as-is, ungrouped
            my $summary = $summaries->[$i];
            $summary->add_member($member, $count) if $count > 0;
         }
      }

   }

   # Add taxonomic groups to all communities
   $self->_add_groups($taxa_objs, $taxa_counts, $summaries);

   return $summaries;
}


method _calc_weights ($count, $weighted_count) {
   # Given a count and a weighted count, calcualte
   my $weight = ($count > 0) ? ($count / $weighted_count) : 1;
   return [ $weight ];
}


method _add_groups ($taxa_objs, $taxa_counts, $summaries) {
   # Add taxonomic groups to the summaries provided
   while (my ($lineage_str, $taxon) = each %$taxa_objs) {
      my $group_id;
      for my $i (0 .. $#$summaries) {
         my $count_info = $taxa_counts->{$lineage_str}->{$i} || next;
         my ($count, $wcount) = @{$count_info};
         my $summary = $summaries->[$i];
         my $group;
         if ($group_id) {
            $group = Bio::Community::Member->new( -id => $group_id );
         } else {
            $group = Bio::Community::Member->new( );
            $group_id = $group->id;
         }
         $group->desc($lineage_str);
         $group->taxon($taxon) if $taxon;
         $group->weights( $self->_calc_weights($count, $wcount) );
         $summary->add_member($group, $count) if $count > 0;
      }
   }
   return 1;
}

__PACKAGE__->meta->make_immutable;

1;
