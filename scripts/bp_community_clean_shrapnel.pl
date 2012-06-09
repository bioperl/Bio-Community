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
use Bio::Community::IO;
use Bio::Community::Tools::ShrapnelCleaner;
use Getopt::Euclid qw(:minimal_keys);


=head1 NAME

bp_community_clean_shrapnel - Remove low-count, low-abundance community members

=head1 SYNOPSIS

  bp_community_clean_shrapnel -input_files          communities.generic         \
                              -count_threshold      1                           \
                              -prevalence_threshold 1                           \
                              -output_prefix        cleaned_communities.generic

=head1 DESCRIPTION

This script takes communities, removes shrapnel (low abundance, low prevalence
members that are likely to be the result of sequencing errors) and saves the
resulting communities in output files. By default, the cleaner removes only
singletons, i.e. community members that appear in only one community (prevalence
of 1) and have only 1 count. You can specify your own count and prevalence
thresholds though. See L<Bio::Community::Tools::ShrapnelCleaner> for more
information.

=head1 REQUIRED ARGUMENTS

=over

=item -if <input_files>... | -input_files <input_files>...

Input file containing the communities to process. When providing communities
in a format that supports only one community per file (e.g. gaas), you can
provide multiple input files.

=for Euclid:
   input_files.type: readable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item -ct <count_threshold> | -count_threshold <count_threshold>

Provide a count threshold for shrapnel removal. Community members with a count
equal or lower than this threshold are removed (provided they also meet
<prevalence_threshold>). Default: count_threshold.default

=for Euclid:
   count_threshold.type: integer
   count_threshold.default: 1

=item -pt <prevalence_threshold> | -prevalence_threshold <prevalence_threshold>

Provide a prevalence threshold for singleton removal. Community members with a
prevalence (number of communities that the member is found in) equal or lower
than this threshold are removed (provided they also meet the count_threshold).
Default: prevalence_threshold.default

=for Euclid:
   prevalence_threshold.type: integer
   prevalence_threshold.default: 1

=item -op <output_prefix> | -output_prefix <output_prefix>

Path and prefix for the output files. Default: output_prefix.default

=for Euclid:
   output_prefix.type: string
   output_prefix.default: 'bp_community_clean_shrapnel'

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

clean( $ARGV{'input_files'}         , $ARGV{'count_threshold'},
       $ARGV{'prevalence_threshold'}, $ARGV{'output_prefix'}    );
exit;


sub clean {
   my ($input_files, $count_threshold, $prevalence_threshold, $output_prefix) = @_;

   # Read input communities and do weight assignment
   my $communities = [];
   my $format;
   for my $input_file (@$input_files) {
      my $in = Bio::Community::IO->new(
         -file => $input_file,
      );
      $format = $in->format;
      while (my $community = $in->next_community) {
         push @$communities, $community;
      }
      $in->close;
   }

   # Remove shrapnel communities
   my $cleaner = Bio::Community::Tools::ShrapnelCleaner->new(
      -communities          => $communities,
      -count_threshold      => $count_threshold,
      -prevalence_threshold => $prevalence_threshold,
   );
   $communities = $cleaner->clean;

   # Write results, converting to relative abundance if desired
   write_communities($communities, $output_prefix, $format);

   return 1;
}


sub write_communities {
   my ($communities, $output_prefix, $output_format) = @_;
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
