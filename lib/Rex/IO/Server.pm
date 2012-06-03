#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
=head1 NAME

Rex::IO::Server - The webservice component of Rex.IO

This is the webservice component of Rex.IO tieing all supported services together under one API.

=head1 GETTING HELP

=over 4

=item * IRC: irc.freenode.net #rex

=item * Bug Tracker: L<https://github.com/krimdomu/rex-io-server/issues>

=back

=head1 INSTALLATION

With cpanminus:

 cpanm Rex::IO::Server

After installing create the file I</etc/rex/io/server.conf>. And set the url to Rex::IO::CMDB.

 {
    cmdb => "http://rex-cmdb:3000",
 }

And start the server:

 rex_ioserver daemon

You can also define an other Listen Port (default is 3000)

 rex_ioserver daemon -l 'http://:4000'

Right now there is no Webinterface. You can test if everything is correct with the following command:

 curl -X LIST http://localhost:3000/server

If you get an answer like this it works:

 {"ok":true,"data":{}}


=cut

package Rex::IO::Server;
use Mojo::Base 'Mojolicious';

our $VERSION = "0.0.1";

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
