# BioPerl module for Bio::Community::Tools::RepresentativeIdConverter
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::Tools::RepresentativeIdConverter - Convert member ID to OTU representative ID

=head1 SYNOPSIS

  use Bio::Community::Tools::RepresentativeIdConverter;


  my $converter = Bio::Community::Tools::Summarizer->new(
     -metacommunity => $meta,
     -cluster_file  => 'gg_99_otu_map.txt',
  );
  my $meta_by_otu = $converter->get_converted_meta;

=head1 DESCRIPTION

Given a metacommunity and an OTU cluster map file, replace the ID of every
member by that of its OTU cluster representative and add it in a new
metacommunity.

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

 Function: Create a new Bio::Community::Tool::RepresentativeIdConverter object
 Usage   : my $converter = Bio::Community::Tool::RepresentativeIdConverter->new(
              -metacommunity => $meta,
           );
 Args    : -metacommunity   : See metacommunity().
           -cluster_file    : See cluster_file().

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

 Usage   : $summarizer->cluster_file('gg_99_otu_map.txt');
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


=head2 get_converted_meta

 Function: Convert the communities and return the corresponding metacommunity.
 Usage   : my $meta_by_otu = $converter->get_converted_meta;
 Args    : None
 Returns : A Bio::Community::Meta object

=cut

method get_converted_meta () {
   my $meta = $self->metacommunity;
   my $meta2 = Bio::Community::Meta->new;

   my $id2repr = $self->_read_cluster_file( $self->cluster_file );

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


method _read_cluster_file ( $file ) {
   my %id2repr;
   my $num_seqs;
   open my $in, '<', $file or die "Error: Could not read file $file\n$!\n";
   while (my $line = <$in>) {
      chomp $line;
      my ($clust_id, $repr_id, @seq_ids) = split "\t", $line;
      $id2repr{$repr_id} = $repr_id;
      $num_seqs++; # repr_id
      for my $seq_id (@seq_ids) {
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
