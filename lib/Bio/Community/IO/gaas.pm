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

   my $in = Bio::Community::IO->new( -file => 'gaas_compo.txt', -format => 'gaas' );

   # See Bio::Community::IO for more information

=head1 DESCRIPTION

This Bio::Community::IO driver handles files in the format generated by GAAS
(http://sourceforge.net/projects/gaas/). Here is an example:

  # tax_name	tax_id	rel_abund
  Streptococcus pyogenes phage 315.1	198538	0.791035649011735
  Goatpox virus Pellor	376852	0.196094208626593
  Lumpy skin disease virus NI-2490	376849	0.0128701423616715

GAAS creates one such file per community. Note that GAAS does not include counts
for the community members but relative abundances. Thus, the get_member_count() 
method of the Bio::Community objects generated using this driver is a relative
abundance (a decimal number) instead of the usual integers used for counts.

=head1 CONSTRUCTOR

No specific constructor

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



package Bio::Community::IO::gaas;

use Moose;
use namespace::autoclean;
use MooseX::Method::Signatures;
use Bio::Community::Member;

extends 'Bio::Community::IO';


method next_member {
   # Read next line
   my $line;
   do {
      $line = $self->_readline;
      if (not defined $line) {
         return undef;
      }
   } while ( ($line =~ m/^#/) || ($line =~ m/^\s*$/) ); # skip comment and empty lines

   # Parse and validate the line 
   chomp $line;
   my ($name, $id, $rel_ab) = split "\t", $line;

   if ( (not defined $name  ) ||
        (not defined $id    ) ||
        (not defined $rel_ab) ) {
      $self->throw("Error: The following line does not follow the GAAS format.\n-->$line<--\n");
   }

   ##### TODO:handle things differently if GAAS used a taxonomy file
   my $member = Bio::Community::Member->new( -desc => $name );

   # Note that a relative abundance is returned, not a count
   return $member, $rel_ab;
}


method write_member (Bio::Community::Member $member, Count $count) {
   my $line = $member->desc."\t".''."\t".$count."\n";
   $self->_print( $line );
   return 1;
}


__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
