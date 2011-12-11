package Bio::Community::Role::IO;

use Moose::Role;
use namespace::autoclean;

requires 'next_member',
         'next_community',
         'write_member',
         'write_community',
         'sort_members';


1;
