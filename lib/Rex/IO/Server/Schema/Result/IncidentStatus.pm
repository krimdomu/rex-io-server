#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema::Result::IncidentStatus;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("incident_status");
__PACKAGE__->add_columns(qw/id name/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many("incidents", "Rex::IO::Server::Schema::Result::Incident", "status_id");

1;
