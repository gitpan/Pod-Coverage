#!/usr/bin/perl -w
use strict;
use Test::More tests => 12;
use lib 't/lib';
use Pod::Coverage ();

my $obj = new Pod::Coverage package => 'Simple1';

ok( $obj, 'it instantiated' );

is( $obj->coverage, 2/3, "Simple1 has 2/3rds coverage");

$obj = new Pod::Coverage package => 'Simple2';

is( $obj->coverage, 0.75, "Simple2 has 75% coverage");

ok( eq_array([ $obj->naked ], [ 'naked' ]), "naked isn't covered");

ok( eq_array([ $obj->naked ], [ $obj->uncovered ]), "naked is uncovered");

$obj = new Pod::Coverage package => 'Simple2', private => [ 'naked' ];

is ( $obj->coverage, 1, "nakedness is a private thing" );

$obj = new Pod::Coverage package => 'Simple1', also_private => [ 'bar' ];

is ( $obj->coverage, 1, "it's also a private bar" );

ok( eq_array([ sort $obj->covered ], [ 'baz', 'foo' ]), "those guys are covered" );

$obj = new Pod::Coverage package => 'Pod::Coverage';

is( $obj->coverage, 1, "Pod::Coverage is covered" );

$obj = new Pod::Coverage package => 'Simple3';

is( $obj->coverage, 1, 'Simple3 is covered' );

$obj = new Pod::Coverage package => 'Simple4';

is( $obj->coverage, 1, "External .pod grokked" );

$obj = new Pod::Coverage package => 'Simple5';

is( $obj->coverage, 1, "Multiple docs per item works" );
