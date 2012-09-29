package add_os_template_id_to_hardware;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   add_column "hardware", os_template_id => "Integer";

}

sub down {

   drop_column "hardware", "os_template_id";

}

1;
