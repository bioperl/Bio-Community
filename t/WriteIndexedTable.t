use strict;
use warnings;
use Bio::Root::Test;

use_ok($_) for qw(
    t::IndexedTable
);


my $out;


# Tab-delimited file (default)

ok $out = t::IndexedTable->new( -file => '>'.'indexed_table.txt' );
is $out->delim, "\t";
is $out->_max_col, 1;
is $out->_max_line, 1;

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

use Data::Dumper; print Dumper($out->_index);


$out->close;


done_testing();

exit;


