#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema::Result::Service;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("service");
__PACKAGE__->add_columns(qw/id service_name task_name task_description/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many("hardware_services", "Rex::IO::Server::Schema::Result::HardwareService", "service_id");

1;
