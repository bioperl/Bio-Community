# BioPerl module for Bio::Community::Types
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Types - Definition of useful data types for use in Moose modules

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


package Bio::Community::Types;

use Moose;
use Moose::Util::TypeConstraints;
use Method::Signatures;
use namespace::autoclean;


# Numbers

subtype 'PositiveNum'
   => as 'Num'
   => where { $_ >= 0 }
   => message { _gen_err_msg('a positive number', $_) };


subtype 'StrictlyPositiveNum'
   => as 'PositiveNum'
   => where { $_ > 0 }
   => message { _gen_err_msg('a strictly positive number', $_) };


subtype 'PositiveInt'
   => as 'Int'
   => where { $_ >= 0 }
   => message { _gen_err_msg('a positive integer', $_) };


subtype 'StrictlyPositiveInt'
   => as 'PositiveInt'
   => where { $_ > 0 }
   => message { _gen_err_msg('a strictly positive integer', $_) };


# A Count should be a positive integer. Sometimes, however, we only have access
# to the relative abundance (a float), and use it as a proxy for a count.
subtype 'Count'
   => as 'PositiveNum';


# Sort numerically
subtype 'NumericSort'
   => as enum( [ qw(-1 0 1) ] )
   => message { _gen_err_msg('0 (off), 1 (increasing) or -1 (decreasing)', $_) };


# Abundance representation
my @AbundanceRepr = qw(count absolute percentage fraction);
subtype 'AbundanceRepr'
   => as enum( \@AbundanceRepr )
   => message { _gen_err_msg(\@AbundanceRepr, $_) };


# Rank: a strictly positive integer
subtype 'AbundanceRank'
   => as 'StrictlyPositiveInt';


# Type of distance
my @DistanceType = qw(1-norm 2-norm euclidean p-norm infinity-norm hellinger
                       bray-curtis shared permuted maxiphi unifrac);
subtype 'DistanceType'
   => as enum( \@DistanceType )
   => message { _gen_err_msg(\@DistanceType, $_) };


# Type of alpha diversity
my @AlphaType = qw(
   observed menhinick margalef chao1 ace
   shannon_e brillouin_e hill_e mcintosh_e simpson_e buzas heip camargo
   shannon   brillouin   hill   mcintosh   simpson   simpson_r
   simpson_d berger
);
subtype 'AlphaType'
   => as enum( \@AlphaType )
   => message { _gen_err_msg(\@AlphaType, $_) };

# Type of transformation
my @TransformationType = qw(identity binary relative hellinger chord);
subtype 'TransformationType'
   => as enum( \@TransformationType )
   => message { _gen_err_msg(\@TransformationType, $_) };

# Members identification method
my @IdentifyMembersByType = qw(id desc);
subtype 'IdentifyMembersByType'
   => as enum( \@IdentifyMembersByType )
   => message { _gen_err_msg(\@IdentifyMembersByType, $_) };


# Duplicates identification method
my @IdentifyDupsByType = qw(desc taxon);
subtype 'IdentifyDupsByType'
   => as enum( \@IdentifyDupsByType )
   => message { _gen_err_msg(\@IdentifyDupsByType, $_) };


# Weight assignment method: a number, 'average', 'median', 'taxonomy'
my @WeightAssignStr = qw(file_average community_average ancestor);
subtype 'WeightAssignStr'
   => as enum( \@WeightAssignStr )
   => message { _gen_err_msg(\@WeightAssignStr, $_) };
subtype 'WeightAssignType'
   => as 'WeightAssignStr | Num'
   => message { _gen_err_msg( ['a number', @WeightAssignStr], $_) };


# Biom matrix type
my @BiomMatrixType = qw(sparse dense);
subtype 'BiomMatrixType'
   => as enum( \@BiomMatrixType )
   => message { _gen_err_msg(\@BiomMatrixType, $_) };

# A readable file
subtype 'ReadableFile'
   => as 'Str'
   => where { (-e $_) && (-r $_) }
   => message { _gen_err_msg([], $_) };

subtype 'ArrayRefOfReadableFiles'
   => as 'ArrayRef[ReadableFile]';

# A readable filehandle (and coercing it from a readable file)
subtype 'ReadableFileHandle'
   => as 'FileHandle';

coerce 'ReadableFileHandle'
   => from 'Str'
   => via { _read_file($_) };

subtype 'ArrayRefOfReadableFileHandles'
   => as 'ArrayRef[ReadableFileHandle]';

coerce 'ArrayRefOfReadableFileHandles'
   => from 'ArrayRefOfReadableFiles'
   => via { [ map { _read_file($_) } @{$_} ] };


func _read_file ($file) {
   open my $fh, '<', $file or die "Could not open file '$_': $!\n";
                   # $self->throw("Could not open file '$_': $!")
   return $fh;
}


func _gen_err_msg ($accepts, $got = '') {
   # Generate an error message. The input is:
   #  * an arrayref of the values accepted, or a string describing valid input
   #  * the value obtained instead of the
   my $accept_str;
   if (ref($accepts) eq 'ARRAY') {
      if (scalar @$accepts > 1) {
         $accept_str = join(', ', @$accepts[0,-2]);
      }
      $accept_str = $accept_str.' or '.$accepts->[-1];
   } else {
      $accept_str = $accepts;
   }
   return "It can only be $accept_str, but was '$got'";
}


__PACKAGE__->meta->make_immutable;

1;

