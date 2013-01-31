#! /usr/bin/env perl

# BioPerl script bc_measure_distance
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
use Bio::Community::Meta::Beta;
use Getopt::Euclid qw(:minimal_keys);


=head1 NAME

bc_measure_distance - Measure beta-diversity between communities

=head1 SYNOPSIS

  bc_measure_distance -input_files   communities.generic      \
                      -dist_type     'hellinger'              \
                      -output_prefix community_distance

=head1 DESCRIPTION

This script reads files containing biological communities and calculate how
dissimilar they are (beta diversity). The output is a tab-delimited file
containing the beta diversity between all pairs of communities. The columns of
this file contain the name of the first community, of the second community, and
their beta diversity, respectively. See L<Bio::Community::Meta::Beta> for more
details. Note that beta diversity metrics are based on relative abundances.
Hence, any weight you provide will affect the results.

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
   output_prefix.default: 'bc_distance'

=item -dt <dist_type> | -dist_type <dist_type>

The type of distance or beta-diversity metric to calculate: 1-norm, euclidean
(2-norm), hellinger, infinity-norm, bray-curtis... Default: dist_type.default

=for Euclid:
   dist_type.type: string
   dist_type.default: 'euclidean'

=item -pf <pair_files>... | -pair_files <pair_files>...

Input file specifying the pairs of communities for which to calculate the
beta-diversity. Each line of a file of pairs should have the name of two
communities, separated by a tab. For each file of pairs, there will be a
corresponding output file.

=for Euclid:
   pair_files.type: readable

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
           $ARGV{'output_prefix'}, $ARGV{'dist_type'}   , $ARGV{'pair_files'}    );
exit;


# TODO: implement option for matrix output


func calc_dist ($input_files, $weight_files, $weight_assign, $output_prefix,
   $dist_type, $pair_files) {

   # Read input communities
   my $meta = Bio::Community::Meta->new;
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
         $meta->add_communities([$community]);
      }
      $in->close;
   }

   # Calculate beta diversity
   if ($pair_files) {
      _process_specific_pairs($meta, $dist_type, $output_prefix, $pair_files);
   } else {
      _process_all_pairs($meta, $dist_type, $output_prefix);
   }

   return 1;
}


func _process_specific_pairs ($meta, $dist_type, $output_prefix, $pair_files) {
   my $i = 0;
   for my $pair_file (@$pair_files) {
      $i++;
      print "Reading pair file $pair_file...\n";
      my $pairs = _read_pair_file($pair_file);
      my $out_file = $output_prefix.'_group'.$i.'.txt';
      print "Writing beta diversity to file $out_file\n";
      open my $out, '>', $out_file or die "Error: Could not write file $out_file\n";
      for my $pair (@$pairs) {
         my $name1 = $pair->[0];
         my $community1 = $meta->get_community_by_name($name1) or
            die "Error: Community $name1 was not found in the provided community file";
         my $name2 = $pair->[1];
         my $community2 = $meta->get_community_by_name($name2) or
            die "Error: Community $name2 was not found in the provided community file";
         my $beta_val = Bio::Community::Meta::Beta->new(
            -metacommunity => Bio::Community::Meta->new(-communities => [$community1, $community2]),
            -type          => $dist_type,
         )->get_beta;
         print $out $community1->name."\t".$community2->name."\t".$beta_val."\n";
      }
      close $out;
   }
   return 1;
}


func _process_all_pairs ($meta, $dist_type, $output_prefix) {
   # Calculate beta diversity for all pairs of communities
   my $out_file = $output_prefix.'.txt';
   print "Writing beta diversity to file $out_file\n";
   open my $out, '>', $out_file or die "Error: Could not write file $out_file\n";
   my $communities = $meta->get_all_communities;
   my $num_communities = scalar @$communities;
   for my $i (0 .. $num_communities - 1) {
      my $community1 = $communities->[$i];
      for my $j ($i + 1 .. $num_communities -1) {
         my $community2 = $communities->[$j];
         my $beta_val = Bio::Community::Meta::Beta->new(
            -metacommunity => Bio::Community::Meta->new(-communities => [$community1, $community2]),
            -type          => $dist_type,
         )->get_beta;
         print $out $community1->name."\t".$community2->name."\t".$beta_val."\n";
      }
   }
   close $out;
   return 1;
}


func _read_pair_file ($file) {
   # Read a file of pairs and return an arrayref of all pairs found
   my @pairs;
   open my $in, '<', $file or die "Error: Could not read file $file\n$!\n";
   while (my $line = <$in>) {
      chomp $line;
      next if $line =~ m/^#/;
      next if $line =~ m/^\s*$/;
      my @pair = split /\t/, $line;
      if (scalar @pair != 2) {
         warn "Line '$line' does not seem to specify a pair of communities. Skipping it\n";
         next;
      }
      push @pairs, \@pair;
   }
   close $in;
   return \@pairs;
}
