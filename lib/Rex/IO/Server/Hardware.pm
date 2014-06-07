#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

package Rex::IO::Server::Hardware;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON "j";
use Mojo::UserAgent;
use Try::Tiny;

use Rex::IO::Server::Helper::IP;

use Data::Dumper;

sub add {
  my ($self) = @_;

  my $json = $self->req->json;

  $self->app->log->debug("Adding new hardware. ");
  $self->app->log->debug( Dumper($json) );

  $json->{state_id}       = 1;
  $json->{os_template_id} = 1;

  my $mac = $json->{mac};
  delete $json->{mac};

  try {
    $self->app->log->debug("Creating new hardware...");
    my $hw = $self->db->resultset("Hardware")->create($json);
    $hw->discard_changes;

    $self->app->log->debug( "New hardware created: " . $hw->id );
    $self->app->log->debug("Creating hardware adapter for new hardware.");

    my $nw_a = $self->db->resultset("NetworkAdapter")->create(
      {
        hardware_id => $hw->id,
        proto       => "dhcp",
        boot        => 1,
        mac         => $mac,
      }
    );

    $self->app->log->debug( "NetworkAdapter created. " . $nw_a->id );

    $self->render(
      json => { ok => Mojo::JSON->true, data => $hw->to_hashRef } );
    1;
  }
  catch {
    $self->app->log->error("Error creating new hardware:\n\nERROR: $_\n\n");
    $self->render(
      json   => { ok => Mojo::JSON->false, error => $_ },
      status => 500
    );
  };
}

sub list {
  my ($self) = @_;

  my $action = $self->param("action");

  if ( $action && $action eq "count" ) {
    my @all_hw = $self->db->resultset('Hardware')->all;
    return $self->render(
      json => { ok => Mojo::JSON->true, count => scalar @all_hw } );
  }

  #
  # table=os
  # table=hardware
  # os.name=SLES
  # hardware.name=foo01
  #

#if($self->param("group_id")) {
#  @all_hw = $self->db->resultset('Hardware')->search({ server_group_id => $self->param("group_id") }, {order_by => 'name'});
#}
#else {
#  @all_hw = $self->db->resultset('Hardware')->search({}, {order_by => 'name'});
#}

  my @tables = $self->param("table");

  my @all_params  = $self->param;
  my $query_param = {};
  for my $t (@tables) {
    for my $p (@all_params) {
      if ( $p =~ m/^$t\.(.*)$/ ) {
        my $key = $p;
        $key =~ s/^hardware\./me./;
        $query_param->{$key} = $self->param($p);
      }
    }
  }

  print STDERR Dumper($query_param);

  @tables = grep { $_ ne "hardware" } @tables;

  print STDERR Dumper( \@tables );

  my @all_hw = $self->db->resultset('Hardware')->search(
    $query_param,
    {
      join => [@tables],
    },
  );

  my @ret;

  for my $hw (@all_hw) {
    push( @ret, $hw->to_hashRef );
  }

  $self->render( json => { ok => Mojo::JSON->true, data => \@ret } );

}

sub search {
  my ($self) = @_;

#my $hw_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->name % ($self->param("name") . '%'));
  my @hw_r = $self->db->resultset("Hardware")
    ->search( { name => { like => $self->param("name") . '%' } } );

  my @ret = ();

  for my $hw (@hw_r) {
    push( @ret, $hw->to_hashRef );
  }

  $self->render( json => \@ret );
}

sub get {
  my ($self) = @_;

#my $hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->id == $self->param("id"))->next;
  my $hw = $self->db->resultset("Hardware")->find( $self->param("id") );
  $self->render( json => { ok => Mojo::JSON->true, data => $hw->to_hashRef } );
}

sub update {
  my ($self) = @_;

  my $hw_id = $self->param("id");
  my $json  = $self->req->json;

#my $hw_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->id == $self->param("id") );
  $self->app->log->debug("Updating hardware: $hw_id");
  $self->app->log->debug( Dumper($json) );

  my $hw = $self->db->resultset("Hardware")->find( $self->param("id") );

  if ($hw) {
    try {
      $self->app->log->debug("Hardware found. going to update.");
      $hw->update($json);
      $self->render( json => { ok => Mojo::JSON->true } );
      1;
    }
    catch {
      $self->app->log->error("Error updating hardware.\n\nERROR: $_\n\n");
      $self->render(
        json   => { ok => Mojo::JSON->false, error => $_ },
        status => 500
      );
    };
  }
  else {
    $self->app->log->debug("Can't find hardware with id: $hw_id!");
    $self->render(
      json   => { ok => Mojo::JSON->false, error => "Hardware not found!" },
      status => 404
    );
  }
}

sub purge {
  my ($self) = @_;

  my $hw_id = $self->param("id");

  $self->app->log->debug("Deleting hardware: $hw_id");

  my $hw_i = $self->db->resultset("Hardware")->find( $self->param("id") );

  # deregister hardware on dhcp
  # $self->app->log->debug("Deleting dhcp entry.");
  # $self->dhcp->delete_entry( $hw_i->name );

  try {
    if ($hw_i) {

      # give plugins the possibility to clean up
      for my $plug ( @{ $self->config->{plugins} } ) {
        my $klass = "Rex::IO::Server::$plug";
        eval "require $klass";
        eval { $klass->__delete_hardware__( $self, $hw_i ); };
      }

      $hw_i->purge;
      $self->render( json => { ok => Mojo::JSON->true } );
    }
    else {
      $self->app->log->debug("Hardware not found ($hw_id).");
      $self->render(
        json   => { ok => Mojo::JSON->false, error => "Hardware not found." },
        status => 404
      );
    }

    1;
  }
  catch {
    $self->app->log->error("Error deleting hardware.\n\nERROR: $_\n\n");
    $self->render(
      json   => { ok => Mojo::JSON->false, error => $_ },
      status => 500
    );
  };

}

################################################################################
# internal functions
################################################################################
sub _ua { return Mojo::UserAgent->new; }

sub __register__ {
  my ( $self, $app ) = @_;
  my $r = $app->routes;

 # $r->route("/hardware")->via("LIST")->over( authenticated => 1 )
 #   ->to("hardware#list");
 # $r->get("/hardware/search/:name")->over( authenticated => 1 )
 #   ->to("hardware#search");
 # $r->post("/hardware/:id")->over( authenticated => 1 )->to("hardware#update");
 # $r->get("/hardware/:id")->over( authenticated => 1 )->to("hardware#get");
 # $r->post("/hardware")->over( authenticated => 1 )->to("hardware#add");

  # new routes
  $r->get("/1.0/hardware/hardware")->over( authenticated => 1 )
    ->to("hardware#list");

  $r->get("/1.0/hardware/hardware/:id")->over( authenticated => 1 )
    ->to("hardware#get");

  $r->post("/1.0/hardware/hardware/:id")->over( authenticated => 1 )
    ->to("hardware#update");

  $r->delete("/1.0/hardware/hardware/:id")->over( authenticated => 1 )
    ->to("hardware#purge");

  $r->post("/1.0/hardware/hardware")->over( authenticated => 1 )
    ->to("hardware#add");
}

1;
