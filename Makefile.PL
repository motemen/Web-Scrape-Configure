use inc::Module::Install;
name 'Web-Scrape-Configure';
all_from 'lib/Web/Scrape/Configure.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
