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

__PACKAGE__->has_many( "server_group_trees",
  "Rex::IO::Server::Schema::Result::ServerGroupTree",
  "permission_set_id" );

__PACKAGE__->has_many( "users", "Rex::IO::Server::Schema::Result::User",
  "permission_set_id" );

__PACKAGE__->has_many( "permissions",
  "Rex::IO::Server::Schema::Result::Permission",
  "permission_set_id" );

sub to_hashRef {
  my ($self) = @_;

  my $data = { $self->get_columns };
  my $perms = { user => {}, group => {} };

  for my $perm ( $self->permissions ) {
    if ( $perm->user_id ) {
      push @{ $perms->{user}->{ $perm->user_id } }, $perm->perm_id;
    }
    elsif ( $perm->group_id ) {
      push @{ $perms->{group}->{ $perm->group_id } }, $perm->perm_id;
    }
  }

  $data->{permissions} = $perms;

  return $data;
}

1;
