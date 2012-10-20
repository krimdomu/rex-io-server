package bios;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   create_table {
      my $t = shift;

      $t->name("bios");

      $t->integer("id", null => FALSE, auto_increment => TRUE);
      $t->integer("hardware_id");
      $t->DateTime("biosdate");
      $t->string("version", size => 50);
      $t->string("ssn", size => 150);
      $t->string("manufacturer", size => 150);
      $t->string("model", size => 150);

      $t->primary_key("id");
   };


}

sub down {

   drop_table "os_template";

}

1;
