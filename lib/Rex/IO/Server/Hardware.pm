#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Hardware;
   
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

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

sub update {
   my ($self) = @_;

   my $hw_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->id == $self->param("id") );

   if(my $hw = $hw_r->next) {
      eval {
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


1;
