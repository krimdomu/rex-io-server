#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Group;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON "j";

sub get {
   my ($self) = @_;

   my $group = $self->db->resultset("Group")->find($self->param("id"));

   if($group) {
      my $data = {
         id   => $group->id,
         name => $group->name,
      };

      return $self->render(json => {ok => Mojo::JSON->true, data => $data});
   }

   return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
}

sub list {
   my ($self) = @_;

   my @groups = $self->db->resultset("Group")->all;
   my @ret;

   for my $group (@groups) {
      push @ret, { $group->get_columns };
   }

   $self->render(json => {ok => Mojo::JSON->true, data => \@ret});
}

sub add {
   my ($self) = @_;

   eval {
      my $group = $self->db->resultset("Group")->create($self->req->json);
      if($group) {
         return $self->render(json => {ok => Mojo::JSON->true, id => $group->id});
      }
   } or do {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 500);
   };
}

sub delete {
   my ($self) = @_;

   my $group_id = $self->param("group_id");
   my $group = $self->db->resultset("Group")->find($group_id);
   
   if($group) {
      $group->delete;
      return $self->render(json => {ok => Mojo::JSON->true});
   }

   return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
}

sub add_user_to_group {
   my ($self) = @_;

   my $user_id = $self->param("user_id");
   my $group_id = $self->param("group_id");

   my $user = $self->db->resultset("User")->find($user_id);
   my $group = $self->db->resultset("Group")->find($group_id);

   if(! $user) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "User not found"}, status => 404);
   }

   if(! $group) {
      return $self->render(json => {ok => Mojo::JSON->false, error => "Group not found"}, status => 404);
   }

   $user->update({
      group_id => $group_id,
   });

   return $self->render(json => {ok => Mojo::JSON->true});
}

1;
