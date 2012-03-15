# BioPerl module for Bio::Community::IO::dummy
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

=head1 NAME

Bio::Community::IO::dummy - Dummy driver (does nothing)

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 OBJECT METHODS

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

=cut


package Bio::Community::IO::dummy;

use Moose;
use namespace::autoclean;
use MooseX::Method::Signatures;

extends 'Bio::Community::IO';
with 'Bio::Community::Role::IO';


our $default_sort_members = 0; # unsorted
our $default_abundance    = 'count';


has 'dummy' => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   init_arg => undef,
);


# Two methods must implemented by a driver: _next_community() and next_member()

method _next_community {
   return 'dummy';
}


method _next_member {
   return 1;
}



__PACKAGE__->meta->make_immutable;

1;
