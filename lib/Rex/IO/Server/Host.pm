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
#      my $hw = Rex::IO::Server::Model::Hardware->new(
#         name => $name,
#         uuid => $json->{uuid},
#         state_id => 1, # set unknown default state
#      );

      my $hw = $self->db->resultset("Hardware")->create({
         name => $name,
         uuid => $json->{uuid},
         state_id => 1,
      });

      $hw->update;

#      my $nw_a = Rex::IO::Server::Model::NetworkAdapter->new(
#         hardware_id => $hw->id,
#         proto       => "dhcp",
#         boot        => 1,
#         mac         => $mac,
#      );
      my $nw_a = $self->db->resultset("NetworkAdapter")->create({
         hardware_id => $hw->id,
         proto       => "dhcp",
         boot        => 1,
         mac         => $mac,
      });

      $nw_a->update;

      return $self->render_json({ok => Mojo::JSON->true});
   } or do {
      return $self->render_json({ok => Mojo::JSON->false, error => $@}, status => 500);
   };
}

sub list {
   my ($self) = @_;

   my @all_hw = $self->db->resultset('Hardware')->all;

   my @ret;

   for my $hw (@all_hw) {
      push(@ret, $hw->to_hashRef);
   }

   $self->render_json({ok => Mojo::JSON->true, data => \@ret});
}

sub get {
   my ($self) = @_;

   #my $hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->mac == $self->stash("mac") );
   my $hw = $self->db->resultset("Hardware")->search({ mac => $self->stash("mac") });

   if(my $data = $hw->first) {
      my $ret = { $data->get_columns };

      my $state = $data->state;
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
