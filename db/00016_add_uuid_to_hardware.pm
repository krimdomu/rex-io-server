package add_uuid_to_hardware;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   add_column "hardware", uuid => "String";

}

sub down {

   drop_column "hardware", "uuid";

}

1;

