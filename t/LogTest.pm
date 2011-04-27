package t::LogTest;

use strict;
use warnings;
use Log::Minimal;

sub logtest {
    warnf @_;
}

1;


