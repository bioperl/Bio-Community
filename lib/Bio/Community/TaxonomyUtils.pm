# BioPerl module for Bio::Community::TaxonomyUtils
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::TaxonomyUtils - Functions for manipulating taxonomic lineages

=head1 SYNOPSIS

  use Bio::Community::TaxonomyUtils qw(split_lineage_string get_lineage_string);

  my $lineage = 'Bacteria;WCHB1-60;unidentified';
  my $lineage_arr = split_lineage_string($lineage);
  $lineage = get_lineage_string($lineage_arr);

  print "Lineage is: $lineage\n"; # Bacteria;WCHB1-60

=head1 DESCRIPTION

This module implements functions to manipulate taxonomic lineages, as arrayref
of taxon names or taxon objects.

=back

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


package Bio::Community::TaxonomyUtils;

use strict;
use warnings;
use Method::Signatures;

use Exporter 'import';
our @EXPORT = qw(
   split_lineage_string
   clean_lineage_arr
   get_taxon_lineage
   get_lineage_string
);

use base 'Bio::Root::Root';


my $sep = ';'; # separator
my $sep_re = qr/$sep\s*/;
my $clean_front_re = qr/^(?:Root)$/i;
my $clean_rear_re  = qr/^(?:\S__||Other|No blast hit|unidentified|uncultured|environmental)$/i;


=head2 split_lineage_string

 Function: Split a lineage string, e.g. 'Bacteria;Proteobacteria' into an
           arrayref of its individual components using the ';' separator, e.g.
           'Bacteria' and 'Betaproteobact'. Also, clean the arrayref using
           clean_lineage_arr(). The opposite operation is get_lineage_string().
 Usage   : my $taxa_names = split_lineage($lineage_string);
 Args    : a lineage string
 Returns : an arrayref of taxon names

=cut

func split_lineage_string ($lineage_str) {
   my $names = [ split $sep_re, $lineage_str ];
   $names = clean_lineage_arr($names);
   return $names;
}


=head2 clean_lineage_arr

 Function: Two step cleanup:
           1/ At the beginning of the array, remove anything called 'Root'
           2/ Starting from the end of the array, remove ambiguous taxonomic
              information such as:
                '', 'No blast hit', 'unidentified', 'uncultured', 'environmental',
                'Other', 'g__', 's__', etc
 Usage   : $lineage_arr = clean_lineage_arr($lineage_arr);
 Args    : A lineage arrayref (either taxon names or objects)
 Returns : A lineage arrayref

=cut

func clean_lineage_arr ($lineage_arr) {
   # Clean the front
   my $elem = $lineage_arr->[0];
   if ( defined $elem ) {
      $elem = $elem->node_name if ref $elem;
      if ($elem =~ $clean_front_re) {
         shift @$lineage_arr;
      }
   }
   # Clean the rear
   while ( $elem = $lineage_arr->[-1] ) {
      $elem = $elem->node_name if ref $elem;
      if ($elem =~ $clean_rear_re) {
         pop @$lineage_arr;
      } else {
         last;
      }
   }
   return $lineage_arr;
}


=head2 get_taxon_lineage

 Function: Take a taxon object and return its lineage as an arrayref of the
           taxon itself, preceded by its ancestor taxa.
 Usage   : my $lineage_arr = get_taxon_lineage($taxon);
 Args    : A taxon object
 Returns : An arrayref of taxon names

=cut

func get_taxon_lineage ($taxon) {
   my @arr;
   if ($taxon) {
      @arr = ($taxon);
      my $ancestor = $taxon;
      while ( $ancestor = $ancestor->ancestor ) {
         unshift @arr, $ancestor;   
      }
   }
   return \@arr;
}


### Renane this join_lineage_arr (and have alias for backward compat)

=head2 get_lineage_string

 Function: Take a lineage arrayref and return a full lineage string by joining
           the elements using the ';' separator. The opposite operation is
           split_lineage_string().
 Usage   : my $lineage = get_lineage_string(['Bacteria', 'Proteobacteria']);
             or
           my $lineage = get_lineage_string([$taxon1, $taxon2]);
 Args    : Arrayref of taxon names or objects
           1 to include a whitespace between each entry (in addition to the separator)
 Returns : A lineage string

=cut

func get_lineage_string ($lineage_arr, $space?) {
   my @names = map { ref $_ ? $_->node_name : $_ } @$lineage_arr;
   $space = (defined($space) && $space) ? ' ' : '';
   return join( $sep.$space, @names );
}



1;
