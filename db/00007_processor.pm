package processor;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   create_table {
      my $t = shift;

      $t->name("processor");

      $t->integer("id", null => FALSE, auto_increment => TRUE);
      $t->integer("hardware_id");
      $t->string("modelname", size => 150);
      $t->string("vendor", size => 150);
      $t->string("flags", size => 150);
      $t->integer("mhz");
      $t->integer("cache");

      $t->primary_key("id");
   };


}

sub down {

   drop_table "processor";

}

1;
