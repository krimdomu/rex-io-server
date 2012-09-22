#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Model::HardwareState;

use strict;
use warnings;

use base qw(DBIx::ORMapper::DM::DataSource::Table);

__PACKAGE__->attr(id => "Integer");
__PACKAGE__->attr(name => "String");

__PACKAGE__->table("hardware_state");
__PACKAGE__->primary_key("id");

__PACKAGE__->has_n("hardware", "Rex::IO::Server::Model::Hardware", "state_id");

1;
