#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema::Result::Group;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("groups");
__PACKAGE__->add_columns(qw/id name/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many("users", "Rex::IO::Server::Schema::Result::User", "group_id");


1;
