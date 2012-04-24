# BioPerl module for Bio::Community::Role::Described
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Role::Described - Role for objects that have a description

=head1 SYNOPSIS

  package My::Package;

  use Moose;
  with 'Bio::Community::Role::Described';

  # Use the desc() method as needed
  # ...

  1;

=head1 DESCRIPTION

This role provides the capability to add an arbitrary description (a string)
to objects of the class that consumes this role.

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


package Bio::Community::Role::Described;

use Moose::Role;
use namespace::autoclean;


=head2 desc

 Usage   : my $description = $member->desc();
 Function: Get or set a description for this object.
 Args    : A string
 Returns : A string

=cut

has desc => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   default => '',
   init_arg => '-desc',
   lazy => 1,
);


1;
