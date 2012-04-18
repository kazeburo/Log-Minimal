package main;

BEGIN {
    # enable coloring by default
    $ENV{LM_COLOR} = 1;
}
use Test::More;
use Log::Minimal;

subtest 'coloring by default' => sub {
    local $Log::Minimal::PRINT = sub { join(" ", @_) };

    like( warnf("foo"), qr/\e\[/);

    eval {
        croakf "foo";
    };
    like $@, qr/\e\[/;

    {
        local $Log::Minimal::PRINT = sub { $_[4] };
        unlike( warnf("foo"), qr/\e\[/);
    }
};

subtest 'suppress coloring by local variable' => sub {
    local $Log::Minimal::PRINT = sub { join(" ", @_) };
    local $Log::Minimal::COLOR = 0;

    unlike( warnf("foo"), qr/\e\[/);

    eval {
        croakf "foo";
    };
    unlike $@, qr/\e\[/;

    {
        local $Log::Minimal::PRINT = sub { $_[4] };
        unlike( warnf("foo"), qr/\e\[/);
    }
};

done_testing;
