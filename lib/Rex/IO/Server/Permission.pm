#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Permission;

use Mojo::Base 'Rex::IO::Server::PluginController';
use Mojo::JSON "j";
use Data::Dumper;
use Digest::Bcrypt;
use Try::Tiny;

sub list_set {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('LIST_PERM_SET') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission LIST_PERM_SET.'
      },
      status => 403
    );
  }

  my @all_sets = $self->db->resultset('PermissionSet')->all;

  my @ret;

  for my $set (@all_sets) {
    push @ret, $set->to_hashRef;
  }

  $self->render( json => { ok => Mojo::JSON->true, data => \@ret } );
}

sub list_perm {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('LIST_PERM') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission LIST_PERM.'
      },
      status => 403
    );
  }

  my @all_sets = $self->db->resultset('Permission')->all;

  my @ret;

  for my $set (@all_sets) {
    push @ret, { $set->get_columns };
  }

  $self->render( json => { ok => Mojo::JSON->true, data => \@ret } );
}

sub get_set {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('LIST_PERM_SET') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission LIST_PERM_SET.'
      },
      status => 403
    );
  }

  my $set =
    $self->db->resultset('PermissionSet')->find( $self->param("set_id") );

  if ( !$set ) {
    return $self->render( json => { ok => Mojo::JSON->false }, status => 404 );
  }

  $self->render( json => { ok => Mojo::JSON->true, data => $set->to_hashRef } );
}

sub get_perm {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('LIST_PERM') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission LIST_PERM.'
      },
      status => 403
    );
  }

  my $perm =
    $self->db->resultset('Permission')->find( $self->param("perm_id") );

  if ( !$perm ) {
    return $self->render( json => { ok => Mojo::JSON->false }, status => 404 );
  }

  $self->render(
    json => { ok => Mojo::JSON->true, data => { $perm->get_columns } } );
}

sub add_set {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('CREATE_PERM_SET') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission CREATE_PERM_SET.'
      },
      status => 403
    );
  }

  eval {
    my $ref = $self->req->json;

    my $set = $self->db->resultset('PermissionSet')->create(
      {
        name        => $ref->{name},
        description => $ref->{description} || '',
      }
    );

    if ( exists $ref->{permissions} && ref $ref->{permissions} eq "HASH" ) {
      $self->app->log->debug("Creating permissions:");
      $self->app->log->debug( Dumper( $ref->{permissions} ) );

      my $users = $ref->{permissions}->{user};
      for my $user_id ( keys %{$users} ) {
        for my $perm_id ( @{ $users->{$user_id} } ) {
          $self->db->resultset('Permission')->create(
            {
              permission_set_id => $set->id,
              user_id           => $user_id,
              perm_id           => $perm_id,
            }
          );
        }
      }

      my $groups = $ref->{permissions}->{group};
      for my $group_id ( keys %{$groups} ) {
        for my $perm_id ( @{ $groups->{$group_id} } ) {
          $self->db->resultset('Permission')->create(
            {
              permission_set_id => $set->id,
              group_id          => $group_id,
              perm_id           => $perm_id,
            }
          );
        }
      }
    }

    $self->render(
      json => { ok => Mojo::JSON->true, data => { $set->get_columns } } );
  } or do {
    return $self->render(
      json   => { ok => Mojo::JSON->false, error => $@ },
      status => 500
    );
  };

}

sub add_perm {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('CREATE_PERM') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission CREATE_PERM.'
      },
      status => 403
    );
  }

  eval {
    my $perm = $self->db->resultset('Permission')->create( $self->req->json );

    $self->render(
      json => { ok => Mojo::JSON->true, data => { $perm->get_columns } } );
  } or do {
    return $self->render(
      json   => { ok => Mojo::JSON->false, error => $@ },
      status => 500
    );
  };

}

sub update_set {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('MODIFY_PERM_SET') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission MODIFY_PERM_SET.'
      },
      status => 403
    );
  }

  my $set =
    $self->db->resultset('PermissionSet')->find( $self->param("set_id") );
  if ( !$set ) {
    return $self->render( json => { ok => Mojo::JSON->false }, status => 404 );
  }

  eval {
    my $ref = $self->req->json;
    $self->app->log->debug( Dumper($ref) );

    $set->update(
      {
        name        => $ref->{name}        || $set->name,
        description => $ref->{description} || $set->description,
      }
    );

    if ( exists $ref->{permissions} && ref $ref->{permissions} eq "HASH" ) {
      $self->app->log->debug("Removing all previous permissions:");
      $set->permissions->delete;

      $self->app->log->debug("Creating permissions:");
      $self->app->log->debug( Dumper( $ref->{permissions} ) );

      my $users = $ref->{permissions}->{user};
      for my $user_id ( keys %{$users} ) {
        for my $perm_id ( @{ $users->{$user_id} } ) {
          $self->db->resultset('Permission')->create(
            {
              permission_set_id => $set->id,
              user_id           => $user_id,
              perm_id           => $perm_id,
            }
          );
        }
      }

      my $groups = $ref->{permissions}->{group};
      for my $group_id ( keys %{$groups} ) {
        for my $perm_id ( @{ $groups->{$group_id} } ) {
          $self->db->resultset('Permission')->create(
            {
              permission_set_id => $set->id,
              group_id          => $group_id,
              perm_id           => $perm_id,
            }
          );
        }
      }
    }

    $self->render( json => { ok => Mojo::JSON->true } );
  } or do {
    return $self->render(
      json   => { ok => Mojo::JSON->false, error => $@ },
      status => 500
    );
  };

}

sub update_perm {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('MODIFY_PERM') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission MODIFY_PERM.'
      },
      status => 403
    );
  }

  my $perm =
    $self->db->resultset('Permission')->find( $self->param("perm_id") );
  if ( !$perm ) {
    return $self->render( json => { ok => Mojo::JSON->false }, status => 404 );
  }

  eval {
    $perm->update( $self->req->json );
    $self->render( json => { ok => Mojo::JSON->true } );
  } or do {
    return $self->render(
      json   => { ok => Mojo::JSON->false, error => $@ },
      status => 500
    );
  };

}

sub delete_set {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('DELETE_PERM_SET') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission DELETE_PERM_SET.'
      },
      status => 403
    );
  }

  my $set =
    $self->db->resultset('PermissionSet')->find( $self->param("set_id") );
  if ( !$set ) {
    return $self->render( json => { ok => Mojo::JSON->false }, status => 404 );
  }

  eval {
    $set->delete;
    $self->render( json => { ok => Mojo::JSON->true } );
  } or do {
    return $self->render(
      json   => { ok => Mojo::JSON->false, error => $@ },
      status => 500
    );
  };

}

sub delete_perm {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('DELETE_PERM') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission DELETE_PERM.'
      },
      status => 403
    );
  }

  my $perm =
    $self->db->resultset('Permission')->find( $self->param("perm_id") );
  if ( !$perm ) {
    return $self->render( json => { ok => Mojo::JSON->false }, status => 404 );
  }

  eval {
    $perm->delete;
    $self->render( json => { ok => Mojo::JSON->true } );
  } or do {
    return $self->render(
      json   => { ok => Mojo::JSON->false, error => $@ },
      status => 500
    );
  };

}

sub list_permission_types {
  my ($self) = @_;

  try {
    my @all_types = $self->db->resultset('PermissionType')->all;
    my @ret;

    for my $t (@all_types) {
      push @ret, { $t->get_columns };
    }

    return $self->render( json => { ok => Mojo::JSON->true, data => \@ret } );
  }
  catch {
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
      plugin => "permission",
      meth   => "GET",
      auth   => Mojo::JSON->true,
      url    => "/set",
      func   => \&Rex::IO::Server::Permission::list_set,
    }
  );

  $app->register_url(
    {
      plugin => "permission",
      meth   => "GET",
      auth   => Mojo::JSON->true,
      url    => "/permission",
      func   => \&Rex::IO::Server::Permission::list_perm,
    }
  );

  $app->register_url(
    {
      plugin => "permission",
      meth   => "GET",
      auth   => Mojo::JSON->true,
      url    => "/type",
      func   => \&Rex::IO::Server::Permission::list_permission_types,
    }
  );

  $app->register_url(
    {
      plugin => "permission",
      meth   => "GET",
      auth   => Mojo::JSON->true,
      url    => "/set/:set_id",
      func   => \&Rex::IO::Server::Permission::get_set,
    }
  );

  $app->register_url(
    {
      plugin => "permission",
      meth   => "GET",
      auth   => Mojo::JSON->true,
      url    => "/permission/:perm_id",
      func   => \&Rex::IO::Server::Permission::get_perm,
    }
  );

  $app->register_url(
    {
      plugin => "permission",
      meth   => "POST",
      auth   => Mojo::JSON->true,
      url    => "/set",
      func   => \&Rex::IO::Server::Permission::add_set,
    }
  );

  $app->register_url(
    {
      plugin => "permission",
      meth   => "POST",
      auth   => Mojo::JSON->true,
      url    => "/permission",
      func   => \&Rex::IO::Server::Permission::add_perm,
    }
  );

  $app->register_url(
    {
      plugin => "permission",
      meth   => "POST",
      auth   => Mojo::JSON->true,
      url    => "/set/:set_id",
      func   => \&Rex::IO::Server::Permission::update_set,
    }
  );

  $app->register_url(
    {
      plugin => "permission",
      meth   => "POST",
      auth   => Mojo::JSON->true,
      url    => "/permission/:perm_id",
      func   => \&Rex::IO::Server::Permission::update_perm,
    }
  );

  $app->register_url(
    {
      plugin => "permission",
      meth   => "DELETE",
      auth   => Mojo::JSON->true,
      url    => "/set/:set_id",
      func   => \&Rex::IO::Server::Permission::delete_set,
    }
  );

  $app->register_url(
    {
      plugin => "permission",
      meth   => "DELETE",
      auth   => Mojo::JSON->true,
      url    => "/permission/:perm_id",
      func   => \&Rex::IO::Server::Permission::delete_perm,
    }
  );

}

1;
