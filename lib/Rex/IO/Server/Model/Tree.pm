#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Model::Tree;

use strict;
use warnings;

use base qw(DBIx::ORMapper::DM::DataSource::Table);

__PACKAGE__->attr(id => "Integer");
__PACKAGE__->attr(parent => "Integer");
__PACKAGE__->attr(name => "String");

__PACKAGE__->table("tree");
__PACKAGE__->primary_key("id");

__PACKAGE__->has_n("Children", "Rex::IO::Server::Model::Tree", "parent");
__PACKAGE__->belongs_to("Parent", "Rex::IO::Server::Model::Tree", "parent");

1;
