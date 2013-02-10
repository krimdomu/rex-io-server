#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::OsTemplate;
   
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

use Data::Dumper;

sub add {
   my ($self) = @_;

   my $json = $self->req->json;

   return eval {
#      my $new_t = Rex::IO::Server::Model::OsTemplate->new(%{ $json });
      my $new_t = $self->db->resultset("OsTemplate")->create($json);
      $new_t->update;

      return $self->render_json({ok => Mojo::JSON->true});
   } or do {
      return $self->render_json({ok => Mojo::JSON->false}, status => 500);
   };
}

sub list {
   my ($self) = @_;

   my @os_r = $self->db->resultset("OsTemplate")->all;

   my @ret = ();

   for my $os (@os_r) {
      push(@ret, { $os->get_columns });
   }

   $self->render_json(\@ret);
}

sub search {
   my ($self) = @_;

   #my $os_r = Rex::IO::Server::Model::OsTemplate->all( Rex::IO::Server::Model::OsTemplate->name % ($self->param("name") . '%'));
   my @os_r = $self->db->resultset("OsTemplate")->search({ name => { like => $self->param("name") . '%' } });

   my @ret = ();

   for my $os (@os_r) {
      push(@ret, { $os->get_columns });
   }

   $self->render_json(\@ret);
}

sub get {
   my ($self) = @_;

   #my $os = Rex::IO::Server::Model::OsTemplate->all( Rex::IO::Server::Model::OsTemplate->id == $self->param("id"))->next;
   my $os = $self->db->resultset("OsTemplate")->find($self->param("id"));
   $self->render_json({ $os->get_columns });
}

sub update {
   my ($self) = @_;

   #my $os_r = Rex::IO::Server::Model::OsTemplate->all( Rex::IO::Server::Model::OsTemplate->id == $self->param("id") );
   my $os_r = $self->db->resultset("OsTemplate")->find($self->param("id"));

   if(my $os = $os_r) {
      eval {
         my $json = $self->req->json;

         for my $k (keys %{ $json }) {
            $os->$k($json->{$k});
         }

         $os->update;

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
