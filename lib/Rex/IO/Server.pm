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

our $VERSION = "0.0.5";

# This method will run once at server start
sub startup {
   my $self = shift;

   #######################################################################
   # Define some custom helpers
   #######################################################################
   $self->helper(db => sub { $self->app->schema });

   #######################################################################
   # Load configuration
   #######################################################################
   my @cfg = ("/etc/rex/io/server.conf", "/usr/local/etc/rex/io/server.conf", "server.conf");
   my $cfg;
   for my $file (@cfg) {
      if(-f $file) {
         $cfg = $file;
         last;
      }
   }

   #######################################################################
   # Load plugins
   #######################################################################
   $self->plugin("Config", file => $cfg);
   $self->plugin("Rex::IO::Server::Mojolicious::Plugin::IP");
   $self->plugin("Rex::IO::Server::Mojolicious::Plugin::User");
   $self->plugin("Authentication" => {
      autoload_user => 1,
      session_key   => $self->config->{session}->{key},
      load_user     => sub {
         my ($app, $uid) = @_;
         my $user = $app->get_user(by_id => $uid);
         return $user; # user objekt
      },
      validate_user => sub {
         my ($app, $username, $password, $extra_data) = @_;
         my $user = $app->get_user(by_name => $username);

         if($user->check_password($password)) {
            return $user->id;
         }

         return;
      },
   });

   #######################################################################
   # Setup routing
   #######################################################################
   my $r = $self->routes;

   #######################################################################
   # routes that don't need authentication
   #######################################################################
   $r->websocket("/messagebroker")->to("message_broker#broker");

   # authentication route. needs to be split out in an own controller
   $r->post("/auth")->to(cb => sub {
      my ($app) = @_;
      my $data = $app->req->json;

      if($app->authenticate($data->{user}, $data->{password})) {
         my $user = $app->current_user;
         return $app->render_json({ok => Mojo::JSON->true, data => {
               id   => $user->id,
               name => $user->name,
            }}, status => 200);
      }
      else {
         return $app->render_json({ok => Mojo::JSON->false}, status => 401);
      }
   });

   #######################################################################
   # routes that need authentication
   #######################################################################
   $r->route("/messagebroker/clients")->via("LIST")->over(authenticated => 1)->to("message_broker#clients");
   $r->post("/messagebroker/:to")->over(authenticated => 1)->to("message_broker#message_to_server");
   $r->get("/messagebroker/online/#ip")->over(authenticated => 1)->to("message_broker#is_online");

   for my $ctrl (qw/hardware os os_template/) {
      my $ctrl_route = $ctrl;
      $ctrl_route =~ s/_/-/gms;
      $r->route("/$ctrl_route")->via("LIST")->over(authenticated => 1)->to("$ctrl#list");
      $r->get("/$ctrl_route/search/:name")->over(authenticated => 1)->to("$ctrl#search");
      $r->post("/$ctrl_route/:id")->over(authenticated => 1)->to("$ctrl#update");
      $r->get("/$ctrl_route/:id")->over(authenticated => 1)->to("$ctrl#get");
      $r->post("/$ctrl_route")->over(authenticated => 1)->to("$ctrl#add");
   }

   $r->delete("/hardware/:id")->over(authenticated => 1)->to("hardware#purge");

   $r->post("/network-adapter/:id")->over(authenticated => 1)->to("hardware#update_network_adapter");

   $r->get("/user/:id")->over(authenticated => 1)->to("user#get");

   #
   # load server plugins
   #
   for my $plug (@{ $self->{defaults}->{config}->{plugins} }) {
      my $s = "Rex::IO::Server::$plug";
      eval "require $s";
      $s->__register__($self);
   }

   $r->get("/plugins")->over(authenticated => 1)->to("plugin#list");

}

1;
