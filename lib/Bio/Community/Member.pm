# BioPerl module for Bio::Community::Member
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Member - The basic constituent of a biological community

=head1 SYNOPSIS

  use Bio::Community::Member;

  my $member1 = Bio::Community::Member->new( -id => 2 );
  my $member1_id = $member1->id;

  my $member2 = Bio::Community::Member->new( );
  my $member2_id = $member2->id;

=head1 DESCRIPTION

A Bio::Community::Member represents an organism, individual, species, amplicon
sequence, shotgun sequence or anything you like.

=head1 CONSTRUCTOR

=head2 Bio::Community::Member->new()

   my $member = Bio::Community::Member->new();

The new() class method constructs a new Bio::Community::Member object and
accepts the following parameters:

=head1 OBJECT METHODS

=item id

The identifier for this community member. An ID is necessary and sufficient to
identify a community member, but additional information can be attached to a
member.

  my $obj1 = Bio::Community::Member->new( -id => 153 );
  my $obj2 = $obj1;
  my $obj3 = Bio::Community::Member->new( -id => 153 );
  my $obj4 = Bio::Community::Member->new( -id => 6123 );
  my $obj5 = Bio::Community::Member->new( ); # automatically assigned ID

In the above example, $obj1, $obj2 and $obj3 represent the same member, while
$obj4 represents a different member, and $obj5 yet another member.

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

 Function: Create a new Bio::Community::Member object
 Usage   : my $member = Bio::Community::Member->new( );
 Args    : -id, -desc, -taxon, -seqs, -weights
 Returns : a new Bio::Community::Member object

=cut


package Bio::Community::Member;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use namespace::autoclean;
use Method::Signatures;
use Bio::Community::Types;

extends 'Bio::Root::Root';

with 'Bio::Community::Role::Described' , # -desc
     'Bio::Community::Role::Classified', # -taxon
     'Bio::Community::Role::Sequenced' , # -seqs
     'Bio::Community::Role::Weighted'  ; # -weights

my $last_num = 1;
my $prefix = 'bc';
# First ID is 'bc1'


=head2 id

 Function: my $description = $member->id();
 Usage   : Get or set the ID for the member. If an ID is not provided, a unique
           ID prefixed with 'bc' is generated, e.g. 'bc1', 'bc2', etc. This
           makes it easy to distinguish IDs assigned by Bio::Community::Member
           from IDs obtained from other sources, e.g. read from a QIIME file.
           Use of the 'bc' prefix is restricted to the Bio::Community::Member
           module; refrain from using it yourself.
 Args    : A string
 Returns : A string

=cut

has id => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   init_arg => '-id',
   lazy => 0,
   predicate => '_has_id',
   #trigger => \&_register_id,
);


# Don't register IDs anymore since we use a prefix that users should not use.
#my %ids = ();
#func _register_id ($self, $id, $old_id?) {
#   # Register ID after it has been assigned
#   $ids{$self->{id}} = undef;
#};


method BUILD ($args) {
   # Ensure that a default ID is assigned if needed after object construction
   if (not $self->_has_id) {
      $self->id($prefix.$last_num);
      $last_num++;      
   }
}


=head2 desc

 Usage   : my $description = $member->desc();
 Function: Get or set a description for this object.
           See Bio::Community::Role::Described.
 Args    : A string
 Returns : A string

=head2 taxon

 Usage   : my $taxon = $member->taxon();
 Function: Get or set a taxon (or species) for this object.
           See Bio::Community::Role::Classified.
 Args    : A Bio::Taxon object
 Returns : A Bio::Taxon object

=head2 seqs

 Usage   : my $seqs = $member->seqs();
 Function: Get or set some sequences for this object.
           See Bio::Community::Role::Sequenced.
 Args    : An arrayref of Bio::SeqI objects
 Returns : An arrayref of Bio::SeqI objects

=head2 weights

 Usage   : my $weights = $member->weights();
 Function: Get or set some weights for this object. Weights represent how biased
           the sampling of this organism is. For example, when random shotgun
           sequencing microorganisms in the environment, the relative abundance
           of reads in the sequence library is not proportional to the relative
           abundance of the genomes because larger genomes contribute
           disproportionalely more reads than small genomes. In such a case, you
           could set the weight to the length of the genome. See
           Bio::Community::Role::Weighted. Also see get_count() and get_rel_ab()
           in Bio::Community.
 Args    : An arrayref of positive integers
 Returns : An arrayref of positive integers

=cut


####
# TODO:
# For on the fly attributes: http://stackoverflow.com/questions/3996067/how-can-i-flexibly-add-data-to-moose-objects
# For flexible attributes: https://github.com/cjfields/biome/blob/master/lib/Biome/Role/Identifiable.pm
####


__PACKAGE__->meta->make_immutable;

1;
