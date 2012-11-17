package add_mac_to_network_adapter;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   add_column "network_adapter", mac => "String";

}

sub down {

   drop_column "network_adapter", "mac";

}

1;

