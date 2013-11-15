#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Schema::Result::QueuedJob;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("queued_jobs");
__PACKAGE__->add_columns(qw/id hardware_id task_id task_order/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to("task", "Rex::IO::Server::Schema::Result::ServiceTask", "task_id");

1;
