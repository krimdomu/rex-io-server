#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Mojolicious::Plugin::CHI;
  
use strict;
use warnings;

use Mojolicious::Plugin;
use CHI;
use base 'Mojolicious::Plugin';

my $cache;

sub register {
  my ( $plugin, $app ) = @_;

  $app->helper(
    chi => sub {
      my $self = shift;
      if(!$cache) {
        $cache = CHI->new(driver => "Memory", global => 1);
      }
      return $cache;
    }
  );
}

1;
