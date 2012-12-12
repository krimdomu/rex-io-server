#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Host;
use Mojo::Base 'Mojolicious::Controller';

use Net::DNS;
use Data::Dumper;
use Mojo::JSON;

sub add {
   my ($self) = @_;

   my $mac = $self->stash("mac");

   my $json = $self->req->json;
   my $name = $json->{name};

   eval {
      my $hw = Rex::IO::Server::Model::Hardware->new(
         name => $name,
         uuid => $json->{uuid},
         state_id => 1, # set unknown default state
      );

      $hw->save;

      my $nw_a = Rex::IO::Server::Model::NetworkAdapter->new(
         hardware_id => $hw->id,
         proto       => "dhcp",
         boot        => 1,
         mac         => $mac,
      );

      $nw_a->save;

      return $self->render_json({ok => Mojo::JSON->true});
   } or do {
      return $self->render_json({ok => Mojo::JSON->false, error => $@}, status => 500);
   };
}

sub list {
   my ($self) = @_;

   my $hw = Rex::IO::Server::Model::Hardware->all;

   my @ret;
   while(my $h = $hw->next) {
      push(@ret, $h->to_hashRef);
   }

   $self->render_json({ok => Mojo::JSON->true, data => \@ret});
}

sub get {
   my ($self) = @_;

   my $hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->mac == $self->stash("mac") );

   if(my $data = $hw->next) {
      my $ret = $data->get_data;

      my $state = $data->state->next;
      $ret->{state} = $state->name;

      $ret->{ok} = Mojo::JSON->true;
      return $self->render_json($ret);
   }

   $self->render_json({ok => Mojo::JSON->false}, status => 404);
}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->get("/host/:mac")->to("host#get");
   $r->post("/host/:mac")->to("host#add");
   $r->route("/host")->via("LIST")->to("host#list");
}

1;
