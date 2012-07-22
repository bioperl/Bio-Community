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
my $ignore_re = qr/^(?:\S__||Other|No blast hit|unidentified|uncultured|environmental)$/i;


=head2 split_lineage_string

 Function: Split a lineage string, e.g. 'Bacteria;Proteobacteria' into an
           arraryref of its individual components using the ';' separator, e.g.
           'Bacteria' and 'Betaproteobact'. Also, clean the arrayref using
           clean_lineage_arr().
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

 Function: Proceed from the end of the array and remove ambiguous taxonomic
           information such as:
              '', 'No blast hit', 'unidentified', 'uncultured', 'environmental',
              'Other', 'g__', 's__', etc
 Usage   : $lineage_arr = clean_lineage_arr($lineage_arr);
 Args    : a lineage arrayref (either taxon names or objects)
 Returns : a lineage arrayref

=cut

func clean_lineage_arr ($lineage_arr) {
   while ( my $elem = $lineage_arr->[-1] ) {
      next if not defined $elem;
      $elem = $elem->node_name if ref $elem;
      if ($elem =~ $ignore_re) {
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
 Args    : a taxon object
 Returns : an arrayref of taxon names

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


=head2 get_lineage_string

 Function: Take a lineage arrayref and return a full lineage string by joining
           the elements using the ';' separator.
 Usage   : my $lineage = get_lineage_string(['Bacteria', 'Proteobacteria']);
             or
           my $lineage = get_lineage_string($taxon1, $taxon2);
 Args    : arrayref of taxon names or objects
 Returns : lineage string

=cut

func get_lineage_string ($lineage_arr) {
   my @names = map { ref $_ ? $_->node_name : $_ } @$lineage_arr;
   return join $sep, @names;
}



1;
