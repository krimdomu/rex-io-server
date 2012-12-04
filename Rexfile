use strict;
use warnings;

use Rex::Bundle;

install_to 'vendor/perl';

task deps => sub {

   if(! is_dir("vendor/perl")) { mkdir "vendor/perl"; }
   
   mod "DBIx::ORMapper", url => "git://github.com/krimdomu/dbix-ormapper.git";
   mod "DBIx::ORMapper::Adapter::MySQL", url => "git://github.com/krimdomu/dbix-ormapper-adapter-mysql.git";
   mod "DBIx::ORMapper::Migration", url => "git://github.com/krimdomu/dbix-ormapper-migration.git";

   mod "Mojolicious";

   mod "Devel::StackTrace";
   mod "Exception::Class";

   mod "DBI";
   mod "DBD::mysql";
   mod "Net::DNS";

   mod "XML::Simple";
};

task s => sub {

   perl "bin/rex_ioserver daemon";

};

