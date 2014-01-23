# BioPerl module for Bio::Community::Alpha
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Alpha - Calculate the alpha diversity of a community

=head1 SYNOPSIS

  use Bio::Community::Alpha;
  
  my $alpha = Bio::Community::Alpha->new( -community => $community,
                                          -type      => 'observed'  );
  my $richness = $alpha->get_alpha;

=head1 DESCRIPTION

The Bio::Community::Alpha module calculates the alpha diversity within a
community. The goal is to support many different alpha diversity metrics, but
the only metric available at the moment is: richness.

For all these metrics, a higher value means that the community is more diverse.

=head1 AUTHOR

Florent Angly L<florent.angly@gmail.com>

=head1 SUPPORT AND BUGS

User feedback is an integral part of the evolution of this and other Bioperl
modules. Please direct usage questions or support issues to the mailing list, 
L<bioperl-l@bioperl.org>, rather than to the module maintainer directly. Many
experienced and reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem with code and
data examples if at all possible.

If you have found a bug, please report it on the BioPerl bug tracking system
to help us keep track the bugs and their resolution:
L<https://redmine.open-bio.org/projects/bioperl/>

=head1 COPYRIGHT

Copyright 2011-2014 by Florent Angly <florent.angly@gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

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
use Math::BigFloat try => 'GMP';

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

           Richness (or estimated number of species):
            * observed :  C<S>
            * menhinick:  C<S/sqrt(n)>, where C<n> is the total counts (observations).
            * margalef : C<(S-1)/ln(n)>
            * chao1    : Bias-corrected chao1 richness, C<S+n1*(n1-1)/(2*(n2+1))>
                         where C<n1> and C<n2> are the number of singletons and
                         doubletons, respectively. Particularly useful for data
                         skewed toward the low-abundance species, e.g. microbial.
                         Based on counts, not relative abundance.
            * ace      : Abundance-based Coverage Estimator (ACE). Based on
                         counts, not relative abundance.

           Evenness (or equitability):
            * buzas      : Buzas & Gibson's (or Sheldon's) evenness, C<e^H/S>.
                           Ranges from 0 to 1.
            * heip       : Heip's evenness, C<(e^H-1)/(S-1)>. Ranges from 0 to 1.
            * shannon_e  : Shannon's evenness, or the Shannon-Wiener index
                           divided by the maximum diversity possible in the
                           community. Ranges from 0 to 1.
            * simpson_e  : Simpson's evenness, or the Simpson's Index of Diversity
                           divided by the maximum diversity possible in the
                           community. Ranges from 0 to 1.
            * brillouin_e: Brillouin's evenness, or the Brillouin's index divided
                           by the maximum diversity possible in the community.
                           Ranges from 0 to 1.
            * hill_e     : Hill's C<E_2,1> evenness, i.e. Simpson's Reciprocal
                           index divided by C<e^H>.
            * mcintosh_e : McIntosh's evenness.
            * camargo    : Camargo's eveness. Ranges from 0 to 1.

           Indices (accounting for species abundance):
            * shannon  : Shannon-Wiener index C<H>. Emphasizes richness and ranges
                         from 0 to infinity.
            * simpson  : Simpson's Index of Diversity C<1-D> (or Gini-Simpson
                         index), where C<D> is Simpson's dominance index. C<1-D>
                         is the probability that two individuals taken randomly
                         are not from the same species. Emphasizes evenness and
                         anges from 0 to 1.
            * simpson_r: Simpson's Reciprocal Index C<1/D>. Ranges from 1 to
                         infinity.
            * brillouin: Brillouin's index, appropriate for small, completely
                         censused communities. Based on counts, not relative
                         abundance.
            * hill     : Hill's C<N_inf> index, the inverse of the Berger-Parker
                         dominance. Ranges from 1 to infinity.
            * mcintosh : McIntosh's index. Based on counts, not relative abundance.

           Dominance (B<not> diversity metrics since the higher their value, the
           lower the diversity):
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

## Index:
##   Fisher index: a diversity index, defined implicitly by the formula
##      S=a*ln(1+n/a) where S is number of taxa, n is number of individuals and a
##      is the value of Fisher's alpha.
##      See http://www.thefreelibrary.com/A+table+of+values+for+Fisher%27s+%5Balpha%5D+log+series+diversity+index.-a0128667026

## QIIME supports these alpha diversity indices:
##   $ alpha_diversity.py -s
##   Known metrics are:
##      Implemented (or not needed) in B:C:
##        observed_species, shannon, simpson_e, simpson, reciprocal_simpson,
##        margalef,  menhinick, equitability, chao1, ACE, dominance, singles,
##        doubles, chao1_confidence, berger_parker_d, brillouin_d, mcintosh_d
##        mcintosh_e, PD_whole_tree
##      Not yet implemented:
##        fisher_alpha, kempton_taylor_q, michaelis_menten_fit, osd, robbins, strong

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
   # http://folk.uio.no/ohammer/past/diversity.html
   return exp($self->_shannon) / $self->community->get_richness;
}


method _heip () {
   # Calculate Heip's evenness
   # http://www.pisces-conservation.com/sdrhelp/index.html?heip.htm
   return (exp($self->_shannon) - 1) / ($self->community->get_richness - 1);
}


method _shannon_e () {
   # Calculate Shannon's evenness
   return $self->_shannon / log($self->community->get_richness);
}


method _simpson_e () {
   # Calculate Simpson's evenness
   return $self->_simpson / (1 - 1/$self->community->get_richness);
}


method _hill_e () {
   # Calculate Hill's E_2,1 evenness
   # http://www.wcsmalaysia.org/analysis/diversityIndexMenagerie.htm#Hill
   return $self->_simpson_r / exp($self->_shannon);
}


method _brillouin_e () {
   # Calculate Brillouin's evenness
   # http://www.wcsmalaysia.org/analysis/diversityIndexMenagerie.htm#Brillouin
   my $community = $self->community;
   my $N = $community->get_members_count;
   my $S = $community->get_richness;
   my $n = int( $N / $S );
   my $r = $N - $S * $n;
   my $tmp1 =           Math::BigFloat->new($N  )->bfac->blog;
   my $tmp2 =     $r  * Math::BigFloat->new($n+1)->bfac->blog;
   my $tmp3 = ($S-$r) * Math::BigFloat->new($n  )->bfac->blog;
   my $bmax  = ($tmp1 - $tmp2 - $tmp3) / $N;
   return $self->_brillouin / $bmax;
}


method _mcintosh_e () {
   # Calculate McIntosh's evenness
   my $d = 0;
   my $U = 0;
   my $community = $self->community;
   while (my $member = $community->next_member) {
      my $c = $community->get_count($member);
      $U += $c**2;
   }
   $U = sqrt($U);
   my $N = $community->get_members_count;
   my $S = $community->get_richness;
   $d = $U / sqrt( ($N-$S+1)**2 + $S - 1 );
   return $d;
}


method _camargo () {
   # Calculate Camargo's evenness
   # http://www.pisces-conservation.com/sdrhelp/index.html?camargo.htm
   my $d = 0;
   my $community = $self->community;
   my $S = $community->get_richness;
   my @p = map { $community->get_rel_ab($_) / 100 } @{$community->get_all_members};
   for my $i (1 .. $S) {
      for my $j ($i+1 .. $S) {
         $d += abs($p[$i-1] - $p[$j-1]) / $S;
      }
   }
   $d = 1 - $d;
   return $d;
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


method _brillouin () {
   # Calculate Brillouin's index of diversity
   # http://www.wcsmalaysia.org/analysis/diversityIndexMenagerie.htm#Brillouin
   # Use the Math::BigFloat module because i) it has a function to calculate
   # factorial, and ii) it can use Math::BigInt::GMP C-bindings to be faster
   my $d = 0;
   my $sum = 0;
   my $community = $self->community;
   while (my $member = $community->next_member) {
      my $c = $community->get_count($member);
      $sum += Math::BigFloat->new($c)->bfac->blog;
   }
   my $N = $community->get_members_count;
   my $tmp = Math::BigFloat->new($N)->bfac->blog;
   $d = ( $tmp - $sum ) / $N;
   return $d;
}


method _hill () {
   # Calculate Hill's N_inf index of diversity
   # http://www.wcsmalaysia.org/analysis/diversityIndexMenagerie.htm#Hill
   return 1 / $self->_berger;
}


method _mcintosh () {
   # Calculate McIntosh's index of diversity
   # http://www.pisces-conservation.com/sdrhelp/index.html?mcintoshd.htm
   my $d = 0;
   my $U = 0;
   my $community = $self->community;
   while (my $member = $community->next_member) {
      my $c = $community->get_count($member);
      $U += $c**2;
   }
   $U = sqrt($U);
   my $N = $community->get_members_count;
   $d = ($N - $U) / ($N - sqrt($N));
   return $d;
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
