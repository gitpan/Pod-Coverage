use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              'NAME'         => 'Pod::Coverage',
              'VERSION_FROM' => 'lib/Pod/Coverage.pm', # finds $VERSION
              'dist' => {
                         COMPRESS=>'gzip -9f',
                         SUFFIX=>'gz',
                         DIST_DEFAULT => 'tardist'
                        },
              'PM' => {
                       'lib/Pod/Coverage.pm'        => '$(INST_LIBDIR)/Coverage.pm',
                      },
              PREREQ_PM => { 'Test::More'     => 0.11,
                             'Devel::Symdump' => 2.01,
                             'Devel::Peek'    => 0,
                             'Pod::Parser'    => 1.13,
                           },
              $] >= 5.005 ? ('AUTHOR'   => 'Richard Clamp <richardc@unixbeard.net>, Michael Stevens <michael@etla.org.>',
                             'ABSTRACT' => 'Checks if the documentation of a module is comprehensive',

                            ) : ()

             );
