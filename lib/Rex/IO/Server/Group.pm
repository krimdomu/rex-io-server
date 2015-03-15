#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Group;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON "j";

sub get {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('LIST_GROUP') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission LIST_GROUP.'
      },
      status => 403
    );
  }

  my $group = $self->db->resultset("Group")->find( $self->param("id") );

  if ($group) {
    my $data = {
      id   => $group->id,
      name => $group->name,
    };

    return $self->render( json => { ok => Mojo::JSON->true, data => $data } );
  }

  return $self->render( json => { ok => Mojo::JSON->false }, status => 404 );
}

sub list {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('LIST_GROUP') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission LIST_GROUP.'
      },
      status => 403
    );
  }

  my @groups = $self->db->resultset("Group")->all;
  my @ret;

  for my $group (@groups) {
    push @ret, { $group->get_columns };
  }

  $self->render( json => { ok => Mojo::JSON->true, data => \@ret } );
}

sub add {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('CREATE_GROUP') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission CREATE_GROUP.'
      },
      status => 403
    );
  }

  eval {
    my $group = $self->db->resultset("Group")->create( $self->req->json );
    if ($group) {
      return $self->render(
        json => { ok => Mojo::JSON->true, id => $group->id } );
    }
  } or do {
    return $self->render( json => { ok => Mojo::JSON->false, error => $@ }, status => 500 );
  };
}

sub delete {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('DELETE_GROUP') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission DELETE_GROUP.'
      },
      status => 403
    );
  }

  my $group_id = $self->param("group_id");

  $self->app->log->debug("Deleting group: $group_id");

  my $group = $self->db->resultset("Group")->find($group_id);

  if ($group) {
    $group->delete;
    return $self->render( json => { ok => Mojo::JSON->true } );
  }

  return $self->render( json => { ok => Mojo::JSON->false }, status => 404 );
}

sub add_user_to_group {
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

  my $user_id  = $self->param("user_id");
  my $group_id = $self->param("group_id");

  my $user  = $self->db->resultset("User")->find($user_id);
  my $group = $self->db->resultset("Group")->find($group_id);

  if ( !$user ) {
    return $self->render(
      json   => { ok => Mojo::JSON->false, error => "User not found" },
      status => 404
    );
  }

  if ( !$group ) {
    return $self->render(
      json   => { ok => Mojo::JSON->false, error => "Group not found" },
      status => 404
    );
  }

  $user->update(
    {
      group_id => $group_id,
    }
  );

  return $self->render( json => { ok => Mojo::JSON->true } );
}

sub __register__ {
  my ( $self, $app ) = @_;
  my $r = $app->routes;

  $app->register_url(
    {
      plugin => "group",
      meth   => "GET",
      auth   => Mojo::JSON->true,
      url    => "/group",
      func   => \&Rex::IO::Server::Group::list,
    }
  );

  $app->register_url(
    {
      plugin => "group",
      meth   => "GET",
      auth   => Mojo::JSON->true,
      url    => "/group/:id",
      func   => \&Rex::IO::Server::Group::get,
    }
  );

  $app->register_url(
    {
      plugin => "group",
      meth   => "POST",
      auth   => Mojo::JSON->true,
      url    => "/group",
      func   => \&Rex::IO::Server::Group::add,
    }
  );

  $app->register_url(
    {
      plugin => "group",
      meth   => "POST",
      auth   => Mojo::JSON->true,
      url    => "/group/:group_id/user/:user_id",
      func   => \&Rex::IO::Server::Group::add_user_to_group,
    }
  );

  $app->register_url(
    {
      plugin => "group",
      meth   => "DELETE",
      auth   => Mojo::JSON->true,
      url    => "/group/:group_id",
      func   => \&Rex::IO::Server::Group::delete,
    }
  );
}

1;
