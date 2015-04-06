#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Schema;

use strict;
use warnings;

our $VERSION = 1;

use base qw(DBIx::Class::Schema);
__PACKAGE__->load_namespaces;

1;
