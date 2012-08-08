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

 Function: Create a new Bio::Community object
 Usage   : my $alpha = Bio::Community::Alpha->new( ... );
 Args    : -community : See community().
           -type      : See type().
 Returns : a new Bio::Community object

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
 Args    : String for the desired type of alpha diversity:
            * richness: the number of species in the community
           This defaults to richness
 Returns : String for the desired type of alpha diversity

=cut

has type => (
   is => 'ro',
   isa => 'AlphaType',
   required => 0,
   lazy => 1,
   default => 'richness',
   init_arg => '-type',
);


#####
## TODO:

## Richness:
##   Menhinick's richness index - the ratio of the number of taxa to the square
##      root of sample size.
##   Margalef's richness index: (S-1)/ln(n), where S is the number of taxa, and n
##      is the number of individuals.

## Evenness:
##   Pielou evenness: see phd thesis
##   equitability: Shannon-Wiener evenness. 0 low, 1 high. Shannon diversity
##      divided by the logarithm of number of taxa. This measures the evenness
##      with which individuals are divided among the taxa present.
##   Buzas and Gibson's evenness = eH/S
##   simpson evenness?

## Index:
##   Shannon-Wiener index: entropy measure. 0 is low, higher is more diverse.
##   Simpson index: 0 low, 1 high. See phd thesis. probability that two members
##      drawn at random from a community belong to different species. Note that
##      S=1-dominance
##   Fisher index: a diversity index, defined implicitly by the formula
##      S=a*ln(1+n/a) where S is number of taxa, n is number of individuals and a
##      is the Fisher's alpha.

##   Chao? http://www.ncbi.nlm.nih.gov/pmc/articles/PMC93182/
##   ACE?  http://www.ncbi.nlm.nih.gov/pmc/articles/PMC93182/
##   PD: Faith's phylogenetic diversity
##   Mean pairwise distance (MPD) and mean nearest taxon distance (MNTD) (Webb et al. 2002)
##   Net-relatedness index (NRI) and nearest taxon index (NTI)
##   See http://nunn.rc.fas.harvard.edu/groups/pica/wiki/cb0ce/111_Phylogenetic_community_ecology.html

## Other measures that are not really alpha diversity (beucase higher value means LESS diverse)
##   Simpson dominance
##   Berger-Parker dominance: is the abundance of most abundant species.

## QIIME supports these alpha diversity indices:
##   $ alpha_diversity.py -s
##   Known metrics are: ACE, berger_parker_d, brillouin_d, chao1, chao1_confidence,
##      dominance, doubles, equitability, fisher_alpha, heip_e, kempton_taylor_q,
##      margalef, mcintosh_d, mcintosh_e, menhinick, michaelis_menten_fit,
##      observed_species, osd, reciprocal_simpson, robbins, shannon, simpson,
##      simpson_e, singles, strong, PD_whole_tree

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


method _richness () {
   # Calculate the richness
   return $self->community->get_richness;
}


__PACKAGE__->meta->make_immutable;

1;
