#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Os;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON "j";

use Data::Dumper;

sub list {
  my ($self) = @_;

  my $action = $self->param("action");

  my @os_r = $self->db->resultset("Os")->all;

  if ( $action && $action eq "count" ) {
    return $self->render(
      json => { ok => Mojo::JSON->true, count => scalar @os_r } );
  }

  #my $os_r = Rex::IO::Server::Model::Os->all;

  my @ret = ();

  for my $os (@os_r) {
    push( @ret, { $os->get_columns } );
  }

  $self->render( json => { ok => Mojo::JSON->true, data => \@ret } );
}

# sub search {
#   my ($self) = @_;
#
#   #my $os_r = Rex::IO::Server::Model::Os->all( Rex::IO::Server::Model::Os->name % ($self->param("name") . '%'));
#   my @os_r = $self->db->resultset("Os")->search({ name => { like => $self->param("name") . '%' } });
#
#   my @ret = ();
#
#   for my $os (@os_r) {
#     push(@ret, { $os->get_columns });
#   }
#
#   $self->render(json => \@ret);
# }

sub get {
  my ($self) = @_;

  $self->app->log->debug( "Getting OS: " . $self->param("id") );

#my $os = Rex::IO::Server::Model::Os->all( Rex::IO::Server::Model::Os->id == $self->param("id"))->next;
  my $os = $self->db->resultset("Os")->find( $self->param("id") );
  $self->render(
    json => { ok => Mojo::JSON->true, data => { $os->get_columns } } );
}

sub add {
  my ($self) = @_;

  $self->app->log->debug("Creating new OS entry:");
  $self->app->log->debug( Dumper( $self->req->json ) );

  eval {
    my $os = $self->db->resultset("Os")->create( $self->req->json );
    $self->render(
      json => { ok => Mojo::JSON->true, data => { $os->get_columns } } );
  } or do {
    return $self->render(
      json   => { ok => Mojo::JSON->false, error => $@ },
      status => 500
    );
  };
}

sub update {
  my ($self) = @_;

  my $os_r = $self->db->resultset("Os")->find( $self->param("id") );

  $self->app->log->debug( "Updating OS entry: " . $self->param("id") );
  $self->app->log->debug( Dumper( $self->req->json ) );

  if ( my $os = $os_r ) {
    eval {
      my $json = $self->req->json;
      $os->update($json);

      return $self->render( json => { ok => Mojo::JSON->true } );
    } or do {
      return $self->render(
        json   => { ok => Mojo::JSON->false, error => $@ },
        status => 500
      );
    };
  }
  else {
    return $self->render( json => { ok => Mojo::JSON->false }, status => 404 );
  }
}

sub delete {
  my ($self) = @_;

  $self->app->log->debug( "Deleting OS entry: " . $self->param("id") );

  my $os_r = $self->db->resultset("Os")->find( $self->param("id") );
  if ( my $os = $os_r ) {

    # first we need to check if there are hardware registered to this OS
    my @hw = $os->hardwares;
    if ( scalar @hw != 0 ) {
      $self->app->log->debug(
        'There is hardware registered to this Os. Please remove them first.');
      return $self->render(
        json => {
          ok => Mojo::JSON->false,
          error =>
            'There is hardware registered to this Os. Please remove them first.'
        },
        status => 500
      );
    }

    eval {
      $os_r->delete;
      return $self->render( json => { ok => Mojo::JSON->true } );
    } or do {
      return $self->render(
        json   => { ok => Mojo::JSON->false, error => $@ },
        status => 500
      );
    };
  }
  else {
    return $self->render( json => { ok => Mojo::JSON->false }, status => 404 );
  }
}

sub __register__ {
  my ( $self, $app ) = @_;
  my $r = $app->routes;

  $r->get("/1.0/os/os")->over( authenticated => 1 )->to("os#list");

  $r->get("/1.0/os/os/:id")->over( authenticated => 1 )->to("os#get");

  $r->post("/1.0/os/os")->over( authenticated => 1 )->to("os#add");

  $r->post("/1.0/os/os/:id")->over( authenticated => 1 )->to("os#update");

  $r->delete("/1.0/os/os/:id")->over( authenticated => 1 )->to("os#delete");
}

1;
