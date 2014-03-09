#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema::Result::Memory;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("memory");
__PACKAGE__->add_columns(qw/id hardware_id size bank serialnumber speed type/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->belongs_to("hardware", "Rex::IO::Server::Schema::Result::Hardware", "hardware_id");

1;
