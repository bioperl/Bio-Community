use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    t::TestTableRole
);


my ($in, $out);

my $file = test_output_file();


# Read linux tab-delimited file

ok $in = t::TestTableRole->new(
   -file => test_input_file('table.txt'),
), 'Read linux table';
is $in->delim, "\t";
is $in->_get_max_col, 3;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';
is $in->_get_value(1, 3), 'soda lake';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(2, 2),  241;
is $in->_get_value(2, 3),  334;
is $in->_get_value(3, 1), 'Goatpox virus';
is $in->_get_value(3, 2),  '"0"';
is $in->_get_value(3, 3),  1023.9;
is $in->_get_value(4, 1), 'Lumpy skin disease virus';
is $in->_get_value(4, 2), '';
is $in->_get_value(4, 3),  123;

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 4), undef;
is $in->_get_value(6, 1), undef;
is $in->_get_value(1, 10), undef;

$in->close;


# Read win32 tab-delimited file

ok $in = t::TestTableRole->new(
   -file => test_input_file('table_win32.txt'),
), 'Read win32 table';
is $in->delim, "\t";
is $in->_get_max_col, 3;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';
is $in->_get_value(1, 3), 'soda lake';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(2, 2),  241;
is $in->_get_value(2, 3),  334;
is $in->_get_value(3, 1), 'Goatpox virus';
is $in->_get_value(3, 2),  0;
is $in->_get_value(3, 3),  1023;
is $in->_get_value(4, 1), 'Lumpy skin disease virus';
is $in->_get_value(4, 2),  39;
is $in->_get_value(4, 3),  123;

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 4), undef;

$in->close;


# Write and read tab-delimited file

ok $out = t::TestTableRole->new( -file => '>'.$file ), 'Write tab-delimited table';
is $out->delim, "\t";
is $out->_get_max_col, 1;
is $out->_get_max_line, 1;

ok $out->_set_value(1, 1, 'Species');
ok $out->_set_value(1, 2, 'gut');
ok $out->_set_value(1, 3, 'soda lake');
ok $out->_set_value(3, 3,  1023.9);
ok $out->_set_value(3, 2,  '"0"');
ok $out->_set_value(3, 1, 'Goatpox virus');
ok $out->_set_value(4, 1, 'Lumpy skin disease virus');
ok $out->_set_value(4, 2, '');
ok $out->_set_value(4, 3,  123);
ok $out->_set_value(2, 1, 'Streptococcus');
ok $out->_set_value(2, 2,  241);
ok $out->_set_value(2, 3,  334);

$out->close;

ok $in = t::TestTableRole->new( -file => $file ), 'Re-read tab-delimited table';
is $in->delim, "\t";
is $in->_get_max_col, 3;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';
is $in->_get_value(1, 3), 'soda lake';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(2, 2),  241;
is $in->_get_value(2, 3),  334;
is $in->_get_value(3, 1), 'Goatpox virus';
is $in->_get_value(3, 2),  '"0"';
is $in->_get_value(3, 3),  1023.9;
is $in->_get_value(4, 1), 'Lumpy skin disease virus';
is $in->_get_value(4, 2), '';
is $in->_get_value(4, 3),  123;

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 4), undef;
is $in->_get_value(6, 1), undef;
is $in->_get_value(1, 10), undef;

# Note: zero or negative numbers are not valid input and cause an exception
#is $in->_get_value(6, 0), undef; 
#is $in->_get_value(0, 10), undef;

$in->close;
unlink $file;


# Write and read tab-delimited file (again, but in a different order)

ok $out = t::TestTableRole->new( -file => '>'.$file ), 'Write tab-delimited table again';
is $out->delim, "\t";
is $out->_get_max_col, 1;
is $out->_get_max_line, 1;

ok $out->_set_value(2, 2,  241);
ok $out->_set_value(1, 2, 'gut');
ok $out->_set_value(1, 1, 'Species');
ok $out->_set_value(3, 1, 'Goatpox virus');
ok $out->_set_value(4, 1, 'Lumpy skin disease virus');
ok $out->_set_value(3, 2,  '"0"');
ok $out->_set_value(1, 3, 'soda lake');
ok $out->_set_value(3, 3,  1023.9);
ok $out->_set_value(4, 2, '');
ok $out->_set_value(4, 3,  123);
ok $out->_set_value(2, 1, 'Streptococcus');
ok $out->_set_value(2, 3,  334);

$out->close;

ok $in = t::TestTableRole->new( -file => $file ), 'Re-read tab-delimited table again';
is $in->delim, "\t";
is $in->_get_max_col, 3;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';
is $in->_get_value(1, 3), 'soda lake';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(2, 2),  241;
is $in->_get_value(2, 3),  334;
is $in->_get_value(3, 1), 'Goatpox virus';
is $in->_get_value(3, 2),  '"0"';
is $in->_get_value(3, 3),  1023.9;
is $in->_get_value(4, 1), 'Lumpy skin disease virus';
is $in->_get_value(4, 2), '';
is $in->_get_value(4, 3),  123;

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 4), undef;
is $in->_get_value(6, 1), undef;
is $in->_get_value(1, 10), undef;

$in->close;
unlink $file;


# Write and read double-space-delimited file

ok $out = t::TestTableRole->new(
   -file  => '>'.$file,
   -delim => '  ',
), 'Write double-space delimited table';

ok $out->_set_value(1, 1, 'Species');
ok $out->_set_value(1, 2, 'gut');
ok $out->_set_value(1, 3, 'soda_lake');
ok $out->_set_value(2, 1, 'Streptococcus');
ok $out->_set_value(2, 2,  241);
ok $out->_set_value(2, 3,  334);
ok $out->_set_value(3, 1, 'Goatpox_virus');
ok $out->_set_value(3, 2,  '"0"');
ok $out->_set_value(3, 3,  1023.9);
ok $out->_set_value(4, 1, 'Lumpy_skin_disease_virus');
ok $out->_set_value(4, 2, '');
ok $out->_set_value(4, 3,  123);

$out->close;

ok $in = t::TestTableRole->new(
   -file  => $file,
   -delim => '  ',
), 'Re-read double-space delimited table';
is $in->delim, '  ';
is $in->_get_max_col, 3;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';
is $in->_get_value(1, 3), 'soda_lake';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(2, 2),  241;
is $in->_get_value(2, 3),  334;
is $in->_get_value(3, 1), 'Goatpox_virus';
is $in->_get_value(3, 2),  '"0"';
is $in->_get_value(3, 3),  1023.9;
is $in->_get_value(4, 1), 'Lumpy_skin_disease_virus';
is $in->_get_value(4, 2), '';
is $in->_get_value(4, 3),  123;

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 4), undef;

$in->close;
unlink $file;


# Write and read file with specified string for missing abundance

ok $out = t::TestTableRole->new(
   -file           => '>'.$file,
   -missing_string => 'n/a',
), 'Write file with specified missing abundance string';
is $out->missing_string, 'n/a';

ok $out->_set_value(1, 1, 'Species');
ok $out->_set_value(1, 2, 'gut');
ok $out->_set_value(1, 3, 'soda_lake');
ok $out->_set_value(2, 1, 'Streptococcus');
ok $out->_set_value(2, 2,  241);
ok $out->_set_value(2, 3,  334);
ok $out->_set_value(3, 1, 'Goatpox_virus');
#ok $out->_set_value(3, 2,  '"0"');
ok $out->_set_value(3, 3,  1023.9);
ok $out->_set_value(4, 1, 'Lumpy_skin_disease_virus');
#ok $out->_set_value(4, 2, '');
ok $out->_set_value(4, 3,  123);

$out->close;

ok $in = t::TestTableRole->new(
   -file  => $file,
), 'Re-read file with specified missing abundance string';
is $in->_get_max_col, 3;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';
is $in->_get_value(1, 3), 'soda_lake';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(2, 2),  241;
is $in->_get_value(2, 3),  334;
is $in->_get_value(3, 1), 'Goatpox_virus';
is $in->_get_value(3, 2), 'n/a';
is $in->_get_value(3, 3),  1023.9;
is $in->_get_value(4, 1), 'Lumpy_skin_disease_virus';
is $in->_get_value(4, 2), 'n/a';
is $in->_get_value(4, 3),  123;

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 4), undef;

$in->close;
unlink $file;


# Write and read table with a single line

ok $out = t::TestTableRole->new( -file => '>'.$file ), 'Write single-line table';

ok $out->_set_value(1, 1, 'sp.');
ok $out->_set_value(1, 1, 'Species');
ok $out->_set_value(1, 2, 'gut');
ok $out->_set_value(1, 3, 'soda lake');

$out->close;

ok $in = t::TestTableRole->new( -file => $file ), 'Re-read single-line table';
is $in->delim, "\t";
is $in->_get_max_col, 3;
is $in->_get_max_line, 1;

is $in->_get_value(1, 3), 'soda lake';
is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';

is $in->_get_value(1, 4), undef;
is $in->_get_value(2, 1), undef;

$in->close;
unlink $file;


# Write and read table with a single column

ok $out = t::TestTableRole->new( -file => '>'.$file ), 'Write single-column table';

ok $out->_set_value(1, 1, 'Species');
ok $out->_set_value(3, 1, 'Goatpox virus');
ok $out->_set_value(2, 1, 'Streptococcus');
ok $out->_set_value(4, 1, 'Lumpy skin disease virus');

$out->close;

ok $in = t::TestTableRole->new( -file => $file ), 'Re-read single-column table';
ok $in->_read_table;
is $in->delim, "\t";
is $in->_get_max_col, 1;
is $in->_get_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(3, 1), 'Goatpox virus';
is $in->_get_value(4, 1), 'Lumpy skin disease virus';

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 2), undef;

$in->close;
unlink $file;


# Write and read table that does not span the entire file

ok $out = t::TestTableRole->new(
   -file       => '>'.$file,
), 'Write table that does not span the entire file';

ok $out->_print("<table>\n");
ok $out->_set_value(1, 1, 'Streptococcus');
ok $out->_set_value(1, 2,  241);
ok $out->_set_value(1, 3,  334);
ok $out->_set_value(2, 1, 'Goatpox virus');
ok $out->_set_value(2, 2,  '"0"');
ok $out->_set_value(2, 3,  1023.9);
ok $out->_write_table;
ok $out->_print("</table>\n");

$out->close;

ok $in = t::TestTableRole->new(
   -file       => $file,
   -start_line => 2, 
   -end_line   => 3,
), 'Re-read table that does not span the entire file';
is $in->delim, "\t";
is $in->_get_max_col, 3;
is $in->_get_max_line, 2;

is $in->_get_value(1, 1), 'Streptococcus';
is $in->_get_value(1, 2),  241;
is $in->_get_value(1, 3),  334;
is $in->_get_value(2, 1), 'Goatpox virus';
is $in->_get_value(2, 2),  '"0"';
is $in->_get_value(2, 3),  1023.9;

is $in->_get_value(3, 1), undef;
is $in->_get_value(1, 4), undef;

$in->close;
unlink $file;

done_testing();

