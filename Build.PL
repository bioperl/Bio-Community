#!/usr/bin/perl -w

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    dist_name            => 'Bio-Community',
    module_name          => 'Bio::Community', # look here for version number
    dist_author          => 'BioPerl Team <bioperl-l@bioperl.org>',
    dist_abstract        => 'Modules to represent and manipulate communities of biological organisms',
    license              => 'perl',
    recursive_test_files => 1,
    create_license       => 1,
    meta_merge           => {
                             'resources' => {
                                             'repository' => 'git://github.com/bioperl/Bio-Community.git',
                                             'homepage'   => 'http://www.bioperl.org',
                                             'bugtracker' => 'https://redmine.open-bio.org/projects/bioperl/',
                                            },
                            },
    build_requires       => {
                             'Test::Number::Delta'          =>  0,
                             # Modules for author tests
                             #'Test::Pod::Coverage'         =>  1.00,
                             #'Pod::Coverage::Moose'        =>  0,
                            },
    requires             => {
                             'perl'                         => '5.10.0',
                             'Bio::Root::Version'           => '1.006922',
                             'DateTime'                     =>  0,
                             'Getopt::Euclid'               => '0.4.3',
                             'JSON::XS'                     =>  0, # biom format
                             'Hash::Util'                   =>  0,
                             'Math::Random::MT'             =>  0, # PRNG role
                             'Module::Runtime'              =>  0, # load IO drivers
                             'Method::Signatures'           =>  0,
                             'Moose'                        =>  0,
                             'MooseX::NonMoose'             =>  0,
                             'MooseX::StrictConstructor'    =>  0,
                             'Parallel::Iterator'           =>  0, # community member iteration
                             'PerlIO::eol'                  =>  0, # IO portable line endings
                             'Scalar::Util'                 =>  0,
                             'Tie::IxHash'                  =>  0, # metacommunity
                            },
    recommends           => {
                             #'Clone::Fast'                 =>  0, # C bindings for Bio::Root::clone(). Broken in 0.97?!
                             'Math::BigInt::GMP'            =>  0, # C bindings for arithmetic
                            },
    script_files         => [
                             'scripts/bc_clean_shrapnel',
                             'scripts/bc_convert_files',
                             'scripts/bc_correct_misassignments',
                             'scripts/bc_get_info',
                             'scripts/bc_manage_samples',
                             'scripts/bc_measure_distance',
                             'scripts/bc_rarefy',
                             'scripts/bc_relative_to_absolute',
                             'scripts/bc_remove_unexpected_members',
                             'scripts/bc_summarize',
                             'scripts/bc_use_repr_id',
                            ],
    recursive_test_files => 1,
    dynamic_config       => 1,
);

$build->create_build_script;

exit;
