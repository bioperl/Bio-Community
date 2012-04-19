# BioPerl module for Bio::Community::Tools::CountNormalizer
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::CountNormalizer - Normalize communities by count

=head1 SYNOPSIS

  use Bio::Community::Tools::CountNormalizer;

  my $normalizer = Bio::Community::Tools::CountNormalizer->new(
     -communities => [ $community1, $community2 ],
     -sample_size => # default is minimum community size
     -repetitions => # default is automatic
     -threshold   =>

  );

=head1 DESCRIPTION

This module produces communities normalized by their number of counts.

Comparing the composition and diversity of biological communities can be biased
by sampling artefacts. When comparing two identical communities, one for which
10,000 counts were made to one, to one with only 1,000 counts, the smaller
community will appear less diverse. A solution is to repeatedly bootstrap the
larger communities by taking 1,000 random members from it.

This module uses Bio::Community::Sampler to take random member from communities
and normalize them by their number of counts. After all random repetitions have
been performed, average communities or representative communities are returned.
These communities all have the same number of counts.

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

 Title   : new
 Function: Create a new Bio::Community::Tool::CountNormalizer object
 Usage   : my $normalizer = Bio::Community::Tool::CountNormalizer->new( );
 Args    : -communities, -repetitions, -sample_size. See details below.
 Returns : a new Bio::Community::Tools::CountNormalizer object

=cut


package Bio::Community::Tools::CountNormalizer;

use Moose;
use MooseX::NonMoose;
use MooseX::Method::Signatures;
use namespace::autoclean;
use Bio::Community::Tools::Sampler;
use Bio::Community::Tools::Distance;
use List::Util qw(min);

extends 'Bio::Root::Root';


=head2 communities

 Title   : communities
 Function: Get/set the communities to normalize.
 Usage   : my $communities = $normalizer->communities;
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


=head2 sample_size

 Title   : sample_size
 Function: Get/set the sample size, i.e. the number of members to pick randomly
           at each iteration. It has to be smaller than the total count of the
           smallest community or an error will be generated. If the sample size
           is omitted, it defaults to the total_count() of the smallest community.
 Usage   : my $sample_size = $normalizer->sample_size;
 Args    : positive integer for the sample size
 Returns : positive integer for the sample size

=cut

has sample_size => (
   is => 'rw',
   isa => 'Maybe[StrictlyPositiveInt]',
   required => 0,
   default => undef,
   lazy => 1,
   init_arg => '-sample_size',
);


=head2 threshold

 Title   : threshold
 Function: Get/set the threshold. While iterating, when the distance between the
           average community and the average community at the previous iteration
           decreases below this threshold, the bootstrapping is stopped. By
           default, the threshold is 1e-5. The repetitions() method provides an
           alternative way to specify when to stop the computation. After
           communities have been normalized using the repetitions() method
           instead of the threshold() method, the distance between the last two
           average communities repetitions can be accessed using the threshold()
           method.
 Usage   : my $repetitions = $normalizer->repetitions;
 Args    : positive integer for the number of repetitions
 Returns : positive integer for the (minimum) number of repetitions

=cut

has threshold => (
   is => 'rw',
   isa => 'Maybe[PositiveNum]',
   required => 0, 
   default => 1E-5,
   lazy => 1,
   init_arg => '-threshold',
);


=head2 repetitions

 Title   : repetitions
 Function: Get/set the number of bootstrap repetitions to perform. If specified,
           instead of relying on the threshold() to determine when to stop
           repeating the bootstrap process, perform an arbitrary number of
           repetitions. After communities have been normalized by count using
           threshold() method, the number of repetitions actually done can be
           accessed using this method.
 Usage   : my $repetitions = $normalizer->repetitions;
 Args    : positive integer for the number of repetitions
 Returns : positive integer for the (minimum) number of repetitions

=cut

has repetitions => (
   is => 'rw',
   isa => 'Maybe[PositiveInt]',
   required => 0, 
   default => undef,
   lazy => 1,
   init_arg => '-repetitions',
   predicate => '_has_repetitions',
);


=head2 get_average_communities

 Title   : get_average_communities
 Function: Calculate the average communities. Each normalized community returned
           corresponds to the equivalent community in the input.
 Usage   : my $communities = $normalizer->get_average_communities;
 Args    : none
 Returns : arrayref of Bio::Community objects

=cut

has average_communities => (
   is => 'rw',
   isa => 'ArrayRef[Bio::Community]',
   required => 0,
   default => sub { [] },
   lazy => 1,
   reader => 'get_average_communities',
   writer => '_set_average_communities',
   predicate => '_has_average_community',
);

before get_average_communities => sub {
   my ($self) = @_;
   $self->_count_normalize if not $self->_has_average_community;
   return 1;
};


=head2 get_representative_communities

 Title   : get_representative_communities
 Function: Calculate the representative communities. Each normalized community
           returned corresponds to the equivalent community in the input.
 Usage   : my $communities = $normalizer->get_representative_communities;
 Args    : none
 Returns : arrayref of Bio::Community objects

=cut

has representative_communities => (
   is => 'rw',
   isa => 'ArrayRef[Bio::Community]',
   required => 0,
   default => sub { [] },
   lazy => 1,
   reader => 'get_representative_communities',
   writer => '_set_representative_communities',
);

before get_representative_communities => sub {
   my ($self) = @_;
   my $averages = $self->get_average_communities;
   my $representatives = [ map { $self->_calc_representative($_) } @$averages ];
   $self->_set_representative_communities($representatives);
   return 1;
};


method _count_normalize () {
   # Normalize communties by total count
   # Sanity check
   my $communities = $self->communities;
   if (scalar @$communities == 0) {
      $self->throw('Need to provide at least one community');
   }

   # Get or set sample size
   my $min = min( map {$_->total_count} @$communities );
   my $sample_size = $self->sample_size;
   if (not defined $sample_size) { 
      # Set sample size to smallest community size
      $sample_size = $min;
      $self->sample_size($sample_size); 
   } else {
      if ($sample_size > $min) {
         $self->throw("Was given a sample size of $sample_size which is larger".
            " than the smaller community ($min counts)");
      }
   }

   # Bootstrap now
   my $average_communities = [];
   my $min_repetitions;
   my $max_threshold;
   for my $community ( @{$self->communities} ) {
      my ($average, $repetitions, $dist);
      if ($community->total_count == $sample_size) {         
         ($average, $repetitions, $dist) = ($community->clone, 0, 0); # Nothing to normalize
         $repetitions = 0;
         $dist = 0;
      } else {
         ($average, $repetitions, $dist) = $self->_bootstrap($community);
      }
      if ( (not defined $min_repetitions) || ($repetitions < $min_repetitions) ) {
         $min_repetitions = $repetitions;
      }
      if ( (not defined $max_threshold) || ($dist > $max_threshold) ) {
         $max_threshold = $dist;
      }
      push @$average_communities, $average;
   }
   $self->_set_average_communities($average_communities);

   ####
   print "min_repetitions = $min_repetitions\n";
   print "max_threshold   = $max_threshold\n";
   ####

   if ($self->_has_repetitions) {
      $self->threshold($max_threshold);
   } else {
      $self->repetitions($min_repetitions);
   }

   return 1;
}


method _bootstrap (Bio::Community $community) {
   # Re-sample a community many times and report the average community

   my $threshold   = $self->threshold();
   my $sample_size = $self->sample_size();
   my $repetitions = $self->repetitions();
   my $sampler = Bio::Community::Tools::Sampler->new( -community => $community );

   my $overall = Bio::Community->new( -name => 'average' );
   my $prev_overall = Bio::Community->new();
   my $iteration = 0;
   my $dist;
   while (1) {
      $iteration++;
      my $random = $sampler->get_rand_community($sample_size);
      $overall = $self->_add( $overall, $random );

      ### divide here??

      # Exit conditions
      if (not defined $repetitions) {
         $dist = Bio::Community::Tools::Distance->new(
               -type        => 'euclidean',
               -communities => [$overall, $prev_overall],
         )->get_distance;

         ####
         print "$iteration\t$dist\n";
         ####

         last if $dist < $threshold;
         $prev_overall = $overall->clone;
      } else {

         ####
         print "$iteration\n";
         ####

         last if $iteration >= $repetitions;
      }
   }

   if (defined $repetitions) {
      $dist = Bio::Community::Tools::Distance->new(
            -type        => 'euclidean',
            -communities => [$overall, $prev_overall],
      )->get_distance;
   }

   my $average = $self->_divide($overall, $iteration);

   ####
   #print "   ...did $iteration repetitions...\n";
   ####

   return $overall, $iteration, $dist;
}


method _add (Bio::Community $existing, Bio::Community $new) {
   # Add a new community to an existing one
   while (my $member = $new->next_member) {
      my $count = $new->get_count($member);
      $existing->add_member( $member, $count );
   }
   return $existing;
}


method _divide (Bio::Community $community, StrictlyPositiveInt $divisor) {
   # Divide the counts in a community
   while (my $member = $community->next_member) {
      my $count     = $community->get_count($member);
      my $new_count = $count / $divisor;
      my $diff = $count - $new_count;
      $community->remove_member( $member, $diff );
   }
   return $community;
}


method _calc_representative(Bio::Community $community) {
   # Sort members by decreasing count
   my $members = [ $community->all_members ];
   my $counts  = [ map { $community->get_count($_) } @$members ];
   ($counts, $members) = Bio::Community::_two_array_sort($counts, $members);

   # 
   my $cur_counts = 0;
   my $target_counts = $community->total_count;
   my $representative = Bio::Community->new( -name => 'representative' );
   for my $i (0 .. scalar @$members - 1) {
      my $member = $members->[$i];
      my $count  = $counts->[$i];
      # Round the count
      my $new_count = int($count + 0.5);
      # Increment or decrement the new count if need be
      if ($cur_counts + $new_count > $target_counts) {
         $new_count--;
      } elsif ($cur_counts + $new_count < $target_counts) {
         if ($new_count == 0) {
            $new_count++;
         }
      }
      # Add member to the community
      $representative->add_member( $member, $new_count );
      $cur_counts += $new_count;
      if ($cur_counts == $target_counts) {
         last;
      }
   }
   return $representative;
}


__PACKAGE__->meta->make_immutable;

1;
