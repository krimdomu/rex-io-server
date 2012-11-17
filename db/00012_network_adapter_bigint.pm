package network_adapter_bigint;

use DBIx::ORMapper::Migration;
use base qw(DBIx::ORMapper::Migration);

sub up {

   change_column "network_adapter", ip        => "BigInteger";
   change_column "network_adapter", netmask   => "BigInteger";
   change_column "network_adapter", broadcast => "BigInteger";
   change_column "network_adapter", network   => "BigInteger";
   change_column "network_adapter", gateway   => "BigInteger";

}

sub down {

   change_column "network_adapter", ip        => "Integer";
   change_column "network_adapter", netmask   => "Integer";
   change_column "network_adapter", broadcast => "Integer";
   change_column "network_adapter", network   => "Integer";
   change_column "network_adapter", gateway   => "Integer";


}

1;
