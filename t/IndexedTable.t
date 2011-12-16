use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    t::IndexedTable
);


my $in;


# Tab-delimited file (default)

ok $in = t::IndexedTable->new( -file => test_input_file('generic_table.txt') );
is $in->delim, "\t";
is $in->_max_col, 3;
is $in->_max_line, 4;

is $in->_get_indexed_value(1, 1), 'Species';
is $in->_get_indexed_value(1, 2), 'gut';
is $in->_get_indexed_value(1, 3), 'soda lake';
is $in->_get_indexed_value(2, 1), 'Streptococcus';
is $in->_get_indexed_value(2, 2),  241;
is $in->_get_indexed_value(2, 3),  334;
is $in->_get_indexed_value(3, 1), 'Goatpox virus';
is $in->_get_indexed_value(3, 2),  '"0"';
is $in->_get_indexed_value(3, 3),  1023.9;
is $in->_get_indexed_value(4, 1), 'Lumpy skin disease virus';
is $in->_get_indexed_value(4, 2), '';
is $in->_get_indexed_value(4, 3),  123;

is $in->_get_indexed_value(5, 1), undef;
is $in->_get_indexed_value(1, 4), undef;

is $in->_get_indexed_value(6, 1), undef;
is $in->_get_indexed_value(1, 10), undef;

# Note: zero or negative numbers are not valid input and cause an exception
#is $in->_get_indexed_value(6, 0), undef; 
#is $in->_get_indexed_value(0, 10), undef;

$in->close;


# Win32 tab-delimited file

ok $in = t::IndexedTable->new( -file => test_input_file('generic_table_win32.txt') );
is $in->delim, "\t";
is $in->_max_col, 3;
is $in->_max_line, 4;

is $in->_get_indexed_value(1, 1), 'Species';
is $in->_get_indexed_value(1, 2), 'gut';
is $in->_get_indexed_value(1, 3), 'soda lake';
is $in->_get_indexed_value(2, 1), 'Streptococcus';
is $in->_get_indexed_value(2, 2),  241;
is $in->_get_indexed_value(2, 3),  334;
is $in->_get_indexed_value(3, 1), 'Goatpox virus';
is $in->_get_indexed_value(3, 2),  0;
is $in->_get_indexed_value(3, 3),  1023;
is $in->_get_indexed_value(4, 1), 'Lumpy skin disease virus';
is $in->_get_indexed_value(4, 2),  39;
is $in->_get_indexed_value(4, 3),  123;

is $in->_get_indexed_value(5, 1), undef;
is $in->_get_indexed_value(1, 4), undef;

is $in->_get_indexed_value(6, 1), undef;
is $in->_get_indexed_value(1, 10), undef;

$in->close;


# Space-delimited file

ok $in = t::IndexedTable->new(
   -file  => test_input_file('generic_table_space_delim.txt'),
   -delim => ' ',
);
is $in->delim, ' ';
is $in->_max_col, 3;
is $in->_max_line, 4;

is $in->_get_indexed_value(1, 1), 'Species';
is $in->_get_indexed_value(1, 2), 'gut';
is $in->_get_indexed_value(1, 3), 'soda_lake';
is $in->_get_indexed_value(2, 1), 'Streptococcus';
is $in->_get_indexed_value(2, 2),  241;
is $in->_get_indexed_value(2, 3),  334;
is $in->_get_indexed_value(3, 1), 'Goatpox_virus';
is $in->_get_indexed_value(3, 2),  '"0"';
is $in->_get_indexed_value(3, 3),  1023.9;
is $in->_get_indexed_value(4, 1), 'Lumpy_skin_disease_virus';
is $in->_get_indexed_value(4, 2), '';
is $in->_get_indexed_value(4, 3),  123;

is $in->_get_indexed_value(5, 1), undef;
is $in->_get_indexed_value(1, 4), undef;

is $in->_get_indexed_value(6, 1), undef;
is $in->_get_indexed_value(1, 10), undef;

$in->close;


# file with whitelines at the end

done_testing();

exit;


