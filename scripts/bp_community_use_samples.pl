#! /usr/bin/env perl

# BioPerl script bp_community_use_samples
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


use strict;
use warnings;
use Bio::Community;
use Bio::Community::IO;
use Getopt::Euclid qw(:minimal_keys);


=head1 NAME

bp_community_use_samples - Include, delete or merge samples

=head1 SYNOPSIS

  bp_community_use_samples -input_files   communities.generic              \
                           -exclude_names community1                       \
                           -merge_names   community2 community5            \
                           -merge_names   community7 community8 community9 \
                           -output_prefix processed_communities

=head1 DESCRIPTION

This script reads files containing biological communities and delete or merge
the specified communities. See L<Bio::Community> for more information.

=head1 REQUIRED ARGUMENTS

=over

=item -if <input_files>... | -input_files <input_files>...

Input file containing the communities to manipulate. When converting from a
format that supports only one community per file (e.g. gaas) to a format that
holds several communities per file (e.g. qiime), you can provide multiple input
files.

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
   output_prefix.default: 'bp_community_use_samples'

=item -in <include_names>... | -include_names <include_names>...

If names of communities are specified, only these communities will be
included in the output file.

=for Euclid:
   include_names.type: string

=item -en <exclude_names>... | -exclude_names <exclude_names>...

If names of communities are specified, these communities will be excluded from
the output file.

=for Euclid:
   exclude_names.type: string

=item -mn <merge_names>... | -merge_names <merge_names>...

Specify the name of the communities to merge. Use this option multiple time if
you need to merge multiple sets of communities. The count of the members of
these communities are added.

=for Euclid:
   repeatable
   merge_names.type: string

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


manip( $ARGV{'input_files'}  , $ARGV{'output_prefix'}, $ARGV{'include_names'},
       $ARGV{'exclude_names'}, $ARGV{'merge_names'} );

exit;


sub manip {
   my ($input_files, $output_prefix, $include_names, $exclude_names, $merge_names) = @_;

   # Prepare communities to include or exclude 
   my $nof_includes = 0;
   my %includes;
   if (defined $include_names) {
      $nof_includes = scalar @$include_names;
      %includes = map { $_ => undef } @$include_names;
   }
   my %excludes;
   if (defined $exclude_names) {
      %excludes = map { $_ => undef } @$exclude_names;
   }
   while ( my ($include, undef) = each %includes ) {
      if (exists $excludes{$include}) {
         die "Error: Cannot request to include and exclude community '$include' at the same time\n";
      }
   }

   # Read input communities, exclude or include as needed
   my @communities;
   my $format;
   for my $input_file (@$input_files) {
      print "Reading file '$input_file'\n";
      my $in = Bio::Community::IO->new( -file => $input_file );
      $format = $in->format;
      while (my $community = $in->next_community) {
         my $name = $community->name;
         if ( $nof_includes > 0 ) {
            # Only include specifically requested communities
            if ( exists $includes{$name} ) {
               push @communities, $community;
            }
         } else {
            if ( not exists $excludes{$name} ) {
               push @communities, $community;

            } # else it is specifically excluded
         }
      }
      $in->close;
   }

   # Merge communities
   if (defined $merge_names) {
      my %communities_hash;
      for my $community (@communities) {
         my $name = $community->name;
         if (exists $communities_hash{$name}) {
            die "Error: Ambiguous community names. Several communities named ".
               "identically, as '$name',  were given as input.\n";
         } else {
            $communities_hash{$name} = $community;
         }
      }
      for my $merge_set (@$merge_names) {
         my $merged_name = join('+', @$merge_set);
         print "Processing $merged_name\n";
         my $merged_community = Bio::Community->new( -name => $merged_name );
         for my $name (@$merge_set) {
            my $community = delete $communities_hash{$name} ||
               die "Error: Could not find requested community, '$name' in the ".
                  "input.\n";
            while ( my $member = $community->next_member ) {
               my $count = $community->get_count($member);
               $merged_community->add_member($member, $count);
            }
         }
         $communities_hash{$merged_name} = $merged_community;
      }
      @communities = values %communities_hash;
   }

   # Write output communities
   if (scalar @communities == 0) {
      warn "Warning: No communities to write\n";
   } else {
      my $multiple_communities = Bio::Community::IO->new(-format=>$format)->multiple_communities;
      my $num = 0;
      my $out;
      my $output_file;
      for my $community (@communities) {
         if (not defined $out) {
            if ($multiple_communities) {
               $output_file = $output_prefix.'.'.$format;
            } else {
              $num++;
               $output_file = $output_prefix.'_'.$num.'.'.$format;
            }
            $out = Bio::Community::IO->new(
               -format => $format,
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

   return 1;
}
