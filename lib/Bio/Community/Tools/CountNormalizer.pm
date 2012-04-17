# BioPerl module for Bio::Community::Tools::CountNormalizer
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

=head1 NAME

Bio::Community::Tools::CountNormalizer - Normalize communities by count

=head1 SYNOPSIS

  use Bio::Community::Tools::CountNormalizer;

  my $normalizer = Bio::Community::Tools::CountNormalizer->new(
     -communities => [ $community1, $community2 ],
     -sample_size => # default is minimum community size
     -repetitions => # default is automatic

  );

=head1 DESCRIPTION

This module produces communities normalized by their number of counts.

Comparing the composition and diversity of biological communities can be biased
by sampling artefacts. When comparing two identical communities, one for which
10,000 counts were made to one, to one with only 1,000 counts, the smaller
community will appear less diverse. A solution is to repeatedly bootstrap the
larger communities by taking 1,000 random members from it.

This module uses Bio::Community::Sampler to take random member from communities
and normalize them by their number of counts. After all random repetitions have
been performed, average communities or representative communities are returned.
These communities all have the same number of counts.

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

=head2 new

 Title   : new
 Function: Create a new Bio::Community::Tool::CountNormalizer object
 Usage   : my $normalizer = Bio::Community::Tool::CountNormalizer->new( );
 Args    : 
 Returns : a new Bio::Community::Tools::CountNormalizer object

=cut


package Bio::Community::Tools::CountNormalizer;

use Moose;
use MooseX::NonMoose;
use MooseX::Method::Signatures;
use namespace::autoclean;

extends 'Bio::Root::Root';


has communities => (
   is => 'ro',
   isa => 'ArrayRef[Bio::Community]',
   required => 0,
   default => sub{ [] },
   lazy => 1,
   init_arg => '-community',
);



has repetitions => (
   is => 'ro',
   isa => 'PositiveInt',
   required => 0,
   default => -1,
   lazy => 1,
   init_arg => '-repetitions',
);


has sample_size => (
   is => 'ro',
   isa => 'StrictlyPositiveInt',
   required => 0,
   default => -1,
   lazy => 1,
   init_arg => '-sample_size',
);


has _average_community => (
   is => 'rw',
   isa => 'Bio::Community',
   required => 0,
   default => undef,
   lazy => 1,
);


has _representative_community => (
   is => 'rw',
   isa => 'Bio::Community',
   required => 0,
   default => undef,
   lazy => 1,
);


method _initialize () {
   
}


method get_average_communities () {

}


method get_representative_communities () {

}


__PACKAGE__->meta->make_immutable;

1;
