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

use DBIx::ORMapper;
use DBIx::ORMapper::Connection::Server::MySQL;
use DBIx::ORMapper::DM;

use Rex::IO::Server::Model::Hardware;
use Rex::IO::Server::Model::HardwareState;
use Rex::IO::Server::Model::OsTemplate;
use Rex::IO::Server::Model::NetworkAdapter;
use Rex::IO::Server::Model::Tree;
use Rex::IO::Server::Model::Bios;
use Rex::IO::Server::Model::Harddrive;
use Rex::IO::Server::Model::Memory;
use Rex::IO::Server::Model::Processor;
use Rex::IO::Server::Model::Os;

our $VERSION = "0.0.4";

# This method will run once at server start
sub startup {
   my $self = shift;

   # Documentation browser under "/perldoc"
   #$self->plugin('PODRenderer');

   my @cfg = ("/etc/rex/io/server.conf", "/usr/local/etc/rex/io/server.conf", "server.conf");
   my $cfg;
   for my $file (@cfg) {
      if(-f $file) {
         $cfg = $file;
         last;
      }
   }
   $self->plugin('Config', file => $cfg);

   # Router
   my $r = $self->routes;

   # message broker routes
   $r->websocket("/messagebroker")->to("message_broker#broker");
   $r->route("/messagebroker/clients")->via("LIST")->to("message_broker#clients");
   $r->post("/messagebroker/:to")->to("message_broker#message_to_server");

   for my $ctrl (qw/hardware os os_template/) {
      my $ctrl_route = $ctrl;
      $ctrl_route =~ s/_/-/gms;
      $r->route("/$ctrl_route")->via("LIST")->to("$ctrl#list");
      $r->get("/$ctrl_route/search/:name")->to("$ctrl#search");
      $r->post("/$ctrl_route/:id")->to("$ctrl#update");
      $r->get("/$ctrl_route/:id")->to("$ctrl#get");
      $r->post("/$ctrl_route")->to("$ctrl#add");
   }


   $r->get("/tree/root")->to("tree#root");

   # load server plugins
   for my $plug (@{ $self->{defaults}->{config}->{plugins} }) {
      my $s = "Rex::IO::Server::$plug";
      eval "require $s";
      $s->__register__($self);
   }

   # do database connection
   DBIx::ORMapper::setup(default => "MySQL://localhost/rexio_server?username=rexio&password=rexio");

   eval {
      my $db = DBIx::ORMapper::get_connection("default");
      $db->connect;

      Rex::IO::Server::Model::Hardware->set_data_source($db);
      Rex::IO::Server::Model::HardwareState->set_data_source($db);
      Rex::IO::Server::Model::OsTemplate->set_data_source($db);
      Rex::IO::Server::Model::NetworkAdapter->set_data_source($db);
      Rex::IO::Server::Model::Tree->set_data_source($db);
      Rex::IO::Server::Model::Bios->set_data_source($db);
      Rex::IO::Server::Model::Harddrive->set_data_source($db);
      Rex::IO::Server::Model::Memory->set_data_source($db);
      Rex::IO::Server::Model::Processor->set_data_source($db);
      Rex::IO::Server::Model::Os->set_data_source($db);
   } or do {
      die("Can't connect to database!\n$@");
   };

}

1;
