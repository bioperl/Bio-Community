# BioPerl module for Bio::Community::IO
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

=head1 NAME

Bio::Community::IO - Read and write files that describe communities

=head1 SYNOPSIS

  use Bio::Community::IO;

  my $in = Bio::Community::IO->new( -file => '', -format => 'gaas' );
  my $member1 = Bio::Community::Member->new( -id => 2 );
  my $member1_id = $member1->id;

  my $member2 = Bio::Community::Member->new( );
  my $member2_id = $member2->id;

=head1 DESCRIPTION

A Bio::Community::IO object implement methods to read and write communities in
formats used by popular programs such as GAAS, QIIME, Pyrotagger.

=head1 CONSTRUCTOR

=head2 Bio::Community::IO->new()

   my $in = Bio::Community::IO->new( );

The new() class method constructs a new Bio::Community::Member object and
accepts the following parameters:

=head1 OBJECT METHODS

=item format

The format of the file: 'gaas', 'qiime' or 'pyrotagger'.

=back

### other methods? -file? -fh?

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
 Function: Create a new Bio::Community::IO object
 Usage   : my $member = Bio::Community::IO->new( );
 Args    : 
 Returns : A Bio::Community::IO object

=cut


package Bio::Community::IO;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
use MooseX::Method::Signatures;
use Bio::Community;
use Bio::Community::Types;

extends 'Bio::Root::Root',
        'Bio::Root::IO';



# Overriding new... Is there a better alternative?
sub new {
   my $class = shift;
   my $real_class = Scalar::Util::blessed($class) || $class;

   # These all come from the same base, Moose::Object, so this is fine
   my $params = $real_class->BUILDARGS(@_);

   my $format = $params->{'-format'};
   if (not defined $format) {
      $real_class->throw("Error: No format was specified.");
   }
   
   # Use the real driver class here
   $real_class = __PACKAGE__.'::'.$format;
   Class::MOP::load_class($real_class);
   $class->throw("Module $real_class does not implement a community IO stream")
       unless $real_class->does('Bio::Community::Role::IO');

   my $self = Class::MOP::Class->initialize($real_class)->new_object($params);

   $self->BUILD($params);

   return $self;
}


sub BUILD {
   my ($self, $args) = @_;
   # Start IOs
   $self->_initialize_io(%$args);
}


=head2 next_member

 Title   : next_member
 Usage   : my ($member, $count) = $in->next_member;
 Function: Get the next member from the community and its abundance. This function
           is provided by a driver specific to each file format.
 Args    : None
 Returns : A Bio::Community::Member object, and
           a positive integer (XXX or float XXX)
             or
           undef if there were no members left

=cut

method next_member {
   $self->throw_not_implemented;
}


=head2 next_community

 Title   : next_community
 Usage   : my $community = $in->next_community;
 Function: Get the next community.
 Args    : None
 Returns : A Bio::Community object
             or
           undef if there were no communities left

=cut

method next_community {
   # Initialize things for the next community and give the community a name
   #my $name = $self->_next_community;

   ### TODO: return undef here if all community have been processed

   # Create and populate a new community
   my $community = Bio::Community->new( );
   while ( my ($member, $count) = $self->next_member ) {
      last if not defined $member;
      $community->add_member($member, $count);
   }
   return $community->get_richness > 0 ? $community : undef;;
}


=head2 write_member

 Title   : write_member
 Usage   : $in->write_member($member, $abundance);
 Function: Write the next member from the community and its count or relative
           abundance. This function is provided by a driver specific to each file
           format.
 Args    : A Bio::Community::Member object
           A positive integer (XXX or float XXX)
 Returns : None

=cut

method write_member (Bio::Community::Member $member, Count $count) {
   $self->throw_not_implemented;
}


=head2 write_community

 Title   : write_community
 Usage   : $in->write_community($community);
 Function: Write the next community.
 Args    : A Bio::Community object
 Returns : None

=cut

method write_community (Bio::Community $community) {
   my $sort_members = $self->sort_members;
   if ($sort_members == 1) {
      my $rank = $community->get_richness;
      while ( my $member = $community->get_member_by_rank($rank) ) {
         $self->_process_member($member, $community);
         $rank--;
         last if $rank == 0;
      }
   } elsif ($sort_members == -1) {
      my $rank = 1;
      while ( my $member = $community->get_member_by_rank($rank) ) {
         $self->_process_member($member, $community);
         $rank++;
      }
   } elsif ($sort_members == 0) {
      ### TODO: should be able to use next_member() but there is a bug
      #while (my $member = $community->next_member) {
      for my $member ($community->all_members) {
         $self->_process_member($member, $community);
      }
   } else {
      $self->throw("Error: $sort_members is not a valid sort value.\n");
   }
   return 1;
}


method _process_member (Bio::Community::Member $member, Bio::Community $community) {
   my $ab_value;
   my $ab_type = $self->abundance_type;
   if ($ab_type eq 'count') {
      $ab_value = $community->get_count($member);
   } elsif ($ab_type eq 'percentage') {
      $ab_value = $community->get_rel_ab($member);
   } elsif ($ab_type eq 'fraction') {
      $ab_value = $community->get_rel_ab($member) / 100;
   } else {
      $self->throw("Error: $ab_value is not a valid abundance type.\n");
   }
   $self->write_member($member, $ab_value);
}


=head2 sort_members

 Title   : sort_members
 Usage   : $in->sort_members();
 Function: When writing a community to a file, sort the community members based
           on their abundance: 0 (off), 1 (by increasing abundance), -1 (by 
           decreasing abundance). The default is specific to each driver used.
 Args    : 0, 1 or -1
 Returns : 0, 1 or -1

=cut

has 'sort_members' => (
   is => 'ro',
   isa => 'NumericSort',
   required => 0,
   lazy => 1,
   init_arg => '-sort_members',
   default => sub { return eval('$'.ref(shift).'::default_sort_members') || 0  },
);


=head2 abundance_type

 Title   : abundance_type
 Usage   : $in->abundance_type();
 Function: When writing a community to a file, sort the community members based
           on their abundance: 0 (off), 1 (by increasing abundance), -1 (by 
           decreasing abundance). The default is specific to each driver used.
 Args    : count, percentage or fraction
 Returns : count, percentage or fraction

=cut

has 'abundance_type' => (
   is => 'ro',
   isa => 'AbundanceType',
   required => 0,
   lazy => 1,
   init_arg => '-abundance_type',
   default => sub { return eval('$'.ref(shift).'::default_abundance_type') || 'percentage' },
);



# Do not inline so that new() can be overridden
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
