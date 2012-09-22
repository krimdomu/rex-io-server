package init;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   create_table {
      my $t = shift;

      $t->name("hardware");

      $t->integer("id", null => FALSE, auto_increment => TRUE);
      $t->string("name", null => FALSE);
      $t->string("ip", size => 15);
      $t->string("mac", size => 17);
      $t->integer("state_id", size => 2, default => 1);

      $t->primary_key("id");
   };

   create_table {
      my $t = shift;

      $t->name("hardware_state");

      $t->integer("id", size => 2, null => FALSE, auto_increment => TRUE);
      $t->string("name", null => FALSE);

      $t->primary_key("id");
   };

   create_table {
      my $t = shift;

      $t->name("tree");

      $t->integer("id", null => FALSE, auto_increment => TRUE);
      $t->integer("parent", null => TRUE, default => 1);
      $t->string("name", null => FALSE, size => 50);

      $t->primary_key("id");
   };

   create_table {
      my $t = shift;

      $t->name("user");

      $t->integer("id", null => FALSE, auto_increment => TRUE);
      $t->string("name", null => FALSE, size => 50);
      $t->string("password", null => FALSE, size => 50);

      $t->primary_key("id");
   };

   create_table {
      my $t = shift;

      $t->name("group");

      $t->integer("id", null => FALSE, auto_increment => TRUE);
      $t->string("name", null => FALSE);

      $t->primary_key("id");
   };

   create_table {
      my $t = shift;

      $t->name("user_group");

      $t->integer("user_id", null => FALSE, auto_increment => TRUE);
      $t->integer("group_id", null => FALSE);

      $t->primary_key("user_id", "group_id");

   };

}

sub down {

   drop_table "user_group";
   drop_table "group";
   drop_table "user";
   drop_table "tree";
   drop_table "hardware_state";
   drop_table "hardware";

}

1;
