#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Schema::Result::ServerGroupTree;

use strict;
use warnings;

use Data::Dumper;

use JSON::XS;

use base qw(DBIx::Class::Core);
__PACKAGE__->load_components(qw( Tree::NestedSet ));

__PACKAGE__->table("server_group_tree");
__PACKAGE__->add_columns( qw/id root_id lft rgt level permission_set_id name/ );

__PACKAGE__->set_primary_key("id");

__PACKAGE__->tree_columns({
    root_column     => 'root_id',
    left_column     => 'lft',
    right_column    => 'rgt',
    level_column    => 'level',
});

__PACKAGE__->belongs_to(
  "permission_set" => "Rex::IO::Server::Schema::Result::PermissionSet",
  "permission_set_id"
);


sub has_perm {
  my ( $self, $perm_type, $user_o ) = @_;

  my $perm_set = $self->permission_set;

  for my $perm ( $perm_set->permissions ) {
    if ( defined $perm->user_id ) {
      next if ( $perm->user_id != $user_o->id );
      return 1
        if ( $perm->user_id == $user_o->id
        && $perm_type eq $perm->permission_type->name );
    }
    elsif ( defined $perm->group_id ) {

      # not implemented yet
    }
  }

  return 0;
}

1;
