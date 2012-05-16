#! /usr/bin/env perl

# BioPerl script bp_community_summarize
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


use strict;
use warnings;
use Bio::DB::Taxonomy;
use Bio::Community::IO;
use Bio::Community::Tools::Summarizer;
use Getopt::Euclid qw(:minimal_keys);


=head1 NAME

bp_community_summarize - Summarize community composition

=head1 SYNOPSIS

  bp_community_summarize -input_files   my_communities.generic   \
                         -output_prefix my_converted_communities

=head1 DESCRIPTION

This script reads a file containing biological communities and performs
summarizes it. In practice, this means transforming community member counts
into relative abundance (taking into account any weights that members could have).
Other popular practices include grouping members with a low abundance together
into an 'Other' group and representing the taxonomy at a higher level, such as
phylum level instead of specied level. See L<Bio::Community::Tools::Summarizer>
for more information.

=head1 REQUIRED ARGUMENTS

=over

=item -if <input_files>... | -input_files <input_files>...

Input file containing the communities to convert. When using a file format
that supports only one community per file (e.g. gaas), you can provide multiple
input files.

=for Euclid:
   input_files.type: readable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item -op <output_prefix> | -output_prefix <output_prefix>

Path and prefix for the output files. Default: output_prefix.default

=for Euclid:
   output_prefix.type: string
   output_prefix.default: 'bp_community_summarize'

=item -ra <relative_abundance> | -relative_abundance <relative_abundance>

Convert counts into relative abundances (taking into account weights): 1 (yes),
0 (no). Default: relative_abundance.default

=for Euclid:
   relative_abundance.type: integer, relative_abundance == 0 || relative_abundance == 1
   relative_abundance.type.error: <relative_abundance> must be 0 or 1 (not relative_abundance)
   relative_abundance.default: 1

=item -ol <other_lt> | -other_lt <other_lt>

Group community members with a relative abundance less than the specified
threshold (in %) into an 'Other' group. Default: other_lt.default %

=for Euclid:
   other_lt.type: integer, other_lt >= 0 && other_lt <= 100
   other_lt.type.error: <other_lt> must be between 0 and 100 (not other_lt)
   other_lt.default: 1

=item -wf <weight_files>... | -weight_files <weight_files>...

Tab-delimited files containing weights to assign to the community members.

=for Euclid:
   weight_files.type: readable

=item -wa <weight_assign> | -weight_assign <weight_assign>

When using a files of weights, define what to do for community members whose
weight is not specified in the weight file (default: weight_assign.default):

* $num : assign to the member the arbitrary weight $num provided

* average : assign to the member the average weight in this file.

* ancestor: go up the taxonomic lineage of the member and assign to it the weight
of the first ancestor that has a weight in the weights file. Fall back to the
'average' method if no taxonomic information is available for this member
(for example a member with no BLAST hit).

=for Euclid:
   weight_assign.type: string
   weight_assign.default: 'ancestor'

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

=cut

summarize( $ARGV{'input_files'} , $ARGV{'output_prefix'}, $ARGV{'relative_abundance'},
           $ARGV{'weight_files'}, $ARGV{'weight_assign'}, $ARGV{'other_lt'} );
exit;


sub summarize {
   my ($input_files, $output_prefix, $relative_abundance, $weight_files,
      $weight_assign, $other_lt) = @_;

   # Read input communities and do weight assignment
   my $communities = [];
   my $format;
   for my $input_file (@$input_files) {
      my $in = Bio::Community::IO->new(
         -file          => $input_file,
         -weight_assign => $weight_assign,
         #### Consider building the taxonomy only when needed, i.e. when taxonomy summary or weight assignment by taxonomy is required
         -taxonomy      => Bio::DB::Taxonomy->new( -source => 'list' ), # build taxonomy on-the-fly
      );
      if ($weight_files) {
         $in->weight_files($weight_files);
      }
      $format = $in->format;
      while (my $community = $in->next_community) {
         push @$communities, $community;
      }
      $in->close;
   }

   # Summarize communities
   my $summarized_communities;
   if ($other_lt) {
      my $summarizer = Bio::Community::Tools::Summarizer->new(
         -communities => $communities,
         -by_rel_ab   => ['<', $other_lt],
      );
      $summarized_communities = $summarizer->get_summaries;
   } else {
      $summarized_communities = $communities;
   }

   # Write results, converting to relative abundance if desired
   write_communities($summarized_communities, $output_prefix, $format, '', $relative_abundance);

   return 1;
}


sub write_communities {
   my ($communities, $output_prefix, $output_format, $type, $relative_abundance) = @_;
   $type ||= '';
   my $multiple_communities = Bio::Community::IO->new(-format=>$output_format)->multiple_communities;
   my $num = 0;
   my $out;
   my $output_file = '';
   for my $community (@$communities) {
      if (not defined $out) {
         if ($multiple_communities) {
            $output_file = $output_prefix;
         } else {
            $num++;
            $output_file = $output_prefix.'_'.$num;
         }
         if ($type) {
            $output_file .= '_'.$type;
         }
         $output_file .= '.'.$output_format;
         $out = Bio::Community::IO->new(
            -format         => $output_format,
            -file           => '>'.$output_file,
            -abundance_type => $relative_abundance ? 'percentage' : 'count',
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
}
