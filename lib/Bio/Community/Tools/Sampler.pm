# BioPerl module for Bio::Community::Tools::Sampler
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

=head1 NAME

Bio::Community::Tools::Sampler - Sample organisms according to their abundance

=head1 SYNOPSIS

  use Bio::Community::Tools::Sampler;

  # get a community somehow...

  my $sampler = Bio::Community::Tools::Sampler->new( -community => $community );
  my $member1 = $sampler->get_rand_member();
  my $member2 = $sampler->get_rand_member();

=head1 DESCRIPTION

Pick individuals at random from a community

=head1 OBJECT METHODS

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
 Usage   : my $sampler = Bio::Community::Tool::Sampler->new( );
 Args    : -community (see below)
 Returns : a new Bio::Community::Tools::Sampler object

=cut


package Bio::Community::Tools::Sampler;

use Moose;
use MooseX::NonMoose;
use MooseX::Method::Signatures;
use namespace::autoclean;
use List::Util qw( first );
use Bio::Community;

extends 'Bio::Root::Root';


method BUILD {
   # Prepare the CDF that we will be sampling from after new()
   my ($cdf, $members) = $self->_calc_cdf();
   $self->_cdf( $cdf );
   $self->_members( $members );
}


=head2 community

 Title   : community
 Function: Get or set the community to sample from
 Usage   : my $community = $sampler->community();
 Args    : a Bio::Community object
 Returns : a Bio::Community object

=cut

has community => (
   is => 'ro',
   isa => 'Bio::Community',
   required => 1,
   lazy => 0,
   init_arg => '-community',
);


has _cdf => (
   is => 'rw',
   isa => 'ArrayRef[PositiveNum]',
   lazy => 1,
   default => sub{ [] },
   init_arg => undef,
);


has _members => (
   is => 'rw',
   isa => 'ArrayRef[Bio::Community::Member]',
   lazy => 1,
   default => sub{ [] },
   init_arg => undef,
);


=head2 get_rand_member

 Title   : get_rand_member
 Function: Get a random member from a community (sample with replacement).
 Usage   : my $member = $sampler->get_rand_member();
 Args    : None
 Returns : A Bio::Community::Member object

=cut

method get_rand_member () {
   # Pick a random member based on the community's cdf
   my $cdf = $self->_cdf;
   my $rand_pick = rand();
   my $index = first {$rand_pick < $$cdf[$_+1]} (0 .. scalar @$cdf - 2);
   return ${$self->_members}[$index];
}

### TODO: option to sample without replacement!


=head2 get_rand_community

 Title   : get_rand_community
 Function: Create a community from random members of a community
 Usage   : my $community = $sampler->get_rand_community(1000);
 Args    : Number of members
 Returns : A Bio::Community object

=cut

method get_rand_community ( StrictlyPositiveInt $total_count = 1 ) {
   my $community = Bio::Community->new();
   $community->add_member( $self->get_rand_member ) for (1 .. $total_count);
   return $community;
}


method _calc_cdf () {
   # Sort the members of the community by decreasing rank and calculate the
   # cumulative density function of their relative abundance
   my $community = $self->community;

   my @cdf = (0);
   my @members = ();
   while (my $member = $community->next_member) {
      my $rank = $community->get_rank($member);
      $members[$rank-1] = $member;
      my $rel_ab = $community->get_rel_ab($member);
      $cdf[$rank] = $rel_ab / 100;
   }

   for my $i ( 1 .. scalar @cdf - 1 ) {
      $cdf[$i] += $cdf[$i-1];
   }

   return \@cdf, \@members;
}



__PACKAGE__->meta->make_immutable;

1;
