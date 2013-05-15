#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema::Result::ServiceTask;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("service_task");
__PACKAGE__->add_columns(qw/id service_id task_name task_description/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to("service", "Rex::IO::Server::Schema::Result::Service", "service_id");
__PACKAGE__->has_many("hardware_tasks", "Rex::IO::Server::Schema::Result::HardwareTask", "hardware_id");
__PACKAGE__->has_many("queued_jobs", "Rex::IO::Server::Schema::Result::QueuedJob", "task_id");

sub to_hashRef {
   my ($self) = @_;
   my $data = { $self->get_columns };

   $data->{service} = { $self->service->get_columns };

   return $data;
}

1;
