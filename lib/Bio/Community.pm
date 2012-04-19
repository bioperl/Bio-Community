# BioPerl module for Bio::Community
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

=head1 NAME

Bio::Community - A biological community

=head1 SYNOPSIS

  use Bio::Community;
  
  my $community = Bio::Community->new( -name => 'soil_1' );
  $community->add_member( $member1 );    # add 1 of this type of Bio::Community::Member
  $community->add_member( $member2, 3 ); # add 3 of this member

  print "There are ".$community->total_count." members in the community\n";
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

 Title   : new
 Function: Create a new Bio::Community object
 Usage   : my $community = Bio::Community->new( ... );
 Args    : -name and -use_weights, see below...
 Returns : a new Bio::Community object

=cut


package Bio::Community;

use Moose;
use MooseX::NonMoose;
use MooseX::Method::Signatures;
use namespace::autoclean;

use Bio::Community::Member;


extends 'Bio::Root::Root';


=head2 name
   
 Title   : name
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

 Title   : use_weights
 Function: Set whether or not relative abundance should be normalized by taking
           into accout the weights of the different members (e.g. genome length,
           gene copy number). Refer to the Bio::Community::Member->weights()
           method for more details
 Usage   : $community->use_weights(1);
 Args    : boolean
 Returns : boolean

=cut

has use_weights => (
   is => 'rw',
   isa => 'Bool',
   lazy => 1,
   default => 0,
   init_arg => '-use_weights',
   trigger => \&_has_changed,
);


=head2 total_count

 Title   : total_count
 Function: Get the total number of members in the community
 Usage   : $community->total_count();
 Args    : none
 Returns : integer

=cut

has total_count => (
   is => 'ro',
   isa => 'Count', 
   lazy => 1,
   default => 0,
   init_arg => undef,
   writer => '_set_total_count',
);

has _weighted_count => (
   is => 'rw',
   isa => 'Count',
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


has _ranks_hash => (
   is => 'rw',
   isa => 'HashRef',
   lazy => 1,
   default => sub{ {} },
   init_arg => undef,
   clearer => '_clear_ranks_hash',
);


has _ranks_arr => (
   is => 'rw',
   isa => 'ArrayRef',
   lazy => 1,
   default => sub{ [] },
   init_arg => undef,
   clearer => '_clear_ranks_arr',
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


=head2 add_member

 Title   : add_member
 Function: Add members to a community
 Usage   : $community->add_member($member, 3);
 Args    : * a Bio::Community::Member to add
           * how many of this member to add (default: 1)
 Returns : 1 on success

=cut

method add_member ( Bio::Community::Member $member, Count $count = 1 ) {
   my $member_id = $member->id;
   $self->_counts->{$member_id} += $count;
   $self->_members->{$member_id} = $member;
   $self->_set_total_count( $self->total_count + $count );
   $self->_weighted_count( $self->_weighted_count + $count / _prod(@{$member->weights}) );
   $self->_has_changed;
   return 1;
}


=head2 remove_member

 Title   : remove_member
 Function: remove members from a community
 Usage   : $community->remove_member($member, 3);
 Args    : * a Bio::Community::Member to remove
           * how many of this member to remove (default: 1)
 Returns : 1 on success

=cut

method remove_member ( Bio::Community::Member $member, Count $count = 1 ) {
   # Sanity checks
   my $member_id = $member->id;
   my $counts = $self->_counts;
   if (not exists $counts->{$member_id}) {
      $self->throw("Error: Could not remove member because it did not exist in the community\n");
   }
   if ($count > $counts->{$member_id}) {
      $self->throw("Error: More members to remove ($count) than there are in the community (".$counts->{$member}."\n");
   }
   # Now remove unwanted members
   $counts->{$member_id} -= $count;
   if ($counts->{$member_id} == 0) {
      delete $counts->{$member_id};
      delete $self->_members->{$member_id};
   }
   $self->_set_total_count( $self->total_count - $count );
   $self->_weighted_count( $self->_weighted_count - $count / _prod(@{$member->weights}) );
   $self->_has_changed;
   return 1;
}


=head2 next_member

 Title   : next_member
 Function: Access the next member in a community (in no specific order). Be
           warned that each time you change the community, this iterator has to
           start again from scratch!
 Usage   : my $member = $community->next_member();
 Args    : none
 Returns : a Bio::Community::Member object

=cut

method next_member {
   if (not defined $self->_members_iterator) {
      $self->_members_iterator($self->_members);
   }
   my (undef, $member) = each %{$self->_members_iterator};
   return $member;
}


=head2 all_members

 Title   : all_members
 Function: Generate a list of all members in a community.
 Usage   : my @members = $community->all_members();
 Args    : none
 Returns : an array of Bio::Community::Member objects

=cut

method all_members {
   my @members = values %{$self->_members};
   return @members;
}


=head2 get_member_by_id

 Title   : get_member_by_id
 Function: Fetch a member based on its ID
 Usage   : my $member = $community->get_member_by_id(3);
 Args    : integer for the member ID
 Returns : a Bio::Community::Member object or undef if member was not found

=cut

method get_member_by_id (Int $member_id) {
   return $self->_members->{$member_id};
}


=head2 get_member_by_rank

 Title   : get_member_by_rank
 Function: Fetch a member based on its abundance rank. A smaller rank corresponds
           to a larger relative abundance.
 Usage   : my $member = $community->get_member_by_rank(1);
 Args    : strictly positive integer for the member rank
 Returns : a Bio::Community::Member object or undef if member was not found

=cut

method get_member_by_rank (AbundanceRank $rank) {
   if ( scalar @{$self->_ranks_arr} == 0 ) {
      # Calculate the ranks unless they already exist
      $self->_calc_ranks();
   }
   return $self->_ranks_arr->[$rank-1];
}



####
# TODO: get_member_by_rel_ab
####

####
# TODO: get_member_by_count
####



=head2 get_richness
   
 Title   : get_richness
 Function: Report the community richness or number of different types of members
 Usage   : my $richness = $community->get_richness();
 Args    : none
 Returns : integer for the richness

=cut

method get_richness {
   if (not defined $self->_richness) {

      # Try to calculate the richness from the abundance ranks first
      my $num_members = scalar @{$self->_ranks_arr};
      
      # If rank abundance are not available, calculate richness manually
      if ($num_members == 0) {
         while ($self->next_member) {
            $num_members++;
         }
      }

      # Save richness for later re-use
      $self->_richness($num_members);
   }
   return $self->_richness;
}


=head2 get_count

 Title   : get_count
 Function: Fetch the abundance or count of a member
 Usage   : my $count = $community->get_count($member);
 Args    : a Bio::Community::Member object
 Returns : An integer for the count of this member, including zero if the member
           was not present in the community.

=cut

method get_count (Bio::Community::Member $member) {
   return $self->_counts->{$member->id} || 0;
}


=head2 get_rel_ab

 Title   : get_rel_ab
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
     $weight = _prod( @{$member->weights} );
     $weighted_count = $self->_weighted_count;
  } else {
     $weight = 1;
     $weighted_count = $self->total_count;
  }
  if ($weighted_count != 0) {
     $rel_ab = $self->get_count($member) * 100 / ($weight * $weighted_count);
  }
  return $rel_ab;
}


=head2 get_rank

 Title   : get_rank
 Function: Determine the abundance rank of a member in the community. The
           organism with the highest relative abundance has rank 1, the second-
           most abundant has rank 2, etc.
 Usage   : my $rank = $community->get_rank($member);
 Args    : a Bio::Community::Member object
 Returns : integer for the abundance rank of this member or undef if the member 
           was not found

=cut

method get_rank (Bio::Community::Member $member) {
   my $member_id = $member->id;
   if ( $self->get_member_by_id($member_id) && scalar @{$self->_ranks_arr} == 0 ) {
      # Calculate the ranks if the member exists and the ranks do not already exist
      $self->_calc_ranks();
   }
   return $self->_ranks_hash->{$member->id} || undef;
}


method _calc_ranks {
   # Calculate the abundance ranks of the community members. Save them in a hash
   # and as an array.

   # 1/ Get abundance of all members and sort them
   my $members = [ $self->all_members ];
   my $rel_abs = [ map { $self->get_rel_ab($_) } @$members ];

   # 2/ Save ranks in an array
   ($rel_abs, $members) = _two_array_sort($rel_abs, $members);
   $self->_ranks_arr( $members );

   # 3/ Save ranks in a hash
   for my $rank (1 .. scalar @$members) {
      my $member = $$members[$rank-1];
      $self->_ranks_hash->{$member->id} = $rank;
   }

   return 1;
}


method _has_changed {
   # Re-initialize some attributes when the community has changed
   $self->_clear_ranks_hash();
   $self->_clear_ranks_arr();
   $self->_clear_richness();
   $self->_clear_members_iterator();
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
   my (@arr) = @_;
   my $prod = 1;
   $prod *= $_ for @arr;
   return $prod;
}


__PACKAGE__->meta->make_immutable;

1;
