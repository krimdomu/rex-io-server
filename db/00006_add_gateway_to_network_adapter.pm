package add_gateway_to_network_adapter;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   add_column "network_adapter", gateway => "Integer";

}

sub down {

   drop_column "network_adapter", "gateway";

}

1;
