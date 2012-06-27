# BioPerl module for Bio::Community::Tools::Ruler
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::Ruler - Beta-diversity and distance separating communities

=head1 SYNOPSIS

  use Bio::Community::Tools::Ruler;

  my $ruler = Bio::Community::Tools::Ruler->new(
     -communities => [ $community1, $community2 ],
     -type        => 'euclidean',
  );
  my $distance = $ruler->get_distance;

=head1 DESCRIPTION

Calculate the distance between two communities. The more different communities
are, the larger the distance between them. Thus, these distance metrics a form
of beta-diversity metric.

Several types of distance are available: 1-norm, 2-norm (euclidean), and
infinity-norm. They consider the communities as a n-dimensional space, where n
is the total number of unique members across the communities.

Since the relative abundance of community members is not always proportional to
member counts (see weights() in Bio::Community::Member and use_weights() in
Bio::Community), the distances measured here are always based on relative
abundance (as a fractional number between 0 and 1, not as a percentage), even
for beta-diversity metrics that are usually based on number of observations
(counts).

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

 Function: Create a new Bio::Community::Tool::Ruler object
 Usage   : my $ruler = Bio::Community::Tools::Ruler->new(
              -communities => [ $community1, $community2 ],
              -type        => 'euclidean',
           );
 Args    : -communities
              Communities to calculate the distance of. See communities().
           -type
              The type of distance to use 1-norm, hellinger, etc. See type().
 Returns : a Bio::Community::Tools::Ruler object

=cut


package Bio::Community::Tools::Ruler;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;
use List::Util qw(min max);

extends 'Bio::Root::Root';


=head2 communities

 Function: Get or set the communities to process.
 Usage   : my $communities = $ruler->communities;
 Args    : arrayref of Bio::Community objects
 Returns : arrayref of Bio::Community objects

=cut

has communities => (
   is => 'ro',
   isa => 'ArrayRef[Bio::Community]',
   required => 1,
   lazy => 0,
   init_arg => '-communities',
);


=head2 type

 Function: Get or set the type of distance or beta-diversity index to measure.
 Usage   : my $type = $ruler->type;
 Args    : string for the desired type of distance
            * 1-norm: the 1-norm distance
            * 2-norm (or euclidean): the euclidean distance
            * infinity-norm: the infinity-norm distance
            * hellinger: like the euclidean distance, but constrained between 0
                and 1
            * bray-curtis: the Bray-Curtis dissimilarity index, between 0 and 1
            * shared: percentage of species shared (between 0 and 100), relative
                to the least rich community). Note: this is the opposite
                of a beta-diversity measure: the higher the percent of 
                species shared, the smaller the smaller the beta-diversity.
            * permuted: a beta-diversity measure between 0 and 100, representing
                the percentage of the dominant species in the first community
                with a permuted abundance rank in the second community. As a
                special case, when no species are shared (and the percentage
                permuted is meaningless), undef is returned.
            * maxiphi: a beta-diversity measure between 0 and 1, based on the 
                percentage of species shared and the percentage of top species
                permuted (that have had a change in abundance rank)

 Returns : string for the desired type of distance

=cut

has type => (
   is => 'ro',
   isa => 'DistanceType',
   required => 0,
   lazy => 1,
   default => '2-norm',
   init_arg => '-type',
);


=head2 get_distance

 Function: Calculate the distance or beta-diversity between the provided
           communities. The distance is calculated based on the relative
           abundance of the members (not their counts).
 Usage   : my $distance = $ruler->get_distance;
 Args    : None
 Returns : A number for the distance

=cut

####after new => sub { # prevents inlining
#### or maybe try BUILD
method get_distance {
   my $communities = $self->communities;
   return $self->_get_pairwise_distance($communities->[0], $communities->[1]);
};


method _get_pairwise_distance ($community1, $community2) {
   my $type = $self->type;
   my $dist;
   if ($type eq '1-norm') {
      $dist = $self->_pnorm($community1, $community2, 1);
   } elsif ( ($type eq '2-norm') || ($type eq 'euclidean') ) {
      $dist = $self->_pnorm($community1, $community2, 2);
   } elsif ($type eq 'infinity-norm') {
      $dist = $self->_infnorm($community1, $community2);
   } elsif ($type eq 'hellinger') {
      $dist = $self->_hellinger($community1, $community2);
   } elsif ($type eq 'bray-curtis') {
      $dist = $self->_braycurtis($community1, $community2);
   } elsif ($type eq 'shared') {
      $dist = $self->_shared($community1, $community2);
   } elsif ($type eq 'permuted') {
      $dist = $self->_permuted($community1, $community2);
   } elsif ($type eq 'maxiphi') {
      $dist = $self->_maxiphi($community1, $community2);
   } elsif ($type eq 'unifrac') {
      my $tree;
      $dist = $self->_unifrac($community1, $community2, $tree);
   } else {
      $self->throw("Invalid distance type '$type'.");
   }
   return $dist;
}


=head2 get_all_distances

 Function: Similar to get_distance(), but return the distance between all
           possible pairs of input communities and also return their average
           distance.
 Usage   : my ($average, $distances) = $ruler->get_all_distances;
 Args    : None
 Returns : * A number for the average distance
           * A hashref of hashref with the value of all pairwise distances,
             keyed by the community names. To get the distance for a specific
             pair of communities, do:
                my $dist = $distances->{$name1}->{$name2};
             or:
                my $dist = $distances->{$name2}->{$name1};
 
=cut

method get_all_distances {
   my $communities = $self->communities;
   my $num_communities = scalar @$communities;
   my $average = 0;
   my $num_pairs = 0;
   my $distances;
   for my $i (0 .. $num_communities - 1) {
      my $community1 = $communities->[$i];
      my $name1 = $community1->name;
      for my $j ($i + 1 .. $num_communities -1) {
         my $community2 = $communities->[$j];
         my $name2 = $community2->name;
         my $distance = $self->_get_pairwise_distance($community1, $community2);
         $num_pairs++;
         $average += $distance;
         if (exists $distances->{$name1}->{$name2}) {
            $self->throw("There are several communities called '$name2'.");
         } else {
            $distances->{$name1}->{$name2} = $distances->{$name2}->{$name1} = $distance;
         }
      }
   }
   $average = ($num_pairs > 0) ? ($average / $num_pairs) : undef;
   return $average, $distances;
}


method _pnorm ($community1, $community2, $power) {
   # Calculate the p-norm. If power is 1, this is the 1-norm. If power is 2,
   # this is the 2-norm (a.k.a. euclidean distance).
   my $all_members = $community1->get_all_members($self->communities);
   my $sumdiff = 0;
   for my $member (@$all_members) {
      my $abundance1 = $community1->get_rel_ab($member) / 100;
      my $abundance2 = $community2->get_rel_ab($member) / 100;
      $sumdiff += ( abs($abundance1 - $abundance2) )**$power;
   }
   my $dist = $sumdiff ** (1/$power);
   return $dist;
}


method _infnorm ($community1, $community2) {
   # Calculate the infinity-norm.
   my $all_members = $community1->get_all_members($self->communities);
   my $dist = 0;
   for my $member (@$all_members) {
      my $abundance1 = $community1->get_rel_ab($member) / 100;
      my $abundance2 = $community2->get_rel_ab($member) / 100;
      my $diff = abs($abundance1 - $abundance2);
      if ($diff > $dist) {
         $dist = $diff;
      }
   }
   return $dist;
}


method _hellinger ($community1, $community2) {
   # Calculate the Hellinger distance.
   return $self->_pnorm($community1, $community2, 2) / sqrt(2);
}


method _braycurtis ($community1, $community2) {
   # Calculate the Bray-Curtis dissimilarity index BC:
   #    BC = 1 - sum( min(r_i, r_j) )
   # where r_i and r_j are the relative abundance (fractional) for species in
   # common between both sites.
   # Can also be written as:
   #    BC = sum( c_i - c_j ) / sum( c_i + c_j )
   # where c_i and c_j are the counts for all observed species.
   my $all_members = $community1->get_all_members($self->communities);
   my $sumdiff = 0;
   for my $member (@$all_members) {
      my $abundance1 = $community1->get_rel_ab($member) / 100;
      next if $abundance1 == 0;
      my $abundance2 = $community2->get_rel_ab($member) / 100;
      next if $abundance2 == 0;
      $sumdiff += min($abundance1, $abundance2);
   }
   return 1 - $sumdiff;
}


method _shared ($community1, $community2) {
   # Percentage of species in common between two communities, relative to the
   # least rich community.
   my $all_members = $community1->get_all_members($self->communities);
   my $num_shared = 0;
   for my $member (@$all_members) {
      if ( ($community1->get_rel_ab($member) > 0) &&
           ($community2->get_rel_ab($member) > 0) ) {
         $num_shared++;
      }
   }
   return $num_shared / min($community1->get_richness,$community2->get_richness) * 100;
}


method _permuted ($community1, $community2) {
   # Percent of top species with a permuted rank-abundance between 2 communities.
   # The exact number cannot be calculated for certain because the random
   # permutation of x species could generate the same sequence (but it would be
   # extremely unlikely). The best we can do is calculate a minimum bound for
   # the number of species permuted. Do this once for the species of community1
   # once, and then for the members of community2 and return the average of the
   # two.This should be a reasonable approximation of the true percent of
   # species permuted.


   #### should it really be the average or simply relative to the least rich community


   my $min_p1 = $self->_min_permuted($community1, $community2);
   my $min_p2 = $self->_min_permuted($community2, $community1);
   my $p;
   if ( (defined $min_p1) && defined($min_p2) ) {
      $p = ($min_p1 + $min_p2) / 2;
   }

   ####
   print "min_p1: '".(defined($min_p1)?$min_p1:'')."'\n";
   print "min_p2: '".(defined($min_p2)?$min_p2:'')."'\n";
   print "p     : '".(defined($p)?$p:'')." %'\n";
   ####

   return $p;
}


method _min_permuted ($community1, $community2) {
   # Estimate the minimum percent of permuted species in community1. Do this by
   # going through members of community2 in increasing abundance rank order and
   # comparing their position to that of the same member in community1 (if
   # shared). If there are no species shared, return undef.

   my $min_permuted;

   my $i = 0;
   my $richness = $community2->get_richness;
   while ($i < $richness) {
      $i++;

      ####
      #print "i $i\n";
      ####
       
      my $member = $community2->get_member_by_rank($i);

      # Skip this member if it is not shared
      next if not $community1->get_rel_ab($member);
         
      my $j = $community1->get_rank($member);

      ####
      #print "   j $j\n";
      ####

      # Record the first mapping as the min permuted
      if (not defined $min_permuted) {
         $min_permuted = $j;
      }

      if ($j > $min_permuted) {
         # Member rank in second community conflicts with minimum permutation
         # assumption. Increase minimum permutation.
         $min_permuted = $j;

         ####
         #print "Updated min_permuted: $min_permuted\n";
         ####
      }

      # Finish if the permutation limit has been reached without conflicts
      last if $i >= $min_permuted;

   }

   if (defined $min_permuted) {
      if ($min_permuted == 1) {
         $min_permuted--;
      }
      $min_permuted = $min_permuted / $community1->get_richness * 100;
   }

   ####
   #print "Return min_permuted: '".(defined($min_permuted)?$min_permuted:'')."'\n";
   ####    

   return $min_permuted;
}


method _maxiphi ($community1, $community2) {
   # Given S, the fraction shared, and P, the fraction permuted, calculate the
   # MaxiPhi beta diversity M as:
   #       M = 1 - S*(2-P)/2
   #
   # M ranges from 0 (low beta diversity, similar communities), to 1 (high beta
   # diversity, dissimilar communities). The weight of the percent permuted
   # parameter is proportional to the percent shared. At 0% shared, the fraction
   # permuted has no weight in the index, while at 100% shared, the fraction
   # permuted and fraction shared have the same weight.
   #
   # For example:
   #      for 100 % shared, 0   % permuted -> M = 0
   #      for 100 % shared, 100 % permuted -> M = 0.5
   #      for 0   % shared, 0   % permuted -> M = 1
   #      for 0   % shared, 100 % permuted -> M = 1

   # Calculate the fraction shared
   my $s = $self->_shared($community1, $community2) / 100;

   # Calculate the fraction permuted
   my $p = $self->_permuted($community1, $community2);
   if (not defined $p) {
      $p = 100; # but any value between 0 and 100 would work as well
   }
   $p /= 100;

   # Calculate the Maxiphi index
   my $m = 1 - $s * (2-$p) / 2;
   return $m;
}


method _unifrac ($community1, $community2, $tree) {
   #### TODO: unifrac distance
   $self->throw_not_implemented;
}


__PACKAGE__->meta->make_immutable;

1;
