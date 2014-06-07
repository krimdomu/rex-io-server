package Rex::IO::Server::Schema::Result::PermissionSet;

use strict;
use warnings;

use Data::Dumper;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("permission_set");
__PACKAGE__->add_columns(qw/id name description/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many( "hardwares", "Rex::IO::Server::Schema::Result::Hardware",
  "permission_set_id" );

__PACKAGE__->has_many( "users", "Rex::IO::Server::Schema::Result::User",
  "permission_set_id" );

__PACKAGE__->has_many( "permissions",
  "Rex::IO::Server::Schema::Result::Permission",
  "permission_set_id" );

1;
