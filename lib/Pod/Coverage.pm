package Pod::Coverage;
use strict;
use Devel::Symdump;
use Devel::Peek qw(CvGV);
use Pod::Find qw(pod_where);

use vars qw/ $VERSION /;
$VERSION = '0.06';

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

If C<pod_from> is supplied, that file is parsed for the documentation,
rather than using Pod::Find

=cut

sub new {
    my $referent = shift;
    my %args = @_;
    my $class = ref $referent || $referent;

    my $private = $args{private} || [ qr/^_/, 
				      qr/^import$/, 
				      qr/^DESTROY$/, 
				      qr/^AUTOLOAD$/, 
				      qr/^bootstrap$/, 
				      @{ $args{also_private} || [] } ];
    my $self = bless { @_, private => $private }, $class;
}

=item $object->coverage

Gives the coverage as a value in the range 0 to 1

=cut


sub coverage {
    my $self = shift;

    my $debug = $self->{debug};
    my $package = $self->{package}; 

    print "getting pod location for '$package'\n" if $debug;
    $self->{pod_from} ||= pod_where({ -inc => 1 }, $package);
    my $pod_from = $self->{pod_from};
    return unless $pod_from;

    print "parsing '$pod_from'\n" if $debug;
    my $pod = new Pod::Coverage::Extractor::;
    $pod->parse_from_file($pod_from, '/dev/null');

    my %symbols = map { $_ => 0 } $self->_get_syms($package);

    print "tying shoelaces\n" if $debug;
    for my $pod (@{ $pod->{identifiers} }) {
        $symbols{$pod} = 1 if exists $symbols{$pod};
    }

    # stash the results for later
    $self->{symbols} = \%symbols;

    my $symbols    = scalar keys %symbols;
    my $documented = scalar grep { $_ } values %symbols;
    return unless $symbols;
    return $documented / $symbols;
}

=item $object->naked/$object->uncovered

Returns a list of uncovered routines, will implicitly call coverage if
it's not already been called.

Note, private identifiers will be skipped.

=cut

sub naked {
    my $self = shift;
    $self->{symbols} or $self->coverage;
    return unless $self->{symbols};
    return grep { !$self->{symbols}{$_} } keys %{ $self->{symbols} };
}

*uncovered = \&naked;

=item $object->covered

Returns a list of covered routines, will implicitly call coverage if
it's not previously been called.

As with C<naked> private identifiers will be skipped.

=cut

sub covered {
    my $self = shift;
    $self->{symbols} or $self->coverage;
    return unless $self->{symbols};
    return grep { $self->{symbols}{$_} } keys %{ $self->{symbols} };
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

=back

=head2 Inheritance interface

These abstract methods while functional in C<Pod::Coverage> may make
your life easier if you want to extend C<Pod::Coverage> to fit your
house style more closely.

B<NOTE> Please consider this interface as in a state of flux until
this comment goes away.

=over

=item _get_syms($package)

return a list of symbols to check for from the specified packahe

=cut

# this one walks the symbol tree
sub _get_syms {
    my $self = shift;
    my $package = shift;

    my $debug = $self->{debug};

    print "requiring '$package'\n" if $debug;
    eval qq{ require $package }; 
    return if $@;

    print "walking symbols\n" if $debug;
    my $syms = new Devel::Symdump $package;

    my @symbols;
    for my $sym ($syms->functions) {
        # see if said method wasn't just imported from elsewhere
        my $owner = CvGV(\&{ $sym });
        $owner =~ s/^\*(.*)::.*?$/$1/;
        next if $owner ne $self->{package};

        # check if it's on the whitelist
        $sym =~ s/$self->{package}:://;
        next if $self->_private_check($sym);

        push @symbols, $sym;
    }
    return @symbols;
}

=item _private_check($symbol)

return true if the symbol should be considered private

=cut

sub _private_check {
    my $self = shift;
    my $sym = shift;
    return grep { $sym =~ /$_/ } @{ $self->{private} };
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
        # take a closer look
	my @pods = ($text =~ /\s*([^\s\|,\/]+)/g);

	foreach my $pod (@pods) {
	    # it's dressed up like a method call
	    $pod =~ /->(.*)/   and $pod = $1;
	    # it's wrapped in a pod style B<>
	    $pod =~ /<(.*)>/   and $pod = $1;
	    # it's got example arguments
	    $pod =~ /(\S+)\s*\(/   and $pod = $1;

	    push @{$self->{identifiers}}, $pod;
	}
    }
}


1;

__END__

=back

=head1 BUGS

Due to the method used to identify documented subroutines
C<Pod::Coverage> may completely miss your house style and declare your
code undocumented.  Patches and/or failing tests welcome.

=head1 TODO

=over

=item Determine if ancestor packages declare things left undocumented

=item Widen the rules for identifying documentation

=item Improve the code coverage of the test suite.  C<Devel::Cover> rocks so hard.

=item Investigate making Pod::Coverage produce suitable data for use by Devel::Cover

=back

=head1 HISTORY

=over

=item Version 0.06

First cut at making inheritance easy.  Pod::Checker::ExportOnly isa
Pod::Checker which only checks what Exporter is allowed to hand out.

Fixed up bad docs from the 0.05 release.

=item Version 0.05

Used Pod::Find to deal with alternative locations for pod files.
Introduced pod_from.  Merged some patches from Schwern.  Added in
covered.  Assimilated C<examples/check_installed> as contributed by
Kirrily "Skud" Robert <skud@cpan.org>.  Copes with multple functions
documented by one section.  Added uncovered as a synonym for naked.

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

=head1 SEE ALSO

L<Test::More>, L<Devel::Cover>

=head1 AUTHORS

Richard Clamp <richardc@unixbeard.net>

Michael Stevens <mstevens@etla.org>

Copyright (c) 2001 Richard Clamp, Micheal Stevens. All rights
reserved.  This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
