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

   eval {
      if(my $hw = $hw_i) {
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

sub _ua { return Mojo::UserAgent->new; }

1;
