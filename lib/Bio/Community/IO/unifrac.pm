# BioPerl module for Bio::Community::IO::unifrac
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::IO::unifrac - Driver to read and write files in the (Fast)Unifrac format

=head1 SYNOPSIS

   my $in = Bio::Community::IO->new( -file => 'commmunities.txt', -format => 'unifrac' );

   # See Bio::Community::IO for more information

=head1 DESCRIPTION

This Bio::Community::IO driver reads and writes Unifrac environment files and
FastUnifrac sample ID mapping files, whose format is described at
L<http://bmf2.colorado.edu/unifrac/help.psp#env_file> and
L<http://bmf2.colorado.edu/fastunifrac/help.psp#sample_id_mapping_file>. In this
tab-delimited format, the first column is a sequence ID, the second is the name
of a community, and the optional third column contains the number of
observations of this sequence in the community. Multiple communities can be
written in a Unifrac formatted-file and spaces are not supported in community
name or member description. Example:

  Sequence.1	Sample.1	1
  Sequence.1	Sample.2	2
  Sequence.2	Sample.1	15
  Sequence.3	Sample.1	2
  Sequence.4	Sample.2	8
  Sequence.5	Sample.1	4
  Sequence.6	Sample.3	1
  Sequence.6	Sample.2	1

For each Bio::Community::Member $member generated from a Unifrac file,
$member->desc() contains the content of the first field, i.e. the first column.
Since the Unifrac format does not specify a member ID, one is automatically
generated and can be retrieved using $member->id().

Note that member counts (the third column) is optional. Example:

  Sequence.1	Sample.1
  Sequence.1	Sample.2
  Sequence.2	Sample.1
  Sequence.3	Sample.1
  Sequence.4	Sample.2
  Sequence.5	Sample.1
  Sequence.6	Sample.3
  Sequence.6	Sample.2

In this case the data is to be interpreted as presence/absence data. When
reading a Unifrac file without counts, all members are given a count of 1.
Conversely, when writing a Unifrac file, if all members have a count of 1, then
the third column is not written. Also, when writing Unifrac files, any spaces in
community member name or member description is replaced by a dot.

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


package Bio::Community::IO::unifrac;

use Moose;
use Method::Signatures;
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
   default => 0,
   lazy => 1,
);


has '_col' => (
   is => 'rw',
   isa => 'PositiveInt',
   required => 0,
   init_arg => undef,
   default => 2,
   lazy => 1,
);


has '_members' => (
   is => 'rw',
   isa => 'HashRef', # HashRef[Bio::Community::Member] but keep it lean
   required => 0,
   init_arg => undef,
   default => sub { {} },
   lazy => 1,
   predicate => '_has_members',
);


has '_current_name' => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   init_arg => undef,
   default => undef,
   lazy => 1,
);


has '_community_names' => (
   is => 'rw',
   isa => 'ArrayRef', # Arrayref[Str] but keep it lean
   required => 0,
   init_arg => undef,
   default => sub { [] },
   lazy => 1,
   predicate => '_has_community_names',
);


has '_desc2line' => (
   is => 'rw',
   isa => 'HashRef', # HashRef[String] but keep it lean
   required => 0,
   init_arg => undef,
   default => sub { {} },
   lazy => 1,
);


has '_qualitative_unifrac' => (
   is => 'rw',
   isa => 'Bool',
   required => 0,
   init_arg => undef,
   default => 1,
   lazy => 1,
);


method _generate_community_names {
   # Read all possible community names from the second column
   my %names;
   my $col = 2;
   for my $line (1 .. $self->_get_max_line) {
      my $name = $self->_get_value($line, $col);
      next if exists $names{$name};
      $names{$name} = undef;
   }
   my @names = keys %names;
   $self->_community_names(\@names);
   return 1;
}


method _generate_members {
   # Make members from the first column
   my %members;
   my $col = 1;
   for my $line (1 .. $self->_get_max_line) {
      my $desc = $self->_get_value($line, $col);
      my $member = Bio::Community::Member->new( -desc => $desc );
      # Skip if member with same desc was already generated
      next if exists $members{$desc};
      $self->_attach_taxon($member, $desc, 1);
      $self->_attach_weights($member);
      $members{$desc} = $member;
   }
   $self->_members(\%members);
   return 1;
}


method next_member {
   my ($member, $count);
   my $line = $self->_line;

   while ( 1 ) {
      $line++;

      # Get the community that this member belongs to (undef if out-of-bounds)
      my $name = $self->_get_value($line, $self->_col);

      # No more members for this community.
      last if not defined $name;

      # Skip members if it does not belong to wanted community
      next unless $name eq $self->_current_name;

      # Fetch member count
      if ($self->_get_max_col == 3) {
         # Quantitative data
         $count = $self->_get_value($line, $self->_col + 1);
      } else {
         # Presence/absence data
         $count = 1;
      }

      # Skip members with no abundance
      next if not $count;  # e.g. ''
      next if $count == 0; # e.g. 0.0

      # Get the member itself
      my $desc = $self->_get_value($line, $self->_col - 1);
      $member = $self->_members->{$desc};
      $self->_line($line);
      last;
   }
   return $member, $count;
}


method _next_community_init {
   # Go to start of next column and return name of new community. The first time,
   # generate all community members and read all community names
   if (not $self->_has_community_names) {
      $self->_generate_community_names();
   }
   if (not $self->_has_members) {
      $self->_generate_members();
   }

   my $name = shift @{$self->_community_names};
   $self->_current_name($name) if defined $name;
   $self->_line(0);
   return $name;
}


method _next_community_finish {
   return 1;
}


method write_member (Bio::Community::Member $member, Count $count) {

   # Replace spaces by dot in description
   my $desc = $member->desc;
   $desc =~ s/ /./g;

   my $desc2line = $self->_desc2line;
   my $line = $desc2line->{$desc};

   my $values = [$desc, $self->_current_name, $count];

   ### not needed if column removal is done at the end
   my $max_cols = $self->_get_max_col;
   if ($max_cols > 0 && (scalar @$values > $max_cols) ) {
      pop @$values;
   }

   if (not defined $line) {

      # This member has not been written previously for another community
      # append to table
      $line = $self->_get_max_line + 1;
      $self->_insert_line($line, $values );
      $desc2line->{$desc} = $line;

   } else {

      # Member already seen. Insert it in table next to where this member is
      # located for other communities. Not sure that this is required by the
      # Unifrac format, but this is safer this way.
      $self->_insert_line($line+1, $values);
      while (my ($memdesc, $memline) = each %$desc2line) {
         if ($memline >= $line) {
            # Increment line numbers
            $desc2line->{$memdesc}++;
         }
      }

   }

   if ($self->_qualitative_unifrac && $count > 1) {
      $self->_qualitative_unifrac( 0 );
   }

   $self->_line( $line + 1 );

   return 1;
}


method _write_community_init (Bio::Community $community) {
   # Replace spaces by dot in community name
   my $name = $community->name;
   $name =~ s/ /./g;
   $self->_current_name( $name );
   return 1;
}


method _write_community_finish (Bio::Community $community) {

   ### Do it at very end, not after each community
   if ( ($self->_get_max_col == 3) && $self->_qualitative_unifrac ) {
      # Delete last column (the counts)
      $self->_delete_col(3);
   }

   return 1;
}



__PACKAGE__->meta->make_immutable;

1;