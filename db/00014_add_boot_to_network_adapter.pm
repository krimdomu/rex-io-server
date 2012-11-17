package add_boot_to_network_adapter;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   add_column "network_adapter", boot => "integer", { size => 2 };

}

sub down {

   drop_column "network_adapter", "boot";

}

1;

