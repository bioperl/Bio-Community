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

=head1 DESCRIPTION

A Bio::Community is composed of Bio::Community::Member objects at a specified
abundance.

=head1 CONSTRUCTOR

=head2 Bio::Community->new()

   $member = Bio::Community::Member->new();

The new() class method constructs a new Bio::Community::Member object and
accepts the following parameters:

=head1 OBJECT METHODS

=back

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
 Args    : 
 Returns : a new Bio::Community::Individual object

=cut


package Bio::Community;

use Moose;
use MooseX::NonMoose;
use MooseX::Method::Signatures;
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
   default => 'Unnamed community',
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
   isa => 'PositiveInt',
   default => 0,
);


=head2 add_member

 Title   : add_member
 Function: Add members to a community
 Usage   : $community->add_member($member, 3);
 Args    : * a Bio::Community::Member to add
           * how many of this member to add (default: 1)
 Returns : 1 on success

=cut

method add_member ( Bio::Community::Member $member, StrictlyPositiveInt $count = 1 ) {
   my $member_id = $member->id;
   $self->{_counts}->{$member_id} += $count;
   $self->{_members}->{$member_id} = $member;
   $self->{total_count} += $count;
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

method remove_member ( Bio::Community::Member $member, StrictlyPositiveInt $count = 1 ) {
   # Sanity checks
   my $member_id = $member->id;
   my $counts = $self->{_counts};
   if (not exists $counts->{$member_id}) {
      die "Error: Could not remove member because it did not exist in the community\n";
   }
   if ($count > $counts->{$member_id}) {
      die "Error: More members to remove ($count) than there are in the community (".$counts->{$member}."\n";
   }
   # Now remove unwanted members
   $counts->{$member_id} -= $count;
   if ($counts->{$member_id} == 0) {
      delete $counts->{$member_id};
      delete $self->{_members}->{$member_id};
   }
   $self->{total_count} -= $count;
   return 1;
}


=head2 next_member

 Title   : next_member
 Function: Access the next member in a community (in no specific order).
 Usage   : my $member = $community->next_member();
 Args    : none
 Returns : a Bio::Community::Member object

=cut

method next_member {
   #### TODO: display an error if community was changed
   #### TODO: avoid doing a copy of the hash... that defeats the purpose
   my (undef, $member) = each %{$self->{_members}};
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
   my @members = values %{$self->{_members}};
   return @members;
}


=head2 richness
   
 Title   : richness
 Function: Report the community richness or number of different types of members
 Usage   : my $richness = $community->num_members();
 Args    : none
 Returns : integer for the richness

=cut

method richness {
   #### TODO: do not re-calculate this if it has already been calculated and 
   ####       the community has not changed
   my $num_members = 0;
   while ($self->next_member) {
      $num_members++;
   }
   return $num_members;
}


=head2 get_member_by_id

 Title   : get_member_by_id
 Function: Fetch a member based on its ID
 Usage   : my $member = $community->get_member_by_id(3);
 Args    : integer for the member ID
 Returns : a Bio::Community::Member or undef if member was not found

=cut

method get_member_by_id (Int $member_id) {
  return $self->{_members}->{$member_id};
}


=head2 get_rel_ab

TODO
Relative abundance of a member

=cut


no Moose;
__PACKAGE__->meta->make_immutable;
1;
