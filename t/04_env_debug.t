
use strict;

use Test::More;

use Log::Minimal;

{
    local $ENV{LM_DEBUG} = 1;
    local $ENV{PM_DEBUG} = 1;

    local $Log::Minimal::PRINT = sub { join(" ", @_) };
    like( debugf("main"),  qr/main/ );
    like( Foo::bar("foo"), qr/foo/  );
}

{
    local $ENV{LM_DEBUG} = 1;
    local $ENV{PM_DEBUG} = 0;

    local $Log::Minimal::PRINT = sub { join(" ", @_) };
    like( debugf("main"),  qr/main/ );
    ok( ! Foo::bar("foo") );
}

{
    local $ENV{LM_DEBUG} = 0;
    local $ENV{PM_DEBUG} = 1;

    local $Log::Minimal::PRINT = sub { join(" ", @_) };
    ok( ! debugf("main") );
    like( Foo::bar("foo"), qr/foo/  );
}

{
    local $ENV{LM_DEBUG} = 0;
    local $ENV{PM_DEBUG} = 0;

    local $Log::Minimal::PRINT = sub { join(" ", @_) };
    ok( ! debugf("main") );
    ok( ! Foo::bar("foo") );
}

{
    eval {
        Foo::foo('undefined subroutine');
    };
    ok($@);
}

done_testing();

package Foo;

use Log::Minimal env_debug => 'PM_DEBUG', 'debugf';

sub bar {
    debugf("%s", join(' ', @_));
}

sub foo {
    warnf("%s", join(' ', @_));
}
