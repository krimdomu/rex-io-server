#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Hardware;
   
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use Mojo::UserAgent;

use Rex::IO::Server::Helper::IP;

use Data::Dumper;


sub list {
   my ($self) = @_;

   my @all_hw = $self->db->resultset('Hardware')->all;

   my @ret;

   for my $hw (@all_hw) {
      push(@ret, $hw->to_hashRef);
   }

   $self->render(json => \@ret);
}

sub search {
   my ($self) = @_;

   #my $hw_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->name % ($self->param("name") . '%'));
   my @hw_r = $self->db->resultset("Hardware")->search({ name => { like => $self->param("name") . '%' } });

   my @ret = ();

   for my $hw (@hw_r) {
      push(@ret, $hw->to_hashRef);
   }

   $self->render(json => \@ret);
}

sub get {
   my ($self) = @_;

   #my $hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->id == $self->param("id"))->next;
   my $hw = $self->db->resultset("Hardware")->find($self->param("id"));
   $self->render(json => $hw->to_hashRef);
}

sub update {
   my ($self) = @_;

   #my $hw_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->id == $self->param("id") );
   my $hw_r = $self->db->resultset("Hardware")->find($self->param("id"));

   $self->send_flush_cache();

   if(my $hw = $hw_r) {
      return eval {
         my $json = $self->req->json;

         for my $k (keys %{ $json }) {
            $hw->$k($json->{$k});
         }

         $hw->update;

         return $self->render(json => {ok => Mojo::JSON->true});
      } or do {
         return $self->render(json => {ok => Mojo::JSON->false, error => $@}, status => 500);
      };
   }
   else {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
   }
}

sub update_network_adapter {
   my ($self) = @_;

   my $nwa_id = $self->param("id");
   my $json = $self->req->json;

   $self->send_flush_cache();

   return eval {
      #my $nw_a = Rex::IO::Server::Model::NetworkAdapter->all( Rex::IO::Server::Model::NetworkAdapter->id == $nwa_id )->next;
      my $nw_a = $self->db->resultset("NetworkAdapter")->find($nwa_id);

      my @calc_int = qw/wanted_ip wanted_netmask wanted_broadcast wanted_network wanted_gateway ip netmask broadcast network gateway/;

      for my $k (keys %{ $json }) {
         if(@calc_int ~~ m/$k/ && $json->{$k}) {
            $json->{$k} = ip_to_int($json->{$k});
         }

         $nw_a->$k($json->{$k});
      }

      $nw_a->update;

      if($json->{boot} && $nw_a->wanted_ip) {
         # if this is the boot device, register ip/mac in dhcp
         $self->_ua->post($self->config->{dhcp}->{server} . "/" . $nw_a->mac, json => {
            name => $nw_a->hardware->name,
            ip   => int_to_ip($nw_a->wanted_ip),
         });
      }

      return $self->render(json => {ok => Mojo::JSON->true});
   } or do {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 500);
   };
}

sub purge {
   my ($self) = @_;

   my $hw_i = $self->db->resultset("Hardware")->find($self->param("id"));

   $self->send_flush_cache();

   # deregister hardware on dhcp
   eval {
      $self->_ua->delete($self->config->{dhcp}->{server} . "/" . $hw_i->name);
   } or do {
      $self->app->log->error("error deregistering " . $hw_i->name . " on dhcp server: $@");
   };



   eval {
      if(my $hw = $hw_i) {

         # give plugins the possibility to clean up
         for my $plug (@{ $self->config->{plugins} }) {
            my $klass = "Rex::IO::Server::$plug";
            eval "require $klass";
            eval { $klass->__delete_hardware__($self, $hw); };
         }

         $hw->purge;
         return $self->render(json => {ok => Mojo::JSON->true});
      }
      else {
         return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
      }
   } or do {
      return $self->render(json => {ok => Mojo::JSON->false, error => $@}, status => 500);
   };

}

################################################################################
# manage network adapters
################################################################################
sub list_network_adapter {
   my ($self) = @_;
   my $hardware_id = $self->param("hardware_id");

   my $hw = $self->db->resultset("Hardware")->find($hardware_id);
   if(! $hw) {
      return $self->render(json => { ok => Mojo::JSON->false, error => "Hardware not found."}, status => 404);
   }

   my $ret = $hw->to_hashRef()->{network_adapters};

   $self->render(json => { ok => Mojo::JSON->true, data => $ret });
}

sub add_network_adapter {
   my ($self) = @_;

   my $ref = $self->req->json;
   my $hardware_id = $self->param("hardware_id");

   $ref->{hardware_id} = $hardware_id;

   my $hw = $self->db->resultset("Hardware")->find($hardware_id);
   if(! $hw) {
      return $self->render(json => { ok => Mojo::JSON->false, error => "Hardware not found."}, status => 404);
   }

   for my $k (qw/ip netmask network gateway broadcast/) {
       $ref->{$k} = ip_to_int $ref->{$k} if(exists $ref->{$k} && $ref->{$k});
       $ref->{"wanted_$k"} = ip_to_int $ref->{$k} if(exists $ref->{$k} && $ref->{$k});
   }


   $self->send_flush_cache();

   my $nwa = $self->db->resultset("NetworkAdapter")->create($ref);

   $self->render(json => { ok => Mojo::JSON->true, data => $nwa->to_hashRef() });
}

sub del_network_adapter {
   my ($self) = @_;

   my $hardware_id = $self->param("hardware_id");
   my $network_adapter_id   = $self->param("network_adapter_id");

   my $hw = $self->db->resultset("Hardware")->find($hardware_id);
   if(! $hw) {
      return $self->render(json => { ok => Mojo::JSON->false, error => "Hardware not found."}, status => 404);
   }

   my $nwa = $self->db->resultset("NetworkAdapter")->find($network_adapter_id);
   if(! $nwa) {
      return $self->render(json => { ok => Mojo::JSON->false, error => "Network Adapter not found."}, status => 404);
   }

   $self->send_flush_cache();

   $nwa->delete;

   $self->render(json => { ok => Mojo::JSON->true });
}

sub get_network_adapter {
   my ($self) = @_;

   my $hardware_id = $self->param("hardware_id");
   my $network_adapter_id   = $self->param("network_adapter_id");

   my $hw = $self->db->resultset("Hardware")->find($hardware_id);
   if(! $hw) {
      return $self->render(json => { ok => Mojo::JSON->false, error => "Hardware not found."}, status => 404);
   }

   my $nwa = $self->db->resultset("NetworkAdapter")->find($network_adapter_id);
   if(! $nwa) {
      return $self->render(json => { ok => Mojo::JSON->false, error => "Network Adapter not found."}, status => 404);
   }

   $self->render(json => { ok => Mojo::JSON->true, data => $nwa->to_hashRef() }); 
}

sub update_network_adapter {
   my ($self) = @_;

   my $hardware_id = $self->param("hardware_id");
   my $network_adapter_id   = $self->param("network_adapter_id");

   my $hw = $self->db->resultset("Hardware")->find($hardware_id);
   if(! $hw) {
      return $self->render(json => { ok => Mojo::JSON->false, error => "Hardware not found."}, status => 404);
   }

   my $nwa = $self->db->resultset("NetworkAdapter")->find($network_adapter_id);
   if(! $nwa) {
      return $self->render(json => { ok => Mojo::JSON->false, error => "Network Adapter not found."}, status => 404);
   }

   $self->send_flush_cache();

   eval {
      $self->app->log->debug("Updating network adapter: " . $nwa->id);
      $self->app->log->debug(Dumper($self->req->json));

      my $ref = $self->req->json;

      for my $k (qw/ip netmask network gateway broadcast/) {
         $ref->{$k} = ip_to_int $ref->{$k} if(exists $ref->{$k} && $ref->{$k});      # beachten: nicht im inventory state
         $ref->{"wanted_$k"} = ip_to_int $ref->{$k} if(exists $ref->{$k} && $ref->{$k});
      }

      $nwa->update($ref);
      1;
   } or do {
      $self->app->log->error("Error updating network adapter: $@");
      return $self->render(json => { ok => Mojo::JSON->false, error => "Error: $@" }, error => 500); 
   };

   $self->render(json => { ok => Mojo::JSON->true, data => $nwa->to_hashRef() }); 
}

################################################################################
# manage bridges
################################################################################
# create a new bridge
sub add_bridge {
   my ($self) = @_;

   my $ref = $self->req->json;
   my $hardware_id = $self->param("hardware_id");

   $ref->{hardware_id} = $hardware_id;

   my $hw = $self->db->resultset("Hardware")->find($hardware_id);
   if(! $hw) {
      return $self->render(json => { ok => Mojo::JSON->false, error => "Hardware not found."}, status => 404);
   }

   for my $k (qw/ip netmask network gateway broadcast/) {
      $ref->{$k} = ip_to_int $ref->{$k} if(exists $ref->{$k} && $ref->{$k});      # beachten: nicht im inventory state
   }

   $self->send_flush_cache();

   my $bridge = $self->db->resultset("NetworkBridge")->create($ref);

   $self->render(json => { ok => Mojo::JSON->true, data => $bridge->to_hashRef() });
}

# list bridges
sub list_bridges {
   my ($self) = @_;

   my @all_bridges = $self->db->resultset("NetworkBridge")->search({hardware_id => $self->param("hardware_id")});

   my $ret = [];
   for my $br (@all_bridges) {
      push @{ $ret }, $br->to_hashRef;
   }

   $self->render(json => { ok => Mojo::JSON->true, data => $ret });
}

# delete bridge
sub del_bridge {
   my ($self) = @_;

   my $hardware_id = $self->param("hardware_id");
   my $bridge_id   = $self->param("bridge_id");

   my $hw = $self->db->resultset("Hardware")->find($hardware_id);
   if(! $hw) {
      return $self->render(json => { ok => Mojo::JSON->false, error => "Hardware not found."}, status => 404);
   }

   my $br = $self->db->resultset("NetworkBridge")->find($bridge_id);
   if(! $br) {
      return $self->render(json => { ok => Mojo::JSON->false, error => "Bridge not found."}, status => 404);
   }

   $self->send_flush_cache();
   $br->delete;

   $self->render(json => { ok => Mojo::JSON->true });
}

sub get_bridge {
   my ($self) = @_;

   my $hardware_id = $self->param("hardware_id");
   my $bridge_id   = $self->param("bridge_id");

   my $hw = $self->db->resultset("Hardware")->find($hardware_id);
   if(! $hw) {
      return $self->render(json => { ok => Mojo::JSON->false, error => "Hardware not found."}, status => 404);
   }

   my $br = $self->db->resultset("NetworkBridge")->find($bridge_id);
   if(! $br) {
      return $self->render(json => { ok => Mojo::JSON->false, error => "Bridge not found."}, status => 404);
   }

   $self->render(json => { ok => Mojo::JSON->true, data => $br->to_hashRef() }); 
}

################################################################################
# internal functions
################################################################################
sub _ua { return Mojo::UserAgent->new; }

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->route("/hardware")->via("LIST")->over(authenticated => 1)->to("hardware#list");
   $r->get("/hardware/search/:name")->over(authenticated => 1)->to("hardware#search");
   $r->post("/hardware/:id")->over(authenticated => 1)->to("hardware#update");
   $r->get("/hardware/:id")->over(authenticated => 1)->to("hardware#get");
   $r->post("/hardware")->over(authenticated => 1)->to("hardware#add");

   # new routes
   $r->get("/1.0/hardware/hardware/:hardware_id/bridge/:bridge_id")->over(authenticated => 1)->to("hardware#get_bridge");
   $r->post("/1.0/hardware/hardware/:hardware_id/bridge/new")->over(authenticated => 1)->to("hardware#add_bridge");
   $r->route("/1.0/hardware/hardware/:hardware_id/bridge")->via("LIST")->over(authenticated => 1)->to("hardware#list_bridges");
   $r->delete("/1.0/hardware/hardware/:hardware_id/bridge/:bridge_id")->over(authenticated => 1)->to("hardware#del_bridge");

   $r->get("/1.0/hardware/hardware/:hardware_id/network_adapter/:network_adapter_id")->over(authenticated => 1)->to("hardware#get_network_adapter");
   $r->post("/1.0/hardware/hardware/:hardware_id/network_adapter/new")->over(authenticated => 1)->to("hardware#add_network_adapter");
   $r->post("/1.0/hardware/hardware/:hardware_id/network_adapter/:network_adapter_id")->over(authenticated => 1)->to("hardware#update_network_adapter");
   $r->route("/1.0/hardware/hardware/:hardware_id/network_adapter")->via("LIST")->over(authenticated => 1)->to("hardware#list_network_adapter");
   $r->delete("/1.0/hardware/hardware/:hardware_id/network_adapter/:network_adapter_id")->over(authenticated => 1)->to("hardware#del_network_adapter");
}


1;
