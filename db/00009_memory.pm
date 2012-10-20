package memory;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   create_table {
      my $t = shift;

      $t->name("memory");

      $t->integer("id", null => FALSE, auto_increment => TRUE);
      $t->integer("hardware_id");
      $t->integer("size");
      $t->integer("bank");
      $t->string("serialnumber", size => 255);
      $t->string("speed", size => 50);
      $t->string("type", size => 150);

      $t->primary_key("id");
   };


}

sub down {

   drop_table "memory";

}

1;
