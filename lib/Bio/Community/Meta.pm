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
  
  my $meta = Bio::Community::Meta->new( -name => 'alpine' );

  # Get communities from somewhere and ...
  $meta->add_communities( [$community1, $community2, $community3] );
  
  print "Metacommunity contains:\n";
  print "   ".$meta->get_communities_count." communities\n";
  print "   ".$meta->get_richness." species\n";
  print "   ".$meta->get_members_count." individuals\n";

=head1 DESCRIPTION

The Bio::Community::Meta module represent metacommunities, or groups of
communities. This object holds several Bio::Community objects, for example
tree communities found at different sites of a forest. Random access to any of
the communities is provided. However, the communities can also be accessed
sequentially, in the order they were given. This makes Bio::Community::Meta
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
 Returns : A new Bio::Community::Meta object

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
 Args    : String for the name
 Returns : String for the name

=cut

has name => (
   is => 'rw',
   isa => 'Str',
   lazy => 1,
   default => 'Unnamed',
   init_arg => '-name',
);


# Communities are stored in a sorted hash
has _communities => (
   is => 'rw',
   #isa => 'Tie::IxHash',
   lazy => 1,
   default => sub { tie my %hash, 'Tie::IxHash'; return \%hash },
   init_arg => undef,
);


=head2 add_communities

 Function: Add communities to a metacommunity. Communities have to have distinct
           names. Do not change the name of a community after you have added it!
 Usage   : $meta->add_communities([$community1, $community2]);
 Args    : An arrayref of Bio::Community objects to add
 Returns : 1 on success

=cut

method add_communities ( ArrayRef[Bio::Community] $communities ) {
   my $comm_hash = $self->_communities;
   for my $community (@$communities) {
      my $name = $community->name;
      if (exists $comm_hash->{$name}) {
         $self->throw("Could not add community '$name' because there already is".
            " a community with this name in the metacommunity");
      }
      $comm_hash->{$name} = $community;
   }
   $self->_communities( $comm_hash );
   $self->_set_communities_count( $self->get_communities_count + scalar @$communities );
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
   $self->_set_communities_count( $self->get_communities_count - 1 );
   return 1;
}


=head2 next_community

 Function: Access the next community in the metacommunity (in the order the
           communities were added). 
 Usage   : my $member = $meta->next_community();
 Args    : None
 Returns : A Bio::Community object

=cut

method next_community () {
   my $community = (each %{$self->_communities})[1];
   return $community;
}


=head2 get_all_communities

 Function: Generate a list of all communities in the metacommunity.
 Usage   : my $communities = $meta->get_all_communities();
 Args    : None
 Returns : An arrayref of Bio::Community objects

=cut

method get_all_communities () {
   my @all_communities = values %{$self->_communities};   
   return \@all_communities;
}


=head2 get_community_by_name

 Function: Fetch a community based on its name
 Usage   : my $community = $meta->get_community_by_name('prairie');
 Args    : String of the community name to look for
 Returns : A Bio::Community object or undef if the community was not found

=cut

method get_community_by_name ( Str $name ) {
   my $community = $self->_communities->{$name};
   return $community;
}


=head2 get_communities_count

 Function: Get the total number of communities in the metacommunity
 Usage   : my $nof_communities = $meta->get_communities_count();
 Args    : None
 Returns : Integer for the count

=cut

has _communities_count => (
   is => 'ro',
   #isa => 'PositiveNum',
   lazy => 1,
   default => 0,
   init_arg => undef,
   reader => 'get_communities_count',
   writer => '_set_communities_count',
);


=head2 get_all_members

 Function: Generate a list of all members in the metacommunity.
 Usage   : my $members = $meta->get_all_members();
 Args    : None
 Returns : An arrayref of Bio::Community::Member objects

=cut

method get_all_members () {
   # Get all members in a hash
   my $all_members = {};
   while (my $community = $self->next_community) {
      while (my $member = $community->next_member('_get_all_members_ite')) {
         # Members are defined by their ID
         $all_members->{$member->id} = $member;
      }
   }
   # Convert member hash to an array
   $all_members = [values %$all_members];
   return $all_members;
}


=head2 get_members_count

 Function: Calculate the total count of members in the metacommunity.
 Usage   : my $nof_individuals = $meta->get_members_count;
 Args    : None
 Returns : Integer for the count

=cut

method get_members_count () {
   my $total_count = 0;
   my $all_members = {};
   while (my $community = $self->next_community) {
      while (my $member = $community->next_member('_get_gamma_richness_ite')) {
         $total_count += $community->get_count($member);
      }
   }
   return $total_count;
}


=head2 get_richness

 Function: Calculate the richness of the metacommunity (number of different
           types of members). This is a form of gamma diversity.
 Usage   : my $gamma_richness = $meta->get_richness();
 Args    : None
 Returns : Integer for the richness

=cut

method get_richness () {
   my $richness = scalar @{$self->get_all_members};
   return $richness;
}


__PACKAGE__->meta->make_immutable;

1;
