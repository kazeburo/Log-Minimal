package Log::Minimal;

use strict;
use warnings;
use base qw/Exporter/;

our $VERSION = '0.01';
our @EXPORT = map { ($_.'f', $_.'ff') } qw/crit warn info debug/;

our $PRINT = sub { warn join(" ",@_) . "\n" };

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
    return unless $ENV{LM_DEBUG};
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
    return unless $ENV{LM_DEBUG};
    _log( "DEBUG", 1, @_ );
}

sub _log {
    my $tag = shift;
    my $full = shift;

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
        $messages = sprintf shift, @_;
    }

    $messages =~ s![\n\r]!!g;

    $PRINT->(
        $time,
        "[$tag]",
        $messages,
        "at $trace"
    );
}


1;
__END__

=head1 NAME

Log::Minimal - Minimal Logger

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

Log::Minimal is Minimal Log module.

=head1 CUSTOMIZE

To change output log method, define $Log::Minimal::PRINT.

  local $Log::Minimal::PRINT = sub {
      my ( $time, $type, $message, $trace) = @_;
      print STDERR "$time [$ENV{SCRIPT_NAME}] $type $message $trace\n";
  };

default

  sub { warn join(" ", @_) . "\n" }

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
