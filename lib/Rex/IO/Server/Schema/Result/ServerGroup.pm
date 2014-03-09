#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Schema::Result::ServerGroup;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime Tree::AdjacencyList/);
__PACKAGE__->table("server_groups");
__PACKAGE__->add_columns(qw/id parent_id name description created/);

__PACKAGE__->set_primary_key("id");
__PACKAGE__->parent_column("parent_id");

__PACKAGE__->has_many("hardware", "Rex::IO::Server::Schema::Result::Hardware", "server_group_id");

1;
