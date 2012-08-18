# BioPerl module for Bio::Community::Role::Locked
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Role::Locked - Role for objects that can be locked (made read-only)

=head1 SYNOPSIS

  package My::Package;

  use Moose;
  with 'Bio::Community::Role::Locked';

  # Use the lock() and unlock() methods as needed
  # ...

  1;

=head1 DESCRIPTION

This role provides the capability to make objects of the class that consumes this
role read-only. The lock() method can be invoked to make an object read-only,
while unlock() restores the read/write properties of the object. If you try to
call a method to modify an object that is locked or otherwise attempt to change
its hash, you will get an error similar to this:

 Modification of a read-only value attempted at accessor Bio::Community::Member::foo

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


package Bio::Community::Role::Locked;

use Moose::Role;
use Method::Signatures;
use namespace::autoclean;
use Hash::Util ();


=head2 lock

 Usage   : $member->lock();
 Function: Lock the object, making it read-only.
 Args    : None
 Returns : 1 for success

=cut

method lock () {
   #Hash::Util::lock_hash_recurse(%$self);
   Hash::Util::lock_hash(%$self);
   return 1;
}


=head2 unlock

 Usage   : $member->unlock();
 Function: Unlock the object, restoring its read and write properties.
 Args    : None
 Returns : 1 for success

=cut

method unlock () {
   #Hash::Util::unlock_hash_recurse(%$self);
   Hash::Util::unlock_hash(%$self);
   return 1;
}


1;
