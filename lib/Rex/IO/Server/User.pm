#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::User;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use Data::Dumper;
use Digest::Bcrypt;

sub get {
   my ($self) = @_;

   my $user = $self->db->resultset("User")->find($self->param("id"));

   if($user) {
      my $data = {
         id   => $user->id,
         name => $user->name,
      };

      return $self->render(json => {ok => Mojo::JSON->true, data => $data});
   }

   return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
}

sub list {
   my ($self) = @_;

   my @users = $self->db->resultset("User")->all;
   my @ret;

   for my $user (@users) {
      my $data = { $user->get_columns };
      $data->{group} = { $user->group->get_columns };

      push @ret, $data;
   }

   $self->render(json => {ok => Mojo::JSON->true, data => \@ret});
}

sub add {
   my ($self) = @_;

   my $json = $self->req->json;

   eval {
      my $salt = $self->config->{auth}->{salt};
      my $cost = $self->config->{auth}->{cost};

      my $bcrypt = Digest::Bcrypt->new;
      $bcrypt->salt($salt);
      $bcrypt->cost($cost);
      $bcrypt->add($json->{password});

      my $pw = $bcrypt->hexdigest;

      my $data = {
         name     => $json->{name},
         password => $pw,
      };

      my $user = $self->db->resultset("User")->create($data);
      if($user) {
         return $self->render(json => {ok => Mojo::JSON->true, id => $user->id});
      }
   } or do {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 500);
   };
}

sub delete {
   my ($self) = @_;

   my $user_id = $self->param("user_id");
   my $user = $self->db->resultset("User")->find($user_id);
   
   if($user) {
      $user->delete;
      return $self->render(json => {ok => Mojo::JSON->true});
   }

   return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
}


1;
