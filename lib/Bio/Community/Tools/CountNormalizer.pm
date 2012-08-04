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

  # Normalize communities in a metacommunity by repeatedly taking 1,000 random members
  my $normalizer = Bio::Community::Tools::CountNormalizer->new(
     -metacommunity => $meta,
     -sample_size   => 1000,
     -threshold     => 0.001, # When to stop iterating. Can specify repetions instead
  );

  my $average_community = $normalizer->get_avg_meta->[0];

  # Round counts and remove members with abundance between 0 and 0.5
  my $representative_community = $normalizer->get_repr_meta->[0];

=head1 DESCRIPTION

This module takes a metacommunity and normalizes (rarefies) the communities it
contains by their number of counts.

Comparing the composition and diversity of biological communities can be biased
by sampling artefacts. When comparing two identical communities, one for which
10,000 counts were made to one, to one with only 1,000 counts, the smaller
community will appear less diverse. A solution is to repeatedly bootstrap the
larger communities by taking 1,000 random members from it.

This module uses L<Bio::Community::Sampler> to take random member from communities
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

 Function: Create a new Bio::Community::Tool::CountNormalizer object
 Usage   : my $normalizer = Bio::Community::Tool::CountNormalizer->new( );
 Args    : -metacommunity: see metacommunity()
           -repetitions  : see repetitions()
           -sample_size  : see sample_size()
 Returns : a new Bio::Community::Tools::CountNormalizer object

=cut


package Bio::Community::Tools::CountNormalizer;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;
use Bio::Community::Meta;
use Bio::Community::Tools::Sampler;
use Bio::Community::Tools::Ruler;
use POSIX;
use List::Util qw(min);

extends 'Bio::Root::Root';


=head2 metacommunity

 Function: Get or set the metacommunity to normalize.
 Usage   : my $meta = $normalizer->metacommunity;
 Args    : A Bio::Community::Meta object
 Returns : A Bio::Community::Meta object

=cut

has metacommunity => (
   is => 'rw',
   isa => 'Bio::Community::Meta',
   required => 0,
   default => undef,
   lazy => 1,
   init_arg => '-metacommunity',
);


=head2 sample_size

 Function: Get or set the sample size, i.e. the number of members to pick randomly
           at each iteration. It has to be smaller than the total count of the
           smallest community or an error will be generated. If the sample size
           is omitted, it defaults to the get_members_count() of the smallest community.
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

 Function: Get or set the threshold. While iterating, when the distance between the
           average community and the average community at the previous iteration
           decreases below this threshold, the bootstrapping is stopped. By
           default, the threshold is 1e-5. The repetitions() method provides an
           alternative way to specify when to stop the computation. After
           communities have been normalized using the repetitions() method
           instead of the threshold() method, the distance between the last two
           average communities repetitions can be accessed using the threshold()
           method.
 Usage   : my $threshold = $normalizer->threshold;
 Args    : positive integer for the number of repetitions
 Returns : positive integer for the (minimum) number of repetitions

=cut

has threshold => (
   is => 'rw',
   isa => 'Maybe[PositiveNum]',
   required => 0, 
   default => 1E-5, # maybe impossible to reach lower thresholds for simplistic communities
   lazy => 1,
   init_arg => '-threshold',
);


=head2 repetitions

 Function: Get or set the number of bootstrap repetitions to perform. If specified,
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
);


=head2 verbose

 Function: Get or set verbose mode. In verbose mode, the current number of
           iterations (and distance if a threshold is used) is displayed.
 Usage   : $normalizer->verbose(1);
 Args    : 0 or 1
 Returns : 0 or 1

=cut

has verbose => (
   is => 'rw',
   isa => 'Bool',
   required => 0, 
   default => 0,
   lazy => 1,
   init_arg => '-verbose',
);


=head2 get_avg_meta

 Function: Calculate an average metacommunity.
 Usage   : my $meta = $normalizer->get_avg_meta;
 Args    : none
 Returns : arrayref of Bio::Community objects

=cut

has average_meta => (
   is => 'rw',
   isa => 'Bio::Community::Meta',
   required => 0,
   default => sub { undef },
   lazy => 1,
   reader => 'get_avg_meta',
   writer => '_set_avg_meta',
   predicate => '_has_avg_meta',
);

before get_avg_meta => sub {
   my ($self) = @_;
   $self->_count_normalize if not $self->_has_avg_meta;
   return 1;
};


=head2 get_repr_meta

 Function: Calculate a representative metacommunity.
 Usage   : my $meta = $normalizer->get_repr_meta;
 Args    : none
 Returns : arrayref of Bio::Community objects

=cut

has representative_meta => (
   is => 'rw',
   isa => 'Bio::Community::Meta',
   required => 0,
   default => sub { undef },
   lazy => 1,
   reader => 'get_repr_meta',
   writer => '_set_repr_meta',
   predicate => '_has_repr_meta',
);

before get_repr_meta => sub {
   my ($self) = @_;
   if (not $self->_has_repr_meta) {
      my $average_meta = $self->get_avg_meta;
      my $representative_meta = Bio::Community::Meta->new( -name => $average_meta->name );
      while (my $average_community = $average_meta->next_community) {
         my $representative_community = $self->_calc_repr($average_community);
         $representative_meta->add_communities([$representative_community]);
      }
      $self->_set_repr_meta($representative_meta);
   }
   return 1;
};


method _count_normalize () {
   # Normalize communties by total count

   # Sanity check
   my $meta = $self->metacommunity;
   if ($meta->get_communities_count == 0) {
      $self->throw('Metacommunity should contain at least one community');
   }

   # Get or set sample size
   my $communities = $meta->get_all_communities;
   my $min = min( map {$_->get_members_count} @$communities );
   my $sample_size = $self->sample_size;
   if (not defined $sample_size) { 
      # Set sample size to smallest community size
      $sample_size = $min;
      $self->sample_size($sample_size); 
   } else {
      if ($sample_size > $min) {
         my $name;
         for my $community (@$communities) {
            if ($community->get_members_count == $min) {
               $name = $community->name;
               last;
            }
         }
         $self->throw("Was given a sample size of $sample_size which is larger".
            " than counts in the smallest community, (name: '$name', counts: ".
            "$min)");
      }
   }
   if ($self->verbose) {
      print "Bootstrap sample size: $sample_size\n";
      if ($self->repetitions) {
         print "Bootstrap number of repetitions: ".$self->repetitions."\n";
      } else {
         print "Bootstrap distance threshold: ".$self->threshold."\n";
      }
   }

   # Bootstrap now
   my $average_meta = Bio::Community::Meta->new( -name => $meta->name );
   my $min_repetitions = POSIX::DBL_MAX;
   my $max_threshold = 0;
   for my $community ( @$communities ) {
      my ($average, $repetitions, $dist);
      if ($community->get_members_count == $sample_size) {         
         ($average, $repetitions, $dist) = ($community->clone, undef, undef);
      } else {
         ($average, $repetitions, $dist) = $self->_bootstrap($community);
      }
      my $name = $community->name;
      #$name .= ' ' if $name;
      #$name .= 'average';
      $average->name($name);
      if (defined $self->repetitions) {
         $max_threshold = $dist if (defined $dist) && ($dist > $max_threshold);
      } else {
         $min_repetitions = $repetitions if (defined $repetitions) && ($repetitions < $min_repetitions);
      }
      $average_meta->add_communities([$average]);
   }
   $self->_set_avg_meta($average_meta);

   if (defined $self->repetitions) {
      $self->threshold($max_threshold);
   } else {
      if ($min_repetitions == POSIX::DBL_MAX) {
         $min_repetitions = 0;
      }
      $self->repetitions($min_repetitions);
   }

   return 1;
}


method _bootstrap (Bio::Community $community) {
   # Re-sample a community many times and report the average community
   my $threshold   = $self->threshold();
   my $sample_size = $self->sample_size();
   my $repetitions = $self->repetitions();

   # Set 'use_weights' to sample from counts (similar to unweighted relative abundances)
   my $use_weights = $community->use_weights;
   $community->use_weights(0);
   my $sampler = Bio::Community::Tools::Sampler->new( -community => $community );

   my $overall = Bio::Community->new(
      -name        => 'overall',
      -use_weights => $use_weights,
   );

   my $members = $community->get_all_members;

   my $verbose = $self->verbose;
   if ($verbose) {
      print "Community '".$community->name."'\n";
   }

   my $prev_overall = Bio::Community->new( -name => 'prev' );
   my $iteration = 0;
   my $dist;
   while (1) {

      # Get a random community and add it to the overall community
      $iteration++;
      my $random = $sampler->get_rand_community($sample_size);
      $overall = $self->_add( $overall, $random, $members );

      # We could divide here, but since the distance is based on the relative
      # abundance, not the counts, it would be the same. Hence, only divide at
      # the end

      my $meta = Bio::Community::Meta->new(-communities =>[$overall, $prev_overall]);

      if (not defined $repetitions) {
         # Exit if distance with last average community is small
         $dist = Bio::Community::Tools::Ruler->new(
               -type          => 'euclidean',
               -metacommunity => $meta,
         )->get_distance;
         if ($verbose) {
            print "   iteration $iteration, distance $dist\n";
         }
         last if $dist < $threshold;
         $prev_overall = $overall->clone;
         $prev_overall->name('prev');
      } else {
         # Exit if all repetitions have been done
         if ($verbose) {
            print "   iteration $iteration\n";
         }
         if ($iteration == $repetitions - 1) {
            $prev_overall = $overall->clone;
            $prev_overall->name('prev');
         } elsif ($iteration >= $repetitions) {
            $dist = Bio::Community::Tools::Ruler->new(
                  -type          => 'euclidean',
                  -metacommunity => $meta,
            )->get_distance;
            last;
         }
      }

   }

   if ($verbose) {
      print "\n";
   }

   $community->use_weights($use_weights);
   my $average = $self->_divide( $overall, $iteration, $members );

   return $overall, $iteration, $dist;
}


#method _add (Bio::Community $existing, Bio::Community $new, $members) {
method _add ($existing, $new, $members) { # keep it lean
   # Add a new community to an existing one
   for my $member (@$members) {
      my $count = $new->get_count($member);
      $existing->add_member( $member, $count );
   }
   return $existing;
}


method _divide (Bio::Community $community, StrictlyPositiveInt $divisor, $members) {
   # Divide the counts in a community
   for my $member (@$members) {
      my $count     = $community->get_count($member);
      my $new_count = $count / $divisor;
      my $diff = $count - $new_count;
      $community->remove_member( $member, $diff );
   }
   return $community;
}


method _calc_repr(Bio::Community $average) {
   # Round the member count and add them into a new, representative community
   my $cur_count = 0;
   my $target_count = int( $average->get_members_count + 0.5 ); # round count like 999.9 to 1000

   my $name = $average->name;
   #$name =~ s/\s*average$//;
   #$name .= ' ' if $name;
   #$name .= 'representative';

   my $representative = Bio::Community->new(
      -name        => $name,
      -use_weights => $average->use_weights,
   );

   my $richness = 0;
   my $deltas;
   my $members;
   while ( my $member = $average->next_member('_calc_repr_ite') ) {
      $richness++;
      # Add member and count to the community
      my $count = $average->get_count($member);
      my $new_count = int( $count + 0.5 );
      my $delta = $new_count - $count;
      push @$deltas, $delta if $delta != 0;
      push @$members, $member;
      next if $new_count == 0;
      $representative->add_member( $member, $new_count );
      $cur_count += $new_count;
   }
   $cur_count = int( $cur_count + 0.5 );

   # Adjust the last count
   if ($cur_count != $target_count) {

      # Sort deltas numerically descending
      ($deltas, $members) = Bio::Community::_two_array_sort($deltas, $members);

      if ($cur_count < $target_count) {
         # Total count too small! Increment members with smallest delta
         do {
            pop @$deltas;
            $representative->add_member( pop(@$members), 1 );
         } while ($representative->get_members_count < $target_count);
      } else {
         # Total count too large! Decrement members with largest delta
         do {
            shift @$deltas;
            $representative->remove_member( shift(@$members), 1 );
         } while ($representative->get_members_count > $target_count);
      }

   }

   return $representative;
}


__PACKAGE__->meta->make_immutable;

1;
