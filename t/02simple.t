#!/usr/bin/perl -w
use strict;
use Test::More tests => 7;
use lib 't/lib';
use Pod::Coverage ();

my $obj = new Pod::Coverage package => 'Simple1';

ok( $obj, 'it instantiated' );

is( $obj->coverage, 2/3, "Simple1 has 2/3rds coverage");

$obj = new Pod::Coverage package => 'Simple2';

is( $obj->coverage, 0.75, "Simple2 has 75% coverage");

ok( eq_array([ $obj->naked ], [ 'naked' ]), "naked isn't covered");

$obj = new Pod::Coverage package => 'Simple2', private => [ 'naked' ];

is ( $obj->coverage, 1, "nakedness is a private thing" );

$obj = new Pod::Coverage package => 'Simple1', also_private => [ 'bar' ];

is ( $obj->coverage, 1, "it's also a private bar" );

$obj = new Pod::Coverage package => 'Pod::Coverage';

is( $obj->coverage, 1, "Pod::Coverage is covered");
