#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:
  
package Rex::IO::Server::Deploy::Os;
use Mojo::Base 'Mojolicious::Controller';

# POST /deploy/os/:name
# {
#   "kernel": "/path/to/pxekernel",
#   "initrd": "/path/to/initrd",
#   "append": "ramdisk_size=20000 apm=power-off ...",
#   "template": "..."
# }
sub register {
  my ($self) = @_;
  my $name = $self->stash("name");

  my $json = $self->req->json;
  $json->{name} = $name;

  eval {
    #my $ot = Rex::IO::Server::Model::OsTemplate->new(%{ $json });
    my $ot = $self->db->resultset("OsTemplate")->create($json);
    $ot->update;

    return $self->render(json => {ok => Mojo::JSON->true});
  } or do {
    return $self->render(json => {ok => Mojo::JSON->false}, status => 500);
  };
}

sub update {
  my ($self) = @_;

  my $id = $self->stash("id");

  my $json = $self->req->json;

  eval {
    #my $ot = Rex::IO::Server::Model::OsTemplate->all( Rex::IO::Server::Model::OsTemplate->id == $id )->next;
    my $ot = $self->db->resultset("OsTemplate")->find($id);
    for my $d (keys %{ $json }) {
      $ot->$d($json->{$d});
    }

    $ot->update;

    return $self->render(json => {ok => Mojo::JSON->true});
  } or do {
    return $self->render(json => {ok => Mojo::JSON->false}, status => 500);
  };

}

sub delete {
  my ($self) = @_;

  eval {
    #my $ot = Rex::IO::Server::Model::OsTemplate->all( Rex::IO::Server::Model::OsTemplate->name eq $self->stash("name") );
    my $ot = $self->db->resultset("OsTemplate")->search({ name => $self->stash("name") });
    if(my $t = $ot->first) {
      $t->delete;
      return $self->render(json => {ok => Mojo::JSON->true});
    }
    else {
      return $self->render(json => {ok => Mojo::JSON->false}, status => 404);
    }

  } or do {
    return $self->render(json => {ok => Mojo::JSON->false, error => $@}, status => 500);
  };
}


sub list {
  my ($self) = @_;

  #my $ot = Rex::IO::Server::Model::OsTemplate->all;
  my @ot = $self->db->resultset("OsTemplate")->all;

  my @ret = ();
  for my $t (@ot) {
    push(@ret, { $t->get_columns });
  }

  $self->render(json => \@ret);
}

1;
