package Rex::IO::Server::Schema::Result::Permission;

use strict;
use warnings;

use Data::Dumper;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("permission");
__PACKAGE__->add_columns(
  id => {
    data_type         => 'serial',
    is_auto_increment => 1,
    is_numeric        => 1,
  },
  permission_set_id => {
    data_type   => 'integer',
    is_nullable => 0,
  },
  perm_id => {
    data_type   => 'integer',
    is_nullable => 0,
  },
  group_id => {
    data_type   => 'integer',
    is_nullable => 1,
    default     => undef,
  },
  user_id => {
    data_type   => 'integer',
    is_nullable => 0,
    default     => undef,
  },
);

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
