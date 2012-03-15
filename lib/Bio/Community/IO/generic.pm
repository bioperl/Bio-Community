# BioPerl module for Bio::Community::IO::generic
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

=head1 NAME

Bio::Community::IO::generic - Driver to read and write files containing communities
in a generic site-by-species table format

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 OBJECT METHODS

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

=cut


package Bio::Community::IO::generic;

use Moose;
use MooseX::Method::Signatures;
use namespace::autoclean;
use Bio::Community::Member;

extends 'Bio::Community::IO';
with 'Bio::Community::Role::IO',
     'Bio::Community::Role::IndexedTable';


our $default_sort_members = 0; # unsorted
our $default_abundance    = 'count';


has '_line' => (
   is => 'rw',
   isa => 'PositiveInt',
   required => 0,
   init_arg => undef,
   default => 1,
   lazy => 1,
);


has '_col' => (
   is => 'rw',
   isa => 'PositiveInt',
   required => 0,
   init_arg => undef,
   default => 1,
   lazy => 1,
);


has '_members' => (
   is => 'rw',
   isa => 'ArrayRef',
   required => 0,
   init_arg => undef,
   default => sub { [] },
   lazy => 1,
   predicate => '_has_members',
);


method _generate_members {
   # Make members from the first column
   my @members;
   my $col = 1;
   my $line = 2; # first line is a header
   while (my $value = $self->_get_indexed_value($line, $col)) {
      my $member = Bio::Community::Member->new( -desc => $value );
      push @members, $member;
      $line++;
   }
   $self->_members(\@members);
}


method _next_community {
   # Go to start of next column. Return name of new community
   $self->_col( $self->_col + 1 );
   $self->_line( 1 );
   my $name = $self->_get_indexed_value(1, $self->_col);
   return $name;
}


method next_member {
   # The first time, index the file and prepare members
   if (not $self->_has_members) {
      $self->_generate_members();
      $self->_col(2);
   }

   my ($member, $count);

   my $line = $self->_line;
   while ( $line++ ) {

      # Get the abundance of the member (undef if out-of-bounds)
      $count = $self->_get_indexed_value($line, $self->_col);

      # No more members for this community.
      last if not defined $count;

      # Skip members with no abundance / abundance of 0
      next if not $count;

      # Get the member itself
      $member = $self->_members->[$line - 2];
      last;

   }
   $self->_line($line);

   return $member, $count;
}


__PACKAGE__->meta->make_immutable;

1;
