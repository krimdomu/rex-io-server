#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema::Result::Incident;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("incidents");
__PACKAGE__->add_columns(qw/id title status_id created creator assignee short content/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many("messages", "Rex::IO::Server::Schema::Result::IncidentMessage", "incident_id");
__PACKAGE__->belongs_to("status", "Rex::IO::Server::Schema::Result::IncidentStatus", "status_id");

__PACKAGE__->belongs_to("assignee", "Rex::IO::Server::Schema::Result::User", "assignee");
__PACKAGE__->belongs_to("creator", "Rex::IO::Server::Schema::Result::User", "creator");

1;
