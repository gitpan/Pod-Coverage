#!/usr/bin/perl -w
use Test::More tests => 2;

BEGIN {
    use_ok('Pod::Coverage');
    use_ok('Pod::Coverage::ExportOnly');
}
