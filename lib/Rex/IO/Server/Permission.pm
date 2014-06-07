#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Permission;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON "j";
use Data::Dumper;
use Digest::Bcrypt;

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
    push @ret, { $set->get_columns };
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

  $self->render(
    json => { ok => Mojo::JSON->true, data => { $set->get_columns } } );
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
    my $set = $self->db->resultset('PermissionSet')->create( $self->req->json );

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
    $set->update( $self->req->json );
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

sub __register__ {
  my ( $self, $app ) = @_;
  my $r = $app->routes;

  $r->get("/1.0/permission/set")->over( authenticated => 1 )
    ->to("permission#list_set");
  $r->get("/1.0/permission/permission")->over( authenticated => 1 )
    ->to("permission#list_perm");

  $r->get("/1.0/permission/set/:set_id")->over( authenticated => 1 )
    ->to("permission#get_set");
  $r->get("/1.0/permission/permission/:perm_id")->over( authenticated => 1 )
    ->to("permission#get_perm");

  $r->post("/1.0/permission/set")->over( authenticated => 1 )
    ->to("permission#add_set");
  $r->post("/1.0/permission/permission")->over( authenticated => 1 )
    ->to("permission#add_perm");

  $r->post("/1.0/permission/set/:set_id")->over( authenticated => 1 )
    ->to("permission#update_set");
  $r->post("/1.0/permission/permission/:perm_id")->over( authenticated => 1 )
    ->to("permission#update_perm");

  $r->delete("/1.0/permission/set/:set_id")->over( authenticated => 1 )
    ->to("permission#delete_set");
  $r->delete("/1.0/permission/permission/:perm_id")->over( authenticated => 1 )
    ->to("permission#delete_perm");

}

1;
