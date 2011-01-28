use inc::Module::Install;
name 'Cache-KyotoTycoon-Serialize';

my $filepath = 'lib/Cache/KyotoTycoon/Serialize.pm';
all_from $filepath;
readme_from $filepath;
readme_pod_from $filepath;
githubmeta;

requires 'Storable';
requires 'Sub::Install';
requires 'List::MoreUtils';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';

auto_set_repository;
auto_include;
WriteAll;
