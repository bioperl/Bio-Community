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
                             'Bio::Root::Version'           => '>1.006902',
                             'Bio::DB::Taxonomy'            =>  0, # >1.006902
                             'Method::Signatures'           =>  0,
                             'Moose'                        =>  0,
                             'Moose::Util::TypeConstraints' =>  0,
                             'MooseX::NonMoose'             =>  0,
                             'MooseX::StrictConstructor'    =>  0,
                             'Parallel::Iterator'           =>  0,
                            },
    recommends           => {
                              # Clone Bio::Community objects through the Bio::Root::clone() method
                             'Clone'                        => 0,
                            },
    script_files         => [
                             'scripts/bp_community_bootstrap.pl',
                             'scripts/bp_community_convert.pl',
                             'scripts/bp_community_summarize.pl',
                            ],
    recursive_test_files => 1,
    dynamic_config       => 1,
);

$build->create_build_script;

exit;
