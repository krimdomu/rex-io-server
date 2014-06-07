package Rex::IO::Server::Schema::Result::Permission;

use strict;
use warnings;

use Data::Dumper;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("permission");
__PACKAGE__->add_columns(qw/id permission_set_id perm_id group_id user_id/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to(
  "permission_set" => "Rex::IO::Server::Schema::Result::PermissionSet",
  "permission_set_id"
);

__PACKAGE__->belongs_to(
  "permission_type" => "Rex::IO::Server::Schema::Result::PermissionType",
  "perm_id"
);

1;
