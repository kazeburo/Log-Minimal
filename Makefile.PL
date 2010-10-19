use inc::Module::Install;
name 'Log-Minimal';
all_from 'lib/Log/Minimal.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
