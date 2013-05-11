#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::IO::Server::ServerGroup;
use Mojo::Base 'Mojolicious::Controller';

use Net::DNS;
use Data::Dumper;
use Mojo::JSON;

sub list {
   my ($self) = @_;

   my @sgs = $self->db->resultset("ServerGroup")->all;

   my @ret;
   for my $sg (@sgs) {
      push @ret, { $sg->get_columns };
   }

   $self->render_json({ok => Mojo::JSON->true, data => \@ret});
}

sub add {
   my ($self) = @_;

   my $ret = eval {
      my $group = $self->db->resultset("ServerGroup")->create($self->req->json);
      $self->render_json({ok => Mojo::JSON->true, id => $group->id});
   } or do {
      return $self->render_json({ok => Mojo::JSON->false, error => $@}, status => 500);
   };

   return $ret;
}

sub add_server_to_group {
   my ($self) = @_;

   my $server_id = $self->param("server_id");
   my $group_id  = $self->param("group_id");

   my $srv = $self->db->resultset("Hardware")->find($server_id);
   my $grp = $self->db->resultset("ServerGroup")->find($group_id);

   if($srv && $grp) {
      $srv->update({
         server_group_id => $group_id,
      });
      return $self->render_json({ok => Mojo::JSON->true});
   }
   else {
      return $self->render_json({ok => Mojo::JSON->false}, status => 404);
   }
}

sub del_server_group {
   my ($self) = @_;

   my $grp = $self->db->resultset("ServerGroup")->find($self->param("group_id"));
   if($grp) { 
      $grp->delete;

      return $self->render_json({ok => Mojo::JSON->true});
   }

   return $self->render_json({ok => Mojo::JSON->false}, status => 404);
}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->route("/server_group")->via("LIST")->to("server_group#list");
   $r->post("/server_group")->to("server_group#add");
   $r->post("/server_group/server/:server_id/:group_id")->to("server_group#add_server_to_group");
   $r->delete("/server_group/:group_id")->to("server_group#del_server_group");
}


1;
