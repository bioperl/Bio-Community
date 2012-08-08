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
use Bio::Community::Meta;
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
another format. This will also remove communities with no members or species
with 0 counts in all communities.

=head1 REQUIRED ARGUMENTS

=over

=item -if <input_files>... | -input_files <input_files>...

Input files containing the communities to convert. All files must have the same
format, which can be one of generic (tab-delimited table), qiime, gaas or
unifrac. See L<Bio::Community::IO> for more information on these format. When
converting from a format that supports only one community per file (e.g. gaas)
to a format that holds several communities per file (e.g. qiime), you can
provide multiple input files.

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
table), qiime, gaas or unifrac. Default: same as input format

=for Euclid:
   output_format.type: string

=back

=cut

#=item -mi <member_identifier> | -member_identifier <merge_identifier>

#When merging communities from different files, two methods can be be used to
#decide if members of different communities are the same or not: 'id' or 'desc'.
#The 'id' method will assume that members with the same ID are the same. However,
#when this is not the case, you can decide that members that have the same
#description are the same using the 'desc' method. Default: merge_identifier.default

#=for Euclid:
#   member_identifier.type: string
#   member_identifier.default: 'id'

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


convert( $ARGV{'input_files'}, $ARGV{'output_prefix'}, $ARGV{'output_format'},
         $ARGV{'member_identifier'} );

exit;


func convert ($input_files, $output_prefix, $output_format, $member_identifier) {

   # Read input communities
   my $meta = Bio::Community::Meta->new;
   for my $input_file (@$input_files) {
      print "Reading file '$input_file'\n";
      my $in = Bio::Community::IO->new( -file => $input_file );
      if (not defined $output_format) {
         $output_format = $in->format;
      }
      while (my $community = $in->next_community) {
         $meta->add_communities([$community]);
      }
      $in->close;
   }

   # Write output communities
   my $multiple_communities = Bio::Community::IO->new(-format=>$output_format)->multiple_communities;
   my $num = 0;
   my $out;
   my $output_file;
   my $num_communities = $meta->get_communities_count;
   while (my $community = $meta->next_community) {
      if (not defined $out) {
         if ($multiple_communities || ($num_communities <= 1)) {
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
