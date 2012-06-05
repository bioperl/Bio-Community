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
use namespace::autoclean;

subtype 'PositiveNum'
   => as 'Num'
   => where { $_ >= 0 }
   => message { "Only positive numbers accepted, but got '".($_||'')."'" };

subtype 'StrictlyPositiveNum'
   => as 'PositiveNum'
   => where { $_ > 0 }
   => message { "Only strictly positive numbers accepted, but got '".($_||'')."'" };

subtype 'PositiveInt'
   => as 'Int'
   => where { $_ >= 0 }
   => message { "Only positive integers accepted, but got '".($_||'')."'" };

subtype 'StrictlyPositiveInt'
   => as 'PositiveInt'
   => where { $_ > 0 }
   => message { "Only strictly positive integers accepted, but got '".($_||'')."'" };


# A Count should be a positive integer but to make things easier. We sometimes
# do not have access to the actual count, but just the relative abundance (a
# float) that we use as a proxy for a count.
subtype 'Count'
   => as 'PositiveNum';

# Sort numerically: 0, 1, -1
subtype 'NumericSort'
   => as 'Int'
   => where { ($_ >= -1) && ($_ <= 1) }
   => message { "This only accepts 0 (off), 1 (increasing) or -1 (decreasing), but got '".($_||'')."'" };


# Abundance representation: count, percentage, fraction
subtype 'AbundanceRepr'
   => as 'Str'
   => where { $_ =~ m/^(count|percentage|fraction)$/ }
   => message { "This only accepts 'count', 'percentage', or 'fraction', but got '".($_||'')."'" };

# Rank: a strictly positive integer
subtype 'AbundanceRank'
   => as 'StrictlyPositiveInt';

# Type of distance: 1-norm, 2-norm, euclidean, p-norm, infinity-norm, unifrac
subtype 'DistanceType'
   => as 'Str'
   => where { $_ =~ m/^(1-norm|2-norm|euclidean|p-norm|infinity-norm|unifrac)$/ }
   => message { "This only accepts '1-norm', '2-norm', 'euclidean', 'p-norm', 'infinity-norm' or 'unifrac', but got '$_'" };

# Weight assignment method: a number, 'average', 'median', 'taxonomy'
subtype 'WeightAssignType'
   => as 'Str'
   => where { ($_ =~ m/^(file_average|community_average|ancestor)$/) || ($_ * 2) }
   => message { "This only accepts 'file_average', 'community_average', 'ancestor' or a number, but got '$_'" };
;

__PACKAGE__->meta->make_immutable;

1;

