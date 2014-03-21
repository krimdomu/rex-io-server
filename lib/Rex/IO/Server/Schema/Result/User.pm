#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Schema::Result::User;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("users");
__PACKAGE__->add_columns(qw/id name password group_id/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to("group", "Rex::IO::Server::Schema::Result::Group", "group_id");

__PACKAGE__->has_many("assigned_incidents", "Rex::IO::Server::Schema::Result::Incident", "assignee");
__PACKAGE__->has_many("created_incidents", "Rex::IO::Server::Schema::Result::Incident", "creator");
__PACKAGE__->has_many("created_incident_messages", "Rex::IO::Server::Schema::Result::IncidentMessage", "creator");


sub to_hashRef {
  my ($self) = @_;
  return { $self->get_columns };
}

1;
