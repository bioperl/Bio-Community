# BioPerl module for Bio::Community::Member
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

=head1 NAME

Bio::Community::Member - The basic constituent of a biological community, i.e. an organism

=head1 SYNOPSIS

  use Bio::Member;

  my $member1 = Bio::Community::Member->new({ id => 2 });
  my $member1_id = $member1->id;

  my $member2 = Bio::Community::Member->new( );
  my $member2_id = $member2->id;

=head1 DESCRIPTION



=head1 CONSTRUCTOR

=head2 Bio::Community::Member->new()

   $member = Bio::Community::Member->new();

The new() class method constructs a new Bio::Community::Member object and
accepts the following parameters:

=head1 OBJECT METHODS

=item id

The identifier for this community member. An ID is necessary and sufficient to
identify a community member. But additional information can be attached to a
member.

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

=cut


package Bio::Community::Member;

use Moose;
use MooseX::NonMoose;

extends 'Bio::Root::Root';

my %ids = ();
my $last_id = 1;

has id => (
   is => 'ro',
   isa => 'Int',
   required => 0,
   default => sub {
         while (exists $ids{$last_id}) { $last_id++; };
         return $last_id;
      },
);

after id => sub {
   # Register ID after its assignment
   my $self = shift;
   $ids{$self->{id}} = undef;
};


####
# has desc
# has seq
# has taxon
# has weights
####


no Moose;
__PACKAGE__->meta->make_immutable;
1;
