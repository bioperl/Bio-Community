package Bio::Community::Member;

use Moose;
use MooseX::NonMoose;

extends 'Bio::Root::Root';

my %ids = ();
my $last_id = 1;

has id => (
   is => 'ro',
   isa => 'Int',
   required => 0,
   default => sub {
         while (exists $ids{$last_id}) { $last_id++; };
         return $last_id;
      },
);

after id => sub {
   # Register ID after its assignment
   my $self = shift;
   $ids{$self->{id}} = undef;
};

no Moose;
__PACKAGE__->meta->make_immutable;
1;
