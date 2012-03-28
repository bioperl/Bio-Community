package Bio::Community::Role::IndexedTable;

use Moose::Role;
use MooseX::Method::Signatures;
use namespace::autoclean;
use Fcntl;


#### Consuming class has to inherit from Bio::Root::IO
requires '_fh',
         '_readline',
         '_print';

=head1 Constructors

=head2 delim

 Title   : delim
 Usage   : my $delim = $in->delim;
 Function: Get or set the delimited, i.e. the characters that delimit the
           columns of the table. The default is tab, "\t".
 Args    : A string
 Returns : A string

=cut

has 'delim' => (
   is => 'ro',
   isa => 'Str',
   required => 0,
   init_arg => '-delim',
   default => "\t",
   lazy => 1,
);


=head2 start_line

 Title   : start_line
 Usage   : my $line_num = $in->start_line;
 Function: Get or set the line number at which the table starts. The default is
           1, i.e. the table starts at the beginning of the file.
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

 Title   : end_line
 Usage   : my $line_num = $in->end_line;
 Function: Get or set the line number at which the table ends. If undef (the
           default), the table ends at the last line of the file.
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


=head2 _max_line

 Title   : _max_line
 Usage   : my $num_lines = $in->_max_line;
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
);


=head2 _max_col

 Title   : _max_col
 Usage   : my $num_cols = $in->_max_col;
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
);


method BUILD {
   if ($self->mode eq 'r') {
      # After object constructed with new(), index table if filehandle is readable
      $self->_index_table;
   }
}


# When reading, contains index of table cells
# When writing, contains cell values to write
has '_index' => (
   is => 'rw',
   isa => 'ArrayRef[PositiveInt]',
   required => 0,
   init_arg => undef,
   default => sub { [] },
   lazy => 1,
   predicate => '_has_index',
);


###has '_values' => (
###   is => 'rw',
###   isa => 'ArrayRef',
###   required => 0,
###   init_arg => undef,
###   default => sub { [] },
###   lazy => 1,
###   predicate => '_has_values',
###);


=head2 _index_table

 Title   : _index_table
 Usage   : $in->_index_table;
 Function: Index the table in the file
 Args    : None
 Returns : 1 on success

=cut

method _index_table () {
   # Index the file the first time

   if ( $self->_has_index ) {
      return 1;
   }

   my $start_line = $self->start_line;
   my $end_line   = $self->end_line;
   if ( (defined $end_line) && ($end_line < $start_line) ) {
      $self->throw("Error: Got start ($start_line) greater than end ($end_line)\n");
   }

   my @arr; # array of file offsets 
   my ($max_line, $max_col) = (0, 0);

   my $delim = $self->delim;
   my $delim_length = length $delim;

   my $file_offset = 0;
   while (my $line = $self->_readline(-raw => 1)) {

      # Count line length
      $line =~ m/([\r\n]?\n)$/;
      my $num_eol_chars = length($1);
      my $line_length = length( $line );

      # Do not index the line if it is before or after the table;
      if ($. < $start_line) {
         $file_offset += $line_length;
         next;
      }
      if ( (defined $end_line) && ($. > $end_line) ) {
         next;
      }

      # Save the offset of the first line of the table
      if (scalar @arr == 0) {
         push @arr, $file_offset;
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
            $self->throw("Error: Got $nof_cols columns at line $. but got a different number ($max_col) at the previous line\n");
         }
      }
      $max_line++;
      push @arr, @matches;
   }
   $self->_index(\@arr);
   $self->_max_line($max_line);
   $self->_max_col($max_col);

   return 1;
}


=head2 _get_indexed_value

 Title   : _get_indexed_value
 Usage   : my $value = $in->_get_indexed_value(1, 3);
 Function: Get the element at the given line and column of the table.
 Args    : A strictly positive integer for the line
           A strictly positive integer for the column
 Returns : A string for the value of the table at the given line and column
             or
           undef if line or column were out-of-bounds

=cut

method _get_indexed_value (StrictlyPositiveInt $line, StrictlyPositiveInt $col) {
   my $val;
   if ( ($line <= $self->_max_line) && ($col <= $self->_max_col) ) {

      # Retrieve the value if it is within the bounds of the table
      my $pos = ($line - 1) * $self->_max_col + $col - 1;
      my $index = $self->_index;
      my $offset = $index->[$pos];
      seek $self->_fh, $offset, 0;
      my $length = $index->[$pos+1] - $offset;
      read $self->_fh, $val, $length or
         $self->throw("Error: Could not read $length chars from offset $offset\n$!\n");

      # Clean up delimiters and end of line characters
      my $delim = $self->delim;
      $val =~ s/[\r\n$delim]//g;

   }
   return $val;
}


#####

=head2 _set_value

 Title   : _set_value
 Usage   : $out->_set_value(1, 3, $value);
 Function: Set the element at the given line and column of the table.
 Args    : A strictly positive integer for the line
           A strictly positive integer for the column
           A string for the value of the table at the given line and column
 Returns : 1 for success

=cut

method _set_value (StrictlyPositiveInt $line, StrictlyPositiveInt $col, $value) {

   # Update table dimensions
   my $max_lines = $self->_max_line;
   my $new_max_lines = $line > $max_lines ? $line : $max_lines;
   my $max_cols = $self->_max_col;
   my $new_max_cols = $col > $max_cols ? $col : $max_cols;
   $self->_max_line($new_max_lines);
   $self->_max_col($new_max_cols);

   # Set new value
   my $pos = ($line - 1) * $new_max_cols + $col - 1;
   $self->_index->[$pos] = $value;

   return 1;
}

#####




1;


