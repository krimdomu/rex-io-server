#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Model::Hardware;

use strict;
use warnings;

use base qw(DBIx::ORMapper::DM::DataSource::Table);

__PACKAGE__->attr(id => "Integer");
__PACKAGE__->attr(name => "String");
__PACKAGE__->attr(ip => "String");
__PACKAGE__->attr(mac => "String");
__PACKAGE__->attr(state_id => "Integer");
__PACKAGE__->attr(os_template_id => "Integer");

__PACKAGE__->table("hardware");
__PACKAGE__->primary_key("id");

__PACKAGE__->belongs_to("state" => "Rex::IO::Server::Model::HardwareState", "state_id");
__PACKAGE__->belongs_to("os_template" => "Rex::IO::Server::Model::OsTemplate", "os_template_id");

1;
