# BioPerl module for Bio::Community
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community - A biological community

=head1 SYNOPSIS

  use Bio::Community;
  
  my $community = Bio::Community->new( -name => 'soil_1' );
  $community->add_member( $member1 );    # add 1 of this type of Bio::Community::Member
  $community->add_member( $member2, 3 ); # add 3 of this member

  print "There are ".$community->get_total_count." members in the community\n";
  print "The total diversity is ".$community->richness." species\n";

  while (my $member = $community->next_member) {
     my $member_id     = $member->id;
     my $member_count  = $community->get_count($member);
     my $member_rel_ab = $community->get_rel_ab($member);
     print "The relative abundance of member $member_id is $member_rel_ab % ($member_count counts)\n";
  }
  

=head1 DESCRIPTION

The Bio::Community module represent communities of biological organisms. It is
composed of Bio::Community::Member objects at a specified abundance. Each member
can represent a species (e.g. an elephant, a bacterium) or a proxy for a species,
such as a DNA sequence.

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

 Function: Create a new Bio::Community object
 Usage   : my $community = Bio::Community->new( ... );
 Args    : -name and -use_weights, see below...
 Returns : a new Bio::Community object

=cut


package Bio::Community;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;
use Bio::Community::Member;
use Parallel::Iterator qw( iterate );


extends 'Bio::Root::Root';


=head2 name

 Function: Get or set the name of the community
 Usage   : $community->name('ocean sample 3');
           my $name = $community->name();
 Args    : string for the name
 Returns : string for the name

=cut

has name => (
   is => 'rw',
   isa => 'Str',
   lazy => 1,
   default => 'Unnamed community',
   init_arg => '-name',
);


=head2 use_weights

 Function: Set whether or not relative abundance should be normalized by taking
           into accout the weights of the different members (e.g. genome length,
           gene copy number). Refer to the Bio::Community::Member->weights()
           method for more details. The default is to use the weights that have
           given to community members.
 Usage   : $community->use_weights(1);
 Args    : boolean
 Returns : boolean

=cut

has use_weights => (
   is => 'rw',
   isa => 'Bool',
   lazy => 1,
   default => 1,
   init_arg => '-use_weights',
);


=head2 get_total_count

 Function: Get the total number of members in the community
 Usage   : $community->get_total_count();
 Args    : none
 Returns : integer

=cut

has total_count => (
   is => 'ro',
   #isa => 'PositiveNum', # too costly for an internal method
   lazy => 1,
   default => 0,
   init_arg => undef,
   reader => 'get_total_count',
   writer => '_set_total_count',
);


has _weighted_count => (
   is => 'rw',
   #isa => 'PositiveNum', # too costly for an internal method
   lazy => 1,
   default => 0,
   init_arg => undef,
);


has _members => (
   is => 'rw',
   isa => 'HashRef',
   lazy => 1,
   default => sub{ {} },
   init_arg => undef,
);


has _counts => (
   is => 'rw',
   isa => 'HashRef',
   lazy => 1,
   default => sub{ {} },
   init_arg => undef,
);


has _ranks_hash_weighted => (
   is => 'rw',
   isa => 'HashRef',
   lazy => 1,
   default => sub{ {} },
   init_arg => undef,
   clearer => '_clear_ranks_hash_weighted',
);


has _ranks_arr_weighted => (
   is => 'rw',
   isa => 'ArrayRef',
   lazy => 1,
   default => sub{ [] },
   init_arg => undef,
   clearer => '_clear_ranks_arr_weighted',
);


has _ranks_hash_unweighted => (
   is => 'rw',
   isa => 'HashRef',
   lazy => 1,
   default => sub{ {} },
   init_arg => undef,
   clearer => '_clear_ranks_hash_unweighted',
);


has _ranks_arr_unweighted => (
   is => 'rw',
   isa => 'ArrayRef',
   lazy => 1,
   default => sub{ [] },
   init_arg => undef,
   clearer => '_clear_ranks_arr_unweighted',
);


has _richness => (
   is => 'rw',
   isa => 'Maybe[Int]',
   lazy => 1,
   default => undef,
   init_arg => undef,
   clearer => '_clear_richness',
);


has _members_iterator => (
   is => 'rw',
   isa => 'Maybe[HashRef]',
   lazy => 1,
   default => undef,
   init_arg => undef,
   clearer => '_clear_members_iterator',
);

has _has_changed => (
   is => 'rw',
   isa => 'Bool',
   lazy => 1,
   default => 0,
   init_arg => undef,
);


=head2 add_member

 Function: Add members to a community
 Usage   : $community->add_member($member, 3);
 Args    : * a Bio::Community::Member to add
           * how many of this member to add (positive number, default: 1)
 Returns : 1 on success

=cut

#method add_member ( Bio::Community::Member $member, Count $count = 1 ) {
method add_member ( $member, $count = 1 ) {
   my $member_id = $member->id;
   $self->_counts->{$member_id} += $count;
   $self->_members->{$member_id} = $member;
   $self->_set_total_count( $self->get_total_count + $count );
   $self->_weighted_count( $self->_weighted_count + $count / _prod($member->weights) );
   $self->_has_changed(1);
   return 1;
}


=head2 remove_member

 Function: remove members from a community
 Usage   : $community->remove_member($member, 3);
 Args    : * A Bio::Community::Member to remove
           * Optional: how of this member to remove. If no value is provided,
             all such members are removed.
 Returns : 1 on success

=cut

#method remove_member ( Bio::Community::Member $member, Count $count = 1 ) {
method remove_member ( $member, $count? ) {
   # Sanity checks
   my $member_id = $member->id;
   my $counts = $self->_counts;
   if (exists $counts->{$member_id}) {
      # Remove existing member
      if ( defined($count) && ($count > $counts->{$member_id}) ) {
         $self->throw("Error: More members to remove ($count) than there are in the community (".$counts->{$member}."\n");
      }
      # Now remove unwanted members
      if (not defined $count) {
         $count = $counts->{$member_id};
      }
      $counts->{$member_id} -= $count;
      if ($counts->{$member_id} == 0) {
         delete $counts->{$member_id};
         delete $self->_members->{$member_id};
      }
      $self->_set_total_count( $self->get_total_count - $count );
      $self->_weighted_count(  $self->_weighted_count - $count / _prod($member->weights) );
      $self->_has_changed(1);
   } # else no such member in the community, nothing to remove
   return 1;
}


=head2 next_member

 Function: Access the next member in a community (in no specific order). Be
           warned that each time you change the community, this iterator has to
           start again from the beginning! By default, a single iterator is
           created. However, if you need several independent iterators, simply
           provide an arbitrary iterator name.
 Usage   : # Get members through the default iterator
           my $member = $community->next_member();
           # Get members through an independent, named iterator
           my $member = $community->next_member('other_ite');           
 Args    : an optional name to give to the iterator (must not start with '_')
 Returns : a Bio::Community::Member object

=cut

method next_member ( $iter_name = 'default' ) {
   $self->_reset if $self->_has_changed;

   my $iters = $self->_members_iterator;

   # Create a named iterator
   my $iter;
   if (not exists $iters->{$iter_name}) {
      # Create new iterator
      $iter = iterate(
         { workers => 0 },
         sub { return $_[1]; }, # i.e. my ($id, $member) = @_; return $member;
         $self->_members
      );
      $iters->{$iter_name} = $iter;
   } else {
      $iter = $iters->{$iter_name};
   }

   # Get next member from iterator
   my $member = $iter->();

   # Delete iterator when done
   if (not defined $member) { 
      delete $iters->{$iter_name};
   }

   $self->_members_iterator($iters);
   return $member;
}


=head2 get_all_members

 Function: Generate a list of all members in the community. Given more communities
           as arguments, generate a list of all members in all the communities,
           including the "caller" community. Every member appears only once in
           that list, even if the member is present in multiple communities
           (remember that the only thing that defines if members are identical
           is their ID).
 Usage   : # Single community
           my @members = $community->get_all_members();
           # Several communities (community1 and community2)
           my @members = $community1->get_all_members([$community2]);
           # Or equivalently, for community1 and community2
           my @members = $community1->get_all_members([$community1, $community2]);
 Args    : an arrayref of Bio::Community objects
 Returns : an arrayref of Bio::Community::Member objects

=cut

#method get_all_members ( ArrayRef[Bio::Community] $other_communities = [] ) {
method get_all_members ( $other_communities = [] ) {

   # Prepend $self to list of communities if it is not already in there
   my $communities = $other_communities;
   my $add_self = 1;
   for my $community (@$communities) {
      if ($community == $self) {
         $add_self = 0;
         last;
      }
   }
   if ($add_self) {
      unshift @$communities, $self;
   }

   # Get all members in a hash
   my $all_members = {};
   for my $community (@$communities) {
      while (my $member = $community->next_member('_get_all_member_ite')) {
         # Members are defined by their ID
         $all_members->{$member->id} = $member; 
      }
   }

   # Convert member hash to an array
   $all_members = [values %$all_members];

   return $all_members;
}


=head2 get_member_by_id

 Function: Fetch a member based on its ID
 Usage   : my $member = $community->get_member_by_id(3);
 Args    : integer for the member ID
 Returns : a Bio::Community::Member object or undef if member was not found

=cut

method get_member_by_id (Int $member_id) {
   return $self->_members->{$member_id};
}


=head2 get_member_by_rank

 Function: Fetch a member based on its abundance rank. A smaller rank corresponds
           to a larger relative abundance.
 Usage   : my $member = $community->get_member_by_rank(1);
 Args    : strictly positive integer for the member rank
 Returns : a Bio::Community::Member object or undef if member was not found

=cut

method get_member_by_rank (AbundanceRank $rank) {
   $self->_reset if $self->_has_changed;
   if ( $self->use_weights && (scalar @{$self->_ranks_arr_weighted} == 0) ) {
      # Calculate the relative abundance ranks unless they already exist
      $self->_calc_ranks();
   }
   if ( (not $self->use_weights) && (scalar @{$self->_ranks_arr_unweighted} == 0) ) {
      # Calculate the count ranks unless they already exist
      $self->_calc_ranks();
   }
   my $member = $self->use_weights ? $self->_ranks_arr_weighted->[$rank-1] :
                                     $self->_ranks_arr_unweighted->[$rank-1];
   return $member;
}


####
# TODO: get_member_by_rel_ab
####


####
# TODO: get_member_by_count
####


=head2 get_richness

 Function: Report the community richness or number of different types of members.
 Usage   : my $richness = $community->get_richness();
 Args    : none
 Returns : integer for the richness

=cut

method get_richness {
   $self->_reset if $self->_has_changed;
   if (not defined $self->_richness) {

      # Try to calculate the richness from the abundance ranks if available
      my $num_members = scalar( @{$self->_ranks_arr_weighted}   ) ||
                        scalar( @{$self->_ranks_arr_unweighted} ) ;

      # If rank abundance are not available, calculate richness manually
      if ($num_members == 0) {
         while ($self->next_member('_get_richness_ite')) {
            $num_members++;
         }
      }

      # Save richness for later re-use
      $self->_richness($num_members);
   }
   return $self->_richness;
}


=head2 get_count

 Function: Fetch the abundance or count of a member
 Usage   : my $count = $community->get_count($member);
 Args    : a Bio::Community::Member object
 Returns : An integer for the count of this member, including zero if the member
           was not present in the community.

=cut

#method get_count (Bio::Community::Member $member) {
method get_count ($member) {
   return $self->_counts->{$member->id} || 0;
}


=head2 get_rel_ab

 Function: Determine the relative abundance (in percent) of a member in the
           community.
 Usage   : my $rel_ab = $community->get_rel_ab($member);
 Args    : a Bio::Community::Member object
 Returns : an integer between 0 and 100 for the relative abundance of this member

=cut

method get_rel_ab (Bio::Community::Member $member) {
  my $rel_ab = 0;
  my ($weight, $weighted_count);
  if ($self->use_weights) {
     $weight = _prod($member->weights);
     $weighted_count = $self->_weighted_count;
  } else {
     $weight = 1;
     $weighted_count = $self->get_total_count;
  }
  if ($weighted_count != 0) {
     $rel_ab = $self->get_count($member) * 100 / ($weight * $weighted_count);
  }
  return $rel_ab;
}


=head2 get_rank

 Function: Determine the abundance rank of a member in the community. The
           organism with the highest relative abundance has rank 1, the second-
           most abundant has rank 2, etc.
 Usage   : my $rank = $community->get_rank($member);
 Args    : a Bio::Community::Member object
 Returns : integer for the abundance rank of this member or undef if the member 
           was not found

=cut

method get_rank (Bio::Community::Member $member) {
   $self->_reset if $self->_has_changed;
   my $member_id = $member->id;
   if ( $self->get_member_by_id($member_id) ) { # If the member exists
      if ( $self->use_weights && (scalar @{$self->_ranks_arr_weighted} == 0) ) {
         # Calculate relative abundance based ranks if ranks do not already exist
         $self->_calc_ranks();
      }
      if ( (not $self->use_weights) && (scalar @{$self->_ranks_arr_unweighted} == 0) ) {
         # Calculate relative abundance based ranks if ranks do not already exist
         $self->_calc_ranks();
      }
   }
   my $rank = $self->use_weights ? $self->_ranks_hash_weighted->{$member->id} :
                                   $self->_ranks_hash_unweighted->{$member->id};
   return $rank;
}


method _calc_ranks {
   # Calculate the abundance ranks of the community members. Save them in a hash
   # and as an array.

   # 1/ Get abundance of all members and sort them
   my $members = $self->get_all_members;
   my $rel_abs = [ map { $self->get_rel_ab($_) } @$members ];

   # 2/ Save ranks in an array
   ($rel_abs, $members) = _two_array_sort($rel_abs, $members);
   my $weighted = $self->use_weights;
   if ($weighted) {
      $self->_ranks_arr_weighted( $members );
   } else {
      $self->_ranks_arr_unweighted( $members );
   }

   # 3/ Save ranks in a hash
   for my $rank (1 .. scalar @$members) {
      my $member = $members->[$rank-1];
      if ($weighted) {
         $self->_ranks_hash_weighted->{$member->id} = $rank;
      } else {
         $self->_ranks_hash_unweighted->{$member->id} = $rank;
      }
   }

   return 1;
}


method _reset {
   # Re-initialize some attributes when the community has changed
   $self->_clear_ranks_hash_weighted();
   $self->_clear_ranks_arr_weighted();
   $self->_clear_ranks_hash_unweighted();
   $self->_clear_ranks_arr_unweighted();
   $self->_clear_richness();
   $self->_clear_members_iterator();
   $self->_has_changed(0);
   return 1;
}


sub _two_array_sort {
   # Sort 2 arrays by doing an decreasing numeric sort of the first one and
   # keeping the match of the elements of the second with those of the first one
   my ($l1, $l2) = @_;
   my @ids = map { [ $$l1[$_], $$l2[$_] ] } (0..$#$l1);
   @ids = sort { $b->[0] <=> $a->[0] } @ids;
   my @k1;
   my @k2;
   for (my $i = 0; $i < scalar @ids; $i++) {
      $k1[$i] = $ids[$i][0];
      $k2[$i] = $ids[$i][1];
   }
   return \@k1, \@k2;
}


sub _prod {
   # Calculate the product of the numbers in an array
   my ($arr) = @_;
   my $prod = 1;
   $prod *= $_ for @$arr;
   return $prod;
}


__PACKAGE__->meta->make_immutable;

1;
