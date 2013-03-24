# BioPerl module for Bio::Community::Tools::FormatGuesser
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::FormatGuesser - Determine the format used by a community file

=head1 SYNOPSIS

  use Bio::Community::Tools::FormatGuesser;

  my $guesser = Bio::Community::Tools::FormatGuesser->new(
     -file => 'file.txt',
  );
  my $format = $guesser->guess;

=head1 DESCRIPTION

Given a file containing one or several communities, try to guess the file format
used by examining the file content (not by looking at the file name).

The guess() method will examine the data, line by line, until it finds a line
that is specific to a format. If no conclusive guess can be made, undef is returned.

If the Bio::Community::Tools::GuessSeqFormat object is given a filehandle
which is seekable, it will be restored to its original position
on return from the guess() method.

=head2 Formats

The following formats are currently supported:

=over

=item *

generic (tab-delimited tables, QIIME summarized OTU tables, ...)

=item *

gaas

=item *

qiime

=item *

unifrac

=item *

biom

=back

See the documentation for the corresponding IO drivers to read and write these
formats in the Bio::Community::IO::* namespace.

=head1 OBJECT METHODS

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

This module was inspired and based on the Bio::Tools::GuessSeqFormat module
written by Andreas Kähäri <andreas.kahari@ebi.ac.uk> and contributors. Thanks to
them!

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=head2 new

 Function: Create a new Bio::Community::Tool::FormatGuesser object
 Usage   : my $guesser = Bio::Community::Tool::FormatGuesser->new( );
 Args    : -text, -file or -fh. If more than one of these arguments was
           provided, only one is used: -text has precendence over -file, which
           has precedence over -fh.
 Returns : a new Bio::Community::Tools::FormatGuesser object

=cut


package Bio::Community::Tools::FormatGuesser;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;

extends 'Bio::Root::Root';


my %formats = (
   biom    => \&_possibly_biom    ,
   gaas    => \&_possibly_gaas    ,
   unifrac => \&_possibly_unifrac ,
   generic => \&_possibly_generic ,
   qiime   => \&_possibly_qiime   ,
);


=head2 file

 Usage   : my $file = $guesser->file;
 Function: Get or set the file from which to guess the format
 Args    : file path (string)
 Returns : file path (string)

=cut

has 'file' => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-file',
   predicate => '_has_file',
);


=head2 fh

 Usage   : my $fh = $guesser->fh;
 Function: Get or set the file handle from which to guess the format. 
 Args    : file handle
 Returns : file handle

=cut

has 'fh' => (
   is => 'rw',
   isa => 'FileHandle',
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-fh',
   predicate => '_has_fh',
);


=head2 text

 Usage   : my $text = $guesser->text;
 Function: Get or set the text from which to guess the format. In most, if not
           all cases, the first few lines of a text string should be enough to
           determine the format.
 Args    : text string
 Returns : text string

=cut

has 'text' => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-text',
   predicate => '_has_text',
);


=head2 guess

 Function: Guess the file format
 Usage   : my $format = $guesser->guess;
 Args    : format string (e.g. generic, qiime, etc)
 Returns : format string (e.g. generic, qiime, etc)

=cut

method guess () {
   my $format;

   # Prepare input
   my $fh;
   my $original_pos;
   my @lines;
   if ($self->_has_text) {
      # Break the text into separate lines.
      @lines = split /\n/, $self->text;
   } elsif ($self->_has_file) {
      # If given a filename, open the file.
      my $file = $self->file;
      open $fh, '<', $file or $self->throw("Could not read file '$file': $!");
   } elsif ($self->_has_fh) {
      $fh = $self->fh;
      $original_pos = tell($fh);
   } else {
      $self->throw('Need to provide -file, -fh or -text');
   }

   # Read lines and try to attribute format
   my %test_formats = %formats;
   my %ok_formats;
   my $line_num  = 0;
   my $prev_line = '';
   while (1) {

      # Read next line. Exit if no lines left
      $line_num++;
      my $line;
      if ($fh) {
         $line = <$fh>;
      } else {
         $line = shift @lines;
      }
      last if not defined $line;

      # Skip white and empty lines.
      next if $line =~ /^\s*$/;

      # Try all formats remaining
      %ok_formats = ();
      my ($test_format, $test_function);
      while ( ($test_format, $test_function) = each (%test_formats) ) {
         if ( &$test_function($line, $line_num, $prev_line) ) {
            # Line matches this format
            $ok_formats{$test_format} = undef;
         } else {
            # Do not try to match this format with upcoming lines
            delete $test_formats{$test_format};
         }
      }
      $prev_line = $line;

      # Exit if there was a match to only one format
      if (scalar keys %ok_formats == 1) {
         last;
      }

      # Give up after having tested 100 lines
      if ($line_num >= 100) {
         last;
      }

   }

   # If several formats matched. Assume 'generic' if possible, undef otherwise
   if (scalar keys %ok_formats > 1) {
      for my $ok_format (keys %ok_formats) {
         if (not $ok_format eq 'generic') {
            delete $ok_formats{$ok_format};
         }
      }
   }

   if (scalar keys %ok_formats == 1) {
      $format = (keys %ok_formats)[0];
   }

   # Cleanup
   if (not $self->_has_text) {
      if ($self->_has_file) {
         # Close the file that we opened
         close $fh;
      } elsif ($self->_has_fh) {
         # Reset cursor to original location
         seek($fh, $original_pos, 0)
            or $self->throw("Could not reset the cursor to its original position: $!");
      }
   }

   return $format;
}


func _possibly_biom ($line, $line_num, $prev_line) {
   # Example:
   # {
   #  "id":null,
   #  "format": "Biological Observation Matrix 0.9.1-dev",
   #  "format_url": "http://biom-format.org",
   #  ...
   my $ok = 0;
   if ($line_num == 1) {
      if ($line =~ m/^{/) {
         $ok = 1;
      }
   } else {
      if ( ($line =~ m/"\S+":/) || 
           ($line =~ m/Biological Observation Matrix/) ) {
         $ok = 1;
      }
   }
   return $ok;
}


func _possibly_generic ($line, $line_num, $prev_line) {
   # Example:
   # Species	gut	soda lake
   # Streptococcus	241	334
   # ...
   my $ok = 0;
   my @fields = split /\t/, $line;
   if (scalar @fields >= 2) {
      if ($line_num == 1) {
        $ok = 1 if $line !~ m/^#/; #### don't like this... too restrictive
        #$ok = 1;
      } else {
        $ok = 1 if $line !~ m/^#/;
      }
   }
   if ($ok && $prev_line) {
      my @prev_fields = split /\t/, $prev_line;
      if ($prev_fields[0] eq $fields[0]) {
         # Same have same species or OTU on previous line
         $ok = 0;
      }
   }
   return $ok;
}


func _possibly_gaas ($line, $line_num, $prev_line) {
   # Example:
   #    # tax_name	tax_id	rel_abund
   #    Streptococcus pyogenes phage 315.1	198538	0.791035649011735
   # or:
   #    # sequence_name	sequence_id	relative_abundance_%
   #    Milk vetch dwarf virus segment 9, complete sequence	gi|20177473|ref|NC_003646.1|	42.6354640657824	
   # First field contains string, second field an ID, third field a float.
   my $ok = 0;
   my @fields = split /\t/, $line;
   if (scalar @fields == 3) {
      if ($line_num == 1) {
        $ok = 1 if $line =~ m/^#\s*(seq*_name|tax*_name)/;
      } else {
        $ok = 1 if $line !~ m/^#/;
      }
   }
   if ($ok && $prev_line) {
      my @prev_fields = split /\t/, $prev_line;
      if ($prev_fields[0] eq $fields[0]) {
         # Cannot have same species name on previous line
         $ok = 0;
      }
      if ($prev_fields[1] eq $fields[1]) {
         # Cannot have same species ID on previous line
         $ok = 0;
      }
   }
   return $ok;
}


func _possibly_unifrac ($line, $line_num, $prev_line) {
   # Example:
   #    Sequence.1	Sample.1	1
   # or:
   #    Sequence.1	Sample.1
   # There are no headers. Two first fields contain strings. Optional third
   # field contains numbers. 
   my $ok = 0;
   my @fields = split /\t/, $line;
   if ($line =~ m/^#/) {
      $ok = 0;
   } else {
      if (scalar @fields == 2) {
         $ok = 1;
      } elsif (scalar @fields == 3) {
         $ok = 1;
      }
   }
   return $ok;
}


func _possibly_qiime ($line, $line_num, $prev_line) {
   # Example:
   # # QIIME v1.3.0 OTU table
   # #OTU ID	20100302	20100304	20100823
   # 0	40	0	76
   # 1	0	142	2
   my $ok = 0;
   if ($line_num == 1) {
      if ($line =~ m/^#\s*QIIME/) {
         $ok = 1;
      }
   } else {
      my @fields = split /\t/, $line;
      if (scalar @fields >= 2) {
         if ($line_num == 2) {
            $ok = 1 if $line =~ m/^#/;
         } else {
            $ok = 1;
         }
      }
      if ($ok && $prev_line) {
         my @prev_fields = split /\t/, $prev_line;
         if ($prev_fields[0] eq $fields[0]) {
            # Cannot have same OTU ID on previous line
            $ok = 0;
         }
      }
   }
   return $ok;
}


__PACKAGE__->meta->make_immutable;

1;
