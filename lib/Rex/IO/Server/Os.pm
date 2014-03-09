#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
  
package Rex::IO::Server::Os;
  
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON "j";

use Data::Dumper;


sub list {
  my ($self) = @_;

  #my $os_r = Rex::IO::Server::Model::Os->all;
  my @os_r = $self->db->resultset("Os")->all;

  my @ret = ();

  for my $os (@os_r) {
    push(@ret, { $os->get_columns });
  }

  $self->render(json => \@ret);
}

sub search {
  my ($self) = @_;

  #my $os_r = Rex::IO::Server::Model::Os->all( Rex::IO::Server::Model::Os->name % ($self->param("name") . '%'));
  my @os_r = $self->db->resultset("Os")->search({ name => { like => $self->param("name") . '%' } });

  my @ret = ();

  for my $os (@os_r) {
    push(@ret, { $os->get_columns });
  }

  $self->render(json => \@ret);
}

sub get {
  my ($self) = @_;

  #my $os = Rex::IO::Server::Model::Os->all( Rex::IO::Server::Model::Os->id == $self->param("id"))->next;
  my $os = $self->db->resultset("Os")->find($self->param("id"));
  $self->render(json => { $os->get_columns });
}

sub update {
  my ($self) = @_;

  #my $os_r = Rex::IO::Server::Model::Os->all( Rex::IO::Server::Model::Os->id == $self->param("id") );
  my $os_r = $self->db->resultset("Os")->find($self->param("id"));

  if(my $os = $os_r) {
    eval {
      my $json = $self->req->json;

      for my $k (keys %{ $json }) {
        $os->$k($json->{$k});
      }

      $os->update;

      return $self->render(json => {ok => Mojo::JSON->true});
    } or do {
      return $self->render(json => {ok => Mojo::JSON->false, error => $@}, status => 500);
    };
  }
  else {
    return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
  }
}


1;
