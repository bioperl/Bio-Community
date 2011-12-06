package Bio::Community::Types;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

subtype 'PositiveInt'
     => as 'Int'
     => where { $_ >= 0 }
     => message { 'Only positive integers accepted' };

subtype 'StrictlyPositiveInt'
     => as 'PositiveInt'
     => where { $_ > 0 }
     => message { 'Only strictly positive integers accepted' };

__PACKAGE__->meta->make_immutable;

1;

