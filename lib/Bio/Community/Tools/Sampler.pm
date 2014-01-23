# BioPerl module for Bio::Community::Tools::Sampler
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
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

 Function: Create a new Bio::Community::Tool::Sampler object
 Usage   : my $sampler = Bio::Community::Tool::Sampler->new( );
 Args    : -community: See community().
           -seed     : See set_seed().
 Returns : a new Bio::Community::Tools::Sampler object

=cut


package Bio::Community::Tools::Sampler;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;
use Bio::Community;

extends 'Bio::Root::Root';
with 'Bio::Community::Role::PRNG';


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
   default => sub { shift->_init_cdf( ) },
   init_arg => undef,
);


has _members => (
   is => 'rw',
   isa => 'ArrayRef', # ArrayRef[Bio::Community::Member]
   lazy => 1,
   default => sub{ [] },
   init_arg => undef,
);


=head2 get_seed, set_seed

 Usage   : $sampler->set_seed(1234513451);
 Function: Get or set the seed used to pick the random members.
 Args    : Positive integer
 Returns : Positive integer

=cut


=head2 get_rand_member

 Function: Get a random member from a community (sample with replacement).
 Usage   : my $member = $sampler->get_rand_member();
 Args    : None
 Returns : A Bio::Community::Member object

=cut

method get_rand_member () {
   # Pick a random member based on the community's cdf
   my $rand_pick = $self->rand();
   my $cdf = $self->_cdf;
   my $index = 0;
   while (1) {
      last if $rand_pick < $cdf->[$index];
      $index++;
   }
   return ${$self->_members}[$index];
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


method _init_cdf () {
   # Sort the members of the community by decreasing rank and calculate the
   # cumulative density function of their relative abundance. Store the
   # resulting CDF and members;
   my $community = $self->community;

   my @cdf;
   my @members = ();
   while ( my $member = $community->next_member('_calc_cdf_ite') ) {
      my $rank = $community->get_rank($member);
      $members[$rank-1] = $member;
      my $rel_ab = $community->get_rel_ab($member);
      $cdf[$rank-1] = $rel_ab / 100;
   }

   for my $i ( 1 .. scalar @cdf - 1 ) {
      $cdf[$i] += $cdf[$i-1];
   }

   $self->_cdf( \@cdf );
   $self->_members( \@members );
   return \@cdf;
}



__PACKAGE__->meta->make_immutable;

1;
