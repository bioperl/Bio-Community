# BioPerl module for Bio::Community::IO::generic
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::IO::generic - Driver to read and write files in a generic tab-delimited site-by-species table format

=head1 SYNOPSIS

   my $in = Bio::Community::IO->new( -file => 'gaas_compo.txt', -format => 'generic' );

   # See Bio::Community::IO for more information

=head1 DESCRIPTION

This Bio::Community::IO driver reads and writes files in a generic format. Multiple
communities can be written in a file to generate a site-by-species table (OTU
table), in which the entries are tab-delimited. Example:

  	site A	site B
  species 1	321	94
  species 2	0	58
  species 3	47	26

=head1 CONSTRUCTOR

See L<Bio::Community::IO>.

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
     'Bio::Community::Role::Table';


our $multiple_communities   =  1;      # format supports several communities per file
#### sorting only effective for first community???
our $default_sort_members   =  0;      # unsorted
our $default_abundance_type = 'count'; # absolute count (positive integer)
our $default_missing_string =  0;      # empty members get a '0'


has '_first_community' => (
   is => 'rw',
   isa => 'Bool',
   required => 0,
   init_arg => undef,
   default => 1,
   lazy => 1,
);


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
   isa => 'ArrayRef[Bio::Community::Member]',
   required => 0,
   init_arg => undef,
   default => sub { [] },
   lazy => 1,
   predicate => '_has_members',
);


has '_id2line' => (
   is => 'rw',
   isa => 'HashRef[String]',
   required => 0,
   init_arg => undef,
   default => sub { {} },
   lazy => 1,
);


method _generate_members {
   # Make members from the first column
   my @members;
   my $col = 1;
   for my $line (2 .. $self->_get_max_line) {
      my $value = $self->_get_value($line, $col);
      my $member = Bio::Community::Member->new( -desc => $value );
      push @members, $member;
   }
   $self->_members(\@members);
}


method next_member {
   my ($member, $count);
   my $line = $self->_line;
   while ( $line++ ) {
      # Get the abundance of the member (undef if out-of-bounds)
      $count = $self->_get_value($line, $self->_col);
      # No more members for this community.
      last if not defined $count;
      # Skip members with no abundance / abundance of 0
      next if not $count;
      next if $count == 0;
      # Get the member itself
      $member = $self->_members->[$line - 2];
      last;
   }
   $self->_line($line);
   $self->_attach_weights($member);
   return $member, $count;
}


method _next_community_init {
   # Go to start of next column and return name of new community. The first time,
   # generate all community members.
   if (not $self->_has_members) {
      $self->_generate_members();
   }
   my $col  = $self->_col + 1;
   my $line = 1;
   my $name = $self->_get_value($line, $col);
   $self->_col( $col );
   $self->_line( $line );
   return $name;
}


method _next_community_finish {
   return 1;
}


method write_member (Bio::Community::Member $member, Count $count) {
    my $id   = $member->id;
    my $line = $self->_id2line->{$id};
    if (not defined $line) {
        # This member has not been written previously for another community
        $line = $self->_get_max_line + 1;
        $self->_set_value( $line, 1, $member->desc );
        $self->_id2line->{$id} = $line;
    }
    $self->_set_value($line, $self->_col, $count);
    $self->_line( $line + 1 );
    return 1;
}


method _write_community_init (Bio::Community $community) {
   # If first community, write first column header
   if ($self->_first_community) {
      $self->_write_headers;
      $self->_first_community(0);
   }
   # Write header for that community
   my $line = 1;
   my $col  = $self->_col + 1;
   $self->_set_value($line, $col, $community->name);
   $self->_line( $line + 1);
   $self->_col( $col );
   return 1;
}


method _write_headers {
   $self->_set_value(1, 1, 'Species');
}


method _write_community_finish (Bio::Community $community) {
   return 1;
}



__PACKAGE__->meta->make_immutable;

1;
