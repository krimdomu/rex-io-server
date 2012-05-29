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

  $r->delete('/service/:name')->to('service#delete');
  $r->delete('/server/:name')->to('server#delete');

  $r->post('/server')->to('server#post');
  $r->post('/service')->to('service#post');

  $r->get('/service/:name')->to('service#get');
  $r->get('/server/:name')->to('server#get');

  $r->route('/server')->via("LIST")->to("server#list");
  $r->route('/service')->via("LIST")->to("service#list");

}

1;
