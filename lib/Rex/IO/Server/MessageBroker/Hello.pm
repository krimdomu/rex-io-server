#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::MessageBroker::Hello;

use Moo;
use Data::Dumper;

has app  => ( is => 'ro' );
has ctrl => ( is => 'ro' );

sub messagebroker_process {
  my ( $self, $message ) = @_;

  $self->app->log->debug("Processing message:");
  $self->app->log->debug(Dumper($message));
}

1;
