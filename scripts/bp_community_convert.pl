#! /usr/bin/env perl

# BioPerl script bp_community_convert
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


use strict;
use warnings;
use Bio::Community::IO;
use Getopt::Euclid qw(:minimal_keys);


=head1 NAME

bp_community_convert - Convert files of communities from one format to another

=head1 SYNOPSIS

  bp_community_convert -input_files   my_communities.qiime     \
                       -output_format generic                  \
                       -output_prefix my_converted_communities

=head1 DESCRIPTION

This script reads files containing biological communities and converts them to
another format. Supported formats are: generic (tab-delimited table), qiime and
gaas. See L<Bio::Community::IO> for more information.

=head1 REQUIRED ARGUMENTS

=over

=item -if <input_files>... | -input_files <input_files>...

Input file containing the communities to convert. When converting from a format
that supports only one community per file (e.g. gaas) to a format that holds
several communities per file (e.g. qiime), you can provide multiple input files.

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
   output_prefix.default: 'bp_community_convert'

=item -of <output_format> | -output_format <output_format>

File format to use for writing the output communities, e.g. generic (tab-delimited
table), qiime or gaas. Default: output_format.default

=for Euclid:
   output_format.type: string
   output_format.default: 'generic'

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


convert( $ARGV{'input_files'}  , $ARGV{'output_prefix'}, $ARGV{'output_format'},
         $ARGV{'include_names'}, $ARGV{'exclude_names'} );

exit;


sub convert {
   my ($input_files, $output_prefix, $output_format, $include_names, $exclude_names) = @_;

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

   # Read input communities
   my @communities;
   for my $input_file (@$input_files) {
      print "Reading file '$input_file'\n";
      my $in = Bio::Community::IO->new( -file => $input_file );
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
