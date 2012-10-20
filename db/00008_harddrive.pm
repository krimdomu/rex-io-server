package harddrive;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   create_table {
      my $t = shift;

      $t->name("harddrive");

      $t->integer("id", null => FALSE, auto_increment => TRUE);
      $t->integer("hardware_id");
      $t->string("devname", size => 50);
      $t->integer("size");
      $t->string("vendor", size => 150);

      $t->primary_key("id");
   };


}

sub down {

   drop_table "harddrive";

}

1;
