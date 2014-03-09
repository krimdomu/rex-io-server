#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
  
package Rex::IO::Server::Mojolicious::Plugin::CMDB;
  
use strict;
use warnings;

use Mojolicious::Plugin;
use Rex::IO::Server::Helper::CMDB;
use base 'Mojolicious::Plugin';

sub register {
  my ( $plugin, $app ) = @_;

  $app->helper(
    cmdb => sub {
      my $self = shift;
      return Rex::IO::Server::Helper::CMDB->new(config => $app->{defaults}->{config});
    }
  );
}

1;
