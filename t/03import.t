#!/usr/bin/perl -w
use strict;
use lib 't/lib';
use Test::More tests => 1;

BEGIN {
    BEGIN {
        open(FH, ">test.out") or die "Couldn't open test.out for writing: $!";
        open(OLDOUT, ">&STDOUT");
        select(select(OLDOUT));
        open(STDOUT, ">&FH");
    }
    use Pod::Coverage package => 'Simple2';
    close STDOUT;
    close FH;
    open(STDOUT, ">&OLDOUT");
    open(FH, "<test.out") or die "Couldn't open test.out for reading: $!";
    my $result;
    { local $/; $result = <FH>; }
    chomp $result;
    is($result, "Simple2 has a Pod::Coverage rating of 0.75\n'naked' is uncovered", "Simple2 works correctly in import form");
    unlink('test.out');
}
