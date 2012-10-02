#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Dhcp;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::UserAgent;
use Data::Dumper;

sub new_lease {
   my ($self) = @_;

   my $json = $self->req->json;

   my $res = $self->_ua->post_json($self->config->{dhcp}->{server} . "/" . $self->stash("mac"), $json)->res;

   warn Dumper($res);

   $self->render_json({ok => Mojo::JSON->true});
}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->post("/dhcp/host/:mac")->to("dhcp#new_lease");
}

sub _ua {
   my ($self) = @_;
   return Mojo::UserAgent->new;
}

1;
