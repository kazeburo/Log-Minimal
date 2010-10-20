use strict;
use Test::More tests => 11;

BEGIN { use_ok 'Log::Minimal' }

use Log::Minimal;

{
    local $Log::Minimal::PRINT = sub { join(" ", @_) };
    like( critf("crit%d", 1), qr/crit1/ );
    like( warnf("warn"), qr/warn/ );
    like( infof('in%fo'), qr/in%fo/ );
    ok( !debugf("debug") );
    local $ENV{LM_DEBUG} = 1;
    like( debugf("debug"), qr/debug/ );
}

{
    local $Log::Minimal::PRINT = sub { join(" ", @_) };
    like( critff("crit%d",1), qr/crit1/ );
    like( warnff("warn"), qr/warn/ );
    like( infoff('in%fo'), qr/in%fo/ );
    ok( !debugff("debug") );
    local $ENV{LM_DEBUG} = 1;
    like( debugff("debug"), qr/debug/ );
}

