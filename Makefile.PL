use ExtUtils::MakeMaker;

my %deps = (
                  'Mojolicious',
                  #'Mojolicious::Plugin::Authentication',
                  'Mojolicious::Plugin::HttpBasicAuth',
                  'Compress::Zlib' => 0,
                  'XML::Simple' => 0,
                  'DBIx::Class' => 0,
                  'DBD::mysql' => 0,
                  'Digest::Bcrypt' => 0,
                  'Mojo::Redis' => 0,
                  'DBIx::Class::Tree::NestedSet' => 0,
                  'Net::DNS' => 0,
                  'JSON::XS' => 0,
                  'Gearman::Client' => 0,
                  'DateTime' => 0,
                  'IO::All'  => 0,
);

WriteMakefile1(
   META_MERGE => {
      resources => {
         repository => 'https://github.com/krimdomu/rex-io-server',
      },
   },
   NAME => 'Rex::IO::Server',
   VERSION_FROM => 'lib/Rex/IO/Server.pm',
   PREREQ_PM => \%deps,
   EXE_FILES => ['bin/rex_ioserver', 'bin/rex_io_monitor_alert_scheduler', 'bin/rex_io_add_user', 'bin/rex_io_pxe_dhcpevent', 'bin/rex_io_register_service'],
   LICENSE => 'Apache License 2.0'
);


sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
   my %params=@_;
   my $eumm_version=$ExtUtils::MakeMaker::VERSION;
   $eumm_version=eval $eumm_version;
   die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
   die "License not specified" if not exists $params{LICENSE};
   if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
      #EUMM 6.5502 has problems with BUILD_REQUIRES
      $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
      delete $params{BUILD_REQUIRES};
   }
   delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
   delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
   delete $params{META_MERGE} if $eumm_version < 6.46;
   delete $params{META_ADD} if $eumm_version < 6.46;
   delete $params{LICENSE} if $eumm_version < 6.31;
   delete $params{AUTHOR} if $] < 5.005;
   delete $params{ABSTRACT_FROM} if $] < 5.005;
   delete $params{BINARY_LOCATION} if $] < 5.005;

   WriteMakefile(%params);
}
