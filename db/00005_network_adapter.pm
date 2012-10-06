package network_adapter;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   create_table {
      my $t = shift;

      $t->name("network_adapter");

      $t->integer("id", null => FALSE, auto_increment => TRUE);
      $t->integer("hardware_id", null => FALSE);
      $t->string("dev", null => FALSE, default => "eth0");
      $t->string("proto", null => FALSE, default => "dhcp");
      $t->integer("ip");
      $t->integer("netmask");
      $t->integer("broadcast");
      $t->integer("network");

      $t->primary_key("id");
   };

   drop_column hardware => "ip";
   
}

sub down {

   drop_table "network_adapter";
   add_column "hardware", ip => "string";

}

1;
