#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Model::Bios;

use strict;
use warnings;

use base qw(DBIx::ORMapper::DM::DataSource::Table);

__PACKAGE__->attr(id => "Integer");
__PACKAGE__->attr(hardware_id => "Integer");
__PACKAGE__->attr(biosdate => "DateTime");
__PACKAGE__->attr(version => "String");
__PACKAGE__->attr(ssn => "String");
__PACKAGE__->attr(manufacturer => "String");
__PACKAGE__->attr(model => "String");

__PACKAGE__->table("bios");
__PACKAGE__->primary_key("id");

__PACKAGE__->belongs_to("hardware", "Rex::IO::Server::Model::Hardware", "hardware_id");

1;
