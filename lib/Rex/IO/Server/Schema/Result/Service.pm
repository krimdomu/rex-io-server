#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
  
package Rex::IO::Server::Schema::Result::Service;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("service");
__PACKAGE__->add_columns(qw/id service_name/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many("tasks", "Rex::IO::Server::Schema::Result::ServiceTask", "service_id");

sub to_hashRef {
  my ($self) = @_;
  my $data = { $self->get_columns };

  $data->{tasks} = [ $self->get_tasks ];

  return $data;
}

sub get_tasks {
  my ($self) = @_;

  my @ret;

  for my $task ($self->tasks) {
    push(@ret, $task->to_hashRef);
  }

  return @ret;
}

1;
