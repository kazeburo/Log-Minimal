package main;

use Test::More;
use Log::Minimal;

eval {
    croakf "foo";
};
like $@, qr/ERROR/;

eval {
    croakff "foo";
};
like $@, qr/ERROR/;

done_testing;

