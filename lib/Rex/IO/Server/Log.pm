#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Log;
use Mojo::Base 'Mojolicious::Controller';

use Net::DNS;
use Data::Dumper;
use Mojo::JSON;

sub append {
   my ($self) = @_;

   $self->app->log_writer->write($self->param("tag"), $self->req->json);

   $self->render(json => {ok => Mojo::JSON->true});
}

sub get_logs {
   my ($self) = @_;

   my $server_id = $self->param("server_id");

   my $json = $self->req->json;
   $json ||= {};

   my $server = $self->db->resultset("Hardware")->find($server_id);

   my $ret = $self->app->log_writer->search(host => $server->name, %{ $json });

   $self->render(json => $ret);
}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->post("/log/server/:server_id")->to("log#get_logs");
   $r->post("/log/#tag")->to("log#append");
}

1;
