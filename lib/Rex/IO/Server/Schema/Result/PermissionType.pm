package Rex::IO::Server::Schema::Result::PermissionType;

use strict;
use warnings;

use Data::Dumper;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("permission_type");
__PACKAGE__->add_columns(qw/id name/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many( "permissions",
  "Rex::IO::Server::Schema::Result::Permission", "perm_id" );

1;