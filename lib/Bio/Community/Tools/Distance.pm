# BioPerl module for Bio::Community::Tools::Distance
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code


=head1 NAME

Bio::Community::Tools::Distance - Calculate the distance separating communities

=head1 SYNOPSIS

  use Bio::Community::Tools::Distance;

  my $obj = Bio::Community::Tools::Distance->new(
     -communities => [ $community1, $community2 ],
     -type        => 'euclidean',
  );
  my $distance = $obj->get_distance;

=head1 DESCRIPTION

Calculate the distance between two communities. The more different communities
are, the larger the distance between them. Thus, these distance metrics can also
be considered a measure of beta-diversity.

Several types of distance are available: 1-norm, 2-norm (euclidean), and
infinity-norm. They consider the communities as a n-dimensional space, where n
is the total number of unique community members across the communities.

Note that the distance is based on the relative abundance and is hence affected
by weights assigned to the community members. See the get_rel_ab() method in
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

 Title   : new
 Function: Create a new Bio::Community::Tool::Sampler object
 Usage   : my $obj = Bio::Community::Tools::Distance->new(
              -communities => [ $community1, $community2 ],
              -type        => 'euclidean',
           );
 Args    : -communities
              An arrayref of the communities (Bio::Community objects) to
              calculate the distance from.
           -type
              The type of distance to use: 1-norm, 2-norm (euclidean), or
              infinity-norm.
 Returns : a Bio::Community::Tools::Distance object

=cut

#### TODO: unifrac distance


package Bio::Community::Tools::Distance;

use Moose;
use MooseX::NonMoose;
use MooseX::Method::Signatures;
use namespace::autoclean;

extends 'Bio::Root::Root';


has communities => (
   is => 'ro',
   isa => 'ArrayRef[Bio::Community]',
   required => 1,
   lazy => 0,
   init_arg => '-communities',
);


has type => (
   is => 'ro',
   isa => 'DistanceType',
   required => 0,
   lazy => 1,
   default => '2-norm',
   init_arg => '-type',
);


=head2 get_distance

 Title   : get_distance
 Function: Calculate the distance between the communities based on the relative
           abundance of the members.
 Usage   : my $distance = $obj->get_distance;
 Args    : none
 Returns : a number for the distance

=cut

####after new => sub { # prevents inlining
#### or maybe try BUILD
method get_distance () {
   my $dist;
   my $type = $self->type;
   if ($type eq '1-norm') {
      $dist = $self->_pnorm(1);
   } elsif ( ($type eq '2-norm') || ($type eq 'euclidean') ) {
      $dist = $self->_pnorm(2);
   } elsif ($type eq 'infinity-norm') {
      $dist = $self->_infnorm();
   } else {
      $self->throw("Invalid distance type '$type'");
   }
   return $dist;
};


method _pnorm (PositiveNum $power) {
   # Calculate the p-norm. If power is 1, this is the 1-norm. If power is 2,
   # this is the 2-norm.
   my ($community1, $community2) = @{$self->communities};
   my $sumdiff = 0;
   # 1/ Process members of community 1
   while (my $member = $community1->next_member) {
      my $abundance1 = $community1->get_rel_ab($member);
      my $abundance2 = $community2->get_rel_ab($member);
      $sumdiff += ( abs($abundance1 - $abundance2) )**$power;
   }
   # 2/ Process members unique to community 2
   while (my $member = $community2->next_member) {
      next if $community1->get_rel_ab($member);
      my $abundance2 = $community2->get_rel_ab($member);
      # Abundance 1 is 0, so we simplify:
      #    $sumdiff += ( abs($abundance1 - $abundance2) )**$power;
      # to:
      $sumdiff += $abundance2**$power
   }
   my $dist = $sumdiff ** (1/$power);
   return $dist;
}


method _infnorm () {
   # Calculate the infinity-norm.
   my ($community1, $community2) = @{$self->communities};
   my $dist = 0;
   # 1/ Process members of community 1
   while (my $member = $community1->next_member) {
      my $abundance1 = $community1->get_rel_ab($member);
      my $abundance2 = $community2->get_rel_ab($member);
      my $diff = abs($abundance1 - $abundance2);
      if ($diff > $dist) {
         $dist = $diff;
      }
   }
   # 2/ Process members unique to community 2
   while (my $member = $community2->next_member) {
      next if $community1->get_rel_ab($member);
      my $abundance2 = $community2->get_rel_ab($member);
      # Abundance 1 is 0, so we simplify:
      #    my $diff = abs($abundance1 - $abundance2);
      # to:
      my $diff = $abundance2;
      if ($diff > $dist) {
         $dist = $diff;
      }
   }
   return $dist;
}


__PACKAGE__->meta->make_immutable;

1;
