#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Mojolicious::Plugin::User;

use strict;
use warnings;

use Mojolicious::Plugin;
use Rex::IO::Server::Auth::User;

use base 'Mojolicious::Plugin';

sub register {
  my ( $plugin, $app ) = @_;

  $app->helper(
    get_user => sub {
      my ( $self, $find_type, $data ) = @_;

      my $u = Rex::IO::Server::Auth::User->new( app => $app );
      return $u->load( $find_type, $data );
    },
  );

  $app->helper(
    current_user => sub {
      my ($self) = @_;
      my $u = Rex::IO::Server::Auth::User->new( app => $app );
      return $u->load( 'by_id', $self->session('uid') );
    },
  );

  $app->routes->add_condition(
    authenticated => sub {
      my ( $r, $c, $captures, $required ) = @_;
      return 1 if $c->basic_auth;
      return 0;
    }
  );
}

1;
