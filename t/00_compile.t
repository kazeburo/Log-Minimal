use strict;
use Test::More tests => 11;

BEGIN { use_ok 'Log::Minimal' }

use Log::Minimal;

{
    local $Log::Minimal::PRINT = sub { join(" ", @_) };
    like( critf("crit"), qr/crit/ );
    like( warnf("warn"), qr/warn/ );
    like( infof("info"), qr/info/ );
    ok( !debugf("debug") );
    local $ENV{LM_DEBUG} = 1;
    like( debugf("debug"), qr/debug/ );
}

{
    local $Log::Minimal::PRINT = sub { join(" ", @_) };
    like( critff("crit"), qr/crit/ );
    like( warnff("warn"), qr/warn/ );
    like( infoff("info"), qr/info/ );
    ok( !debugff("debug") );
    local $ENV{LM_DEBUG} = 1;
    like( debugff("debug"), qr/debug/ );
}

