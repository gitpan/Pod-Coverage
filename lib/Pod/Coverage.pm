package Pod::Coverage;
use strict;
use Devel::Symdump;
use Devel::Peek qw(CvGV);

use vars qw/ $VERSION /;
$VERSION = '0.04';

=head1 NAME

Pod::Coverage - Checks if the documentation of a module is comprehensive

=head1 SYNOPSIS

  # all in one invocation
  use Pod::Coverage package => 'Fishy';

  # straight OO
  use Pod::Coverage;
  my $pc = new Pod::Coverage package => 'Pod::Coverage';
  print "We rock!" if $pc->coverage == 1;


=head1 DESCRIPTION

Developers hate writing documentation.  They'd hate it even more if
their computer tattled on them, but maybe they'll be even more
thankful in the long run.  Even if not, perlmodstyle tells you to, so
you must obey.

This module provides a mechanism for determining if the pod for a
given module is comprehensive.

It expects to find either a =head2 or an =item block documenting a
subroutine.

Consider:
 # an imaginary Foo.pm
 package Foo;

 =item foo

 The foo sub

 = cut

 sub foo {}
 sub bar {}

 1;
 __END__

In this example Foo::foo is covered, but Foo::bar is not, so the Foo
package is only 50% (0.5) covered

=head2 Methods

=over

=item Pod::Coverage->new(package => $package)

Creates a new Pod::Coverage object.

C<package> the name of the package to analyse

C<private> an array of regexen which define what symbols are regarded
as private (and so need not be documented) defaults to /^_/,
/^import$/, /^DESTROY/, and /^AUTOLOAD/.

C<also_private> is similar to C<private> but these are appended to the
default set

=cut

sub new {
    my $referent = shift;
    my %args = @_;
    my $class = ref $referent || $referent;

    my $private = $args{private} || [ qr/^_/, qr/^import$/, qr/^DESTROY/, qr/^AUTOLOAD/, @{ $args{also_private} || [] } ];
    my $self = bless { @_, private => $private }, $class;
}

=item $object->coverage

Gives the coverage as a value in the range 0 to 1

=cut


sub coverage {
    my $self = shift;

    my $package = $self->{package};
    eval qq{ require $package; };
    return if $@;

    my $syms = new Devel::Symdump $package;
    my $file = $package;
    $file =~ s!::!/!g;
    if ($INC{"$file.pm"}) {
        $file = $INC{"$file.pm"};
    }
    return unless $file;

    my $pod = new Pod::Coverage::Extractor::;
    $pod->parse_from_file($file, '/dev/null');

    my %symbols;
    for my $sym ($syms->functions) {
        # see if said method wasn't just imported from elsewhere
        my $owner = CvGV(\&{ $sym });
        $owner =~ s/^\*(.*)::.*?$/$1/;
        next if $owner ne $self->{package};

        # check if it's on the whitelist
        $sym =~ s/$self->{package}:://;
        next if grep { $sym =~ /$_/ } @{ $self->{private} };

        $symbols{$sym} = 0;
    }

    for my $pod (@{ $pod->{identifiers} }) {
        # it's dressed up like a method call
        $pod =~ /->(.*)/   and $pod = $1;
        # it's wrapped in a pod style B<>
        $pod =~ /<(.*)>/   and $pod = $1;
        # it's got example arguments
        $pod =~ /(\S+)\s*\(/   and $pod = $1;

        $symbols{$pod} = 1 if exists $symbols{$pod};
    }

    # stash the results for later
    $self->{symbols} = \%symbols;

    my $symbols    = scalar keys %symbols;
    my $documented = scalar grep { $_ } values %symbols;
    return unless $symbols;
    return $documented / $symbols;
}

=item $object->naked

Returns a list of uncovered routines, will implicitly call coverage if
it's not already been called.

=cut

sub naked {
    my $self = shift;
    $self->{symbols} or $self->coverage;
    return unless $self->{symbols};
    return grep { !$self->{symbols}{$_} } keys %{ $self->{symbols} };
}

sub import {
    my $self = shift;
    return unless @_;
    # we were called with arguments
    my $pc = new Pod::Coverage @_;
    print $pc->{package}, " has a Pod::Coverage rating of ", $pc->coverage,"\n";
    my @looky_here = $pc->naked;
    if (@looky_here > 1) {
        print "The following are uncovered: ", join(", ", @looky_here), "\n";
    }
    elsif (@looky_here) {
        print "'$looky_here[0]' is uncovered\n";
    }

}

package Pod::Coverage::Extractor;
use Pod::Parser;
use vars qw/ @ISA /;
@ISA = 'Pod::Parser';

# extract subnames from a pod stream
sub command {
    my $self = shift;
    my ($command, $text, $line_num) = @_;
    if ($command eq 'item' || $command =~ /^head(?:2|3|4)/) {
        # lose trailing newlines, and take note
        return unless $text =~ /(.*)/;
        push @{$self->{identifiers}}, $1;
    }
}

1;

__END__

=back

=head1 BUGS

Due to the method used to identify documented subroutines
C<Pod::Coverage> may completely miss your house style and declare your
code undocumented.  Patches and/or failing tests welcome.

Also the code currently only deals with packages in their own .pm
files, this will be adressed with the next release.

=head1 TODO

=over

=item Examine globals and explicitly exported symbols

=item Determine if ancestor packages declare things left undocumented

=item Widen the rules for identifying documentation

=item Look for a correponding .pod file to go with your .pm file

This is typical of code like Data::Dumper and Quantum::Superpositions,
which have extensive documentation, but Pod::Coverage declares them to
have none.

=back

=head1 HISTORY

=over

=item Version 0.04

Just 0.03 with a correctly generated README file

=item Version 0.03

Applied a patch from Dave Rolsky (barely 6 hours after release of
0.02) to improve scanning of pod markers.

=item Version 0.02

Fixed up the import form.  Removed dependency on List::Util.  Added
naked method.  Exposed private configuration.

=item Version 0.01

As #london.pm invaded Brighton, people taked about documentation
standards.  mstevens scribbled something down, richardc coded it, the
rest is ponies.

=back

=head1 AUTHORS

Richard Clamp <richardc@unixbeard.net>

Michael Stevens <mstevens@etla.org>

Copyright (c) 2001 Richard Clamp, Micheal Stevens. All rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
