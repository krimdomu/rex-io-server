package Rex::IO::Server;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
  my $self = shift;

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer');
  $self->plugin("Rex::IO::Server::Mojolicious::Plugin::CMDB");

  # Router
  my $r = $self->routes;

  $r->get('/server/:name')->to('server#get');

}

1;
