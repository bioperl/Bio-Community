# BioPerl module for Bio::Community::IO::biom
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::IO::biom - Driver to read and write files in the sparse BIOM format

=head1 SYNOPSIS

   my $in = Bio::Community::IO->new( -file => 'biom_communities.txt', -format => 'biom' );

   # See Bio::Community::IO for more information

=head1 DESCRIPTION

This Bio::Community::IO::biom driver reads and writes files in the BIOM format
version 1.0 described at L<http://biom-format.org/documentation/format_versions/biom-1.0.html>.
Multiple communities and additional metadata can be recorded in a BIOM file.
Here is an example of minimal sparse BIOM file:

  {
      "id":null,
      "format": "Biological Observation Matrix 0.9.1-dev",
      "format_url": "http://biom-format.org",
      "type": "OTU table",
       "generated_by": "QIIME revision 1.4.0-dev",
      "date": "2011-12-19T19:00:00",
      "rows":[
              {"id":"GG_OTU_1", "metadata":null},
              {"id":"GG_OTU_2", "metadata":null},
              {"id":"GG_OTU_3", "metadata":null},
              {"id":"GG_OTU_4", "metadata":null},
              {"id":"GG_OTU_5", "metadata":null}
          ],
      "columns": [
              {"id":"Sample1", "metadata":null},
              {"id":"Sample2", "metadata":null},
              {"id":"Sample3", "metadata":null},
              {"id":"Sample4", "metadata":null},
              {"id":"Sample5", "metadata":null},
              {"id":"Sample6", "metadata":null}
          ],
      "matrix_type": "sparse",
      "matrix_element_type": "int",
      "shape": [5, 6],
      "data":[[0,2,1],
              [1,0,5],
              [1,1,1],
              [1,3,2],
              [1,4,3],
              [1,5,1],
              [2,2,1],
              [2,3,4],
              [2,4,2],
              [3,0,2],
              [3,1,1],
              [3,2,1],
              [3,5,1],
              [4,1,1],
              [4,2,1]
             ]
  }

Rows and columns can be expressed in a richer way, e.g.:

  {"id":"GG_OTU_1", "metadata":{"taxonomy":["k__Bacteria", "p__Proteobacteria", "c__Gammaproteobacteria", "o__Enterobacteriales", "f__Enterobacteriaceae", "g__Escherichia", "s__"]}},

  {"id":"Sample1", "metadata":{
                           "BarcodeSequence":"CGCTTATCGAGA",
                           "LinkerPrimerSequence":"CATGCTGCCTCCCGTAGGAGT",
                           "BODY_SITE":"gut",
                           "Description":"human gut"}},

###For each Bio::Community::Member $member generated from a QIIME file, $member->id()
###contains the OTU ID, while $member->desc() holds the content of the consensus
###lineage field.

=head1 CONSTRUCTOR

See L<Bio::Community::IO>.

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


package Bio::Community::IO::biom;

use Moose;
use Method::Signatures;
use namespace::autoclean;
use Bio::Community::Member;
use JSON qw( decode_json encode_json );

extends 'Bio::Community::IO';
with 'Bio::Community::Role::IO';
###with 'Bio::Community::Role::IO',
###     'Bio::Community::Role::Table';

our $multiple_communities   =  1;      # format supports several communities per file
#### sorting only effective for first community???
our $default_sort_members   =  0;      # unsorted
our $default_abundance_type = 'count'; # absolute count (positive integer)
our $default_missing_string =  0;      # empty members get a '0'


###around BUILDARGS => func ($orig, $class, %args) {
###   $args{-start_line} = 2; 
###   return $class->$orig(%args);
###};


###before 'close' => sub {
###   # Add taxonomy (desc) if available
###   my ($self) = @_;
###   my $col = $self->_col + 1;
###   my $descs = $self->_line2desc;
###   if ( scalar keys %{$descs} ) {
###      $self->_set_value(1, $col, 'Consensus Lineage');
###      while ( my ($line, $desc) = each %$descs ) {
###         $self->_set_value($line, $col, $desc);
###      }
###   }
###};


###has '_first_community' => (
###   is => 'rw',
###   isa => 'Bool',
###   required => 0,
###   init_arg => undef,
###   default => 1,
###   lazy => 1,
###);


###has '_line' => (
###   is => 'rw',
###   isa => 'PositiveInt',
###   required => 0,
###   init_arg => undef,
###   default => 1,
###   lazy => 1,
###);


###has '_col' => (
###   is => 'rw',
###   isa => 'PositiveInt',
###   required => 0,
###   init_arg => undef,
###   default => 1,
###   lazy => 1,
###);


###has '_skip_last_col' => (
###   is => 'rw',
###   isa => 'Bool',
###   required => 0,
###   init_arg => undef,
###   default => 0,
###   lazy => 1,
###);


###has '_members' => (
###   is => 'rw',
###   isa => 'ArrayRef', # ArrayRef[Bio::Community::Member] but keep it lean
###   required => 0,
###   init_arg => undef,
###   default => sub { [] },
###   lazy => 1,
###   predicate => '_has_members',
###);


###has '_id2line' => (
###   is => 'rw',
###   isa => 'HashRef', # HashRef[String] but keep it lean
###   required => 0,
###   init_arg => undef,
###   default => sub { {} },
###   lazy => 1,
###);


###has '_line2desc' => (
###   is => 'rw',
###   #isa => 'HashRef', # HashRef[PositiveInt] but keep it lean
###   required => 0,
###   init_arg => undef,
###   default => sub { {} },
###   lazy => 1,
###);


###method _generate_members () {
###   # Make members from the first column. Also, find out if they have a taxonomy.

###   # Does the last column contain the taxonomy?
###   my $first_col_header = $self->_get_value(1, 1);
###   my $taxo_col;
###   if ($first_col_header =~ m/OTU ID/i) {
###      my $last_col_header = $self->_get_value(1, $self->_get_max_col);
###      if ( (defined $last_col_header) && ($last_col_header =~ m/consensus\s*lineage/i) ) {
###         $taxo_col = $self->_get_max_col;
###         $self->_skip_last_col(1);
###      }
###   } else {
###      $self->warn("Could not recognize the headers of the QIIME OTU table, but ".
###         "assuming that a valid table was provided\n");
###   }

###   # What are the members?
###   my @members;
###   my $col = 1;
###   my $line = 1; # first line of the table is a header
###   for my $line (2 .. $self->_get_max_line) {
###      my $member;
###      # Get OTU ID if possible
###      my $otu_id = $self->_get_value($line, $col);
###      $member = Bio::Community::Member->new( -id => $otu_id );
###      # Get taxonomic assignment if possible
###      if (defined $taxo_col) {
###         my $taxo_desc = $self->_get_value($line, $taxo_col);
###         $member->desc( $taxo_desc );
###         $self->_attach_taxon($member, $taxo_desc, 1);
###      }
###      $self->_attach_weights($member);
###      push @members, $member;
###   }
###   $self->_members(\@members);
###}


###method next_member () {
###   my ($member, $count);
###   my $line = $self->_line;
###   while ( $line++ ) {
###      # Get the abundance of the member (undef if out-of-bounds)
###      $count = $self->_get_value($line, $self->_col);
###      # No more members for this community.
###      last if not defined $count;
###      # Skip members with no abundance
###      next if not $count;  # e.g. ''
###      next if $count == 0; # e.g. 0.0
###      # Get the member itself
###      $member = $self->_members->[$line - 2];
###      $self->_line($line);
###      last;
###   }
###   return $member, $count;
###}


###method _next_community_init () {
###   # Go to start of next column and return name of new community or undef.
###   # The first time, initialize the read process by generating all community members.
###   if (not $self->_has_members) {
###      $self->_generate_members();
###   }
###   my $col  = $self->_col + 1;
###   my $line = 1;
###   my $name;
###   if ( $self->_skip_last_col && ($col == $self->_get_max_col) ) {
###      # At the taxonomy column. All communities were visited. Get out of the table
###      $col++;
###   } else {
###      $name = $self->_get_value($line, $col);
###   }
###   $self->_col( $col );
###   $self->_line( $line );
###   return $name;
###}


###method _next_community_finish () {
###   return 1;
###}


###method write_member (Bio::Community::Member $member, Count $count) {
###    my $id   = $member->id;
###    my $line = $self->_id2line->{$id};
###    if (not defined $line) {
###        # This member has not been written previously for another community
###        $line = $self->_get_max_line + 1;
###        $self->_set_value( $line, 1, $member->id );
###        $self->_id2line->{$id} = $line;
###    }
###    if ( $member->desc) {
###       # We'll have to write the description (taxonomy) if it is given
###       $self->_line2desc->{$line} = $member->desc;
###    }
###    $self->_set_value($line, $self->_col, $count);
###    $self->_line( $line + 1 );
###    return 1;
###}


###method _write_community_init (Bio::Community $community) {
###   # If first community, write first column header
###   if ($self->_first_community) {
###      $self->_write_headers;
###      $self->_first_community(0);
###   }
###   # Write header for that community
###   my $line = 1;
###   my $col  = $self->_col + 1;
###   $self->_set_value($line, $col, $community->name);
###   $self->_line( $line + 1);
###   $self->_col( $col );
###   return 1;
###}


###method _write_headers () {
###   $self->_print("# QIIME v1.3.0 OTU table\n");
###   $self->_set_value(1, 1, '#OTU ID');
###}


###method _write_community_finish (Bio::Community $community) {
###   return 1;
###}



__PACKAGE__->meta->make_immutable;

1;
