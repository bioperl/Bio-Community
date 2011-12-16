package t::IndexedTable;

use Moose;

extends 'Bio::Community::IO';
with 'Bio::Community::Role::IndexedTable';

# This is simply a test module that consumes the IndexedTable role.

__PACKAGE__->meta->make_immutable;

1;
