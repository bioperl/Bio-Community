package Bio::Community::IO;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
use MooseX::Method::Signatures;
use Bio::Community::Types;

extends 'Bio::Root::Root';


has 'format' => (
   is => 'ro',
   isa => 'Str',
   required => 1,
   init_arg => '-format',
);


#method BUILDER {
   # apply the role for the proper format

#   my $role = 'dummy';
   #my $role = __PACKAGE__."::".$self->format;

#   print "Need to apply $role to \$self\n";

   #__PACKAGE__->meta->apply
#}


#method next_member {
#
#}


#method next_community {
#
#}


#method _index_file {
#
#}


#__PACKAGE__->meta->make_immutable(inline_constructor => 0);
__PACKAGE__->meta->make_immutable;

1;
