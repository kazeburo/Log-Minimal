
use strict;

package OLObj;

use overload
    '0+' => \&numelic,
    '""' => \&stringfy;

sub new {
    my ($class, $value) = @_;
    bless \$value, $class;
};

sub numelic {
    my $self = shift;
    $$self;
}

sub stringfy {
    my $self = shift;
    qq!"$$self"!;
}

package Foo;

sub new {
    my ($class, $value) = @_;
    bless \$value, $class;
};

package main;

use Test::More;

BEGIN { use_ok 'Log::Minimal' }

use Log::Minimal;

local $ENV{LM_DEBUG} = 0;

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
    local $Log::Minimal::PRINT = sub { join(" ", @_) };
    local $Log::Minimal::ESCAPE_WHITESPACE = 0;
    like( critf("debu\t\r\ng"), qr/debu\t\r\ng/ );
}

use t::LogTest;

{
    local $Log::Minimal::PRINT = sub { join(" ", @_) };
    like t::LogTest::logtest("crit%d",1), qr/LogTest\.pm/;

    local $Log::Minimal::TRACE_LEVEL = $Log::Minimal::TRACE_LEVEL + 1;
    unlike t::LogTest::logtest("crit%d",1), qr/LogTest\.pm/;
}

{
    like( ddf(\"foo"), qr/\\'foo'/ );
    like( ddf("foo\r\nbar"), qr/foo\r\nbar/ );
    is( ddf({"a" => 1, "b" => 2}), "{'a' => 1,'b' => 2}" );


    local $Log::Minimal::PRINT = sub { join(" ", @_) };
    local $Log::Minimal::AUTODUMP = 1;
    my $ol = OLObj->new("foo");
    like( warnf("%s",$ol), qr/"foo"/);
    like( warnf( $ol ), qr/"foo"/);
    my $ol2 = OLObj->new(200);
    like( warnf("%f",$ol2), qr/200\.00/);
    my $foo = Foo->new("foo");
    like( warnf($foo), qr/bless.+foo.+Foo/);
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

