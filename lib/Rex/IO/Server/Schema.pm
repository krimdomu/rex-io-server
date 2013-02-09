#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema;

use strict;
use warnings;

use base qw(DBIx::Class::Schema);
__PACKAGE__->load_namespaces;

1;
