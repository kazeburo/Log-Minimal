use strict;
use Test::More;

BEGIN { use_ok 'Log::Minimal' }

use Log::Minimal;

{
    local $Log::Minimal::PRINT = sub { join(" ", @_) };
    like( critf("crit%d", 1), qr/crit1/ );
    like( warnf("warn"), qr/warn/ );
    like( infof('in%fo'), qr/in%fo/ );
    ok( !debugf("debug") );
    local $ENV{LM_DEBUG} = 1;
    like( debugf("debu\t\r\ng"), qr/debu\\t\\r\\ng/ );
}

{
    local $Log::Minimal::PRINT = sub { join(" ", @_) };
    like( critff("crit%d",1), qr/crit1/ );
    like( warnff("warn"), qr/warn/ );
    like( infoff('in%fo'), qr/in%fo/ );
    ok( !debugff("debug") );
    local $ENV{LM_DEBUG} = 1;
    like( debugff("debu\t\r\ng"), qr/debu\\t\\r\\ng/ );
}


{
    like( ddd(\"foo"), qr/\\'foo'/ );
    like( ddd("foo\r\nbar"), qr/foo\r\nbar/ );   
}


{
    local $Log::Minimal::PRINT = sub { join( "", @_) };
    local $Log::Minimal::LOG_LEVEL = "MUTE";
    ok( ! critf("crit") );

    local $Log::Minimal::LOG_LEVEL = "CRITICAL";
    ok( critf("crit") );
    ok( ! warnf("warn") );

    local $Log::Minimal::LOG_LEVEL = "WARN";
    ok( critf("crit") );
    ok( warnf("warn") );
    ok( !debugf("debug") );

    local $Log::Minimal::LOG_LEVEL = "INFO";
    ok( critf("crit") );
    ok( warnf("warn") );
    ok( infof("info") );
    ok( !debugf("debug") );

    local $Log::Minimal::LOG_LEVEL = "DEBUG";
    ok( !debugf("debug") );

    local $ENV{LM_DEBUG} = 1;
    ok( debugf("debug") );

    local $Log::Minimal::LOG_LEVEL = "INFO";
    ok( !debugf("debug") );

    local $Log::Minimal::LOG_LEVEL = "DEBUG";
    ok( debugf("debug") );

    local $Log::Minimal::LOG_LEVEL = "MUTE";
    ok( !debugf("debug") );
}

done_testing();

