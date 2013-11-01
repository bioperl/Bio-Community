# BioPerl module for Bio::Community::Role::PRNG
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Role::PRNG - Role for objects that use a pseudo-random number generator

=head1 SYNOPSIS

  package My::Package;

  use Moose;
  with 'Bio::Community::Role::PRNG';

  # Use set_seed(), get_seed() and rand() as needed
  # ...

  1;

=head1 DESCRIPTION

This role provides the capability to generate random numbers using a specified
or automatically determined seed. This module uses the superior Mersenne-Twister
algorithm provided by the L<Math::Random::MT> module to draw uniformly
distributed random numbers.

=head1 AUTHOR

Florent Angly L<florent.angly@gmail.com>

=head1 SUPPORT AND BUGS

User feedback is an integral part of the evolution of this and other Bioperl
modules. Please direct usage questions or support issues to the mailing list, 
L<bioperl-l@bioperl.org>, rather than to the module maintainer directly. Many
experienced and reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem with code and
data examples if at all possible.

If you have found a bug, please report it on the BioPerl bug tracking system
to help us keep track the bugs and their resolution:
L<https://redmine.open-bio.org/projects/bioperl/>

=head1 COPYRIGHT

Copyright 2011,2012,2013 by the BioPerl Team L<bioperl-l@bioperl.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


package Bio::Community::Role::PRNG;

use Moose::Role;
use namespace::autoclean;
use Method::Signatures;
use Math::Random::MT;


has _prng  => (
   is => 'rw',
   #isa => 'Math::Random::MT',
   required => 0,
   default => undef,
   default => sub { Math::Random::MT->new( shift->seed ) },
   init_arg => undef,
   lazy => 1,
   predicate => '_has_prng',
);


has seed => (
   is => 'rw',
   isa => 'Maybe[PositiveInt]',
   required => 0,
   default => undef,
   init_arg => '-seed',
   lazy => 1,
);


=head2 get_seed, set_seed

 Usage   : $prng->set_seed(1234513451);
 Function: Get or set the seed used to generate the random numbers.
 Args    : Positive integer
 Returns : Positive integer

=cut

method get_seed {
   $self->_prng->get_seed;
}


method set_seed ($int) {
   $self->_prng->set_seed($int);
}


=head2 rand

 Usage   : my $num = $prng->rand($max);
 Function: Generate a number uniformly distributed in [0, $max)
 Args    : Number
 Returns : Number

=cut

method rand ($num?) {
   $self->_prng->rand($num);
}



1;
