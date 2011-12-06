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

=head1 CONSTRUCTOR

=head2 Bio::Community::Tools::Sampler->new()

   my $member = Bio::Community::Member->new();

The new() class method constructs a new Bio::Community::Tools::Sampler object and
accepts the following parameters:

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
 Args    : 
 Returns : a new Bio::Community::Tools::Sampler object

=cut


package Bio::Community::Tools::Sampler;

use Moose;
use MooseX::Method::Signatures;
use namespace::autoclean;

use Bio::Community;

extends 'Bio::Root::Root';


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

after community => sub {
   # Calculate cdf
   my $self = shift;
   $self->_cdf( $self->_calc_cdf() );
};


=head2 get_rand_member

 Title   : get_rand_member
 Function: Get random members from the community
 Usage   : my $member = $sampler->get_rand_member();
 Args    : 
 Returns : a Bio::Community object

=cut

method get_rand_member () {
   
}


method get_rand_community () {
   
}


has _cdf => (
   is => 'rw',
   isa => 'ArrayRef[PositiveNum]',
   required => 1,
   lazy => 1,
   default => sub{ {} },
   init_arg => undef,
);


method _calc_cdf () {
   # Calculate the cumulative density function for this community
   my $community = $self->community;
   my @cdf = (0);
   my $sum = 0;
   while (my $member = $community->next_member) {
      my $rel_ab = $community->get_rel_ab($member);
      $sum += $rel_ab;
      push @cdf, $sum;
   }
   return \@cdf;
}



__PACKAGE__->meta->make_immutable;

1;
