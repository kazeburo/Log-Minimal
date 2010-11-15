package Log::Minimal;

use strict;
use warnings;
use base qw/Exporter/;
use Data::Dumper;

our $VERSION = '0.03';
our @EXPORT = map { ($_.'f', $_.'ff') } qw/crit warn info debug/;
push @EXPORT, 'ddd';

our $PRINT = sub {
    my ( $time, $type, $message, $trace) = @_;
    warn "$time [$type] $message at $trace\n";
};

our $ENV_DEBUG = "LM_DEBUG";

our $LOG_LEVEL = 'DEBUG';
my %log_level_map = (
    DEBUG    => 1,
    INFO     => 2,
    WARN     => 3,
    CRITICAL => 4,
    MUTE     => 0,
);

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
        my $i=1;
        my @stack;
        while ( my @caller = caller($i) ) {
            push @stack, "$caller[1] line $caller[2]";
            $i++;
        }
        $trace = join " ,", @stack
    }
    else {
        my @caller = caller(1);
        $trace = "$caller[1] line $caller[2]";
    }

    my $messages = '';
    if ( @_ == 1 && defined $_[0]) {
        $messages = $_[0];
    }
    elsif ( @_ >= 2 )  {
        $messages = sprintf(shift, @_);
    }

    $messages =~ s/\x0d/\\r/g;
    $messages =~ s/\x0a/\\n/g;
    $messages =~ s/\x09/\\t/g;

    $PRINT->(
        $time,
        $tag,
        $messages,
        $trace
    );
}

sub ddd {
    my $value = shift;
    if ( defined $value && ref($value) ) {
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 0;
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
  warnf("%d %s", 1, "foo");
  infof("foo");
  debugf("foo"); print if $ENV{LM_DEBUG} is true

  # with full stack trace
  critff("%s","foo");
  # 2010-10-20T00:25:17 [CRITICAL] foo at lib/Example.pm line 10, example.pl line 12
  warnff("%d %s", 1, "foo");
  infoff("foo");
  debugff("foo"); print if $ENV{LM_DEBUG} is true

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

=item ddd($value:Any)

Utility method that serializes given value with Data::Dumper;

  warnf( "dump is %s, another dump is %s", ddd($hashref), ddd($arrayref) );


=back

=head1 ENVIRONMENT

To print debugf and debugff messages, $ENV{LM_DEBUG} must be true.


=head1 CUSTOMIZE

=over 4

=item $Log::Minimal::PRINT

To change the method of outputting the log, set $Log::Minimal::PRINT.

  # with PSGI Application. output log with request uri.
  my $app = sub {
      my $env = shift;
      local $Log::Minimal::PRINT = sub {
          my ( $time, $type, $message, $trace) = @_;
          $env->{psgi.errors}->print(
              "$time [$env->{SCRIPT_NAME}] [$type] $message at $trace\n");
      };
      run_app(...);
  }

default is

  sub {
    my ( $time, $type, $message, $trace) = @_;
    warn "$time [$type] $message at $trace\n";
  }

=item $Log::Minimal::LOG_LEVEL

Set level to output log.

  local $Log::Minimal::LOG_LEVEL = "WARN";
  infof("foo"); #print nothing
  warnf("foo");

Support levels are DEBUG,INFO,WARN,CRITICAL and NONE.
If NONE is set, no output. Default log level is DEBUG.

=back

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 THANKS TO

Yuji Shimada (xaicron)

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
