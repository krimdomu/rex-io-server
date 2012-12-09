package add_virtual_to_network_adapter;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   add_column "network_adapter", virtual => "Integer";

}

sub down {

   drop_column "network_adapter", "virtual";

}

1;

