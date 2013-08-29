# BioPerl module for Bio::Community::Alpha
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Alpha - Calculate the alpha diversity of a community

=head1 SYNOPSIS

  use Bio::Community::Alpha;
  
  my $alpha = Bio::Community::Alpha->new( -community => $community,
                                          -type      => 'richness'  );
  my $richness = $alpha->get_alpha;

=head1 DESCRIPTION

The Bio::Community::Alpha module calculates the alpha diversity within a
community. The goal is to support many different alpha diversity metrics, but
the only metric available at the moment is: richness.

For all these metrics, a higher value means that the community is more diverse.

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

 Function: Create a new Bio::Community::Alpha object
 Usage   : my $alpha = Bio::Community::Alpha->new( ... );
 Args    : -community : See community().
           -type      : See type().
 Returns : a new Bio::Community::Alpha object

=cut


package Bio::Community::Alpha;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;

extends 'Bio::Root::Root';


=head2 community

 Function: Get or set the community to process.
 Usage   : my $community = $alpha->community();
 Args    : A Bio::Community object
 Returns : A Bio::Community object

=cut

has community => (
   is => 'ro',
   isa => 'Bio::Community',
   required => 1,
   lazy => 0,
   init_arg => '-community',
);


=head2 type

 Function: Get or set the type of alpha diversity metric to measure.
 Usage   : my $type = $alpha->type;
 Args    : String for the desired type of alpha diversity ('observed' by default).

           Richness: Let C<S> be number of observed members C<i> (species, taxa,
           OTUs) in the community and C<n> be the total counts (observations).
            * observed :  C<S>
            * menhinick:  C<S / sqrt(n)>
            * margalef : C<(S-1) / ln(n)>
            * chao1    : Bias-corrected chao1 richness. Note that this determines
                         singleton and doubleton species and has to use counts
                         instead of relative abundance.

           Evenness (or equitability):
            * shannon_e: Shannon's evenness, or the Shannon-Wiener index divided
                         by the maximum diversity possible in the community.
                         Ranges from 0 to 1.
            * simpson_e: Simpson's evenness, or the Simpson's Index of Diversity
                         divided by the maximum diversity possible in the community.
                         Ranges from 0 to 1.

           Indices accounting for both richness and evenness:
            * shannon  : Shannon-Wiener index. Emphasizes richness. Ranges from
                         0 to infinity.
            * simpson  : Simpson's Index of Diversity (1-D), i.e. the probability
                         that two individuals taken randomly are not from the
                         same species. Emphasizes evenness. Ranges from 0 to 1.
            * simpson_r: Simpson's reciprocal Index (1/D). Ranges from 1 to
                         infinity.

 Returns : String for the desired type of alpha diversity.

=cut

has type => (
   is => 'ro',
   isa => 'AlphaType',
   required => 0,
   lazy => 1,
   default => 'observed',
   init_arg => '-type',
);


#####
## TODO:

## Evenness:
##   Pielou evenness: see phd thesis
##   Buzas and Gibson's evenness = eH/S

## Index:
##   Fisher index: a diversity index, defined implicitly by the formula
##      S=a*ln(1+n/a) where S is number of taxa, n is number of individuals and a
##      is the value of Fisher's alpha.
##      See http://www.thefreelibrary.com/A+table+of+values+for+Fisher%27s+%5Balpha%5D+log+series+diversity+index.-a0128667026

##   Chao2?
##   ACE?  http://www.ncbi.nlm.nih.gov/pmc/articles/PMC93182/
##   PD: Faith's phylogenetic diversity
##   Mean pairwise distance (MPD) and mean nearest taxon distance (MNTD) (Webb et al. 2002)
##   Net-relatedness index (NRI) and nearest taxon index (NTI)
##   See http://nunn.rc.fas.harvard.edu/groups/pica/wiki/cb0ce/111_Phylogenetic_community_ecology.html

## Other measures that are not really alpha diversity (because higher value means LESS diverse)
##   Simpson's D: simpson_d
##   Berger-Parker dominance: is the abundance of most abundant species.

## QIIME supports these alpha diversity indices:
##   $ alpha_diversity.py -s
##   Known metrics are:
##      Implemented in B:C:
##        observed_species, shannon, simpson_e, simpson, reciprocal_simpson, margalef,  menhinick, equitability, chao1
##      Not yet implemented:
##        ACE, chao1_confidence
##        mcintosh_e, heip_e
##        dominance, berger_parker_d, brillouin_d, mcintosh_d
##        doubles, fisher_alpha, kempton_taylor_q, michaelis_menten_fit, osd, robbins, singles, strong,
##        PD_whole_tree

#####


=head2 get_alpha

 Function: Calculate the alpha diversity of a community.
 Usage   : my $metric = $alpha->get_alpha;
 Args    : None
 Returns : A number for the alpha diversity measurement

=cut

method get_alpha () {
   my $metric = '_'.$self->type;
   return $self->$metric();
};


method _observed () {
   # Calculate the observed richness
   return $self->community->get_richness;
}


method _menhinick () {
   # Calculate the Menhinick richness
   return $self->community->get_richness / sqrt($self->community->get_members_count);
}


method _margalef () {
   # Calculate the Margalef richness
   return ($self->community->get_richness - 1) / log($self->community->get_members_count);
}


method _chao1 () {
   # Calculate Chao's bias-corrected chao1 richness
   # We use the bias-corrected version because it is always defined, even if
   # there are no doubletons, contrary to the non-bias corrected version
   my $d  = 0;
   my ($n1, $n2) = (0, 0); # singletons and doubletons
   my $community = $self->community;
   while (my $member = $community->next_member) {
      my $c = $community->get_count($member);
      if ($c == 1) {
         $n1++;
      } elsif ($c == 2) {
         $n2++;
      } elsif ( $c != int($c) ) {
         $self->throw("Got count $c but can only compute chao1 on integer numbers");
      }
   }
   return $community->get_richness + ($n1*($n1-1)) / (2*($n2+1));
}


method _shannon_e () {
   # Calculate Shannon's evenness
   return $self->_shannon / log($self->community->get_richness);
}


method _simpson_e () {
   # Calculate Simpson's evenness
   return $self->_simpson / (1 - 1/$self->community->get_richness);
}


method _shannon () {
   # Calculate the Shannon-Wiener index
   my $d = 0;
   my $community = $self->community;
   while (my $member = $community->next_member) {
      my $p = $community->get_rel_ab($member) / 100;
      $d += $p * log($p);
   }
   return -$d;
}


method _simpson_d () {
   # Calculate Simpson's Index (D)
   my $d = 0;
   my $community = $self->community;
   while (my $member = $community->next_member) {
      my $p = $community->get_rel_ab($member) / 100;
      $d += $p**2;
   }
   return $d;
}


method _simpson () {
   # Calculate Simpson's Index of Diversity (1-D)
   return 1 - $self->_simpson_d;
}


method _simpson_r () {
   # Calculate Simpson's Reciprocal Index (1/D)
   return 1 / $self->_simpson_d;
}


__PACKAGE__->meta->make_immutable;

1;
