#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::MessageBroker::Ping;

use Moo;
use Data::Dumper;

has app  => ( is => 'ro' );
has ctrl => ( is => 'ro' );

sub messagebroker_process {
  my ( $self, $message ) = @_;

  $self->app->log->debug("Processing ping message:");
  $self->app->log->debug( Dumper($message) );

  my $key = "status:" . $self->ctrl->tx->remote_address . ":online";

  $self->app->redis->set( $key, 1 );
  $self->app->redis->expireat(
    $key,
    time + (
      $self->app->config->{agent}->{keep_alive_timeout} *
        $self->app->config->{agent}->{keep_alive_flap}
    )
  );
}

1;
