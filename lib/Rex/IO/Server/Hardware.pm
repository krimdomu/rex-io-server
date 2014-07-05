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

  if ( !$self->current_user->has_perm('CREATE_HARDWARE') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission to create new hardware.'
      },
      status => 403
    );
  }

  my $json = $self->req->json;

  $self->app->log->debug("Adding new hardware. ");
  $self->app->log->debug( Dumper($json) );

  my $mac = $json->{mac};
  delete $json->{mac};

  my @nw_adapter;
  if ( exists $json->{network_adapters}
    && ref $json->{network_adapters} eq "ARRAY" )
  {
    @nw_adapter = @{ $json->{network_adapters} };
    delete $json->{network_adapters};
  }
  else {
    @nw_adapter = (
      {
        proto => "dhcp",
        mac   => $mac,
        boot  => 1,
        dev   => "eth0",
      }
    );
  }

  # check if hardware already exists
  my @macs;
  map { push @macs, $_->{mac} if $_->{mac} } @nw_adapter;
  $self->app->log->debug( "Searching for macs: " . Dumper( \@macs ) );
  my @hw = $self->db->resultset("Hardware")->search(
    {
      "network_adapters.mac" => { "-in" => \@macs }
    },
    {
      join => "network_adapters",
    }
  );

  if (@hw) {
    $self->app->log->error("Can't add hardware. Hardware already exists.");
    return $self->render(
      json => {
        ok       => Mojo::JSON->false,
        error    => "Hardware already exists.",
        redirect => "/1.0/hardware/hardware/" . $hw[0]->id
      },
      status => 409
    );
  }

  try {
    $self->app->log->debug("Creating new hardware...");

    my $os_id = $json->{os_id};

    if ( !$os_id ) {

      # no os exists, create or find one
      my @kernels = $self->db->resultset("Os")->search(
        {
          version => $json->{kernelrelease},
          kernel  => $json->{kernel},
        }
      );

      if ( scalar @kernels == 0 ) {
        $self->app->log->debug("Need to create new OS.");
        $self->app->log->debug(
              "version: $json->{kernelrelease} / kernel: $json->{kernel} "
            . "/ name: $json->{operatingsystem}" );

        # no kernel exists, create a new one
        my $new_os = $self->db->resultset("Os")->create(
          {
            version => $json->{kernelrelease},
            kernel  => $json->{kernel},
            name    => $json->{operatingsystem},
          }
        );

        $os_id = $new_os->id;
      }
      else {
        $self->app->log->debug( "Found OS: " . $kernels[0]->id );
        $os_id = $kernels[0]->id;
      }
    }

    my $hw = $self->db->resultset("Hardware")->create(
      {
        name              => $json->{name},
        os_id             => $os_id,
        uuid              => $json->{uuid} || '',
        server_group_id   => $json->{server_group_id} || 1,
        permission_set_id => $json->{permission_set_id} || 1,
        kernelrelease     => $json->{kernelrelease} || '',
        kernelversion     => $json->{kernelversion} || '',
      }
    );
    $hw->discard_changes;

    $self->app->log->debug( "New hardware created: " . $hw->id );
    $self->app->log->debug("Creating hardware adapter for new hardware.");

    map {
      $_->{hardware_id} = $hw->id;
      $_->{ip}          = ip_to_int( $_->{ip} );
      $_->{netmask}     = ip_to_int( $_->{netmask} );
      $_->{network}     = ip_to_int( $_->{network} );
      $_->{broadcast}   = ip_to_int( $_->{broadcast} );
      $_->{gateway}     = ip_to_int( $_->{gateway} );
    } @nw_adapter;

    for my $nw (@nw_adapter) {
      next if !$nw->{mac};    # skip nics with no mac
      my $nw_a = $self->db->resultset("NetworkAdapter")->create($nw);
      $self->app->log->debug( "NetworkAdapter created. " . $nw_a->id );
    }

    # check for cpus
    if ( exists $json->{cpus} ) {
      for my $cpu ( @{ $json->{cpus} } ) {
        $cpu->{hardware_id} = $hw->id;
        my $cpu_a = $self->db->resultset("Processor")->create($cpu);
        $self->app->log->debug( "Processor created. " . $cpu_a->id );
      }
    }

    # check for harddrives
    if ( exists $json->{harddrives} ) {
      for my $hd ( @{ $json->{harddrives} } ) {
        $hd->{hardware_id} = $hw->id;
        my $hd_a = $self->db->resultset("Harddrive")->create($hd);
        $self->app->log->debug( "Harddrive created. " . $hd_a->id );
      }
    }

    # check for memories
    if ( exists $json->{memories} ) {
      for my $mem ( @{ $json->{memories} } ) {
        $mem->{hardware_id} = $hw->id;
        my $mem_a = $self->db->resultset("Memory")->create($mem);
        $self->app->log->debug( "Memory created. " . $mem_a->id );
      }
    }

    # check for bios information
    if ( exists $json->{bios} ) {
      my $bios_a = $self->db->resultset("Bios")->create( $json->{bios} );
      $self->app->log->debug( "Bios created. " . $bios_a->id );
    }

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

  if ( !$self->current_user->has_perm('LIST_HARDWARE') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission to list hardware.'
      },
      status => 403
    );
  }

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

  $self->app->log->debug("Dumping query parameter: ");
  $self->app->log->debug( Dumper($query_param) );

  @tables = grep { $_ ne "hardware" } @tables;

  $self->app->log->debug("Dumping join tables: ");
  $self->app->log->debug( Dumper( \@tables ) );

  my @all_hw = $self->db->resultset('Hardware')->search(
    $query_param,
    {
      join => [@tables],
    },
  );

  my @ret;

  for my $hw (@all_hw) {
    if ( $hw->has_perm( 'READ', $self->current_user ) ) {
      push( @ret, $hw->to_hashRef );
    }
  }

  $self->render( json => { ok => Mojo::JSON->true, data => \@ret } );

}

sub search {
  my ($self) = @_;

  if ( !$self->current_user->has_perm('LIST_HARDWARE') ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission to list hardware.'
      },
      status => 403
    );
  }

#my $hw_r = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->name % ($self->param("name") . '%'));
  my @hw_r = $self->db->resultset("Hardware")
    ->search( { name => { like => $self->param("name") . '%' } } );

  my @ret = ();

  for my $hw (@hw_r) {
    if ( $hw->has_perm( 'READ', $self->current_user ) ) {
      push( @ret, $hw->to_hashRef );
    }
  }

  $self->render( json => \@ret );
}

sub get {
  my ($self) = @_;

  # no special check for LIST_HARDWARE
  # because it might be that the user can retrieve one special hardware

#my $hw = Rex::IO::Server::Model::Hardware->all( Rex::IO::Server::Model::Hardware->id == $self->param("id"))->next;

  my $hw;
  my $search_for = $self->param("id");

  if ( $search_for =~ m/^(\d+)$/ ) {
    $hw = $self->db->resultset("Hardware")->find($search_for);
  }
  elsif ( $search_for =~ m/[a-zA-Z0-9_\-\.:]+/ ) {

    # seems to be a name
    ($hw) =
      $self->db->resultset("Hardware")->search( { name => $search_for } );
  }

  if ( !$hw ) {
    return $self->render( json => { ok => Mojo::JSON->false }, status => 404 );
  }

  if ( $hw->has_perm( 'READ', $self->current_user ) ) {
    return $self->render(
      json => { ok => Mojo::JSON->true, data => $hw->to_hashRef } );
  }

  return $self->render(
    json =>
      { ok => Mojo::JSON->false, error => 'No permission to get hardware' },
    status => 403
  );
}

sub update {
  my ($self) = @_;

  my $hw_id = $self->param("id");
  my $json  = $self->req->json;

  $self->app->log->debug("Updating hardware: $hw_id");
  $self->app->log->debug( Dumper($json) );

  my $hw = $self->db->resultset("Hardware")->find( $self->param("id") );

  if ( !$hw->has_perm( 'MODIFY', $self->current_user ) ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission to modify hardware.'
      },
      status => 403
    );
  }

  if ($hw) {

################################################################

    my $json = $self->req->json;

    $self->app->log->debug("Updating hardware. ");
    $self->app->log->debug( Dumper($json) );

    my $mac = $json->{mac};
    delete $json->{mac};

    my @nw_adapter;
    if ( exists $json->{network_adapters}
      && ref $json->{network_adapters} eq "ARRAY" )
    {
      @nw_adapter = @{ $json->{network_adapters} };
      delete $json->{network_adapters};
    }
    else {
      @nw_adapter = (
        {
          proto => "dhcp",
          mac   => $mac,
          boot  => 1,
          dev   => "eth0",
        }
      );
    }

    try {
      $self->app->log->debug("Updating hardware...");

      my $os_id = $json->{os_id};

      if ( !$os_id && exists $json->{os_id} ) {

        # no os exists, create or find one
        my @kernels = $self->db->resultset("Os")->search(
          {
            version => $json->{kernelrelease},
            kernel  => $json->{kernel},
          }
        );

        if ( scalar @kernels == 0 ) {
          $self->app->log->debug("Need to create new OS.");
          $self->app->log->debug(
                "version: $json->{kernelrelease} / kernel: $json->{kernel} "
              . "/ name: $json->{operatingsystem}" );

          # no kernel exists, create a new one
          my $new_os = $self->db->resultset("Os")->create(
            {
              version => $json->{kernelrelease},
              kernel  => $json->{kernel},
              name    => $json->{operatingsystem},
            }
          );

          $os_id = $new_os->id;
        }
        else {
          $self->app->log->debug( "Found OS: " . $kernels[0]->id );
          $os_id = $kernels[0]->id;
        }
      }

      $hw->update(
        {
          name            => $json->{name}            || $hw->name,
          os_id           => $os_id                   || $hw->os_id,
          uuid            => $json->{uuid}            || $hw->uuid,
          server_group_id => $json->{server_group_id} || $hw->server_group_id,
          permission_set_id => $json->{permission_set_id}
            || $hw->permission_set_id,
          kernelrelease => $json->{kernelrelease} || $hw->kernelrelease,
          kernelversion => $json->{kernelversion} || $hw->kernelversion,
        }
      );

      $self->app->log->debug( "Hardware updated: " . $hw->id );
      $self->app->log->debug("Creating hardware adapter for hardware.");

      map {
        $_->{hardware_id} = $hw->id;
        $_->{ip}          = ip_to_int( $_->{ip} );
        $_->{netmask}     = ip_to_int( $_->{netmask} );
        $_->{network}     = ip_to_int( $_->{network} );
        $_->{broadcast}   = ip_to_int( $_->{broadcast} );
        $_->{gateway}     = ip_to_int( $_->{gateway} );
      } @nw_adapter;

      for my $nw (@nw_adapter) {
        next if !$nw->{mac};    # skip nics with no mac
                                # check if adapter exists
        my @nw_s = $self->db->resultset("NetworkAdapter")->search(
          {
            mac => $nw->{mac},
          }
        );

        if ( scalar @nw_s >= 1 && $nw_s[0]->hardware_id == $hw->id ) {
          $self->app->log->debug( "Updating network adapter: " . $nw_s[0]->id );
          $nw_s[0]->update($nw);
        }
        elsif ( scalar @nw_s >= 1 ) {
          $self->app->log->error(
            "Found network adapter, but this doesn't belong to hardware.");
          return $self->render(
            json => {
              ok => Mojo::JSON->false,
              error =>
                "Found network adapter, but this doesn't belong to hardware."
            },
            status => 409
          );
        }
        else {
          # net network adapter
          my $nw_a = $self->db->resultset("NetworkAdapter")->create($nw);
          $self->app->log->debug( "NetworkAdapter created. " . $nw_a->id );
        }
      }

      # check for cpus
      if ( exists $json->{cpus} ) {

        # first delete old cpus
        $hw->processors->delete;

        for my $cpu ( @{ $json->{cpus} } ) {
          $cpu->{hardware_id} = $hw->id;
          my $cpu_a = $self->db->resultset("Processor")->create($cpu);
          $self->app->log->debug( "Processor created. " . $cpu_a->id );
        }
      }

      # check for harddrives
      if ( exists $json->{harddrives} ) {
        $hw->harddrives->delete;

        for my $hd ( @{ $json->{harddrives} } ) {
          $hd->{hardware_id} = $hw->id;
          my $hd_a = $self->db->resultset("Harddrive")->create($hd);
          $self->app->log->debug( "Harddrive created. " . $hd_a->id );
        }
      }

      # check for memories
      if ( exists $json->{memories} ) {
        $hw->memories->delete;

        for my $mem ( @{ $json->{memories} } ) {
          $mem->{hardware_id} = $hw->id;
          my $mem_a = $self->db->resultset("Memory")->create($mem);
          $self->app->log->debug( "Memory created. " . $mem_a->id );
        }
      }

      # check for bios information
      if ( exists $json->{bios} ) {
        my $bios_s = $hw->bios;
        $hw->bios->delete if $bios_s;

        my $bios_a = $self->db->resultset("Bios")->create( $json->{bios} );
        $self->app->log->debug( "Bios created. " . $bios_a->id );
      }

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

################################################################

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

  if ( !$hw_i->has_perm( 'DELETE', $self->current_user ) ) {
    return $self->render(
      json => {
        ok    => Mojo::JSON->false,
        error => 'No permission to delete hardware.'
      },
      status => 403
    );
  }

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

  $r->get("/1.0/hardware/hardware/*id")->over( authenticated => 1 )
    ->to("hardware#get");

  $r->post("/1.0/hardware/hardware/:id")->over( authenticated => 1 )
    ->to("hardware#update");

  $r->delete("/1.0/hardware/hardware/:id")->over( authenticated => 1 )
    ->to("hardware#purge");

  $r->post("/1.0/hardware/hardware")->over( authenticated => 1 )
    ->to("hardware#add");
}

1;
