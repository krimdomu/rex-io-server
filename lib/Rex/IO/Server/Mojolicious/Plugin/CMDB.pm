#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Mojolicious::Plugin::CMDB;
   
use strict;
use warnings;

use Mojolicious::Plugin;
use Rex::IO::Server::CMDB;
use base 'Mojolicious::Plugin';

sub register {
   my ( $plugin, $app ) = @_;

   $app->helper(
      cmdb => sub {
         my $self = shift;
         return Rex::IO::Server::CMDB->new;
      }
   );
}

1;
