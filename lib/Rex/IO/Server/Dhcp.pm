#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
  
package Rex::IO::Server::Dhcp;
use Mojo::Base 'Mojolicious::Controller';

use Mojo::JSON "j";
use Mojo::UserAgent;
use Data::Dumper;

sub new_lease {
  my ($self) = @_;

  my $json = $self->req->json;

  my $mac = $self->param("mac");
  unless($mac =~ m/^([0-9A-F]{2}[:-]){5}([0-9A-F]{2})$/i) {
    return $self->render(json => {ok => Mojo::JSON->false, error => "No MAC given."}, status => 500);
  }

  $mac =~ s/\-/:/g;

  my $res = $self->_ua->post_json($self->config->{dhcp}->{server} . "/" . "\L$mac", $json)->res;

  $self->render(json => {ok => Mojo::JSON->true});
}

sub list_leases {
  my ($self) = @_;

  my $res = $self->_list("/")->res->json;

  if(! $res->{leases}) {
    return $self->render(json => {});
  }

  $self->render(json => $res->{leases});
}

sub __register__ {
  my ($self, $app) = @_;
  my $r = $app->routes;

  $r->post("/dhcp/#mac")->over(authenticated => 1)->to("dhcp#new_lease");
  $r->route("/dhcp")->via("LIST")->over(authenticated => 1)->to("dhcp#list_leases");
}

sub _ua {
  my ($self) = @_;
  return Mojo::UserAgent->new;
}

sub _list {
  my ($self, $url) = @_;
  my $tx = $self->_ua->build_tx(LIST => $self->config->{dhcp}->{server} . $url);
  $self->_ua->start($tx);
}

1;
