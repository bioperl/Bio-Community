#! /usr/bin/env perl

# BioPerl script bc_convert_files
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


use strict;
use warnings;
use Method::Signatures;
use Bio::Community::IO;
use Getopt::Euclid qw(:minimal_keys);


=head1 NAME

bc_convert_files - Merge/split community files and convert between formats

=head1 SYNOPSIS

  # Format conversion
  bc_convert_files -input_files   my_communities.qiime     \
                   -output_format generic                  \
                   -output_prefix my_converted_communities

  # Merging communities
  bc_convert_files -input_files   some_communities.generic other_communities.generic \
                   -output_format generic                  \
                   -output_prefix my_converted_communities

=head1 DESCRIPTION

This script reads files containing biological communities and converts them to
another format.

=head1 REQUIRED ARGUMENTS

=over

=item -if <input_files>... | -input_files <input_files>...

Input file containing the communities to convert. Supported formats are: generic
(tab-delimited table), qiime, gaas and unifrac. See L<Bio::Community::IO> for
more information. When converting from a format that supports only one community
per file (e.g. gaas) to a format that holds several communities per file (e.g.
qiime), you can provide multiple input files.

=for Euclid:
   input_files.type: readable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item -op <output_prefix> | -output_prefix <output_prefix>

Path and prefix for the output files. Several output files will be created if
the requested output format can only hold a single community. Default: output_prefix.default

=for Euclid:
   output_prefix.type: string
   output_prefix.default: 'bc_convert_files'

=item -of <output_format> | -output_format <output_format>

File format to use for writing the output communities, e.g. generic (tab-delimited
table), qiime or gaas. Default: output_format.default

=for Euclid:
   output_format.type: string
   output_format.default: 'generic'

=back

=cut

#=item -mi <member_identifier> | -member_identifier <merge_identifier>
#
#Pick how to decide if members in different communities are the same or not:
#
#Default: merge_identifier.default
#
#=for Euclid:
#   member_identifier.type: string
#   member_identifier.default: 'bc_convert_files'

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


convert( $ARGV{'input_files'}, $ARGV{'output_prefix'}, $ARGV{'output_format'} );

exit;


func convert ($input_files, $output_prefix, $output_format) {

   # Read input communities
   my @communities;
   for my $input_file (@$input_files) {
      print "Reading file '$input_file'\n";
      my $in = Bio::Community::IO->new( -file => $input_file );
      while (my $community = $in->next_community) {
         push @communities, $community;
      }
      $in->close;
   }

   # Write output communities
   my $multiple_communities = Bio::Community::IO->new(-format=>$output_format)->multiple_communities;
   my $num = 0;
   my $out;
   my $output_file;
   for my $community (@communities) {
      if (not defined $out) {
         if ($multiple_communities) {
            $output_file = $output_prefix.'.'.$output_format;
         } else {
            $num++;
            $output_file = $output_prefix.'_'.$num.'.'.$output_format;
         }
         $out = Bio::Community::IO->new(
            -format => $output_format,
            -file   => '>'.$output_file,
         );
      }
      print "Writing community '".$community->name."' to file '$output_file'\n";
      $out->write_community($community);
      if (not $multiple_communities) {
         $out->close;
         $out = undef;
      }
   }
   if (defined $out) {
      $out->close;
   }

   return 1;
}
