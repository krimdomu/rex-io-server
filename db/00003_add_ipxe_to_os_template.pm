package add_ipxe_to_os_template;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   add_column "os_template", ipxe => "text";

}

sub down {

   drop_column "os_template", "ipxe";

}

1;
