
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

done_testing();

package Foo;

use Log::Minimal env_debug => 'PM_DEBUG';

sub bar {
    debugf("%s", join(' ', @_));
}

