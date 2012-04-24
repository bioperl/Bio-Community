# BioPerl module for Bio::Community::Role::Weighted
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Role::Weighted - Role for objects that have a weight

=head1 SYNOPSIS

  package My::Package;

  use Moose;
  with 'Bio::Community::Role::Weighted';

  # Use the weights() method as needed
  # ...

  1;

=head1 DESCRIPTION

This role provides the capability to add an arrayref of weights (strictly positive
numbers) to objects of the class that consumes this role.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this
and other Bioperl modules. Send your comments and suggestions preferably
to one of the Bioperl mailing lists.

Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support 

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and 
reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem 
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via the
web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR - Florent Angly

Email florent.angly@gmail.com

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut


package Bio::Community::Role::Weighted;

use Moose::Role;
use namespace::autoclean;

=head2 weights

 Title   : weights
 Usage   : my $weights = $member->weights();
 Function: Get or set some weights for this object. Weights represent how biased
           the sampling of this organism is. For example, when random shotgun
           sequencing microorganisms in the environment, the relative abundance
           of reads in the sequence library is not proportional to the relative
           abundance of the genomes because larger genomes contribute
           disproportionalely more reads than small genomes. In such a case, you
           could set the weight to the length of the genome.
 Args    : An arrayref of positive integers
 Returns : An arrayref of positive integers

=cut

has weights => (
   is => 'rw',
   isa => 'Maybe[ArrayRef[StrictlyPositiveNum]]',
   required => 0,
   default => sub{[ 1 ]},
   init_arg => '-weights',
   lazy => 1,
);


1;
