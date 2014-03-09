#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
  
package Rex::IO::Server::Tree;
  
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON "j";

use Data::Dumper;


sub root {
  my ($self) = @_;

  $self->render(json => {ok => Mojo::JSON->false}, status => 404);
}


1;
