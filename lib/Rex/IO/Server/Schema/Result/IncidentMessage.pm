#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema::Result::IncidentMessage;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("incident_message");
__PACKAGE__->add_columns(qw/id incident_id title creator created message/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to("incident", "Rex::IO::Server::Schema::Result::Incident", "incident_id");
__PACKAGE__->belongs_to("creator", "Rex::IO::Server::Schema::Result::User", "creator");

1;
