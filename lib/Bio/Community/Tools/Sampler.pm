# BioPerl module for Bio::Community::Tools::Sampler
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::Sampler - Sample organisms according to their abundance

=head1 SYNOPSIS

  use Bio::Community::Tools::Sampler;

  # get a community somehow...

  my $sampler = Bio::Community::Tools::Sampler->new( -community => $community );
  my $member1 = $sampler->get_rand_member();
  my $member2 = $sampler->get_rand_member();

=head1 DESCRIPTION

Pick individuals at random (without replacement) from a community.

Note that the sampling is done based on relative abundances, and is hence
affected by weights. If you need to sample based on counts instead, simply set
$community->use_weights(0), before using Bio::Community::Tools::Sampler.

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

 Function: Create a new Bio::Community::Tool::Sampler object
 Usage   : my $sampler = Bio::Community::Tool::Sampler->new( );
 Args    : -community (see below)
 Returns : a new Bio::Community::Tools::Sampler object

=cut


package Bio::Community::Tools::Sampler;

use Moose;
use MooseX::NonMoose;
use Method::Signatures;
use namespace::autoclean;
use List::Util qw( first );
use Bio::Community;

####
#use Math::Random::MT qw(srand rand);
####

extends 'Bio::Root::Root';


method BUILD ($args) {
   # Prepare the CDF that we will be sampling from after new()
   my ($cdf, $members) = $self->_calc_cdf();
   $self->_cdf( $cdf );
   $self->_members( $members );
}


=head2 community

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
   isa => 'ArrayRef', # ArrayRef[PositiveNum]
   lazy => 1,
   default => sub{ [] },
   init_arg => undef,
);


has _members => (
   is => 'rw',
   isa => 'ArrayRef', # ArrayRef[Bio::Community::Member]
   lazy => 1,
   default => sub{ [] },
   init_arg => undef,
);


=head2 get_rand_member

 Function: Get a random member from a community (sample with replacement).
 Usage   : my $member = $sampler->get_rand_member();
 Args    : None
 Returns : A Bio::Community::Member object

=cut

method get_rand_member {
   # Pick a random member based on the community's cdf
   my $rand_pick = rand();
   my $cdf = $self->_cdf;
   my $index = 1;
   while (1) {
      last if $rand_pick < $cdf->[$index];
      $index++;
   }
   return ${$self->_members}[$index-1];
}


=head2 get_rand_community

 Function: Create a community from random members of a community
 Usage   : my $community = $sampler->get_rand_community(1000);
 Args    : Number of members (strictly positive integer)
 Returns : A Bio::Community object

=cut

method get_rand_community ( StrictlyPositiveInt $total_count = 1 ) {
   # Adding random members 1 by 1 in a communty is slow. Generate all the members
   # first. Then add them all at once to a community.

   # 1/ Generate all random members
   my $members = {};
   my $counts  = {};
   for (1 .. $total_count) {
      my $member = $self->get_rand_member;
      my $id = $member->id;
      $members->{$id} = $member;
      $counts->{$id}++;
   }

   # 2/ Add all members in a community object
   my $community = Bio::Community->new();
   while (my ($id, $member) = each %$members) {
      my $count = $counts->{$id};
      $community->add_member( $member, $count );
   }
   
   return $community;
}


method _calc_cdf {
   # Sort the members of the community by decreasing rank and calculate the
   # cumulative density function of their relative abundance
   my $community = $self->community;

   my @cdf = (0);
   my @members = ();
   while ( my $member = $community->next_member('_calc_cdf_ite') ) {
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
