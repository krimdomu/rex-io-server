package Rex::IO::Server::Cmdb;
use Mojo::Base 'Mojolicious::Controller';

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->delete('/service/:name')->to('cmdb-service#delete');
   $r->delete('/server/:name')->to('cmdb-server#delete');

   $r->post('/server')->to('cmdb-server#post');
   $r->post('/service')->to('cmdb-service#post');

   $r->get('/service/:name')->to('cmdb-service#get');
   $r->get('/server/:name')->to('cmdb-server#get');

   $r->route('/server')->via("LIST")->to("cmdb-server#list");
   $r->route('/service')->via("LIST")->to("service#list");

   $r->route('/server/:name')->via("LINK")->to("server#link");
   $r->route('/server/:name')->via("UNLINK")->to("server#unlink");


   $r->put("/server/:name/service/:service")->to("server#service_put");

   $r->put("/server/:name/:section")->to("server#section_put");
}

1;
