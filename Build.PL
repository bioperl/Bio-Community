#!/usr/bin/perl -w

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    dist_name            => 'Bio::Community',
    dist_version         => '0.01',
    module_name          => 'Bio::Community',
    dist_author          => 'BioPerl Team <bioperl-l@bioperl.org>',
    dist_abstract        => 'Bio::Community - modules to represent and manipulate communities of organisms',
    license              => 'perl',
    recursive_test_files => 1,
    create_license       => 1,
    meta_merge           => {
	                     'resources' => {
				         'repository' => '',
	                                    },
			    },
    requires             => {
                             'perl'                => '5.10.0',
                             'Bio::Root::Version'  => '1.006900',
                             'Moose'               => 0,
                            },
    recursive_test_files => 1,
    dynamic_config       => 1,
);

$build->create_build_script;

exit;
