#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Hardware;
   
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

use Rex::IO::Server::Helper::IP;

use Data::Dumper;


sub list {
   my ($self) = @_;

   my $hw_r = Rex::IO::Server::Model::Hardware->all;

   my @ret = ();

   while(my $hw = $hw_r->next) {
      push(@ret, $hw->to_hashRef);
   }

   $self->render_json(\@ret);
}

sub search {
   my ($self) = @_;

   my $hw_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->name % ($self->param("name") . '%'));

   my @ret = ();

   while(my $hw = $hw_r->next) {
      push(@ret, $hw->to_hashRef);
   }

   $self->render_json(\@ret);
}

sub get {
   my ($self) = @_;

   my $hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->id == $self->param("id"))->next;
   $self->render_json($hw->to_hashRef);
}

sub update {
   my ($self) = @_;

   my $hw_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->id == $self->param("id") );

   if(my $hw = $hw_r->next) {
      return eval {
         my $json = $self->req->json;

         for my $k (keys %{ $json }) {
            $hw->$k = $json->{$k};
         }

         $hw->update;

         return $self->render_json({ok => Mojo::JSON->true});
      } or do {
         return $self->render_json({ok => Mojo::JSON->false, error => $@}, status => 500);
      };
   }
   else {
      return $self->render_json({ok => Mojo::JSON->false}, status => 404);
   }
}

sub update_network_adapter {
   my ($self) = @_;

   my $nwa_id = $self->param("id");
   my $json = $self->req->json;

   return eval {
      my $nw_a = Rex::IO::Server::Model::NetworkAdapter->all( Rex::IO::Server::Model::NetworkAdapter->id == $nwa_id )->next;

      my @calc_int = qw/ip netmask broadcast network gateway/;

      for my $k (keys %{ $json }) {
         if(@calc_int ~~ m/$k/ && $json->{$k}) {
            $json->{$k} = ip_to_int($json->{$k});
         }

         $nw_a->$k = $json->{$k};
      }

      $nw_a->update;

      return $self->render_json({ok => Mojo::JSON->true});
   } or do {
      return $self->render_json({ok => Mojo::JSON->false}, status => 500);
   };
}


1;
