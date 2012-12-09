package add_serial_to_harddrive;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   add_column "harddrive", serial => "String";

}

sub down {

   drop_column "harddrive", "serial";

}

1;

