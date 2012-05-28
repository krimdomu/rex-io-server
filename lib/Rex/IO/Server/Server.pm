#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Server;
   
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;

use Data::Dumper;



sub get {
   my ($self) = @_;
   my $server = $self->stash("name");

   my $data = $self->cmdb->get_server($server);

   if(! ref($data) ) {
      $self->render_json({ok => Mojo::JSON->false}, status => $data);
   }

   my $ret = {
      ok => Mojo::JSON->true,
      data => $data,
   };
   $self->render_json($ret);
}

1;
