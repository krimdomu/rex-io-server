package drop_mac_from_hardware;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   drop_column "hardware", "mac";

}

sub down {

   add_column "hardware", mac => "string", { size => 17 };

}

1;

