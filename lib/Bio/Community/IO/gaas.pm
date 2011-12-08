package Bio::Community::IO::gaas;

use Moose::Role;
use namespace::autoclean;


has 'dummy' => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   init_arg => undef,
);


#method _next_member {
#
#}


#method _next_community {
#
#}


1;
