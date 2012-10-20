#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Model::Processor;

use strict;
use warnings;

use base qw(DBIx::ORMapper::DM::DataSource::Table);

__PACKAGE__->attr(id => "Integer");
__PACKAGE__->attr(hardware_id => "Integer");
__PACKAGE__->attr(modelname => "String");
__PACKAGE__->attr(vendor => "String");
__PACKAGE__->attr(flags => "String");
__PACKAGE__->attr(mhz => "Integer");
__PACKAGE__->attr(cache => "Integer");

__PACKAGE__->table("processor");
__PACKAGE__->primary_key("id");

__PACKAGE__->belongs_to("hardware", "Rex::IO::Server::Model::Hardware", "hardware_id");

1;
