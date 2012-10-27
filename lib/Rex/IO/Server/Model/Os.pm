#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Model::Os;

use strict;
use warnings;

use base qw(DBIx::ORMapper::DM::DataSource::Table);

__PACKAGE__->attr(id => "Integer");
__PACKAGE__->attr(name => "String");
__PACKAGE__->attr(version => "String");

__PACKAGE__->table("os");
__PACKAGE__->primary_key("id");

__PACKAGE__->has_n("hardware", "Rex::IO::Server::Model::Hardware", "os_id");


1;
