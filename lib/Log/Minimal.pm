package Log::Minimal;

use strict;
use warnings;
use Term::ANSIColor qw//;

our $VERSION = '0.17';
our @EXPORT = map { ($_.'f', $_.'ff') } qw/crit warn info debug croak/;
push @EXPORT, 'ddf';

our $PRINT = sub {
    my ( $time, $type, $message, $trace, $raw_message) = @_;
    warn "$time [$type] $message at $trace\n";
};

our $DIE = sub {
    my ( $time, $type, $message, $trace, $raw_message) = @_;
    die "$time [$type] $message at $trace\n";
};

our $DEFAULT_COLOR = {
    info  => { text => 'green', },
    debug => {
        text       => 'red',
        background => 'white',
    },
    'warn' => {
        text       => 'black',
        background => 'yellow',
    },
    'critical' => {
        text       => 'black',
        background => 'red'
    },
    'error' => {
        text       => 'red',
        background => 'black'
    }
};

if ($ENV{LM_DEFAULT_COLOR}) {
    # LEVEL=FG;BG:LEVEL=FG;BG:...
    for my $level_color (split /:/, $ENV{LM_DEFAULT_COLOR}) {
        my($level, $color) = split /=/, $level_color, 2;
        my($fg, $bg)       = split /;/, $color, 2;
        $Log::Minimal::DEFAULT_COLOR->{$level} = {
            $fg ? (text       => $fg) : (),
            $bg ? (background => $bg) : (),
        };
    }
}

our $ENV_DEBUG = "LM_DEBUG";
our $AUTODUMP = 0;
our $LOG_LEVEL = 'DEBUG';
our $TRACE_LEVEL = 0;
our $COLOR = $ENV{LM_COLOR} || 0;
our $ESCAPE_WHITESPACE = 1;

my %log_level_map = (
    DEBUG    => 1,
    INFO     => 2,
    WARN     => 3,
    CRITICAL => 4,
    MUTE     => 0,
    ERROR    => 99,
);

sub import {
    my $class   = shift;
    my $package = caller(0);
    my @args = @_;

    my %want_export;
    my $env_debug;
    while ( my $arg = shift @args ) {
        if ( $arg eq 'env_debug' ) {
            $env_debug = shift @args;
        }
        else {
            $want_export{$arg} = 1;
        }
    }

    if ( ! keys %want_export ) {
        #all
        $want_export{$_} = 1 for @EXPORT;
    }

    no strict 'refs';
    for my $f (grep !/^debug/, @EXPORT) {
        if ( $want_export{$f} ) {
            *{"$package\::$f"} = \&$f;
        }
    }

    for my $f (map { ($_.'f', $_.'ff') } qw/debug/) {
        if ( $want_export{$f} ) {
            if ( $env_debug ) {
                *{"$package\::$f"} = sub {
                    local $TRACE_LEVEL = $TRACE_LEVEL + 1;
                    local $ENV_DEBUG   = $env_debug;
                    $f->(@_);
                };
            }
            else {
                *{"$package\::$f"} = \&$f;
            }
        }
    }

}

sub critf {
    _log( "CRITICAL", 0, @_ );
}

sub warnf {
    _log( "WARN", 0, @_ );
}

sub infof {
    _log( "INFO", 0, @_ );
}

sub debugf {
    return if !$ENV{$ENV_DEBUG} || $log_level_map{DEBUG} < $log_level_map{uc $LOG_LEVEL};
    _log( "DEBUG", 0, @_ );
}

sub critff {
    _log( "CRITICAL", 1, @_ );
}

sub warnff {
    _log( "WARN", 1, @_ );
}

sub infoff {
    _log( "INFO", 1, @_ );
}

sub debugff {
    return if !$ENV{$ENV_DEBUG} || $log_level_map{DEBUG} < $log_level_map{uc $LOG_LEVEL};
    _log( "DEBUG", 1, @_ );
}

sub croakf {
    local $PRINT = $DIE;
    _log( "ERROR", 0, @_ );
}

sub croakff {
    local $PRINT = $DIE;
    _log( "ERROR", 1, @_ );
}

sub _log {
    my $tag = shift;
    my $full = shift;

    my $_log_level = $log_level_map{uc $LOG_LEVEL} || return;
    return unless $log_level_map{$tag} >= $_log_level;

    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(time);
    my $time    = sprintf(
        "%04d-%02d-%02dT%02d:%02d:%02d",
        $year + 1900,
        $mon + 1, $mday, $hour, $min, $sec
    );

    my $trace;
    if ( $full ) {
        my $i=$TRACE_LEVEL+1;
        my @stack;
        while ( my @caller = caller($i) ) {
            push @stack, "$caller[1] line $caller[2]";
            $i++;
        }
        $trace = join " ,", @stack
    }
    else {
        my @caller = caller($TRACE_LEVEL+1);
        $trace = "$caller[1] line $caller[2]";
    }

    my $messages = '';
    if ( @_ == 1 && defined $_[0]) {
        $messages = $AUTODUMP ? ''.Log::Minimal::Dumper->new($_[0]) : $_[0];
    }
    elsif ( @_ >= 2 )  {
        $messages = sprintf(shift, map { $AUTODUMP ? Log::Minimal::Dumper->new($_) : $_ } @_);
    }

    if ($ESCAPE_WHITESPACE) {
        $messages =~ s/\x0d/\\r/g;
        $messages =~ s/\x0a/\\n/g;
        $messages =~ s/\x09/\\t/g;
    }

    my $raw_message = $messages;
    if ( $COLOR ) {
        $messages = Term::ANSIColor::color($DEFAULT_COLOR->{lc($tag)}->{text}) 
            . $messages . Term::ANSIColor::color("reset")
                if $DEFAULT_COLOR->{lc($tag)}->{text};
        $messages = Term::ANSIColor::color("on_".$DEFAULT_COLOR->{lc($tag)}->{background}) 
            . $messages . Term::ANSIColor::color("reset")
                if $DEFAULT_COLOR->{lc($tag)}->{background};
    }

    $PRINT->(
        $time,
        $tag,
        $messages,
        $trace,
        $raw_message
    );
}

sub ddf {
    my $value = shift;
    Log::Minimal::Dumper::dumper($value);
}

1;

package
    Log::Minimal::Dumper;

use strict;
use warnings;
use base qw/Exporter/;
use Data::Dumper;
use Scalar::Util qw/blessed/;

use overload
    '""' => \&stringfy,
    '0+' => \&numeric,
    fallback => 1;

sub new {
    my ($class, $value) = @_;
    bless \$value, $class;
}

sub stringfy {
    my $self = shift;
    my $value = $$self;
    if ( blessed($value) && (my $stringify = overload::Method( $value, '""' ) || overload::Method( $value, '0+' )) ) {
        $value = $stringify->($value);
    }
    dumper($value);
}

sub numeric {
    my $self = shift;
    my $value = $$self;
    if ( blessed($value) && (my $numeric = overload::Method( $value, '0+' ) || overload::Method( $value, '""' )) ) {
        $value = $numeric->($value);
    }
    $value;
}

sub dumper {
    my $value = shift;
    if ( defined $value && ref($value) ) {
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 0; 
        local $Data::Dumper::Sortkeys = 1;
        $value = Data::Dumper::Dumper($value);
    }
    $value;
}


1;
__END__

=head1 NAME

Log::Minimal - Minimal but customizable logger.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Log::Minimal is Minimal but customizable log module.

=head1 EXPORT FUNCTIONS

=over 4

=item critf(($message:Str|$format:Str,@list:Array));

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

=item warnf(($message:Str|$format:Str,@list:Array));

Display WARN messages.

=item infof(($message:Str|$format:Str,@list:Array));

Display INFO messages.

=item debugf(($message:Str|$format:Str,@list:Array));

Display DEBUG messages, if $ENV{LM_DEBUG} is true.

=item critff(($message:Str|$format:Str,@list:Array));

  critff("could't connect to example.com");
  critff("Connection timeout timeout:%d, host:%s", 2, "example.com");

Display CRITICAL messages with stack trace.

=item warnff(($message:Str|$format:Str,@list:Array));

Display WARN messages with stack trace.

=item infoff(($message:Str|$format:Str,@list:Array));

Display INFO messages with stack trace.

=item debugff(($message:Str|$format:Str,@list:Array));

Display DEBUG messages with stack trace, if $ENV{LM_DEBUG} is true.

=item croakf(($message:Str|$format:Str,@list:Array));

die with formatted $message

  croakf("critical error");
  # 2011-06-10T16:27:26 [ERROR] critical error at sample.pl line 23

=item croakff(($message:Str|$format:Str,@list:Array));

die with formatted $message with stack trace

=item ddf($value:Any)

Utility method that serializes given value with Data::Dumper;

 my $serialize = ddf($hashref);


=back

=head1 ENVIRONMENT VALUE

=over 4

=item $ENV{LM_DEBUG}

To print debugf and debugff messages, $ENV{LM_DEBUG} must be true.

You can change variable name from LM_DEBUG to arbitrary string which is specified by "env_debug" in use line. Changed variable name affects only in package locally.

  use Log::Minimal env_debug => 'FOO_DEBUG';
  
  $ENV{LM_DEBUG}  = 1;
  $ENV{FOO_DEBUG} = 0;
  debugf("hello"); # no output
  
  $ENV{FOO_DEBUG} = 1;
  debugf("world"); # print message

=item $ENV{LM_COLOR}

$ENV{LM_COLOR} is used as default value of $Log::Minimal::COLOR

=item $ENV{LM_DEFAULT_COLOR}

$ENV{LM_DEFAULT_COLOR} is used as default value of $Log::Minimal::DEFAULT_COLOR

Format of value is "LEVEL=FG;BG:LEVEL=FG;BG:...". "FG" and "BG" are optional.

For example:

  export LM_DEFAULT_COLOR='debug=red:info=;cyan:critical=yellow;red'

=back

=head1 CUSTOMIZE

=over 4

=item $Log::Minimal::COLOR

Coloring log messages. Disabled by default.

=item $Log::Minimal::PRINT

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

$message includes color sequences, If you want raw message text, use $raw_message.
default is

  sub {
    my ( $time, $type, $message, $trace,$raw_message) = @_;
    warn "$time [$type] $message at $trace\n";
  }

=item $Log::Minimal::DIE

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

=item $Log::Minimal::LOG_LEVEL

Set level to output log.

  local $Log::Minimal::LOG_LEVEL = "WARN";
  infof("foo"); #print nothing
  warnf("foo");

Support levels are DEBUG,INFO,WARN,CRITICAL and NONE.
If NONE is set, no output. Default log level is DEBUG.

=item $Log::Minimal::AUTODUMP

Serialize message with Data::Dumper.

  warnf("%s",{ foo => bar}); # HASH(0x100804ed0)

  local $Log::Minimal::AUTODUMP = 1;
  warnf("dump is %s", {foo=>'bar'}); #dump is {foo=>'bar'}

  my $uri = URI->new("http://search.cpan.org/");
  warnf("uri: '%s'", $uri); # uri: 'http://search.cpan.org/'

If message is object and has overload methods like '""' or '0+', 
Log::Minimal uses it instead of Data::Dumper.

=item $Log::Minimal::TRACE_LEVEL

Like a $Carp::CarpLevel, this variable determines how many additional call frames are to be skipped.
Defaults to 0.

=item $Log::Minimal::ESCAPE_WHITESPACE

If this value is true, whitespace other than space will be represented as [\n\t\r].
Defaults to 0.

=back

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 THANKS TO

Yuji Shimada (xaicron)

Yoshihiro Sugi (sugyan)

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
