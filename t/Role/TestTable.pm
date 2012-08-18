package t::Role::TestTable;

use Moose;

extends 'Bio::Community::IO';
with 'Bio::Community::Role::Table';

# This is simply a test module that consumes the Table role.

__PACKAGE__->meta->make_immutable;

1;
