#! /usr/bin/env perl

use strict;
use warnings;
use lib 'lib';
use Bio::Community::IO;
use Bio::Community::Tools::Accumulator;

my $meta = Bio::Community::IO->new(-file => 't/data/qiime_w_no_taxo.txt')->next_metacommunity;

my $acc = Bio::Community::Tools::Accumulator->new(
   -metacommunity => $meta,
   -type          => 'rarefaction',
   -nof_ticks     => 10,
   -repetitions   => 10,
   #-alpha        => 
);

my $res = $acc->get_curve;
