# BioPerl module for Bio::Community::IO::gaas
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself
#
# POD documentation - main docs before the code

=head1 NAME

Bio::Community::IO::gaas - Driver to read and write files in the format used by GAAS

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


package Bio::Community::IO::format_to_index;

use Moose;
use namespace::autoclean;

extends 'Bio::Community::IO';
with 'Bio::Community::Role::IO';


our $default_sort_members = 0;

has '_index' => (
   is => 'rw',
   isa => 'ArrayRef[ArrayRef[PositiveInt]]',
   required => 0,
   init_arg => undef,
   predicate => '_has_index',
);


method _index_file (Str $delim) {
   # Index the file the first time

   my @arr = (); # an array of array 

   while (my $line = $self->_readline) {

      ####
      print "line = $line\n";
      ####

      my $offset = 0;
      my @matches;
      while ( 1 ) {
         my $match = index($line, $delim, $offset);
         last if $match == -1;
         push @matches, $match;
         $offset = $match + 1;
      }
      for my $i ( 0 .. scalar @matches - 1) {

         my $match = $matches[$i];
         push @{$arr[$i]}, $match;
      }
   }
   $self->_index(\@arr);

   #####
   warn "Indexing file...\n";
   use Data::Dumper;
   warn Dumper(\@arr);
   #####

}

method _next_member {
   if (not $self->_has_index) {
      $self->_index_file("\t");
   }

   ####
   my $member = Bio::Community::Member->new();
   my $count  = 0;
   ####

   return $member, $count;
}


__PACKAGE__->meta->make_immutable;

1;
