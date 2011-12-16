package Bio::Community::Role::IndexedTable;

use Moose::Role;
use MooseX::Method::Signatures;
use namespace::autoclean;


# Object has to be a Bio::Root::IO
requires '_fh',
         '_readline';


has 'delim' => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   init_arg => undef,
   default => "\t",
   lazy => 1,
);


#### provide a start and stop so that the entire file does not need to be
#### indexed: headers and footers do not need to be indexed


has '_index' => (
   is => 'rw',
   isa => 'ArrayRef[ArrayRef[PositiveInt]]',
   required => 0,
   init_arg => undef,
   predicate => '_has_index',
   #default => sub { [] },
   #lazy => 1,
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
   # Index the table after the object has been constructed with new()
   $self->_index_table;
}


=head2 _index_table

 Title   : _index
 Usage   : $in->_index_table;
 Function: Index a table
 Args    : None
 Returns : None

=cut

method _index_table () {
   # Index the file the first time

   my @arr = (); # an array of array 

   my ($max_line, $max_col) = (0, 0);

   my $file_offset = 0;
   while (my $line = $self->_readline) {
      my $line_offset = 0;
      my @matches;
      while ( 1 ) {
         my $match = index($line, $self->delim, $line_offset);
         if ($match == -1) {
            # Reached end of line. Register it and move on to next line.
            $match = length( $line ) - 1;
            push @matches, $match + $file_offset;
            $file_offset += $match + 1; ### +2 on non-unix platforms (\r\n) ??
            last;
         } else {
            push @matches, $match + $file_offset;
            $line_offset = $match + 1;
         }
      }
      #### complain if the number of column is not the same everywhere?
      push @arr, \@matches;
      $max_line++;
      $max_col = scalar @matches if scalar @matches > $max_col;
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

   my $offset1;
   if ($column == 1) {
      if ($line == 1) {
         $offset1 = 0;
      } else {
         $offset1 = $self->_index->[$line-2]->[-1]
      }
   } else {
      $offset1 = $self->_index->[$line-1]->[$column-2];
   }
   
   if (defined $offset1) {
      seek $self->_fh, $offset1, 0;
      my $offset2 = $self->_index->[$line-1]->[$column-1];
      if (defined $offset2) {
         read($self->_fh, $val, $offset2 - $offset1) or
            $self->throw("Error: Could not read content between offset $offset1 and $offset2\n$!\n");

         ####
         $val =~ s/[\r\n\t]//;
         #$val =~ s/\t//;
         ####

      }
   }

   return $val;
}




1;


