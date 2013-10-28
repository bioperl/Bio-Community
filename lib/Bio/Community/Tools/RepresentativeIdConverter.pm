# BioPerl module for Bio::Community::Tools::RepresentativeIdConverter
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::RepresentativeIdConverter - Convert member ID to OTU representative ID or taxonomic ID

=head1 SYNOPSIS

  use Bio::Community::Tools::RepresentativeIdConverter;

  my $converter = Bio::Community::Tools::Summarizer->new(
     -metacommunity => $meta,
     -cluster_file  => 'gg_99_otu_map.txt',
  );
  my $meta_by_otu = $converter->get_converted_meta;

=head1 DESCRIPTION

Given a metacommunity and an OTU cluster map file (or taxonomic assignment file),
replace the ID of every member by that of its OTU cluster (or taxonomic)
representative and add it in a new metacommunity.

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

Copyright 2011,2012,2013 by the BioPerl Team L<bioperl-l@bioperl.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=head2 new

 Function: Create a new Bio::Community::Tool::RepresentativeIdConverter object
 Usage   : my $converter = Bio::Community::Tool::RepresentativeIdConverter->new(
              -metacommunity => $meta,
              -cluster_file  => '99_otu_map.txt',
           );
           # or
           my $converter = Bio::Community::Tool::RepresentativeIdConverter->new(
              -metacommunity  => $meta,
              -taxassign_file => 'rep_set_tax_assignments.txt',
           );
 Args    : -metacommunity  : See metacommunity().
           -cluster_file   : See cluster_file().
           -taxassign_file : See taxassign_file().
           Use either -cluster_file or -taxassign_file
 Returns : a Bio::Community::Tools::RepresentativeIdConverter object

=cut


package Bio::Community::Tools::RepresentativeIdConverter;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;
use Bio::Community::IO;
use Bio::Community::Meta;


extends 'Bio::Root::Root';


=head2 metacommunity

 Function: Get/set communities, given as metacommunity, to summarize.
 Usage   : my $meta = $summarizer->metacommunity;
 Args    : A Bio::Community::Meta object
 Returns : A Bio::Community::Meta object

=cut

has metacommunity => (
   is => 'rw',
   isa => 'Bio::Community::Meta',
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-metacommunity',
);


=head2 cluster_file

 Function: Get / set the tab-delimited file that defines the OTU clusters. The
           columns are: OTU ID, ID of the representative sequence, IDs of the
           other sequences in the OTU. For example:

               0	367523
               1	187144
               2	544886	544649
               3	310669
               4	355095	310677	347705	563209

           The OTU files distributed by Greengenes use this format (e.g.,
           99_otu_map.txt).
 Usage   : $summarizer->cluster_file('99_otu_map.txt');
 Args    : OTU cluster file name
 Returns : OTU cluster file name

=cut

has cluster_file => (
   is => 'rw',
   isa => 'Maybe[Str]',
   required => 1,
   lazy => 1,
   default => undef,
   init_arg => '-cluster_file',
);


=head2 taxassign_file

 Function: Get / set the tab-delimited file that defines the OTU taxonomic
           assignemts. The first four columns (out of 12) should be: OTU ID,
           taxonomic string, E-value, taxonomic ID. For example:

           345     k__Bacteria; p__Actinobacteria; c__Actinobacteria; o__Actinomycetales; f__Propionibacteriaceae; g__Propionibacterium; s__acnes  5e-138  1042485 95.67   300     13      0       1       300     878     579
           346     k__Bacteria; p__Firmicutes; c__Bacilli; o__; f__; g__; s__      8e-134  1064834 99.59   245     1       0       1       245     909     665
           347     k__Bacteria; p__Proteobacteria; c__Gammaproteobacteria; o__Pseudomonadales; f__Pseudomonadaceae; g__Pseudomonas; s__    2e-103  959954  98.99   198     2       0       103     300     718     521

           The taxonomic assignment files generated by QIIME (rep_set_tax_assignments.txt)
           follow this format.
 Usage   : $summarizer->taxassign_file('rep_set_tax_assignments.txt');
 Args    : taxonomic assignment file name
 Returns : taxonomic assignment file name

=cut

has taxassign_file => (
   is => 'rw',
   isa => 'Maybe[Str]',
   required => 1,
   lazy => 1,
   default => undef,
   init_arg => '-taxassign_file',
);


=head2 get_converted_meta

 Function: Convert the communities and return the corresponding metacommunity.
 Usage   : my $meta_by_otu = $converter->get_converted_meta;
 Args    : None
 Returns : A Bio::Community::Meta object

=cut

method get_converted_meta () {

   if ( (defined $self->cluster_file) && (defined $self->taxassign_file) ) {
      $self->throw('Need to specify use either a cluster_file or a taxassign_file');
   }

   my $meta = $self->metacommunity;
   my $meta2 = Bio::Community::Meta->new;

   my $file = $self->cluster_file || $self->taxassign_file;
   if (not defined $file) {
      $self->throw("No cluster file or taxonomic assignment file was provided");
   }
   my $id2repr = $self->_read_repr_file(
      $file,
      defined $self->cluster_file ? 'cluster' : 'taxo',
   );

   while (my $community = $meta->next_community) {
      my $name = $community->name;
      my $use_weights = $community->use_weights;
      my $community2 = Bio::Community->new(
         -name        => $name,
         -use_weights => $use_weights,
      );
      while (my $member = $community->next_member) {

         my $id = $member->id;
         my $count = $community->get_count($member);
         my $repr_id = $id2repr->{$id};

         if (not defined $repr_id) {
            $self->warn("Could not find representative sequence for member ID $id. Keeping original ID.\n");
            $repr_id = $id;
         }

         my $member2 = $community2->get_member_by_id($repr_id);
         if (not defined $member2) {
            # Member is new. Create it.
            $member2 = $member->clone;
            $member2->id($repr_id);
         }

         $community2->add_member( $member2, $count );

      }
      $meta2->add_communities([$community2]);
   }

   return $meta2;
};


method _read_repr_file ( $file, $type ) {
   # Type is either 'cluster' for an OTU cluster file, or 'taxo' for a taxonomic
   # assignment file.
   my $col_off;
   my %id2repr;
   my $num_seqs;
   open my $in, '<', $file or $self->throw("Could not read file '$file'\n$!");
   while (my $line = <$in>) {
      chomp $line;
      next if $line =~ m/^\s*$/;
      my @elems = split "\t", $line;
      my ($repr_id, $seq_ids);
      if ($type eq 'cluster') {
         shift @elems; # cluster ID
         $repr_id = shift @elems;
         $seq_ids = \@elems;
         push @$seq_ids, $repr_id;
      } elsif ($type eq 'taxo') {
         $repr_id = $elems[3];
         $seq_ids = [ $elems[0] ];
      } else {
         $self->throw("Internal error: Unexpected type '$type'");
      }
      for my $seq_id (@$seq_ids) {
         $id2repr{$seq_id} = $repr_id;
         $num_seqs++; # seq_id
      }
   }
   close $in;
   if ($num_seqs <= 0) {
      $self->throw("No entries found in file $file\n");
   }
   return \%id2repr;
}


__PACKAGE__->meta->make_immutable;

1;
