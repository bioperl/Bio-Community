# BioPerl module for Bio::Community::Role::Table
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Role::Table - Role to read/write data tables and provide random
access to their cells

=head1 SYNOPSIS

  package My::Package;

  use Moose;
  extends 'Bio::Root::IO';
  with 'Bio::Community::Role::Table';

  # Use the new(), _read_table(), _get_value(), _set_value() and _write_table()
  # methods as needed
  # ...

  1;

=head1 DESCRIPTION

This role implements methods to read and write file structured as a table
containing rows and columns. When reading a table from a file, an index is kept
to provide random-access to any cell of the table. When writing a table to a file,
cell data can also be given in any order. It is kept in memory until the file is
written to disk.

Objects are constructed with the new() method. Since Table-consuming classes
must inherit from Bio::Root::IO, all Bio::Root::IO options are accepted, e.g.
-file, -fh, -string, -flush, etc. Other constructors are detailed in the
L<APPENDIX>.

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


package Bio::Community::Role::Table;

use Moose::Role;
use Method::Signatures;
use namespace::autoclean;
use Fcntl;


# Consuming class has to inherit from Bio::Root::IO
requires '_fh',
         '_readline',
         '_print';


=head2 delim

 Usage   : my $delim = $in->delim;
 Function: When reading or writing a table, get or set the delimiter, i.e. the
           characters that delimit the columns of the table. The default is the
           tab character "\t".
 Args    : A string
 Returns : A string

=cut

has 'delim' => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   init_arg => '-delim',
   default => "\t",
   lazy => 1,
);


=head2 start_line

 Usage   : my $line_num = $in->start_line;
 Function: When reading a table, get or set the line number at which the table
           starts. The default is 1, i.e. the table starts at the first line of
           the file. This option is not used when writing a table, but see
           _write_table() for details.
 Args    : A strictly positive number
 Returns : A strictly positive number

=cut

has 'start_line' => (
   is => 'ro',
   isa => 'StrictlyPositiveInt',
   required => 0,
   init_arg => '-start_line',
   default => 1,
   lazy => 1,
);


=head2 end_line

 Usage   : my $line_num = $in->end_line;
 Function: When reading a table, get or set the line number at which the table
           ends. If undef (the default), the table ends at the last line of the
           file.
 Args    : A strictly positive number or undef
 Returns : A strictly positive number or undef

=cut

has 'end_line' => (
   is => 'ro',
   isa => 'Maybe[StrictlyPositiveInt]',
   required => 0,
   init_arg => '-end_line',
   default => undef,
   lazy => 1,
);


=head2 missing_string

 Usage   : my $missing = $out->missing_string;
 Function: When reading a table, get or set the line number at which the table
           ends. If undef (the default), the table ends at the last line of the
           file.
 Args    : A string, e.g. '', '0', 'n/a', '-'
 Returns : A string

=cut

has 'missing_string' => (
   is => 'ro',
   isa => 'Str',
   required => 0,
   init_arg => '-missing_string',
   default => '0',
   lazy => 1,
);


=head2 _get_max_line

 Usage   : my $num_lines = $in->_get_max_line;
 Function: Get the number of lines in the table
 Args    : None
 Returns : Strictly positive integer

=cut

has '_max_line' => (
   is => 'rw',
   isa => 'StrictlyPositiveInt',
   required => 0,
   init_arg => undef,
   default => 1,
   lazy => 1,
   reader => '_get_max_line',
   writer => '_set_max_line',
);


=head2 _get_max_col

 Usage   : my $num_cols = $in->_get_max_col;
 Function: Get the number of columns in the table
 Args    : None
 Returns : Strictly positive integer

=cut

has '_max_col' => (
   is => 'rw',
   isa => 'StrictlyPositiveInt',
   required => 0,
   init_arg => undef,
   default => 1,
   lazy => 1,
   reader => '_get_max_col',
   writer => '_set_max_col',
);


sub BUILD {
   my $self = shift;
   # After object constructed with new(), index table if filehandle is readable
   if ($self->mode eq 'r') {
      $self->_read_table;
   }
}


before 'close' =>  sub {
   # Before closing filehandle, write the table if filehandle is writable and
   # the table was not already written.
   my $self = shift;
   if ( ($self->mode eq 'w') && (not $self->_was_written) ) {
      $self->_write_table;
   }
};


# Index of the location of the cells (when reading a table)
has '_index' => (
   is => 'rw',
   isa => 'ArrayRef', # really an ArrayRef[PositiveInt] but keep it light
   required => 0,
   init_arg => undef,
   default => sub { [] },
   lazy => 1,
   predicate => '_has_index',
);


# Value contained in the table cells (when writing a table)
has '_values' => (
   is => 'rw',
   isa => 'ArrayRef', # really an ArrayRef[Str] but keep it light
   required => 0,
   init_arg => undef,
   default => sub { [''] },
   lazy => 1,
);


has '_was_written' => (
   is => 'rw',
   isa => 'Bool',
   required => 0,
   init_arg => undef,
   default => 0,
   lazy => 1,
);


=head2 _read_table

 Usage   : $in->_read_table;
 Function: Read the table in the file and index the position of its cells.
 Args    : None
 Returns : 1 on success

=cut

method _read_table () {
   # Index the file the first time

   if ( $self->_has_index ) {
      return 1;
   }

   my $start_line = $self->start_line;
   my $end_line   = $self->end_line;
   if ( (defined $end_line) && ($end_line < $start_line) ) {
      $self->throw("Error: Got start ($start_line) greater than end ($end_line)\n");
   }

   my @index; # array of file offsets 
   my ($max_line, $max_col) = (0, 0);

   my $delim = $self->delim;
   my $delim_length = length $delim;

   my $file_offset = 0;
   while (my $line = $self->_readline(-raw => 1)) {

      # Count line length
      $line =~ m/([\r\n]?\n)$/; # last line may not match
      my $num_eol_chars = length($1||'');
      my $line_length = length $line;

      # Do not index the line if it is before or after the table
      if ($. < $start_line) {
         $file_offset += $line_length;
         next;
      }
      if ( (defined $end_line) && ($. > $end_line) ) {
         next;
      }

      # Save the offset of the first line of the table
      if (scalar @index == 0) {
         push @index, $file_offset;
      }

      # Index the line
      my $line_offset = 0;
      my @matches;
      while ( 1 ) {
         my $match = index($line, $delim, $line_offset);
         if ($match == -1) {
            # Reached end of line. Register it and move on to next line.
            $match = length( $line ) - $num_eol_chars;
            push @matches, $match + $file_offset;
            $file_offset += $line_length;
            last;
         } else {
            # Save the match
            push @matches, $match + $file_offset;
            $line_offset = $match + $delim_length;
         }
      }
      my $nof_cols = scalar @matches;
      if ($nof_cols != $max_col) {
         if ($max_col == 0) {
            # Initialize the number of columns
            $max_col = $nof_cols;
         } else {
            $self->throw( "Error: Got $nof_cols columns at line $. but got a ".
               "different number ($max_col) at the previous line\n" );
         }
      }
      $max_line++;
      push @index, @matches;
   }
   $self->_index(\@index);
   $self->_set_max_line($max_line);
   $self->_set_max_col($max_col);

   return 1;
}


=head2 _get_value

 Usage   : my $value = $in->_get_value(1, 3);
 Function: Get the value of the cell given its position in the table (line and
           column).
 Args    : A strictly positive integer for the line
           A strictly positive integer for the column
 Returns : A string for the value of the table at the given line and column
             or
           undef if line or column were out-of-bounds

=cut

#method _get_value (StrictlyPositiveInt $line, StrictlyPositiveInt $col) { # too costly
method _get_value ($line, $col) {
   my $val;
   if ( ($line <= $self->_get_max_line) && ($col <= $self->_get_max_col) ) {

   ###my $max_cols = $self->_get_max_col; # not really faster
   ###if ( ($col <= $max_cols) && ($line <= $self->_get_max_line) ) {

      # Retrieve the value if it is within the bounds of the table
      my $pos = ($line - 1) * $self->_get_max_col + $col - 1;
      my $index = $self->_index;
      my $offset = $index->[$pos];
      seek $self->_fh, $offset, 0;
      my $length = $index->[$pos+1] - $offset;
      read $self->_fh, $val, $length or
         $self->throw("Error: Could not read $length chars from offset $offset\n$!\n");

      # Clean up delimiters and end of line characters

      my $delim = $self->delim;
      $val =~ s/[\r\n$delim]//g;

      ###$val =~ s/[\r\n${\$self->delim}]//g; # not really any faster

   }
   return $val;
}


=head2 _set_value

 Usage   : $out->_set_value(1, 3, $value);
 Function: Set the element at the given line and column of the table.
 Args    : A strictly positive integer for the line
           A strictly positive integer for the column
           A string for the value of the table at the given line and column
 Returns : 1 for success

=cut

#method _set_value (StrictlyPositiveInt $line, StrictlyPositiveInt $col, $value) { # too costly
method _set_value ($line, $col, $value) {

   my $pos = 0;
   my $values = $self->_values;
   my $max_lines = $self->_get_max_line;
   my $max_cols = $self->_get_max_col;

   # Extend table with columns if needed
   if ($col > $max_cols) {
      my $new_max_cols = $col;
      my $diff = $new_max_cols - $max_cols;
      for ( my $idx  = $max_cols;
               $idx  < $new_max_cols * $max_lines;
               $idx += $new_max_cols               ) {
         splice @$values, $idx, 0, ($self->missing_string)x$diff;
      }
      $max_cols = $new_max_cols;
      $self->_set_max_col($new_max_cols);
   }

   # Extend table with lines if needed
   if ($line > $max_lines) {
      my $new_max_lines = $line;
      for ( my $idx  = $max_cols * $max_lines;
               $idx  < $max_cols * $new_max_lines;
               $idx += $max_cols                   ) {
         splice @$values, $idx, 0, ($self->missing_string)x$max_cols;
      }
      $max_lines = $new_max_lines;
      $self->_set_max_line($new_max_lines);
   }

   # Set new value
   $pos = ($line - 1) * $max_cols + $col - 1;
   $values->[$pos] = $value;

   return 1;
}


=head2 _write_table

 Usage   : $out->_write_table;
 Function: Write the content of the cells in the table to a file. This method is
           called automatically when the filehandle is closed: $out->close;
           If you want header lines before the table, it is your responsability
           to write them to file using the _print() method of Bio::Root::IO
           prior to calling _write_table().
 Args    : None
 Returns : 1 on success

=cut

method _write_table {
   my $delim    = $self->delim;
   my $values   = $self->_values;
   my $max_cols = $self->_get_max_col;
   for my $line ( 1 .. $self->_get_max_line ) {
      my $start = ($line - 1) * $max_cols;
      my $end   =  $line      * $max_cols - 1;
      $self->_print( join( $delim, @$values[$start..$end] ) . "\n" );
   }
   $self->_was_written(1);
   return 1;
}


1;


