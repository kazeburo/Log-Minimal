# NAME

Log::Minimal - Minimal but customizable logger.

# SYNOPSIS

    use Log::Minimal;

    critf("%s","foo"); # 2010-10-20T00:25:17 [CRITICAL] foo at example.pl line 12
    warnf("%d %s %s", 1, "foo", $uri);
    infof('foo');
    debugf("foo"); print if $ENV{LM_DEBUG} is true

    # with full stack trace
    critff("%s","foo");
    # 2010-10-20T00:25:17 [CRITICAL] foo at lib/Example.pm line 10, example.pl line 12
    warnff("%d %s %s", 1, "foo", $uri);
    infoff('foo');
    debugff("foo"); print if $ENV{LM_DEBUG} is true

    my $serialize = ddf({ 'key' => 'value' });

    # die with formatted message
    croakf('foo');
    croakff('%s %s', $code, $message);

# DESCRIPTION

Log::Minimal is Minimal but customizable log module.

# EXPORT FUNCTIONS

- critf(($message:Str|$format:Str,@list:Array));

        critf("could't connect to example.com");
        critf("Connection timeout timeout:%d, host:%s", 2, "example.com");

    Display CRITICAL messages.
    When two or more arguments are passed to the function, 
    the first argument is treated as a format of printf. 

        local $Log::Minimal::AUTODUMP = 1;
        critf({ foo => 'bar' });
        critf("dump is %s", { foo => 'bar' });

    If $Log::Minimal::AUTODUMP is true, reference or object message is serialized with 
    Data::Dumper automatically.

- warnf(($message:Str|$format:Str,@list:Array));

    Display WARN messages.

- infof(($message:Str|$format:Str,@list:Array));

    Display INFO messages.

- debugf(($message:Str|$format:Str,@list:Array));

    Display DEBUG messages, if $ENV{LM\_DEBUG} is true.

- critff(($message:Str|$format:Str,@list:Array));

        critff("could't connect to example.com");
        critff("Connection timeout timeout:%d, host:%s", 2, "example.com");

    Display CRITICAL messages with stack trace.

- warnff(($message:Str|$format:Str,@list:Array));

    Display WARN messages with stack trace.

- infoff(($message:Str|$format:Str,@list:Array));

    Display INFO messages with stack trace.

- debugff(($message:Str|$format:Str,@list:Array));

    Display DEBUG messages with stack trace, if $ENV{LM\_DEBUG} is true.

- croakf(($message:Str|$format:Str,@list:Array));

    die with formatted $message

        croakf("critical error");
        # 2011-06-10T16:27:26 [ERROR] critical error at sample.pl line 23

- croakff(($message:Str|$format:Str,@list:Array));

    die with formatted $message with stack trace

- ddf($value:Any)

    Utility method that serializes given value with Data::Dumper;

        my $serialize = ddf($hashref);



# ENVIRONMENT VALUE

- $ENV{LM\_DEBUG}

    To print debugf and debugff messages, $ENV{LM\_DEBUG} must be true.

    You can change variable name from LM\_DEBUG to arbitrary string which is specified by "env\_debug" in use line. Changed variable name affects only in package locally.

        use Log::Minimal env_debug => 'FOO_DEBUG';
        

        $ENV{LM_DEBUG}  = 1;
        $ENV{FOO_DEBUG} = 0;
        debugf("hello"); # no output
        

        $ENV{FOO_DEBUG} = 1;
        debugf("world"); # print message

- $ENV{LM\_COLOR}

    $ENV{LM\_COLOR} is used as default value of $Log::Minimal::COLOR

- $ENV{LM\_DEFAULT\_COLOR}

    $ENV{LM\_DEFAULT\_COLOR} is used as default value of $Log::Minimal::DEFAULT\_COLOR

    Format of value is "LEVEL=FG;BG:LEVEL=FG;BG:...". "FG" and "BG" are optional.

    For example:

        export LM_DEFAULT_COLOR='debug=red:info=;cyan:critical=yellow;red'

# CUSTOMIZE

- $Log::Minimal::COLOR

    Coloring log messages. Disabled by default.

- $Log::Minimal::PRINT

    To change the method of outputting the log, set $Log::Minimal::PRINT.

        # with PSGI Application. output log with request uri.
        my $app = sub {
            my $env = shift;
            local $Log::Minimal::PRINT = sub {
                my ( $time, $type, $message, $trace,$raw_message) = @_;
                $env->{psgi.errors}->print(
                    "$time [$env->{SCRIPT_NAME}] [$type] $message at $trace\n");
            };
            run_app(...);
        }

    $message includes color sequences, If you want raw message text, use $raw\_message.
    default is

        sub {
          my ( $time, $type, $message, $trace,$raw_message) = @_;
          warn "$time [$type] $message at $trace\n";
        }

- $Log::Minimal::DIE

    To change the format of die message, set $Log::Minimal::DIE.

        local $Log::Minimal::PRINT = sub {
            my ( $time, $type, $message, $trace) = @_;
            die "[$type] $message at $trace\n"; # not need time
        };

    default is

        sub {
          my ( $time, $type, $message, $trace) = @_;
          die "$time [$type] $message at $trace\n";
        }

- $Log::Minimal::LOG\_LEVEL

    Set level to output log.

        local $Log::Minimal::LOG_LEVEL = "WARN";
        infof("foo"); #print nothing
        warnf("foo");

    Support levels are DEBUG,INFO,WARN,CRITICAL and NONE.
    If NONE is set, no output except croakf and croakff. Default log level is DEBUG.

- $Log::Minimal::AUTODUMP

    Serialize message with Data::Dumper.

        warnf("%s", {foo => 'bar'}); # HASH(0x100804ed0)

        local $Log::Minimal::AUTODUMP = 1;
        warnf("dump is %s", {foo=>'bar'}); #dump is {foo=>'bar'}

        my $uri = URI->new("http://search.cpan.org/");
        warnf("uri: '%s'", $uri); # uri: 'http://search.cpan.org/'

    If message is object and has overload methods like '""' or '0+', 
    Log::Minimal uses it instead of Data::Dumper.

- $Log::Minimal::TRACE\_LEVEL

    Like a $Carp::CarpLevel, this variable determines how many additional call frames are to be skipped.
    Defaults to 0.

- $Log::Minimal::ESCAPE\_WHITESPACE

    If this value is true, whitespace other than space will be represented as \[\\n\\t\\r\].
    Defaults to 0.

# AUTHOR

Masahiro Nagano <kazeburo {at} gmail.com>

# THANKS TO

Yuji Shimada (xaicron)

Yoshihiro Sugi (sugyan)

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
