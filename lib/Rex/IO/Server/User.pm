#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::User;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

sub get {
   my ($self) = @_;

   my $user = $self->db->resultset("User")->find($self->param("id"));

   if($user) {
      my $data = {
         id   => $user->id,
         name => $user->name,
      };

      return $self->render_json({ok => Mojo::JSON->true, data => $data});
   }

   return $self->render_json({ok => Mojo::JSON->false}, status => 404);
}

1;
