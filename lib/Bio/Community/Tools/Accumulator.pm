# BioPerl module for Bio::Community::Tools::Rarefier
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::Accumulator - Species accumulation curves

=head1 SYNOPSIS

  use Bio::Community::Tools::Accumulator;

###  # Normalize communities in a metacommunity by repeatedly taking 1,000 random members
###  my $rarefier = Bio::Community::Tools::Rarefier->new(
###     -metacommunity => $meta,
###     -sample_size   => 1000,
###     -threshold     => 0.001, # stop bootstrap iterations when threshold is reached
###  );

###  # Rarefied results, with decimal counts
###  my $average_community = $rarefier->get_avg_meta->[0];

###  # Round counts to integer numbers
###  my $representative_community = $rarefier->get_repr_meta->[0];
###  

###  # Alternatively, specify a number of repetitions
###  my $rarefier = Bio::Community::Tools::Rarefier->new(
###     -metacommunity => $meta,
###     -sample_size   => 1000,
###     -repetitions   => 0.001, # stop after this number of bootstrap iterations
###  );

###  # ... or assume an infinite number of repetitions
###  my $rarefier = Bio::Community::Tools::Rarefier->new(
###     -metacommunity => $meta,
###     -sample_size   => 1000,
###     -repetitions   => 'inf',
###  );

=head1 DESCRIPTION

This module takes a metacommunity and produces two types of species accumulation
curves: rarefaction curves, collector curves.

NEED EXPLANATIONS

WARNING: NEED integer counts, not relative abundance

Note: No plots are drawn. Only the data needed for the plots is computed.

=head1 AUTHOR

Florent Angly L<florent.angly@gmail.com>

=head1 SUPPORT AND BUGS

User feedback is an integral part of the evolution of this and other Bioperl
modules. Please direct usage questions or support issues to the mailing list, 
L<bioperl-l@bioperl.org>, rather than to the module maintainer directly. Many
experienced and reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem with code and
data examples if at all possible.

If you have found a bug, please report it on the BioPerl bug tracking system
to help us keep track the bugs and their resolution:
L<https://redmine.open-bio.org/projects/bioperl/>

=head1 COPYRIGHT

Copyright 2011-2014 by Florent Angly <florent.angly@gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=head2 new

 Function: Create a new Bio::Community::Tool::Accumulator object
 Usage   : my $accumulator = Bio::Community::Tool::Accumulator->new( );
 Args    : -metacommunity: see metacommunity()
           -type         : 'rarefaction' or 'collector'
           -repetitions  : see repetitions()
           -nof_ticks    : see nof_ticks()
           -alpha        : see alpha()
           -seed         : see set_seed()
 Returns : a new Bio::Community::Tools::Accumulator object

=cut


package Bio::Community::Tools::Accumulator;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Bio::Community::Meta;
####use Bio::Community::Meta::Beta;
####use POSIX;
####use List::Util qw(min); ####
use Method::Signatures;

extends 'Bio::Root::Root';
with 'Bio::Community::Role::PRNG';


=head2 metacommunity

 Function: Get or set the metacommunity to normalize.
 Usage   : my $meta = $accumulator->metacommunity;
 Args    : A Bio::Community::Meta object
 Returns : A Bio::Community::Meta object

=cut

has metacommunity => (
   is => 'rw',
   isa => 'Maybe[Bio::Community::Meta]',
   required => 0,
   default => undef,
   lazy => 1,
   init_arg => '-metacommunity',
);


=head2 type

 Function: Get or set the type of accumulation curve to produce.
 Usage   : my $type = $accumularot->type;
 Args    : String of the accumulation curve type: 'rarefaction' (default) or 'collector'
 Returns : String of the accumulation curve type

=cut

has type => (
   is => 'rw',
   isa => 'AccumulationType',
   required => 0,
   default => 'rarefaction',
   lazy => 1,
   init_arg => '-type',
);


=head2 repetitions

 Function: Get or set the number of repetitions to perform. The mean across all
           these repetitions is reported.
 Usage   : my $repetitions = $accumulator->repetitions;
 Args    : positive integer or 'inf' number of repetitions
 Returns : positive integer for the (minimum) number of repetitions

=cut

has repetitions => (
   is => 'rw',
   isa => 'Maybe[PositiveInt | Str]',
   required => 0, 
   default => undef,
   lazy => 1,
   init_arg => '-repetitions',
);


=head2 nof_ticks

 Function: For rarefaction curves, get or set how many different numbers of
           individuals to sample. This number is a minimum (for the community
           with the smallest number of individuals) and the ticks are
           logarithmically spaced.
 Usage   : my $nof_ticks = $accumulator->repetitions;
 Args    : positive integer for the number of repetitions  (default: 10)
 Returns : positive integer for the number of repetitions

=cut

has nof_ticks => (
   is => 'rw',
   isa => 'StrictlyPositiveInt',
   required => 0, 
   default => 12,
   lazy => 1,
   init_arg => '-nof_ticks',
);


=head2 alpha

 Function: Get or set the type of alpha diversity to calculate.
 Usage   : my $alpha = $accumulator->alpha;
 Args    : 
 Returns : 

=cut

has alpha => (
   is => 'rw',
   ####isa => 'Maybe[PositiveInt | Str]',
   required => 0, 
   default => undef,
   lazy => 1,
   init_arg => '-repetitions',
);


=head2 get_seed, set_seed

 Usage   : $sampler->set_seed(1234513451);
 Function: Get or set the seed used to pick the random members.
 Args    : Positive integer
 Returns : Positive integer

=cut


=head2 get_curve

 Function: Calculate the accumulation curve.
 Usage   : my $curve = $rarefier->get_curve;
 Args    : none
 Returns : A tab-delimited string for the accumulation curve.

=cut

method get_curve {
   # Determine range:
   #    collector: 1..nof_samples for collector
   #    rarefaction: 1 to max_count of smallest comm. Extend for larger communities
   my $ticks = $self->_get_ticks();
   use Data::Dumper; print Dumper($ticks);
   # rarefaction: can use 
   # if (rarefaction) {
   #    for my $num (@range) {
   #       # use Rarefier (special case for inf!)
   #       # calculate alpha
   #    }
   # } elsif (collector) {
   #    for my $num (@range) {
   #       # mix communities manually
   #       # calculate alpha
   #    }
   # } else { 
   #    error
   # }
   #return $string;
}


method _get_ticks {
   # Sanity check
   my $meta = $self->metacommunity;
   if ( (not $meta) || ($meta->get_communities_count == 0) ) {
      $self->throw('Should have a metacommunity containing at least one community');
   }

   my @ticks;
   if ($self->type eq 'collector') {
      # Ticks for a collector curve, i.e. number of communities
      @ticks = 1 .. $meta->get_communities_count;
   } else {
      # Ticks for a rarefaction curve, i.e. number of individuals
      my $comms = $meta->get_all_communities;

      my $counts = [ map {$_->get_members_count} @$comms ];
      my $sort_order = [ sort { $counts->[$a] <=> $counts->[$b] } 0..$#$comms ];
      my $min_count = $counts->[0];
      my $max_count = $counts->[1];

      my $nof_ticks = $self->nof_ticks - 1;
      
      #my $interval = $min_count / ($nof_ticks-1);
      #print "interval: $interval\n"; ###
      #my @ticks = (0);
      #for my $i (1 .. $nof_ticks) {
      #   push @ticks, $ticks[$i-1]+$interval;
      #}
      #use Data::Dumper; print Dumper(\@ticks);

      #my $param = $min_count / (exp($nof_ticks-1)-1);
      #print "param: $param\n"; ###
      #@ticks = map { $param*(exp($_)-1) } 0..$nof_ticks-1;

      my $param = ($min_count-1) / (exp($nof_ticks-1)-1);
      @ticks = (0);
      my $tick_num = -1;
      for my $i (@$sort_order) {
         my $count = $counts->[$i];
         my $val;
         while (1) {
            $tick_num++;
            $val = $param*(exp($tick_num)-1)+1;
            print "val: $val\n"; ####
            $val = int( $val + 0.5 );
            next if $val == $ticks[-1]; # avoid duplicates
            if ($val < $count) {
               push @ticks, $val;
            } else {
               push @ticks, $count;
               $tick_num-- if $val > $count;
               last;
            }
         }
      }

   }
   return \@ticks;
}

__PACKAGE__->meta->make_immutable;

1;
