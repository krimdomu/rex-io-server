#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Mojolicious::Plugin::Redis;

use strict;
use warnings;

use Mojolicious::Plugin;
use Rex::IO::Server::Helper::IP;
use base 'Mojolicious::Plugin';
use Mojo::Redis;

sub register {
  my ( $plugin, $app ) = @_;

  my $redis;

  $app->helper(
    redis => sub {
      if ($redis) { return $redis; }

      $redis =
        Mojo::Redis->new( server => $app->config->{redis}{default}{server} . ":"
          . $app->config->{redis}{default}{port} );

      return $redis;
    },
  );
}

1;
