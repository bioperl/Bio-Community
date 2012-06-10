#! /usr/bin/env perl

# BioPerl script bp_community_measure_distance
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


use strict;
use warnings;
use Bio::Community::IO;
use Bio::Community::Tools::Ruler;
use Getopt::Euclid qw(:minimal_keys);


=head1 NAME

bp_community_measure_distance - Measure the distance or beta-diversity between communities

=head1 SYNOPSIS

  bp_community_measure_distance -input_files   communities.generic      \
                                -dist_type     'hellinger'              \
                              ### pair_file  : a file containing the pairs of sample
                              ###    to calculate (output_type cannot be matrix)        \
                              ### ouput_type : either matrix format or pairwise format
                                -output_prefix community_distance

=head1 DESCRIPTION

This script reads files containing biological communities and calculate the
distance or beta-diversity that separates them. The output is a tab-delimited
matrix containing the distance between all communities. See
L<Bio::Community::Tools::Ruler> for more details. Note that distances and beta-
diversity metrics are based on relative abundances. Hence, any weight you
provide will affect the results.

=head1 REQUIRED ARGUMENTS

=over

=item -if <input_files>... | -input_files <input_files>...

Input file containing the communities to manipulate. When providing communities
in a format that supports only one community per file (e.g. gaas), you can
provide multiple input files.

=for Euclid:
   input_files.type: readable

=back

=head1 OPTIONAL ARGUMENTS

=over

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

=item -op <output_prefix> | -output_prefix <output_prefix>

Path and prefix for the output files. Default: output_prefix.default

=for Euclid:
   output_prefix.type: string
   output_prefix.default: 'bp_community_measure_distance'

=item -dt <dist_type> | -dist_type <dist_type>

The type of distance or beta-diversity metric to calculate: 1-norm, euclidean
(2-norm), hellinger, infinity-norm, bray-curtis... Default: dist_type.default

=for Euclid:
   dist_type.type: string
   dist_type.default: 'euclidean'

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


calc_dist( $ARGV{'input_files'}  , $ARGV{'weight_files'}, $ARGV{'weight_assign'},
           $ARGV{'output_prefix'}, $ARGV{'dist_type'} );
exit;


sub calc_dist {
   my ($input_files, $weight_files, $weight_assign, $output_prefix, $dist_type) = @_;

   # Read input communities
   my $communities = [];
   for my $input_file (@$input_files) {
      print "Reading file '$input_file'\n";
      my $in = Bio::Community::IO->new(
         -file          => $input_file,
         -weight_assign => $weight_assign,
      );
      if ($weight_files) {
         $in->weight_files($weight_files);
      }
      while (my $community = $in->next_community) {
         push @$communities, $community;
      }
      $in->close;
   }

   # Calculate distances
   my $out_file = $output_prefix.'.txt';
   print "Writing distances to file $out_file\n";
   open my $out, '>', $out_file or die "Error: Could not write file $out_file\n";
   my $num_communities = scalar @$communities;
   for my $i (0 .. $num_communities - 1) {
      my $community_1 = $communities->[$i];
      for my $j ($i + 1 .. $num_communities -1) {
         my $community_2 = $communities->[$j];
         my $distance = Bio::Community::Tools::Ruler->new(
            -communities => [$community_1, $community_2],
            -type        => $dist_type,
         )->get_distance;
         print $out $community_1->name."\t".$community_2->name."\t".$distance."\n";
      }
   }
   close $out;

   return 1;
}
