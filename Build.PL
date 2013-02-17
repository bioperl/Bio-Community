#!/usr/bin/perl -w

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
    dist_name            => 'Bio-Community',
    dist_version         => '0.01',
    module_name          => 'Bio::Community',
    dist_author          => 'BioPerl Team <bioperl-l@bioperl.org>',
    dist_abstract        => 'Bio::Community - Represent and manipulate communities of biological organisms',
    license              => 'perl',
    recursive_test_files => 1,
    create_license       => 1,
    meta_merge           => {
                             'resources' => {
                                             'repository' => 'git://github.com/bioperl/Bio-Community.git',
                                             #'homepage'   => 'http://...',
                                             #'bugtracker' => 'http://...',
                                            },
                            },
    build_requires       => {
                             'Test::Number::Delta'          =>  0,
                            },
    requires             => {
                             'perl'                         => '5.10.0',
                             'Bio::Root::Version'           => '>1.006901',
                             'Bio::DB::Taxonomy'            =>  0, # >1.006901
                             'Getopt::Euclid'               => '0.4.0',
                             'Hash::Util'                   =>  0,
                             'Math::Random::MT'             =>  0, # sampler
                             'Method::Signatures'           =>  0,
                             'Moose'                        =>  0,
                             'Moose::Util::TypeConstraints' =>  0,
                             'MooseX::NonMoose'             =>  0,
                             'MooseX::StrictConstructor'    =>  0,
                             'Parallel::Iterator'           =>  0, # community member iteration
                             'Tie::IxHash'                  =>  0, # metacommunity
                            },
    recommends           => {
                              # Clone objects using Bio::Root::clone(). Uses a pure-Perl way if needed. Broken in 0.97?!
                             'Clone::Fast'                  => 0,
                            },
    script_files         => [
                             'scripts/bc_rarefy',
                             'scripts/bc_clean_shrapnel',
                             'scripts/bc_convert_files',
                             'scripts/bc_get_info',
                             'scripts/bc_manage_samples',
                             'scripts/bc_measure_distance',
                             'scripts/bc_summarize',
                            ],
    recursive_test_files => 1,
    dynamic_config       => 1,
);

$build->create_build_script;

exit;
