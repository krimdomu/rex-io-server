#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::IO::Server::Dhcp;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON;
use Mojo::UserAgent;
use Data::Dumper;

sub new_lease {
   my ($self) = @_;

   my $json = $self->req->json;

   my $mac = $self->param("mac");
   unless($mac =~ m/^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$/i) {
      return $self->render_json({ok => Mojo::JSON->false, error => "No MAC given."}, status => 500);
   }

   $mac =~ s/\-/:/g;

   my $res = $self->_ua->post_json($self->config->{dhcp}->{server} . "/" . "\L$mac", $json)->res;

   $self->render_json({ok => Mojo::JSON->true});
}

sub __register__ {
   my ($self, $app) = @_;
   my $r = $app->routes;

   $r->post("/dhcp/#mac")->to("dhcp#new_lease");
}

sub _ua {
   my ($self) = @_;
   return Mojo::UserAgent->new;
}

1;
