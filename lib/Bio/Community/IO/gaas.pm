package Bio::Community::IO::gaas;

use Moose::Role;
use namespace::autoclean;
use MooseX::Method::Signatures;


has '_index' => (
   is => 'rw',
   isa => 'ArrayRef[ArrayRef[PositiveInt]]',
   required => 0,
   init_arg => undef,
   predicate => '_has_index',
);


method _index_file (Str $delim) {
   # Index the file the first time

   my @arr = (); # an array of array 

   while (my $line = $self->_readline) {

      ####
      print "line = $line\n";
      ####

      my $offset = 0;
      my @matches;
      while ( 1 ) {
         my $match = index($line, $delim, $offset);
         last if $match == -1;
         push @matches, $match;
         $offset = $match + 1;
      }
      for my $i ( 0 .. scalar @matches - 1) {

         my $match = $matches[$i];
         push @{$arr[$i]}, $match;
      }
   }
   $self->_index(\@arr);

   #####
   warn "Indexing file...\n";
   use Data::Dumper;
   warn Dumper(\@arr);
   #####

}


method _next_member {
   if (not $self->_has_index) {
      $self->_index_file("\t");
   }

   ####
   my $member = Bio::Community->new();
   my $count  = 0;
   ####

   return $member, $count;
}


1;
