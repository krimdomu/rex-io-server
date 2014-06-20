#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::User;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON "j";
use Data::Dumper;
use Digest::Bcrypt;

sub get {
  my ($self) = @_;

  my $user = $self->db->resultset("User")->find( $self->param("id") );

  if (!$self->current_user->has_perm('LIST_USER')
    && $user->id != $self->current_user->id )
  {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission LIST_USER.'
      },
      status => 403
    );
  }

  if ($user) {
    my $data = {
      id   => $user->id,
      name => $user->name,
    };

    return $self->render( json => { ok => Mojo::JSON->true, data => $data } );
  }

  return $self->render( json => { ok => Mojo::JSON->false }, status => 404 );
}

sub list {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('LIST_USER') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission LIST_USER.'
      },
      status => 403
    );
  }

  my @users = $self->db->resultset("User")->all;
  my @ret;

  for my $user (@users) {
    my $data = { $user->get_columns };
    $data->{group} = { $user->group->get_columns };

    push @ret, $data;
  }

  $self->render( json => { ok => Mojo::JSON->true, data => \@ret } );
}

sub add {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('CREATE_USER') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission CREATE_USER.'
      },
      status => 403
    );
  }

  my $json = $self->req->json;

  eval {
    my $salt = $self->config->{auth}->{salt};
    my $cost = $self->config->{auth}->{cost};

    my $bcrypt = Digest::Bcrypt->new;
    $bcrypt->salt($salt);
    $bcrypt->cost($cost);
    $bcrypt->add( $json->{password} );

    my $pw = $bcrypt->hexdigest;

    my $data = {
      name     => $json->{name},
      password => $pw,
    };

    my $user = $self->db->resultset("User")->create($data);
    if ($user) {
      return $self->render(
        json => { ok => Mojo::JSON->true, id => $user->id } );
    }
  } or do {
    return $self->render( json => { ok => Mojo::JSON->false, error => $@ }, status => 500 );
  };
}

sub delete {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('DELETE_USER') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission DELETE_USER.'
      },
      status => 403
    );
  }

  my $user_id = $self->param("user_id");
  my $user    = $self->db->resultset("User")->find($user_id);

  if ($user) {
    $user->delete;
    return $self->render( json => { ok => Mojo::JSON->true } );
  }

  return $self->render( json => { ok => Mojo::JSON->false }, status => 404 );
}

sub login {
  my ($self) = @_;
  $self->app->log->debug( "Authentication of: " . $self->req->json->{user} );
  my $user = $self->get_user( 'by_name', $self->req->json->{user} );
  if ( $user && $user->check_password( $self->req->json->{password} ) ) {
    my @perms = $user->get_permissions;

    $self->app->log->debug("Permissions for user: ");
    $self->app->log->debug(Dumper \@perms);

    return $self->render(
      json => {
        ok   => Mojo::JSON->true,
        data => {
          id          => $user->id,
          name        => $user->name,
          permissions => [ @perms ]
        }
      }
    );

  }

  return $self->render(
    json   => { ok => Mojo::JSON->false, error => 'No valid user' },
    status => 401
  );
}

sub __register__ {
  my ( $self, $app ) = @_;
  my $r = $app->routes;

  $r->get("/1.0/user/user")->over( authenticated => 1 )->to("user#list");
  $r->get("/1.0/user/user/:id")->over( authenticated => 1 )->to("user#get");

  $r->post("/1.0/user/user")->over( authenticated => 1 )->to("user#add");
  $r->post("/1.0/user/login")->to("user#login");

  $r->delete("/1.0/user/user/:user_id")->over( authenticated => 1 )
    ->to("user#delete");
}

1;
