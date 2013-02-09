#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema::Result::OsTemplate;

use strict;
use warnings;

use base qw(DBIx::Class::Core);

__PACKAGE__->load_components(qw/InflateColumn::DateTime/);
__PACKAGE__->table("os_template");
__PACKAGE__->add_columns(qw/id name kernel initrd append template ipxe/);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many("hardwares", "Rex::IO::Server::Schema::Result::Hardware", "os_template_id");

1;
