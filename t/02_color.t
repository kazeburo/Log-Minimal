package main;

use Test::More;
use Log::Minimal;

local $Log::Minimal::PRINT = sub { join(" ", @_) };
local $Log::Minimal::COLOR = 1;

like( warnf("foo"), qr/\e\[/);

eval {
    croakf "foo";
};
like $@, qr/\e\[/;

{
    local $Log::Minimal::PRINT = sub { $_[4] };
    unlike( warnf("foo"), qr/\e\[/);
}

done_testing;

