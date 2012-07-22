#! /usr/bin/env perl

# BioPerl script bc_bootstrap
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
use Bio::Community::Tools::CountNormalizer;
use Getopt::Euclid qw(:minimal_keys);


=head1 NAME

bc_bootstrap - Do bootstrapping to normalize community by member count

=head1 SYNOPSIS

  bc_bootstrap -input_files   my_communities.generic   \
               -output_prefix my_converted_communities \
               -sample_size   1000

=head1 DESCRIPTION

This script reads a file containing biological communities and performs
bootstrapping, i.e. repeatedly takes a random subset of the community members,
in order to normalize communities by member count. The output is a file
containing average communities and another containing representative communities.
See L<Bio::Community::Tools::CountNormalizer> for more information.

=head1 REQUIRED ARGUMENTS

=over

=item -if <input_files>... | -input_files <input_files>...

Input file containing the communities to bootstrap. When providing communities
in a format that supports only one community per file (e.g. gaas), you can
provide multiple input files.

=for Euclid:
   input_files.type: readable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item -op <output_prefix> | -output_prefix <output_prefix>

Path and prefix for the output files. Default: output_prefix.default

=for Euclid:
   output_prefix.type: string
   output_prefix.default: 'bc_bootstrap'

=item -ss <sample_size> | -sample_size <sample_size>

Number of members to randomly take at each bootstrap iteration. If omitted, the
sample size defaults to the size (member count) of the smallest community.

=for Euclid:
   sample_size.type: +integer

=item -dt <dist_threshold> | -dist_threshold <dist_threshold>

Keep doing bootstrap iterations until the distance between the current average
community and the average community at the previous iteration becomes less than
the specified threshold.

=for Euclid:
   dist_threshold.type: +num
   dist_threshold.default: 1e-3

=item -nr <num_repetitions> | -num_repetitions <num_repetitions>

Perform the specified number of bootstrap iterations instead of a dynamic number
of iterations based on a distance threshold.

=for Euclid:
   num_repetitions.type: +integer

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


bootstrap( $ARGV{'input_files'}, $ARGV{'output_prefix'}, $ARGV{'sample_size'},
   $ARGV{'dist_threshold'}, $ARGV{'num_repetitions'} );
exit;


func bootstrap ($input_files, $output_prefix, $sample_size, $dist_threshold,
   $num_repetitions) {

   # Read input communities
   my $communities = [];
   my $format;
   for my $input_file (@$input_files) {
      my $in = Bio::Community::IO->new( -file => $input_file );
      $format = $in->format;
      while (my $community = $in->next_community) {
         push @$communities, $community;
      }
      $in->close;
   }

   # Prepare normalizer
   my $normalizer = Bio::Community::Tools::CountNormalizer->new(
      -communities => $communities,
      -verbose     => 1,
   );
   if (defined $dist_threshold) {
      $normalizer->threshold($dist_threshold);
   }
   if (defined $num_repetitions) {
      $normalizer->repetitions($num_repetitions);
   }
   if (defined $sample_size) {
      $normalizer->sample_size($sample_size);
   }

   # Bootstrap and write average communities
   my $out_communities = $normalizer->get_average_communities;
   write_communities($out_communities, $output_prefix, $format, 'average');

   # Calculate and write representative communities
   $out_communities = $normalizer->get_representative_communities;
   write_communities($out_communities, $output_prefix, $format, 'representative');

   return 1;
}


func write_communities ($communities, $output_prefix, $output_format, $type='') {
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
}
