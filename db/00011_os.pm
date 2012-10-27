package os;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   create_table {
      my $t = shift;

      $t->name("os");

      $t->integer("id", null => FALSE, auto_increment => TRUE);
      $t->string("version", size => 20);
      $t->string("name", size => 50);

      $t->primary_key("id");
   };

   add_column "hardware", os_id => "Integer";

}

sub down {

   drop_column hardware => "os_id";
   drop_table "os";

}

1;
