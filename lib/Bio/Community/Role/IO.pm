package Bio::Community::Role::IO;

use Moose::Role;
use namespace::autoclean;

requires 'next_member',
         'next_community',
         '_next_community_init',
         '_next_community_finish',
         'write_member',
         'write_community',
         '_write_community_init',
         '_write_community_finish',
         'sort_members';

1;
