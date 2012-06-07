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
are, the larger the distance between them. Thus, these distance metrics can also
be considered a measure of beta-diversity.

Several types of distance are available: 1-norm, 2-norm (euclidean), and
infinity-norm. They consider the communities as a n-dimensional space, where n
is the total number of unique community members across the communities.

Note that the distances are based on the relative abundance (as a fractional
number between 0 and 1, not as a percentage) and is hence affected by weights
assigned to the community members. See the get_rel_ab() method in
L<Bio::Community>.

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
use List::Util qw(min);

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

 Function: Calculate the distance between the communities based on the relative
           abundance of the members.
 Usage   : my $distance = $ruler->get_distance;
 Args    : none
 Returns : a number for the distance

=cut

####after new => sub { # prevents inlining
#### or maybe try BUILD
method get_distance {
   my $dist;
   my $type = $self->type;
   if ($type eq '1-norm') {
      $dist = $self->_pnorm(1);
   } elsif ( ($type eq '2-norm') || ($type eq 'euclidean') ) {
      $dist = $self->_pnorm(2);
   } elsif ($type eq 'infinity-norm') {
      $dist = $self->_infnorm();
   } elsif ($type eq 'hellinger') {
      $dist = $self->_hellinger();
   } elsif ($type eq 'bray-curtis') {
      $dist = $self->_braycurtis();
   } elsif ($type eq 'unifrac') {
      $dist = $self->_unifrac();
   } else {
      $self->throw("Invalid distance type '$type'");
   }
   return $dist;
};


method _pnorm ($power) {
   # Calculate the p-norm. If power is 1, this is the 1-norm. If power is 2,
   # this is the 2-norm (a.k.a. euclidean distance).
   my $communities = $self->communities;
   my $community1  = $communities->[0];
   my $community2  = $communities->[1];
   my $all_members = $community1->get_all_members($communities);
   my $sumdiff = 0;
   for my $member (@$all_members) {
      my $abundance1 = $community1->get_rel_ab($member) / 100;
      my $abundance2 = $community2->get_rel_ab($member) / 100;
      $sumdiff += ( abs($abundance1 - $abundance2) )**$power;
   }
   my $dist = $sumdiff ** (1/$power);
   return $dist;
}


method _infnorm () {
   # Calculate the infinity-norm.
   my $communities = $self->communities;
   my $community1  = $communities->[0];
   my $community2  = $communities->[1];
   my $all_members = $community1->get_all_members($communities);
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


method _hellinger () {
   # Calculate the Hellinger distance.
   return $self->_pnorm(2) / sqrt(2);
}


method _braycurtis () {
   # Calculate the Bray-Curtis dissimilarity index BC:
   #    BC = 1 - sum( min(r_i, r_j) )
   # where r_i and r_j are the relative abundance (fractional) for species in
   # common between both sites.
   # Can also be written as:
   #    BC = sum( c_i - c_j ) / sum( c_i + c_j )
   # where c_i and c_j are the counts for all observed species.
   my $communities = $self->communities;
   my $community1  = $communities->[0];
   my $community2  = $communities->[1];
   my $all_members = $community1->get_all_members($communities);
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


method _unifrac () {
   #### TODO: unifrac distance
   $self->throw_not_implemented;
}


__PACKAGE__->meta->make_immutable;

1;
