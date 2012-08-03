# BioPerl module for Bio::Community::Meta
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Meta - A metacommunity, or group of communities

=head1 SYNOPSIS

  use Bio::Community::Meta;
  
  XXX
  

=head1 DESCRIPTION

The Bio::Community::Meta module represent metacommunities, or groups of
communities. This object holds several Bio::Community objects, for examples
tree communities found at different sites of a forest. Random access to any of
the communities is provided. However, the communities can also be accessed
sequentially in the order they were given. This makes Bio::Community::Meta
capable of representing communities along a natural gradient.

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

 Function: Create a new Bio::Community::Meta object
 Usage   : my $meta = Bio::Community::Meta->new( ... );
 Args    : -name       : see name()
           -communities: see add_communities()
 Returns : a new Bio::Community::Meta object

=cut


package Bio::Community::Meta;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;
use Tie::IxHash;


extends 'Bio::Root::Root';


method BUILD ($args) {
   # Process -community constructor
   my $communities = delete $args->{'-communities'};
   if ($communities) {
      $self->add_communities($communities);
   }
}


=head2 name

 Function: Get or set the name of the metacommunity
 Usage   : $meta->name('estuary_salinity_gradient');
           my $name = $meta->name();
 Args    : string for the name
 Returns : string for the name

=cut

has name => (
   is => 'rw',
   isa => 'Str',
   lazy => 1,
   default => 'Unnamed metacommunity',
   init_arg => '-name',
);



##### If the name of a community changed, need to change the hash



###=head2 get_total_count

### Function: Get the total number of members in the community
### Usage   : $community->get_total_count();
### Args    : none
### Returns : integer

###=cut

###has total_count => (
###   is => 'ro',
###   #isa => 'PositiveNum', # too costly for an internal method
###   lazy => 1,
###   default => 0,
###   init_arg => undef,
###   reader => 'get_total_count',
###   writer => '_set_total_count',
###);


###has _weighted_count => (
###   is => 'rw',
###   #isa => 'PositiveNum', # too costly for an internal method
###   lazy => 1,
###   default => 0,
###   init_arg => undef,
###);


###has _members => (
###   is => 'rw',
###   isa => 'HashRef',
###   lazy => 1,
###   default => sub{ {} },
###   init_arg => undef,
###);


###has _counts => (
###   is => 'rw',
###   isa => 'HashRef',
###   lazy => 1,
###   default => sub{ {} },
###   init_arg => undef,
###);


###has _ranks_hash_weighted => (
###   is => 'rw',
###   isa => 'HashRef',
###   lazy => 1,
###   default => sub{ {} },
###   init_arg => undef,
###   clearer => '_clear_ranks_hash_weighted',
###);


###has _ranks_arr_weighted => (
###   is => 'rw',
###   isa => 'ArrayRef',
###   lazy => 1,
###   default => sub{ [] },
###   init_arg => undef,
###   clearer => '_clear_ranks_arr_weighted',
###);


###has _ranks_hash_unweighted => (
###   is => 'rw',
###   isa => 'HashRef',
###   lazy => 1,
###   default => sub{ {} },
###   init_arg => undef,
###   clearer => '_clear_ranks_hash_unweighted',
###);


###has _ranks_arr_unweighted => (
###   is => 'rw',
###   isa => 'ArrayRef',
###   lazy => 1,
###   default => sub{ [] },
###   init_arg => undef,
###   clearer => '_clear_ranks_arr_unweighted',
###);


###has _richness => (
###   is => 'rw',
###   isa => 'Maybe[Int]',
###   lazy => 1,
###   default => undef,
###   init_arg => undef,
###   clearer => '_clear_richness',
###);


###has _members_iterator => (
###   is => 'rw',
###   isa => 'Maybe[HashRef]',
###   lazy => 1,
###   default => undef,
###   init_arg => undef,
###   clearer => '_clear_members_iterator',
###);

###has _has_changed => (
###   is => 'rw',
###   isa => 'Bool',
###   lazy => 1,
###   default => 0,
###   init_arg => undef,
###);



has _communities => (
   is => 'rw',
   #isa => 'Tie::IxHash',
   lazy => 1,
   default => sub{ tie my %hash, 'Tie::IxHash'; return \%hash },
   init_arg => undef,
);


=head2 add_communities

 Function: Add communities to a metacommunity. Communities have to have distinct
           names.
 Usage   : $meta->add_communities([$community1, $community2]);
 Args    : an arrayref of Bio::Community objects to add
 Returns : 1 on success

=cut

method add_communities ( ArrayRef[Bio::Community] $communities ) {
   my $comm_hash = $self->_communities;
   for my $community (@$communities) {
      my $name = $community->name;
      if (exists $comm_hash->{$name}) {
         $self->throw("Could not add community '$name' because there already is".
            "a community with this name in the metacommunity");
      }
      $comm_hash->{$name} = $community;
   }
   $self->_communities( $comm_hash );
   $self->_set_community_count( $self->get_community_count + scalar @$communities );
   return 1;
}


=head2 remove_community

 Function: Remove a community from a metacommunity
 Usage   : $meta->remove_community($community);
 Args    : A Bio::Community to remove
 Returns : 1 on success

=cut

method remove_community ( Bio::Community $community ) {
   delete $self->_communities->{$community->name};
   $self->_set_community_count( $self->get_community_count - 1 );
   return 1;
}


=head2 next_community

 Function: Access the next community in the metacommunity (in the order the
           communities were added). 
 Usage   : my $member = $meta->next_community();
 Args    : none
 Returns : a Bio::Community object

=cut

method next_community ( ) {
   my $community = (each %{$self->_communities})[1];
   return $community;
}


=head2 get_all_communities

 Function: Generate a list of all communities in the metacommunity.
 Usage   : my @communities = $meta->get_all_communities();
 Args    : an arrayref of Bio::Community objects
 Returns : an arrayref of Bio::Community::Member objects

=cut

method get_all_communities ( ) {
   my @all_communities = values %{$self->_communities};   
   return \@all_communities;
}


=head2 get_community_by_name

 Function: Fetch a community based on its ID
 Usage   : my $community = $meta->get_community_by_name('prairie');
 Args    : string for the community name
 Returns : a Bio::Community object or undef if the community was not found

=cut

method get_community_by_name ( Str $name ) {
   my $community = $self->_communities->{$name};
   return $community;
}


=head2 get_community_count

 Function: Get the total number of communities in the metacommunity
 Usage   : $meta->get_community_count();
 Args    : none
 Returns : integer

=cut

has _community_count => (
   is => 'ro',
   #isa => 'PositiveNum', # too costly for an internal method
   lazy => 1,
   default => 0,
   init_arg => undef,
   reader => 'get_community_count',
   writer => '_set_community_count',
);




#=head2 get_richness

# Function: Report the community richness or number of different types of members.
# Usage   : my $richness = $community->get_richness();
# Args    : none
# Returns : integer for the richness

#=cut

#method get_richness {
#   $self->_reset if $self->_has_changed;
#   if (not defined $self->_richness) {

#      # Try to calculate the richness from the abundance ranks if available
#      my $num_members = scalar( @{$self->_ranks_arr_weighted}   ) ||
#                        scalar( @{$self->_ranks_arr_unweighted} ) ;

#      # If rank abundance are not available, calculate richness manually
#      if ($num_members == 0) {
#         while ($self->next_member('_get_richness_ite')) {
#            $num_members++;
#         }
#      }

#      # Save richness for later re-use
#      $self->_richness($num_members);
#   }
#   return $self->_richness;
#}


# get_all_members

# get_member_total_count

__PACKAGE__->meta->make_immutable;

1;
