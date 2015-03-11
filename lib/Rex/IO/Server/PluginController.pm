#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::PluginController;

use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

sub render {
  my ($self, @rest) = @_;
  $self->app->log->debug("Rendering:");
  $self->app->log->debug(Dumper(\@rest));
  $self->SUPER::render(@rest);
}

1;
