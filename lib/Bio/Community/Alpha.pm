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
use List::Util qw(max);

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
            * menhinick:  C<S/sqrt(n)>
            * margalef : C<(S-1)/ln(n)>
            * chao1    : Bias-corrected chao1 richness, C<S+n1*(n1-1)/(2*(n2+1))>
                         where C<n1> and C<n2> are the number of singletons and
                         doubletons, respectively. Particularly useful for data
                         skewed toward the low-abundance species, e.g. microbial.
                         Note this metric uses counts instead of relative
                         abundance.
            * ace      : Abundance-based Coverage Estimator (ACE). Note this
                         metric uses counts instead of relative abundance.

           Evenness (or equitability):
            * buzas    : Buzas & Gibson's evenness, C<e^H/S>. Ranges from 0 to 1.
            * shannon_e: Shannon's evenness, or the Shannon-Wiener index divided
                         by the maximum diversity possible in the community.
                         Ranges from 0 to 1.
            * simpson_e: Simpson's evenness, or the Simpson's Index of Diversity
                         divided by the maximum diversity possible in the
                         community. Ranges from 0 to 1.
            * hill     : C<N_inf>, the inverse of the Berger-Parker dominance.
                         Ranges from 1 to infinity.

           Indices accounting explicitly for both richness and evenness:
            * shannon  : Shannon-Wiener index C<H>. Emphasizes richness. Ranges
                         from 0 to infinity.
            * simpson  : Simpson's Index of Diversity C<1-D>, where C<D> is
                         Simpson's dominance index. C<1-D> is the probability
                         that two individuals taken randomly are not from the
                         same species. Emphasizes evenness. Ranges from 0 to 1.
            * simpson_r: Simpson's reciprocal Index C<1/D>. Ranges from 1 to
                         infinity.

           Dominance metrics: Note that they are B<not> diversity measurements
           because the higher their value, the lower the diversity.
            * simpson_d: Simpson's Dominance Index C<D>. Ranges from 0 to 1.
            * berger   : Berger-Parker dominance, i.e. the proportion of the most
                         abundant species. Ranges from 0 to 1.

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

## Hill is a evenness, richness or composite index??

## Index:
##   Brillouin
##   Fisher index: a diversity index, defined implicitly by the formula
##      S=a*ln(1+n/a) where S is number of taxa, n is number of individuals and a
##      is the value of Fisher's alpha.
##      See http://www.thefreelibrary.com/A+table+of+values+for+Fisher%27s+%5Balpha%5D+log+series+diversity+index.-a0128667026

## Richness:
##   Chao2?

## Evenness:
##   Brillouin evenness
##   McIntosh
#    Heip

## Phylogenetic
##   PD: Faith's phylogenetic diversity
##   Mean pairwise distance (MPD) and mean nearest taxon distance (MNTD) (Webb et al. 2002)
##   Net-relatedness index (NRI) and nearest taxon index (NTI)
##   See http://nunn.rc.fas.harvard.edu/groups/pica/wiki/cb0ce/111_Phylogenetic_community_ecology.html

## QIIME supports these alpha diversity indices:
##   $ alpha_diversity.py -s
##   Known metrics are:
##      Implemented (or not needed) in B:C:
##        observed_species, shannon, simpson_e, simpson, reciprocal_simpson,
##        margalef,  menhinick, equitability, chao1, ACE, dominance, singles,
##        doubles, chao1_confidence, berger_parker_d
##      Not yet implemented:
##        mcintosh_e, heip_e
##        brillouin_d, mcintosh_d
##        fisher_alpha, kempton_taylor_q, michaelis_menten_fit, osd, robbins, strong,
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
   my $d = 0;
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


method _ace () {
   # Calculate abundance-based coverage estimator (ACE) richness.
   # http://www.ncbi.nlm.nih.gov/pmc/articles/PMC93182/
   my $d = 0;
   my $thresh = 10;
   my ($s_rare, $s_abund) = (0, 0); # number of rare, and abundant (>10) species
   my @F = (0) x $thresh; # number of singletons, doubletons, tripletons, ... 10-tons
   my $community = $self->community;
   while (my $member = $community->next_member) {
      my $c = $community->get_count($member);
      if ($c > $thresh) {
         $s_abund++;
      } else {
         $s_rare++;
         if ( $c != int($c) ) {
            $self->throw("Got count $c but can only compute chao1 on integer numbers");
         } else {
            $F[$c-1]++;
         }
      }
   }
   my ($n_rare, $tmp_sum) = (0, 0);
   for my $i (0.. $thresh) {
      my $add = $i * $F[$i-1];
      $n_rare  += $add;
      $add *= $i-1;
      $tmp_sum += $add;
   }
   my $C = 1 - $F[0]/$n_rare;
   my $gamma = ($s_rare * $tmp_sum) / ($C * $n_rare * ($n_rare-1)) - 1;
   $gamma = max($gamma, 0);
   $d = $s_abund + $s_rare/$C + $F[0]*$gamma/$C;
   return $d;
}


method _buzas () {
   # Calculate Buzas and Gibson's evenness
   return exp($self->_shannon) / $self->community->get_richness;
}


method _shannon_e () {
   # Calculate Shannon's evenness
   return $self->_shannon / log($self->community->get_richness);
}


method _simpson_e () {
   # Calculate Simpson's evenness
   return $self->_simpson / (1 - 1/$self->community->get_richness);
}


method _hill () {
   # Calculate Hill's N_inf diversity
   return 1 / $self->_berger;
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


method _simpson () {
   # Calculate Simpson's Index of Diversity (1-D)
   return 1 - $self->_simpson_d;
}


method _simpson_r () {
   # Calculate Simpson's Reciprocal Index (1/D)
   return 1 / $self->_simpson_d;
}


method _simpson_d () {
   # Calculate Simpson's Dominance Index (D)
   my $d = 0;
   my $community = $self->community;
   while (my $member = $community->next_member) {
      my $p = $community->get_rel_ab($member) / 100;
      $d += $p**2;
   }
   return $d;
}


method _berger () {
   # Calculate Berger-Parker's dominance
   my $community = $self->community;
   return $community->get_rel_ab($community->get_member_by_rank(1)) / 100;
}


__PACKAGE__->meta->make_immutable;

1;
