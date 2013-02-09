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

=cut

package Rex::IO::Server;
use Mojo::Base 'Mojolicious';
use Mojo::UserAgent;
use Mojo::IOLoop;
use Data::Dumper;

use Rex::IO::Server::Schema;

has schema => sub {
   my ($self) = @_;

   my $dsn = "DBI:mysql:"
           . "database=". $self->config->{database}->{schema} . ";"
           . "host="    . $self->config->{database}->{host};
            
   return Rex::IO::Server::Schema->connect($dsn, 
      $self->config->{database}->{username},
      $self->config->{database}->{password});
};

our $VERSION = "0.0.4";

# This method will run once at server start
sub startup {
   my $self = shift;

   # Documentation browser under "/perldoc"
   #$self->plugin('PODRenderer');

   $self->helper(db => sub { $self->app->schema });

   my @cfg = ("/etc/rex/io/server.conf", "/usr/local/etc/rex/io/server.conf", "server.conf");
   my $cfg;
   for my $file (@cfg) {
      if(-f $file) {
         $cfg = $file;
         last;
      }
   }
   $self->plugin('Config', file => $cfg);
   $self->plugin('Rex::IO::Server::Mojolicious::Plugin::IP');

   # Router
   my $r = $self->routes;

   # message broker routes
   $r->websocket("/messagebroker")->to("message_broker#broker");
   $r->route("/messagebroker/clients")->via("LIST")->to("message_broker#clients");
   $r->post("/messagebroker/:to")->to("message_broker#message_to_server");
   $r->get("/messagebroker/online/#ip")->to("message_broker#is_online");

   for my $ctrl (qw/hardware os os_template/) {
      my $ctrl_route = $ctrl;
      $ctrl_route =~ s/_/-/gms;
      $r->route("/$ctrl_route")->via("LIST")->to("$ctrl#list");
      $r->get("/$ctrl_route/search/:name")->to("$ctrl#search");
      $r->post("/$ctrl_route/:id")->to("$ctrl#update");
      $r->get("/$ctrl_route/:id")->to("$ctrl#get");
      $r->post("/$ctrl_route")->to("$ctrl#add");
   }

   $r->delete("/hardware/:id")->to("hardware#purge");

   $r->post("/network-adapter/:id")->to("hardware#update_network_adapter");


   $r->get("/tree/root")->to("tree#root");

   # load server plugins
   for my $plug (@{ $self->{defaults}->{config}->{plugins} }) {
      my $s = "Rex::IO::Server::$plug";
      eval "require $s";
      $s->__register__($self);
   }

   $r->get("/plugins")->to("plugin#list");

}

1;
