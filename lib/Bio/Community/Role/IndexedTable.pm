package Bio::Community::Role::IndexedTable;

use Moose::Role;
use MooseX::Method::Signatures;
use namespace::autoclean;


# Object has to be a Bio::Root::IO
requires '_fh',
         '_readline';

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

#has 'start_line' => (
#   is => 'ro',
#   isa => 'StrictlyPositiveInt',
#   required => 0,
#   init_arg => '-start_line',
#   default => 1,
#   lazy => 1,
#);


=head2 end_line

 Title   : end_line
 Usage   : my $line_num = $in->end_line;
 Function: Get or set the line number at which the table ends. If undef (the
           default), the table ends at the last line of the file.
 Args    : A strictly positive number or undef
 Returns : A strictly positive number or undef

=cut

#has 'end_line' => (
#   is => 'ro',
#   isa => 'Maybe[StrictlyPositiveInt]',
#   required => 0,
#   init_arg => '-end_line',
#   default => undef,
#   lazy => 1,
#);


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
   # Index the table after the object has been constructed with new()
   $self->_index_table;
}


has '_index' => (
   is => 'rw',
   ####
   #isa => 'ArrayRef[ArrayRef[PositiveInt]]',
   isa => 'ArrayRef[PositiveInt]',
   ####
   required => 0,
   init_arg => undef,
   default => sub { [] },
   lazy => 1,
);


=head2 _index_table

 Title   : _index
 Usage   : $in->_index_table;
 Function: Index a table
 Args    : None
 Returns : None

=cut

method _index_table () {
   # Index the file the first time

   my @arr = ( 0 ); # array of file offsets 
   my ($max_line, $max_col) = (0, 0);

   #### TODO: provide a start and end line
   #my $start_line = $self->start_line;
   #my $end_line   = $self->end_line;
   ####

   my $file_offset = 0;
   while (my $line = $self->_readline(-raw => 1)) {
      my $line_offset = 0;
      my @matches;
      while ( 1 ) {
         my $match = index($line, $self->delim, $line_offset);
         if ($match == -1) {
            # Reached end of line. Register it and move on to next line.
            $line =~ m/([\r\n]?\n)$/;
            my $num_eol_chars = length($1);
            $match = length( $line ) - $num_eol_chars;
            push @matches, $match + $file_offset;
            $file_offset += $match + $num_eol_chars;
            last;
         } else {
            push @matches, $match + $file_offset;
            $line_offset = $match + 1;
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

   #####
   warn "Indexing file...\n";
   use Data::Dumper;
   warn Dumper(\@arr);
   #####

}


=head2 _get_indexed_value

 Title   : _get_indexed_value
 Usage   : my $value = $in->_get_indexed_value(1,3);
 Function: Get the element of the table at the given line and column. The first
           time this is called, the file will be indexed.
 Args    : A strictly positive integer for the line
           A strictly positive integer for the column
 Returns : A string for the value of the table at the given line and column
             or
           undef if line or column were out-of-bounds

=cut

method _get_indexed_value (StrictlyPositiveInt $line, StrictlyPositiveInt $column) {
   my $val = undef;
   if ( ($line <= $self->_max_line) && ($column <= $self->_max_col) ) {

      # Retrieve the value if it is within the bounds of the table
      my $pos = ($line - 1) * $self->_max_col + $column - 1;
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




1;


