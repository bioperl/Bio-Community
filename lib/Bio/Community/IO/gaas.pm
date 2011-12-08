package Bio::Community::IO::gaas;

use Moose::Role;
use namespace::autoclean;
use MooseX::Method::Signatures;

requires '_readline'; 

has '_index' => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   init_arg => undef,
   predicate => '_has_index',
);


### indexing files is nice but what happens if the input is a stream passed through stdin?

method _index_file (Str $delim) {

   ####
   warn "Indexing file...\n";
   ####

   while (my $line = $self->_readline) {
      my $offset = 0;
      my @matches;
      while ( 1 ) {
         my $match = index($line, $delim, $offset);
         last if $match == -1;
         push @matches, $match;
         $offset = $match + 1;
      }
   }
}


method _next_member {
   if (not $self->_has_index) {
      $self->_index_file("\t");
   }
}


1;
