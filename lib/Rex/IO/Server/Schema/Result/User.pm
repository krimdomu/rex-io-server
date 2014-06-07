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
__PACKAGE__->add_columns(qw/id name password group_id permission_set_id/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to( "group", "Rex::IO::Server::Schema::Result::Group",
  "group_id" );

__PACKAGE__->belongs_to( "permission_set",
  "Rex::IO::Server::Schema::Result::PermissionSet",
  "permission_set_id" );

sub has_perm {
  my ( $self, $perm_type ) = @_;

  my $perm_set = $self->permission_set;

  for my $perm ( $perm_set->permissions ) {
    if ( defined $perm->user_id ) {
      next if ( $perm->user_id != $self->id );
      return 1
        if ( $perm->user_id == $self->id && $perm_type eq $perm->permission_type->name );
    }
    elsif ( defined $perm->group_id ) {

      # not implemented yet
    }
  }

  return 0;
}


sub to_hashRef {
  my ($self) = @_;
  return { $self->get_columns };
}

1;
