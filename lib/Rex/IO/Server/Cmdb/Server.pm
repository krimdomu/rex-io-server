#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
  
package Rex::IO::Server::Cmdb::Server;
  
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON "j";

use Data::Dumper;

sub post {
  my ($self) = @_;
  my $ref = $self->req->json;

  my $new_res = $self->cmdb->add_server($ref);

  $self->render(json => $new_res, status => 201);
}

sub delete {
  my ($self) = @_;

  my $data = $self->cmdb->delete_server($self->stash("name"));

  if($data->{ok} == Mojo::JSON->false) {
    $self->render(json => $data, status => 404);
  }
  else {
    $self->render(json => $data);
  }
}

sub get {
  my ($self) = @_;
  my $server = $self->stash("name");

  my $data = $self->chi->get($server);

  if(!$data) {
    $data = $self->cmdb->get_server($server);
    $self->chi->set($server, $data);
  }

  if(! ref($data) ) {
    $self->render(json => {ok => Mojo::JSON->false}, status => $data);
  }

  my $ret = {
    ok => Mojo::JSON->true,
    data => $data,
  };
  $self->render(json => $ret);
}

sub list {
  my ($self) = @_;

  my $data = $self->chi->get("server_list");

  if(!$data) {
    $data = $self->cmdb->get_server_list();
    $self->chi->set("server_list", $data);
  }

  if(! ref($data) ) {
    $self->render(json => {ok => Mojo::JSON->false}, status => $data);
  }

  my $ret = {
    ok => Mojo::JSON->true,
    data => $data,
  };
  $self->render(json => $ret);
}

sub link {
  my  $self = shift;
  
  my $data = $self->cmdb->add_service_to_server($self->stash("name"), $self->req->json);

  if(! ref($data) ) {
    $self->render(json => {ok => Mojo::JSON->false}, status => $data);
  }

  my $ret = {
    ok => Mojo::JSON->true,
    data => $data,
  };
  $self->render(json => $ret);
}

sub unlink {
  my  $self = shift;
  
  my $data = $self->cmdb->remove_service_from_server($self->stash("name"), $self->req->json);

  if(! ref($data) ) {
    $self->render(json => {ok => Mojo::JSON->false}, status => $data);
  }

  my $ret = {
    ok => Mojo::JSON->true,
    data => $data,
  };
  $self->render(json => $ret);
}

sub service_put {
  my $self = shift;

  my $data = $self->cmdb->configure_service_of_server($self->stash("name"), $self->stash("service"), $self->req->json);

  if(! ref($data) ) {
    $self->render(json => {ok => Mojo::JSON->false}, status => $data);
  }

  my $ret = {
    ok => Mojo::JSON->true,
    data => $data,
  };
  $self->render(json => $ret);
}

sub section_put {
  my $self = shift;

  my $data = $self->cmdb->add_section_to_server($self->stash("name"), $self->stash("section"), $self->req->json);

  if(! ref($data) ) {
    $self->render(json => {ok => Mojo::JSON->false}, status => $data);
  }

  my $ret = {
    ok => Mojo::JSON->true,
    data => $data,
  };
  $self->render(json => $ret);
}


1;
