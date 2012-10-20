#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Model::Memory;

use strict;
use warnings;

use base qw(DBIx::ORMapper::DM::DataSource::Table);

__PACKAGE__->attr(id => "Integer");
__PACKAGE__->attr(hardware_id => "Integer");
__PACKAGE__->attr(size => "Integer");
__PACKAGE__->attr(bank => "Integer");
__PACKAGE__->attr(serialnumber => "String");
__PACKAGE__->attr(speed => "Integer");
__PACKAGE__->attr(type => "String");

__PACKAGE__->table("memory");
__PACKAGE__->primary_key("id");

__PACKAGE__->belongs_to("hardware", "Rex::IO::Server::Model::Hardware", "hardware_id");

1;
