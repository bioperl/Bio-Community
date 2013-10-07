# BioPerl module for Bio::Community::Meta::Gamma
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Meta::Gamma - Calculate the gamma diversity of a metacommunity

=head1 SYNOPSIS

  use Bio::Community::Meta::Gamma;
  
  my $gamma = Bio::Community::Meta::Gamma->new( -community => $community,
                                                -type      => 'richness'  );
  my $richness = $gamma->get_gamma;

=head1 DESCRIPTION

The Bio::Community::Meta::Gamma module calculates the gamma diversity of a group
of communities (provided as a metacommunity object). The goal is to support the
same diversity metrics provided by Bio::Community::Alpha, but the only metric
available at the moment is: richness.

For all these metrics, a higher value means that the community is more diverse.

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

 Function: Create a new Bio::Community::Meta::Gamma object
 Usage   : my $gamma = Bio::Community::Meta::Gamma->new( ... );
 Args    : -metacommunity : See metacommunity().
           -type          : See type().
 Returns : a new Bio::Community::Meta::Gamma object

=cut


package Bio::Community::Meta::Gamma;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;

extends 'Bio::Root::Root';


=head2 metacommunity

 Function: Get or set the communities to process, given as a metacommunity.
 Usage   : my $meta = $gamma->metacommunity;
 Args    : A Bio::Community::Meta object
 Returns : A Bio::Community::Meta object

=cut

has metacommunity => (
   is => 'ro',
   isa => 'Bio::Community::Meta',
   required => 1,
   lazy => 0,
   init_arg => '-metacommunity',
);


=head2 type

 Function: Get or set the type of gamma diversity metric to measure.
 Usage   : my $type = $gamma->type;
 Args    : String for the desired type of gamma diversity:
            * richness: the number of species in the metacommunity
           This defaults to richness
 Returns : String for the desired type of gamma diversity

=cut

has type => (
   is => 'ro',
   isa => 'AlphaType', # support same metrics as Bio::Community::Alpha
   required => 0,
   lazy => 1,
   default => 'observed',
   init_arg => '-type',
);


#####
# TODO
#   build a "gamma community" and feed it to Bio::Community::Alpha so that we can
#   use all the same alpha diversity metrics
#####


=head2 get_gamma

 Function: Calculate the gamma diversity of a community.
 Usage   : my $metric = $gamma->get_gamma;
 Args    : None
 Returns : A number for the gamma diversity measurement

=cut

method get_gamma () {
   my $metric = '_'.$self->type;
   return $self->$metric();
};


method _observed () {
   # Calculate the observed richness
   return $self->metacommunity->get_richness;
}


__PACKAGE__->meta->make_immutable;

1;
