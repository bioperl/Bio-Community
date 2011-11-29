package Bio::Community::Member;

use Moose;

has id => (
  is => 'ro',
  isa => 'Int',
  required => 0,
);


1;
