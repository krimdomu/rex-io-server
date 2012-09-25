package os_template;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   create_table {
      my $t = shift;

      $t->name("os_template");

      $t->integer("id", null => FALSE, auto_increment => TRUE);
      $t->string("name", null => FALSE);
      $t->string("kernel", size => 255);
      $t->string("initrd", size => 255);
      $t->text("append");
      $t->text("template");

      $t->primary_key("id");
   };


}

sub down {

   drop_table "os_template";

}

1;
