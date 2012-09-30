#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Tree;
   
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

use Data::Dumper;


sub root {
   my ($self) = @_;

   my $tree_r = Rex::IO::Server::Model::Tree->all( Rex::IO::Server::Model::Tree->id == 1 );

   if(my $root = $tree_r->next) {
      return $self->render_json($root->get_data);
   }

   $self->render_json({ok => Mojo::JSON->false}, status => 404);
}


1;
