#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Schema::Result::User;

use strict;
use warnings;
use Rex::IO::Server::Schema::Helper::has_perm;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("users");
__PACKAGE__->add_columns(
  id => {
    data_type         => 'serial',
    is_auto_increment => 1,
    is_numeric        => 1,
  },
  name => {
    data_type   => 'varchar',
    size        => 150,
    is_nullable => 0,
  },
  group_id => {
    data_type   => 'integer',
    is_nullable => 0,
  },
  permission_set_id => {
    data_type   => 'integer',
    is_nullable => 0,
  },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to( "group", "Rex::IO::Server::Schema::Result::Group",
  "group_id" );

__PACKAGE__->belongs_to( "permission_set",
  "Rex::IO::Server::Schema::Result::PermissionSet",
  "permission_set_id" );

sub to_hashRef {
  my ($self) = @_;
  return { $self->get_columns };
}

sub get_permissions {
  my ($self) = @_;

  my $set = $self->permission_set;

  my @perms;

  for my $perm ( $set->permissions ) {
    if ( $perm->user_id && $perm->user_id == $self->id ) {
      push @perms, $perm->permission_type->name;
    }

    if ( $perm->group_id && $perm->group_id == $self->group_id ) {
      push @perms, $perm->permission_type->name;
    }
  }

  return @perms;
}

1;
