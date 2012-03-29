use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    t::TestTable
);


my $in;


# Tab-delimited file (default)

ok $in = t::TestTable->new( -file => test_input_file('table.txt') );
is $in->delim, "\t";
is $in->_max_col, 3;
is $in->_max_line, 4;

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


# Win32 tab-delimited file

ok $in = t::TestTable->new( -file => test_input_file('table_win32.txt') );
is $in->delim, "\t";
is $in->_max_col, 3;
is $in->_max_line, 4;

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


# Double-space-delimited file

ok $in = t::TestTable->new(
   -file  => test_input_file('table_space_delim.txt'),
   -delim => '  ',
);
is $in->delim, '  ';
is $in->_max_col, 3;
is $in->_max_line, 4;

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


# Table that does not span the entire file

ok $in = t::TestTable->new(
   -file       => test_input_file('table.txt'),
   -start_line => 2, 
   -end_line   => 3,
);
is $in->delim, "\t";
is $in->_max_col, 3;
is $in->_max_line, 2;

is $in->_get_value(1, 1), 'Streptococcus';
is $in->_get_value(1, 2),  241;
is $in->_get_value(1, 3),  334;
is $in->_get_value(2, 1), 'Goatpox virus';
is $in->_get_value(2, 2),  '"0"';
is $in->_get_value(2, 3),  1023.9;

is $in->_get_value(3, 1), undef;
is $in->_get_value(1, 4), undef;

$in->close;


# Table with a single line

ok $in = t::TestTable->new( -file => test_input_file('table_single_line.txt') );
is $in->delim, "\t";
is $in->_max_col, 3;
is $in->_max_line, 1;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(1, 2), 'gut';
is $in->_get_value(1, 3), 'soda lake';

is $in->_get_value(1, 4), undef;
is $in->_get_value(2, 1), undef;

$in->close;


# Table with a single column

ok $in = t::TestTable->new( -file => test_input_file('table_single_column.txt') );
ok $in->_read_table;
is $in->delim, "\t";
is $in->_max_col, 1;
is $in->_max_line, 4;

is $in->_get_value(1, 1), 'Species';
is $in->_get_value(2, 1), 'Streptococcus';
is $in->_get_value(3, 1), 'Goatpox virus';
is $in->_get_value(4, 1), 'Lumpy skin disease virus';

is $in->_get_value(5, 1), undef;
is $in->_get_value(1, 2), undef;

$in->close;


done_testing();

exit;


