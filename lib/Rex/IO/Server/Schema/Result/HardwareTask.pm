#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema::Result::HardwareTask;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("hardware_task");
__PACKAGE__->add_columns(qw/id hardware_id task_id task_order/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to("task", "Rex::IO::Server::Schema::Result::ServiceTask", "task_id");
__PACKAGE__->belongs_to("hardware", "Rex::IO::Server::Schema::Result::Hardware", "hardware_id");

1;
