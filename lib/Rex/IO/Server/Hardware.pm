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


1;
