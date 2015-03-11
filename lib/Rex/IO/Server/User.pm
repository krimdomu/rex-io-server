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
use Try::Tiny;

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
    $data->{group}          = { $user->group->get_columns };
    $data->{permission_set} = { $user->permission_set->get_columns };

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
      name              => $json->{name},
      password          => $pw,
      group_id          => $json->{group_id} || 2,
      permission_set_id => $json->{permission_set_id} || 2,
    };

    my $user = $self->db->resultset("User")->create($data);
    if ($user) {
      return $self->render(
        json => { ok => Mojo::JSON->true, id => $user->id } );
    }
  } or do {
    return $self->render(
      json   => { ok => Mojo::JSON->false, error => $@ },
      status => 500
    );
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
    $self->app->log->debug( Dumper \@perms );

    return $self->render(
      json => {
        ok   => Mojo::JSON->true,
        data => {
          id          => $user->id,
          name        => $user->name,
          permissions => [@perms]
        }
      }
    );

  }

  return $self->render(
    json   => { ok => Mojo::JSON->false, error => 'No valid user' },
    status => 401
  );
}

sub update {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('MODIFY_USER') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission MODIFY_USER.'
      },
      status => 403
    );
  }

  try {

    my $user_id = $self->param("user_id");
    my $user    = $self->db->resultset("User")->find($user_id);

    if ($user) {
      $self->app->log->debug("Updating user: $user_id");

      my $json = $self->req->json;
      $self->app->log->debug( Dumper($json) );

      my $salt = $self->config->{auth}->{salt};
      my $cost = $self->config->{auth}->{cost};

      my $bcrypt = Digest::Bcrypt->new;
      $bcrypt->salt($salt);
      $bcrypt->cost($cost);
      $bcrypt->add( $json->{password} );

      my $pw = $bcrypt->hexdigest;

      $user->update(
        {
          name => $json->{user} || $user->name,
          password => ( $json->{password} ? $pw : $user->password ),
          group_id => $json->{group_id} || $user->group_id,
          permission_set_id => $json->{permission_set_id}
            || $user->permission_set_id,
        }
      );

      $self->app->log->debug("User $user_id updated.");

      return $self->render( json => { ok => Mojo::JSON->true } );
    }
    else {
      $self->app->log->error("User $user_id not found.");
      return $self->render(
        json   => { ok => Mojo::JSON->false },
        status => 404
      );
    }
  }
  catch {
    $self->app->log->error("Error: @_");
    return $self->render(
      json   => { ok => Mojo::JSON->false, error => "@_" },
      status => 500
    );
  };

}

sub __register__ {
  my ( $self, $app ) = @_;
  my $r = $app->routes;

  $app->register_url(
    {
      plugin => "user",
      meth   => "GET",
      auth   => Mojo::JSON->true,
      url    => "/user",
      func   => \&Rex::IO::Server::User::list,
    }
  );

  $app->register_url(
    {
      plugin => "user",
      meth   => "GET",
      auth   => Mojo::JSON->true,
      url    => "/user/:id",
      func   => \&Rex::IO::Server::User::get,
    }
  );

  $app->register_url(
    {
      plugin => "user",
      meth   => "POST",
      auth   => Mojo::JSON->true,
      url    => "/user",
      func   => \&Rex::IO::Server::User::add,
    }
  );

  $app->register_url(
    {
      plugin => "user",
      meth   => "POST",
      auth   => Mojo::JSON->true,
      url    => "/user/:user_id",
      func   => \&Rex::IO::Server::User::update,
    }
  );

  $app->register_url(
    {
      plugin => "user",
      meth   => "POST",
      auth   => Mojo::JSON->false,
      url    => "/login",
      func   => \&Rex::IO::Server::User::login,
    }
  );

  $app->register_url(
    {
      plugin => "user",
      meth   => "DELETE",
      auth   => Mojo::JSON->true,
      url    => "/user/:user_id",
      func   => \&Rex::IO::Server::User::delete,
    }
  );
}

1;
