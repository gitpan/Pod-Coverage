use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $module = 'lib/Pod/Coverage.pm';
WriteMakefile(
              'NAME'         => 'Pod::Coverage',
              'VERSION_FROM' => $module, # finds $VERSION
              'dist'         => {
				 COMPRESS=>'gzip -9f',
				 SUFFIX=>'gz',
				 DIST_DEFAULT => 'tardist'
				},
	      PM             => {
				 'lib/Pod/Coverage.pm'            => '$(INST_LIBDIR)/Coverage.pm',
				 'lib/Pod/Coverage/ExportOnly.pm' => '$(INST_LIBDIR)/Coverage/ExportOnly.pm',
				 'lib/Pod/Coverage/Overloader.pm' => '$(INST_LIBDIR)/Coverage/Overloader.pm',
				},
              PREREQ_PM      => { 
				 'Test::More'     => 0.11,
				 'Devel::Symdump' => 2.01,
				 'Pod::Parser'    => 1.13,
				 'Pod::Find'      => 0.21,
				},
              $] >= 5.005 ? ('AUTHOR'   => 'Richard Clamp <richardc@unixbeard.net>, Michael Stevens <michael@etla.org.>',
                             'ABSTRACT' => 'Checks if the documentation of a module is comprehensive',

                            ) : ()

             );

use Config;
use File::Spec::Functions;
sub MY::postamble {
    my $perl     = $Config{perlpath};
    my $pod2text = catfile($Config{bin}, "pod2text");
    return <<EOF
README: $module
\t$perl $pod2text $module > README
EOF
}
