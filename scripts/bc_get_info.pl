#! /usr/bin/env perl

# BioPerl script bc_get_info
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

bc_get_info - Display list of community names, member IDs and description

=head1 SYNOPSIS

  bc_get_info -input_files   my_communities.generic   \
              -output_prefix my_converted_communities \
              -info_type     'desc'

=head1 DESCRIPTION

This script reads a file containing biological communities and retrieves basic
information from it, such as the names of the communities it contains, or the
ID and description of their members. The information is displayed on screen
unless an output prefix is provided.

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

=item -op <output_prefix> | -output_prefix <output_prefix>

Path and prefix for the output file. The output is displayed on screen if no 
output prefix is provided. Default: output_prefix.default

=for Euclid:
   output_prefix.type: string
   output_prefix.default: ''

=item -it <info_type> | -info_type <info_type>

Type of information to return, either: 'name' to return community names (in
order of appearance), 'desc' for members IDs (in no specific order), or 'id' for
member description (in no specific order). Default: info_type.default

=for Euclid:
   info_type.type: /(name|id|desc)/
   info_type.default: 'name'

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


get_info( $ARGV{'input_files'}, $ARGV{'output_prefix'}, $ARGV{'info_type'} );
exit;


func get_info ($input_files, $output_prefix, $info_type) {

   # Read input communities
   my $meta = Bio::Community::Meta->new();
   my $communities = [];
   my $format;
   for my $input_file (@$input_files) {
      my $in = Bio::Community::IO->new( -file => $input_file );
      $format = $in->format;
      while (my $community = $in->next_community) {
         $meta->add_communities([$community]);
      }
      $in->close;
   }

   # Prepare output
   my $out;
   if ($output_prefix) {
      my $output_file = $output_prefix.'.txt';
      open $out, '>', $output_file or die "Error: Could not write file $output_file\n$!\n";
   } else {
      $out = \*STDOUT;
   }

   # Fetch desired info
   if ($info_type eq 'name') {
      while (my $community = $meta->next_community) {
         print $out $community->name."\n";
      }
   } elsif ($info_type eq 'desc') {
      for my $member (@{$meta->get_all_members}) {
         print $out $member->desc."\n";
      }
   } elsif ($info_type eq 'id') {
      for my $member (@{$meta->get_all_members}) {
         print $out $member->id."\n";
      }
   } else {
      die "Error: $info_type is not a valid value for <info_type>\n";
   }

   close $out;

   return 1;
}

