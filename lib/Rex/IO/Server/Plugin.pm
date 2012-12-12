#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Plugin;
   
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

use Data::Dumper;

sub list {
   my ($self) = @_;

   $self->render_json($self->config->{"plugins"});
}

1;
