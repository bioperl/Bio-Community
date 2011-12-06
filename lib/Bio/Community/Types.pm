package Bio::Community::Types;

use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

subtype 'PositiveNum'
     => as 'Num'
     => where { $_ >= 0 }
     => message { 'Only positive numbers accepted' };

subtype 'StrictlyPositiveNum'
     => as 'PositiveNum'
     => where { $_ > 0 }
     => message { 'Only strictly positive numbers accepted' };

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

