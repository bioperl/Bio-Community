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

   # Reading
   my $in = Bio::Community::IO->new(
      -file   => 'biom_communities.txt',
      -format => 'biom'
   );
   my $type = $in->get_matrix_type; # either dense or sparse

   # Writing
   my $out = Bio::Community::IO->new(
      -file        => 'biom_communities.txt',
      -format      => 'biom',
      -matrix_type => 'sparse', # default matrix type
   );

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

Columns (i.e. communities) can be expressed in a richer way, e.g.:

  {"id":"Sample1", "metadata":{
                           "BarcodeSequence":"CGCTTATCGAGA",
                           "LinkerPrimerSequence":"CATGCTGCCTCCCGTAGGAGT",
                           "BODY_SITE":"gut",
                           "Description":"human gut"}},

The 'id' can be recovered from the id() method of the resulting Bio::Community,
while the 'Description' is obtained from the desc() method.

Rows can also be expressed in a richer form:

  {"id":"GG_OTU_1", "metadata":{"taxonomy":["k__Bacteria", "p__Proteobacteria", "c__Gammaproteobacteria", "o__Enterobacteriales", "f__Enterobacteriaceae", "g__Escherichia", "s__"]}},

For each Bio::Community::Member generated, the id() method contains the 'id' and
desc() holds a concantenated version of the 'taxonomy'.

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
use JSON::XS qw( decode_json encode_json );
use DateTime;

use constant BIOM_NAME => 'Biological Observation Matrix 1.0';
use constant BIOM_URL  => 'http://biom-format.org/documentation/format_versions/biom-1.0.html';
use constant BIOM_MATRIX_TYPE => 'sparse'; # sparse or dense
use constant BIOM_TYPE => 'OTU table';
# "XXX table" where XXX is Pathway, Gene, Function, Ortholog, Metabolite or Taxon


#BIOM_MATRIX_ELEMENT_TYPE
#  "int" : integer
#  "float" : floating point
#  "unicode" : unicode string

extends 'Bio::Community::IO';
with 'Bio::Community::Role::IO';


our $multiple_communities   =  1;      # format supports several communities per file
#### sorting only effective for first community???
our $default_sort_members   =  0;      # unsorted
our $default_abundance_type = 'count'; # absolute count (positive integer)
our $default_missing_string =  0;      # empty members get a '0'


###around BUILDARGS => func ($orig, $class, %args) {
###   $args{-start_line} = 2; 
###   return $class->$orig(%args);
###};


before 'close' => sub {
   my ($self) = @_;
   if ($self->_has_first_community) {
      # Write JSON to file, but only if fh opened for writing
      my $rows = $self->_get_line; #### UPDATE with number of members
      my $cols = $self->_get_col;
      my $json = $self->_get_json;
      $json->{'shape'} = [$rows, $cols];
      my $writer = JSON::XS->new->pretty;
      my $str = $writer->encode($json);
      $self->_print($str);
   }
};


has '_first_community' => (
   is => 'rw',
   isa => 'Bool',
   required => 0,
   init_arg => undef,
   default => 1,
   predicate => '_has_first_community',
   lazy => 1,
);


has 'matrix_type' => (
   is => 'rw',
   #isa => 'Bool', ### either sparse or dense ### need type checking
   required => 0,
   init_arg => '-matrix_type',
   default => undef,
   lazy => 1,
   reader => 'get_matrix_type',
   writer => 'set_matrix_type',
   predicate => '_has_matrix_type',
);


has '_json' => (
   is => 'rw',
   #isa => 'JSON::XS',
   required => 0,
   init_arg => undef,
   default => undef,
   lazy => 1,
   predicate => '_has_json',
   reader => '_get_json',
   writer => '_set_json',
);


has '_max_line' => (
   is => 'rw',
   #isa => 'StrictlyPositiveInt',
   required => 0,
   init_arg => undef,
   lazy => 1,
   default => 0,
   reader => '_get_max_line',
   writer => '_set_max_line',
);


has '_max_col' => (
   is => 'rw',
   #isa => 'StrictlyPositiveInt',
   required => 0,
   init_arg => undef,
   lazy => 1,
   default => 0,
   reader => '_get_max_col',
   writer => '_set_max_col',
);


has '_line' => (
   is => 'rw',
   isa => 'PositiveInt',
   required => 0,
   init_arg => undef,
   default => 0,
   lazy => 1,
   reader => '_get_line',
   writer => '_set_line',
);


has '_col' => (
   is => 'rw',
   isa => 'PositiveInt',
   required => 0,
   init_arg => undef,
   default => 0,
   lazy => 1,
   reader => '_get_col',
   writer => '_set_col',
);


has '_members' => (
   is => 'rw',
   isa => 'HashRef', # HashRef{id} = Bio::Community::Member
   required => 0,
   init_arg => undef,
   default => sub { [] },
   lazy => 1,
   predicate => '_has_members',
   reader => '_get_members',
   writer => '_set_members',
);


has '_sorted_members' => (
   is => 'rw',
   isa => 'HashRef', # HashRef{species}{sample} = count
   required => 0,
   init_arg => undef,
   default => sub { {} },
   lazy => 1,
   reader => '_get_sorted_members',
   writer => '_set_sorted_members',
);


method _generate_members () {
   my %members = ();
   for my $row (1 .. $self->_get_max_line) {
      my $json = $self->_get_json->{'rows'}->[$row-1];
      my $id = $json->{'id'};
      my $member = Bio::Community::Member->new( -id => $id );
      my $metadata = $json->{'metadata'};
      if (exists $metadata->{'taxonomy'}) {
         my $taxo_desc;
         if (ref($metadata->{'taxonomy'}) eq 'SCALAR') {
            $taxo_desc = $metadata->{'taxonomy'};
         } elsif (ref($metadata->{'taxonomy'}) eq 'ARRAY') {
            $taxo_desc = join '; ', @{$metadata->{'taxonomy'}};
         }
         $member->desc( $taxo_desc );
      }
      if (exists $members{$id}) {
         $self->warn("Member with ID $id is present multiple times... ".
            "Continuing despite the perils!");
      }
      $members{$id} = $member;
   }

   $self->_set_members(\%members);
   return 1;
}


method _sort_members_by_community {
   # Sort members by community to facilitate parsing
   my %sorted_members;
   my $json   = $self->_get_json;
   my $matrix = $json->{'data'};
   my $rows   = $json->{'rows'};
   for my $i (0 .. scalar @$matrix - 1) {
      my ($row, $sample, $count) = @{$matrix->[$i]};
      if ($count > 0) {
         my $species = $rows->[$row]->{'id'};
         $sorted_members{$sample}{$species} += $count; # adding allows duplicates
      }
   }
   $self->_set_sorted_members(\%sorted_members);
   return 1;
}


method next_member () {
   my ($id, $member, $count);

   my $col     = $self->_get_col;
   my $members = $self->_get_members;
   my $json    = $self->_get_json;
   my $is_sparse = $json->{'matrix_type'} eq 'sparse' ? 1 : 0;

   if ($is_sparse) { # sparse matrix format

      my $sorted_members = $self->_get_sorted_members;
      my @ids = keys %{$sorted_members->{$col-1}};
      if (scalar @ids > 0) {
         $id = shift @ids;
         $count = delete $sorted_members->{$col-1}->{$id};
         $self->_set_sorted_members($sorted_members);
      }

   } else { # dense matrix format

      my $rows   = $json->{'rows'};
      my $matrix = $json->{'data'};
      my $line   = $self->_get_line;
      while ( ++$line ) {
         # Get the abundance of the member (undef if out-of-bounds)
         $count = $matrix->[$line-1]->[$col-1];
         if (defined $count) {
            if ($count > 0) {
               $id = $rows->[$line-1]->{'id'};
               $self->_set_line($line);
               last;
            }
         } else {
            # No more members for this community
            $self->_set_line(0);
            last;
         }
      }

   }

   if (defined $id) {
      $member = $members->{$id};
   }

   return $member, $count;
}


method _parse_json () {
   # Parse JSON string incrementally
   my $parser = JSON::XS->new();
   while (my $line = $self->_readline(-raw => 1)) {
      $parser->incr_parse( $line );
   }
   my $json = $parser->incr_parse();

   #### Parse JSON string in one step
   ###my $str = '';
   ###while (my $line = $self->_readline(-raw => 1)) {
   ###   $str .= $line;
   ###}
   ###my $json = $parser->decode($str);

   $self->_set_json($json);

   my ($max_line, $max_col) = @{$json->{'shape'}};
   $self->_set_max_line( $max_line );
   $self->_set_max_col( $max_col );

   $self->set_matrix_type($json->{'matrix_type'});

   return $json;
}


method _next_community_init () {
   # First time, parse the JSON string
   if (not $self->_has_json) {
      $self->_parse_json();
   }

   # Generate all members
   if (not $self->_has_members) {
      $self->_generate_members();
   }

   # Sort members when reading sparse matrix
   if ($self->get_matrix_type eq 'sparse') {
      $self->_sort_members_by_community();
   }

   # Get community name and set column number
   my $col = $self->_get_col + 1;
   my $name;
   if ($self->_get_col <= $self->_get_max_col) {
      $name = $self->_get_json->{'columns'}->[$col-1]->{'id'};
   }
   $self->_set_col( $col );

   return $name;
}


method _next_community_finish () {
   return 1;
}


method write_member (Bio::Community::Member $member, Count $count) {
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
}


method _write_community_init (Bio::Community $community) {
   # Set default matrix type to sparse
   if (not $self->_has_matrix_type) {
      $self->set_matrix_type('sparse');

   }
   # If first community, write some generic header information
   if ($self->_first_community) {
      $self->_write_headers;
      $self->_first_community(0);
   }

   $self->_set_col( $self->_get_col + 1);

   return 1;
}


method _write_headers () {
   my $json = {};
   $json->{'id'}           = undef;
   $json->{'format'}       = BIOM_NAME;
   $json->{'format_url'}   = BIOM_URL;
   $json->{'type'}         = BIOM_TYPE;
   $json->{'generated_by'} = 'Bio::Community version XXX'; ####
   $json->{'date'}         = DateTime->now->datetime; # ISO 8601, e.g. 2011-12-19T19:00:00
   $json->{'matrix_type'}  = $self->get_matrix_type;
   $self->_set_json($json);
}


method _write_community_finish (Bio::Community $community) {
   return 1;
}


__PACKAGE__->meta->make_immutable;

1;
