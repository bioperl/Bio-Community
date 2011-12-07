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


method BUILD {
   # Apply the role for the format that is needed
   my $role = __PACKAGE__."::".$self->format;

   eval "require $role";
   if ($@) {
      my $msg = "$role cannot be found or contains errors\n".
                "Exception: $@\n".
                "For more information about the IO system please see the ".
                __PACKAGE__." docs.\n";
      $self->throw($msg);
   }

   $role->meta->apply( $self );
}


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
