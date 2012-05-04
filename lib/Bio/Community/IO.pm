# BioPerl module for Bio::Community::IO
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


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
formats used by popular programs such as GAAS and QIIME, or as generic tab-
separated tables.

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

 Function: Create a new Bio::Community::IO object
 Usage   : # Reading a file
           my $member = Bio::Community::IO->new( -file => 'community.txt' );
           # Writing a file
           my $member = Bio::Community::IO->new( -file => '>community.txt', format => 'generic' );
 Args    : -file   :  Path of a community file
           -format :  Format of the file: 'generic', 'gaas', 'qiime'. This is
                      optional when reading a community file because the format
                      is automatically detected.
           -weights:  Arrayref of files that contains weights to assign to members.
           -taxonomy: Given a Bio::DB::Taxonomy object, try to place the community
                      members in this taxonomy.
           See Bio::Root::IO for other accepted constructors, like -fh.
 Returns : A Bio::Community::IO object

=cut


package Bio::Community::IO;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
use Method::Signatures;
use Bio::Community;
use Bio::Community::Types;
use Bio::Community::Tools::FormatGuesser;

extends 'Bio::Root::Root',
        'Bio::Root::IO';



# Overriding new... Is there a better alternative?
sub new {
   my $class = shift;
   my $real_class = Scalar::Util::blessed($class) || $class;

   # These all come from the same base, Moose::Object, so this is fine
   my $params = $real_class->BUILDARGS(@_);
   my $format = delete $params->{'-format'};
   if (not defined $format) {
      # Try to guess format
      my $guesser = Bio::Community::Tools::FormatGuesser->new();
      if ($params->{'-file'}) {
         $guesser->file( $params->{'-file'} );
      } elsif ($params->{'-fh'}) {
         $guesser->fh( $params->{'-fh'} );
      }
      $format = $guesser->guess;
   }
   if (not defined $format) {
      $real_class->throw("Error: Could not automatically detect input format.");
   }

   # Use the real driver class here
   $real_class = __PACKAGE__.'::'.$format;
   Class::MOP::load_class($real_class);
   $class->throw("Module $real_class does not implement a community IO stream")
       unless $real_class->does('Bio::Community::Role::IO');

   $params = $real_class->BUILDARGS(%$params);

   my $self = Class::MOP::Class->initialize($real_class)->new_object($params);

   return $self;
}


sub BUILD {
   my ($self, $args) = @_;
   # Start IOs
   $self->_initialize_io(%$args);
}


=head2 next_member

 Usage   : my ($member, $count) = $in->next_member;
 Function: Get the next member from the community and its abundance. This function
           relies on the _next_member method provided by a driver specific to
           fille format requested.
 Args    : None
 Returns : An array containing:
             A Bio::Community::Member object (or undef)
             A positive number (or undef)

=cut

method next_member {
   $self->throw_not_implemented;
}


=head2 next_community

 Usage   : my $community = $in->next_community;
 Function: Get the next community. Note that communities without members are
           skipped.
 Args    : None
 Returns : A Bio::Community object
             or
           undef if there were no communities left

=cut

method next_community {
   my $community;
   while ( 1 ) { # Skip communities with no members

      # Initialize driver for next community and set community name
      my $name = $self->_next_community_init;

      # All communities have been read
      last if not defined $name;

      # Create a new community object
      $community = Bio::Community->new( -name => $name );
      # Populate the community with members
      while ( my ($member, $count) = $self->next_member() ) {
         last if not defined $member; # All members have been read
         $community->add_member($member, $count);
      }
      $self->_next_community_finish;

      if ($community->get_richness > 0) {
         last;
      } else {
         $community = undef;
      }

   }

   # Community is undef if all communities have been seen
   return $community;
}


method _next_community_init {
   # Driver-side method to initialize new community and return its name
   $self->throw_not_implemented;
}


method _next_community_finish {
   # Driver-side method to finalize a community
   $self->throw_not_implemented;
}


=head2 write_member

 Usage   : $in->write_member($member, $abundance);
 Function: Write the next member from the community and its count or relative
           abundance. This function is provided by a driver specific to each file
           format.
 Args    : A Bio::Community::Member object
           A positive number
 Returns : None

=cut

method write_member (Bio::Community::Member $member, Count $count) {
   $self->throw_not_implemented;
}


=head2 write_community

 Usage   : $in->write_community($community);
 Function: Write the next community.
 Args    : A Bio::Community object
 Returns : None

=cut

method write_community (Bio::Community $community) {
   $self->_write_community_init($community);
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
      while ( my $member = $community->next_member('_write_community_ite') ) {
         $self->_process_member($member, $community);
      }
   } else {
      $self->throw("Error: $sort_members is not a valid sort value.\n");
   }
   $self->_write_community_finish($community);
   return 1;
}


method _write_community_init (Bio::Community $community) {
   # Driver-side method to initialize writing a community
   $self->throw_not_implemented;
}


method _write_community_finish (Bio::Community $community) {
   # Driver-side method to finalize writing a community
   $self->throw_not_implemented;
}


#method _process_member (Bio::Community::Member $member, Bio::Community $community) {
method _process_member ($member, $community) {
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

 Usage   : $in->abundance_type();
 Function: When writing a community to a file, report the abundance as one of
           three possible representations: a raw count, a percentage (0-100%) or
           a fractional number (0-1). The default is specific to each driver
           used.
 Args    : count, percentage or fraction
 Returns : count, percentage or fraction

=cut

has 'abundance_type' => (
   is => 'ro',
   isa => 'AbundanceRepr',
   required => 0,
   lazy => 1,
   init_arg => '-abundance_type',
   default => sub { return eval('$'.ref(shift).'::default_abundance_type') || 'percentage' },
);


=head2 missing_string

 Usage   : $in->missing_string();
 Function: When writing a community to a file, specify what abundance string to
           use for members that are not present in the community. The default is
           specific to each driver used.
 Args    : string e.g. '', '0', 'n/a', '-'
 Returns : string

=cut

has 'missing_string' => (
   is => 'ro',
   isa => 'Str',
   required => 0,
   lazy => 1,
   init_arg => '-missing_string',
   default => sub { return eval('$'.ref(shift).'::default_missing_string') || 0 },
);


=head2 multiple_communities

 Usage   : $in->multiple_communities();
 Function: Return whether or not the file format can represent multiple
           communities in a single file           
 Args    : 0 or 1
 Returns : 0 or 1

=cut

has 'multiple_communities' => (
   is => 'ro',
   isa => 'Bool',
   required => 0,
   lazy => 1,
   default => sub { return eval('$'.ref(shift).'::multiple_communities') || 0 },
);


=head2 weight_files

 Usage   : $in->weight_files();
 Function: When reading a community, specify files containing weights to assign
           to the community members. Each type of file can contain a different
           type of weight to add. The file should contain two tab-delimited
           columns: the first one should contain the description of the member,
           and the second one the weight to assign to this member.
 Args    : arrayref of file names
 Returns : arrayref of file names

=cut

has 'weight_files' => (
   is => 'rw',
   isa => 'ArrayRef', # ArrayRef[Str] but keep it light
   required => 0,
   lazy => 1,
   default => sub { [] },
   init_arg => '-weight_files',
   trigger => \&_read_weights,
);


has '_weights' => (
   is => 'rw',
   isa => 'ArrayRef', # ArrayRef[HashRef[Num]], but keep it light
   required => 0,
   lazy => 1,
   default => sub { [] },
   predicate => '_has_weights',
);


has '_average_weights' => (
   is => 'rw',
   isa => 'ArrayRef', # ArrayRef[Num] but keep it light
   required => 0,
   lazy => 1,
   default => sub { [] },
   predicate => '_has_average_weights',
);


method _read_weights ($args) {
   my $files = $self->weight_files;
   my $all_weights = [];
   my $average_weights = [];
   for my $file (@$files) {
      my $average = 0;
      my $num = 0;
      my $file_weights = {};
      open my $in, '<', $file or $self->throw("Could not open file '$file': $!");
      while (my $line = <$in>) {
         next if $line =~ m/^#/;
         next if $line =~ m/^\s*$/;
         chomp $line;
         my ($id, $weight) = (split '\t', $line)[0..1];
         $file_weights->{$id} = $weight;
         $average += $weight;
         $num++;
      }
      close $in;
      push @$all_weights, $file_weights;
      $average /= $num if $num > 0;
      push @$average_weights, $average;
   }
   $self->_weights( $all_weights );
   $self->_average_weights( $average_weights );
   return 1;
}


=head2 weight_assign

 Usage   : $in->weight_assign();
 Function: When using weights, specify what value to assign to the members for
           which no weight is specified in the provided weight file:
            * $num      : the weight provided as argument
            * 'average' : the average weight in the weight file
 Args    : 'average' or a number
 Returns : 'average' or a number

=cut

has 'weight_assign' => (
   is => 'rw',
   isa => 'WeightAssignType',
   required => 0,
   lazy => 1,
   default => 'average',
   init_arg => '-weight_assign',
);


=head2 _attach_weights

 Usage   : $in->_attach_weights($member);
 Function: Once a member has been created, a driver should call this method
           to attach the proper weights (read from the user-provided weight
           files) to a member. If no member is provided, this method will not
           complain and will do nothing.
 Args    : a Bio::Community::Member or nothing
 Returns : 1 for success

=cut

method _attach_weights (Maybe[Bio::Community::Member] $member) {
   # Once we have a member, attach weights to it
   if ( defined($member) && $self->_has_weights ) {
      my $weights;
      for my $i (0 .. scalar @{$self->_weights} - 1) {
         my $weight;
         my $weight_type = $self->_weights->[$i];
         my $desc = $member->desc;
         if ($desc && exists($weight_type->{$desc}) ) {
            # This member has a weight
            $weight = $weight_type->{$desc};
         } else {
            # This member has no weight, provide an alternative weight
            my $assign = $self->weight_assign; 
            if ($assign eq 'average') {
               # Use the average weight in the weight file
               $weight = $self->_average_weights->[$i];
            } else {
               # Use an arbitrary weight
               $weight = $assign;
            }
         }
         push @$weights, $weight;
      }
      $member->weights($weights);
   }
   return 1;
}


=head2 taxonomy

 Usage   : $in->taxonomy();
 Function: When reading communities, try to place the community members on the
           provided taxonomy (provided taxonomic assignments are specified in
           the input. Make sure that you use the same taxonomy as in the
           community to ensure that members can be placed. A warning is
           issued for every member that fails to be placed.
 Args    : Bio::DB::Taxonomy
 Returns : Bio::DB::Taxonomy

=cut

has 'taxonomy' => (
   is => 'rw',
   isa => 'Maybe[Bio::DB::Taxonomy]',
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-taxonomy',
);


# Do not inline so that new() can be overridden
__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
