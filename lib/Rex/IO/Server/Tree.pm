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

   $self->render_json({ok => Mojo::JSON->false}, status => 404);
}


1;
