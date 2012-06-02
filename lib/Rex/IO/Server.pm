package Rex::IO::Server;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
   my $self = shift;

   # Documentation browser under "/perldoc"
   $self->plugin('PODRenderer');

   my @cfg = ("/etc/rex/io/server.conf", "/usr/local/etc/rex/io/server.conf", "server.conf");
   my $cfg;
   for my $file (@cfg) {
      if(-f $file) {
         $cfg = $file;
         last;
      }
   }
   $self->plugin('Config', file => $cfg);

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

   $r->route('/server/:name')->via("LINK")->to("server#link");
   $r->route('/server/:name')->via("UNLINK")->to("server#unlink");


   $r->put("/server/:name/service/:service")->to("server#service_put");

   $r->put("/server/:name/:section")->to("server#section_put");

   $r->post("/fusioninventory")->to("fusion_inventory#post");
}

1;
