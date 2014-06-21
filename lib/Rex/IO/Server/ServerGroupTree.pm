#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::ServerGroupTree;

use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;
use Carp;
use Try::Tiny;

sub create_root_node {
  my ($self) = @_;

  try {
    my $root_node = $self->db->resultset("ServerGroupTree")->create(
      {
        permission_set_id => 1,
        name              => 'Rex.IO',
      }
    );

    return $self->render(
      json => { ok => Mojo::JSON->true, data => { $root_node->get_columns } } );
  }
  catch {
    return $self->render(
      json   => { ok => Mojo::JSON->false, error => "@_" },
      status => 500
    );
  };
}

sub create_node {
  my ($self) = @_;

  my $json = $self->req->json;

  try {
    confess "No name given."      if !exists $json->{name};
    confess "No parent_id given." if !exists $json->{parent_id};

    my $parent_node =
      $self->db->resultset("ServerGroupTree")->find( $json->{parent_id} );

    if ( !$parent_node ) {
      return $self->render(
        json => { ok => Mojo::JSON->false, error => "Parent node not found." },
        status => 404
      );
    }

    my $child_node = $parent_node->add_to_children(
      {
        permission_set_id => $json->{permission_set_id} || 1,
        name => $json->{name},
      }
    );

    return $self->render(
      json => { ok => Mojo::JSON->true, data => { $child_node->get_columns } }
    );
  }
  catch {
    return $self->render(
      json   => { ok => Mojo::JSON->false, error => "@_" },
      status => 500
    );
  };
}

sub get_tree {
  my ($self) = @_;

  try {
    my $root_node =
      $self->db->resultset("ServerGroupTree")
      ->find( ( $self->param("node_id") || 1 ) );

    my @all_nodes = $root_node->nodes;
    my @ret       = ();

    for my $n (@all_nodes) {
      push @ret, { $n->get_columns };
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

sub get_root {
  my ($self) = @_;

  try {
    my $root_node = $self->db->resultset("ServerGroupTree")->find(1);
    return $self->render(
      json => { ok => Mojo::JSON->true, data => { $root_node->get_columns } } );
  }
  catch {
    return $self->render(
      json   => { ok => Mojo::JSON->false, error => "@_" },
      status => 500
    );
  };
}

sub get_children {
  my ($self) = @_;

  my $node_id = $self->param("node_id");

  try {
    my $node     = $self->db->resultset("ServerGroupTree")->find($node_id);
    my @children = $node->children;
    my @ret;
    for my $c (@children) {
      my $data = { $c->get_columns };
      $data->{has_children} = $c->is_branch;
      push @ret, $data;
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

  $r->get("/1.0/server_group_tree/tree")->over( authenticated => 1 )
    ->to("server_group_tree#get_tree");

  $r->get("/1.0/server_group_tree/root")->over( authenticated => 1 )
    ->to("server_group_tree#get_root");

  $r->get("/1.0/server_group_tree/children/:node_id")
    ->over( authenticated => 1 )->to("server_group_tree#get_children");

  $r->post("/1.0/server_group_tree/root")->over( authenticated => 1 )
    ->to("server_group_tree#create_root_node");

  $r->post("/1.0/server_group_tree/node")->over( authenticated => 1 )
    ->to("server_group_tree#create_node");

}

1;
