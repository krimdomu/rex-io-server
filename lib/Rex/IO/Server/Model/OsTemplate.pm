#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Model::OsTemplate;

use strict;
use warnings;

use base qw(DBIx::ORMapper::DM::DataSource::Table);

__PACKAGE__->attr(id => "Integer");
__PACKAGE__->attr(name => "String");
__PACKAGE__->attr(kernel => "String");
__PACKAGE__->attr(initrd => "String");
__PACKAGE__->attr(append => "Text");
__PACKAGE__->attr(template => "Text");
__PACKAGE__->attr(ipxe => "Text");

__PACKAGE__->table("os_template");
__PACKAGE__->primary_key("id");

__PACKAGE__->belongs_to("hardware", "Rex::IO::Server::Model::Hardware", "os_template_id");

1;
