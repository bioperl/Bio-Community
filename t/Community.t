use strict;
use warnings;
use Bio::Root::Test;

use Bio::Community::Member;

use_ok($_) for qw(
    Bio::Community
);

my $community;

ok $community = Bio::Community->new();

isa_ok $community, 'Bio::Root::RootI';
isa_ok $community, 'Bio::Community';

ok $community->add_member( Bio::Community::Member->new() );

ok $community->add_member( Bio::Community::Member->new(), 23 );



done_testing();

exit;
