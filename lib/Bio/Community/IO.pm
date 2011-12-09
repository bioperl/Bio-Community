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

=head2 Bio::Community::Member->new()

   my $in = Bio::Community::Member::IO->new( );

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


has 'format' => (
   is => 'ro',
   isa => 'Str',
   required => 1,
   init_arg => '-format',
);


sub BUILD {
   my ($self, $args) = @_;

   # Apply the role corresponding to the format that is requested
   my $role = __PACKAGE__."::".$self->format;
   eval "require $role";
   if ($@) {
      my $msg = "$role cannot be found or contains errors\n".
                "Exception: $@\n".
                "For more information about the IO system please see the ".
                __PACKAGE__." docs.\n";
      $self->throw($msg);
   }
   $role->meta->apply( $self );

   # Start IOs
   my @args = %$args;
   $self->_initialize_io(@args);
}


=head2 next_member

 Title   : next_member
 Usage   : my ($member, $count) = $in->next_member;
 Function: Get the next member from the community and its abundance. This function
           is provided by a driver specific to each file format.
 Args    : None
 Returns : A Bio::Community::Member object
           A positive integer (XXX or float XXX)

=cut

method next_member {
   $self->throw_not_implemented;
}


=head2 next_community

 Title   : next_community
 Usage   : my $community = $in->next_community;
 Function: Get the next community.
 Args    : None
 Returns : A Bio::Community::Member object
           A positive integer (XXX or float XXX)

=cut

method next_community {
   my $community = Bio::Community->new();
   while ( my ($member, $count) = $self->next_member ) {
      $community->add_member($member, $count);
   }
   return $community;
}


=head2 write_member

 Title   : write_member
 Usage   : $in->write_member($member, $count);
 Function: Write the next member from the community and its abundance. This function
           is provided by a driver specific to each file format.
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
   $self->throw_not_implemented;
}


__PACKAGE__->meta->make_immutable;

1;
