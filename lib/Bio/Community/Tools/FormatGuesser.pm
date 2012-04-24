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

  my $format = Bio::Community::Tools::FormatGuesser->new( ... );

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
use MooseX::Method::Signatures;
use namespace::autoclean;

extends 'Bio::Root::Root';


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
   init_arg => '-file',
);


=head2 text

 Usage   : my $text = $guesser->text;
 Function: Get or set the text from which to guess the format. In most, if not
           all cases, the first line of the file should be enough to determine
           the format.
 Args    : text string
 Returns : text string

=cut

has 'fh' => (
   is => 'rw',
   isa => 'FileHandle',
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-file',
#   predicate => '-file',
);


=head2 guess

 Function: Guess the file format
 Usage   : my $format = $guesser->guess;
 Args    : format string (e.g. generic, qiime, etc)
 Returns : format string (e.g. generic, qiime, etc)

=cut

method guess {
   my $format;

###   my @lines;
###   if (defined $self->{-text}) {
###      # Break the text into separate lines.
###      @lines = split /\n/, $self->{-text};
###   } elsif (defined $self->{-file}) {
###        # If given a filename, open the file.
###        open($fh, $self->{-file}) or
###            $self->throw("Can not open '$self->{-file}' for reading: $!");
###    } elsif (defined $self->{-fh}) {
###        # If given a filehandle, figure out if it's a plain GLOB
###        # or a IO::Handle which is seekable.  In the case of a
###        # GLOB, we'll assume it's seekable.  Get the current
###        # position in the stream.
###        $fh = $self->{-fh};
###        if (ref $fh eq 'GLOB') {
###            $start_pos = tell($fh);
###        } elsif (UNIVERSAL::isa($fh, 'IO::Seekable')) {
###            $start_pos = $fh->getpos();
###        }
###    }

   return $$format;
}



__PACKAGE__->meta->make_immutable;

1;
