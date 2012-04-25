use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    Bio::Community::Tools::FormatGuesser
);


my ($guesser, $text, $fh, $file, $line);


# Bare object

ok $guesser = Bio::Community::Tools::FormatGuesser->new(), 'bare object';
isa_ok $guesser, 'Bio::Community::Tools::FormatGuesser';


# Test mixed input

$text = <<EOF;
{
    "id":null,
    "format": "Biological Observation Matrix 0.9.1-dev",
    "format_url": "http://biom-format.org",
    "type": "OTU table",
    "generated_by": "QIIME revision 1.4.0-dev",
    "date": "2011-12-19T19:00:00",
EOF

open $fh, '<', test_input_file('qiime_w_greengenes_taxo.txt');

$file = test_input_file('gaas_compo.txt');
ok $guesser = Bio::Community::Tools::FormatGuesser->new(
   -file => $file, # gaas
   -text => $text, # biom
   -fh   => $fh,   # qiime
), 'mixed input';
is $guesser->file, $file;
is $guesser->text, $text;
is $guesser->fh, $fh;

is $guesser->guess, 'biom';

close $fh;

# Test input text

ok $guesser = Bio::Community::Tools::FormatGuesser->new(), 'text input';
ok $guesser->text($text);
is $guesser->guess, 'biom';


# Test input filehandle

open $fh, '<', test_input_file('biom_minimal_sparse.biom');
ok $guesser = Bio::Community::Tools::FormatGuesser->new( -fh => $fh ), 'filehandle input';
is $guesser->fh, $fh;
is $guesser->guess, 'biom';
$line = <$fh>;
chomp $line;
is $line, '{', 'filehandle was rewinded';
close $fh;


# Test biom input file

$file = test_input_file('biom_minimal_sparse.biom');
ok $guesser = Bio::Community::Tools::FormatGuesser->new( -file => $file ), 'biom file';
is $guesser->file, $file;
is $guesser->guess, 'biom';


# Test generic input file

$file = test_input_file('generic_table.txt');
ok $guesser = Bio::Community::Tools::FormatGuesser->new( -file => $file ), 'generic file';
is $guesser->file, $file;
is $guesser->guess, 'generic';

$file = test_input_file('qiime_w_silva_taxo_L2.txt');
ok $guesser = Bio::Community::Tools::FormatGuesser->new( -file => $file ), 'generic file';
is $guesser->file, $file;
is $guesser->guess, 'generic';


# Test gaas input file

$file = test_input_file('gaas_compo.txt');
ok $guesser = Bio::Community::Tools::FormatGuesser->new( -file => $file ), 'gaas file';
is $guesser->file, $file;
is $guesser->guess, 'gaas';


# Test qiime input file

$file = test_input_file('qiime_w_no_taxo.txt');
ok $guesser = Bio::Community::Tools::FormatGuesser->new( -file => $file ), 'qiime file';
is $guesser->file, $file;
is $guesser->guess, 'qiime';

$file = test_input_file('qiime_w_greengenes_taxo.txt');
ok $guesser = Bio::Community::Tools::FormatGuesser->new( -file => $file ), 'qiime file';
is $guesser->file, $file;
is $guesser->guess, 'qiime';


# Test unknown format

$file = test_input_file('lorem_ipsum.txt');
ok $guesser = Bio::Community::Tools::FormatGuesser->new( -file => $file ), 'unknown file';
is $guesser->file, $file;
is $guesser->guess, undef;

# Test empty format

$text = '';
ok $guesser = Bio::Community::Tools::FormatGuesser->new( -text => $text ), 'empty text';
is $guesser->text, $text;
is $guesser->guess, undef;


done_testing();

exit;

