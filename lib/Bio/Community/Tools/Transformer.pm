# BioPerl module for Bio::Community::Tools::Transformer
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::Transformer - Arbitrary transformation of member counts

=head1 SYNOPSIS

  use Bio::Community::Tools::Transformer;

  # Hellinger-transform the counts of community members in a metacommunity
  my $transformer = Bio::Community::Tools::Transformer->new(
     -metacommunity => $meta,
     -type          => 'hellinger',
  );

  my $transformed_meta = $summarizer->get_transformed_meta;

=head1 DESCRIPTION

This module takes a metacommunity and transform the count of the community
members it contains. Several transformation methods are available: identity,
binary, hellinger, total.

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

 Function: Create a new Bio::Community::Tool::Transformer object
 Usage   : my $transformer = Bio::Community::Tool::Transformer->new( );
 Args    : -metacommunity: see metacommunity()
           -type         : see type()
 Returns : a new Bio::Community::Tools::Transformer object

=cut


package Bio::Community::Tools::Transformer;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;
use Bio::Community::Meta;
use Scalar::Util;


extends 'Bio::Root::Root';


=head2 metacommunity

 Function: Get or set the metacommunity to normalize.
 Usage   : my $meta = $transformer->metacommunity;
 Args    : A Bio::Community::Meta object
 Returns : A Bio::Community::Meta object

=cut

has metacommunity => (
   is => 'rw',
   isa => 'Bio::Community::Meta',
   required => 0,
   default => undef,
   lazy => 1,
   init_arg => '-metacommunity',
);


=head2 type

 Function: Get or set the type of transformation.
 Usage   : my $type = $transformer->type;
 Args    : String:
              * identity  : keep the counts as-is
              * binary    : 1 for presence, 0 for absence
              * hellinger : Hellinger transformation (square root)
              * total     : scale the counts of each community to the given
                            total. See total_file().
 Returns : identity, binary, hellinger, or total

=cut

has type => (
   is => 'rw',
   isa => 'TransformationType',
   required => 0,
   default => 'identity',
   lazy => 1,
   init_arg => '-type',
);


=head2 total_abundance

 Function: Get or set the total counts
 Usage   : my $file = $transformer->total_abundance;
 Args    : Hashref giving the the total abundance (values) for each community (keys).
 Returns : Total counts hashref

=cut

has total_abundance => (
   is => 'rw',
   isa => 'Maybe[HashRef]',
   required => 0,
   default => undef,
   lazy => 1,
   init_arg => '-total_abundance',
);


=head2 get_transformed_meta

 Function: Calculate and return a transformed metacommunity.
 Usage   : my $meta = $transformer->get_transformed_meta;
 Args    : none
 Returns : a new Bio::Community::Meta object

=cut

has transformed_meta => (
   is => 'rw',
   isa => 'Bio::Community::Meta',
   required => 0,
   default => sub { undef },
   lazy => 1,
   reader => 'get_transformed_meta',
   writer => '_set_transformed_meta',
   predicate => '_has_transformed_meta',
);

before get_transformed_meta => sub {
   my ($self) = @_;
   $self->_transform if not $self->_has_transformed_meta;
   return 1;
};


method _transform () {
   # Sanity check
   my $meta = $self->metacommunity;
   if ($meta->get_communities_count == 0) {
      $self->throw('Metacommunity should contain at least one community');
   }

   # Register transformation functions
   my $sub;
   my $type = $self->type;
   my $want_totals;
   if ($type eq 'identity') {
      $sub = sub {
         return shift();
      };
   } elsif ($type eq 'binary') {
      $sub = sub {
         return shift() > 0 ? 1 : 0;
      };
   } elsif ($type eq 'hellinger') {
      $sub = sub {
         return sqrt(shift());
      };
   } elsif ($type eq 'total') {
      $want_totals = $self->total_abundance;
      while (my $community = $meta->next_community) {
         my $name = $community->name;
         if (not exists $want_totals->{$name}) {
            $self->throw("No total abundance given for community '$name'");
         }
      }
      $sub = sub {
         my ($count, $scaling) = @_;
         return $count * $scaling;
      };
   } else {
      $self->throw("Unsupported transformation type '$type'");
   }

   # Transform now
   my $transformed_meta = Bio::Community::Meta->new( -name => $meta->name );
   while (my $community = $meta->next_community) {
      my $name = $community->name;
      my $transformed = Bio::Community->new(
         -name        => $name,
         -use_weights => $community->use_weights,
      );
      my $scaling;
      if ($type eq 'total') {
         my $count = $community->get_members_count;
         if ($count) {
            $scaling = $want_totals->{$name} / $count;
         }
      }
      while ( my $member = $community->next_member('_transform') ) {
         my $count = $community->get_count($member);
         my $transf_count = $sub->($count, $scaling);
         $transformed->add_member($member, $transf_count);
      }
      $transformed_meta->add_communities([$transformed]);
   }
   $self->_set_transformed_meta($transformed_meta);

   return 1;
}


__PACKAGE__->meta->make_immutable;

1;
